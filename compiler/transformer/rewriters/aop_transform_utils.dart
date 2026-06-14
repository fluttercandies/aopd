// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'dart:convert';
import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import '../aop_diagnostic_reporter.dart';
import 'aop_item_info.dart';
import 'aop_mode.dart';

class AopUtils {
  AopUtils._();

  static const String kAopAnnotationClassCall = 'Call';
  static const String kAopAnnotationClassExecute = 'Execute';
  static const String kAopAnnotationClassInject = 'Inject';
  static const String kAopAnnotationClassAdd = 'Add';
  static const String kAopAnnotationFieldGetInitializer = 'FieldGet';

  static const String kImportUriAopAspect =
      'package:aopd/src/annotations/aspect.dart';
  static const String kImportUriAopCall =
      'package:aopd/src/annotations/call.dart';
  static const String kImportUriAopExecute =
      'package:aopd/src/annotations/execute.dart';
  static const String kImportUriAopInject =
      'package:aopd/src/annotations/inject.dart';
  static const String kImportUriAopAdd =
      'package:aopd/src/annotations/add.dart';
  static const String kImportUriAopFieldGet =
      'package:aopd/src/annotations/field_get.dart';

  static const String kImportUriPointCut =
      'package:aopd/src/annotations/pointcut.dart';
  static const String kAopUniqueKeySeperator = '#';
  static const String kAopAnnotationClassAspect = 'Aspect';
  static const String kAopAnnotationImportUri = 'importUri';
  static const String kAopAnnotationClsName = 'clsName';
  static const String kAopAnnotationSuperClsName = 'superCls';
  static const String kAopAnnotationMethodName = 'methodName';
  static const String kAopAnnotationIsRegex = 'isRegex';
  static const String kAopAnnotationExcludeCoreLib = 'excludeCoreLib';
  static const String kAopAnnotationfieldName = 'fieldName';
  static const String kAopAnnotationLineNum = 'lineNum';
  static const String kAopAnnotationIsStatic = 'isStatic';

  static const String kAopAnnotationClassPointCut = 'PointCut';
  static const String kAopAnnotationInstanceMethodPrefix = '-';
  static const String kAopAnnotationStaticMethodPrefix = '+';
  static int kPrimaryKeyAopMethod = 0;
  static const String kAopStubMethodPrefix = 'aop_stub_';
  static const String kAopPointcutProcessName = 'proceed';
  static const String kAopPointcutIgnoreVariableDeclaration = '//AOPD Ignore';
  static const String kAopPointcutReplaceThisUsage = '//AOPD Replace This';
  static Procedure? _pointCutProceedProcedure;
  static Procedure? get pointCutProceedProcedure => _pointCutProceedProcedure;
  static set pointCutProceedProcedure(Procedure? value) {
    _pointCutProceedProcedure = value;
    // Invalidate the per-pass PointCut member cache whenever the runtime handle
    // changes (reset to null at pass start, then set to the new component's
    // PointCut). Resolved lazily on first use below.
    _pcPositionalParamsField = null;
    _pcNamedParamsField = null;
    _pcTargetField = null;
    _pcConstructor = null;
  }

  static Field? _pcPositionalParamsField;
  static Field? _pcNamedParamsField;
  static Field? _pcTargetField;
  static Constructor? _pcConstructor;

  /// The PointCut runtime class (parent of [pointCutProceedProcedure]).
  static Class get pointCutClass => pointCutProceedProcedure!.parent as Class;

  static Field _pointCutFieldNamed(String name) {
    for (final Field field in pointCutClass.fields) {
      if (field.name.text == name) {
        return field;
      }
    }
    throw StateError('PointCut runtime is missing field "$name".');
  }

  /// PointCut fields/constructor read at every woven site. The runtime class is
  /// fixed for the whole pass, so these are resolved ONCE (lazily) and cached,
  /// rather than re-scanning `pointCutClass.fields` at each callsite. The cache
  /// is cleared by the [pointCutProceedProcedure] setter each pass.
  static Field get pointCutPositionalParamsField =>
      _pcPositionalParamsField ??= _pointCutFieldNamed('positionalParams');
  static Field get pointCutNamedParamsField =>
      _pcNamedParamsField ??= _pointCutFieldNamed('namedParams');
  static Field get pointCutTargetField =>
      _pcTargetField ??= _pointCutFieldNamed('target');
  static Constructor get pointCutConstructor =>
      _pcConstructor ??= pointCutClass.constructors.first;
  static Procedure? listGetProcedure;
  static Procedure? mapGetProcedure;
  static Component? platformStrongComponent;

  /// Crash-safety reporter for the current transform pass. Set by the
  /// orchestrator at the start of each pass. Rewriters report skips/errors here
  /// instead of throwing. (M5 will move this into a per-transform context.)
  static AopDiagnosticReporter? diagnostics;

  static Library? coreLib;

  static AopMode? getAopModeByNameAndImportUri(String name, String importUri) {
    if (name == kAopAnnotationClassCall && importUri == kImportUriAopCall) {
      return AopMode.call;
    }
    if (name == kAopAnnotationClassExecute &&
        importUri == kImportUriAopExecute) {
      return AopMode.execute;
    }
    if (name == kAopAnnotationClassInject && importUri == kImportUriAopInject) {
      return AopMode.inject;
    }
    if (name == kAopAnnotationClassAdd && importUri == kImportUriAopAdd) {
      return AopMode.add;
    }

    if (name == kAopAnnotationFieldGetInitializer &&
        importUri == kImportUriAopFieldGet) {
      return AopMode.fieldGet;
    }

    return null;
  }

  /// Resolves the AOP mode of an [annotation] expression, or null if it is not
  /// an AOPD annotation. Detects the annotation's class/library via canonical
  /// name (with a resolved-node fallback, since canonical names are unbound
  /// during the modular-transform phase). Used to recognise AOP annotations
  /// without fully parsing them -- e.g. to forbid stacking several on one
  /// member (#13).
  static AopMode? resolveAnnotationAopMode(
    Expression annotation,
    Map<String, Library> componentLibraryMap,
  ) {
    String? clsName;
    String? libName;
    if (annotation is ConstantExpression) {
      final Constant constant = annotation.constant;
      if (constant is! InstanceConstant) {
        return null;
      }
      final CanonicalName? cn = constant.classReference.canonicalName;
      final AopKernelResolver resolver = AopKernelResolver(componentLibraryMap);
      constant.classReference.node ??= resolver.resolve(cn);
      final TreeNode? node = constant.classReference.node;
      if (node is Class) {
        clsName = node.name;
        libName = (node.parent as Library?)?.importUri.toString();
      }
      clsName ??= AopKernelResolver.memberNameOf(cn);
      libName ??= resolver.libraryImportUriOf(cn);
    } else if (annotation is ConstructorInvocation) {
      final Class? cls = annotation.targetReference.node?.parent as Class?;
      final Library? lib = cls?.parent as Library?;
      clsName = cls?.name;
      libName = lib?.importUri.toString();
    } else {
      return null;
    }
    if (clsName == null || libName == null) {
      return null;
    }
    return getAopModeByNameAndImportUri(clsName, libName);
  }

