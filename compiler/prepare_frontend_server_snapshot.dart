// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const String _schemaVersion = '1';
const String _snapshotName = 'frontend_server_aot.dart.snapshot';
const String _snapshotPathMarker = 'AOPD_SNAPSHOT_PATH=';

Future<void> main(List<String> args) async {
  try {
    exitCode = await runPrepareFrontendServerSnapshot(args);
  } catch (error, stackTrace) {
    stderr.writeln('[AOPD] Unexpected error while preparing snapshot: $error');
    stderr.writeln(stackTrace);
    exitCode = 255;
  }
}

Future<int> runPrepareFrontendServerSnapshot(List<String> args) async {
  final _PrepareOptions options;
  try {
    options = _PrepareOptions.parse(args);
  } on _UsageException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln(_usage);
    return 64;
  }

  final Directory? aopdRoot = _resolveAopdRoot(options.aopdRoot);
  if (aopdRoot == null) {
    stderr.writeln('[AOPD] Cannot resolve AOPD package root.');
    return 65;
  }

  final Directory appRoot =
      Directory(options.appRoot ?? Directory.current.path).absolute;
  if (!appRoot.existsSync()) {
    stderr.writeln('[AOPD] Flutter app root does not exist: ${appRoot.path}');
    return 66;
  }

  final Directory flutterRoot = Directory(options.flutterRoot).absolute;
  if (!flutterRoot.existsSync()) {
    stderr
        .writeln('[AOPD] Flutter SDK root does not exist: ${flutterRoot.path}');
    return 67;
  }

  final String dartExecutable =
      options.dartExecutable ?? Platform.resolvedExecutable;
  if (!File(dartExecutable).existsSync()) {
    stderr.writeln('[AOPD] Dart executable does not exist: $dartExecutable');
    return 68;
  }

  final String cacheKey = await _computeCacheKey(
    aopdRoot: aopdRoot,
    flutterRoot: flutterRoot,
    dartExecutable: dartExecutable,
  );

  final Directory aopdToolDir =
      Directory(_join(appRoot.path, <String>['.dart_tool', 'aopd']));
  final Directory snapshotDir =
      Directory(_join(aopdToolDir.path, <String>['snapshots', cacheKey]));
  final File snapshotFile =
      File(_join(snapshotDir.path, <String>[_snapshotName]));

  if (snapshotFile.existsSync() && !options.force) {
    stdout.writeln(
        '[AOPD] Using cached frontend_server snapshot: ${snapshotFile.path}');
    stdout.writeln('$_snapshotPathMarker${snapshotFile.path}');
    return 0;
  }

  final File generationLockFile =
      File(_join(aopdToolDir.path, <String>['locks', '$cacheKey.lock']));
  final RandomAccessFile generationLock =
      await _lockSnapshotGeneration(generationLockFile);
  try {
    if (snapshotFile.existsSync() && !options.force) {
      stdout.writeln(
          '[AOPD] Using cached frontend_server snapshot: ${snapshotFile.path}');
      stdout.writeln('$_snapshotPathMarker${snapshotFile.path}');
      return 0;
    }

    final bool inputsChanged = _hasOtherSnapshots(aopdToolDir, cacheKey);
    stdout.writeln(options.force
        ? '[AOPD] Regenerating frontend_server snapshot (--force)...'
        : inputsChanged
            ? '[AOPD] Inputs changed (compiler sources / Dart SDK / Flutter '
                'version); building a NEW frontend_server snapshot...'
            : '[AOPD] Building frontend_server snapshot (first build for this '
                'app)...');
    stdout.writeln('[AOPD] cache-key: $cacheKey');

    final Directory workspaceRoot =
        Directory(_join(aopdToolDir.path, <String>['workspace']));
    final Directory workspaceDir = _createBuildWorkspace(
      workspaceRoot: workspaceRoot,
      cacheKey: cacheKey,
    );
    workspaceDir.createSync(recursive: true);
    snapshotDir.createSync(recursive: true);
    final Directory appLocalPubCacheDir =
        Directory(_join(aopdToolDir.path, <String>['pub-cache']));

    try {
      _copyCompilerWorkspace(aopdRoot: aopdRoot, workspaceDir: workspaceDir);
    } on FileSystemException catch (error) {
      stderr.writeln(
          '[AOPD] Failed to prepare compiler workspace: ${error.message}');
      stderr.writeln('[AOPD] ${error.path}');
      return 69;
    }

    final int pubGetExitCode = await _resolveCompilerWorkspaceDependencies(
      dartExecutable,
      workspaceDir: workspaceDir,
      appLocalPubCacheDir: appLocalPubCacheDir,
    );
    if (pubGetExitCode != 0) {
      return pubGetExitCode;
    }

    final File tempSnapshotFile = File('${snapshotFile.path}.tmp');
    if (tempSnapshotFile.existsSync()) {
      tempSnapshotFile.deleteSync();
    }

    final DateTime snapshotCompileStarted = DateTime.now();
    final _ProcessRunResult snapshotResult = await _runProcess(
      dartExecutable,
      <String>[
        'compile',
        'aot-snapshot',
        'frontend_server/starter.dart',
        '-o',
        tempSnapshotFile.path,
      ],
      workingDirectory: workspaceDir.path,
      environment: _dartToolEnvironment(),
    );
    final int snapshotExitCode = snapshotResult.exitCode;
    final File? generatedSnapshotFile = await _resolveGeneratedSnapshotFile(
      tempSnapshotFile: tempSnapshotFile,
      snapshotFile: snapshotFile,
      processOutput: '${snapshotResult.stdout}\n${snapshotResult.stderr}',
      startedAt: snapshotCompileStarted,
    );
    if (snapshotExitCode != 0 && !tempSnapshotFile.existsSync()) {
      stderr.writeln('[AOPD] Failed to generate frontend_server snapshot.');
      return snapshotExitCode;
    }
    if (snapshotExitCode != 0) {
      stdout
          .writeln('[AOPD] Dart compile returned exit code $snapshotExitCode, '
              'but the snapshot file was generated. Continuing because '
              'snapshot generation completed.');
    }

    if (generatedSnapshotFile == null) {
      stderr.writeln(
          '[AOPD] Dart completed but snapshot was not created: ${tempSnapshotFile.path}');
      return 70;
    }
    if (!_samePath(generatedSnapshotFile.path, snapshotFile.path)) {
      if (snapshotFile.existsSync()) {
        snapshotFile.deleteSync();
      }
      generatedSnapshotFile.renameSync(snapshotFile.path);
    }
    _writeWorkspaceMarker(
      workspaceRoot: workspaceRoot,
      cacheKey: cacheKey,
      workspaceDir: workspaceDir,
    );
    _deleteStaleBuildWorkspaces(
      workspaceRoot: workspaceRoot,
      cacheKey: cacheKey,
      currentWorkspaceDir: workspaceDir,
    );
    // Best-effort: drop artifacts from previous cache keys (frequent while
    // iterating on the compiler, rare for released apps). Never blocks.
    _deleteOldArtifacts(aopdToolDir, cacheKey);

    stdout.writeln(
        '[AOPD] Generated frontend_server snapshot: ${snapshotFile.path}');
    stdout.writeln('$_snapshotPathMarker${snapshotFile.path}');
    return 0;
  } finally {
    _unlockSnapshotGeneration(generationLock);
  }
}

