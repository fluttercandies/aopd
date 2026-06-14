// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Behavioral test for the FieldGet transformer (M3.4 + M3.5): drives the real
// AopFieldGetImplTransformer over a constructed kernel tree and asserts a
// static field read is replaced by an advice call receiving a real PointCut.
// This is the regression guard for the bug where static FieldGet matched via
// (unbound) canonicalName and silently never fired.

import 'dart:typed_data';

import 'package:kernel/ast.dart';

import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/aop_transform_utils.dart';
import '../transformer/rewriters/field_get_transformer.dart';
import '_harness.dart';

void main() {
  // --- Target library: class Store { static channel; } ---
  final Uri targetFile = Uri.parse('file:///target.dart');
  final Library targetLib =
      Library(Uri.parse('package:t/target.dart'), fileUri: targetFile);
  final Class store = Class(name: 'Store', fileUri: targetFile);
  targetLib.addClass(store);
  final Field channel = Field.mutable(Name('channel'),
      type: const DynamicType(), isStatic: true, fileUri: targetFile);
  store.addField(channel);

  // --- Aspect advice: static String advice(PointCut pc) ---
  final Uri aspectFile = Uri.parse('file:///aspect.dart');
  final Library aspectLib =
      Library(Uri.parse('package:t/aspect.dart'), fileUri: aspectFile);
  final Procedure advice = Procedure(
    Name('advice'),
    ProcedureKind.Method,
    FunctionNode(EmptyStatement(),
        positionalParameters: <VariableDeclaration>[VariableDeclaration('pc')]),
    isStatic: true,
    fileUri: aspectFile,
  );
  aspectLib.addProcedure(advice);

  // --- Minimal PointCut class so buildMinimalPointCut works ---
  final Uri pcFile = Uri.parse('file:///pointcut.dart');
  final Library pcLib =
      Library(Uri.parse('package:aopd/src/annotations/pointcut.dart'),
          fileUri: pcFile);
  final Class pointCutClass = Class(name: 'PointCut', fileUri: pcFile);
  pcLib.addClass(pointCutClass);
  pointCutClass
      .addConstructor(Constructor(FunctionNode(EmptyStatement()),
          name: Name(''), fileUri: pcFile));
  final Procedure proceed = Procedure(Name('proceed'), ProcedureKind.Method,
      FunctionNode(EmptyStatement()),
      fileUri: pcFile);
  pointCutClass.addProcedure(proceed);
  AopUtils.pointCutProceedProcedure = proceed;

  // --- Reading library: read() => Store.channel; ---
  final Uri readFile = Uri.parse('file:///read.dart');
  final Library readLib =
      Library(Uri.parse('package:t/read.dart'), fileUri: readFile);
  final ReturnStatement readReturn =
      ReturnStatement(StaticGet(channel)..fileOffset = 0);
  final Procedure reader = Procedure(
    Name('read'),
    ProcedureKind.Method,
    FunctionNode(readReturn),
    isStatic: true,
    fileUri: readFile,
  );
  readLib.addProcedure(reader);

  final Map<Uri, Source> uriToSource = <Uri, Source>{
    readFile: Source(<int>[0], Uint8List.fromList(<int>[120]),
        readLib.importUri, readLib.fileUri),
  };

  final AopItemInfo info = AopItemInfo(
    mode: AopMode.fieldGet,
    importUri: 'package:t/target.dart',
    clsName: 'Store',
    methodName: null,
    fieldName: 'channel',
    isStatic: true,
    aopMember: advice,
  );

  group('static FieldGet is woven (M3.5 regression guard)', () {
    AopFieldGetImplTransformer(<AopItemInfo>[info], uriToSource)
        .visitLibrary(readLib);

    final Expression result = (reader.function.body as ReturnStatement).expression!;
    check(result is StaticInvocation, 'read replaced by a StaticInvocation');
    if (result is StaticInvocation) {
      check(result.target == advice, 'invocation targets the advice');
      check(result.arguments.positional.length == 1, 'advice gets one argument');
      final Expression arg = result.arguments.positional.first;
      check(arg is ConstructorInvocation, 'argument is a real PointCut (not null)');
      check(arg is! NullLiteral, 'argument is NOT a bare null (the old bug)');
      if (arg is ConstructorInvocation) {
        // M5.4: fieldGet now supplies a proceedClosure so proceed() can read
        // the original field value.
        final Iterable<NamedExpression> closures = arg.arguments.named
            .where((NamedExpression n) => n.name == 'proceedClosure');
        check(closures.length == 1,
            'PointCut carries a proceedClosure (M5.4)');
        check(closures.isNotEmpty && closures.first.value is FunctionExpression,
            'proceedClosure is a FunctionExpression reading the field');
      }
    }
  });

  group('non-matching field is left unchanged', () {
    // A reader of a different field must not be rewritten.
    final Field other = Field.mutable(Name('other'),
        type: const DynamicType(), isStatic: true, fileUri: targetFile);
    store.addField(other);
    final ReturnStatement otherReturn =
        ReturnStatement(StaticGet(other)..fileOffset = 0);
    final Procedure otherReader = Procedure(Name('readOther'),
        ProcedureKind.Method, FunctionNode(otherReturn),
        isStatic: true, fileUri: readFile);
    readLib.addProcedure(otherReader);

    AopFieldGetImplTransformer(<AopItemInfo>[info], uriToSource)
        .visitLibrary(readLib);

    check((otherReader.function.body as ReturnStatement).expression is StaticGet,
        'unmatched field read stays a StaticGet');
  });

  finish();
}
