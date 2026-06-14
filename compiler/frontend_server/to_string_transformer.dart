// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:frontend_server/frontend_server.dart'
    as frontend
    show ProgramTransformer;
import 'package:kernel/ast.dart';

/// A [RecursiveVisitor] that replaces [Object.toString] overrides with
/// `super.toString()`.
class ToStringVisitor extends RecursiveVisitor {
  ToStringVisitor(this._packageUris);

  /// A set of package URIs to apply this transformer to, e.g. 'dart:ui' and
  /// 'package:flutter/foundation.dart'.
  final Set<String> _packageUris;

  /// Turn 'dart:ui' into 'dart:ui', or
  /// 'package:flutter/src/semantics_event.dart' into 'package:flutter'.
  String _importUriToPackage(Uri importUri) =>
      '${importUri.scheme}:${importUri.pathSegments.first}';

  bool _isInTargetPackage(Procedure node) {
    return _packageUris.contains(
      _importUriToPackage(node.enclosingLibrary.importUri),
    );
  }

  bool _hasKeepAnnotation(Procedure node) {
    for (final ConstantExpression expression
        in node.annotations.whereType<ConstantExpression>()) {
      if (expression.constant is! InstanceConstant) {
        continue;
      }
      final InstanceConstant constant = expression.constant as InstanceConstant;
      if (constant.classNode.name == '_KeepToString' &&
          constant.classNode.enclosingLibrary.importUri.toString() ==
              'dart:ui') {
        return true;
      }
    }
    return false;
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.name.text == 'toString' &&
        node.enclosingClass != null &&
        !node.isStatic &&
        !node.isAbstract &&
        !node.enclosingClass!.isEnum &&
        _isInTargetPackage(node) &&
        !_hasKeepAnnotation(node)) {
      node.function.body?.replaceWith(
        ReturnStatement(
          SuperMethodInvocation(
            ThisExpression(),
            node.name,
            Arguments(<Expression>[]),
            node,
          ),
        ),
      );
    }
  }

  @override
  void defaultMember(Member node) {}
}

/// Replaces [Object.toString] overrides with calls to super for the specified
/// [packageUris].
class ToStringTransformer extends frontend.ProgramTransformer {
  ToStringTransformer(this._child, this._packageUris);

  final frontend.ProgramTransformer? _child;

  /// A set of package URIs to apply this transformer to, e.g. 'dart:ui' and
  /// 'package:flutter/foundation.dart'.
  final Set<String> _packageUris;

  @override
  void transform(Component component) {
    assert(_child is! ToStringTransformer);
    if (_packageUris.isNotEmpty) {
      component.visitChildren(ToStringVisitor(_packageUris));
    }
    _child?.transform(component);
  }
}
