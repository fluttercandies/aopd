// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'package:kernel/ast.dart';

import 'aop_item_info.dart';
import 'aop_mode.dart';
import 'aop_transform_utils.dart';

class AopCallImplTransformer extends Transformer {
  AopCallImplTransformer(
    this._aopItemInfoList,
    this._libraryMap,
    this._uriToSource,
  );

  final List<AopItemInfo> _aopItemInfoList;
  final Map<String, Library> _libraryMap;
  late Library _curLibrary;

  final Map<Uri, Source> _uriToSource;
  final Map<InvocationExpression, InvocationExpression>
  _invocationExpressionMapping = <InvocationExpression, InvocationExpression>{};

  @override
  Library visitLibrary(Library node) {
    _curLibrary = node;
    node.transformChildren(this);
    return node;
  }

  @override
  InvocationExpression visitConstructorInvocation(
    ConstructorInvocation constructorInvocation,
  ) {
    constructorInvocation.transformChildren(this);
    final Node? node = constructorInvocation.targetReference.node;

    if (node is Constructor) {
      final Constructor constructor = node;

      final Class cls = constructor.parent as Class;
      final String procedureImportUri = (cls.parent as Library).importUri
          .toString();
      String functionName = cls.name;
      if (constructor.name.text.isNotEmpty) {
        functionName += '.${constructor.name.text}';
      }

      final AopItemInfo? aopItemInfo = _filterAopItemInfo(
        _aopItemInfoList,
        procedureImportUri,
        cls.name,
        functionName,
        true,
      );

      if (aopItemInfo != null &&
          aopItemInfo.mode == AopMode.call &&
          AopUtils.checkIfSkipAOP(aopItemInfo, _curLibrary) == false) {
        if (!AopUtils.adviceFormMatches(aopItemInfo, expectStatic: true)) {
          return constructorInvocation;
        }
        return transformConstructorInvocation(
          constructorInvocation,
          aopItemInfo,
        );
      }
    } else {
      return constructorInvocation;
    }
    return constructorInvocation;
  }

  @override
  StaticInvocation visitStaticInvocation(StaticInvocation staticInvocation) {
    staticInvocation.transformChildren(this);
    Node? node = staticInvocation.targetReference.node as Node?;
    node ??= AopUtils.getNodeFromCanonicalName(
      _libraryMap,
      staticInvocation.targetReference.canonicalName,
    );
    if (node is Procedure) {
      final Procedure procedure = node;
      final TreeNode treeNode = procedure.parent!;
      if (treeNode is Library) {
        final Library library = treeNode;
        final String libraryImportUri = library.importUri.toString();
        final AopItemInfo? aopItemInfo = _filterAopItemInfo(
          _aopItemInfoList,
          libraryImportUri,
          '',
          procedure.name.text,
          true,
        );
        if (aopItemInfo != null &&
            aopItemInfo.mode == AopMode.call &&
            AopUtils.checkIfSkipAOP(aopItemInfo, _curLibrary) == false) {
          if (!AopUtils.adviceFormMatches(aopItemInfo, expectStatic: true)) {
            return staticInvocation;
          }
          return transformLibraryStaticMethodInvocation(
            staticInvocation,
            procedure,
            aopItemInfo,
          );
        }
      } else if (treeNode is Class) {
        final Class cls = treeNode;
        final String procedureImportUri = (cls.parent as Library).importUri
            .toString();
        final AopItemInfo? aopItemInfo = _filterAopItemInfo(
          _aopItemInfoList,
          procedureImportUri,
          cls.name,
          procedure.name.text,
          true,
        );
        if (aopItemInfo != null &&
            aopItemInfo.mode == AopMode.call &&
            AopUtils.checkIfSkipAOP(aopItemInfo, _curLibrary) == false) {
          if (!AopUtils.adviceFormMatches(aopItemInfo, expectStatic: true)) {
            return staticInvocation;
          }
          return transformClassStaticMethodInvocation(
            staticInvocation,
            aopItemInfo,
          );
        }
      }
    } else {
      //      assert(false);
      return staticInvocation;
    }
    return staticInvocation;
  }

