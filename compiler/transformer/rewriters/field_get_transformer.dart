// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'package:kernel/ast.dart';

import 'aop_item_info.dart';
import 'aop_transform_utils.dart';

class AopFieldGetImplTransformer extends Transformer {
  AopFieldGetImplTransformer(this._aopItemInfoList, this._uriToSource);

  final List<AopItemInfo> _aopItemInfoList;
  final Map<Uri, Source> _uriToSource;
  Library? _curLibrary;

  @override
  Library visitLibrary(Library node) {
    _curLibrary = node;
    node.transformChildren(this);
    return node;
  }

  @override
  TreeNode visitStaticGet(StaticGet node) {
    // Resolve the field's owner from the target NODE, not canonicalName:
    // during the modular-transform phase canonical names are not yet bound
    // (they are assigned at serialization), so the old canonicalName-based
    // matching silently never fired -- static FieldGet was effectively dead.
    final Member? target = node.targetReference.node as Member?;
    final Class? ownerClass = target?.enclosingClass;
    final Library? ownerLibrary = target?.enclosingLibrary;
    if (target == null || ownerClass == null || ownerLibrary == null) {
      // Unresolved, or a top-level static (no enclosing class) which @FieldGet
      // (clsName-based) does not target.
      return super.visitStaticGet(node);
    }

    final String importUri = ownerLibrary.importUri.toString();
    final String clsName = ownerClass.name;
    final String fieldName = target.name.text;

    final AopItemInfo? aopItemInfo = _filterAopItemInfo(
      _aopItemInfoList,
      importUri,
      clsName,
      fieldName,
      true,
    );

    if (aopItemInfo != null) {
      // #3: fieldGet advice is invoked via StaticInvocation, so it must be a
      // static method; skip with a diagnostic otherwise.
      if (!AopUtils.adviceFormMatches(aopItemInfo, expectStatic: true)) {
        return super.visitStaticGet(node);
      }
      // A static read has no receiver, so target is null.
      return _buildAdviceCall(
        aopItemInfo,
        node.fileOffset,
        NullLiteral(),
        field: target,
        ownerClass: ownerClass,
        isStatic: true,
      );
    }

    return super.visitStaticGet(node) as Expression;
  }

  @override
  Expression visitInstanceGet(InstanceGet node) {
    // M3.5: resolve the field's owner from the interface target, not from the
    // class where the read happens (_curClass), which produced both false
    // positives and false negatives.
    final Member? interfaceTarget =
        node.interfaceTargetReference.node as Member?;
    final Class? ownerClass = interfaceTarget?.enclosingClass;
    final Library? ownerLibrary = interfaceTarget?.enclosingLibrary;
    if (ownerClass == null || ownerLibrary == null) {
      return super.visitInstanceGet(node) as Expression;
    }

    final String importUri = ownerLibrary.importUri.toString();
    final String clsName = ownerClass.name;
    final String fieldName = node.name.text;

    final AopItemInfo? aopItemInfo = _filterAopItemInfo(
      _aopItemInfoList,
      importUri,
      clsName,
      fieldName,
      false,
    );

    if (aopItemInfo != null) {
      // #3: fieldGet advice is invoked via StaticInvocation, so it must be a
      // static method; skip with a diagnostic otherwise.
      if (!AopUtils.adviceFormMatches(aopItemInfo, expectStatic: true)) {
        return super.visitInstanceGet(node) as Expression;
      }
      // Pass the receiver as the PointCut target; the original InstanceGet is
      // replaced by the advice call.
      return _buildAdviceCall(
        aopItemInfo,
        node.fileOffset,
        node.receiver,
        field: interfaceTarget,
        ownerClass: ownerClass,
        isStatic: false,
      );
    }

    return super.visitInstanceGet(node) as Expression;
  }

  /// Replaces a matched field read with a call to the advice, passing a real
  /// (non-null) [PointCut]. Previously a bare `NullLiteral` was passed, which
  /// crashed any advice that dereferenced its parameter.
  ///
  /// M5.4: also attaches a `proceedClosure` so the advice can call proceed() to
  /// read the ORIGINAL field value (a static `Owner.field` read, or an instance
  /// `(pc.target as Owner).field` read). Previously proceed() returned null for
  /// fieldGet.
  Expression _buildAdviceCall(
    AopItemInfo aopItemInfo,
    int fileOffset,
    Expression target, {
    required Member? field,
    required Class? ownerClass,
    required bool isStatic,
  }) {
    final Map<String, String> sourceInfo = AopUtils.calcSourceInfo(
      _uriToSource,
      _curLibrary!,
      fileOffset,
    );

    FunctionExpression? proceedClosure;
    if (field is Field && ownerClass != null) {
      // A field read takes no arguments, so build the closure directly rather
      // than via buildProceedClosure (which reconstructs an arg list).
      final Class pointCutClass =
          AopUtils.pointCutProceedProcedure!.parent as Class;
      final VariableDeclaration pcParam = VariableDeclaration(
        'pc',
        type: InterfaceType(pointCutClass, Nullability.nonNullable),
      );
      final Expression read = isStatic
          ? StaticGet(field)
          : InstanceGet(
              InstanceAccessKind.Instance,
              AopUtils.pointCutTargetCast(pcParam, ownerClass),
              field.name,
              interfaceTarget: field,
              resultType: field.type,
            );
      proceedClosure = FunctionExpression(
        FunctionNode(
          Block(<Statement>[ReturnStatement(read)]),
          positionalParameters: <VariableDeclaration>[pcParam],
          returnType: const DynamicType(),
        ),
      );
      AopUtils.setMissingFileOffsets(proceedClosure, fileOffset);
    }

    final Arguments redirectArguments = Arguments.empty()
      ..positional.add(
        AopUtils.buildMinimalPointCut(
          sourceInfo,
          target,
          proceedClosure: proceedClosure,
        ),
      );
    final StaticInvocation invocation = StaticInvocation(
      aopItemInfo.requiredAdviceProcedure,
      redirectArguments,
    );
    // Synthetic advice call; backfill offsets for the verifier.
    AopUtils.setMissingFileOffsets(invocation, fileOffset);
    return invocation;
  }

  //Filter AopInfoMap for specific callsite.
  AopItemInfo? _filterAopItemInfo(
    List<AopItemInfo> aopItemInfoList,
    String importUri,
    String clsName,
    String fieldName,
    bool isStatic,
  ) {
    //Reverse sorting so that the newly added Aspect might override the older ones.

    final int aopItemInfoCnt = aopItemInfoList.length;
    for (int i = aopItemInfoCnt - 1; i >= 0; i--) {
      final AopItemInfo aopItemInfo = aopItemInfoList[i];

      if (aopItemInfo.excludeCoreLib &&
          AopUtils.isExcludedCoreLibrary(_curLibrary!)) {
        continue;
      }

      if (aopItemInfo.isRegex) {
        if (aopItemInfo.importUriRegex.hasMatch(importUri) &&
            aopItemInfo.clsNameRegex.hasMatch(clsName) &&
            aopItemInfo.fieldNameRegex.hasMatch(fieldName) &&
            isStatic == aopItemInfo.requiredIsStatic) {
          return aopItemInfo;
        }
      } else {
        if (aopItemInfo.importUri == importUri &&
            aopItemInfo.clsName == clsName &&
            aopItemInfo.requiredFieldName == fieldName &&
            isStatic == aopItemInfo.requiredIsStatic) {
          return aopItemInfo;
        }
      }
    }
    return null;
  }
}
