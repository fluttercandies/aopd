import 'annotation_info.dart';

/// Wraps method execution for the matched target method.
///
/// This only works for methods that have a Dart body. Native or external
/// methods cannot be wrapped.
@pragma('vm:entry-point')
class Execute extends AnnotationInfo {
  /// Creates an execution annotation.
  ///
  /// - [importUri]: the target library URI, e.g.
  ///   `'package:flutter/src/widgets/framework.dart'`. Use `''` for the
  ///   aspect's own library when matching top-level functions.
  /// - [clsName]: the target class name, or `''` for a top-level function.
  /// - [methodName]: the method to wrap, prefixed with `-` for an instance
  ///   method or `+` for a static method / constructor / top-level function
  ///   (e.g. `'-build'`, `'+of'`).
  /// - [isRegex]: when `true`, [importUri], [clsName] and [methodName] (after
  ///   the `-`/`+` prefix) are regular expressions matched with
  ///   `RegExp.hasMatch` — a partial match, so anchor with `^...$` for exact.
  const factory Execute(
    String importUri,
    String clsName,
    String methodName, {
    bool isRegex,
  }) = Execute._;

  @pragma('vm:entry-point')
  const Execute._(
    String importUri,
    String clsName,
    String methodName, {
    super.isRegex = false,
  }) : super(importUri: importUri, clsName: clsName, methodName: methodName);
}