  @override
  InstanceInvocation visitInstanceInvocation(
    InstanceInvocation instanceInvocation,
  ) {
    instanceInvocation.transformChildren(this);

    final Node? node =
        instanceInvocation.interfaceTargetReference.node as Node?;
    String? importUri, clsName, methodName;
    if (node is Procedure || node == null) {
      if (node is Procedure) {
        final Procedure procedure = node;
        final Class? cls = procedure.parent as Class?;
        if (cls == null) {
          // The resolved target is not a class method (e.g. an extension or
          // top-level method). Instance @Call matches class methods, so there
          // is nothing to match -- skip instead of crashing on `cls!`.
          return instanceInvocation;
        }
        importUri = (cls.parent as Library).importUri.toString();
        clsName = cls.name;
        methodName = instanceInvocation.name.text;
      } else if (node == null) {
        // NOTE: canonical names are typically NOT bound during the modular
        // transform (assigned at serialization; see the M3.5 finding in
        // field_get_transformer), so this fallback is best-effort and usually
        // yields nulls -> no match. The resolved-node path above is what
        // actually matches in practice.
        final CanonicalName? canonicalName =
            instanceInvocation.interfaceTargetReference.canonicalName;
        final AopKernelResolver resolver = AopKernelResolver(_libraryMap);
        importUri = resolver.libraryImportUriOf(canonicalName);
        clsName = resolver.ownerClassNameOf(canonicalName);
        methodName = AopKernelResolver.memberNameOf(canonicalName);
      }
      final AopItemInfo? aopItemInfo = _filterAopItemInfo(
        _aopItemInfoList,
        importUri,
        clsName,
        methodName,
        false,
      );
      if (aopItemInfo != null &&
          aopItemInfo.mode == AopMode.call &&
          AopUtils.checkIfSkipAOP(aopItemInfo, _curLibrary) == false) {
        if (!AopUtils.adviceFormMatches(aopItemInfo, expectStatic: false) ||
            !AopUtils.adviceClassConstructable(aopItemInfo)) {
          return instanceInvocation;
        }
        return transformInstanceMethodInvocation(
          instanceInvocation,
          aopItemInfo,
        );
      }
    }
    return instanceInvocation;
  }

  //Filter AopInfoMap for specific callsite.
  AopItemInfo? _filterAopItemInfo(
    List<AopItemInfo> aopItemInfoList,
    String? importUri,
    String? clsName,
    String? methodName,
    bool isStatic,
  ) {
    //Reverse sorting so that the newly added Aspect might override the older ones.
    importUri ??= '';
    clsName ??= '';
    methodName ??= '';
    final int aopItemInfoCnt = aopItemInfoList.length;
    for (int i = aopItemInfoCnt - 1; i >= 0; i--) {
      final AopItemInfo aopItemInfo = aopItemInfoList[i];

      if (aopItemInfo.excludeCoreLib &&
          AopUtils.isExcludedCoreLibrary(_curLibrary)) {
        continue;
      }

      if (aopItemInfo.isRegex) {
        // Skip the aspect library itself.
        if (_curLibrary == aopItemInfo.adviceLibrary) {
          continue;
        }

        if (aopItemInfo.importUriRegex.hasMatch(importUri) &&
            aopItemInfo.clsNameRegex.hasMatch(clsName) &&
            aopItemInfo.methodNameRegex.hasMatch(methodName) &&
            isStatic == aopItemInfo.requiredIsStatic) {
          return aopItemInfo;
        }
      } else {
        if (aopItemInfo.importUri == importUri &&
            aopItemInfo.clsName == clsName &&
            aopItemInfo.requiredMethodName == methodName &&
            isStatic == aopItemInfo.requiredIsStatic) {
          return aopItemInfo;
        }
      }
    }
    return null;
  }

