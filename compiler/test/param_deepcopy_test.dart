// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// #4/#7: woven stubs (@Execute) and added methods (@Add) must OWN their
// parameter declarations -- never share the source method's VariableDeclaration
// nodes. A shared parameter would be parented under two functions at once
// (an AST invariant violation). These tests assert, after weaving, that:
//   * the stub/added method's params are disjoint (by identity) from the
//     source method's params,
//   * every VariableGet inside the stub/added body resolves to that method's
//     OWN params (not the source's),
//   * each param is parented under its owning function,
//   * the source method's generics are erased on the stub (non-generic stub).

import 'dart:typed_data';

import 'package:kernel/ast.dart';

import '../transformer/rewriters/add_transformer.dart';
import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/aop_transform_utils.dart';
import '../transformer/rewriters/execute_transformer.dart';
import '_harness.dart';

/// Collects the [VariableDeclaration]s referenced by every `VariableGet` under
/// a node, so we can check they all belong to the expected parameter set.
class _VarGetCollector extends RecursiveVisitor {
  final Set<VariableDeclaration> vars = <VariableDeclaration>{};

  @override
  void visitVariableGet(VariableGet node) {
    vars.add(node.variable);
    super.visitVariableGet(node);
  }
}

Set<VariableDeclaration> _varGetsIn(TreeNode node) {
  final _VarGetCollector collector = _VarGetCollector();
  node.accept(collector);
  return collector.vars;
}

/// Sets up the shared PointCut runtime + SDK helper handles used by both modes.
Class _installPointCutRuntime() {
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
    'stubKey',
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

  // Dummy `[]` operators so concatArguments4PointcutStubCall can name them when
  // a woven method actually has parameters.
  AopUtils.listGetProcedure = Procedure(Name('[]'), ProcedureKind.Operator,
      FunctionNode(EmptyStatement()),
      fileUri: pcFile);
  AopUtils.mapGetProcedure = Procedure(Name('[]'), ProcedureKind.Operator,
      FunctionNode(EmptyStatement()),
      fileUri: pcFile);
  return pointCutClass;
}

