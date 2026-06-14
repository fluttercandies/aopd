// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'dart:io';

import 'rewriters/aop_item_info.dart';

/// Severity of an AOPD diagnostic.
enum AopDiagnosticLevel {
  /// Something was skipped but the build is unaffected otherwise.
  warning,

  /// A weave was abandoned; the original code is left untouched.
  error,

  /// A requested capability is not supported by this AOPD version.
  unsupported,
}

/// Single point through which the AOP transform reports problems.
///
/// Crash-safety policy ("degrade but loud"): when weaving an aspect item fails
/// or is unsupported, the transform must NOT throw. It reports here and leaves
/// the original code untouched, so a bad aspect can never kill the host build
/// or crash the host app. Every message carries enough context
/// (mode/importUri/class/method/field/line) for the user to locate the
/// offending annotation.
///
/// Messages are emitted both through the frontend-server [logger] (visible with
/// verbose logging) and to stderr, which the patched Flutter tool surfaces as
/// `printError`, so AOPD diagnostics are never silent.
class AopDiagnosticReporter {
  AopDiagnosticReporter(this._logger);

  final void Function(String msg)? _logger;

  int warningCount = 0;
  int errorCount = 0;

  /// A weave was skipped; build is otherwise fine.
  void warning(AopItemInfo? item, String message) {
    warningCount++;
    _emit(AopDiagnosticLevel.warning, item, message);
  }

  /// A weave was abandoned because something went wrong; original code kept.
  void error(AopItemInfo? item, String message) {
    errorCount++;
    _emit(AopDiagnosticLevel.error, item, message);
  }

  /// A requested capability is not supported; the item is skipped.
  void unsupported(AopItemInfo? item, String reason) {
    warningCount++;
    _emit(AopDiagnosticLevel.unsupported, item, reason);
  }

  void _emit(AopDiagnosticLevel level, AopItemInfo? item, String message) {
    final String text = _format(level, item, message);
    _logger?.call(text);
    // stderr is surfaced by the patched Flutter tool, so diagnostics stay
    // visible even when the verbose logger is not wired.
    try {
      stderr.writeln(text);
    } on Object {
      // Never let diagnostics themselves throw.
    }
  }

  String _format(AopDiagnosticLevel level, AopItemInfo? item, String message) {
    final StringBuffer buffer = StringBuffer('[AOPD] ')
      ..write(_levelLabel(level));
    if (item != null) {
      buffer.write(' mode=${item.mode.name}');
      if (item.importUri.isNotEmpty) {
        buffer.write(' importUri=${item.importUri}');
      }
      if (item.clsName.isNotEmpty) {
        buffer.write(' cls=${item.clsName}');
      }
      final String? methodName = item.methodName;
      if (methodName != null && methodName.isNotEmpty) {
        buffer.write(' method=$methodName');
      }
      final String? fieldName = item.fieldName;
      if (fieldName != null && fieldName.isNotEmpty) {
        buffer.write(' field=$fieldName');
      }
      final int? lineNum = item.lineNum;
      if (lineNum != null) {
        // item.lineNum is the internal 0-based value (the annotation's
        // 1-based lineNum minus 1). Report the 1-based source line the user
        // actually wrote.
        buffer.write(' line=${lineNum + 1}');
      }
    }
    buffer.write(' : $message');
    return buffer.toString();
  }

  String _levelLabel(AopDiagnosticLevel level) {
    switch (level) {
      case AopDiagnosticLevel.warning:
        return 'WARNING';
      case AopDiagnosticLevel.error:
        return 'ERROR';
      case AopDiagnosticLevel.unsupported:
        return 'UNSUPPORTED';
    }
  }
}
