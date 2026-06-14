// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'aop_item_info.dart';
import 'aop_transform_utils.dart';

class AopAddImplTransformer extends RecursiveVisitor {
  AopAddImplTransformer(this._aopItemInfoList, this._uriToSource);

  final List<AopItemInfo> _aopItemInfoList;
  final Map<Uri, Source> _uriToSource;

  Library? _curLibrary;

  @override
  void visitLibrary(Library node) {
    _curLibrary = node;
    node.visitChildren(this);
  }

  @override
  void visitClass(Class node) {
    final String procedureImportUri = (node.parent as Library).importUri
        .toString();

    List<AopItemInfo>? items = _filterAopItemInfo(
      _aopItemInfoList,
      procedureImportUri,
      node.name,
      node.superclass,
    );
    if (items.isNotEmpty) {
      for (AopItemInfo item in items) {
        //Exclude hook class
        if (item.adviceLibrary != _curLibrary) {
          // #3: @Add invokes the advice via `new Aspect().advice(...)`, so it
          // must be an instance method on an aspect class with a no-arg
          // constructor; skip with a diagnostic otherwise.
          if (!AopUtils.adviceFormMatches(item, expectStatic: false) ||
              !AopUtils.adviceClassConstructable(item)) {
            continue;
          }
          try {
            insertMethod4Class(item, node);
          } catch (e, st) {
            // Per-item isolation (P1b): a failing @Add must neither abort the
            // other add items nor kill the build (degrade but loud).
            AopUtils.diagnostics?.error(item, 'add weave failed: $e\n$st');
          }
        }
      }
    }
  }