  //Library Static Method Invocation
  StaticInvocation transformLibraryStaticMethodInvocation(
    StaticInvocation staticInvocation,
    Procedure procedure,
    AopItemInfo aopItemInfo,
  ) {
    // assert(aopItemInfo.mode != null);

    if (_invocationExpressionMapping[staticInvocation] != null) {
      return _invocationExpressionMapping[staticInvocation] as StaticInvocation;
    }

    final Library procedureLibrary = procedure.parent as Library;

    final String stubKey =
        '${AopUtils.kAopStubMethodPrefix}${AopUtils.kPrimaryKeyAopMethod}';
    AopUtils.kPrimaryKeyAopMethod++;

    // Build the PointCut arguments that will be passed to the advice method.
    final Arguments redirectArguments = Arguments.empty();
    final Map<String, String> sourceInfo = AopUtils.calcSourceInfo(
      _uriToSource,
      _curLibrary,
      staticInvocation.fileOffset,
    );
    final Expression proceedClosure = buildStaticMethodProceedClosure(
      aopItemInfo,
      procedure,
      staticInvocation.fileOffset,
    );
    AopUtils.concatArgumentsForAopMethod(
      sourceInfo,
      redirectArguments,
      stubKey,
      StringLiteral(procedureLibrary.importUri.toString()),
      procedure,
      staticInvocation.arguments,
      null,
      proceedClosure: proceedClosure,
    );
    final StaticInvocation staticInvocationNew = StaticInvocation(
      aopItemInfo.requiredAdviceProcedure,
      redirectArguments,
    );

    AopUtils.setMissingFileOffsets(
      staticInvocationNew,
      staticInvocation.fileOffset,
    );
    _invocationExpressionMapping[staticInvocation] = staticInvocationNew;
    return staticInvocationNew;
  }

  //Class Constructor Invocation
  StaticInvocation transformConstructorInvocation(
    ConstructorInvocation constructorInvocation,
    AopItemInfo aopItemInfo,
  ) {
    // assert(aopItemInfo.mode != null);

    if (_invocationExpressionMapping[constructorInvocation] != null) {
      return _invocationExpressionMapping[constructorInvocation]
          as StaticInvocation;
    }

    final Constructor constructor =
        constructorInvocation.targetReference.node as Constructor;
    final Class procedureClass = constructor.parent as Class;

    final String stubKey =
        '${AopUtils.kAopStubMethodPrefix}${AopUtils.kPrimaryKeyAopMethod}';
    AopUtils.kPrimaryKeyAopMethod++;

    // Build the PointCut arguments that will be passed to the advice method.
    final Arguments redirectArguments = Arguments.empty();
    final Map<String, String> sourceInfo = AopUtils.calcSourceInfo(
      _uriToSource,
      _curLibrary,
      constructorInvocation.fileOffset,
    );
    final Class? currentClass = AopUtils.findClassOfNode(constructorInvocation);
    final Expression proceedClosure = buildConstructorProceedClosure(
      aopItemInfo,
      constructor,
      constructorInvocation.fileOffset,
    );
    AopUtils.concatArgumentsForAopMethod(
      sourceInfo,
      redirectArguments,
      stubKey,
      StringLiteral(procedureClass.name),
      constructor,
      constructorInvocation.arguments,
      currentClass,
      allowThisFallbackToMemberParent: false,
      proceedClosure: proceedClosure,
    );

    final StaticInvocation staticInvocationNew = StaticInvocation(
      aopItemInfo.requiredAdviceProcedure,
      redirectArguments,
    );

    AopUtils.setMissingFileOffsets(
      staticInvocationNew,
      constructorInvocation.fileOffset,
    );
    _invocationExpressionMapping[constructorInvocation] = staticInvocationNew;
    return staticInvocationNew;
  }

  //Class Static Method Invocation
  StaticInvocation transformClassStaticMethodInvocation(
    StaticInvocation staticInvocation,
    AopItemInfo aopItemInfo,
  ) {
    // assert(aopItemInfo.mode != null);

    if (_invocationExpressionMapping[staticInvocation] != null) {
      return _invocationExpressionMapping[staticInvocation] as StaticInvocation;
    }

    final Procedure procedure =
        staticInvocation.targetReference.node! as Procedure;
    final Class procedureClass = procedure.parent as Class;

    final String stubKey =
        '${AopUtils.kAopStubMethodPrefix}${AopUtils.kPrimaryKeyAopMethod}';
    AopUtils.kPrimaryKeyAopMethod++;

    // Build the PointCut arguments that will be passed to the advice method.
    final Arguments redirectArguments = Arguments.empty();
    final Map<String, String> sourceInfo = AopUtils.calcSourceInfo(
      _uriToSource,
      _curLibrary,
      staticInvocation.fileOffset,
    );
    final Class? currentClass = AopUtils.findClassOfNode(staticInvocation);

    final Expression proceedClosure = buildStaticMethodProceedClosure(
      aopItemInfo,
      procedure,
      staticInvocation.fileOffset,
    );
    AopUtils.concatArgumentsForAopMethod(
      sourceInfo,
      redirectArguments,
      stubKey,
      StringLiteral(procedureClass.name),
      procedure,
      staticInvocation.arguments,
      currentClass,
      allowThisFallbackToMemberParent: false,
      proceedClosure: proceedClosure,
    );

    final StaticInvocation staticInvocationNew = StaticInvocation(
      aopItemInfo.requiredAdviceProcedure,
      redirectArguments,
    );

    AopUtils.setMissingFileOffsets(
      staticInvocationNew,
      staticInvocation.fileOffset,
    );
    _invocationExpressionMapping[staticInvocation] = staticInvocationNew;
    return staticInvocationNew;
  }