  /// (#3) Validate that the advice method's static/instance form is compatible
  /// with the invocation the rewriter will generate: a `StaticInvocation`
  /// needs a static advice; a `new Aspect().advice(...)` needs an instance
  /// advice. A mismatch would emit invalid kernel (and could crash the VM on
  /// load). On mismatch this emits a diagnostic and returns false so the caller
  /// leaves the site un-woven (degrade but loud).
  static bool adviceFormMatches(
    AopItemInfo aopItemInfo, {
    required bool expectStatic,
  }) {
    final Procedure advice = aopItemInfo.requiredAdviceProcedure;
    if (advice.isStatic != expectStatic) {
      diagnostics?.unsupported(
        aopItemInfo,
        'advice "${advice.name.text}" must be '
        '${expectStatic ? 'a static' : 'an instance'} method for this '
        'pointcut (the generated call is '
        '${expectStatic ? 'static' : 'on a new aspect instance'}); got '
        '${advice.isStatic ? 'static' : 'instance'}. Skipping this site.',
      );
      return false;
    }
    return true;
  }

  /// (#3) Instance advice is invoked via `new Aspect()` using
  /// `aspectClass.constructors.first`. Verify that constructor is callable with
  /// no arguments; otherwise the generated ConstructorInvocation would be
  /// invalid kernel. Emits a diagnostic and returns false on mismatch.
  static bool adviceClassConstructable(AopItemInfo aopItemInfo) {
    final Class? aspectClass = aopItemInfo.requiredAopMember.enclosingClass;
    if (aspectClass == null) {
      return true; // non-class advice is handled by other guards
    }
    if (aspectClass.constructors.isEmpty) {
      diagnostics?.unsupported(
        aopItemInfo,
        'aspect class "${aspectClass.name}" has no usable constructor for '
        'instance advice; skipping this site.',
      );
      return false;
    }
    final FunctionNode fn = aspectClass.constructors.first.function;
    final bool noArgs =
        fn.requiredParameterCount == 0 &&
        !fn.namedParameters.any((VariableDeclaration p) => p.isRequired);
    if (!noArgs) {
      diagnostics?.unsupported(
        aopItemInfo,
        'aspect class "${aspectClass.name}" must have a no-argument '
        'constructor for instance advice; its first constructor requires '
        'arguments. Skipping this site.',
      );
      return false;
    }
    return true;
  }

  /// (#27) Order aspect items into a stable, reproducible sequence (C) and emit
  /// a loud diagnostic for exact-target conflicts (B) -- two or more aspects
  /// from different advice methods targeting the same join point.
  ///
  /// Determinism (C): sorting by a stable aspect key makes "@Call last-wins" /
  /// "@Execute stacking" / "@Add first-wins" reproducible across builds,
  /// independent of library/member traversal order.
  ///
  /// Conflict reporting (B): exact (non-regex) target collisions within a mode
  /// are reported once. Regex-target overlaps are NOT statically determinable
  /// and are not reported here (documented limitation).
  static void sortAndReportConflicts(List<AopItemInfo> items) {
    String aspectKey(AopItemInfo i) {
      final Member m = i.requiredAopMember;
      final String lib = m.enclosingLibrary.importUri.toString();
      final String cls = m.enclosingClass?.name ?? '';
      return '$lib::$cls::${m.name.text}::${m.fileOffset}';
    }

    String targetMemberName(AopItemInfo i) {
      switch (i.mode) {
        case AopMode.call:
        case AopMode.execute:
        case AopMode.inject:
          return i.requiredMethodName;
        case AopMode.fieldGet:
          return i.requiredFieldName;
        case AopMode.add:
          return '';
      }
    }

    bool targetIsStatic(AopItemInfo i) {
      switch (i.mode) {
        case AopMode.call:
        case AopMode.execute:
        case AopMode.inject:
        case AopMode.fieldGet:
          return i.requiredIsStatic;
        case AopMode.add:
          return false;
      }
    }

    items.sort(
      (AopItemInfo a, AopItemInfo b) => aspectKey(a).compareTo(aspectKey(b)),
    );

    final Map<String, List<AopItemInfo>> groups = <String, List<AopItemInfo>>{};
    for (final AopItemInfo i in items) {
      if (i.isRegex) {
        continue; // regex overlap is not statically determinable
      }
      final String target =
          '${i.mode.name}|${i.importUri}|${i.clsName}|'
          '${targetMemberName(i)}|${targetIsStatic(i)}';
      groups.putIfAbsent(target, () => <AopItemInfo>[]).add(i);
    }

    groups.forEach((String _, List<AopItemInfo> group) {
      if (group.length < 2) {
        return;
      }
      final AopMode mode = group.first.mode;
      final String aspects = group
          .map((AopItemInfo i) => aspectKey(i))
          .join(', ');
      String detail;
      switch (mode) {
        case AopMode.call:
        case AopMode.fieldGet:
          detail = 'last-wins: only ${aspectKey(group.last)} takes effect';
          break;
        case AopMode.execute:
          detail = 'stacked (wrapped) in this order';
          break;
        case AopMode.add:
          detail = 'first-wins: only ${aspectKey(group.first)} is added';
          break;
        case AopMode.inject:
          detail = 'all applied in this order';
          break;
      }
      final String targetName =
          '${group.first.clsName}.${targetMemberName(group.first)}';
      diagnostics?.warning(
        group.first,
        '${group.length} @${mode.name} aspects target the same $targetName '
        '($aspects) -- $detail.',
      );
    });
  }

  /// Returns the first invalid regular-expression pattern among [patterns], or
  /// null if all (non-empty) patterns compile. Used to validate `isRegex`
  /// annotation fields up front so a bad pattern is skipped with a diagnostic
  /// instead of throwing a [FormatException] mid-transform.
  static String? firstInvalidRegex(List<String?> patterns) {
    for (final String? pattern in patterns) {
      if (pattern == null || pattern.isEmpty) {
        continue;
      }
      try {
        RegExp(pattern);
      } on FormatException {
        return pattern;
      }
    }
    return null;
  }

  //Generic Operation
  static void insertLibraryDependency(Library library, Library dependLibrary) {
    for (LibraryDependency dependency in library.dependencies) {
      if (dependency.importedLibraryReference.node == dependLibrary) {
        return;
      }
    }
    library.dependencies.add(LibraryDependency.import(dependLibrary));
  }

  static int getLineStartNumForStatement(Source source, Statement statement) {
    int fileOffset = statement.fileOffset;
    if (fileOffset == -1) {
      if (statement is ExpressionStatement) {
        final ExpressionStatement expressionStatement = statement;
        fileOffset = expressionStatement.expression.fileOffset;
      } else if (statement is AssertStatement) {
        final AssertStatement assertStatement = statement;
        fileOffset = assertStatement.conditionStartOffset;
      } else if (statement is LabeledStatement) {
        fileOffset = statement.body.fileOffset;
      }
    }
    return getLineNumBySourceAndOffset(source, fileOffset);
  }

