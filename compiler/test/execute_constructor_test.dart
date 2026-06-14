// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Behavioral test for M1.1 crash-safety: @Execute on a constructor must NOT
// crash the transform (it used to: `Constructor as Procedure`). It must skip
// with an UNSUPPORTED diagnostic and leave the constructor unmodified.

import 'package:kernel/ast.dart';

import '../transformer/aop_diagnostic_reporter.dart';
import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/aop_transform_utils.dart';
import '../transformer/rewriters/execute_transformer.dart';
import '_harness.dart';

void main() {
  final Uri targetFile = Uri.parse('file:///target.dart');
  final Library targetLib =
      Library(Uri.parse('package:t/target.dart'), fileUri: targetFile);
  final Class foo = Class(name: 'Foo', fileUri: targetFile);
  targetLib.addClass(foo);
  final Statement ctorBody = EmptyStatement();
  final Constructor ctor = Constructor(
    FunctionNode(ctorBody),
    name: Name(''),
    fileUri: targetFile,
  );
  foo.addConstructor(ctor);

  final Procedure advice = Procedure(
    Name('advice'),
    ProcedureKind.Method,
    FunctionNode(EmptyStatement(),
        positionalParameters: <VariableDeclaration>[VariableDeclaration('pc')]),
    isStatic: true,
    fileUri: targetFile,
  );
  targetLib.addProcedure(advice);

  final AopItemInfo info = AopItemInfo(
    mode: AopMode.execute,
    importUri: 'package:t/target.dart',
    clsName: 'Foo',
    methodName: 'Foo', // matches the unnamed constructor (nameForConstructor)
    isStatic: true,
    aopMember: advice,
  );

  final List<String> diagnostics = <String>[];
  AopUtils.diagnostics = AopDiagnosticReporter(diagnostics.add);

  group('constructor @Execute degrades safely (M1.1)', () {
    bool threw = false;
    try {
      AopExecuteImplTransformer(
        <AopItemInfo>[info],
        <String, Library>{'package:t/target.dart': targetLib},
        <Uri, Source>{},
      ).aopTransform();
    } catch (_) {
      threw = true;
    }

    check(!threw, 'transform does not throw on constructor @Execute');
    check(identical(ctor.function.body, ctorBody),
        'constructor body left unmodified');
    final bool reported = diagnostics
        .any((String d) => d.contains('constructor @Execute is not supported'));
    check(reported, 'an UNSUPPORTED diagnostic was emitted');
  });

  finish();
}
