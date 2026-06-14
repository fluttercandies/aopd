// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;

import 'aop_diagnostic_reporter.dart';
import 'rewriters/add_transformer.dart';
import 'rewriters/aop_item_info.dart';
import 'rewriters/aop_mode.dart';
import 'rewriters/aop_transform_utils.dart';
import 'rewriters/call_transformer.dart';
import 'rewriters/execute_transformer.dart';
import 'rewriters/field_get_transformer.dart';
import 'rewriters/inject_transformer.dart';
import 'widget_location/track_widget_constructor_locations.dart';

/// Top-level AOP transformer driver. Exposes two entry points so the kernel
/// pipeline can run them around constant evaluation:
///   * [transformWidgetCreator] must run BEFORE constant evaluation.
///   * [transform] must run AFTER constant evaluation.
class AopWrapperTransformer {
  AopWrapperTransformer({this.platformStrongComponent});

  List<AopItemInfo> aopItemInfoList = <AopItemInfo>[];
  Map<String, Library> componentLibraryMap = <String, Library>{};
  Component? platformStrongComponent;

  final WidgetCreatorTracker _aopWidgetCreatorTracker = WidgetCreatorTracker();

  /// Phase 1: emit AOP-specific widget creation tracking. Must be invoked
  /// BEFORE constant evaluation because it produces ConstConstructorInvocation
  /// nodes that need to be folded into kernel Constants.
  void transformWidgetCreator(
    Component program, {
    void Function(String msg)? logger,
  }) {
    // M4.8: this is only called when track_widget_creation is requested. If the
    // AOPD location runtime is not reachable in the component, the tracker
    // silently returns -- warn loudly instead, so users don't think tracking is
    // active when it isn't.
    final bool hasLocationRuntime = program.libraries.any(
      (Library lib) =>
          lib.importUri.toString() == 'package:aopd/src/location.dart' &&
          lib.classes.any((Class c) => c.name == 'AopLocation'),
    );
    if (!hasLocationRuntime) {
      logger?.call(
        '[AOPD] WARNING: track_widget_creation is enabled but the AOPD '
        'location runtime (package:aopd/src/location.dart / AopLocation) is '
        'not reachable in this component; widget location tracking is '
        'skipped. Import package:aopd/aopd.dart somewhere reachable to '
        'enable it.',
      );
    }
    _aopWidgetCreatorTracker.transform(program, program.libraries, null);
  }

  void transform(
    Component program, {
    CoreTypes? coreTypes,
    void Function(String msg)? logger,
  }) {
    ///   * [transform] must run AFTER constant evaluation.
    // so that annotations on aspect classes / members are stored as
    // ConstantExpression rather than RedirectingFactoryInvocation).
    //
    // Crash-safety outermost guardrail: an AOP failure must never kill the host
    // build. If anything escapes the inner guardrails, report loudly and let
    // the build continue (degrade but loud).
    AopUtils.beginProceedClosurePass();
    try {
      transformAspects(program, coreTypes: coreTypes, logger: logger);
    } catch (e, st) {
      logger?.call(
        '[AOPD] ERROR: AOP transform aborted; build continues '
        'without complete weaving. $e\n$st',
      );
    } finally {
      // Insert any hoisted proceed functions now that every rewriter has
      // finished visiting members in place (see [buildProceedClosure]). This
      // also runs after a caught transform error: partially rewritten callsites
      // may already contain StaticTearOffConstants that must point at members
      // in the host library for the resulting kernel to stay valid.
      AopUtils.flushDeferredProceedProcedures();
    }
  }

