// Source-level debugging entrypoint for AOPD's frontend_server wrapper.
//
// Launch this script with the compiler package config:
//
//   --packages=compiler/.dart_tool/package_config.json
//
// Without that package config, the Dart VM cannot resolve packages such as
// frontend_server, kernel, and vm.

// ignore_for_file: unintended_html_in_doc_comment

import 'dart:convert';
import 'dart:io';

import '../compiler/frontend_server/server.dart' as server;

// Pass the demo project directory as the first argument, for example: example.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart --packages=compiler/.dart_tool/package_config.json '
      'bin/debug_server.dart <demo-project-dir>\n'
      '       e.g. bin/debug_server.dart example',
    );
    exitCode = 64; // EX_USAGE
    return;
  }
  final targetDemoDir = args.first;

  final scriptFile = File.fromUri(Platform.script);
  final repoRoot = _resolveRepoRoot(scriptFile.parent);
  if (repoRoot == null) {
    stderr.writeln('ERROR: Cannot resolve repository root from script path.');
    stderr.writeln('       Script: ${scriptFile.path}');
    exitCode = 1;
    return;
  }

  final sep = Platform.pathSeparator;
  final exampleDir = Directory('${repoRoot.path}$sep$targetDemoDir');
  if (!exampleDir.existsSync()) {
    stderr.writeln(
      'ERROR: $targetDemoDir/ directory not found at: ${exampleDir.path}',
    );
    exitCode = 2;
    return;
  }

  final flutterRoot = _findFlutterRoot(exampleDir);
  if (flutterRoot == null) {
    stderr.writeln('ERROR: Cannot determine Flutter SDK root.');
    stderr.writeln('       Run `flutter pub get` inside $targetDemoDir/ first.');
    exitCode = 3;
    return;
  }

  final buildHashDir = _findLatestBuildHashDir(exampleDir);
  if (buildHashDir == null) {
    stderr.writeln('ERROR: No flutter_build hash directory found.');
    stderr.writeln('       Run a build first:');
    stderr.writeln('         cd $targetDemoDir && flutter build apk --debug');
    exitCode = 4;
    return;
  }

  final depfilePath =
      _findDepfile(buildHashDir) ??
      '${buildHashDir.path}${sep}kernel_snapshot_program.d';

  final sdkRoot =
      '$flutterRoot${sep}bin${sep}cache${sep}artifacts${sep}engine'
      '${sep}common${sep}flutter_patched_sdk$sep';
  final packageConfig =
      '${exampleDir.path}$sep.dart_tool${sep}package_config.json';
  final outputDill = '${buildHashDir.path}${sep}app.dill';

  final File outputDillFile = File(outputDill);
  if (outputDillFile.existsSync()) {
    outputDillFile.deleteSync();
    stdout.writeln('Deleted stale app.dill to force full AOP recompile.');
  }

  final flutterInfo = await _readFlutterVersionInfo(flutterRoot);
  final flutterVersion = flutterInfo['frameworkVersion'] ?? '';
  final flutterChannel = flutterInfo['channel'] ?? '';
  final flutterGitUrl = flutterInfo['repositoryUrl'] ?? '';
  final flutterFrameworkRevision = flutterInfo['frameworkRevision'] ?? '';
  final flutterEngineRevision = flutterInfo['engineRevision'] ?? '';
  final flutterDartVersion = _normalizeDartVersion(
    flutterInfo['dartSdkVersion'] ?? '',
  );

  final builtArgs = <String>[
    '--sdk-root',
    sdkRoot,
    '--target=flutter',
    '--no-print-incremental-dependencies',
    '-DFLUTTER_VERSION=$flutterVersion',
    '-DFLUTTER_CHANNEL=$flutterChannel',
    '-DFLUTTER_GIT_URL=$flutterGitUrl',
    '-DFLUTTER_FRAMEWORK_REVISION=$flutterFrameworkRevision',
    '-DFLUTTER_ENGINE_REVISION=$flutterEngineRevision',
    '-DFLUTTER_DART_VERSION=$flutterDartVersion',
    '-DFLUTTER_APP_FLAVOR=',
    '-Ddart.vm.profile=false',
    '-Ddart.vm.product=false',
    '--enable-asserts',
    '--track-widget-creation',
    // AOPD's own widget-location tracker is gated on this flag (the stock
    // --track-widget-creation only drives Flutter's Inspector); enable it so
    // this entrypoint can debug AOPD widget-location weaving.
    '--aop-track-widget-creation',
    '1',
    '--no-link-platform',
    '--packages',
    packageConfig,
    '--output-dill',
    outputDill,
    '--depfile',
    depfilePath,
    '--incremental',
    '--aop',
    '1',
    '--verbosity=error',
    'package:$targetDemoDir/main.dart',
  ];

  stdout.writeln('Flutter root  : $flutterRoot');
  stdout.writeln('Build hash dir: ${buildHashDir.path}');
  stdout.writeln('Depfile       : $depfilePath');
  stdout.writeln('');
  stdout.writeln('frontend_server args:');
  stdout.writeln('  ${builtArgs.join(' ')}');
  stdout.writeln('');

  exitCode = await server.starter(builtArgs);
}

