// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Runs every *_test.dart in compiler/test/ and aggregates results.
//
//   dart --packages=compiler/.dart_tool/package_config.json \
//        compiler/test/run_all.dart

import 'dart:io';

Future<void> main() async {
  final Directory testDir = File.fromUri(Platform.script).parent;
  final List<File> tests = testDir
      .listSync()
      .whereType<File>()
      .where((File f) => f.path.endsWith('_test.dart'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  if (tests.isEmpty) {
    stdout.writeln('No *_test.dart files found in ${testDir.path}');
    return;
  }

  final String packageConfig =
      '${testDir.parent.path}${Platform.pathSeparator}.dart_tool'
      '${Platform.pathSeparator}package_config.json';

  int failed = 0;
  for (final File test in tests) {
    stdout.writeln('\n### ${test.uri.pathSegments.last}');
    final Process process = await Process.start(
      Platform.resolvedExecutable,
      <String>['--packages=$packageConfig', test.path],
      mode: ProcessStartMode.inheritStdio,
    );
    if (await process.exitCode != 0) {
      failed++;
    }
  }

  stdout.writeln('\n===============================');
  if (failed > 0) {
    stdout.writeln('SUITE FAILED: $failed/${tests.length} test file(s) failed');
    exitCode = 1;
  } else {
    stdout.writeln('SUITE PASSED: ${tests.length} test file(s)');
  }
}
