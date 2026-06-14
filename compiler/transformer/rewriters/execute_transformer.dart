// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'package:kernel/ast.dart';

import 'aop_item_info.dart';
import 'aop_transform_utils.dart';
//
// class AopStatementsInsertInfo {
//   AopStatementsInsertInfo(
//       {this.library,
//       this.source,
//       this.constructor,
//       this.procedure,
//       this.node,
//       this.aopItemInfo,
//       this.aopInsertStatements});
//
//   final Library library;
//   final Source source;
//   final Constructor constructor;
//   final Procedure procedure;
//   final Node node;
//   final AopItemInfo aopItemInfo;
//   final List<Statement> aopInsertStatements;
// }

class AopExecuteImplTransformer extends Transformer {
  AopExecuteImplTransformer(
    this._aopItemInfoList,
    this._libraryMap,
    this._uriToSource,
  );

  final List<AopItemInfo> _aopItemInfoList;
  final Map<String, Library> _libraryMap;
  final Map<Uri, Source> _uriToSource;

  Set<Library> _filterLibraryWithAopItemInfo(
    Map<String, Library> libraryMap,
    AopItemInfo aopItemInfo,
  ) {
    final Set<Library> filteredLibraries = <Library>{};
    if (aopItemInfo.isRegex) {
      for (String libraryName in libraryMap.keys) {
        if (aopItemInfo.importUriRegex.hasMatch(libraryName)) {
          filteredLibraries.add(libraryMap[libraryName]!);
        }
      }
    } else {
      final Library? library = libraryMap[aopItemInfo.importUri];
      if (library != null) {
        filteredLibraries.add(library);
      }
    }
    return filteredLibraries;
  }

  Member? _filterFirstMatchPatchClassMember(
    Map<String, Library> libraryMap,
    Member expectMember,
    AopItemInfo aopItemInfo,
  ) {
    // Member filteredMember;
    final Class expectedCls = expectMember.parent as Class;
    for (String importUri in libraryMap.keys) {
      final Library lib = libraryMap[importUri] as Library;
      if (lib != expectedCls.parent) {
        continue;
      }
      for (Class mightPatchCls in lib.classes) {
        bool matches = false;
        if (mightPatchCls.name == aopItemInfo.clsName) {
          matches = true;
        } else {
          for (
            int i = 0;
            i < mightPatchCls.implementedTypes.length && matches == false;
            i++
          ) {
            final Supertype supertype = mightPatchCls.implementedTypes[i];
            if (supertype.className.node == expectedCls &&
                mightPatchCls.parent == expectedCls.parent &&
                mightPatchCls.name == '_${expectedCls.name}') {
              matches = true;
            }
          }
        }
        if (matches) {
          for (Member member in mightPatchCls.members) {
            //Here, the patch member's body must be non-empty.
            if (member.name.text == expectMember.name.text &&
                member.function!.body != null) {
              return member;
            }
          }
        }
      }
    }
    return null;
  }

  Set<Procedure> _filterLibraryProcedureWithAopItemInfo(
    Library library,
    AopItemInfo aopItemInfo,
  ) {
    final Set<Procedure> filteredProcedures = <Procedure>{};
    //Check Procedures
    for (Procedure procedure in library.procedures) {
      if (procedure.isStatic == aopItemInfo.requiredIsStatic &&
          procedure.function.body != null &&
          procedure
              .function
              .typeParameters
              .isEmpty) // Generic type annotated procedures can not be manipulated as lack of type information.
      {
        if (aopItemInfo.isRegex) {
          if (aopItemInfo.methodNameRegex.hasMatch(procedure.name.text)) {
            filteredProcedures.add(procedure);
          }
        } else {
          if (aopItemInfo.requiredMethodName == procedure.name.text) {
            filteredProcedures.add(procedure);
          }
        }
      }
    }
    return filteredProcedures;
  }

  Set<Class> _filterClassWithAopItemInfo(
    Library library,
    AopItemInfo aopItemInfo,
  ) {
    assert(aopItemInfo.clsName.isNotEmpty);
    final Set<Class> filteredClasses = <Class>{};
    for (Class cls in library.classes) {
      if (aopItemInfo.isRegex) {
        if (aopItemInfo.clsNameRegex.hasMatch(cls.name)) {
          filteredClasses.add(cls);
        }
      } else {
        if (aopItemInfo.clsName == cls.name) {
          filteredClasses.add(cls);
        }
      }
    }
    return filteredClasses;
  }

