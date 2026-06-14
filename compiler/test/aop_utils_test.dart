// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Unit tests for AopUtils pure/constructible helpers, built directly on small
// in-memory kernel nodes (no CFE pipeline needed).
//   * firstInvalidRegex   — M1.0 regex up-front validation
//   * findClassOfNode      — M1.2 (the top-level null path that used to crash)
//   * buildMinimalPointCut — M3.4 FieldGet real-PointCut construction

import 'dart:typed_data';

import 'package:kernel/ast.dart';

import '../transformer/aop_diagnostic_reporter.dart';
import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '../transformer/rewriters/aop_transform_utils.dart';
import '_harness.dart';

final Uri _fileUri = Uri.parse('file:///t.dart');

Library _newLibrary() =>
    Library(Uri.parse('package:t/t.dart'), fileUri: _fileUri);

Procedure _newMethod(String name) => Procedure(
  Name(name),
  ProcedureKind.Method,
  FunctionNode(EmptyStatement()),
  fileUri: _fileUri,
);

void main() {
  group('firstInvalidRegex (M1.0)', () {
    check(
      AopUtils.firstInvalidRegex(<String?>['run.*', 'Foo', null, '']) == null,
      'valid patterns + null/empty -> null',
    );
    check(
      AopUtils.firstInvalidRegex(<String?>['package:example/(']) ==
          'package:example/(',
      'unbalanced paren is reported',
    );
    check(
      AopUtils.firstInvalidRegex(<String?>['ok', 'a[b']) == 'a[b',
      'first invalid among several is reported',
    );
    check(
      AopUtils.firstInvalidRegex(<String?>[]) == null,
      'empty list -> null',
    );
  });

  group('findClassOfNode (M1.2 — must not crash at top level)', () {
    final Library lib = _newLibrary();
    final Class cls = Class(name: 'Foo', fileUri: _fileUri);
    lib.addClass(cls);
    final Procedure method = _newMethod('m');
    cls.addProcedure(method);
    final Procedure topProc = _newMethod('top');
    lib.addProcedure(topProc);

    check(
      AopUtils.findClassOfNode(method) == cls,
      'member inside a class resolves to that class',
    );
    check(
      AopUtils.findClassOfNode(method.function) == cls,
      'nested node (FunctionNode) resolves to the enclosing class',
    );
    check(AopUtils.findClassOfNode(cls) == cls, 'a Class resolves to itself');
    check(
      AopUtils.findClassOfNode(topProc) == null,
      'top-level member returns null (previously `null as Class` crash)',
    );
    check(AopUtils.findClassOfNode(lib) == null, 'a Library returns null');
  });

  group('AopKernelResolver canonical-name fallback', () {
    final Library lib = _newLibrary();
    final Procedure top = _newMethod('top');
    lib.addProcedure(top);

    final Class cls = Class(name: 'Box', fileUri: _fileUri);
    lib.addClass(cls);
    final Procedure method = _newMethod('open');
    cls.addProcedure(method);
    final Field field = Field.mutable(
      Name('value'),
      type: const DynamicType(),
      fileUri: _fileUri,
    );
    cls.addField(field);
    final Constructor constructor = Constructor(
      FunctionNode(EmptyStatement()),
      name: Name('named'),
      fileUri: _fileUri,
    );
    cls.addConstructor(constructor);

    final Component component = Component(libraries: <Library>[lib]);
    component.computeCanonicalNames();
    final Map<String, Library> libraries = <String, Library>{
      lib.importUri.toString(): lib,
    };

    final CanonicalName topName = top.reference.canonicalName!;
    final CanonicalName methodName = method.reference.canonicalName!;
    final CanonicalName fieldName = field.fieldReference.canonicalName!;
    final CanonicalName constructorName = constructor.reference.canonicalName!;

    top.reference.node = null;
    method.reference.node = null;
    field.fieldReference.node = null;
    constructor.reference.node = null;

    final AopKernelResolver resolver = AopKernelResolver(libraries);

    check(
      resolver.resolve(topName) == top,
      'top-level procedure resolves from an unbound canonical name',
    );
    check(
      resolver.resolve(methodName) == method,
      'class procedure resolves from an unbound canonical name',
    );
    check(
      resolver.resolve(fieldName) == field,
      'class field resolves from an unbound canonical name',
    );
    check(
      resolver.resolve(constructorName) == constructor,
      'class constructor resolves from an unbound canonical name',
    );
    check(
      resolver.libraryImportUriOf(methodName) == lib.importUri.toString(),
      'resolver reports the owning library import URI',
    );
    check(
      resolver.ownerClassNameOf(methodName) == 'Box',
      'resolver reports the owning class name',
    );
    check(
      AopUtils.getNodeFromCanonicalName(<String, Library>{}, methodName) ==
          null,
      'missing library returns null instead of throwing',
    );
  });

  group('buildMinimalPointCut (M3.4)', () {
    // Minimal fake PointCut class with a constructor + a `proceed` method.
    final Library lib = _newLibrary();
    final Class pointCutClass = Class(name: 'PointCut', fileUri: _fileUri);
    lib.addClass(pointCutClass);
    final Constructor ctor = Constructor(
      FunctionNode(EmptyStatement()),
      name: Name(''),
      fileUri: _fileUri,
    );
    pointCutClass.addConstructor(ctor);
    final Procedure proceed = _newMethod('proceed');
    pointCutClass.addProcedure(proceed);
    AopUtils.pointCutProceedProcedure = proceed;

    final ConstructorInvocation inv = AopUtils.buildMinimalPointCut(
      <String, String>{'file': 'x', 'lineNum': '7'},
      NullLiteral(),
    );

    check(inv.target == ctor, 'targets the PointCut constructor');
    check(
      inv.arguments.positional.length == 8,
      'PointCut takes exactly 8 positional args',
    );
    final Expression sourceInfos = inv.arguments.positional[0];
    check(sourceInfos is MapLiteral, 'arg0 sourceInfos is a MapLiteral');
    check(
      (sourceInfos as MapLiteral).entries.length == 2,
      'sourceInfos map has both entries',
    );
    check(
      inv.arguments.positional[1] is NullLiteral,
      'arg1 target is null for the static-read case passed in',
    );
    check(
      inv.arguments.positional[2] is StringLiteral,
      'arg2 function is a String',
    );
    check(inv.arguments.positional[6] is NullLiteral, 'arg6 members is null');
    check(
      inv.arguments.positional[7] is NullLiteral,
      'arg7 annotations is null',
    );
  });

  group('getLineNumBySourceAndOffset (M4.2 binary search)', () {
    final Source source = Source(
      <int>[0, 10, 20, 30],
      Uint8List.fromList(List<int>.filled(40, 120)),
      Uri.parse('package:t/t.dart'),
      Uri.parse('file:///t.dart'),
    );
    check(
      AopUtils.getLineNumBySourceAndOffset(source, 0) == 0,
      'offset 0 -> line 0',
    );
    check(
      AopUtils.getLineNumBySourceAndOffset(source, 5) == 0,
      'offset 5 -> line 0',
    );
    check(
      AopUtils.getLineNumBySourceAndOffset(source, 10) == 1,
      'offset 10 -> line 1',
    );
    check(
      AopUtils.getLineNumBySourceAndOffset(source, 25) == 2,
      'offset 25 -> line 2',
    );
    check(
      AopUtils.getLineNumBySourceAndOffset(source, 35) == 3,
      'offset 35 -> last line',
    );
    check(
      AopUtils.getLineNumBySourceAndOffset(source, 30) == 3,
      'offset 30 -> line 3 boundary',
    );
    check(
      AopUtils.getLineNumBySourceAndOffset(source, -1) == -1,
      'negative offset -> -1',
    );
  });

  group('resolveAnnotationAopMode (#13 multi-annotation detector)', () {
    ConstantExpression anno(String importUri, String clsName) {
      final Library lib = Library(
        Uri.parse(importUri),
        fileUri: Uri.parse('file:///a.dart'),
      );
      final Class cls = Class(name: clsName, fileUri: lib.fileUri);
      lib.addClass(cls);
      return ConstantExpression(
        InstanceConstant(cls.reference, <DartType>[], <Reference, Constant>{}),
      );
    }

    final ConstantExpression call = anno(
      'package:aopd/src/annotations/call.dart',
      'Call',
    );
    final ConstantExpression execute = anno(
      'package:aopd/src/annotations/execute.dart',
      'Execute',
    );
    final ConstantExpression notAop = anno('package:foo/foo.dart', 'Whatever');

    check(
      AopUtils.resolveAnnotationAopMode(call, <String, Library>{}) ==
          AopMode.call,
      'Call annotation resolves to call mode',
    );
    check(
      AopUtils.resolveAnnotationAopMode(execute, <String, Library>{}) ==
          AopMode.execute,
      'Execute annotation resolves to execute mode',
    );
    check(
      AopUtils.resolveAnnotationAopMode(notAop, <String, Library>{}) == null,
      'non-AOPD annotation resolves to null',
    );

    final int aopCount = <Expression>[call, execute, notAop]
        .where(
          (Expression a) =>
              AopUtils.resolveAnnotationAopMode(a, <String, Library>{}) != null,
        )
        .length;
    check(
      aopCount == 2,
      'two AOP annotations counted -> #13 forbid would trigger',
    );
  });

  group('AopItemInfo.tryCreate validates mode-specific fields (#36)', () {
    final List<String> errors = <String>[];
    void onInvalid(String message) => errors.add(message);

    final Library lib = Library(
      Uri.parse('package:t/aspect.dart'),
      fileUri: Uri.parse('file:///aspect.dart'),
    );
    final Class cls = Class(name: 'Aspect', fileUri: lib.fileUri);
    lib.addClass(cls);
    final Procedure advice = Procedure(
      Name('adv'),
      ProcedureKind.Method,
      FunctionNode(EmptyStatement()),
      fileUri: lib.fileUri,
    );
    cls.addProcedure(advice);

    final AopItemInfo? missingMethod = AopItemInfo.tryCreate(
      mode: AopMode.call,
      importUri: 'package:x/x.dart',
      clsName: 'X',
      isStatic: false,
      aopMember: advice,
      onInvalid: onInvalid,
    );
    check(missingMethod == null, 'call item without methodName is rejected');

    final AopItemInfo? missingLine = AopItemInfo.tryCreate(
      mode: AopMode.inject,
      importUri: 'package:x/x.dart',
      clsName: 'X',
      methodName: 'run',
      isStatic: false,
      aopMember: advice,
      onInvalid: onInvalid,
    );
    check(missingLine == null, 'inject item without lineNum is rejected');

    final AopItemInfo? missingField = AopItemInfo.tryCreate(
      mode: AopMode.fieldGet,
      importUri: 'package:x/x.dart',
      clsName: 'X',
      isStatic: true,
      aopMember: advice,
      onInvalid: onInvalid,
    );
    check(missingField == null, 'fieldGet item without fieldName is rejected');

    final AopItemInfo? validAdd = AopItemInfo.tryCreate(
      mode: AopMode.add,
      importUri: 'package:x/x.dart',
      clsName: 'X',
      aopMember: advice,
      onInvalid: onInvalid,
    );
    check(validAdd != null, 'add item does not require method/field/line');

    final AopItemInfo? validInject = AopItemInfo.tryCreate(
      mode: AopMode.inject,
      importUri: 'package:x/x.dart',
      clsName: 'X',
      methodName: 'run',
      isStatic: false,
      lineNum: 3,
      aopMember: advice,
      onInvalid: onInvalid,
    );
    check(
      validInject?.requiredMethodName == 'run',
      'valid inject exposes a non-null requiredMethodName',
    );
    check(
      validInject?.requiredLineNum == 3,
      'valid inject exposes a non-null requiredLineNum',
    );
    check(errors.length == 3, 'three invalid items reported diagnostics');
  });

  group('sortAndReportConflicts (#27 B+C)', () {
    final List<String> msgs = <String>[];
    AopUtils.diagnostics = AopDiagnosticReporter((String m) => msgs.add(m));

    final Library aspectLib = Library(
      Uri.parse('package:t/aspect.dart'),
      fileUri: Uri.parse('file:///aspect.dart'),
    );
    final Class aspectCls = Class(name: 'Aspect', fileUri: aspectLib.fileUri);
    aspectLib.addClass(aspectCls);
    Procedure adv(String n) {
      final Procedure p = Procedure(
        Name(n),
        ProcedureKind.Method,
        FunctionNode(EmptyStatement()),
        fileUri: aspectLib.fileUri,
      );
      aspectCls.addProcedure(p);
      return p;
    }

    final Procedure a1 = adv('a1');
    final Procedure a2 = adv('a2');
    AopItemInfo callItem(Member m) => AopItemInfo(
      mode: AopMode.call,
      importUri: 'package:x/x.dart',
      clsName: 'X',
      methodName: 'foo',
      isStatic: false,
      aopMember: m,
    );

    // Provided out of order; sort must put a1 before a2 (stable aspect key).
    final List<AopItemInfo> items = <AopItemInfo>[callItem(a2), callItem(a1)];
    AopUtils.sortAndReportConflicts(items);
    check(
      items.first.requiredAopMember == a1 && items.last.requiredAopMember == a2,
      'C: deterministic order (a1 before a2)',
    );
    check(
      msgs.any((String m) => m.contains('aspects target the same')),
      'B: exact-target conflict diagnostic emitted',
    );
    check(
      msgs.any((String m) => m.contains('last-wins')),
      'B: @Call conflict reported as last-wins',
    );

    msgs.clear();
    AopUtils.sortAndReportConflicts(<AopItemInfo>[callItem(a1)]);
    check(
      !msgs.any((String m) => m.contains('aspects target the same')),
      'no conflict reported for a single aspect',
    );
  });

  group('decodedSource + calcSourceInfo (#26)', () {
    final Library lib = Library(
      Uri.parse('package:t/t.dart'),
      fileUri: Uri.parse('file:///t.dart'),
    );
    final Source source = Source(
      <int>[0, 10, 20, 30],
      Uint8List.fromList('hi'.codeUnits),
      lib.importUri,
      lib.fileUri,
    );
    final Map<Uri, Source> uriToSource = <Uri, Source>{lib.fileUri: source};

    // decodedSource decodes correctly and caches (same String instance).
    check(AopUtils.decodedSource(source) == 'hi', 'decodes source bytes');
    check(
      identical(AopUtils.decodedSource(source), AopUtils.decodedSource(source)),
      'decodedSource caches per Source (same instance returned)',
    );

    // calcSourceInfo via binary search.
    final Map<String, String> at25 = AopUtils.calcSourceInfo(
      uriToSource,
      lib,
      25,
    );
    check(at25['lineNum'] == '3', 'offset 25 -> line 3 (1-based)');
    check(at25['lineOffset'] == '5', 'offset 25 -> column 5');

    final Map<String, String> at0 = AopUtils.calcSourceInfo(
      uriToSource,
      lib,
      0,
    );
    check(
      at0['lineNum'] == '1' && at0['lineOffset'] == '0',
      'offset 0 -> line 1, col 0',
    );

    // Robustness: a synthetic offset before the first line must not throw
    // (previously `late lineOffSet` was left unassigned).
    final Map<String, String> atNeg = AopUtils.calcSourceInfo(
      uriToSource,
      lib,
      -1,
    );
    check(
      atNeg['lineNum'] == '0' && atNeg['lineOffset'] == '0',
      'offset before first line -> 0/0, no crash',
    );
  });

  group('adviceFormMatches (#3 advice static/instance guard)', () {
    final List<String> msgs = <String>[];
    AopUtils.diagnostics = AopDiagnosticReporter((String m) => msgs.add(m));
    final Library lib = Library(
      Uri.parse('package:t/aspect.dart'),
      fileUri: Uri.parse('file:///aspect.dart'),
    );
    final Class cls = Class(name: 'Aspect', fileUri: lib.fileUri);
    lib.addClass(cls);
    Procedure adv(String n, {required bool isStatic}) {
      final Procedure p = Procedure(
        Name(n),
        ProcedureKind.Method,
        FunctionNode(EmptyStatement()),
        isStatic: isStatic,
        fileUri: lib.fileUri,
      );
      cls.addProcedure(p);
      return p;
    }

    final Procedure staticAdv = adv('s', isStatic: true);
    final Procedure instanceAdv = adv('i', isStatic: false);
    AopItemInfo item(Member m) => AopItemInfo(
      mode: AopMode.call,
      importUri: 'package:x/x.dart',
      clsName: 'X',
      methodName: 'foo',
      aopMember: m,
    );

    check(
      AopUtils.adviceFormMatches(item(staticAdv), expectStatic: true),
      'static advice satisfies expectStatic:true',
    );
    check(
      AopUtils.adviceFormMatches(item(instanceAdv), expectStatic: false),
      'instance advice satisfies expectStatic:false',
    );
    check(
      !AopUtils.adviceFormMatches(item(instanceAdv), expectStatic: true),
      'instance advice fails expectStatic:true (would be invalid kernel)',
    );
    check(
      !AopUtils.adviceFormMatches(item(staticAdv), expectStatic: false),
      'static advice fails expectStatic:false',
    );
    check(
      msgs.any((String m) => m.contains('must be')),
      'a mismatch emits a diagnostic',
    );
  });

  group('adviceClassConstructable (#3 instance-advice ctor guard)', () {
    final List<String> msgs = <String>[];
    AopUtils.diagnostics = AopDiagnosticReporter((String m) => msgs.add(m));

    Procedure adviceIn(Class cls) {
      final Procedure p = Procedure(
        Name('adv'),
        ProcedureKind.Method,
        FunctionNode(EmptyStatement()),
        fileUri: cls.fileUri,
      );
      cls.addProcedure(p);
      return p;
    }

    final Library okLib = Library(
      Uri.parse('package:t/ok.dart'),
      fileUri: Uri.parse('file:///ok.dart'),
    );
    final Class okCls = Class(name: 'OkAspect', fileUri: okLib.fileUri);
    okLib.addClass(okCls);
    okCls.addConstructor(
      Constructor(
        FunctionNode(EmptyStatement()),
        name: Name(''),
        fileUri: okLib.fileUri,
      ),
    );
    final Procedure okAdvice = adviceIn(okCls);

    final Library badLib = Library(
      Uri.parse('package:t/bad.dart'),
      fileUri: Uri.parse('file:///bad.dart'),
    );
    final Class badCls = Class(name: 'BadAspect', fileUri: badLib.fileUri);
    badLib.addClass(badCls);
    badCls.addConstructor(
      Constructor(
        FunctionNode(
          EmptyStatement(),
          positionalParameters: <VariableDeclaration>[VariableDeclaration('x')],
          requiredParameterCount: 1,
        ),
        name: Name(''),
        fileUri: badLib.fileUri,
      ),
    );
    final Procedure badAdvice = adviceIn(badCls);

    AopItemInfo item(Member m) => AopItemInfo(
      mode: AopMode.call,
      importUri: 'package:x/x.dart',
      clsName: 'X',
      methodName: 'foo',
      aopMember: m,
    );

    check(
      AopUtils.adviceClassConstructable(item(okAdvice)),
      'aspect with a no-arg constructor is constructable',
    );
    check(
      !AopUtils.adviceClassConstructable(item(badAdvice)),
      'aspect whose first constructor requires args is not constructable',
    );
    check(
      msgs.any((String m) => m.contains('no-argument constructor')),
      'a non-constructable aspect emits a diagnostic',
    );
  });

  finish();
}
