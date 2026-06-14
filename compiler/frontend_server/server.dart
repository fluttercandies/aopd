// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:frontend_server/frontend_server.dart'
    as frontend
    show CompilerInterface, ProgramTransformer, argParser, usage;
import 'package:frontend_server/starter.dart' as frontend_starter show starter;

import 'aopd_frontend_compiler.dart';
import 'to_string_transformer.dart';

bool _aopOptionRegistered = false;

/// Idempotent: registers the `--aop` option exactly once on the shared
/// `frontend.argParser`, so subsequent parses inside pkg `starter` accept it.
void _registerAopOption() {
  if (_aopOptionRegistered) {
    return;
  }
  frontend.argParser.addOption('aop', help: 'aop transform');
  frontend.argParser.addOption(
    'aop-track-widget-creation',
    help: 'enable AOPD widget creation location tracking',
  );
  _aopOptionRegistered = true;
}

/// Entry point for the Flutter-side frontend server.
///
/// Strategy: do the minimum amount of pre-processing required to wire AOP
/// (parse `--aop`, build an [AopdFrontendCompiler], install the
/// `AopdFlutterTarget` lazily on first compile) and then hand the rest of
/// the lifecycle off to the upstream pkg `starter`. This way we automatically
/// inherit resident-compiler mode, native-assets-only mode, train mode, and
/// any future modes added upstream - without duplicating the dispatch logic
/// here.
Future<int> starter(
  List<String> args, {
  frontend.CompilerInterface? compiler,
  Stream<List<int>>? input,
  StringSink? output,
  frontend.ProgramTransformer? transformer,
}) async {
  _registerAopOption();

  ArgResults options;
  try {
    options = frontend.argParser.parse(args);
  } catch (error) {
    print('ERROR: $error\n');
    print(frontend.usage);
    return 1;
  }

  final Set<String> deleteToStringPackageUris =
      (options['delete-tostring-package-uri'] as List<String>).toSet();
  final bool aopEnabled = options['aop']?.toString() == '1';
  final bool trackWidgetCreation =
      options['aop-track-widget-creation']?.toString() == '1';

  if (aopEnabled) {
    compiler ??= AopdFrontendCompiler(
      output,
      transformer: ToStringTransformer(transformer, deleteToStringPackageUris),
      unsafePackageSerialization:
          options['unsafe-package-serialization'] as bool,
      aopTransform: true,
      trackWidgetCreation: trackWidgetCreation,
    );
  }

  // Delegate the full lifecycle (including --train, resident mode,
  // --native-assets-only, single-shot compile and stdin server) to the
  // upstream starter. Our compiler instance plugs the AOP target in lazily
  // on its first `compile` call.
  return frontend_starter.starter(
    args,
    compiler: compiler,
    input: input,
    output: output,
  );
}