  void transformAspects(
    Component program, {
    CoreTypes? coreTypes,
    void Function(String msg)? logger,
  }) {
    AopUtils.diagnostics = AopDiagnosticReporter(logger);
    // M5.4: stub keys no longer drive a central proceed() dispatch table -- each
    // woven site carries its own proceedClosure (decentralized). The counter
    // now only produces unique names for the moved-out execute stubs within a
    // single compile, so resetting it per transform keeps full builds
    // deterministic. Its cross-delta drift is no longer a correctness concern.
    AopUtils.kPrimaryKeyAopMethod = 0;
    // #1: reset the global static state so a resident / incremental compile
    // cannot reuse nodes resolved from a previous component. coreLib in
    // particular is only assigned conditionally below (and the #33 CoreTypes
    // fallback uses `??=`), so without this reset a stale coreLib from the
    // previous pass could survive and be woven into the new component.
    AopUtils.coreLib = null;
    AopUtils.pointCutProceedProcedure = null;
    AopUtils.listGetProcedure = null;
    AopUtils.mapGetProcedure = null;
    AopUtils.platformStrongComponent = null;
    aopItemInfoList.clear();
    componentLibraryMap.clear();
    for (Library library in program.libraries) {
      componentLibraryMap.putIfAbsent(
        library.importUri.toString(),
        () => library,
      );
    }
    program.libraries.forEach(_checkIfCompleteLibraryReference);
    final List<Library> libraries = program.libraries;

    if (libraries.isEmpty) {
      return;
    }

    _resolveAopProcedures(libraries);

    // (#27 B+C) Deterministic order + loud diagnostic on exact-target
    // conflicts, before splitting into per-mode lists below.
    AopUtils.sortAndReportConflicts(aopItemInfoList);

    final Procedure? pointCutProceedProcedure = _findPointCutProceedProcedure(
      libraries,
    );
    if (pointCutProceedProcedure == null) {
      if (aopItemInfoList.isNotEmpty) {
        // M3/M5: aspects were found but the PointCut runtime is not in this
        // compile unit. On a full build PointCut is always present, so this
        // almost always means an INCREMENTAL recompile (a delta without
        // package:aopd) or a missing aopd dependency. Weaving is skipped for
        // these aspects -- be loud (degrade but loud) rather than silently
        // desync.
        AopUtils.diagnostics?.error(
          null,
          'found ${aopItemInfoList.length} AOP annotation(s) but the '
          'PointCut runtime (package:aopd) is not in this compile unit; AOP '
          'weaving is skipped. This is usually an incremental recompile -- do '
          'a full rebuild (e.g. `flutter clean`) -- or package:aopd is not '
          'imported anywhere reachable.',
        );
      } else {
        logger?.call('[AOPD] PointCut.proceed not found; no aspects to weave.');
      }
      return;
    }
    Procedure? listGetProcedure;
    Procedure? mapGetProcedure;
    // Search SDK helpers across the current component and the platform
    // component. PointCut itself must come from the current component; adding
    // generated stubs to a platform PointCut causes canonical-name collisions
    // when the app PointCut library is written to dill.
    final List<Library> concatLibraries = <Library>[
      ...libraries,
      ...?platformStrongComponent != null
          ? platformStrongComponent?.libraries
          : <Library>[],
    ];
    final Map<Uri, Source> concatUriToSource = <Uri, Source>{}
      ..addAll(program.uriToSource)
      ..addAll(
        platformStrongComponent != null
            ? platformStrongComponent!.uriToSource
            : <Uri, Source>{},
      );
    final Map<String, Library> libraryMap = <String, Library>{};
    for (Library library in concatLibraries) {
      libraryMap.putIfAbsent(library.importUri.toString(), () => library);
      if (listGetProcedure != null && mapGetProcedure != null) {
        continue;
      }

      if (library.name == 'dart.core') {
        AopUtils.coreLib = library;
      }

      final Uri importUri = library.importUri;
      for (Class cls in library.classes) {
        final String clsName = cls.name;
        if (clsName == 'List' && importUri.toString() == 'dart:core') {
          for (Procedure procedure in cls.procedures) {
            if (procedure.name.text == '[]') {
              listGetProcedure = procedure;
            }
          }
        }
        if (clsName == 'Map' && importUri.toString() == 'dart:core') {
          for (Procedure procedure in cls.procedures) {
            if (procedure.name.text == '[]') {
              mapGetProcedure = procedure;
            }
          }
        }
      }
    }
    // #33: fall back to CoreTypes for the SDK helpers when they are not in
    // program.libraries (e.g. --no-link-platform compiles, where dart:core is
    // loaded as a separate platform component). CoreTypes always resolves the
    // real dart:core, so weaving proceeds instead of being skipped.
    if (coreTypes != null) {
      AopUtils.coreLib ??= coreTypes.coreLibrary;
      if (listGetProcedure == null) {
        for (final Procedure p in coreTypes.listClass.procedures) {
          if (p.name.text == '[]') {
            listGetProcedure = p;
          }
        }
      }
      if (mapGetProcedure == null) {
        for (final Procedure p in coreTypes.mapClass.procedures) {
          if (p.name.text == '[]') {
            mapGetProcedure = p;
          }
        }
      }
    }
    final List<AopItemInfo> callInfoList = <AopItemInfo>[];
    final List<AopItemInfo> executeInfoList = <AopItemInfo>[];
    final List<AopItemInfo> injectInfoList = <AopItemInfo>[];
    final List<AopItemInfo> addInfoList = <AopItemInfo>[];
    final List<AopItemInfo> fieldGetInfoList = <AopItemInfo>[];

    for (AopItemInfo aopItemInfo in aopItemInfoList) {
      if (aopItemInfo.mode == AopMode.call) {
        callInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.execute) {
        executeInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.inject) {
        injectInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.add) {
        addInfoList.add(aopItemInfo);
      } else if (aopItemInfo.mode == AopMode.fieldGet) {
        fieldGetInfoList.add(aopItemInfo);
      }
    }

    AopUtils.pointCutProceedProcedure = pointCutProceedProcedure;
    AopUtils.listGetProcedure = listGetProcedure;
    AopUtils.mapGetProcedure = mapGetProcedure;
    AopUtils.platformStrongComponent = platformStrongComponent;

    // Crash-safety: every woven call/execute relies on dart:core `==`
    // (coreLib) and List/Map `[]` (listGet/mapGet). If they are not in this
    // component (e.g. --no-link-platform with dart:core external and no
    // platformStrongComponent fallback), weaving would crash on `!`. Skip all
    // weaving with a loud diagnostic instead of producing broken output.
    if (AopUtils.coreLib == null ||
        listGetProcedure == null ||
        mapGetProcedure == null) {
      AopUtils.diagnostics?.error(
        null,
        'SDK helpers not found in component '
        '(coreLib=${AopUtils.coreLib != null}, '
        'listGet=${listGetProcedure != null}, '
        'mapGet=${mapGetProcedure != null}); skipping all AOP weaving.',
      );
      return;
    }

    // Aop call transformer
    if (callInfoList.isNotEmpty) {
      try {
        final AopCallImplTransformer aopCallImplTransformer =
            AopCallImplTransformer(callInfoList, libraryMap, concatUriToSource);

        for (int i = 0; i < libraries.length; i++) {
          final Library library = libraries[i];
          try {
            aopCallImplTransformer.visitLibrary(library);
          } catch (e, st) {
            // Per-library isolation: a throw while weaving one library must not
            // abort call-mode weaving for the remaining libraries (call sites
            // have no per-site try/catch, unlike execute/inject/add items).
            AopUtils.diagnostics?.error(
              null,
              'call-mode weaving failed in ${library.importUri}: $e\n$st',
            );
          }
        }
      } catch (e, st) {
        AopUtils.diagnostics?.error(null, 'call-mode weaving failed: $e\n$st');
      }
    }

    if (addInfoList.isNotEmpty) {
      try {
        final AopAddImplTransformer aopAddImplTransformer =
            AopAddImplTransformer(addInfoList, concatUriToSource);
        for (int i = 0; i < libraries.length; i++) {
          final Library library = libraries[i];
          try {
            aopAddImplTransformer.visitLibrary(library);
          } catch (e, st) {
            // Per-library isolation: mirror call/fieldGet. A throw weaving one
            // library (e.g. a cast failure before insertMethod4Class's per-item
            // guard) must not abort @Add for the remaining libraries.
            AopUtils.diagnostics?.error(
              null,
              'add-mode weaving failed in ${library.importUri}: $e\n$st',
            );
          }
        }
      } catch (e, st) {
        AopUtils.diagnostics?.error(null, 'add-mode weaving failed: $e\n$st');
      }
    }

    // Aop execute transformer
    if (executeInfoList.isNotEmpty) {
      try {
        AopExecuteImplTransformer(
          executeInfoList,
          libraryMap,
          concatUriToSource,
        ).aopTransform();
      } catch (e, st) {
        AopUtils.diagnostics?.error(
          null,
          'execute-mode weaving failed: $e\n$st',
        );
      }
    }
    // Aop inject transformer
    if (injectInfoList.isNotEmpty) {
      try {
        AopInjectImplTransformer(
          injectInfoList,
          libraryMap,
          concatUriToSource,
        ).aopTransform();
      } catch (e, st) {
        AopUtils.diagnostics?.error(
          null,
          'inject-mode weaving failed: $e\n$st',
        );
      }
    }

    // Aop field get transformer
    if (fieldGetInfoList.isNotEmpty) {
      try {
        final AopFieldGetImplTransformer aopFieldGetImplTransformer =
            AopFieldGetImplTransformer(fieldGetInfoList, concatUriToSource);

        for (int i = 0; i < libraries.length; i++) {
          final Library library = libraries[i];
          try {
            aopFieldGetImplTransformer.visitLibrary(library);
          } catch (e, st) {
            // Per-library isolation (see call-mode above): one failing library
            // must not abort fieldGet weaving for the rest.
            AopUtils.diagnostics?.error(
              null,
              'fieldGet-mode weaving failed in ${library.importUri}: $e\n$st',
            );
          }
        }
      } catch (e, st) {
        AopUtils.diagnostics?.error(
          null,
          'fieldGet-mode weaving failed: $e\n$st',
        );
      }
    }
  }

