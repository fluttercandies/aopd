// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Crash-safety negative (C-loop) tests for P1b: a malformed inject/add item
// must "degrade but loud" (skip with a diagnostic) rather than throw and abort
// the whole mode.

import 'dart:typed_data';

import 'package:kernel/ast.dart';

import '../transformer/rewriters/add_transformer.dart';
import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/inject_transformer.dart';
import '_harness.dart';

void main() {
  group('add: regex superCls walking to the root must not throw', () {
    // Regression for the `superClazz.superclass!` bug: when a regex @Add has a
    // superCls that matches nothing, the walk reaches a root class whose
    // superclass is null. The old `!` threw there, aborting the whole add mode.
    final Uri file = Uri.parse('file:///m.dart');
    final Library lib = Library(Uri.parse('package:t/m.dart'), fileUri: file);
    final Class base = Class(name: 'Base', fileUri: file);
    lib.addClass(base);
    final Class derived = Class(
        name: 'Derived', fileUri: file, supertype: base.asThisSupertype);
    lib.addClass(derived);

    final Uri aspectFile = Uri.parse('file:///aspect.dart');
    final Library aspectLib =
        Library(Uri.parse('package:t/aspect.dart'), fileUri: aspectFile);
    final Class aspectCls = Class(name: 'Aspect', fileUri: aspectFile);
    aspectLib.addClass(aspectCls);
    final Procedure extra = Procedure(
        Name('extra'),
        ProcedureKind.Method,
        FunctionNode(EmptyStatement(),
            positionalParameters: <VariableDeclaration>[
              VariableDeclaration('pc')
            ]),
        fileUri: aspectFile);
    aspectCls.addProcedure(extra);

    final AopItemInfo item = AopItemInfo(
      mode: AopMode.add,
      importUri: 'package:t/m.dart',
      clsName: 'Derived',
      methodName: null,
      isRegex: true,
      superCls: 'NoSuchSuper',
      aopMember: extra,
    );

    bool threw = false;
    try {
      AopAddImplTransformer(<AopItemInfo>[item], <Uri, Source>{})
          .visitLibrary(lib);
    } catch (_) {
      threw = true;
    }
    check(!threw, 'no throw walking the superclass chain to a null root');
    check(
        derived.procedures
            .where((Procedure p) => p.name.text == 'extra')
            .isEmpty,
        'no method added when superCls does not match');
  });

  group('inject: non-block advice body degrades without throwing', () {
    final Uri file = Uri.parse('file:///t.dart');
    final Library lib = Library(Uri.parse('package:t/t.dart'), fileUri: file);
    final Class cls = Class(name: 'T', fileUri: file);
    lib.addClass(cls);
    final Procedure m = Procedure(
        Name('m'),
        ProcedureKind.Method,
        FunctionNode(Block(<Statement>[ReturnStatement(IntLiteral(0))]),
            returnType: const DynamicType()),
        fileUri: file);
    cls.addProcedure(m);

    // Aspect advice with a NON-block body (e.g. an `=> expr` method).
    final Uri aspectFile = Uri.parse('file:///aspect.dart');
    final Library aspectLib =
        Library(Uri.parse('package:t/aspect.dart'), fileUri: aspectFile);
    final Class aspectCls = Class(name: 'Aspect', fileUri: aspectFile);
    aspectLib.addClass(aspectCls);
    final Procedure adv = Procedure(Name('adv'), ProcedureKind.Method,
        FunctionNode(ReturnStatement(IntLiteral(0))),
        fileUri: aspectFile);
    aspectCls.addProcedure(adv);

    final AopItemInfo item = AopItemInfo(
      mode: AopMode.inject,
      importUri: 'package:t/t.dart',
      clsName: 'T',
      methodName: 'm',
      isStatic: false,
      lineNum: 1,
      aopMember: adv,
    );

    final Map<String, Library> libMap = <String, Library>{
      'package:t/t.dart': lib,
      'package:t/aspect.dart': aspectLib,
    };
    final Map<Uri, Source> uriToSource = <Uri, Source>{
      file: Source(<int>[0], Uint8List.fromList(<int>[120]), lib.importUri,
          lib.fileUri),
    };

    bool threw = false;
    try {
      AopInjectImplTransformer(<AopItemInfo>[item], libMap, uriToSource)
          .aopTransform();
    } catch (_) {
      threw = true;
    }
    check(!threw, 'non-block advice body does not throw (degrades)');
    final Block body = m.function.body as Block;
    check(
        body.statements.length == 1 &&
            body.statements.first is ReturnStatement,
        'target method body left unchanged');
  });

  finish();
}