  Set<Member> _filterClassMemberWithAopItemInfo(
    Class cls,
    AopItemInfo aopItemInfo,
  ) {
    final Set<Member> filteredMembers = <Member>{};
    //Check Constructors
    for (Constructor constructor in cls.constructors) {
      final String functionName = AopUtils.nameForConstructor(constructor);
      if (aopItemInfo.requiredIsStatic &&
          constructor.function.typeParameters.isEmpty) {
        //&& constructor.function.body != null
        if (aopItemInfo.isRegex) {
          if (aopItemInfo.methodNameRegex.hasMatch(functionName)) {
            filteredMembers.add(constructor);
          }
        } else {
          if (aopItemInfo.requiredMethodName == functionName) {
            filteredMembers.add(constructor);
          }
        }
      }
    }

    // List procedures = cls.procedures;
    //Check Procedures
    for (Procedure procedure in cls.procedures) {
      // NOTE: generic methods are intentionally NOT skipped here. The example's
      // AutoAnalyticsAspect weaves GestureRecognizer.invokeCallback<T> and works
      // in practice; type args are erased (deepCopyASTNode ignoreGenerics) -- a
      // known limitation for type-dependent advice, not a crash. See M4.7.
      if (procedure.isStatic == aopItemInfo.requiredIsStatic) {
        //procedure.function.body != null
        if (aopItemInfo.isRegex) {
          if (aopItemInfo.methodNameRegex.hasMatch(procedure.name.text)) {
            filteredMembers.add(procedure);
          }
        } else {
          if (aopItemInfo.requiredMethodName == procedure.name.text) {
            filteredMembers.add(procedure);
          }
        }
      }
    }
    return filteredMembers;
  }

  void aopTransform() {
    for (AopItemInfo aopItemInfo in _aopItemInfoList) {
      try {
        _transformExecuteItem(aopItemInfo);
      } catch (e, st) {
        // Per-item isolation: a failing execute weave must neither abort the
        // other execute items nor kill the build.
        AopUtils.diagnostics?.error(
          aopItemInfo,
          'execute weave failed: $e\n$st',
        );
      }
    }
  }

  void _transformExecuteItem(AopItemInfo aopItemInfo) {
    // #3: instance advice is invoked via `new Aspect()`; guard the no-arg
    // constructor requirement before weaving (static advice uses a
    // StaticInvocation and needs no constructor).
    final Procedure advice = aopItemInfo.requiredAdviceProcedure;
    if (!advice.isStatic && !AopUtils.adviceClassConstructable(aopItemInfo)) {
      return;
    }
    final Set<Library> filteredLibraries = _filterLibraryWithAopItemInfo(
      _libraryMap,
      aopItemInfo,
    );
    for (Library filteredLibrary in filteredLibraries) {
      // Skip the aspect library itself.
      if (aopItemInfo.isRegex && filteredLibrary == aopItemInfo.adviceLibrary) {
        continue;
      }
      final String clsName = aopItemInfo.clsName;
      // Transform library-level static methods.
      final bool isLibraryMethodNotRegex =
          clsName.isEmpty && !aopItemInfo.isRegex;
      final bool isLibraryMethodAndRegex =
          aopItemInfo.clsNameRegex.hasMatch('') && aopItemInfo.isRegex;
      if (isLibraryMethodNotRegex || isLibraryMethodAndRegex) {
        final Set<Procedure> filteredProcedures =
            _filterLibraryProcedureWithAopItemInfo(
              filteredLibrary,
              aopItemInfo,
            );
        for (Procedure procedure in filteredProcedures) {
          transformMethodProcedure(filteredLibrary, procedure, aopItemInfo);
        }
      }
      // Transform class static methods and instance methods.
      if (clsName.isNotEmpty) {
        final Set<Class> filteredLibraryClses = _filterClassWithAopItemInfo(
          filteredLibrary,
          aopItemInfo,
        );
        for (Class filteredCls in filteredLibraryClses) {
          final Set<Member> filteredMembers = _filterClassMemberWithAopItemInfo(
            filteredCls,
            aopItemInfo,
          );
          for (Member filteredMember in filteredMembers) {
            if (filteredMember is Constructor) {
              transformConstructor(
                filteredLibrary,
                filteredMember,
                aopItemInfo,
              );
            } else if (filteredMember is Procedure) {
              if (filteredMember.function.body == null) {
                // #6: abstract/external method with no body -- look for a patch
                // member that has one. If there is none, skip THIS member with
                // a diagnostic instead of `null!` (which would abort the rest
                // of this aspect item's members).
                final Member? patch = _filterFirstMatchPatchClassMember(
                  _libraryMap,
                  filteredMember,
                  aopItemInfo,
                );
                if (patch == null) {
                  AopUtils.diagnostics?.unsupported(
                    aopItemInfo,
                    'no patch member with a body found for abstract/external '
                    '${filteredMember.name.text}; skipping this member.',
                  );
                  continue;
                }
                filteredMember = patch;
              }
              transformMethodProcedure(
                filteredLibrary,
                filteredMember as Procedure,
                aopItemInfo,
              );
            }
          }
        }
      }
    }
  }