Future<Map<String, String>> _readFlutterVersionInfo(String flutterRoot) async {
  final String sep = Platform.pathSeparator;
  final String flutterToolPath = Platform.isWindows
      ? '$flutterRoot${sep}bin${sep}flutter.bat'
      : '$flutterRoot${sep}bin${sep}flutter';

  final File flutterTool = File(flutterToolPath);
  if (!flutterTool.existsSync()) {
    return <String, String>{};
  }

  try {
    final ProcessResult result = await Process.run(
      flutterToolPath,
      <String>['--version', '--machine'],
    );
    if (result.exitCode != 0) {
      return <String, String>{};
    }

    final String output = (result.stdout as String).trim();
    if (output.isEmpty) {
      return <String, String>{};
    }

    final Object decoded = jsonDecode(output);
    if (decoded is! Map<String, dynamic>) {
      return <String, String>{};
    }

    String readString(String key) {
      final Object? value = decoded[key];
      return value is String ? value : '';
    }

    return <String, String>{
      'frameworkVersion': readString('frameworkVersion'),
      'channel': readString('channel'),
      'repositoryUrl': readString('repositoryUrl'),
      'frameworkRevision': readString('frameworkRevision'),
      'engineRevision': readString('engineRevision'),
      'dartSdkVersion': readString('dartSdkVersion'),
    };
  } catch (_) {
    return <String, String>{};
  }
}

String _normalizeDartVersion(String raw) {
  if (raw.isEmpty) {
    return '';
  }
  return raw.split(' ').first;
}

Directory? _resolveRepoRoot(Directory scriptDir) {
  var current = scriptDir;
  for (var i = 0; i < 6; i++) {
    final pubspec = File(
      '${current.path}${Platform.pathSeparator}pubspec.yaml',
    );
    final frontendServer = Directory(
      '${current.path}${Platform.pathSeparator}compiler'
      '${Platform.pathSeparator}frontend_server',
    );
    if (pubspec.existsSync() && frontendServer.existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return null;
}

String? _findFlutterRoot(Directory exampleDir) {
  final packageConfigFile = File(
    '${exampleDir.path}${Platform.pathSeparator}.dart_tool'
    '${Platform.pathSeparator}package_config.json',
  );
  if (!packageConfigFile.existsSync()) return null;

  try {
    final json =
        jsonDecode(packageConfigFile.readAsStringSync())
            as Map<String, dynamic>;
    final packages = json['packages'] as List<dynamic>;
    for (final pkg in packages) {
      final map = pkg as Map<String, dynamic>;
      if (map['name'] == 'flutter') {
        final rootUri = map['rootUri'] as String;
        final flutterPkgDir = Directory.fromUri(Uri.parse(rootUri));
        return flutterPkgDir.parent.parent.path;
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}

Directory? _findLatestBuildHashDir(Directory exampleDir) {
  final flutterBuildDir = Directory(
    '${exampleDir.path}${Platform.pathSeparator}.dart_tool'
    '${Platform.pathSeparator}flutter_build',
  );
  if (!flutterBuildDir.existsSync()) return null;

  final dirs = flutterBuildDir
      .listSync(followLinks: false)
      .whereType<Directory>()
      .toList();
  if (dirs.isEmpty) return null;

  dirs.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return dirs.first;
}

String? _findDepfile(Directory hashDir) {
  for (final entity in hashDir.listSync(followLinks: false)) {
    if (entity is File && entity.path.endsWith('.d')) {
      return entity.path;
    }
  }
  return null;
}
