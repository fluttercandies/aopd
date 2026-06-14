// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Crash-safety #33: when the dart:core SDK helpers (`==` / List/Map `[]`) cannot
// be resolved -- e.g. an unusual --no-link-platform compile with no CoreTypes
// fallback -- the transform must SKIP all weaving with a loud diagnostic, never
// dereference a null helper and crash the build. The guard runs before any
// per-mode weaving, so any aspects present are left untouched.

import 'package:kernel/ast.dart';

import '../transformer/aop_transformer.dart';
import '_harness.dart';

void main() {
  // A component that has the PointCut runtime (so resolution gets past the
  // "PointCut not found" branch) but NO dart:core at all -> coreLib/listGet/
  // mapGet stay null, and no CoreTypes is passed.
  final Uri pcFile = Uri.parse('file:///pointcut.dart');
  final Library pcLib = Library(
      Uri.parse('package:aopd/src/annotations/pointcut.dart'),
      fileUri: pcFile);
  final Class pointCutClass = Class(name: 'PointCut', fileUri: pcFile);
  pcLib.addClass(pointCutClass);
  pointCutClass.addProcedure(Procedure(
      Name('proceed'),
      ProcedureKind.Method,
      FunctionNode(Block(<Statement>[ReturnStatement(NullLiteral())])),
      fileUri: pcFile));

  final Component component = Component(libraries: <Library>[pcLib]);

  final List<String> logs = <String>[];
  bool threw = false;
  try {
    AopWrapperTransformer().transformAspects(
      component,
      logger: (String msg) => logs.add(msg),
    );
  } on Object {
    threw = true;
  }

  group('missing SDK helpers degrade loudly, no crash (#33)', () {
    check(!threw,
        'transformAspects does NOT throw when dart:core helpers are absent');
    check(logs.any((String m) => m.contains('SDK helpers not found')),
        'emits the loud [AOPD] "SDK helpers not found" diagnostic');
    // The guard returns before any per-mode weaving runs.
  });

  finish();
}
