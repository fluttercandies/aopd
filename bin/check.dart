// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// One-command verification entry point for AOPD (repo-only; see .pubignore).
// Runs the verification matrix and aggregates pass/fail.
//
//   dart bin/check.dart           # analyze + unit tests + root flutter tests
//                                  #   + (marker/kernel checks IF a build exists)
//   dart bin/check.dart --full    # + clean full example flutter test
//
// Marker/kernel checks (validate_example_dill, verify_dill) run opportunistically
// on an existing example build (do `flutter build apk --debug` first to produce
// one). The --full step is self-contained (clean AOPD-pipeline build + full
// example tests) and is the strongest single check. Exit code is non-zero if
// any step fails.

import 'dart:io';

class _Step {
  _Step(this.label, this.exe, this.args, {this.cwd, this.runInShell = false});

  final String label;
  final String exe;
  final List<String> args;
  final String? cwd;
  final bool runInShell;
}

Future<void> main(List<String> args) async {
  final bool full = args.contains('--full');
  final Directory? repoRoot = _resolveRepoRoot(
    File.fromUri(Platform.script).parent,
  );
  if (repoRoot == null) {
    stderr.writeln('[check] cannot resolve repository root.');
    exitCode = 2;
    return;
  }
  final String root = repoRoot.path;
  final String sep = Platform.pathSeparator;
  final String dart = Platform.resolvedExecutable;
  final String pkgCfg =
      '--packages=compiler$sep.dart_tool${sep}package_config.json';
  final String exampleDir = '$root${sep}example';
  final bool appDillExists = _latestAppDill(root) != null;

  final List<_Step> steps = <_Step>[
    _Step('analyze (compiler/transformer + compiler/test)', dart, <String>[
      'analyze',
      'compiler/transformer',
      'compiler/test',
    ]),
    _Step('analyze (lib)', dart, <String>['analyze', 'lib']),
    _Step('unit tests (compiler/test)', dart, <String>[
      pkgCfg,
      'compiler/test/run_all.dart',
    ]),
    _Step('root tests (flutter test)', 'flutter', <String>[
      'test',
    ], runInShell: true),
  ];

  if (appDillExists) {
    // Opportunistic structural + kernel checks on an existing flutter build.
    // Run BEFORE any clean so --full doesn't wipe the artifact first. NOTE:
    // these run on whatever build exists (may be stale); for a current-code
    // structural check, do a fresh `flutter build apk --debug` first.
    steps.add(
      _Step('validate weave markers', dart, <String>[
        'bin/validate_example_dill.dart',
      ]),
    );
    steps.add(
      _Step('kernel verify (verify_dill)', dart, <String>[
        pkgCfg,
        'compiler/tool/verify_dill.dart',
      ]),
    );
  } else {
    stdout.writeln(
      '[check] no example app.dill; skipping marker/kernel checks. '
      '(Run `flutter build apk --debug` in example/ to enable them.)',
    );
  }

  if (full) {
    // Authoritative end-to-end check: a clean AOPD-pipeline build + the full
    // example suite. Self-contained (does not need a pre-existing build).
    steps.add(
      _Step(
        'flutter clean',
        'flutter',
        <String>['clean'],
        cwd: exampleDir,
        runInShell: true,
      ),
    );
    steps.add(
      _Step(
        'example tests (flutter test)',
        'flutter',
        <String>['test'],
        cwd: exampleDir,
        runInShell: true,
      ),
    );
  }

  final List<String> failed = <String>[];
  for (final _Step step in steps) {
    stdout.writeln('\n=== ${step.label} ===');
    final Process process = await Process.start(
      step.exe,
      step.args,
      workingDirectory: step.cwd ?? root,
      mode: ProcessStartMode.inheritStdio,
      runInShell: step.runInShell,
    );
    final int code = await process.exitCode;
    if (code != 0) {
      failed.add(step.label);
      stdout.writeln('--- FAIL: ${step.label} (exit $code) ---');
    }
  }

  stdout.writeln(
    '\n================ check summary (${full ? 'full' : 'fast'}) '
    '================',
  );
  if (failed.isEmpty) {
    stdout.writeln('ALL PASS (${steps.length} steps)');
  } else {
    stdout.writeln(
      'FAILED (${failed.length}/${steps.length}): '
      '${failed.join(', ')}',
    );
    exitCode = 1;
  }
}

String? _latestAppDill(String root) {
  final String sep = Platform.pathSeparator;
  final Directory buildDir = Directory(
    '$root${sep}example$sep.dart_tool${sep}flutter_build',
  );
  if (!buildDir.existsSync()) {
    return null;
  }
  final List<File> dills = <File>[
    for (final FileSystemEntity entity in buildDir.listSync(
      recursive: true,
      followLinks: false,
    ))
      if (entity is File && entity.path.endsWith('${sep}app.dill')) entity,
  ];
  if (dills.isEmpty) {
    return null;
  }
  // Pick the NEWEST, matching dump/validate/verify which all use the latest
  // build -- otherwise the marker/kernel checks could gate on a stale app.dill
  // that those tools never look at.
  dills.sort(
    (File a, File b) => b.statSync().modified.compareTo(a.statSync().modified),
  );
  return dills.first.path;
}

Directory? _resolveRepoRoot(Directory scriptDir) {
  Directory current = scriptDir;
  for (int i = 0; i < 6; i++) {
    final File pubspec = File(
      '${current.path}${Platform.pathSeparator}pubspec.yaml',
    );
    final Directory compiler = Directory(
      '${current.path}${Platform.pathSeparator}compiler',
    );
    if (pubspec.existsSync() && compiler.existsSync()) {
      return current;
    }
    final Directory parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return null;
}
