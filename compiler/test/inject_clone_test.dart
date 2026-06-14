// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// A2 (#15): @Inject must CLONE the advice statements into the target instead of
// MOVING them and then clearing the advice body. These tests assert, at the
// onPrepareTransform/onPostTransform level (offset-free), that:
//   * onPrepareTransform returns CLONES of the advice statements (not the same
//     node instances),
//   * the advice body is NOT mutated by a weave (it used to be cleared),
//   * the advice is therefore REUSABLE -- a second prepare still yields the
//     statements (a fresh set of clones).

import 'dart:typed_data';

import 'package:kernel/ast.dart';

import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/inject_transformer.dart';
import '_harness.dart';

void main() {
  final Uri aspectFile = Uri.parse('file:///aspect.dart');
  final Library aspectLib =
      Library(Uri.parse('package:t/aspect.dart'), fileUri: aspectFile);
  final Class aspectCls = Class(name: 'InjectAspect', fileUri: aspectFile);
  aspectLib.addClass(aspectCls);

  // Advice with a two-statement block body (no //AOPD Ignore markers, so both
  // are kept and cloned; no var-decls, so no source/offset lookup is needed).
  final Procedure advice = Procedure(
    Name('inj'),
    ProcedureKind.Method,
    FunctionNode(Block(<Statement>[
      ExpressionStatement(StringLiteral('hello')),
      ExpressionStatement(IntLiteral(7)),
    ]))
      ..fileOffset = 10,
    isStatic: true,
    fileUri: aspectFile,
  )..fileOffset = 10;
  aspectCls.addProcedure(advice);

  // Target method (only needs params/body for onPrepareTransform bookkeeping).
  final Uri targetFile = Uri.parse('file:///target.dart');
  final Library targetLib =
      Library(Uri.parse('package:t/target.dart'), fileUri: targetFile);
  final Class svc = Class(name: 'Svc', fileUri: targetFile);
  targetLib.addClass(svc);
  final Procedure target = Procedure(
    Name('run'),
    ProcedureKind.Method,
    FunctionNode(Block(<Statement>[ReturnStatement(NullLiteral())]),
        positionalParameters: <VariableDeclaration>[VariableDeclaration('x')]),
    isStatic: false,
    fileUri: targetFile,
  );
  svc.addProcedure(target);

  final Map<Uri, Source> uriToSource = <Uri, Source>{
    aspectFile: Source(<int>[0], Uint8List.fromList(<int>[120]),
        aspectLib.importUri, aspectLib.fileUri),
    targetFile: Source(<int>[0], Uint8List.fromList(<int>[120]),
        targetLib.importUri, targetLib.fileUri),
  };
  final Map<String, Library> libraryMap = <String, Library>{
    'package:t/target.dart': targetLib,
    'package:t/aspect.dart': aspectLib,
  };

  final AopItemInfo info = AopItemInfo(
    mode: AopMode.inject,
    importUri: 'package:t/target.dart',
    clsName: 'Svc',
    methodName: 'run',
    isStatic: false,
    lineNum: 1,
    aopMember: advice,
  );

  final List<Statement> origStmts =
      (advice.function.body as Block).statements.toList();

  final AopInjectImplTransformer t =
      AopInjectImplTransformer(<AopItemInfo>[info], libraryMap, uriToSource);

  group('inject clones advice statements (A2 / #15)', () {
    final List<Statement> returned =
        t.onPrepareTransform(targetLib, target, info);

    check(returned.length == 2, 'prepare returns both advice statements');
    check(
        returned.length == 2 &&
            !identical(returned[0], origStmts[0]) &&
            !identical(returned[1], origStmts[1]),
        'returned statements are CLONES (not the advice node instances)');
    check(
        returned.isNotEmpty &&
            returned[0].runtimeType == origStmts[0].runtimeType &&
            returned[1].runtimeType == origStmts[1].runtimeType,
        'clones preserve statement types');

    check((advice.function.body as Block).statements.length == 2,
        'advice body unchanged after onPrepareTransform');

    t.onPostTransform(info);

    // The key A2 invariant: the previous implementation cleared this to length 0.
    check((advice.function.body as Block).statements.length == 2,
        'advice body is NOT cleared after onPostTransform (reusable)');
    check(
        identical(
            (advice.function.body as Block).statements[0], origStmts[0]),
        'advice still owns its original statement nodes');
  });

  group('advice is reusable across weaves', () {
    final List<Statement> first = t.onPrepareTransform(targetLib, target, info);
    t.onPostTransform(info);
    final List<Statement> second = t.onPrepareTransform(targetLib, target, info);
    t.onPostTransform(info);

    check(first.length == 2 && second.length == 2,
        'both weaves see the advice statements (advice not consumed)');
    check(
        first.isNotEmpty &&
            second.isNotEmpty &&
            !identical(first[0], second[0]),
        'each weave gets a FRESH clone (no shared node between weaves)');
  });

  group('mergeTransform folds same-line items without mutating advice (A2)', () {
    final Procedure adviceA = Procedure(
      Name('mA'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[ExpressionStatement(StringLiteral('A'))]))
        ..fileOffset = 10,
      isStatic: true,
      fileUri: aspectFile,
    )..fileOffset = 10;
    final Procedure adviceB = Procedure(
      Name('mB'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[ExpressionStatement(StringLiteral('B'))]))
        ..fileOffset = 10,
      isStatic: true,
      fileUri: aspectFile,
    )..fileOffset = 10;
    aspectCls.addProcedure(adviceA);
    aspectCls.addProcedure(adviceB);

    AopItemInfo mk(Procedure advice) => AopItemInfo(
          mode: AopMode.inject,
          importUri: 'package:t/target.dart',
          clsName: 'Svc',
          methodName: 'run',
          isStatic: false,
          lineNum: 5,
          aopMember: advice,
        );
    final AopItemInfo infoA = mk(adviceA);
    final AopItemInfo infoB = mk(adviceB);

    final AopInjectImplTransformer tm = AopInjectImplTransformer(
        <AopItemInfo>[infoA, infoB], libraryMap, uriToSource);
    tm.sortTransform();
    tm.mergeTransform();

    // The previous implementation moved one advice's statements into the
    // other's body (insertAll), leaving it length 2. Now neither is touched.
    check((adviceA.function.body as Block).statements.length == 1,
        'advice A body not mutated by merge');
    check((adviceB.function.body as Block).statements.length == 1,
        'advice B body not mutated by merge');

    final List<Statement> p1 = tm.onPrepareTransform(targetLib, target, infoA);
    tm.onPostTransform(infoA);
    final List<Statement> p2 = tm.onPrepareTransform(targetLib, target, infoB);
    tm.onPostTransform(infoB);
    check(p1.length + p2.length == 3,
        'merge recorded the sibling: survivor yields 2, the other yields 1');
    check(p1.length == 2 || p2.length == 2,
        'one item (the survivor) injects BOTH advice statements');
  });

  // `//AOPD Ignore` mock-var path: a var the advice declares only to satisfy the
  // aspect's own compilation is skipped (not injected), and references to it in
  // the injected statements are remapped BY NAME to the target's variable. This
  // is the A2 path most likely to regress (the mock var is now cloned), and the
  // example does not exercise it.
  group('inject remaps //AOPD Ignore mock vars to the target var (A2)', () {
    final Uri aFile = Uri.parse('file:///ignore_aspect.dart');
    final Library aLib =
        Library(Uri.parse('package:t/ignore_aspect.dart'), fileUri: aFile);
    final Class aCls = Class(name: 'IgnoreAspect', fileUri: aFile);
    aLib.addClass(aCls);

    // The mock var declaration sits on a line ending with the Ignore marker so
    // checkIfSkipableVarDeclaration recognizes it (offset 0 => line 0).
    final VariableDeclaration mockX = VariableDeclaration('x')..fileOffset = 0;
    final ExpressionStatement useX = ExpressionStatement(VariableGet(mockX));
    final Procedure advice = Procedure(
      Name('inj'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[mockX, useX]))..fileOffset = 0,
      isStatic: true,
      fileUri: aFile,
    )..fileOffset = 0;
    aCls.addProcedure(advice);

    final String markerLine = 'var x = 0; //AOPD Ignore\n';
    final Uri tFile = Uri.parse('file:///ignore_target.dart');
    final Library tLib =
        Library(Uri.parse('package:t/ignore_target.dart'), fileUri: tFile);
    final Class tCls = Class(name: 'T', fileUri: tFile);
    tLib.addClass(tCls);
    final VariableDeclaration targetX = VariableDeclaration('x');
    final Procedure tProc = Procedure(
      Name('run'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[ReturnStatement(NullLiteral())]),
          positionalParameters: <VariableDeclaration>[targetX]),
      isStatic: false,
      fileUri: tFile,
    );
    tCls.addProcedure(tProc);

    final Map<Uri, Source> uriToSource = <Uri, Source>{
      aFile: Source(<int>[0, markerLine.length],
          Uint8List.fromList(markerLine.codeUnits), aLib.importUri, aFile),
    };
    final Map<String, Library> libraryMap = <String, Library>{
      'package:t/ignore_target.dart': tLib,
      'package:t/ignore_aspect.dart': aLib,
    };
    final AopItemInfo info = AopItemInfo(
      mode: AopMode.inject,
      importUri: 'package:t/ignore_target.dart',
      clsName: 'T',
      methodName: 'run',
      isStatic: false,
      lineNum: 1,
      aopMember: advice,
    );

    final AopInjectImplTransformer t =
        AopInjectImplTransformer(<AopItemInfo>[info], libraryMap, uriToSource);
    final List<Statement> returned = t.onPrepareTransform(tLib, tProc, info);

    // The mock var-decl is skipped; only the using statement is injected.
    check(returned.length == 1, 'mock var declaration is NOT injected (skipped)');
    final Statement only = returned.isEmpty ? EmptyStatement() : returned.first;
    final Expression? expr =
        only is ExpressionStatement ? only.expression : null;
    check(expr is VariableGet, 'injected statement reads the mock var');
    if (expr is VariableGet) {
      check(!identical(expr.variable, mockX),
          'the injected reference is to a CLONE of the mock var, not the original');
      // visitVariableGet remaps the (cloned) mock-var reference by name.
      final VariableGet remapped = t.visitVariableGet(expr);
      check(identical(remapped.variable, targetX),
          'mock-var reference is remapped to the target method\'s own var');
    }
    // Advice body is untouched.
    check((advice.function.body as Block).statements.length == 2,
        'advice body unchanged (mock decl + use both retained)');
  });

  // visitVariableDeclaration must tolerate UNNAMED synthetic vars (async/for
  // desugaring temps). Previously `node.name!` threw on them and aborted the
  // whole inject item for any method containing such temps.
  group('inject tolerates unnamed synthetic VariableDeclarations', () {
    final AopInjectImplTransformer t = AopInjectImplTransformer(
        <AopItemInfo>[], <String, Library>{}, <Uri, Source>{});
    bool threw = false;
    try {
      // An unnamed local (name == null), as kernel emits for compiler temps.
      t.visitVariableDeclaration(VariableDeclaration(null));
      // A named one still works alongside it.
      t.visitVariableDeclaration(VariableDeclaration('kept'));
    } on Object {
      threw = true;
    }
    check(!threw,
        'visitVariableDeclaration does not throw on an unnamed variable');
  });

  finish();
}
