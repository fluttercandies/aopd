/// Base metadata shared by AOPD annotations.
@pragma('vm:entry-point')
class AnnotationInfo {
  /// Creates annotation metadata for a target library, class, and method.
  @pragma('vm:entry-point')
  const AnnotationInfo({
    required this.importUri,
    required this.clsName,
    this.methodName,
    this.lineNum,
    this.isRegex = false,
    this.superCls,
  });

  /// Dart library URI to operate on.
  final String importUri;

  /// Dart class name to operate on.
  final String clsName;

  /// Dart method name to operate on.
  final String? methodName;

  /// Whether target strings should be interpreted as regular expressions.
  final bool isRegex;

  /// One-based source line used by `@Inject`.
  ///
  /// AOPD inserts before this line when the target is transformed.
  final int? lineNum;

  /// Superclass name used by regex-based `@Add` matching.
  final String? superCls;
}