  void transformConstructor(
    Library originalLibrary,
    Constructor constructor,
    AopItemInfo aopItemInfo,
  ) {
    // First-version decision (see doc/README.md): @Execute on a constructor
    // is NOT supported. The previous implementation created a Constructor stub
    // and cast it to Procedure (`originalStubConstructor as Procedure`), which
    // crashed the whole compile. Crash-safety: skip with a clear diagnostic and
    // leave the constructor unmodified.
    AopUtils.diagnostics?.unsupported(
      aopItemInfo,
      'constructor @Execute is not supported in this version; '
      'the constructor is left unmodified.',
    );
  }

  void transformMethodProcedure(
    Library library,
    Procedure procedure,
    AopItemInfo aopItemInfo,
  ) {
    if (procedure.function.body == null) {
      return;
    }
    if (!AopUtils.canOperateLibrary(library)) {
      return;
    }
    if (procedure.parent is Class) {
      if (procedure.isStatic) {
        transformStaticMethodProcedure(library, aopItemInfo, procedure);
      } else {
        transformInstanceMethodProcedure(library, aopItemInfo, procedure);
      }
    } else if (procedure.parent is Library) {
      transformStaticMethodProcedure(library, aopItemInfo, procedure);
    }
  }

  void transformStaticMethodProcedure(
    Library originalLibrary,
    AopItemInfo aopItemInfo,
    Procedure originalProcedure,
  ) {
    final FunctionNode functionNode = originalProcedure.function;
    final bool shouldReturn =
        originalProcedure.function.returnType is! VoidType;

    final String stubKey =
        '${AopUtils.kAopStubMethodPrefix}${AopUtils.kPrimaryKeyAopMethod}';
    AopUtils.kPrimaryKeyAopMethod++;

    // Move the original method body into a stub so execution can flow from the
    // target method to the AOP stub, then back to the target stub. The stub gets
    // a clone of the original function (fresh params + remapped body), so the
    // original method below can keep its own params for the advice call.
    final Procedure originalStubProcedure = AopUtils.createStubProcedure(
      Name(
        '${originalProcedure.name.text}_$stubKey',
        originalProcedure.name.library,
      ),
      aopItemInfo,
      originalProcedure,
      shouldReturn,
    );
    final TreeNode parent = originalProcedure.parent as TreeNode;

    originalStubProcedure.parent = parent;
    late String parentIdentifier;
    if (parent is Library) {
      parent.procedures.add(originalStubProcedure);
      parentIdentifier = parent.importUri.toString();
    } else if (parent is Class) {
      parent.addProcedure(originalStubProcedure);
      parentIdentifier = parent.name;
    }

    // M5.4: instead of generating an aop_stub_N method on PointCut plus a
    // central proceed() branch, pass a self-contained proceed closure that
    // invokes the moved stub directly. This makes the woven site independent of
    // any central dispatch table (incremental/hot-reload safe).
    final Expression proceedClosure =
        AopUtils.buildExecuteProceedClosure(
          aopItemInfo,
          originalStubProcedure,
          originalProcedure,
          shouldReturn: shouldReturn,
          isInstance: false,
        );
    functionNode.body = createPointcutCallFromOriginal(
      originalLibrary,
      aopItemInfo,
      stubKey,
      StringLiteral(parentIdentifier),
      originalProcedure,
      AopUtils.argumentsFromFunctionNode(functionNode),
      shouldReturn,
      proceedClosure: proceedClosure,
    );
  }