  Procedure? _findPointCutProceedProcedure(Iterable<Library> libraries) {
    for (Library library in libraries) {
      if (library.importUri.toString() != AopUtils.kImportUriPointCut) {
        continue;
      }
      for (Class cls in library.classes) {
        if (cls.name != AopUtils.kAopAnnotationClassPointCut) {
          continue;
        }
        for (Procedure procedure in cls.procedures) {
          if (procedure.name.text == AopUtils.kAopPointcutProcessName) {
            return procedure;
          }
        }
      }
    }
    return null;
  }

  void _resolveAopProcedures(Iterable<Library> libraries) {
    for (Library library in libraries) {
      final List<Class> classes = library.classes;
      for (Class cls in classes) {
        final bool aopEnabled = AopUtils.checkIfClassEnableAop(cls.annotations);
        if (!aopEnabled) {
          continue;
        }
        for (Member member in cls.members) {
          try {
            final AopItemInfo? aopItemInfo = _processAopMember(member);
            if (aopItemInfo != null) {
              aopItemInfoList.add(aopItemInfo);
            }
          } catch (e) {
            // A malformed annotation must not abort resolution of the others.
            AopUtils.diagnostics?.error(
              null,
              'failed to parse AOP annotation on '
              '${cls.name}.${member.name.text}: $e',
            );
          }
        }
      }
    }
  }

