import 'annotation_info.dart';

/// Replaces reads of the matched field.
@pragma('vm:entry-point')
class FieldGet extends AnnotationInfo {
  /// Creates a field-read annotation.
  ///
  /// - [importUri]: the target library URI.
  /// - [clsName]: the class declaring the field.
  /// - [fieldName]: the field whose reads are replaced.
  /// - [isStatic]: whether the matched field is static.
  /// - [isRegex]: when `true`, [importUri], [clsName] and [fieldName] are
  ///   `RegExp.hasMatch` patterns (partial match — anchor with `^...$`).
  const factory FieldGet(
    String importUri,
    String clsName,
    String fieldName,
    bool isStatic, {
    bool isRegex,
  }) = FieldGet._;

  @pragma('vm:entry-point')
  const FieldGet._(
    String importUri,
    String clsName,
    this.fieldName,
    this.isStatic, {
    super.isRegex = false,
  }) : super(importUri: importUri, clsName: clsName);

  /// Field name to match.
  final String fieldName;

  /// Whether the matched field is static.
  final bool isStatic;
}
