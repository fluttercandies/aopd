import 'annotation_info.dart';

/// Replaces call sites matching the target method.
///
/// Unlike [Execute] (which wraps the callee's body), `@Call` rewrites the
/// call *site*, so it can also intercept constructor invocations.
@pragma('vm:entry-point')
class Call extends AnnotationInfo {
  /// Creates a call-site annotation.
  ///
  /// - [importUri]: the target library URI, e.g.
  ///   `'package:flutter/src/widgets/framework.dart'`.
  /// - [clsName]: the target class name, or `''` for a top-level function.
  /// - [methodName]: the call to replace, prefixed with `-` for an instance
  ///   method or `+` for a static method / constructor / top-level function.
  ///   Use the class name itself with `+` to match a constructor call.
  /// - [isRegex]: when `true`, the matchers are `RegExp.hasMatch` patterns
  ///   (partial match — anchor with `^...$` for exact).
  /// - [excludeCoreLib]: when `true`, call sites inside `dart:` and
  ///   `package:flutter/` libraries are not rewritten.
  const factory Call(
    String importUri,
    String clsName,
    String methodName, {
    bool isRegex,
    bool excludeCoreLib,
  }) = Call._;

  @pragma('vm:entry-point')
  const Call._(
    String importUri,
    String clsName,
    String methodName, {
    super.isRegex = false,
    this.excludeCoreLib = false,
  }) : super(importUri: importUri, clsName: clsName, methodName: methodName);

  /// Whether calls from Dart and Flutter SDK libraries should be ignored.
  final bool excludeCoreLib;
}