  //Instance Method Invocation
  InstanceInvocation transformInstanceMethodInvocation(
    InstanceInvocation instanceInvocation,
    AopItemInfo aopItemInfo,
  ) {
    // assert(aopItemInfo.mode != null);

    if (_invocationExpressionMapping[instanceInvocation] != null) {
      return _invocationExpressionMapping[instanceInvocation]
          as InstanceInvocation;
    }

    final Node? targetNode = instanceInvocation.interfaceTargetReference.node;
    if (targetNode is! Procedure) {
      // visitInstanceInvocation may match via canonical name while the
      // interface target node is still unresolved. Don't cast-crash: skip this
      // callsite with a diagnostic and leave it unchanged.
      AopUtils.diagnostics?.warning(
        aopItemInfo,
        'instance @Call target could not be resolved to a concrete '
        'method; leaving callsite unchanged.',
      );
      return instanceInvocation;
    }
    Procedure methodProcedure = targetNode;
    Class? methodClass = targetNode.parent as Class?;

    Class? methodImplClass = methodClass;
    final String procedureName = instanceInvocation.name.text;
    Library? originalLibrary = methodProcedure.parent?.parent as Library?;
    if (originalLibrary == null) {
      final AopKernelResolver resolver = AopKernelResolver(_libraryMap);
      final String? libImportUri = resolver.libraryImportUriOf(
        instanceInvocation.interfaceTargetReference.canonicalName,
      );
      originalLibrary = _libraryMap[libImportUri];
    }
    if (methodClass == null) {
      final AopKernelResolver resolver = AopKernelResolver(_libraryMap);
      final String? expectedName = resolver.ownerClassNameOf(
        instanceInvocation.interfaceTargetReference.canonicalName,
      );
      if (originalLibrary == null) {
        return instanceInvocation;
      }
      for (Class cls in originalLibrary.classes) {
        if (cls.name == expectedName) {
          methodClass = cls;
          break;
        }
      }
    }

    if (methodClass == null) {
      return instanceInvocation;
    }

    if (methodClass.flags & Class.FlagAbstract != 0) {
      for (Class cls in originalLibrary!.classes) {
        final String clsName = cls.name;
        if (cls.flags & Class.FlagAbstract != 0) {
          // Abstract classes cannot provide the concrete method body.
          continue;
        }
        // methodClass is abstract here (guarded by the enclosing `if`), so the
        // concrete impl is the private `_<Name>` class implementing it.
        bool matches = false;
        for (Supertype superType in cls.implementedTypes) {
          if (superType.className.node == methodClass) {
            matches = true;
          }
        }
        if (!matches || (clsName != '_${methodClass.name}')) {
          continue;
        }
        methodImplClass = cls;
        for (Procedure procedure in cls.procedures) {
          final String methodName = procedure.name.text;
          if (methodName == procedureName) {
            methodProcedure = procedure;
            break;
          }
        }
      }
    }

    if (methodImplClass == null) {
      return instanceInvocation;
    }

    final String stubKey =
        '${AopUtils.kAopStubMethodPrefix}${AopUtils.kPrimaryKeyAopMethod}';
    AopUtils.kPrimaryKeyAopMethod++;

    // Build the PointCut arguments that will be passed to the advice method.
    final Arguments redirectArguments = Arguments.empty();
    final Map<String, String> sourceInfo = AopUtils.calcSourceInfo(
      _uriToSource,
      _curLibrary,
      instanceInvocation.fileOffset,
    );
    final Class? currentClass = AopUtils.findClassOfNode(instanceInvocation);

    // M5.4: decentralized proceed -- attach a closure that performs the original
    // instance call instead of generating a central stub + proceed() branch.
    final Expression proceedClosure = buildInstanceMethodProceedClosure(
      instanceInvocation,
      aopItemInfo,
      methodImplClass,
      methodProcedure,
      instanceInvocation.fileOffset,
    );

    AopUtils.concatArgumentsForAopMethod(
      sourceInfo,
      redirectArguments,
      stubKey,
      instanceInvocation.receiver,
      methodProcedure,
      instanceInvocation.arguments,
      currentClass,
      allowThisFallbackToMemberParent: false,
      proceedClosure: proceedClosure,
    );

    final Procedure advice = aopItemInfo.requiredAdviceProcedure;
    final Class cls = aopItemInfo.adviceClass;
    final ConstructorInvocation redirectConstructorInvocation =
        ConstructorInvocation.byReference(
          cls.constructors.first.reference,
          Arguments(<Expression>[]),
        );
    final InstanceInvocation methodInvocationNew = InstanceInvocation(
      InstanceAccessKind.Instance,
      redirectConstructorInvocation,
      advice.name,
      redirectArguments,
      interfaceTarget: advice,
      functionType: advice.getterType as FunctionType,
    );
    AopUtils.insertLibraryDependency(_curLibrary, aopItemInfo.adviceLibrary);

    AopUtils.setMissingFileOffsets(
      methodInvocationNew,
      instanceInvocation.fileOffset,
    );
    _invocationExpressionMapping[instanceInvocation] = methodInvocationNew;
    return methodInvocationNew;
  }