  AopItemInfo? _processAopMember(Member member) {
    // #13: forbid stacking multiple AOP annotations on one member. Only the
    // first would ever take effect (the loop below returns on the first
    // match), silently dropping the rest. Be loud: skip the member with an
    // error instead of weaving an arbitrary one.
    final int aopAnnotationCount = member.annotations
        .where(
          (Expression a) =>
              AopUtils.resolveAnnotationAopMode(a, componentLibraryMap) != null,
        )
        .length;
    if (aopAnnotationCount > 1) {
      final String where =
          '${member.enclosingClass?.name ?? '(library)'}.${member.name.text}';
      AopUtils.diagnostics?.error(
        null,
        'multiple AOP annotations on $where are not supported; skipping this '
        'member. Put each aspect in its own method.',
      );
      return null;
    }
    for (Expression annotation in member.annotations) {
      if (annotation is ConstantExpression) {
        final ConstantExpression constantExpression = annotation;
        final Constant constant = constantExpression.constant;
        if (constant is InstanceConstant) {
          final InstanceConstant instanceConstant = constant;
          final CanonicalName? canonicalName =
              instanceConstant.classReference.canonicalName;
          constant.classReference.node ??= AopUtils.getNodeFromCanonicalName(
            componentLibraryMap,
            canonicalName,
          );
          constant.fieldValues.forEach((
            Reference reference,
            Constant constant,
          ) {
            reference.node ??= AopUtils.getNodeFromCanonicalName(
              componentLibraryMap,
              reference.canonicalName,
            );
          });

          // After constant evaluation, canonical names may be null while the
          // resolved node is still available. Fall back to the class node to
          // find the annotation's class/library identification.
          String? annotationClsName;
          String? annotationLibName;
          final TreeNode? clsNode = instanceConstant.classReference.node;
          if (clsNode is Class) {
            annotationClsName = clsNode.name;
            final Library? lib = clsNode.parent as Library?;
            annotationLibName = lib?.importUri.toString();
          }
          final AopKernelResolver resolver = AopKernelResolver(
            componentLibraryMap,
          );
          annotationClsName ??= AopKernelResolver.memberNameOf(canonicalName);
          annotationLibName ??= resolver.libraryImportUriOf(canonicalName);
          if (annotationClsName == null || annotationLibName == null) {
            continue;
          }
          final AopMode? aopMode = AopUtils.getAopModeByNameAndImportUri(
            annotationClsName,
            annotationLibName,
          );
          if (aopMode == null) {
            continue;
          }
          // #12: parse into nullable locals and validate required fields
          // below, rather than `late` that throws LateInitializationError on a
          // malformed/unexpected annotation shape.
          String? importUri;
          String? clsName;
          String? superClsName;
          String? methodName;
          String? fieldName;
          bool isRegex = false;
          bool excludeCoreLib = false;
          int? lineNum;
          bool isStatic = false;

          instanceConstant.fieldValues.forEach((
            Reference reference,
            Constant constant,
          ) {
            // Identify the annotation field name using the canonical name when
            // available, otherwise fall back to the resolved Field node name.
            String? fieldRefName = reference.canonicalName?.name;
            if (fieldRefName == null) {
              final NamedNode? n = reference.node;
              if (n is Field) {
                fieldRefName = n.name.text;
              }
            }
            if (constant is StringConstant) {
              final String value = constant.value;
              if (fieldRefName == AopUtils.kAopAnnotationImportUri) {
                importUri = value;
              } else if (fieldRefName == AopUtils.kAopAnnotationClsName) {
                clsName = value;
              } else if (fieldRefName == AopUtils.kAopAnnotationMethodName) {
                methodName = value;
              } else if (fieldRefName == AopUtils.kAopAnnotationSuperClsName) {
                superClsName = value;
              } else if (fieldRefName == AopUtils.kAopAnnotationfieldName) {
                fieldName = value;
              }
            }
            if (fieldRefName == AopUtils.kAopAnnotationLineNum) {
              if (constant is DoubleConstant) {
                final int value = constant.value.toInt();
                lineNum = value - 1;
              } else if (constant is IntConstant) {
                final int value = constant.value;
                lineNum = value - 1;
              }
            }
            if (constant is BoolConstant) {
              final bool value = constant.value;
              if (fieldRefName == AopUtils.kAopAnnotationIsRegex) {
                isRegex = value;
              } else if (fieldRefName ==
                  AopUtils.kAopAnnotationExcludeCoreLib) {
                excludeCoreLib = value;
              } else if (fieldRefName == AopUtils.kAopAnnotationIsStatic) {
                isStatic = value;
              }
            }
          });

          if (aopMode != AopMode.fieldGet) {
            if (methodName != null) {
              if (methodName!.startsWith(
                AopUtils.kAopAnnotationInstanceMethodPrefix,
              )) {
                methodName = methodName!.substring(
                  AopUtils.kAopAnnotationInstanceMethodPrefix.length,
                );
              } else if (methodName!.startsWith(
                AopUtils.kAopAnnotationStaticMethodPrefix,
              )) {
                methodName = methodName!.substring(
                  AopUtils.kAopAnnotationStaticMethodPrefix.length,
                );
                isStatic = true;
              }
            }
          }

          member.annotations.remove(annotation);

          // Crash-safety: validate regex patterns up front so an invalid
          // pattern is skipped with a diagnostic, never thrown as a
          // FormatException mid-transform.
          if (isRegex) {
            final String? badPattern = AopUtils.firstInvalidRegex(<String?>[
              importUri,
              clsName,
              methodName,
              fieldName,
            ]);
            if (badPattern != null) {
              AopUtils.diagnostics?.unsupported(
                null,
                'invalid regex pattern "$badPattern" in '
                '@$annotationClsName (importUri=$importUri, cls=$clsName); '
                'skipping this aspect item.',
              );
              return null;
            }
          }

          // #12: required-field validation (replaces the old `late` crash).
          if (importUri == null || clsName == null) {
            AopUtils.diagnostics?.unsupported(
              null,
              'AOP annotation @$annotationClsName is missing importUri/clsName; '
              'skipping this aspect item.',
            );
            return null;
          }

          return AopItemInfo.tryCreate(
            importUri: importUri!,
            clsName: clsName!,
            methodName: methodName,
            isStatic: isStatic,
            aopMember: member,
            mode: aopMode,
            isRegex: isRegex,
            superCls: superClsName,
            lineNum: lineNum,
            excludeCoreLib: excludeCoreLib,
            fieldName: fieldName,
            onInvalid: (String message) {
              AopUtils.diagnostics?.unsupported(
                null,
                'invalid @$annotationClsName annotation on '
                '${member.name.text}: $message Skipping this aspect item.',
              );
            },
          );
        }
      }
      //Debug Mode
      else if (annotation is ConstructorInvocation) {
        final ConstructorInvocation constructorInvocation = annotation;
        final Class? cls =
            constructorInvocation.targetReference.node?.parent as Class?;
        final Library? clsParentLib = cls?.parent as Library?;
        if (cls == null || clsParentLib == null) {
          continue;
        }
        final AopMode? aopMode = AopUtils.getAopModeByNameAndImportUri(
          cls.name,
          clsParentLib.importUri.toString(),
        );
        if (aopMode == null) {
          continue;
        }
        // #12: guard the literal casts so a malformed debug-mode annotation
        // degrades (skip + diagnostic) instead of throwing a cast error.
        final List<Expression> positional =
            constructorInvocation.arguments.positional;
        if (positional.length < 2 ||
            positional[0] is! StringLiteral ||
            positional[1] is! StringLiteral) {
          AopUtils.diagnostics?.unsupported(
            null,
            'malformed @${cls.name} debug-mode annotation (expected string '
            'importUri and clsName); skipping this aspect item.',
          );
          continue;
        }
        final String importUri = (positional[0] as StringLiteral).value;
        final String clsName = (positional[1] as StringLiteral).value;
        String methodName =
            positional.length > 2 && positional[2] is StringLiteral
            ? (positional[2] as StringLiteral).value
            : '';
        bool isRegex = false;
        int? lineNum;
        String? superCls;

        for (NamedExpression namedExpression
            in constructorInvocation.arguments.named) {
          final Expression value = namedExpression.value;
          if (namedExpression.name == AopUtils.kAopAnnotationLineNum &&
              value is IntLiteral) {
            lineNum = value.value - 1;
          } else if (namedExpression.name ==
                  AopUtils.kAopAnnotationSuperClsName &&
              value is StringLiteral) {
            superCls = value.value;
          } else if (namedExpression.name == AopUtils.kAopAnnotationIsRegex &&
              value is BoolLiteral) {
            isRegex = value.value;
          }
        }

        bool isStatic = false;
        if (methodName.startsWith(
          AopUtils.kAopAnnotationInstanceMethodPrefix,
        )) {
          methodName = methodName.substring(
            AopUtils.kAopAnnotationInstanceMethodPrefix.length,
          );
        } else if (methodName.startsWith(
          AopUtils.kAopAnnotationStaticMethodPrefix,
        )) {
          methodName = methodName.substring(
            AopUtils.kAopAnnotationStaticMethodPrefix.length,
          );
          isStatic = true;
        }

        String fieldName = '';

        if (aopMode == AopMode.fieldGet) {
          if (positional.length > 2 && positional[2] is StringLiteral) {
            fieldName = (positional[2] as StringLiteral).value;
          }
          if (positional.length > 3 && positional[3] is BoolLiteral) {
            isStatic = (positional[3] as BoolLiteral).value;
          }
        }

        member.annotations.remove(annotation);

        return AopItemInfo.tryCreate(
          importUri: importUri,
          clsName: clsName,
          methodName: methodName,
          isStatic: isStatic,
          aopMember: member,
          mode: aopMode,
          superCls: superCls,
          isRegex: isRegex,
          lineNum: lineNum,
          fieldName: fieldName,
          onInvalid: (String message) {
            AopUtils.diagnostics?.unsupported(
              null,
              'invalid @${cls.name} debug-mode annotation on '
              '${member.name.text}: $message Skipping this aspect item.',
            );
          },
        );
      }
    }

    return null;
  }

  void _checkIfCompleteLibraryReference(Library library) {
    for (LibraryDependency libraryDependency in library.dependencies) {
      libraryDependency.importedLibraryReference.node ??=
          AopUtils.getNodeFromCanonicalName(
            componentLibraryMap,
            libraryDependency.importedLibraryReference.canonicalName,
          );
    }
  }
}
