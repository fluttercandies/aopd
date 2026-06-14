// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Unit test for AopDiagnosticReporter (plan M0.2). Pure unit, no kernel needed.

import '../transformer/aop_diagnostic_reporter.dart';
import '../transformer/rewriters/aop_item_info.dart';
import '../transformer/rewriters/aop_mode.dart';
import '_harness.dart';

void main() {
  final List<String> logged = <String>[];
  final AopDiagnosticReporter reporter =
      AopDiagnosticReporter(logged.add);

  final AopItemInfo item = AopItemInfo(
    mode: AopMode.execute,
    importUri: 'package:example/demos/basic/basic_targets.dart',
    clsName: 'BasicTarget',
    methodName: 'runExecuteDemo',
    lineNum: 12, // internal 0-based; reported as the 1-based source line 13
  );

  group('AopDiagnosticReporter formatting', () {
    reporter.warning(item, 'skipped because regex is invalid');
    final String last = logged.last;
    expectContains(last, '[AOPD]', 'warning has AOPD prefix');
    expectContains(last, 'WARNING', 'warning has level');
    expectContains(last, 'mode=execute', 'warning has mode');
    expectContains(last, 'cls=BasicTarget', 'warning has class');
    expectContains(last, 'method=runExecuteDemo', 'warning has method');
    expectContains(last, 'line=13', 'warning reports 1-based source line (0-based 12 -> 13)');
    expectContains(last, 'skipped because regex is invalid', 'warning has message');
  });

  group('levels and counters', () {
    reporter.error(item, 'weave abandoned');
    expectContains(logged.last, 'ERROR', 'error has level');
    reporter.unsupported(item, 'generic methods not supported');
    expectContains(logged.last, 'UNSUPPORTED', 'unsupported has level');
    check(reporter.errorCount == 1, 'errorCount == 1');
    check(reporter.warningCount == 2, 'warningCount == 2 (warning + unsupported)');
  });

  group('null item is tolerated', () {
    reporter.warning(null, 'orchestration-level note');
    expectContains(logged.last, 'orchestration-level note', 'null item still logs message');
    expectNotContains(logged.last, 'mode=', 'null item has no mode token');
  });

  finish();
}
