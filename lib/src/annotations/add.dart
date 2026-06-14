import 'annotation_info.dart';

/// Adds the annotated method to classes matching the target class or pattern.
///
/// The advice method's name becomes the added method's name. Because the
/// method does not exist statically, callers invoke it through dynamic
/// dispatch.
@pragma('vm:entry-point')
class Add extends AnnotationInfo {
  /// Creates an add-method annotation.
  ///
  /// - [importUri]: the target library URI.
  /// - [clsName]: the class (or, with [isRegex], the class-name pattern) that
  ///   receives the method.
  /// - [isRegex]: when `true`, [importUri] and [clsName] are `RegExp.hasMatch`
  ///   patterns (partial match — anchor with `^...$`).
  /// - [superCls]: when set, only classes that have this class somewhere in
  ///   their superclass chain are matched.
  const factory Add(
    String importUri,
    String clsName, {
    bool isRegex,
    String? superCls,
  }) = Add._;

  @pragma('vm:entry-point')
  const Add._(
    String importUri,
    String clsName, {
    super.isRegex = false,
    super.superCls,
  }) : super(importUri: importUri, clsName: clsName);
}