Directory _createBuildWorkspace({
  required Directory workspaceRoot,
  required String cacheKey,
}) {
  workspaceRoot.createSync(recursive: true);
  final String suffix =
      '${DateTime.now().microsecondsSinceEpoch}-${pid.toString()}';
  final Directory workspaceDir =
      Directory(_join(workspaceRoot.path, <String>['$cacheKey-$suffix']));
  if (workspaceDir.existsSync()) {
    workspaceDir.deleteSync(recursive: true);
  }
  return workspaceDir;
}

void _writeWorkspaceMarker({
  required Directory workspaceRoot,
  required String cacheKey,
  required Directory workspaceDir,
}) {
  final File marker =
      File(_join(workspaceRoot.path, <String>['$cacheKey.txt']));
  marker.writeAsStringSync(workspaceDir.path);
}

Future<RandomAccessFile> _lockSnapshotGeneration(File lockFile) async {
  lockFile.parent.createSync(recursive: true);
  stdout.writeln('[AOPD] Waiting for snapshot generation lock...');
  final Stopwatch stopwatch = Stopwatch()..start();
  var nextWaitingLog = const Duration(seconds: 10);
  // Bound the wait so a stale lock (crashed/hung process, antivirus, Windows
  // file lock) can't hang the build forever; surface an actionable error.
  const Duration maxWait = Duration(minutes: 2);

  while (true) {
    final RandomAccessFile lock = lockFile.openSync(mode: FileMode.write);
    try {
      lock.lockSync();
      stdout.writeln('[AOPD] Acquired snapshot generation lock.');
      return lock;
    } on FileSystemException catch (error) {
      lock.closeSync();
      if (!_isFileAlreadyLocked(error)) {
        rethrow;
      }
      if (stopwatch.elapsed >= maxWait) {
        throw StateError(
            '[AOPD] Timed out after ${stopwatch.elapsed.inSeconds}s waiting for '
            'the snapshot generation lock:\n  ${lockFile.path}\n'
            'A previous frontend_server / compile process is likely stuck or '
            'still holding the lock. Fix: kill stray Dart processes '
            '(Windows: `taskkill /F /IM dart.exe /IM dartaotruntime.exe`; '
            'macOS/Linux: `pkill -f dart`), optionally delete the lock file '
            'above, then rebuild.');
      }
      if (stopwatch.elapsed >= nextWaitingLog) {
        stdout
            .writeln('[AOPD] Still waiting for snapshot generation lock after '
                '${stopwatch.elapsed.inSeconds}s...');
        nextWaitingLog += const Duration(seconds: 10);
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
}

bool _isFileAlreadyLocked(FileSystemException error) {
  if (error.osError?.errorCode == 33) {
    return true;
  }
  final String message = error.message.toLowerCase();
  return message.contains('lock failed') || message.contains('locked');
}

void _unlockSnapshotGeneration(RandomAccessFile lock) {
  try {
    lock.unlockSync();
  } finally {
    lock.closeSync();
  }
}

/// Best-effort removal of artifacts left by PREVIOUS cache keys: old
/// `snapshots/<key>/` directories, `workspace/<key>.txt` markers, and
/// `workspace/<key>-<suffix>/` build dirs. Common while iterating on the AOPD
/// compiler, rare for released apps.
///
/// Each other key's artifacts are deleted only while holding that key's
/// generation lock (acquired non-blocking). If a build of that key is active it
/// holds the lock, we skip, and never delete its live snapshot/workspace --
/// closing the gap where a different-key build could nuke another running
/// build's files. The whole pass is best-effort: anything locked / in use is
/// skipped, and unexpected failures are swallowed so the build never blocks or
/// fails on cleanup.
void _deleteOldArtifacts(Directory aopdToolDir, String cacheKey) {
  bool isCacheKey(String name) =>
      name.length == 32 && RegExp(r'^[0-9a-f]+$').hasMatch(name);
  try {
    final Directory snapshotsDir =
        Directory(_join(aopdToolDir.path, <String>['snapshots']));
    final Directory workspaceRoot =
        Directory(_join(aopdToolDir.path, <String>['workspace']));

    // Collect every OTHER cache key that has artifacts on disk.
    final Set<String> otherKeys = <String>{};
    if (snapshotsDir.existsSync()) {
      for (final FileSystemEntity entity
          in snapshotsDir.listSync(followLinks: false)) {
        final String name = _basename(entity.path);
        if (entity is Directory && name != cacheKey && isCacheKey(name)) {
          otherKeys.add(name);
        }
      }
    }
    if (workspaceRoot.existsSync()) {
      for (final FileSystemEntity entity
          in workspaceRoot.listSync(followLinks: false)) {
        final String name = _basename(entity.path);
        if (entity is Directory) {
          final int dash = name.indexOf('-');
          if (dash > 0) {
            final String key = name.substring(0, dash);
            if (key != cacheKey && isCacheKey(key)) {
              otherKeys.add(key);
            }
          }
        } else if (entity is File && name.endsWith('.txt')) {
          final String key = name.substring(0, name.length - 4);
          if (key != cacheKey && isCacheKey(key)) {
            otherKeys.add(key);
          }
        }
      }
    }

    for (final String otherKey in otherKeys) {
      _deleteArtifactsForIdleKey(
        aopdToolDir: aopdToolDir,
        otherKey: otherKey,
        snapshotsDir: snapshotsDir,
        workspaceRoot: workspaceRoot,
      );
    }
  } catch (_) {
    // Cleanup is purely opportunistic; never let it affect the build.
  }
}

/// Deletes all artifacts of [otherKey] (snapshot dir, marker, build workspaces)
/// only if no build of that key is currently running -- detected by acquiring
/// the key's generation lock non-blocking. If the lock is held, a build is
/// active and we skip entirely, so we never delete a concurrent build's live
/// files.
void _deleteArtifactsForIdleKey({
  required Directory aopdToolDir,
  required String otherKey,
  required Directory snapshotsDir,
  required Directory workspaceRoot,
}) {
  final RandomAccessFile? lock =
      _tryAcquireGenerationLock(aopdToolDir, otherKey);
  if (lock == null) {
    // A build of otherKey holds the lock (or it can't be opened) -- skip.
    return;
  }
  try {
    _deleteEntityBestEffort(
        Directory(_join(snapshotsDir.path, <String>[otherKey])));
    if (workspaceRoot.existsSync()) {
      for (final FileSystemEntity entity
          in workspaceRoot.listSync(followLinks: false)) {
        final String name = _basename(entity.path);
        if (entity is File && name == '$otherKey.txt') {
          _deleteEntityBestEffort(entity);
        } else if (entity is Directory && name.startsWith('$otherKey-')) {
          _deleteEntityBestEffort(entity);
        }
      }
    }
  } finally {
    _releaseGenerationLock(lock);
  }
}

/// Tries to acquire [otherKey]'s generation lock WITHOUT blocking. Returns the
/// locked handle on success, or null if a build of that key currently holds it
/// (or the lock can't be opened). Caller must release via
/// [_releaseGenerationLock]. Uses the same `locks/<key>.lock` as
/// [_lockSnapshotGeneration]; `FileLock.exclusive` is non-blocking and throws
/// when the lock is held.
RandomAccessFile? _tryAcquireGenerationLock(
    Directory aopdToolDir, String otherKey) {
  final File lockFile =
      File(_join(aopdToolDir.path, <String>['locks', '$otherKey.lock']));
  try {
    lockFile.parent.createSync(recursive: true);
    final RandomAccessFile lock = lockFile.openSync(mode: FileMode.write);
    try {
      lock.lockSync();
      return lock;
    } on FileSystemException {
      lock.closeSync();
      return null;
    }
  } on FileSystemException {
    return null;
  }
}

void _releaseGenerationLock(RandomAccessFile lock) {
  try {
    lock.unlockSync();
  } catch (_) {
    // ignore
  } finally {
    try {
      lock.closeSync();
    } catch (_) {
      // ignore
    }
  }
}

void _deleteEntityBestEffort(FileSystemEntity entity) {
  try {
    if (entity.existsSync()) {
      entity.deleteSync(recursive: true);
    }
  } on FileSystemException {
    // Locked / in use -- skip; never block the build.
  }
}

/// Removes leftover build workspaces of THIS cache key (e.g. a crashed prior
/// build's `<cacheKey>-<suffix>/` dir), except the one in use now. Restricted
/// to the current key on purpose: same-key builds are serialized by the same
/// `locks/<cacheKey>.lock`, so any other `<cacheKey>-*` dir here is a dead
/// leftover -- never a concurrent build's active workspace. Workspaces of OTHER
/// cache keys are reclaimed by [_deleteOldArtifacts] under a per-key try-lock,
/// so a concurrent different-key build's live workspace is never deleted.
void _deleteStaleBuildWorkspaces({
  required Directory workspaceRoot,
  required String cacheKey,
  required Directory currentWorkspaceDir,
}) {
  if (!workspaceRoot.existsSync()) {
    return;
  }
  final String currentPath = currentWorkspaceDir.absolute.path;
  final String prefix = '$cacheKey-';
  for (final FileSystemEntity entity in workspaceRoot.listSync()) {
    if (entity is! Directory) {
      continue;
    }
    final String name = _basename(entity.path);
    if (!name.startsWith(prefix) || !_isBuildWorkspaceDirectory(name)) {
      continue;
    }
    if (_samePath(entity.absolute.path, currentPath)) {
      continue;
    }
    try {
      entity.deleteSync(recursive: true);
    } on FileSystemException catch (error) {
      stdout.writeln('[AOPD] Failed to remove stale workspace: '
          '${error.path ?? entity.path}');
    }
  }
}

bool _isBuildWorkspaceDirectory(String name) {
  final int separatorIndex = name.indexOf('-');
  if (separatorIndex <= 0) {
    return false;
  }
  final String cacheKey = name.substring(0, separatorIndex);
  if (cacheKey.length != 32) {
    return false;
  }
  return RegExp(r'^[0-9a-f]+$').hasMatch(cacheKey);
}

void _copyCompilerWorkspace({
  required Directory aopdRoot,
  required Directory workspaceDir,
}) {
  final Directory compilerDir =
      Directory(_join(aopdRoot.path, <String>['compiler']));
  final File compilerPubspec =
      File(_join(compilerDir.path, <String>['pubspec.yaml']));
  if (!compilerPubspec.existsSync()) {
    throw FileSystemException(
        'compiler/pubspec.yaml not found', compilerPubspec.path);
  }
  _copyDirectory(compilerDir, workspaceDir);
  _validateCompilerWorkspace(workspaceDir);
}

void _validateCompilerWorkspace(Directory workspaceDir) {
  final File pubspecFile =
      File(_join(workspaceDir.path, <String>['pubspec.yaml']));
  if (!pubspecFile.existsSync()) {
    throw FileSystemException(
        'copied compiler/pubspec.yaml not found', pubspecFile.path);
  }

  final List<String> missingPaths = <String>[];
  for (final String relativePath in _pathOverrides(pubspecFile)) {
    final Directory overrideDir = Directory(_join(
        workspaceDir.path,
        relativePath
            .split(RegExp(r'[/\\]'))
            .where((String p) => p.isNotEmpty)
            .toList()));
    final File overridePubspec =
        File(_join(overrideDir.path, <String>['pubspec.yaml']));
    if (!overrideDir.existsSync() || !overridePubspec.existsSync()) {
      missingPaths.add(relativePath);
    }
  }

  if (missingPaths.isNotEmpty) {
    throw FileSystemException(
      'compiler workspace is incomplete. Missing path overrides: '
      '${missingPaths.join(', ')}',
      workspaceDir.path,
    );
  }
}

List<String> _pathOverrides(File pubspecFile) {
  final List<String> paths = <String>[];
  for (final String line in pubspecFile.readAsLinesSync()) {
    final RegExpMatch? match =
        RegExp(r'^\s*path:\s*(.+?)\s*$').firstMatch(line);
    if (match == null) {
      continue;
    }
    String value = match.group(1)!.trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    if (value.startsWith('pkg/') || value.startsWith(r'pkg\')) {
      paths.add(value);
    }
  }
  return paths;
}

void _copyDirectory(
  Directory sourceDir,
  Directory targetDir,
) {
  if (!sourceDir.existsSync()) {
    throw FileSystemException('Source directory not found', sourceDir.path);
  }
  targetDir.createSync(recursive: true);
  for (final FileSystemEntity entity
      in sourceDir.listSync(followLinks: false)) {
    final String name = _basename(entity.path);
    final String targetPath = _join(targetDir.path, <String>[name]);
    if (entity is Directory) {
      if (_isIgnoredDirectoryName(name)) {
        continue;
      }
      _copyDirectory(entity, Directory(targetPath));
    } else if (entity is File) {
      if (_isIgnoredFileName(name)) {
        continue;
      }
      File(targetPath).parent.createSync(recursive: true);
      entity.copySync(targetPath);
    }
  }
}

bool _isIgnoredDirectoryName(String name) {
  return name == '.dart_tool' ||
      name == 'build' ||
      name == '.git' ||
      name == '.idea';
}

bool _isIgnoredFileName(String name) {
  if (name == _snapshotName || name == 'package_config.json') {
    return true;
  }
  if (name.endsWith('.snapshot') ||
      name.endsWith('.dill') ||
      name.endsWith('.tmp') ||
      name.endsWith('.log')) {
    return true;
  }
  return false;
}

/// Whether a snapshot for a DIFFERENT cache key already exists, i.e. this
/// build regenerates because inputs (compiler sources / Dart SDK / Flutter
/// version) changed -- as opposed to the very first build for this app. Used
/// only to make the log message clearer about WHY a new snapshot is built.
bool _hasOtherSnapshots(Directory aopdToolDir, String cacheKey) {
  final Directory snapshotsDir =
      Directory(_join(aopdToolDir.path, <String>['snapshots']));
  if (!snapshotsDir.existsSync()) {
    return false;
  }
  for (final FileSystemEntity entity
      in snapshotsDir.listSync(followLinks: false)) {
    if (entity is Directory && _basename(entity.path) != cacheKey) {
      return true;
    }
  }
  return false;
}

Future<String> _computeCacheKey({
  required Directory aopdRoot,
  required Directory flutterRoot,
  required String dartExecutable,
}) async {
  final _StableHash hash = _StableHash();
  hash.addString('schema=$_schemaVersion\n');
  hash.addString('os=${Platform.operatingSystem}\n');
  hash.addString('platformVersion=${Platform.version}\n');
  hash.addString('dartExecutable=$dartExecutable\n');
  hash.addString('dartVersion=${await _dartVersion(dartExecutable)}\n');

  for (final String relativePath in <String>[
    'version',
    _join('bin', <String>['cache', 'flutter.version.json']),
    _join('bin', <String>['cache', 'engine_stamp.json']),
    _join('bin', <String>['cache', 'dart-sdk', 'version']),
  ]) {
    final File file = File(_join(flutterRoot.path, <String>[relativePath]));
    if (file.existsSync()) {
      hash.addString('$relativePath=');
      hash.addBytes(file.readAsBytesSync());
      hash.addString('\n');
    }
  }

  final List<File> sourceFiles = _compilerSourceFiles(aopdRoot);
  for (final File file in sourceFiles) {
    hash.addString(_relativePath(aopdRoot.path, file.path));
    hash.addString('\n');
    hash.addBytes(file.readAsBytesSync());
    hash.addString('\n');
  }

  return hash.hex;
}

List<File> _compilerSourceFiles(Directory aopdRoot) {
  final Directory compilerDir =
      Directory(_join(aopdRoot.path, <String>['compiler']));
  final List<File> files = <File>[
    File(_join(aopdRoot.path, <String>['pubspec.yaml'])),
  ];
  if (compilerDir.existsSync()) {
    files.addAll(_listHashableFiles(compilerDir));
  }

  files.removeWhere((File file) => !file.existsSync());
  files.sort((File a, File b) => a.path.compareTo(b.path));
  return files;
}

List<File> _listHashableFiles(Directory directory) {
  final List<File> files = <File>[];
  for (final FileSystemEntity entity
      in directory.listSync(followLinks: false)) {
    final String name = _basename(entity.path);
    if (entity is Directory) {
      if (_isIgnoredDirectoryName(name) || _isHashIgnoredDirectoryName(name)) {
        continue;
      }
      files.addAll(_listHashableFiles(entity));
    } else if (entity is File &&
        !_isIgnoredFileName(name) &&
        !_isHashIgnoredFileName(name)) {
      files.add(entity);
    }
  }
  return files;
}

// #7: hash-only exclusions. These are never compiled into the snapshot (its
// entrypoint is frontend_server/starter.dart), so editing them must NOT
// invalidate the cached snapshot and trigger a needless rebuild. They are
// still COPIED into the workspace (the copy path is unchanged); only the cache
// key ignores them.
bool _isHashIgnoredDirectoryName(String name) =>
    name == 'test' || name == 'tool';

bool _isHashIgnoredFileName(String name) => name.endsWith('.md');

Future<String> _dartVersion(String dartExecutable) async {
  final ProcessResult result =
      await Process.run(dartExecutable, <String>['--version']);
  return '${result.stdout}${result.stderr}'.trim();
}

Future<int> _resolveCompilerWorkspaceDependencies(
  String dartExecutable, {
  required Directory workspaceDir,
  required Directory appLocalPubCacheDir,
}) async {
  stdout.writeln('[AOPD] Resolving compiler workspace dependencies...');

  stdout
      .writeln('[AOPD] Trying pub get with the existing Pub cache (offline).');
  _ProcessRunResult result = await _runProcess(
    dartExecutable,
    <String>['pub', 'get', '--offline', '--no-precompile'],
    workingDirectory: workspaceDir.path,
    environment: _dartToolEnvironment(),
  );
  int exitCode = result.exitCode;
  if (_hasResolvedPackageConfig(workspaceDir)) {
    if (exitCode != 0) {
      stdout.writeln('[AOPD] Pub get returned exit code $exitCode, but '
          'package_config.json was generated. Continuing because dependency '
          'resolution completed.');
    }
    stdout.writeln('[AOPD] Resolved dependencies from the existing Pub cache.');
    return 0;
  }

  stdout.writeln(
      '[AOPD] Offline pub get failed; trying the default Pub cache online.');
  result = await _runProcess(
    dartExecutable,
    <String>['pub', 'get', '--no-precompile'],
    workingDirectory: workspaceDir.path,
    environment: _dartToolEnvironment(),
  );
  exitCode = result.exitCode;
  if (_hasResolvedPackageConfig(workspaceDir)) {
    if (exitCode != 0) {
      stdout.writeln('[AOPD] Pub get returned exit code $exitCode, but '
          'package_config.json was generated. Continuing because dependency '
          'resolution completed.');
    }
    stdout.writeln('[AOPD] Resolved dependencies with the default Pub cache.');
    return 0;
  }

  appLocalPubCacheDir.createSync(recursive: true);
  stdout.writeln(
      '[AOPD] Default Pub cache failed; trying app-local PUB_CACHE: ${appLocalPubCacheDir.path}');
  result = await _runProcess(
    dartExecutable,
    <String>['pub', 'get', '--no-precompile'],
    workingDirectory: workspaceDir.path,
    environment: _dartToolEnvironment(pubCacheDir: appLocalPubCacheDir),
  );
  exitCode = result.exitCode;
  if (_hasResolvedPackageConfig(workspaceDir)) {
    if (exitCode != 0) {
      stdout.writeln('[AOPD] Pub get returned exit code $exitCode, but '
          'package_config.json was generated. Continuing because dependency '
          'resolution completed.');
    }
    stdout
        .writeln('[AOPD] Resolved dependencies with the app-local Pub cache.');
    return 0;
  }

  stderr.writeln('[AOPD] Failed to resolve compiler workspace dependencies.');
  stderr.writeln('[AOPD] The compiler workspace was copied successfully, but '
      '"dart pub get" failed in every mode.');
  stderr.writeln('[AOPD] Checked modes: existing Pub cache offline, default '
      'Pub cache online, and app-local PUB_CACHE at ${appLocalPubCacheDir.path}.');
  stderr.writeln('[AOPD] Check network access, PUB_HOSTED_URL, and Pub cache '
      'permissions, then rerun with a clean Flutter build.');
  return exitCode;
}

bool _hasResolvedPackageConfig(Directory workspaceDir) {
  final File packageConfigFile = File(
    _join(workspaceDir.path, <String>['.dart_tool', 'package_config.json']),
  );
  if (!packageConfigFile.existsSync()) {
    return false;
  }
  try {
    final Object? decoded = jsonDecode(packageConfigFile.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      return false;
    }
    final Object? packagesValue = decoded['packages'];
    if (packagesValue is! List<Object?>) {
      return false;
    }
    final Set<String> packageNames = <String>{};
    for (final Object? packageInfo in packagesValue) {
      if (packageInfo is Map<String, Object?>) {
        final Object? name = packageInfo['name'];
        if (name is String) {
          packageNames.add(name);
        }
      }
    }
    return <String>{
      'frontend_server',
      'front_end',
      'kernel',
      'vm',
      'args',
      'package_config',
    }.every(packageNames.contains);
  } on FormatException {
    return false;
  } on FileSystemException {
    return false;
  }
}

Future<_ProcessRunResult> _runProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  Map<String, String>? environment,
}) async {
  stdout.writeln('[AOPD] ${_quoteCommand(<String>[executable, ...arguments])}');
  final ProcessResult result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );
  final String stdoutText = result.stdout.toString();
  final String stderrText = _filterDartCliNoise(result.stderr.toString());
  _writeProcessOutput(stdoutText);
  _writeProcessOutput(stderrText, isError: true);
  return _ProcessRunResult(
    exitCode: result.exitCode,
    stdout: stdoutText,
    stderr: stderrText,
  );
}

Future<File?> _resolveGeneratedSnapshotFile({
  required File tempSnapshotFile,
  required File snapshotFile,
  required String processOutput,
  required DateTime startedAt,
}) async {
  final List<File> candidates = <File>[
    tempSnapshotFile,
    for (final String path in _generatedSnapshotPaths(processOutput))
      File(path),
  ];

  for (int attempt = 0; attempt < 20; attempt++) {
    for (final File candidate in candidates) {
      if (_hasUsableFile(candidate)) {
        return candidate;
      }
    }
    if (_hasUsableFile(snapshotFile) &&
        _wasModifiedAfter(snapshotFile, startedAt)) {
      return snapshotFile;
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  return null;
}

Iterable<String> _generatedSnapshotPaths(String output) sync* {
  final RegExp generatedPattern =
      RegExp(r'^Generated:\s*(.+?)\s*$', multiLine: true, caseSensitive: false);
  for (final RegExpMatch match in generatedPattern.allMatches(output)) {
    String value = match.group(1)!.trim();
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }
    if (value.isNotEmpty) {
      yield value;
    }
  }
}

bool _hasUsableFile(File file) {
  try {
    return file.existsSync() && file.lengthSync() > 0;
  } on FileSystemException {
    return false;
  }
}

bool _wasModifiedAfter(File file, DateTime startedAt) {
  try {
    return !file.lastModifiedSync().isBefore(startedAt);
  } on FileSystemException {
    return false;
  }
}

bool _samePath(String a, String b) {
  final String normalizedA = File(a).absolute.path.replaceAll(r'\', '/');
  final String normalizedB = File(b).absolute.path.replaceAll(r'\', '/');
  if (Platform.isWindows) {
    return normalizedA.toLowerCase() == normalizedB.toLowerCase();
  }
  return normalizedA == normalizedB;
}

void _writeProcessOutput(Object? output, {bool isError = false}) {
  final String text = output?.toString() ?? '';
  if (text.isEmpty) {
    return;
  }
  if (isError) {
    stderr.write(text);
  } else {
    stdout.write(text);
  }
}

String _filterDartCliNoise(String output) {
  if (output.isEmpty) {
    return output;
  }

  final List<String> keptLines = <String>[];
  bool skippingDartCliNoise = false;
  for (final String line in output.split(RegExp(r'\r?\n'))) {
    if (_isDartCliNoiseStart(line)) {
      skippingDartCliNoise = true;
      continue;
    }
    if (skippingDartCliNoise) {
      if (_isDartCliNoiseStart(line) || _isDartCliNoiseContinuation(line)) {
        continue;
      }
      skippingDartCliNoise = false;
    }
    keptLines.add(line);
  }

  final String filtered = keptLines.join('\n');
  if (filtered.isEmpty || filtered == '\n') {
    return '';
  }
  return output.endsWith('\n') ? '$filtered\n' : filtered;
}

bool _isDartCliNoiseStart(String line) {
  return line.contains('dart-flutter-telemetry-session.json') ||
      line.contains(r'Pub\Cache\active_roots') ||
      line.contains('/Pub/Cache/active_roots');
}

bool _isDartCliNoiseContinuation(String line) {
  final String trimmed = line.trim();
  return trimmed.isEmpty ||
      trimmed == '.' ||
      trimmed.startsWith(', errno = ') ||
      trimmed == '<asynchronous suspension>' ||
      trimmed.startsWith('#') ||
      trimmed.startsWith('Stack Trace:') ||
      trimmed.startsWith("Exception: 'FileSystemException") ||
      trimmed.startsWith("Invocation: 'dart ");
}

Map<String, String> _dartToolEnvironment({Directory? pubCacheDir}) {
  final Map<String, String> environment = <String, String>{
    ...Platform.environment,
    'DART_SUPPRESS_ANALYTICS': 'true',
    'FLUTTER_SUPPRESS_ANALYTICS': 'true',
  };
  if (pubCacheDir != null) {
    environment['PUB_CACHE'] = pubCacheDir.path;
  }
  return environment;
}

Directory? _resolveAopdRoot(String? explicitRoot) {
  final List<Directory> starts = <Directory>[
    if (explicitRoot != null) Directory(explicitRoot),
    Directory.current,
    File.fromUri(Platform.script).parent,
  ];
  for (final Directory start in starts) {
    Directory current = start.absolute;
    for (int i = 0; i < 8; i++) {
      if (_isAopdRoot(current)) {
        return current;
      }
      final Directory parent = current.parent;
      if (parent.path == current.path) {
        break;
      }
      current = parent;
    }
  }
  return null;
}

bool _isAopdRoot(Directory dir) {
  return File(_join(dir.path, <String>['pubspec.yaml'])).existsSync() &&
      File(_join(dir.path, <String>[
        'compiler',
        'prepare_frontend_server_snapshot.dart'
      ])).existsSync();
}

String _join(String start, List<String> parts) {
  final String sep = Platform.pathSeparator;
  String result = start;
  for (final String part in parts) {
    if (result.isEmpty) {
      result = part;
    } else if (result.endsWith('/') || result.endsWith(r'\')) {
      result = '$result$part';
    } else {
      result = '$result$sep$part';
    }
  }
  return result;
}

String _basename(String path) {
  final int slash = path.lastIndexOf('/');
  final int backslash = path.lastIndexOf(r'\');
  final int index = slash > backslash ? slash : backslash;
  return index == -1 ? path : path.substring(index + 1);
}

String _relativePath(String root, String path) {
  final String normalizedRoot =
      Directory(root).absolute.path.replaceAll(r'\', '/');
  final String normalizedPath = File(path).absolute.path.replaceAll(r'\', '/');
  final String prefix =
      normalizedRoot.endsWith('/') ? normalizedRoot : '$normalizedRoot/';
  if (normalizedPath.startsWith(prefix)) {
    return normalizedPath.substring(prefix.length);
  }
  return normalizedPath;
}

String _quoteCommand(List<String> command) {
  return command.map((String part) {
    if (part.contains(' ')) {
      return '"$part"';
    }
    return part;
  }).join(' ');
}

class _PrepareOptions {
  _PrepareOptions({
    required this.flutterRoot,
    this.appRoot,
    this.aopdRoot,
    this.dartExecutable,
    this.force = false,
  });

  final String? appRoot;
  final String? aopdRoot;
  final String flutterRoot;
  final String? dartExecutable;
  final bool force;

  static _PrepareOptions parse(List<String> args) {
    String? appRoot;
    String? aopdRoot;
    String? flutterRoot;
    String? dartExecutable;
    bool force = false;

    for (int i = 0; i < args.length; i++) {
      final String arg = args[i];
      String readValue(String name) {
        if (arg.startsWith('$name=')) {
          return arg.substring(name.length + 1);
        }
        if (arg == name && i + 1 < args.length) {
          i += 1;
          return args[i];
        }
        throw _UsageException('Missing value for $name');
      }

      if (arg == '--app-root' || arg.startsWith('--app-root=')) {
        appRoot = readValue('--app-root');
      } else if (arg == '--aopd-root' || arg.startsWith('--aopd-root=')) {
        aopdRoot = readValue('--aopd-root');
      } else if (arg == '--flutter-root' || arg.startsWith('--flutter-root=')) {
        flutterRoot = readValue('--flutter-root');
      } else if (arg == '--dart' || arg.startsWith('--dart=')) {
        dartExecutable = readValue('--dart');
      } else if (arg == '--force') {
        force = true;
      } else if (arg == '--help' || arg == '-h') {
        throw _UsageException(_usage);
      } else {
        throw _UsageException('Unknown argument: $arg');
      }
    }

    flutterRoot ??= Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot == null || flutterRoot.isEmpty) {
      throw _UsageException('Missing required --flutter-root.');
    }

    return _PrepareOptions(
      appRoot: appRoot,
      aopdRoot: aopdRoot,
      flutterRoot: flutterRoot,
      dartExecutable: dartExecutable,
      force: force,
    );
  }
}

class _UsageException implements Exception {
  _UsageException(this.message);

  final String message;
}

class _ProcessRunResult {
  const _ProcessRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class _StableHash {
  static const int _prime = 0x01000193;
  static const int _mask = 0xffffffff;

  final List<int> _hashes = <int>[
    0x811c9dc5,
    0x12345678,
    0x9e3779b9,
    0xfeedbeef,
  ];

  void addString(String value) {
    addBytes(Uint8List.fromList(utf8.encode(value)));
  }

  void addBytes(List<int> bytes) {
    for (final int byte in bytes) {
      for (int i = 0; i < _hashes.length; i++) {
        _hashes[i] ^= (byte + i * 17) & 0xff;
        _hashes[i] = (_hashes[i] * _prime) & _mask;
      }
    }
  }

  String get hex => _hashes
      .map((int value) => value.toRadixString(16).padLeft(8, '0'))
      .join();
}

const String _usage = '''
Usage:
  dart run bin/prepare_frontend_server_snapshot.dart --flutter-root <flutterRoot> [options]

Options:
  --app-root <path>      Flutter application root. Defaults to current directory.
  --aopd-root <path>     AOPD package root. Defaults to resolving from this script.
  --flutter-root <path>  Flutter SDK root.
  --dart <path>          Dart executable used to run pub get and compile the snapshot.
  --force                Regenerate the snapshot even when the cache entry exists.
''';