  // M5.4: decentralized proceed closure for a constructor callsite.
  Expression buildConstructorProceedClosure(
    AopItemInfo aopItemInfo,
    Constructor originalMember,
    int closureFileOffset,
  ) {
    final bool shouldReturn = originalMember.function.returnType is! VoidType;
    return AopUtils.buildProceedClosure(
      originalMember,
      aopItemInfo,
      shouldReturn: shouldReturn,
      closureFileOffset: closureFileOffset,
      hostLibrary: _curLibrary,
      buildInvocation: (VariableDeclaration pcParam, Arguments args) =>
          ConstructorInvocation(originalMember, args),
    );
  }

  // M5.4: decentralized proceed closure for a static/library-function callsite.
  Expression buildStaticMethodProceedClosure(
    AopItemInfo aopItemInfo,
    Procedure originalMember,
    int closureFileOffset,
  ) {
    final bool shouldReturn = originalMember.function.returnType is! VoidType;
    return AopUtils.buildProceedClosure(
      originalMember,
      aopItemInfo,
      shouldReturn: shouldReturn,
      closureFileOffset: closureFileOffset,
      hostLibrary: _curLibrary,
      buildInvocation: (VariableDeclaration pcParam, Arguments args) =>
          StaticInvocation(originalMember, args),
    );
  }

  // M5.4: build the decentralized proceed closure for an instance callsite,
  // instead of an aop_stub_N method on PointCut + central proceed() branch.
  Expression buildInstanceMethodProceedClosure(
    InstanceInvocation originalInvocation,
    AopItemInfo aopItemInfo,
    Class procedureImpl,
    Procedure originalProcedure,
    int closureFileOffset,
  ) {
    final bool shouldReturn =
        originalProcedure.function.returnType is! VoidType;
    return AopUtils.buildProceedClosure(
      originalProcedure,
      aopItemInfo,
      shouldReturn: shouldReturn,
      closureFileOffset: closureFileOffset,
      hostLibrary: _curLibrary,
      buildInvocation: (VariableDeclaration pcParam, Arguments args) {
        return InstanceInvocation(
          InstanceAccessKind.Instance,
          AopUtils.pointCutTargetCast(pcParam, procedureImpl),
          originalProcedure.name,
          args,
          interfaceTarget: originalProcedure,
          functionType: originalInvocation.functionType,
        );
      },
    );
  }
}