  static int getLineStartNumForInitializer(
    Source source,
    Initializer initializer,
  ) {
    int fileOffset = initializer.fileOffset;
    if (fileOffset == -1) {
      if (initializer is AssertInitializer) {
        fileOffset = initializer.statement.conditionStartOffset;
      }
    }
    return getLineNumBySourceAndOffset(source, fileOffset);
  }

  static int getLineNumBySourceAndOffset(Source source, int fileOffset) {
    // Binary search over the sorted lineStarts (M4.2): returns the largest
    // index whose lineStart <= fileOffset, or -1 when fileOffset is before the
    // first line start (e.g. a synthetic -1 offset). Preserves the exact
    // semantics of the previous linear scan.
    final List<int>? lineStarts = source.lineStarts;
    if (lineStarts == null || lineStarts.isEmpty) {
      return -1;
    }
    if (fileOffset < lineStarts[0]) {
      return -1;
    }
    int lo = 0;
    int hi = lineStarts.length - 1;
    while (lo < hi) {
      final int mid = (lo + hi + 1) >> 1;
      if (lineStarts[mid] <= fileOffset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  /// Cache of UTF-8-decoded source text, keyed by the [Source] object (#26).
  /// The marker checks below previously re-decoded the ENTIRE file on every
  /// call; inject-heavy projects paid that O(file) cost repeatedly. Keyed by
  /// the Source instance so entries are GC'd once a compile's component is
  /// dropped (no cross-compile leak).
  static final Expando<String> _decodedSourceCache = Expando<String>();

  /// Returns the UTF-8-decoded text of [source], decoding once then caching.
  static String decodedSource(Source source) => _decodedSourceCache[source] ??=
      const Utf8Decoder().convert(source.source);

  static VariableDeclaration? checkIfSkipableVarDeclaration(
    Source source,
    Statement statement,
  ) {
    if (statement is VariableDeclaration) {
      final VariableDeclaration variableDeclaration = statement;

      final int lineNum = AopUtils.getLineNumBySourceAndOffset(
        source,
        variableDeclaration.fileOffset,
      );
      if (lineNum == -1) {
        return null;
      }
      final int charFrom = source.lineStarts![lineNum];

      int charTo = source.source.length;
      if (lineNum < source.lineStarts!.length - 1) {
        charTo = source.lineStarts![lineNum + 1];
      }
      final String sourceString = decodedSource(source);
      final String sourceLine = sourceString.substring(charFrom, charTo);
      if (lineEndsWithMarker(
        sourceLine,
        AopUtils.kAopPointcutIgnoreVariableDeclaration,
      )) {
        return variableDeclaration;
      }
    }
    return null;
  }

  static bool? checkIfReplaceThisUsage(Source source, Statement statement) {
    final int lineNum = AopUtils.getLineNumBySourceAndOffset(
      source,
      statement.fileOffset,
    );
    if (lineNum == -1) {
      return null;
    }
    final int charFrom = source.lineStarts![lineNum];

    int charTo = source.source.length;
    if (lineNum < source.lineStarts!.length - 1) {
      charTo = source.lineStarts![lineNum + 1];
    }
    final String sourceString = decodedSource(source);
    final String sourceLine = sourceString.substring(charFrom, charTo);
    if (lineEndsWithMarker(sourceLine, AopUtils.kAopPointcutReplaceThisUsage)) {
      return true;
    }
    return false;
  }

  static bool lineEndsWithMarker(String sourceLine, String marker) {
    // Match the marker at end-of-line, tolerating trailing whitespace and line
    // endings (notably CRLF "\r\n" on Windows). The previous implementation
    // only handled bare "\n", so markers silently failed on CRLF sources.
    return sourceLine.trimRight().endsWith(marker);
  }

  static Class? findClassOfNode(TreeNode node) {
    TreeNode? temp = node;
    while (temp != null && temp is! Class) {
      temp = temp.parent;
    }
    // No enclosing class (e.g. a call site in a top-level function or field
    // initializer). Return null instead of crashing with `null as Class`; the
    // caller must tolerate a null caller-class context.
    return temp is Class ? temp : null;
  }

  static Field? findFieldForClassWithName(Class cls, String fieldName) {
    for (Field field in cls.fields) {
      if (field.name.text == fieldName) {
        return field;
      }
    }
    return null;
  }

  static bool isAsyncFunctionNode(FunctionNode functionNode) {
    return functionNode.dartAsyncMarker == AsyncMarker.Async ||
        functionNode.dartAsyncMarker == AsyncMarker.AsyncStar;
  }

  static Node? getNodeToVisitRecursively(Object statement) {
    if (statement is FunctionDeclaration) {
      return statement.function;
    }
    if (statement is LabeledStatement) {
      return statement.body;
    }
    if (statement is IfStatement) {
      return statement.then;
    }
    if (statement is ForInStatement) {
      return statement.body;
    }
    if (statement is ForStatement) {
      return statement.body;
    }
    return null;
  }

  static void concatArgumentsForAopMethod(
    Map<String, String> sourceInfo,
    Arguments redirectArguments,
    String stubKey,
    Expression targetExpression,
    Member member,
    Arguments invocationArguments,
    Class? currentClass, {
    bool allowThisFallbackToMemberParent = true,
    Expression? proceedClosure,
  }) {
    // Build the PointCut constructor payload consumed by call/execute advice.
    final Arguments pointCutConstructorArguments = Arguments.empty();
    final List<MapLiteralEntry> sourceInfos = <MapLiteralEntry>[];

    sourceInfo.forEach((String key, String value) {
      sourceInfos.add(
        MapLiteralEntry(StringLiteral(key), StringLiteral(value)),
      );
    });

    pointCutConstructorArguments.positional.add(MapLiteral(sourceInfos));
    pointCutConstructorArguments.positional.add(targetExpression);
    String? memberName = member.name.text;
    if (member is Constructor) {
      memberName = AopUtils.nameForConstructor(member);
    }
    pointCutConstructorArguments.positional.add(StringLiteral(memberName));
    pointCutConstructorArguments.positional.add(StringLiteral(stubKey));
    pointCutConstructorArguments.positional.add(
      ListLiteral(invocationArguments.positional),
    );
    final List<MapLiteralEntry> entries = <MapLiteralEntry>[];
    for (NamedExpression namedExpression in invocationArguments.named) {
      entries.add(
        MapLiteralEntry(
          StringLiteral(namedExpression.name),
          namedExpression.value,
        ),
      );
    }
    pointCutConstructorArguments.positional.add(MapLiteral(entries));

    Class? clz;
    // The member/annotation snapshot is built via `this.field`. That is only
    // valid when the generated PointCut expression runs with a `this` in scope:
    //   * execute mode: the woven body replaces the target method body, so
    //     `this` is the target instance -> fall back to member.parent is OK
    //     (allowThisFallbackToMemberParent == true).
    //   * call mode at a top-level call site (currentClass == null): there is
    //     NO `this`, so synthesizing this.field would be invalid kernel. Call
    //     sites pass allowThisFallbackToMemberParent: false -> members null.
    if (currentClass == null &&
        allowThisFallbackToMemberParent &&
        member.parent is Class) {
      clz = member.parent as Class;
    } else {
      clz = currentClass;
    }

    //Get annotations and members in call/execute mode
    if (clz != null) {
      final ThisExpression thisE = ThisExpression();
      final List<MapLiteralEntry> filedsMap = <MapLiteralEntry>[];

      final List<Field> fields = clz.fields;

      for (Field f in fields) {
        NamedExpression ne;

        if (f.isConst) {
          // A const field's initializer is a ConstantExpression after constant
          // evaluation (AOP runs in phase 3). CLONE it before adding it to the
          // members map: reusing the node would re-parent the Field's own
          // initializer into this MapLiteral, and weaving the same field at two
          // sites would put one node in two trees (invalid kernel). A null
          // initializer (external const) and BasicLiteral consts are skipped.
          final Expression? initializer = f.initializer;
          if (initializer != null && initializer is! BasicLiteral) {
            filedsMap.add(
              MapLiteralEntry(
                StringLiteral(f.name.text),
                CloneVisitorNotMembers().clone(initializer),
              ),
            );
          }
        } else if (f.isStatic) {
          final StaticGet staticGet = StaticGet(f);
          ne = NamedExpression(f.name.text, staticGet);
          filedsMap.add(MapLiteralEntry(StringLiteral(f.name.text), ne.value));
        } else {
          // Use `f.name` directly (instead of constructing a new Name with the
          // caller class' library) so that private fields keep the correct
          // defining library reference. Otherwise accessing private members
          // such as `_pendingPointerEvents` on a mixin-applied class fails
          // with NoSuchMethodError at runtime.
          final InstanceGet property = InstanceGet(
            InstanceAccessKind.Instance,
            thisE,
            f.name,
            interfaceTarget: f,
            resultType: f.type,
          );
          final NamedExpression ne = NamedExpression(f.name.text, property);
          filedsMap.add(MapLiteralEntry(StringLiteral(f.name.text), ne.value));
        }
      }

      if (member is Procedure && member.isStatic) {
        pointCutConstructorArguments.positional.add(NullLiteral());
      } else {
        pointCutConstructorArguments.positional.add(MapLiteral(filedsMap));
      }

      //Get annotations of caller
      final List<Expression> annotations = clz.annotations;
      final List<MapLiteralEntry> annotationMap = <MapLiteralEntry>[];

      for (Expression annotation in annotations) {
        if (annotation is ConstantExpression) {
          final ConstantExpression constantExpression = annotation;
          final Constant constant = constantExpression.constant;

          if (constant is InstanceConstant) {
            final InstanceConstant instanceConstant = constant;
            final Map<Reference, Constant> vals = instanceConstant.fieldValues;

            final List<MapLiteralEntry> annotationParams = <MapLiteralEntry>[];

            vals.forEach((Reference ref, Constant val) {
              final ConstantExpression exp = ConstantExpression(val);
              String refName = ref.canonicalName?.name ?? '';
              if (refName.isEmpty) {
                final NamedNode? n = ref.node;
                if (n is Field) {
                  refName = n.name.text;
                }
              }
              annotationParams.add(
                MapLiteralEntry(StringLiteral(refName), exp),
              );
            });

            String annoName =
                instanceConstant.classReference.canonicalName?.name ?? '';
            if (annoName.isEmpty) {
              final TreeNode? n = instanceConstant.classReference.node;
              if (n is Class) {
                annoName = n.name;
              }
            }
            annotationMap.add(
              MapLiteralEntry(
                StringLiteral(annoName),
                MapLiteral(annotationParams),
              ),
            );
          }
        } else if (annotation is ConstructorInvocation) {
          // Older SDKs may lower annotations to InstanceConstant earlier.
        }
      }

      pointCutConstructorArguments.positional.add(MapLiteral(annotationMap));
    } else {
      pointCutConstructorArguments.positional.add(NullLiteral());
      pointCutConstructorArguments.positional.add(NullLiteral());
    }

    // M5.4: when a decentralized proceed closure is supplied, attach it as the
    // `proceedClosure` named argument so PointCut.proceed() can call the
    // original directly -- no central stubKey-dispatch branch is generated.
    if (proceedClosure != null) {
      pointCutConstructorArguments.named.add(
        NamedExpression('proceedClosure', proceedClosure),
      );
    }
    final ConstructorInvocation pointCutConstructorInvocation =
        ConstructorInvocation(
          pointCutConstructor,
          pointCutConstructorArguments,
        );
    redirectArguments.positional.add(pointCutConstructorInvocation);
  }

  static Arguments concatArguments4PointcutStubCall(
    Member member,
    AopItemInfo aopItemInfo, {
    VariableDeclaration? pointCutParam,
  }) {
    // The generated arguments read each value from the PointCut's
    // positionalParams/namedParams so advice can mutate them before proceed.
    // Legacy (centralized) stubs are methods ON PointCut, so the receiver is
    // `this`. Decentralized closures (M5.4) receive the PointCut as a parameter
    // [pointCutParam], so reads go through `pointCutParam` instead of `this`.
    Expression pointCutReceiver() =>
        pointCutParam != null ? VariableGet(pointCutParam) : ThisExpression();
    final Arguments arguments = Arguments.empty();
    int i = 0;

    final Field positionalParamsField = pointCutPositionalParamsField;
    final Field namedParams = pointCutNamedParamsField;

    for (VariableDeclaration variableDeclaration
        in member.function!.positionalParameters) {
      final Arguments getArguments = Arguments.empty();
      getArguments.positional.add(IntLiteral(i));

      final DynamicInvocation methodInvocation = DynamicInvocation(
        DynamicAccessKind.Dynamic,
        InstanceGet(
          InstanceAccessKind.Instance,
          pointCutReceiver(),
          Name('positionalParams'),
          resultType: positionalParamsField.getterType,
          interfaceTarget: positionalParamsField,
        ),
        listGetProcedure!.name,
        getArguments,
      );

      final AsExpression asExpression = AsExpression(
        methodInvocation,
        deepCopyASTNode(variableDeclaration.type, ignoreGenerics: true),
      );
      arguments.positional.add(asExpression);
      i++;
    }
    final List<NamedExpression> namedEntries = <NamedExpression>[];

    for (VariableDeclaration variableDeclaration
        in member.function!.namedParameters) {
      final Arguments getArguments = Arguments.empty();
      getArguments.positional.add(StringLiteral(variableDeclaration.name!));

      final DynamicInvocation methodInvocation = DynamicInvocation(
        DynamicAccessKind.Dynamic,
        InstanceGet(
          InstanceAccessKind.Instance,
          pointCutReceiver(),
          Name('namedParams'),
          interfaceTarget: namedParams,
          resultType: namedParams.getterType,
        ),
        mapGetProcedure!.name,
        getArguments,
      );

      final AsExpression asExpression = AsExpression(
        methodInvocation,
        deepCopyASTNode(variableDeclaration.type, ignoreGenerics: true),
      );
      namedEntries.add(
        NamedExpression(variableDeclaration.name!, asExpression),
      );
    }
    if (namedEntries.isNotEmpty) {
      arguments.named.addAll(namedEntries);
    }

    return arguments;
  }

  /// M5.4: build a decentralized `proceedClosure` `(PointCut pc) { ... }`.
  ///
  /// [buildInvocation] receives the closure's PointCut parameter and the
  /// argument list (already wired to read `pc.positionalParams`/`namedParams`
  /// via [concatArguments4PointcutStubCall]) and returns the expression that
  /// performs the original operation. This replaces the legacy `aop_stub_N`
  /// method + central proceed() branch, making each woven site self-contained
  /// (incremental/hot-reload safe).
  static int _proceedClosureSeq = 0;

  /// Hoisted proceed functions, queued for insertion into their host library.
  ///
  /// They are NOT added during the call/execute rewrite: the rewriters visit a
  /// library's members in place, so a procedure added mid-visit would be
  /// re-visited and its proceed invocation re-woven, recursing forever. They
  /// are flushed by [flushDeferredProceedProcedures] once the whole AOP
  /// transform has finished, before serialization.
  static final List<MapEntry<Library, Procedure>> _deferredProceedProcedures =
      <MapEntry<Library, Procedure>>[];

  /// Starts a new AOP transform pass.
  ///
  /// A previous pass can abort after queuing proceed functions but before they
  /// are inserted. Drop those stale procedures before this pass starts; they
  /// belong to a different component and must never be flushed into the next
  /// resident/incremental compile. The name sequence intentionally remains
  /// monotonic for the lifetime of the resident compiler to avoid colliding
  /// with synthetic procedures already added to a reused component.
  static void beginProceedClosurePass() {
    _deferredProceedProcedures.clear();
  }

  /// Inserts every queued proceed function into its host library and clears the
  /// queue. Call once after all AOP rewriters have run.
  static void flushDeferredProceedProcedures() {
    for (final MapEntry<Library, Procedure> entry
        in _deferredProceedProcedures) {
      entry.key.addProcedure(entry.value);
    }
    _deferredProceedProcedures.clear();
  }

  static Expression buildProceedClosure(
    Member originalMember,
    AopItemInfo aopItemInfo, {
    required bool shouldReturn,
    required int closureFileOffset,
    required Library hostLibrary,
    required Expression Function(
      VariableDeclaration pcParam,
      Arguments stubArgs,
    )
    buildInvocation,
  }) {
    final Class pointCutClass = pointCutProceedProcedure!.parent as Class;
    final VariableDeclaration pcParam = VariableDeclaration(
      'pc',
      type: InterfaceType(pointCutClass, Nullability.nonNullable),
    );
    final Arguments stubArgs = concatArguments4PointcutStubCall(
      originalMember,
      aopItemInfo,
      pointCutParam: pcParam,
    );
    final Expression invocation = buildInvocation(pcParam, stubArgs);
    final Block body = Block(<Statement>[
      if (shouldReturn) ReturnStatement(invocation),
      if (!shouldReturn) ...<Statement>[
        ExpressionStatement(invocation),
        ReturnStatement(NullLiteral()),
      ],
    ]);
    final FunctionNode functionNode = FunctionNode(
      body,
      positionalParameters: <VariableDeclaration>[pcParam],
      returnType: const DynamicType(),
    );

    // Hoist each proceed body to a UNIQUE top-level static function and pass a
    // tear-off as the proceed handler, rather than an inline anonymous closure.
    //
    // An anonymous `(PointCut) => ...` proceed closure captures nothing, so it
    // is effectively a constant function. When one enclosing member weaves
    // several @Call sites, Dart 3.12's VM collapses the sibling no-capture
    // closures onto the first one -- so every `proceed()` ran the FIRST site's
    // body (an int/String cast crash in mixed-signature matrices). Attempts to
    // keep them distinct as named local functions or forced captures are folded
    // back to anonymous closures by the kernel optimizer. A top-level function
    // has a stable, unique canonical identity that survives those passes and is
    // never merged. (Single-closure @Execute sites never collided, but routing
    // them through the same hoist is equally correct and keeps one code path.)
    //
    // The procedure is queued (see [_deferredProceedProcedures]) and inserted
    // only after the whole transform finishes, so the in-place rewriters never
    // re-visit it.
    final Procedure proceedProcedure = Procedure(
      Name('_aopProceed\$${_proceedClosureSeq++}', hostLibrary),
      ProcedureKind.Method,
      functionNode,
      isStatic: true,
      fileUri: hostLibrary.fileUri,
    );
    proceedProcedure.fileOffset = closureFileOffset;
    proceedProcedure.fileStartOffset = closureFileOffset;
    proceedProcedure.fileEndOffset = closureFileOffset;
    // Synthetic bodies have no source offsets; backfill so the kernel verifier
    // (afterModularTransformations) accepts them.
    setMissingFileOffsets(functionNode, closureFileOffset);
    _deferredProceedProcedures.add(
      MapEntry<Library, Procedure>(hostLibrary, proceedProcedure),
    );

    // Post constant-evaluation, a static tear-off must be a constant rather
    // than a raw `StaticTearOff` expression (the VM rejects the bare node with
    // "Unexpected tag 17 (StaticTearOff)"). Wrap it accordingly.
    return ConstantExpression(
      StaticTearOffConstant(proceedProcedure),
      functionNode.computeFunctionType(Nullability.nonNullable),
    )..fileOffset = closureFileOffset;
  }

  /// Read `(pc.target as [castClass])` for instance-mode proceed closures.
  static Expression pointCutTargetCast(
    VariableDeclaration pcParam,
    Class castClass,
  ) {
    final Field targetField = pointCutTargetField;
    return AsExpression(
      InstanceGet(
        InstanceAccessKind.Instance,
        VariableGet(pcParam),
        Name('target'),
        resultType: targetField.type,
        interfaceTarget: targetField,
      ),
      InterfaceType(castClass, Nullability.nonNullable),
    );
  }

  /// M5.4: execute-mode proceed closure invoking the moved-out [originalStub].
  static Expression buildExecuteProceedClosure(
    AopItemInfo aopItemInfo,
    Procedure originalStub,
    Member originalMember, {
    required bool shouldReturn,
    required bool isInstance,
    Class? instanceClass,
  }) {
    return buildProceedClosure(
      originalMember,
      aopItemInfo,
      shouldReturn: shouldReturn,
      // The @Execute proceed body is hoisted into the woven member's own
      // library, alongside the moved-out stub it invokes.
      closureFileOffset: originalMember.fileOffset,
      hostLibrary: originalMember.enclosingLibrary,
      buildInvocation: (VariableDeclaration pcParam, Arguments args) {
        if (isInstance) {
          return DynamicInvocation(
            DynamicAccessKind.Dynamic,
            pointCutTargetCast(pcParam, instanceClass!),
            originalStub.name,
            args,
          );
        }
        return StaticInvocation(originalStub, args);
      },
    );
  }

  /// Whether [library] belongs to the Dart/Flutter SDK for the purpose of
  /// `excludeCoreLib`. Matches the documented semantics ("Dart and Flutter SDK
  /// libraries"): both `dart:` and `package:flutter/`. (M4.5)
  static bool isExcludedCoreLibrary(Library library) {
    final String uri = library.importUri.toString();
    return uri.startsWith('dart:') || uri.startsWith('package:flutter/');
  }

  static bool canOperateLibrary(Library library) {
    if (platformStrongComponent != null &&
        platformStrongComponent!.libraries.contains(library)) {
      return false;
    }
    return true;
  }

  static Block createProcedureBodyWithExpression(
    Expression expression,
    bool shouldReturn,
  ) {
    final Block bodyStatements = Block(<Statement>[]);
    if (shouldReturn) {
      bodyStatements.addStatement(ReturnStatement(expression));
    } else {
      bodyStatements.addStatement(ExpressionStatement(expression));
    }

    return bodyStatements;
  }

  // Skip AOP operations in the aspect library itself.
  static bool checkIfSkipAOP(AopItemInfo aopItemInfo, Library curLibrary) {
    final Library aopLibrary1 = aopItemInfo.adviceLibrary;
    final Library aopLibrary2 =
        pointCutProceedProcedure!.parent!.parent as Library;
    if (curLibrary == aopLibrary1 || curLibrary == aopLibrary2) {
      return true;
    }
    return false;
  }

  static bool checkIfClassEnableAop(List<Expression> annotations) {
    bool enabled = false;
    for (Expression annotation in annotations) {
      //Release Mode
      if (annotation is ConstantExpression) {
        final ConstantExpression constantExpression = annotation;
        final Constant constant = constantExpression.constant;
        if (constant is InstanceConstant) {
          final InstanceConstant instanceConstant = constant;
          final CanonicalName? canonicalName =
              instanceConstant.classReference.canonicalName;
          // Canonical names may be cleared after constant evaluation; fall
          // back to the resolved class node when needed.
          String? annotationClsName;
          String? annotationLibName;
          final TreeNode? node = instanceConstant.classReference.node;
          if (node is Class) {
            annotationClsName = node.name;
            final Library? lib = node.parent as Library?;
            annotationLibName = lib?.importUri.toString();
          }
          annotationClsName ??= AopKernelResolver.memberNameOf(canonicalName);
          annotationLibName ??= AopKernelResolver.libraryNameOf(canonicalName);
          if (annotationClsName == AopUtils.kAopAnnotationClassAspect &&
              annotationLibName == AopUtils.kImportUriAopAspect) {
            enabled = true;
            break;
          }
        }
      }
      //Debug Mode
      else if (annotation is ConstructorInvocation) {
        final ConstructorInvocation constructorInvocation = annotation;
        final Class? cls =
            constructorInvocation.targetReference.node?.parent as Class?;
        if (cls == null) {
          continue;
        }
        final Library? library = cls.parent as Library?;
        if (library == null) {
          continue;
        }
        if (cls.name == AopUtils.kAopAnnotationClassAspect &&
            library.importUri.toString() == AopUtils.kImportUriAopAspect) {
          enabled = true;
          break;
        }
      }
    }
    return enabled;
  }

  static Map<String, String> calcSourceInfo(
    Map<Uri, Source> uriToSource,
    Library library,
    int fileOffset,
  ) {
    final Map<String, String> sourceInfo = <String, String>{};
    String importUri = library.importUri.toString();
    final int idx = importUri.lastIndexOf('/');
    if (idx != -1) {
      importUri = importUri.substring(0, idx);
    }
    final Uri fileUri = library.fileUri;
    final Source source = uriToSource[fileUri]!;
    // #26: binary search instead of a linear scan over lineStarts. Also avoids
    // the previous `late lineOffSet` that was left unassigned (and would throw)
    // when fileOffset preceded the first line start.
    final int lineNum = getLineNumBySourceAndOffset(source, fileOffset);
    final int lineOffSet = lineNum >= 0
        ? fileOffset - source.lineStarts![lineNum]
        : 0;

    sourceInfo.putIfAbsent('importUri', () => library.importUri.toString());
    sourceInfo.putIfAbsent('library', () => importUri);
    sourceInfo.putIfAbsent('file', () => fileUri.toString());
    sourceInfo.putIfAbsent('lineNum', () => '${lineNum + 1}');
    sourceInfo.putIfAbsent('lineOffset', () => '$lineOffSet');

    return sourceInfo;
  }

  /// Builds a [CloneVisitorNotMembers] whose `typeSubstitution` erases [fn]'s
  /// OWN generic type parameters to `dynamic`.
  ///
  /// AOPD never carries generics onto woven stubs / added methods: the proceed
  /// closure invokes a moved stub via a `StaticInvocation` / `DynamicInvocation`
  /// with NO type arguments, and arguments are read back from the PointCut's
  /// `positionalParams`/`namedParams` (typed `List`/`Map<dynamic>`). A generic
  /// stub would therefore produce invalid kernel. We clone only the body (never
  /// `visitFunctionNode` for the outer function), so `prepareTypeParameters`
  /// does not overwrite this substitution.
  static CloneVisitorNotMembers erasingCloner(FunctionNode fn) {
    return CloneVisitorNotMembers(
      typeSubstitution: <TypeParameter, DartType>{
        for (final TypeParameter tp in fn.typeParameters)
          tp: const DynamicType(),
      },
    );
  }

  /// Clones [params] into FRESH [VariableDeclaration]s via [cloner], registering
  /// each old->new mapping in the cloner's variable table so a body cloned with
  /// the SAME [cloner] remaps its `VariableGet`/`VariableSet` to the fresh
  /// declarations. This is what stops a single parameter node from being parented
  /// under two functions at once (the original method AND its stub).
  static List<VariableDeclaration> cloneParams(
    CloneVisitorNotMembers cloner,
    List<VariableDeclaration> params,
  ) {
    return <VariableDeclaration>[
      for (final VariableDeclaration p in params) cloner.clone(p),
    ];
  }

  /// Builds a self-contained [FunctionNode] for an execute stub: fresh
  /// parameters plus a clone of [fn]'s body whose variable references are
  /// remapped to those fresh parameters, with [fn]'s own generics erased to
  /// `dynamic`. The result shares NO AST nodes with [fn], so the original method
  /// keeps its own parameters for the advice-call body. Cloned body offsets are
  /// backfilled by the caller via [setMissingFileOffsets].
  static FunctionNode cloneFunctionForStub(
    FunctionNode fn, {
    required bool shouldReturn,
  }) {
    final CloneVisitorNotMembers cloner = erasingCloner(fn);
    final List<VariableDeclaration> positional = cloneParams(
      cloner,
      fn.positionalParameters,
    );
    final List<VariableDeclaration> named = cloneParams(
      cloner,
      fn.namedParameters,
    );
    final Statement? body = fn.body == null ? null : cloner.clone(fn.body!);
    return FunctionNode(
      body,
      positionalParameters: positional,
      namedParameters: named,
      requiredParameterCount: fn.requiredParameterCount,
      returnType: shouldReturn
          ? cloner.visitType(fn.returnType)
          : const VoidType(),
      asyncMarker: fn.asyncMarker,
      dartAsyncMarker: fn.dartAsyncMarker,
      // Preserve the async value type: the kernel verifier rejects an Async
      // function whose emittedValueType is null, and a normal build does NOT
      // run the verifier -- so an @Execute on an `async` method would emit
      // invalid kernel straight to the VM. Erase the function's own generics
      // to match the rest of the stub.
      emittedValueType: fn.emittedValueType == null
          ? null
          : cloner.visitType(fn.emittedValueType!),
    );
  }

  static Procedure createStubProcedure(
    Name methodName,
    AopItemInfo aopItemInfo,
    Procedure referProcedure,
    bool shouldReturn,
  ) {
    // Clone the reference function so the stub OWNS its parameters and a body
    // whose VariableGet/Set point to those fresh params -- never sharing nodes
    // with the original method (#4/#7). Must run before the caller replaces the
    // original method's body, while referProcedure.function.body is still intact.
    final FunctionNode functionNode = cloneFunctionForStub(
      referProcedure.function,
      shouldReturn: shouldReturn,
    );
    final Procedure procedure = Procedure(
      Name(methodName.text, methodName.library),
      ProcedureKind.Method,
      functionNode,
      isStatic: referProcedure.isStatic,
      fileUri: referProcedure.fileUri,
      stubKind: referProcedure.stubKind,
      stubTarget: referProcedure.stubTarget,
    );

    procedure.fileOffset = referProcedure.fileOffset;
    procedure.fileEndOffset = referProcedure.fileEndOffset;
    procedure.fileStartOffset = referProcedure.fileStartOffset;

    // Cloning a bare body loses file offsets (no active file uri); backfill so
    // the kernel verifier (afterModularTransformations) accepts the stub.
    setMissingFileOffsets(functionNode, referProcedure.fileOffset);

    return procedure;
  }

  static Constructor createStubConstructor(
    Name methodName,
    AopItemInfo aopItemInfo,
    Constructor referConstructor,
    bool shouldReturn,
  ) {
    // Same node-ownership guarantee as createStubProcedure (fresh params + body
    // clone). Constructor @Execute is currently unsupported (no caller), but the
    // helper is kept correct-by-construction for a future revival.
    final FunctionNode functionNode = cloneFunctionForStub(
      referConstructor.function,
      shouldReturn: shouldReturn,
    );
    final Constructor constructor = Constructor(
      functionNode,
      name: Name(methodName.text, methodName.library),
      isConst: referConstructor.isConst,
      isExternal: referConstructor.isExternal,
      isSynthetic: referConstructor.isSynthetic,
      initializers: deepCopyASTNodes(referConstructor.initializers),
      transformerFlags: referConstructor.transformerFlags,
      fileUri: referConstructor.fileUri,
      reference: Reference()..node = referConstructor.reference.node,
    );

    constructor.fileOffset = referConstructor.fileOffset;
    constructor.fileEndOffset = referConstructor.fileEndOffset;
    constructor.startFileOffset = referConstructor.startFileOffset;
    setMissingFileOffsets(functionNode, referConstructor.fileOffset);
    return constructor;
  }

  static dynamic deepCopyASTNode(
    dynamic node, {
    bool isReturnType = false,
    bool ignoreGenerics = false,
  }) {
    if (node is TypeParameter) {
      if (ignoreGenerics) {
        return TypeParameter(node.name, node.bound, node.defaultType);
      }
    }
    if (node is VariableDeclaration) {
      return VariableDeclaration(
        node.name,
        initializer: node.initializer,
        type: deepCopyASTNode(node.type),
        flags: node.flags,
        isFinal: node.isFinal,
        isConst: node.isConst,
        isLate: node.isLate,
        isRequired: node.isRequired,
        isLowered: node.isLowered,
      );
    }
    if (node is TypeParameterType) {
      if (isReturnType || ignoreGenerics) {
        return const DynamicType();
      }
      return TypeParameterType(
        deepCopyASTNode(node.parameter),
        deepCopyASTNode(node.declaredNullability),
      );
    }
    if (node is FunctionType) {
      return FunctionType(
        deepCopyASTNodes(node.positionalParameters),
        deepCopyASTNode(node.returnType, isReturnType: true),
        node.nullability,
        namedParameters: deepCopyASTNodes(node.namedParameters),
        typeParameters: deepCopyASTNodes(node.typeParameters),
        requiredParameterCount: node.requiredParameterCount,
      );
    }
    if (node is TypedefType) {
      return TypedefType(
        node.typedefNode,
        node.nullability,
        deepCopyASTNodes(node.typeArguments, ignoreGeneric: ignoreGenerics),
      );
    }
    return node;
  }

  static List<T> deepCopyASTNodes<T>(
    List<T> nodes, {
    bool ignoreGeneric = false,
  }) {
    final List<T> newNodes = <T>[];
    for (T node in nodes) {
      final dynamic newNode = deepCopyASTNode(
        node,
        ignoreGenerics: ignoreGeneric,
      );
      if (newNode != null) {
        newNodes.add(newNode);
      }
    }
    return newNodes;
  }

  static Arguments argumentsFromFunctionNode(FunctionNode functionNode) {
    return argumentsFromParams(
      functionNode.positionalParameters,
      functionNode.namedParameters,
    );
  }

  /// Builds an [Arguments] of `VariableGet`s reading [positionalParameters] /
  /// [namedParameters] directly. Lets a caller forward FRESH (cloned) parameters
  /// instead of the source method's nodes (see [cloneParams]).
  static Arguments argumentsFromParams(
    List<VariableDeclaration> positionalParameters,
    List<VariableDeclaration> namedParameters,
  ) {
    final List<Expression> positional = <Expression>[];
    final List<NamedExpression> named = <NamedExpression>[];
    for (VariableDeclaration variableDeclaration in positionalParameters) {
      positional.add(VariableGet(variableDeclaration));
    }
    for (VariableDeclaration variableDeclaration in namedParameters) {
      named.add(
        NamedExpression(
          variableDeclaration.name!,
          VariableGet(variableDeclaration),
        ),
      );
    }
    return Arguments(positional, named: named);
  }

  static String nameForConstructor(Constructor constructor) {
    final Class constructorCls = constructor.parent! as Class;
    String constructorName = constructorCls.name;
    if (constructor.name.text.isNotEmpty) {
      constructorName += '.${constructor.name.text}';
    }
    return constructorName;
  }

  static NamedNode? getNodeFromCanonicalName(
    Map<String, Library> libraryMap,
    CanonicalName? canonicalName,
  ) {
    return AopKernelResolver(libraryMap).resolve(canonicalName);
  }

  /// Builds a minimal-but-real `PointCut(...)` constructor invocation carrying
  /// only the always-safe context (sourceInfos + target). Used by FieldGet so
  /// advice receives a non-null `PointCut` (previously a bare `NullLiteral`,
  /// which crashed any advice that dereferenced it). members/annotations are
  /// left null on purpose: a field read has no caller `this` to snapshot, so we
  /// avoid synthesizing `this.field` (which would be invalid kernel at a static
  /// or top-level read site).
  static ConstructorInvocation buildMinimalPointCut(
    Map<String, String> sourceInfo,
    Expression target, {
    Expression? proceedClosure,
  }) {
    final Arguments arguments = Arguments.empty();
    final List<MapLiteralEntry> sourceInfos = <MapLiteralEntry>[];
    sourceInfo.forEach((String key, String value) {
      sourceInfos.add(
        MapLiteralEntry(StringLiteral(key), StringLiteral(value)),
      );
    });
    arguments.positional.add(MapLiteral(sourceInfos)); // sourceInfos
    arguments.positional.add(target); // target
    arguments.positional.add(StringLiteral('')); // function
    arguments.positional.add(StringLiteral('')); // stubKey
    arguments.positional.add(NullLiteral()); // positionalParams
    arguments.positional.add(NullLiteral()); // namedParams
    arguments.positional.add(NullLiteral()); // members
    arguments.positional.add(NullLiteral()); // annotations
    // M5.4: fieldGet supplies a closure so proceed() can return the original
    // field value (previously proceed() returned null for fieldGet).
    if (proceedClosure != null) {
      arguments.named.add(NamedExpression('proceedClosure', proceedClosure));
    }
    return ConstructorInvocation(pointCutConstructor, arguments);
  }

  static Class? classOfLib(Library lib, String className) {
    for (Class clazz in lib.classes) {
      if (clazz.name == className) {
        return clazz;
      }
    }
    return null;
  }

  static Procedure? procedureOfClass(Class clazz, String procedureName) {
    for (Procedure procedure in clazz.procedures) {
      if (procedure.name.text == procedureName) {
        return procedure;
      }
    }
    return null;
  }

  /// Backfills [offset] onto generated AST nodes under [node] that have no file
  /// offset, so AOPD's synthetic kernel passes the verifier
  /// (`afterModularTransformations` requires real offsets). Only nodes whose
  /// offset is [TreeNode.noOffset] are touched; real offsets on moved original
  /// code are preserved.
  static void setMissingFileOffsets(TreeNode node, int offset) {
    if (offset < 0) {
      return;
    }
    node.accept(_MissingOffsetSetter(offset));
  }
}

class AopKernelResolver {
  AopKernelResolver(this.libraryMap);

  final Map<String, Library> libraryMap;

  NamedNode? resolve(CanonicalName? canonicalName) {
    if (canonicalName == null) {
      return null;
    }
    final TreeNode? boundNode = canonicalName.reference.node;
    if (boundNode is NamedNode) {
      return boundNode;
    }

    final List<String> path = nonSymbolicPath(canonicalName);
    if (path.isEmpty) {
      return null;
    }

    // Missing libraries are expected for references outside the current
    // component. Leave them unresolved instead of aborting the transform.
    final Library? library = libraryMap[path.first];
    if (library == null || path.length == 1) {
      return library;
    }

    if (path.length == 2) {
      final bool underSymbolicBucket =
          canonicalName.parent?.name.startsWith('@') ?? false;
      if (underSymbolicBucket) {
        return _libraryChild(library, path[1]) ?? _class(library, path[1]);
      }
      return _class(library, path[1]) ?? _libraryChild(library, path[1]);
    }

    final Class? cls = _class(library, path[1]);
    if (cls == null || path.length == 2) {
      return cls;
    }
    return _classChild(cls, path[2]);
  }

  String? libraryImportUriOf(CanonicalName? canonicalName) {
    final Library? library = _libraryOf(resolve(canonicalName));
    return library?.importUri.toString() ?? libraryNameOf(canonicalName);
  }

  String? ownerClassNameOf(CanonicalName? canonicalName) {
    final NamedNode? node = resolve(canonicalName);
    if (node is Class) {
      return node.name;
    }
    final TreeNode? parent = node?.parent;
    if (parent is Class) {
      return parent.name;
    }
    final List<String> path = nonSymbolicPath(canonicalName);
    if (path.length >= 3) {
      return path[path.length - 2];
    }
    return null;
  }

  static String? libraryNameOf(CanonicalName? canonicalName) {
    final List<String> path = nonSymbolicPath(canonicalName);
    return path.isEmpty ? null : path.first;
  }

  static String? memberNameOf(CanonicalName? canonicalName) {
    final List<String> path = nonSymbolicPath(canonicalName);
    return path.isEmpty ? null : path.last;
  }

  static List<String> nonSymbolicPath(CanonicalName? canonicalName) {
    final List<String> path = <String>[];
    CanonicalName? current = canonicalName;
    while (current != null) {
      final CanonicalName? parent = current.parent;
      if (parent != null && !current.name.startsWith('@')) {
        path.insert(0, current.name);
      }
      current = parent;
    }
    return path;
  }

  Library? _libraryOf(NamedNode? node) {
    if (node is Library) {
      return node;
    }
    TreeNode? parent = node?.parent;
    while (parent != null) {
      if (parent is Library) {
        return parent;
      }
      parent = parent.parent;
    }
    return null;
  }

  Class? _class(Library library, String name) {
    for (final Class cls in library.classes) {
      if (cls.name == name) {
        return cls;
      }
    }
    return null;
  }

  NamedNode? _libraryChild(Library library, String name) {
    for (final Procedure procedure in library.procedures) {
      if (procedure.name.text == name) {
        return procedure;
      }
    }
    for (final Field field in library.fields) {
      if (field.name.text == name) {
        return field;
      }
    }
    return null;
  }

  NamedNode? _classChild(Class cls, String name) {
    for (final Procedure procedure in cls.procedures) {
      if (procedure.name.text == name) {
        return procedure;
      }
    }
    for (final Field field in cls.fields) {
      if (field.name.text == name) {
        return field;
      }
    }
    for (final Constructor constructor in cls.constructors) {
      if (constructor.name.text == name) {
        return constructor;
      }
    }
    return null;
  }
}

class _MissingOffsetSetter extends RecursiveVisitor {
  _MissingOffsetSetter(this.offset);

  final int offset;

  @override
  void defaultTreeNode(TreeNode node) {
    if (node.fileOffset == TreeNode.noOffset) {
      node.fileOffset = offset;
    }
    // `fileEndOffset` is a plain field (not a child TreeNode) carried by
    // FunctionNode/Block/etc., so it is never reached as part of the child
    // walk and synthetic AOP nodes leave it at `noOffset` (-1). The Dart 3.12
    // VM derives the source range of an enclosing member's nested functions
    // from these end offsets; several proceed closures that all report a
    // degenerate `[offset, -1]` range get dispatched off-by-one (a method that
    // weaves multiple @Call sites then runs the wrong proceed body). Backfill a
    // well-formed end offset for every synthetic node that carries one.
    if (node is FunctionNode && node.fileEndOffset == TreeNode.noOffset) {
      node.fileEndOffset = offset;
    } else if (node is Block && node.fileEndOffset == TreeNode.noOffset) {
      node.fileEndOffset = offset;
    }
    super.defaultTreeNode(node);
  }
}
