import 'dart:io';

// Change this value to dump another local demo project.
const String _targetDemoDir = 'example';

Future<void> main(List<String> args) async {
  final scriptFile = File.fromUri(Platform.script);
  final binDir = scriptFile.parent;
  final repoRoot = _resolveRepoRoot(binDir);

  if (repoRoot == null) {
    stderr.writeln(
        'Cannot resolve repository root from script path: ${scriptFile.path}');
    exitCode = 1;
    return;
  }

  final dumpKernelScript = File(
    '${repoRoot.path}${Platform.pathSeparator}compiler${Platform.pathSeparator}pkg${Platform.pathSeparator}vm${Platform.pathSeparator}bin${Platform.pathSeparator}dump_kernel.dart',
  );
  if (!dumpKernelScript.existsSync()) {
    stderr.writeln('dump_kernel.dart not found: ${dumpKernelScript.path}');
    exitCode = 2;
    return;
  }

  final outputPath = args.length >= 2
      ? args[1]
      : '${repoRoot.path}${Platform.pathSeparator}$_targetDemoDir${Platform.pathSeparator}out.dill.txt';

  String? inputDillPath;
  if (args.isNotEmpty) {
    inputDillPath = args[0];
  } else {
    inputDillPath = _findLatestAppDill(repoRoot.path);
  }

  if (inputDillPath == null) {
    stderr.writeln(
      'No app.dill found under $_targetDemoDir/.dart_tool/flutter_build/.',
    );
    stderr.writeln('Try running a Flutter build first, for example:');
    stderr.writeln('  cd $_targetDemoDir');
    stderr.writeln('  flutter build apk --debug');
    exitCode = 3;
    return;
  }

  final dartExe = Platform.resolvedExecutable;
  final cmdArgs = [dumpKernelScript.path, inputDillPath, outputPath];

  stdout.writeln('Using dart: $dartExe');
  stdout.writeln('Input dill: $inputDillPath');
  stdout.writeln('Output txt: $outputPath');
  stdout.writeln('Running: dart ${cmdArgs.join(' ')}');

  final process = await Process.start(
    dartExe,
    cmdArgs,
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: repoRoot.path,
  );

  final code = await process.exitCode;
  if (code != 0) {
    stderr.writeln('dump_kernel failed with exit code: $code');
    exitCode = code;
    return;
  }

  final outFile = File(outputPath);
  if (!outFile.existsSync()) {
    stderr.writeln('Output file was not created: $outputPath');
    exitCode = 4;
    return;
  }

  stdout.writeln(
      'Done. Output generated: $outputPath (${outFile.lengthSync()} bytes)');
}

String? _findLatestAppDill(String repoRootPath) {
  final flutterBuildDir = Directory(
    '$repoRootPath${Platform.pathSeparator}$_targetDemoDir${Platform.pathSeparator}.dart_tool${Platform.pathSeparator}flutter_build',
  );
  if (!flutterBuildDir.existsSync()) {
    return null;
  }

  final appDillFiles = <File>[];
  for (final entity
      in flutterBuildDir.listSync(recursive: true, followLinks: false)) {
    if (entity is File &&
        entity.path.endsWith('${Platform.pathSeparator}app.dill')) {
      appDillFiles.add(entity);
    }
  }

  if (appDillFiles.isEmpty) {
    return null;
  }

  appDillFiles.sort(
    (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
  );
  return appDillFiles.first.path;
}

Directory? _resolveRepoRoot(Directory scriptDir) {
  var current = scriptDir;
  for (var i = 0; i < 6; i++) {
    final pubspec =
        File('${current.path}${Platform.pathSeparator}pubspec.yaml');
    final dumpKernel = File(
      '${current.path}${Platform.pathSeparator}compiler${Platform.pathSeparator}pkg${Platform.pathSeparator}vm${Platform.pathSeparator}bin${Platform.pathSeparator}dump_kernel.dart',
    );
    if (pubspec.existsSync() && dumpKernel.existsSync()) {
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
