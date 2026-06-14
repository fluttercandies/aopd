// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Incremental / hot-reload harness (M5, opportunistic).
//
// Drives the AOPD frontend_server through the resident protocol
// (compile -> accept -> edit a file -> recompile) and inspects each produced
// dill. This exercises the AOP transform under recompileDelta -- the path the
// full-build tests never hit -- and empirically demonstrates the M5.4
// decentralization story:
//
//   * editing the ASPECT file and recompiling does NOT crash/abort and yields
//     a valid delta (mode 2 is structurally safe: no central proceed table);
//   * editing a BUSINESS file and recompiling is crash-safe; whether the
//     recompiled library is re-woven depends on whether the PointCut runtime is
//     in the delta (mode 1 "degrade but loud") -- the harness REPORTS which.
//
// Requires a prior full build so a flutter_build hash dir + depfile exist:
//   cd example && flutter build bundle --debug
// Run:
//   dart --packages=compiler/.dart_tool/package_config.json \
//        compiler/tool/incremental_harness.dart
//
// Exit code is non-zero if any recompile errors out or a dill fails to load.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';

int _failures = 0;
void _check(bool ok, String desc) {
  if (ok) {
    stdout.writeln('  ok    $desc');
  } else {
    _failures++;
    stdout.writeln('  FAIL  $desc');
  }
}

void _info(String msg) => stdout.writeln('  ..    $msg');

