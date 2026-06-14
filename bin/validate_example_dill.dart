// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// End-to-end smoke check for AOPD weaving (plan M0.3 / B-loop step 3).
//
// Verifies that the example app's compiled kernel actually contains the
// expected AOP weave markers. Run after building the example, e.g.:
//
//   dart bin/dump.dart                          # produce example/out.dill.txt
//   dart bin/validate_example_dill.dart        # assert markers
//
// Or let this tool dump the latest app.dill itself (default), or validate an
// already-dumped text file with --text <path>.
//
// Exit codes: 0 = all required markers present; non-zero = missing markers or
// setup failure (with a clear list of what's missing).

import 'dart:io';

// Markers that MUST be present whenever the example is built with AOPD on.
const List<String> _requiredMarkers = <String>[
  'PointCut',
  'proceed',
  // M5.4 decentralized weaving: every woven call/execute/fieldGet PointCut
  // carries a proceedClosure. This is the primary signal of current-arch
  // weaving.
  'proceedClosure',
  // Legacy/auxiliary signal: execute still names its moved-out body
  // `<method>_aop_stub_N`, and PointCut.stubKey strings are "aop_stub_N". (The
  // central proceed() stub dispatch this once referred to was removed in M5.4.)
  'aop_stub_',
  'AutoAnalyticsAspect',
  'PerformanceAspect',
  'BasicAnnotationsAspect',
];

// Markers that depend on `aopd.track_widget_creation: true`. Missing them is a
// warning, not a failure, because the example may be built without it.
const List<String> _widgetTrackingMarkers = <String>[
  r'$creationLocationAopd_',
  'aopLocation',
  'AopHasCreationLocation',
];

const String _targetDemoDir = 'example';

Future<void> main(List<String> args) async {
  final Directory? repoRoot = _resolveRepoRoot(File.fromUri(Platform.script).parent);
  if (repoRoot == null) {
    stderr.writeln('[validate] Cannot resolve repository root.');
    exitCode = 1;
    return;
  }

  final String sep = Platform.pathSeparator;
  String? textPath = _optionValue(args, '--text');

  if (textPath == null) {
    // Dump the latest example app.dill to a temp text file first.
    final String? dill = _findLatestAppDill(repoRoot.path);
    if (dill == null) {
      stderr.writeln('[validate] No example app.dill found. Build the example first:');
      stderr.writeln('  cd $_targetDemoDir && flutter build apk --debug');
      exitCode = 2;
      return;
    }
    textPath = '${repoRoot.path}${sep}example${sep}out.dill.txt';
    final int dumpExit = await _dump(repoRoot.path, dill, textPath);
    if (dumpExit != 0) {
      stderr.writeln('[validate] dump_kernel failed (exit $dumpExit).');
      exitCode = dumpExit;
      return;
    }
  }

  final File textFile = File(textPath);
  if (!textFile.existsSync()) {
    stderr.writeln('[validate] Dump text not found: $textPath');
    exitCode = 3;
    return;
  }

  final String content = textFile.readAsStringSync();

  final List<String> missingRequired = <String>[
    for (final String m in _requiredMarkers)
      if (!content.contains(m)) m,
  ];
  final List<String> missingWidget = <String>[
    for (final String m in _widgetTrackingMarkers)
      if (!content.contains(m)) m,
  ];

  stdout.writeln('[validate] Checked: $textPath');
  for (final String m in _requiredMarkers) {
    stdout.writeln('  ${missingRequired.contains(m) ? 'MISSING ' : 'ok      '} $m');
  }
  if (missingWidget.isEmpty) {
    stdout.writeln('  ok       widget tracking markers present');
  } else {
    stdout.writeln('  (warn)   widget tracking markers absent '
        '(expected unless aopd.track_widget_creation is on): '
        '${missingWidget.join(', ')}');
  }

  if (missingRequired.isNotEmpty) {
    stderr.writeln('[validate] FAIL: missing required AOP markers: '
        '${missingRequired.join(', ')}');
    exitCode = 4;
    return;
  }
  stdout.writeln('[validate] OK: all required AOP weave markers present.');
}

Future<int> _dump(String repoRoot, String dillPath, String outPath) async {
  final String sep = Platform.pathSeparator;
  final String dumpKernel =
      '$repoRoot${sep}compiler${sep}pkg${sep}vm${sep}bin${sep}dump_kernel.dart';
  if (!File(dumpKernel).existsSync()) {
    stderr.writeln('[validate] dump_kernel.dart not found: $dumpKernel');
    return 5;
  }
  stdout.writeln('[validate] Dumping $dillPath -> $outPath');
  final Process process = await Process.start(
    Platform.resolvedExecutable,
    <String>[dumpKernel, dillPath, outPath],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: repoRoot,
  );
  return process.exitCode;
}

String? _optionValue(List<String> args, String name) {
  for (int i = 0; i < args.length; i++) {
    if (args[i] == name && i + 1 < args.length) {
      return args[i + 1];
    }
    if (args[i].startsWith('$name=')) {
      return args[i].substring(name.length + 1);
    }
  }
  return null;
}

String? _findLatestAppDill(String repoRoot) {
  final String sep = Platform.pathSeparator;
  final Directory buildDir = Directory(
    '$repoRoot$sep$_targetDemoDir$sep.dart_tool${sep}flutter_build',
  );
  if (!buildDir.existsSync()) {
    return null;
  }
  final List<File> appDills = <File>[];
  for (final FileSystemEntity entity
      in buildDir.listSync(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('${sep}app.dill')) {
      appDills.add(entity);
    }
  }
  if (appDills.isEmpty) {
    return null;
  }
  appDills.sort((File a, File b) =>
      b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return appDills.first.path;
}

Directory? _resolveRepoRoot(Directory scriptDir) {
  Directory current = scriptDir;
  for (int i = 0; i < 6; i++) {
    final File pubspec = File('${current.path}${Platform.pathSeparator}pubspec.yaml');
    final Directory compiler =
        Directory('${current.path}${Platform.pathSeparator}compiler');
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