  // ignore: flutter_style_todos
  void insertMethod4Class(AopItemInfo aopItemInfo, Class pointCutClass) {
    final Procedure originProcedure = aopItemInfo.requiredAdviceProcedure;

    for (Member member in pointCutClass.members) {
      if (member.name.text == originProcedure.name.text) {
        return;
      }
    }

    AopUtils.insertLibraryDependency(_curLibrary!, aopItemInfo.adviceLibrary);

    final Arguments redirectArguments = Arguments.empty();
    final Map<String, String> sourceInfo = AopUtils.calcSourceInfo(
      _uriToSource,
      _curLibrary!,
      0,
    );

    final FunctionNode originFunctionNode =
        aopItemInfo.requiredAdviceProcedure.function;

    // Give the added method its OWN parameter declarations (generics erased)
    // instead of sharing the advice method's nodes (#4/#7) -- a shared param
    // would otherwise be parented under both the advice and the added method.
    // The redirect arguments below must read these fresh params.
    final CloneVisitorNotMembers paramCloner = AopUtils.erasingCloner(
      originFunctionNode,
    );
    final List<VariableDeclaration> positionalParameters = AopUtils.cloneParams(
      paramCloner,
      originFunctionNode.positionalParameters,
    );
    final List<VariableDeclaration> namedParameters = AopUtils.cloneParams(
      paramCloner,
      originFunctionNode.namedParameters,
    );

    final Arguments originArguments = AopUtils.argumentsFromParams(
      positionalParameters,
      namedParameters,
    );

    final Arguments pointCutConstructorArguments = Arguments.empty();
    final List<MapLiteralEntry> sourceInfos = <MapLiteralEntry>[];
    sourceInfo.forEach((String key, String value) {
      sourceInfos.add(
        MapLiteralEntry(StringLiteral(key), StringLiteral(value)),
      );
    });
    pointCutConstructorArguments.positional.add(MapLiteral(sourceInfos));
    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());

    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());
    pointCutConstructorArguments.positional.add(NullLiteral());

    final Class pointCutProceedProcedureCls =
        AopUtils.pointCutProceedProcedure!.parent as Class;
    final ConstructorInvocation pointCutConstructorInvocation =
        ConstructorInvocation(
          pointCutProceedProcedureCls.constructors.first,
          pointCutConstructorArguments,
        );

    redirectArguments.positional.add(pointCutConstructorInvocation);

    if (originArguments.positional.length > 1) {
      for (int i = 1; i < originArguments.positional.length; i++) {
        final Expression expression = originArguments.positional[i];
        redirectArguments.positional.add(expression);
      }
    }

    redirectArguments.named.addAll(originArguments.named);

    // pointCutConstructorInvocation.arguments.positional
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

    final bool shouldReturn = originProcedure.function.returnType is! VoidType;
    // Erase the advice's own generics to dynamic (consistent with the woven
    // stubs): the added method does not carry type parameters.
    final DartType returnType = shouldReturn
        ? paramCloner.visitType(originProcedure.function.returnType)
        : const VoidType();

    final Block bodyStatements = Block(<Statement>[]);
    if (shouldReturn) {
      bodyStatements.addStatement(ReturnStatement(methodInvocationNew));
    } else {
      bodyStatements.addStatement(ExpressionStatement(methodInvocationNew));
    }

    final FunctionNode functionNode = FunctionNode(
      bodyStatements,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      requiredParameterCount: originProcedure.function.requiredParameterCount,
      returnType: returnType,
      asyncMarker: originProcedure.function.asyncMarker,
      dartAsyncMarker: originProcedure.function.dartAsyncMarker,
      // Preserve the async value type (the verifier rejects Async + null
      // emittedValueType); erase the advice's own generics to match.
      emittedValueType: originProcedure.function.emittedValueType == null
          ? null
          : paramCloner.visitType(originProcedure.function.emittedValueType!),
    );

    final Name name = Name(originProcedure.name.text, _curLibrary);

    final Procedure procedure = Procedure(
      name,
      ProcedureKind.Method,
      functionNode,
      isStatic: originProcedure.isStatic,
      fileUri: pointCutClass.fileUri,
    );
    procedure.fileOffset = pointCutClass.fileOffset;
    // Synthetic added method; backfill offsets for the verifier.
    AopUtils.setMissingFileOffsets(functionNode, pointCutClass.fileOffset);

    pointCutClass.addProcedure(procedure);
  }

  //Filter AopInfoMap for specific class.
  List<AopItemInfo> _filterAopItemInfo(
    List<AopItemInfo> aopItemInfoList,
    String importUri,
    String clsName,
    Class? superClazz,
  ) {
    //Reverse sorting so that the newly added Aspect might override the older ones.
    final int aopItemInfoCnt = aopItemInfoList.length;

    final List<AopItemInfo> items = <AopItemInfo>[];
    for (int i = aopItemInfoCnt - 1; i >= 0; i--) {
      final AopItemInfo aopItemInfo = aopItemInfoList[i];

      if (aopItemInfo.isRegex) {
        if (aopItemInfo.importUriRegex.hasMatch(importUri) &&
            aopItemInfo.clsNameRegex.hasMatch(clsName)) {
          bool shouldAdd = true;

          if (aopItemInfo.superCls != null) {
            shouldAdd = false;
            // Walk a LOCAL copy: `superClazz` is a shared method parameter, and
            // the reverse loop evaluates every item against the same class.
            // Mutating it here would advance/null it for the next item, silently
            // mis-matching a second @Add(isRegex, superCls:) on the same class.
            Class? walk = superClazz;
            while (walk != null) {
              if (walk.name == aopItemInfo.superCls) {
                shouldAdd = true;
                break;
              }
              // `Object.superclass` is null, so use the nullable getter (NOT
              // `!`): a non-matching superCls must end the loop, not throw.
              walk = walk.superclass;
            }
          }

          if (shouldAdd == true) {
            items.add(aopItemInfo);
          }
        }
      } else {
        if (aopItemInfo.importUri == importUri &&
            aopItemInfo.clsName == clsName) {
          items.add(aopItemInfo);
        }
      }
    }
    return items;
  }
}
