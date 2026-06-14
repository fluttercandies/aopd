// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Node-ownership: concatArgumentsForAopMethod snapshots a woven class's fields
// into the PointCut `members` map. A const field's initializer must be CLONED,
// not reused -- reusing it re-parents the Field's own initializer into the map,
// and weaving the same field at two sites would put one node in two trees
// (invalid kernel). This locks the clone.

import 'package:kernel/ast.dart';

import '../transformer/rewriters/aop_transform_utils.dart';
import '_harness.dart';

class _ExprCollector extends RecursiveVisitor {
  final Set<Expression> seen = <Expression>{};

  @override
  void defaultExpression(Expression node) {
    seen.add(node);
    super.defaultExpression(node);
  }
}

void main() {
  // --- PointCut runtime (constructor + proceed) ---
  final Uri pcFile = Uri.parse('file:///pointcut.dart');
  final Library pcLib = Library(
      Uri.parse('package:aopd/src/annotations/pointcut.dart'),
      fileUri: pcFile);
  final Class pcClass = Class(name: 'PointCut', fileUri: pcFile);
  pcLib.addClass(pcClass);
  pcClass.addConstructor(Constructor(FunctionNode(EmptyStatement()),
      name: Name(''), fileUri: pcFile));
  AopUtils.pointCutProceedProcedure = Procedure(
      Name('proceed'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[ReturnStatement(NullLiteral())])),
      fileUri: pcFile);
  pcClass.addProcedure(AopUtils.pointCutProceedProcedure!);

  // --- Target class with a const field whose initializer is a
  //     ConstantExpression (the post-constant-eval shape, not a BasicLiteral) ---
  final Uri targetFile = Uri.parse('file:///target.dart');
  final Library targetLib =
      Library(Uri.parse('package:t/target.dart'), fileUri: targetFile);
  final Class cls = Class(name: 'C', fileUri: targetFile);
  targetLib.addClass(cls);
  final ConstantExpression constInit = ConstantExpression(IntConstant(7));
  final Field constField = Field.immutable(Name('answer'),
      type: const DynamicType(),
      initializer: constInit,
      isConst: true,
      fileUri: targetFile);
  cls.addField(constField);
  final Procedure member = Procedure(
    Name('m'),
    ProcedureKind.Method,
    FunctionNode(Block(<Statement>[ReturnStatement(NullLiteral())])),
    fileUri: targetFile,
  );
  cls.addProcedure(member);

  final Arguments redirectArguments = Arguments.empty();
  AopUtils.concatArgumentsForAopMethod(
    <String, String>{},
    redirectArguments,
    'aop_stub_0',
    ThisExpression(),
    member,
    Arguments.empty(),
    cls,
  );

  group('const-field members snapshot clones the initializer', () {
    final _ExprCollector collector = _ExprCollector();
    for (final Expression e in redirectArguments.positional) {
      e.accept(collector);
    }

    check(constField.initializer == constInit,
        'the original Field still owns its initializer node');
    check(!collector.seen.contains(constInit),
        'the ORIGINAL initializer node is not reused in the members map (cloned)');
    final bool clonePresent = collector.seen.any((Expression e) =>
        e is ConstantExpression &&
        e.constant is IntConstant &&
        (e.constant as IntConstant).value == 7);
    check(clonePresent,
        'a CLONE of the const value (IntConstant 7) is present in the members map');
  });

  finish();
}