Future<void> main() async {
  final String sep = Platform.pathSeparator;
  final Directory repoRoot = _resolveRepoRoot(File.fromUri(Platform.script).parent);
  final Directory exampleDir = Directory('${repoRoot.path}${sep}example');
  final String? flutterRoot = _findFlutterRoot(exampleDir, sep);
  final Directory? buildHashDir = _findLatestBuildHashDir(exampleDir, sep);
  if (flutterRoot == null || buildHashDir == null) {
    stderr.writeln('[harness] No flutter_build dir / Flutter root. Build first:\n'
        '          cd example && flutter build bundle --debug');
    exitCode = 4;
    return;
  }

  final String depfile = _findDepfile(buildHashDir) ??
      '${buildHashDir.path}${sep}kernel_snapshot_program.d';
  final String sdkRoot = '$flutterRoot${sep}bin${sep}cache${sep}artifacts'
      '${sep}engine${sep}common${sep}flutter_patched_sdk$sep';
  final String packageConfig =
      '${exampleDir.path}$sep.dart_tool${sep}package_config.json';
  final String outputDill = '${buildHashDir.path}${sep}harness.dill';
  final Map<String, String> fv = await _readFlutterVersionInfo(flutterRoot, sep);

  final List<String> args = <String>[
    '--sdk-root', sdkRoot,
    '--target=flutter',
    '--no-print-incremental-dependencies',
    '-DFLUTTER_VERSION=${fv['frameworkVersion'] ?? ''}',
    '-DFLUTTER_CHANNEL=${fv['channel'] ?? ''}',
    '-DFLUTTER_GIT_URL=${fv['repositoryUrl'] ?? ''}',
    '-DFLUTTER_FRAMEWORK_REVISION=${fv['frameworkRevision'] ?? ''}',
    '-DFLUTTER_ENGINE_REVISION=${fv['engineRevision'] ?? ''}',
    '-DFLUTTER_DART_VERSION=${(fv['dartSdkVersion'] ?? '').split(' ').first}',
    '-Ddart.vm.profile=false',
    '-Ddart.vm.product=false',
    '--enable-asserts',
    '--track-widget-creation',
    '--no-link-platform',
    '--packages', packageConfig,
    '--output-dill', outputDill,
    '--depfile', depfile,
    '--incremental',
    '--aop', '1',
    '--verbosity=error',
  ];

  final String starter =
      '${repoRoot.path}${sep}compiler${sep}frontend_server${sep}starter.dart';
  final String pkgCfg =
      '${repoRoot.path}${sep}compiler$sep.dart_tool${sep}package_config.json';

  stdout.writeln('[harness] launching frontend_server...');
  final Process proc = await Process.start(
    Platform.resolvedExecutable,
    <String>['--packages=$pkgCfg', starter, ...args],
  );
  proc.stderr.transform(utf8.decoder).listen((String s) {
    if (s.trim().isNotEmpty) stderr.write('  [fs] $s');
  });
  final StreamIterator<String> lines = StreamIterator<String>(
      proc.stdout.transform(utf8.decoder).transform(const LineSplitter()));

  Future<({String dill, int errors})> readResult() async {
    String? key;
    while (await lines.moveNext()) {
      final String line = lines.current;
      if (key == null) {
        if (line.startsWith('result ')) key = line.substring(7).trim();
      } else if (line.startsWith('$key ')) {
        final String rest = line.substring(key.length + 1).trim();
        final int sp = rest.lastIndexOf(' ');
        return (
          dill: rest.substring(0, sp),
          errors: int.tryParse(rest.substring(sp + 1)) ?? -1
        );
      }
    }
    throw StateError('frontend_server stream ended before a result');
  }

  const String entry = 'package:example/main.dart';
  final File aspectFile = File('${exampleDir.path}${sep}lib${sep}aop'
      '${sep}aspects${sep}basic_annotations_aspect.dart');
  final File targetFile = File('${exampleDir.path}${sep}lib${sep}demos'
      '${sep}basic${sep}basic_targets.dart');
  final String aspectOriginal = aspectFile.readAsStringSync();
  final String targetOriginal = targetFile.readAsStringSync();

  try {
    // --- 1) Full compile ---
    stdout.writeln('\n== full compile ==');
    proc.stdin.writeln('compile $entry');
    final ({String dill, int errors}) full = await readResult();
    proc.stdin.writeln('accept');
    _check(full.errors == 0, 'full compile reports 0 errors');
    final Component fullComp = _load(full.dill);
    final bool fullWoven = _isWoven(fullComp, 'basic_targets.dart');
    _check(fullWoven, 'full build wove basic_targets (execute stub present)');
    _check(!_hasCentralDispatch(fullComp),
        'PointCut.proceed has NO central stubKey dispatch (decentralized)');

    // --- 2) Edit the ASPECT file and recompile (mode 2 territory) ---
    stdout.writeln('\n== recompile after editing the ASPECT ==');
    aspectFile.writeAsStringSync(
        '$aspectOriginal\n// aopd-incremental-harness touch\n');
    final ({String dill, int errors}) d1 =
        await _recompile(proc, readResult, entry, <File>[aspectFile]);
    _check(d1.errors == 0,
        'recompile after aspect edit reports 0 errors (no crash/abort)');
    final Component delta1 = _load(d1.dill);
    _info('aspect-edit delta libraries: ${delta1.libraries.length}');
    _check(!_hasCentralDispatch(delta1),
        'aspect-edit delta has no central stubKey dispatch');
    proc.stdin.writeln('accept');

    // --- 3) Edit a BUSINESS file and recompile (mode 1 territory) ---
    stdout.writeln('\n== recompile after editing a BUSINESS target ==');
    targetFile.writeAsStringSync(
        '$targetOriginal\n// aopd-incremental-harness touch\n');
    final ({String dill, int errors}) d2 =
        await _recompile(proc, readResult, entry, <File>[targetFile]);
    _check(d2.errors == 0,
        'recompile after business edit reports 0 errors (crash-safe)');
    final Component delta2 = _load(d2.dill);
    final bool hasPointCut = delta2.libraries
        .any((Library l) => l.importUri.toString().contains('pointcut.dart'));
    final bool deltaWoven = _isWoven(delta2, 'basic_targets.dart');
    _info('business-edit delta: ${delta2.libraries.length} libs, '
        'PointCut runtime in delta=$hasPointCut, basic_targets re-woven=$deltaWoven');
    _info(deltaWoven
        ? 'mode-1: target was re-woven in the delta.'
        : 'mode-1 (degrade but loud): target left un-woven in delta -- needs a '
            'full rebuild to re-weave. Crash-safe.');
    proc.stdin.writeln('accept');

    proc.stdin.writeln('quit');
    await proc.exitCode.timeout(const Duration(seconds: 20), onTimeout: () {
      proc.kill();
      return -1;
    });
  } finally {
    // Always restore the source files.
    aspectFile.writeAsStringSync(aspectOriginal);
    targetFile.writeAsStringSync(targetOriginal);
    try {
      File(outputDill).deleteSync();
    } catch (_) {}
  }

  stdout.writeln('\n---');
  if (_failures > 0) {
    stdout.writeln('HARNESS FAILED: $_failures check(s) failed');
    exitCode = 1;
  } else {
    stdout.writeln('HARNESS PASSED: incremental recompiles are crash-safe and '
        'decentralized.');
  }
}

Future<({String dill, int errors})> _recompile(
    Process proc,
    Future<({String dill, int errors})> Function() readResult,
    String entry,
    List<File> invalidated) async {
  const String key = 'aopd-harness-boundary';
  proc.stdin.writeln('recompile $entry $key');
  for (final File f in invalidated) {
    proc.stdin.writeln(f.uri.toString());
  }
  proc.stdin.writeln(key);
  return readResult();
}

