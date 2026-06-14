// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Repository-only tool (lives under compiler/ because it imports
// package:kernel / package:vm, which only resolve via the compiler workspace
// package config). Runs the kernel verifier over a compiled .dill to check
// that AOPD weaving produced well-formed kernel.
//
//   dart --packages=compiler/.dart_tool/package_config.json \
//        compiler/tool/verify_dill.dart [path/to/app.dill]
//
// With no argument it verifies the latest example/.../app.dill.

import 'dart:convert';
import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/verifier.dart';
import 'package:vm/modular/target/flutter.dart' show FlutterTarget;

const String _targetDemoDir = 'example';

Future<void> main(List<String> args) async {
  final Directory? repoRoot = _resolveRepoRoot(File.fromUri(Platform.script).parent);
  if (repoRoot == null) {
    stderr.writeln('[verify] Cannot resolve repository root.');
    exitCode = 2;
    return;
  }

  final String? dillPath =
      args.isNotEmpty ? args.first : _findLatestAppDill(repoRoot.path);
  if (dillPath == null) {
    stderr.writeln('[verify] No .dill given and no example app.dill found.');
    exitCode = 2;
    return;
  }
  if (!File(dillPath).existsSync()) {
    stderr.writeln('[verify] File not found: $dillPath');
    exitCode = 2;
    return;
  }

  // app.dill is built with --no-link-platform, so it references the platform
  // (dart:core etc.) externally. Load the platform dill first so those
  // references bind; otherwise verification fails on unbound platform refs
  // (a setup artifact, not an AOPD problem).
  final Component component = Component();
  final String? platformDill = _findPlatformDill(repoRoot.path);
  if (platformDill != null && File(platformDill).existsSync()) {
    stdout.writeln('[verify] Linking platform: $platformDill');
    loadComponentFromBinary(platformDill, component);
  } else {
    stdout.writeln('[verify] WARNING: platform dill not found; unbound '
        'platform references will be reported (not AOPD issues).');
  }

  stdout.writeln('[verify] Loading $dillPath');
  loadComponentFromBinary(dillPath, component);
  final Target target = FlutterTarget(TargetFlags());

  final int appLibs = component.libraries
      .where((Library l) => !l.importUri.isScheme('dart'))
      .length;
  stdout.writeln('[verify] ${component.libraries.length} libraries '
      '($appLibs non-dart). Verifying afterModularTransformations '
      '(skipPlatform: true)...');

  try {
    verifyComponent(
      target,
      VerificationStage.afterModularTransformations,
      component,
      skipPlatform: true,
      // Skip package:flutter/ libraries: Flutter's own stock widget tracker
      // (--track-widget-creation) adds a `_location` field without a
      // fileOffset, which this (stricter-than-production) verifier rejects.
      // That noise is not AOPD's; skipping it isolates AOPD's own output
      // (app + package:aopd libs, including the proceed stubs).
      librarySkipFilter: (Library library) =>
          library.importUri.toString().startsWith('package:flutter/'),
    );
    stdout.writeln('[verify] OK: kernel verification passed '
        '(app + package:aopd libraries; package:flutter skipped).');
  } on VerificationError catch (error) {
    stderr.writeln('[verify] FAIL: $error');
    exitCode = 1;
  } catch (error, stackTrace) {
    stderr.writeln('[verify] FAIL (unexpected): $error');
    stderr.writeln(stackTrace);
    exitCode = 1;
  }
}

String? _findPlatformDill(String repoRoot) {
  final String? flutterRoot = _findFlutterRoot(repoRoot);
  if (flutterRoot == null) {
    return null;
  }
  final String sep = Platform.pathSeparator;
  return '$flutterRoot${sep}bin${sep}cache${sep}artifacts${sep}engine'
      '${sep}common${sep}flutter_patched_sdk${sep}platform_strong.dill';
}

String? _findFlutterRoot(String repoRoot) {
  final String sep = Platform.pathSeparator;
  final File packageConfig = File(
      '$repoRoot$sep$_targetDemoDir$sep.dart_tool${sep}package_config.json');
  if (!packageConfig.existsSync()) {
    return null;
  }
  try {
    final Map<String, dynamic> json =
        jsonDecode(packageConfig.readAsStringSync()) as Map<String, dynamic>;
    for (final dynamic pkg in json['packages'] as List<dynamic>) {
      final Map<String, dynamic> map = pkg as Map<String, dynamic>;
      if (map['name'] == 'flutter') {
        final Directory flutterPkgDir =
            Directory.fromUri(Uri.parse(map['rootUri'] as String));
        return flutterPkgDir.parent.parent.path;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}

String? _findLatestAppDill(String repoRoot) {
  final String sep = Platform.pathSeparator;
  final Directory buildDir = Directory(
      '$repoRoot$sep$_targetDemoDir$sep.dart_tool${sep}flutter_build');
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
