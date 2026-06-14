// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:frontend_server/frontend_server.dart'
    as frontend
    show CompilerInterface, FrontendCompiler, ProgramTransformer;
import 'package:vm/incremental_compiler.dart';

import '../transformer/aopd_flutter_target.dart';

/// A [frontend.FrontendCompiler] wrapper that installs the AOPD Flutter target
/// before the first real compile.
///
/// The target instance owns the AOP transformer, so incremental recompile
/// cycles keep using the same AOP state without extra frontend-server
/// bookkeeping.
class AopdFrontendCompiler implements frontend.CompilerInterface {
  AopdFrontendCompiler(
    StringSink? output, {
    bool? unsafePackageSerialization,
    frontend.ProgramTransformer? transformer,
    this.aopTransform = false,
    this.trackWidgetCreation = false,
  }) : _compiler = frontend.FrontendCompiler(
         output,
         transformer: transformer,
         unsafePackageSerialization: unsafePackageSerialization,
       );

  final frontend.CompilerInterface _compiler;
  final bool aopTransform;
  final bool trackWidgetCreation;
  bool _targetInstalled = false;

  void _ensureAopTargetInstalled() {
    if (aopTransform && !_targetInstalled) {
      installAopdFlutterTarget(trackWidgetCreation: trackWidgetCreation);
      _targetInstalled = true;
    }
  }

  @override
  Future<bool> compile(
    String filename,
    ArgResults options, {
    IncrementalCompiler? generator,
  }) async {
    _ensureAopTargetInstalled();
    return _compiler.compile(filename, options, generator: generator);
  }

  @override
  Future<void> recompileDelta({
    String? entryPoint,
    bool recompileRestart = false,
  }) {
    return _compiler.recompileDelta(
      entryPoint: entryPoint,
      recompileRestart: recompileRestart,
    );
  }

  @override
  void acceptLastDelta() {
    _compiler.acceptLastDelta();
  }

  @override
  Future<void> rejectLastDelta() {
    return _compiler.rejectLastDelta();
  }

  @override
  void invalidate(Uri uri) {
    _compiler.invalidate(uri);
  }

  @override
  Future<void> compileExpression(
    String expression,
    List<String> definitions,
    List<String> definitionTypes,
    List<String> typeDefinitions,
    List<String> typeBounds,
    List<String> typeDefaults,
    String libraryUri,
    String? klass,
    String? method,
    int offset,
    String? scriptUri,
    bool isStatic,
  ) {
    return _compiler.compileExpression(
      expression,
      definitions,
      definitionTypes,
      typeDefinitions,
      typeBounds,
      typeDefaults,
      libraryUri,
      klass,
      method,
      offset,
      scriptUri,
      isStatic,
    );
  }

  @override
  Future<void> compileExpressionToJs(
    String libraryUri,
    String? scriptUri,
    int line,
    int column,
    Map<String, String> jsModules,
    Map<String, String> jsFrameValues,
    String expression,
  ) {
    return _compiler.compileExpressionToJs(
      libraryUri,
      scriptUri,
      line,
      column,
      jsModules,
      jsFrameValues,
      expression,
    );
  }

  @override
  void reportError(String msg) {
    _compiler.reportError(msg);
  }

  @override
  void resetIncrementalCompiler() {
    _compiler.resetIncrementalCompiler();
  }

  @override
  Future<bool> setNativeAssets(String nativeAssets) {
    return _compiler.setNativeAssets(nativeAssets);
  }

  @override
  Future<bool> compileNativeAssetsOnly(
    ArgResults options, {
    IncrementalCompiler? generator,
  }) {
    return _compiler.compileNativeAssetsOnly(options, generator: generator);
  }
}
