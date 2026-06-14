// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Positive regex weaving: a regex @Execute must weave EVERY matching method and
// leave non-matching ones untouched. The example covers regex execute at the
// integration level (advanced_recipes_aspect) and aop_utils_test covers invalid
// patterns; this locks the matcher at the unit level (multiple matches + a
// deliberate non-match).

import 'dart:typed_data';

import 'package:kernel/ast.dart';

import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/aop_transform_utils.dart';
import '../transformer/rewriters/execute_transformer.dart';
import '_harness.dart';

bool _isWoven(Procedure p) {
  final Statement body = p.function.body!;
  if (body is! Block || body.statements.isEmpty) {
    return false;
  }
  final Statement first = body.statements.first;
  return first is ReturnStatement && first.expression is StaticInvocation;
}

void main() {
  // --- PointCut runtime ---
  final Uri pcFile = Uri.parse('file:///pointcut.dart');
  final Library pcLib = Library(
      Uri.parse('package:aopd/src/annotations/pointcut.dart'),
      fileUri: pcFile);
  final Class pointCutClass = Class(name: 'PointCut', fileUri: pcFile);
  pcLib.addClass(pointCutClass);
  pointCutClass.addConstructor(Constructor(FunctionNode(EmptyStatement()),
      name: Name(''), fileUri: pcFile));
  for (final String f in <String>['target', 'positionalParams', 'namedParams',
    'stubKey']) {
    pointCutClass.addField(
        Field.mutable(Name(f), type: const DynamicType(), fileUri: pcFile));
  }
  AopUtils.pointCutProceedProcedure = Procedure(
      Name('proceed'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[ReturnStatement(NullLiteral())])),
      fileUri: pcFile);
  pointCutClass.addProcedure(AopUtils.pointCutProceedProcedure!);

  // --- Aspect with static advice ---
  final Uri aspectFile = Uri.parse('file:///aspect.dart');
  final Library aspectLib =
      Library(Uri.parse('package:t/aspect.dart'), fileUri: aspectFile);
  final Class aspectCls = Class(name: 'RegexAspect', fileUri: aspectFile);
  aspectLib.addClass(aspectCls);
  final Procedure advice = Procedure(
    Name('advice'),
    ProcedureKind.Method,
    FunctionNode(EmptyStatement(),
        positionalParameters: <VariableDeclaration>[VariableDeclaration('pc')]),
    isStatic: true,
    fileUri: aspectFile,
  );
  aspectCls.addProcedure(advice);

  // --- Target with compute1/compute2 (match 'compute') + other (no match) ---
  final Uri targetFile = Uri.parse('file:///target.dart');
  final Library targetLib =
      Library(Uri.parse('package:t/target.dart'), fileUri: targetFile);
  final Class svc = Class(name: 'Svc', fileUri: targetFile);
  targetLib.addClass(svc);
  Procedure mkMethod(String name, int value) => Procedure(
        Name(name),
        ProcedureKind.Method,
        FunctionNode(Block(<Statement>[ReturnStatement(IntLiteral(value))]),
            returnType: const DynamicType()),
        isStatic: true,
        fileUri: targetFile,
      );
  final Procedure compute1 = mkMethod('compute1', 1);
  final Procedure compute2 = mkMethod('compute2', 2);
  final Procedure other = mkMethod('other', 3);
  svc.addProcedure(compute1);
  svc.addProcedure(compute2);
  svc.addProcedure(other);

  final Map<Uri, Source> uriToSource = <Uri, Source>{
    targetFile: Source(<int>[0], Uint8List.fromList(<int>[120]),
        targetLib.importUri, targetLib.fileUri),
  };
  final Map<String, Library> libraryMap = <String, Library>{
    'package:t/target.dart': targetLib,
    'package:t/aspect.dart': aspectLib,
  };

  final AopItemInfo info = AopItemInfo(
    mode: AopMode.execute,
    importUri: 'package:t/target\\.dart',
    clsName: 'Svc',
    methodName: 'compute', // partial regex: matches compute1, compute2, not other
    isStatic: true,
    isRegex: true,
    aopMember: advice,
  );

  AopExecuteImplTransformer(<AopItemInfo>[info], libraryMap, uriToSource)
      .aopTransform();

  group('regex @Execute weaves every match, skips non-matches', () {
    final Iterable<Procedure> stubs = svc.procedures
        .where((Procedure p) => p.name.text.contains('_aop_stub_'));
    check(stubs.length == 2, 'exactly two stubs created (compute1 + compute2)');

    check(_isWoven(compute1), 'compute1 is woven (matches regex)');
    check(_isWoven(compute2), 'compute2 is woven (matches regex)');
    check(!_isWoven(other), 'other is NOT woven (does not match regex)');

    // The non-matching method keeps its original literal body.
    final Statement otherBody = other.function.body!;
    final Statement otherFirst = (otherBody as Block).statements.first;
    check(otherFirst is ReturnStatement && otherFirst.expression is IntLiteral,
        'other keeps its original body (return 3)');

    // Each woven method calls the advice.
    final Statement c1 = (compute1.function.body! as Block).statements.first;
    final Expression? call = c1 is ReturnStatement ? c1.expression : null;
    check(call is StaticInvocation && call.target == advice,
        'compute1 body invokes the advice');
  });

  finish();
}