  void transformInstanceMethodProcedure(
    Library originalLibrary,
    AopItemInfo aopItemInfo,
    Procedure originalProcedure,
  ) {
    final FunctionNode functionNode = originalProcedure.function;
    final Class originalClass = originalProcedure.parent as Class;
    final Statement? body = functionNode.body;
    if (body == null) {
      return;
    }
    final bool shouldReturn =
        originalProcedure.function.returnType is! VoidType;

    final String stubKey =
        '${AopUtils.kAopStubMethodPrefix}${AopUtils.kPrimaryKeyAopMethod}';
    AopUtils.kPrimaryKeyAopMethod++;

    // Move the original method body into a stub so execution can flow from the
    // target method to the AOP stub, then back to the target stub. The stub gets
    // a clone of the original function (fresh params + remapped body).
    final Procedure originalStubProcedure = AopUtils.createStubProcedure(
      Name(
        '${originalProcedure.name.text}_$stubKey',
        originalProcedure.name.library,
      ),
      aopItemInfo,
      originalProcedure,
      shouldReturn,
    );
    originalClass.addProcedure(originalStubProcedure);
    originalStubProcedure.parent = originalClass;

    // M5.4: pass a self-contained proceed closure that invokes the moved stub
    // via `(pc.target as OriginalClass).stub(...)`, instead of an aop_stub_N
    // method on PointCut + central proceed() branch.
    final Expression proceedClosure =
        AopUtils.buildExecuteProceedClosure(
          aopItemInfo,
          originalStubProcedure,
          originalProcedure,
          shouldReturn: shouldReturn,
          isInstance: true,
          instanceClass: originalClass,
        );
    functionNode.body = createPointcutCallFromOriginal(
      originalLibrary,
      aopItemInfo,
      stubKey,
      ThisExpression(),
      originalProcedure,
      AopUtils.argumentsFromFunctionNode(functionNode),
      shouldReturn,
      proceedClosure: proceedClosure,
    );
  }

  Block createPointcutCallFromOriginal(
    Library library,
    AopItemInfo aopItemInfo,
    String stubKey,
    Expression targetExpression,
    Member member,
    Arguments arguments,
    bool shouldReturn, {
    Expression? proceedClosure,
  }) {
    AopUtils.insertLibraryDependency(library, aopItemInfo.adviceLibrary);
    final Arguments redirectArguments = Arguments.empty();

    final Map<String, String> sourceInfo = AopUtils.calcSourceInfo(
      _uriToSource,
      library,
      0,
    );
    sourceInfo.putIfAbsent('procedure', () => member.toString());
    AopUtils.concatArgumentsForAopMethod(
      sourceInfo,
      redirectArguments,
      stubKey,
      targetExpression,
      member,
      arguments,
      null,
      proceedClosure: proceedClosure,
    );
    late Expression callExpression;
    final Procedure procedure = aopItemInfo.requiredAdviceProcedure;
    if (procedure.isStatic) {
      callExpression = StaticInvocation(procedure, redirectArguments);
    } else {
      final Class aopItemMemberCls = aopItemInfo.adviceClass;
      final ConstructorInvocation redirectConstructorInvocation =
          ConstructorInvocation.byReference(
            aopItemMemberCls.constructors.first.reference,
            Arguments(<Expression>[]),
          );
      callExpression = InstanceInvocation(
        InstanceAccessKind.Instance,
        redirectConstructorInvocation,
        procedure.name,
        redirectArguments,
        interfaceTarget: procedure,
        functionType: procedure.getterType as FunctionType,
      );
    }
    final Block body = AopUtils.createProcedureBodyWithExpression(
      callExpression,
      shouldReturn,
    );
    // Synthetic advice-call body; backfill offsets for the verifier.
    AopUtils.setMissingFileOffsets(body, member.fileOffset);
    return body;
  }
}