Component _load(String dillPath) {
  final Component component = Component();
  BinaryBuilder(File(dillPath).readAsBytesSync(), disableLazyReading: true)
      .readComponent(component);
  return component;
}

/// True if a library whose importUri ends with [libSuffix] contains a moved
/// execute stub (named `*_aop_stub_*`), i.e. it was woven.
bool _isWoven(Component component, String libSuffix) {
  for (final Library lib in component.libraries) {
    if (!lib.importUri.toString().endsWith(libSuffix)) continue;
    for (final Class c in lib.classes) {
      for (final Procedure p in c.procedures) {
        if (p.name.text.contains('_aop_stub_')) return true;
      }
    }
  }
  return false;
}

/// True if PointCut.proceed contains a legacy central `stubKey == "..."`
/// dispatch branch (an IfStatement whose condition compares against a string).
bool _hasCentralDispatch(Component component) {
  for (final Library lib in component.libraries) {
    if (!lib.importUri.toString().contains('pointcut.dart')) continue;
    for (final Class c in lib.classes) {
      if (c.name != 'PointCut') continue;
      for (final Procedure p in c.procedures) {
        if (p.name.text != 'proceed') continue;
        final Statement? body = p.function.body;
        if (body is! Block) continue;
        for (final Statement s in body.statements) {
          if (s is IfStatement && s.condition is EqualsCall) {
            final EqualsCall eq = s.condition as EqualsCall;
            if (eq.left is StringLiteral || eq.right is StringLiteral) {
              return true;
            }
          }
        }
      }
    }
  }
  return false;
}

Directory _resolveRepoRoot(Directory scriptDir) {
  Directory current = scriptDir;
  for (int i = 0; i < 6; i++) {
    final File pubspec =
        File('${current.path}${Platform.pathSeparator}pubspec.yaml');
    final Directory fs = Directory('${current.path}${Platform.pathSeparator}'
        'compiler${Platform.pathSeparator}frontend_server');
    if (pubspec.existsSync() && fs.existsSync()) return current;
    final Directory parent = current.parent;
    if (parent.path == current.path) break;
    current = parent;
  }
  return scriptDir;
}

String? _findFlutterRoot(Directory exampleDir, String sep) {
  final File pc =
      File('${exampleDir.path}$sep.dart_tool${sep}package_config.json');
  if (!pc.existsSync()) return null;
  try {
    final Map<String, dynamic> json =
        jsonDecode(pc.readAsStringSync()) as Map<String, dynamic>;
    for (final dynamic pkg in json['packages'] as List<dynamic>) {
      final Map<String, dynamic> m = pkg as Map<String, dynamic>;
      if (m['name'] == 'flutter') {
        return Directory.fromUri(Uri.parse(m['rootUri'] as String))
            .parent
            .parent
            .path;
      }
    }
  } catch (_) {}
  return null;
}

Directory? _findLatestBuildHashDir(Directory exampleDir, String sep) {
  final Directory d =
      Directory('${exampleDir.path}$sep.dart_tool${sep}flutter_build');
  if (!d.existsSync()) return null;
  final List<Directory> dirs =
      d.listSync(followLinks: false).whereType<Directory>().toList();
  if (dirs.isEmpty) return null;
  dirs.sort((Directory a, Directory b) =>
      b.statSync().modified.compareTo(a.statSync().modified));
  return dirs.first;
}

String? _findDepfile(Directory hashDir) {
  for (final FileSystemEntity e in hashDir.listSync(followLinks: false)) {
    if (e is File && e.path.endsWith('.d')) return e.path;
  }
  return null;
}

Future<Map<String, String>> _readFlutterVersionInfo(
    String flutterRoot, String sep) async {
  final String tool = Platform.isWindows
      ? '$flutterRoot${sep}bin${sep}flutter.bat'
      : '$flutterRoot${sep}bin${sep}flutter';
  if (!File(tool).existsSync()) return <String, String>{};
  try {
    final ProcessResult r =
        await Process.run(tool, <String>['--version', '--machine']);
    if (r.exitCode != 0) return <String, String>{};
    final Object? d = jsonDecode((r.stdout as String).trim());
    if (d is! Map<String, dynamic>) return <String, String>{};
    String s(String k) => d[k] is String ? d[k] as String : '';
    return <String, String>{
      'frameworkVersion': s('frameworkVersion'),
      'channel': s('channel'),
      'repositoryUrl': s('repositoryUrl'),
      'frameworkRevision': s('frameworkRevision'),
      'engineRevision': s('engineRevision'),
      'dartSdkVersion': s('dartSdkVersion'),
    };
  } catch (_) {
    return <String, String>{};
  }
}
