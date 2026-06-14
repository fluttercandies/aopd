const String _vmEntryPoint = 'vm:entry-point';

/// Interface for classes that track the source code location where their
/// constructor was called from.
///
/// {@macro flutter.widgets.WidgetInspectorService.getChildrenSummaryTree}
/// The compiler transform adds this interface to widget classes so AOPD can
/// expose source locations without depending on Flutter Inspector internals.
@pragma(_vmEntryPoint)
abstract class AopHasCreationLocation {
  AopLocation get aopLocation;
}

/// See `compiler/transformer/widget_location/track_widget_constructor_locations.dart`
/// for the compiler transform that creates these values.
@pragma(_vmEntryPoint)
class AopLocation {
  const AopLocation({
    required this.file,
    required this.line,
    required this.column,
    this.name,
    this.ownerImportUri,
  });

  final String file;
  final int line;
  final int column;
  final String? name;

  /// Import URI of the class that owns this location, used to distinguish
  /// Flutter SDK widgets from app and package widgets.
  final String? ownerImportUri;

  bool isFlutterSdk() {
    if (ownerImportUri != null &&
        ownerImportUri!.startsWith('package:flutter/')) {
      return true;
    }
    final String normalizedFile = file.replaceAll(r'\', '/');
    if (normalizedFile.contains('/packages/flutter/')) {
      return true;
    }
    return false;
  }

  @override
  String toString() {
    return 'AopLocation{file: $file, line: $line, column: $column, name: $name, ownerImportUri: $ownerImportUri}';
  }
}
