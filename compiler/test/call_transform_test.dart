// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Behavioral test for the call transformer's M5.4 decentralized weaving: an
// instance @Call callsite must be redirected through the advice with a
// PointCut carrying a `proceedClosure`, and must NOT add an aop_stub_N method
// to PointCut nor inject a branch into proceed().

import 'dart:typed_data';

import 'package:kernel/ast.dart';

import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/aop_transform_utils.dart';
import '../transformer/rewriters/call_transformer.dart';
import '_harness.dart';

void main() {
  // --- PointCut runtime library ---
  final Uri pcFile = Uri.parse('file:///pointcut.dart');
  final Library pcLib = Library(
      Uri.parse('package:aopd/src/annotations/pointcut.dart'),
      fileUri: pcFile);
  final Class pointCutClass = Class(name: 'PointCut', fileUri: pcFile);
  pcLib.addClass(pointCutClass);
  pointCutClass.addConstructor(Constructor(FunctionNode(EmptyStatement()),
      name: Name(''), fileUri: pcFile));
  for (final String f in <String>[
    'target',
    'positionalParams',
    'namedParams',
    'stubKey'
  ]) {
    pointCutClass.addField(
        Field.mutable(Name(f), type: const DynamicType(), fileUri: pcFile));
  }
  final Procedure proceed = Procedure(
      Name('proceed'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[ReturnStatement(NullLiteral())])),
      fileUri: pcFile);
  pointCutClass.addProcedure(proceed);
  AopUtils.pointCutProceedProcedure = proceed;

  // --- Aspect: class MyAspect { dynamic advice(PointCut pc) } (instance) ---
  final Uri aspectFile = Uri.parse('file:///aspect.dart');
  final Library aspectLib =
      Library(Uri.parse('package:t/aspect.dart'), fileUri: aspectFile);
  final Class aspectCls = Class(name: 'MyAspect', fileUri: aspectFile);
  aspectLib.addClass(aspectCls);
  aspectCls.addConstructor(Constructor(FunctionNode(EmptyStatement()),
      name: Name(''), fileUri: aspectFile));
  final Procedure advice = Procedure(
    Name('advice'),
    ProcedureKind.Method,
    FunctionNode(EmptyStatement(),
        positionalParameters: <VariableDeclaration>[VariableDeclaration('pc')],
        returnType: const DynamicType()),
    fileUri: aspectFile,
  );
  aspectCls.addProcedure(advice);

  // --- Target: class Target { int foo() { return 1; } } ---
  final Uri targetFile = Uri.parse('file:///target.dart');
  final Library targetLib =
      Library(Uri.parse('package:t/target.dart'), fileUri: targetFile);
  final Class target = Class(name: 'Target', fileUri: targetFile);
  targetLib.addClass(target);
  final Procedure foo = Procedure(
    Name('foo'),
    ProcedureKind.Method,
    FunctionNode(Block(<Statement>[ReturnStatement(IntLiteral(1))]),
        returnType: const DynamicType()),
    fileUri: targetFile,
  );
  target.addProcedure(foo);

  // --- Caller: dynamic run(Target t) { return t.foo(); } ---
  final Uri callFile = Uri.parse('file:///call.dart');
  final Library callLib =
      Library(Uri.parse('package:t/call.dart'), fileUri: callFile);
  final VariableDeclaration tParam = VariableDeclaration('t',
      type: InterfaceType(target, Nullability.nonNullable));
  final InstanceInvocation fooCall = InstanceInvocation(
    InstanceAccessKind.Instance,
    VariableGet(tParam),
    Name('foo'),
    Arguments(<Expression>[]),
    interfaceTarget: foo,
    functionType: foo.getterType as FunctionType,
  )..fileOffset = 0;
  final Procedure run = Procedure(
    Name('run'),
    ProcedureKind.Method,
    FunctionNode(Block(<Statement>[ReturnStatement(fooCall)]),
        positionalParameters: <VariableDeclaration>[tParam],
        returnType: const DynamicType()),
    isStatic: true,
    fileUri: callFile,
  );
  callLib.addProcedure(run);

  final Map<Uri, Source> uriToSource = <Uri, Source>{
    callFile: Source(<int>[0], Uint8List.fromList(<int>[120]),
        callLib.importUri, callLib.fileUri),
  };
  final Map<String, Library> libraryMap = <String, Library>{
    'package:t/target.dart': targetLib,
    'package:t/aspect.dart': aspectLib,
    'package:t/call.dart': callLib,
    'package:aopd/src/annotations/pointcut.dart': pcLib,
  };

  final AopItemInfo info = AopItemInfo(
    mode: AopMode.call,
    importUri: 'package:t/target.dart',
    clsName: 'Target',
    methodName: 'foo',
    isStatic: false,
    aopMember: advice,
  );

  final int pcProceduresBefore = pointCutClass.procedures.length;
  final int proceedStatementsBefore =
      (proceed.function.body as Block).statements.length;

  AopCallImplTransformer(<AopItemInfo>[info], libraryMap, uriToSource)
      .visitLibrary(callLib);

  group('instance call weave is decentralized (M5.4)', () {
    final Statement first = (run.function.body as Block).statements.first;
    final Expression? adviceCall =
        first is ReturnStatement ? first.expression : null;
    check(adviceCall is InstanceInvocation,
        'callsite redirected to an InstanceInvocation (the advice)');
    if (adviceCall is InstanceInvocation) {
      check(adviceCall.interfaceTargetReference.node == advice,
          'redirected to the advice method');
      final Expression pcArg = adviceCall.arguments.positional.first;
      check(pcArg is ConstructorInvocation, 'advice receives a PointCut(...)');
      if (pcArg is ConstructorInvocation) {
        final Iterable<NamedExpression> closures = pcArg.arguments.named
            .where((NamedExpression n) => n.name == 'proceedClosure');
        check(closures.length == 1, 'PointCut gets exactly one proceedClosure');
        // M5.4 + Dart 3.12: the proceed body is hoisted to a top-level function
        // and passed as a constant static tear-off (not an inline closure), so
        // sibling proceed sites in one method keep distinct VM identities.
        final Expression? pcVal =
            closures.isNotEmpty ? closures.first.value : null;
        check(
            pcVal is ConstantExpression &&
                pcVal.constant is StaticTearOffConstant,
            'proceedClosure is a constant tear-off of a hoisted proceed function');
      }
    }

    check(
        (proceed.function.body as Block).statements.length ==
            proceedStatementsBefore,
        'proceed() body is unchanged — no central dispatch branch added');
    check(pointCutClass.procedures.length == pcProceduresBefore,
        'no aop_stub_N method added to PointCut');
  });

  finish();
}
