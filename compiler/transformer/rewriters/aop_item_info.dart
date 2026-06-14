// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'package:kernel/ast.dart';

import 'aop_mode.dart';
import 'aop_transform_utils.dart';

class AopItemInfo {
  /// Raw constructor kept for focused tests and internal fixtures. Production
  /// annotation parsing should prefer [tryCreate], which validates the
  /// mode-specific required fields before the item reaches a rewriter.
  AopItemInfo({
    required this.mode,
    required this.importUri,
    required this.clsName,
    required this.methodName,
    this.isStatic,
    this.aopMember,
    this.isRegex = false,
    this.superCls,
    this.lineNum,
    this.excludeCoreLib = false,
    this.fieldName,
  });

  static AopItemInfo? tryCreate({
    required AopMode mode,
    required String importUri,
    required String clsName,
    String? methodName,
    bool? isStatic,
    Member? aopMember,
    bool isRegex = false,
    String? superCls,
    int? lineNum,
    bool excludeCoreLib = false,
    String? fieldName,
    void Function(String message)? onInvalid,
  }) {
    void invalid(String message) {
      onInvalid?.call(message);
    }

    if (aopMember == null) {
      invalid('AOP item is missing its advice member.');
      return null;
    }
    if (aopMember is! Procedure) {
      invalid('AOP annotation must be placed on an advice method.');
      return null;
    }

    switch (mode) {
      case AopMode.call:
      case AopMode.execute:
        if (methodName == null || methodName.isEmpty) {
          invalid('@${mode.name} requires methodName.');
          return null;
        }
        if (isStatic == null) {
          invalid('@${mode.name} requires isStatic target metadata.');
          return null;
        }
        break;
      case AopMode.inject:
        if (methodName == null || methodName.isEmpty) {
          invalid('@Inject requires methodName.');
          return null;
        }
        if (isStatic == null) {
          invalid('@Inject requires isStatic target metadata.');
          return null;
        }
        if (lineNum == null) {
          invalid('@Inject requires lineNum.');
          return null;
        }
        break;
      case AopMode.add:
        break;
      case AopMode.fieldGet:
        if (fieldName == null || fieldName.isEmpty) {
          invalid('@FieldGet requires fieldName.');
          return null;
        }
        if (isStatic == null) {
          invalid('@FieldGet requires isStatic target metadata.');
          return null;
        }
        break;
    }

    return AopItemInfo(
      mode: mode,
      importUri: importUri,
      clsName: clsName,
      methodName: methodName,
      isStatic: isStatic,
      aopMember: aopMember,
      isRegex: isRegex,
      superCls: superCls,
      lineNum: lineNum,
      excludeCoreLib: excludeCoreLib,
      fieldName: fieldName,
    );
  }

  final AopMode mode;
  final String importUri;
  final String clsName;
  final String? methodName;
  final bool? isStatic;
  final bool isRegex;
  final String? superCls;
  final Member? aopMember;
  final int? lineNum;
  final bool excludeCoreLib;
  final String? fieldName;

  Member get requiredAopMember {
    final Member? member = aopMember;
    if (member == null) {
      throw StateError('AOP item $mode is missing its advice member.');
    }
    return member;
  }

  Procedure get requiredAdviceProcedure {
    final Member member = requiredAopMember;
    if (member is Procedure) {
      return member;
    }
    throw StateError('AOP item $mode advice is not a Procedure.');
  }

  Class get adviceClass {
    final TreeNode? parent = requiredAopMember.parent;
    if (parent is Class) {
      return parent;
    }
    throw StateError('AOP item $mode advice member is not in a class.');
  }

  Library get adviceLibrary {
    final TreeNode? parent = adviceClass.parent;
    if (parent is Library) {
      return parent;
    }
    throw StateError('AOP item $mode advice class is not in a library.');
  }

  String get requiredMethodName {
    final String? value = methodName;
    if (value == null || value.isEmpty) {
      throw StateError('AOP item $mode is missing methodName.');
    }
    return value;
  }

  String get requiredFieldName {
    final String? value = fieldName;
    if (value == null || value.isEmpty) {
      throw StateError('AOP item $mode is missing fieldName.');
    }
    return value;
  }

  bool get requiredIsStatic {
    final bool? value = isStatic;
    if (value == null) {
      throw StateError('AOP item $mode is missing isStatic.');
    }
    return value;
  }

  int get requiredLineNum {
    final int? value = lineNum;
    if (value == null) {
      throw StateError('AOP item $mode is missing lineNum.');
    }
    return value;
  }

  bool get hasLineNum => lineNum != null;

  // M4.1: precompiled, cached RegExp for regex-mode matching. Only accessed
  // when isRegex is true (call sites guard on it), and patterns are validated
  // up front (AopUtils.firstInvalidRegex) before an AopItemInfo is created, so
  // these never throw. Avoids recompiling the same RegExp at every callsite /
  // class visit.
  RegExp? _importUriRegex;
  RegExp get importUriRegex => _importUriRegex ??= RegExp(importUri);

  RegExp? _clsNameRegex;
  RegExp get clsNameRegex => _clsNameRegex ??= RegExp(clsName);

  RegExp? _methodNameRegex;
  RegExp get methodNameRegex => _methodNameRegex ??= RegExp(requiredMethodName);

  RegExp? _fieldNameRegex;
  RegExp get fieldNameRegex => _fieldNameRegex ??= RegExp(requiredFieldName);

  static String uniqueKeyForMethod(
    String importUri,
    String clsName,
    String methodName,
    bool isStatic, {
    int? lineNum,
  }) {
    return importUri +
        AopUtils.kAopUniqueKeySeperator +
        clsName +
        AopUtils.kAopUniqueKeySeperator +
        methodName +
        AopUtils.kAopUniqueKeySeperator +
        (isStatic == true ? '+' : '-') +
        (lineNum != null ? ('${AopUtils.kAopUniqueKeySeperator}$lineNum') : '');
  }
}