void main() {
  _installPointCutRuntime();

  // ===========================================================================
  // @Execute: generic method with a positional (typed by the type param) and a
  // required named parameter, body reading both.
  // ===========================================================================
  group('execute stub owns its parameters (no shared nodes)', () {
    final Uri aspectFile = Uri.parse('file:///aspect.dart');
    final Library aspectLib =
        Library(Uri.parse('package:t/aspect.dart'), fileUri: aspectFile);
    final Class aspectCls = Class(name: 'ExecAspect', fileUri: aspectFile);
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

    final Uri targetFile = Uri.parse('file:///target.dart');
    final Library targetLib =
        Library(Uri.parse('package:t/target.dart'), fileUri: targetFile);
    final Class svc = Class(name: 'Svc', fileUri: targetFile);
    targetLib.addClass(svc);

    final TypeParameter typeParam = TypeParameter('T', const DynamicType());
    final VariableDeclaration paramA = VariableDeclaration('a',
        type: TypeParameterType(typeParam, Nullability.nonNullable));
    final VariableDeclaration paramB =
        VariableDeclaration('b', type: const DynamicType(), isRequired: true);
    final Procedure compute = Procedure(
      Name('compute'),
      ProcedureKind.Method,
      FunctionNode(
        Block(<Statement>[
          ExpressionStatement(VariableGet(paramB)),
          ReturnStatement(VariableGet(paramA)),
        ]),
        typeParameters: <TypeParameter>[typeParam],
        positionalParameters: <VariableDeclaration>[paramA],
        namedParameters: <VariableDeclaration>[paramB],
        requiredParameterCount: 1,
        returnType: const DynamicType(),
      ),
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
    };

    final AopItemInfo info = AopItemInfo(
      mode: AopMode.execute,
      importUri: 'package:t/target.dart',
      clsName: 'Svc',
      methodName: 'compute',
      isStatic: true,
      aopMember: advice,
    );

    // Capture the ORIGINAL parameter identities before weaving.
    final VariableDeclaration origA = paramA;
    final VariableDeclaration origB = paramB;

    AopExecuteImplTransformer(<AopItemInfo>[info], libraryMap, uriToSource)
        .aopTransform();

    final Iterable<Procedure> stubs = svc.procedures
        .where((Procedure p) => p.name.text.startsWith('compute_aop_stub_'));
    check(stubs.length == 1, 'one moved-body stub created');
    final Procedure stub = stubs.first;

    // The original method keeps its own params.
    check(identical(compute.function.positionalParameters.first, origA),
        'original method keeps its positional param node');
    check(identical(compute.function.namedParameters.first, origB),
        'original method keeps its named param node');

    final Set<VariableDeclaration> origParams = <VariableDeclaration>{
      ...compute.function.positionalParameters,
      ...compute.function.namedParameters,
    };
    final Set<VariableDeclaration> stubParams = <VariableDeclaration>{
      ...stub.function.positionalParameters,
      ...stub.function.namedParameters,
    };

    check(stubParams.length == 2, 'stub has 1 positional + 1 named param');
    check(origParams.intersection(stubParams).isEmpty,
        'stub params are DISJOINT from original params (no shared nodes)');

    // Every VariableGet in the stub body resolves to the stub's own params.
    final Set<VariableDeclaration> stubBodyVars =
        _varGetsIn(stub.function.body!);
    check(stubBodyVars.isNotEmpty, 'stub body reads its parameters');
    check(stubBodyVars.difference(stubParams).isEmpty,
        'stub body only references the stub\'s own params');
    check(stubBodyVars.intersection(origParams).isEmpty,
        'stub body references NONE of the original method\'s params');

    // The original method's NEW body (advice call) references original params
    // (forwarded into the PointCut). It also contains the proceedClosure, whose
    // own `pc` parameter is declared in-scope -- so the meaningful invariant is:
    // it references the original params and NEVER leaks into the stub's params.
    final Set<VariableDeclaration> origBodyVars =
        _varGetsIn(compute.function.body!);
    check(origBodyVars.containsAll(origParams),
        'rewritten original body forwards the original params');
    check(origBodyVars.intersection(stubParams).isEmpty,
        'rewritten original body references NONE of the stub\'s params');

    // Parent invariants.
    check(
        stub.function.positionalParameters.first.parent == stub.function &&
            stub.function.namedParameters.first.parent == stub.function,
        'stub params are parented under the stub function');
    check(
        compute.function.positionalParameters.first.parent ==
                compute.function &&
            compute.function.namedParameters.first.parent == compute.function,
        'original params are parented under the original function');

    // Generics erased on the stub.
    check(stub.function.typeParameters.isEmpty,
        'stub is non-generic (type parameters erased)');
    check(stub.function.positionalParameters.first.type is DynamicType,
        'stub positional param type erased to dynamic');
  });

  // ===========================================================================
  // @Add: an instance advice `added(PointCut pc, int x)` adds a method to a
  // target class in another library; the added method must own fresh params and
  // forward its OWN `x`, not the advice's.
  // ===========================================================================
  group('add method owns its parameters (no shared nodes)', () {
    final Uri aspectFile = Uri.parse('file:///add_aspect.dart');
    final Library aspectLib =
        Library(Uri.parse('package:t/add_aspect.dart'), fileUri: aspectFile);
    final Class aspectCls = Class(name: 'AddAspect', fileUri: aspectFile);
    aspectLib.addClass(aspectCls);
    aspectCls.addConstructor(Constructor(FunctionNode(EmptyStatement()),
        name: Name(''), fileUri: aspectFile));

    final VariableDeclaration advicePc = VariableDeclaration('pc');
    final VariableDeclaration adviceX =
        VariableDeclaration('x', type: const DynamicType());
    final Procedure added = Procedure(
      Name('added'),
      ProcedureKind.Method,
      FunctionNode(
        Block(<Statement>[ReturnStatement(VariableGet(adviceX))]),
        positionalParameters: <VariableDeclaration>[advicePc, adviceX],
        returnType: const DynamicType(),
      ),
      isStatic: false,
      fileUri: aspectFile,
    );
    aspectCls.addProcedure(added);

    final Uri targetFile = Uri.parse('file:///add_target.dart');
    final Library targetLib =
        Library(Uri.parse('package:t/add_target.dart'), fileUri: targetFile);
    final Class target = Class(name: 'Target', fileUri: targetFile);
    targetLib.addClass(target);

    final Map<Uri, Source> uriToSource = <Uri, Source>{
      targetFile: Source(<int>[0], Uint8List.fromList(<int>[120]),
          targetLib.importUri, targetLib.fileUri),
    };

    final AopItemInfo info = AopItemInfo(
      mode: AopMode.add,
      importUri: 'package:t/add_target.dart',
      clsName: 'Target',
      methodName: 'added',
      isStatic: false,
      aopMember: added,
    );

    AopAddImplTransformer(<AopItemInfo>[info], uriToSource)
        .visitLibrary(targetLib);

    final Iterable<Procedure> addedOnTarget =
        target.procedures.where((Procedure p) => p.name.text == 'added');
    check(addedOnTarget.length == 1, 'method added to the target class');
    final Procedure addedMethod = addedOnTarget.first;

    final Set<VariableDeclaration> adviceParams = <VariableDeclaration>{
      advicePc,
      adviceX,
    };
    final Set<VariableDeclaration> addedParams = <VariableDeclaration>{
      ...addedMethod.function.positionalParameters,
      ...addedMethod.function.namedParameters,
    };

    check(addedParams.length == 2, 'added method has fresh pc + x params');
    check(adviceParams.intersection(addedParams).isEmpty,
        'added method params are DISJOINT from advice params (no shared nodes)');

    final Set<VariableDeclaration> addedBodyVars =
        _varGetsIn(addedMethod.function.body!);
    check(addedBodyVars.difference(addedParams).isEmpty,
        'added body only references the added method\'s own params');
    check(addedBodyVars.intersection(adviceParams).isEmpty,
        'added body references NONE of the advice params');

    check(
        addedMethod.function.positionalParameters
            .every((VariableDeclaration v) => v.parent == addedMethod.function),
        'added params are parented under the added method');

    // The advice method is untouched -- it keeps its own params.
    check(identical(added.function.positionalParameters[1], adviceX),
        'advice method keeps its own param node');
  });

  // ===========================================================================
  // @Execute on an `async` method: the moved-body stub must keep asyncMarker AND
  // emittedValueType. The kernel verifier rejects an Async function with a null
  // emittedValueType, and a normal build does NOT run the verifier -- so dropping
  // it would emit invalid kernel straight to the VM.
  // ===========================================================================
  group('execute stub preserves async value type (emittedValueType)', () {
    final Uri aspectFile = Uri.parse('file:///aspect_async.dart');
    final Library aspectLib =
        Library(Uri.parse('package:t/aspect_async.dart'), fileUri: aspectFile);
    final Class aspectCls = Class(name: 'AsyncAspect', fileUri: aspectFile);
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

    final Uri targetFile = Uri.parse('file:///target_async.dart');
    final Library targetLib = Library(Uri.parse('package:t/target_async.dart'),
        fileUri: targetFile);
    final Class svc = Class(name: 'ASvc', fileUri: targetFile);
    targetLib.addClass(svc);
    final Procedure asyncCompute = Procedure(
      Name('compute'),
      ProcedureKind.Method,
      FunctionNode(
        Block(<Statement>[ReturnStatement(IntLiteral(1))]),
        returnType: const DynamicType(),
        asyncMarker: AsyncMarker.Async,
        dartAsyncMarker: AsyncMarker.Async,
        emittedValueType: const DynamicType(),
      ),
      isStatic: true,
      fileUri: targetFile,
    );
    svc.addProcedure(asyncCompute);

    final Map<Uri, Source> uriToSource = <Uri, Source>{
      targetFile: Source(<int>[0], Uint8List.fromList(<int>[120]),
          targetLib.importUri, targetLib.fileUri),
    };
    final Map<String, Library> libraryMap = <String, Library>{
      'package:t/target_async.dart': targetLib,
      'package:t/aspect_async.dart': aspectLib,
    };
    final AopItemInfo info = AopItemInfo(
      mode: AopMode.execute,
      importUri: 'package:t/target_async.dart',
      clsName: 'ASvc',
      methodName: 'compute',
      isStatic: true,
      aopMember: advice,
    );

    AopExecuteImplTransformer(<AopItemInfo>[info], libraryMap, uriToSource)
        .aopTransform();

    final Iterable<Procedure> stubs = svc.procedures
        .where((Procedure p) => p.name.text.startsWith('compute_aop_stub_'));
    check(stubs.length == 1, 'async method woven into a stub');
    if (stubs.isNotEmpty) {
      final FunctionNode fn = stubs.first.function;
      check(fn.asyncMarker == AsyncMarker.Async, 'stub keeps the Async marker');
      check(fn.emittedValueType != null,
          'stub preserves emittedValueType (verifier-valid Async function)');
    }
  });

  finish();
}
