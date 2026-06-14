import 'annotation_info.dart';

/// Inserts statements into a matched method at a stable source line.
///
/// Note: `@Inject` matches its target by EXACT `importUri` / `clsName` /
/// `methodName`. Unlike `@Call`/`@Execute`/`@Add`, it does not support regex
/// matching, so no `isRegex` parameter is exposed.
@pragma('vm:entry-point')
class Inject extends AnnotationInfo {
  /// Creates an injection annotation.
  ///
  /// [lineNum] is required: the compiler needs a stable source line to inject
  /// at, and omitting it would otherwise surface as a compiler-side error
  /// rather than a clear Dart compile error here.
  const factory Inject(
    String importUri,
    String clsName,
    String methodName, {
    required int lineNum,
  }) = Inject._;

  @pragma('vm:entry-point')
  const Inject._(
    String importUri,
    String clsName,
    String methodName, {
    required int lineNum,
  }) : super(
         importUri: importUri,
         clsName: clsName,
         methodName: methodName,
         lineNum: lineNum,
       );
}
