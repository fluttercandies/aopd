// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Behavioral test for the execute transformer's M5.4 decentralized weaving:
// a woven method must pass a `proceedClosure` to its PointCut and must NOT add
// an `aop_stub_N` method to PointCut nor inject a branch into proceed().
// The moved original body still lives in a `<name>_aop_stub_N` stub.

import 'dart:typed_data';

import 'package:kernel/ast.dart';

import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/aop_transform_utils.dart';
import '../transformer/rewriters/execute_transformer.dart';
import '_harness.dart';

void main() {
  // --- PointCut runtime library ---
  final Uri pcFile = Uri.parse('file:///pointcut.dart');
  final Library pcLib = Library(
      Uri.parse('package:aopd/src/annotations/pointcut.dart'),
      fileUri: pcFile);
  final Class pointCutClass = Class(name: 'PointCut', fileUri: pcFile);
  pcLib.addClass(pointCutClass);
  pointCutClass.addConstructor(
      Constructor(FunctionNode(EmptyStatement()), name: Name(''), fileUri: pcFile));
  for (final String f in <String>['target', 'positionalParams', 'namedParams',
    'stubKey']) {
    pointCutClass.addField(Field.mutable(Name(f),
        type: const DynamicType(), fileUri: pcFile));
  }
  // proceed() { return null; } — a Block body the legacy path would mutate.
  final Procedure proceed = Procedure(
      Name('proceed'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[ReturnStatement(NullLiteral())])),
      fileUri: pcFile);
  pointCutClass.addProcedure(proceed);
  AopUtils.pointCutProceedProcedure = proceed;

  // --- Aspect advice: class MyAspect { static dynamic advice(PointCut pc) } ---
  final Uri aspectFile = Uri.parse('file:///aspect.dart');
  final Library aspectLib =
      Library(Uri.parse('package:t/aspect.dart'), fileUri: aspectFile);
  final Class aspectCls = Class(name: 'MyAspect', fileUri: aspectFile);
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

  // --- Target: class Svc { static int compute() { return 1; } } ---
  final Uri targetFile = Uri.parse('file:///target.dart');
  final Library targetLib =
      Library(Uri.parse('package:t/target.dart'), fileUri: targetFile);
  final Class svc = Class(name: 'Svc', fileUri: targetFile);
  targetLib.addClass(svc);
  final Procedure compute = Procedure(
    Name('compute'),
    ProcedureKind.Method,
    FunctionNode(Block(<Statement>[ReturnStatement(IntLiteral(1))]),
        returnType: const DynamicType()),
    isStatic: true,
    fileUri: targetFile,
  );
  svc.addProcedure(compute);

  final Map<Uri, Source> uriToSource = <Uri, Source>{
    targetFile: Source(<int>[0], Uint8List.fromList(<int>[120]),
        targetLib.importUri, targetLib.fileUri),
  };
  final Map<String, Library> libraryMap = <String, Library>{
    'package:t/target.dart': targetLib,
    'package:t/aspect.dart': aspectLib,
    'package:aopd/src/annotations/pointcut.dart': pcLib,
  };

  final AopItemInfo info = AopItemInfo(
    mode: AopMode.execute,
    importUri: 'package:t/target.dart',
    clsName: 'Svc',
    methodName: 'compute',
    isStatic: true,
    aopMember: advice,
  );

  final int pcProceduresBefore = pointCutClass.procedures.length;
  final int proceedStatementsBefore =
      (proceed.function.body as Block).statements.length;

  AopExecuteImplTransformer(<AopItemInfo>[info], libraryMap, uriToSource)
      .aopTransform();

  group('execute weave is decentralized (M5.4)', () {
    // 1) The woven method body calls the advice.
    final Statement body = compute.function.body!;
    check(body is Block, 'compute body is a Block');
    final Statement first = (body as Block).statements.first;
    check(first is ReturnStatement, 'compute returns the advice result');
    final Expression? adviceCall =
        first is ReturnStatement ? first.expression : null;
    check(adviceCall is StaticInvocation, 'advice call is a StaticInvocation');

    // 2) The PointCut argument carries a proceedClosure tear-off.
    if (adviceCall is StaticInvocation) {
      check(adviceCall.target == advice, 'invocation targets the advice');
      final Expression pcArg = adviceCall.arguments.positional.first;
      check(pcArg is ConstructorInvocation, 'argument is a PointCut(...)');
      if (pcArg is ConstructorInvocation) {
        final Iterable<NamedExpression> closures = pcArg.arguments.named
            .where((NamedExpression n) => n.name == 'proceedClosure');
        check(closures.length == 1, 'PointCut gets exactly one proceedClosure');
        // M5.4 + Dart 3.12: hoisted to a top-level function, passed as a
        // constant static tear-off rather than an inline closure.
        final Expression? pcVal =
            closures.isNotEmpty ? closures.first.value : null;
        check(
            pcVal is ConstantExpression &&
                pcVal.constant is StaticTearOffConstant,
            'proceedClosure is a constant tear-off of a hoisted proceed function');
      }
    }

    // 3) proceed() was NOT mutated (no central if-branch inserted).
    check(
        (proceed.function.body as Block).statements.length ==
            proceedStatementsBefore,
        'proceed() body is unchanged — no central dispatch branch added');

    // 4) PointCut did NOT gain an aop_stub_N method.
    check(pointCutClass.procedures.length == pcProceduresBefore,
        'no aop_stub_N method added to PointCut');

    // 5) The original body was moved into a stub on Svc that still returns 1.
    final Iterable<Procedure> stubs = svc.procedures.where(
        (Procedure p) => p.name.text.startsWith('compute_aop_stub_'));
    check(stubs.length == 1, 'moved-body stub added to the target class');
    if (stubs.isNotEmpty) {
      final Statement stubBody = stubs.first.function.body!;
      final Statement s = (stubBody as Block).statements.first;
      check(s is ReturnStatement && s.expression is IntLiteral,
          'stub still returns the original literal');
    }
  });

  finish();
}
