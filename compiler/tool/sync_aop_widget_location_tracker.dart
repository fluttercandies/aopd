// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

import 'dart:io';

/// Regenerates AOPD's widget-location tracker from the upstream kernel tracker.
///
/// The upstream file is intentionally mirrored under `pkg/kernel`. AOPD needs a
/// small, well-known set of changes: package imports, distinct parameter/field
/// names, AOPD runtime location classes, and the `ownerImportUri` payload.
/// Keeping those changes as checked replacements makes SDK upgrades much less
/// hand-edited.
void main(List<String> args) {
  final bool checkOnly = args.contains('--check');
  final Directory compilerRoot = _findCompilerRoot();
  final File upstreamFile = File(
    '${compilerRoot.path}/pkg/kernel/lib/transformations/'
    'track_widget_constructor_locations.dart',
  );
  final File targetFile = File(
    '${compilerRoot.path}/transformer/widget_location/'
    'track_widget_constructor_locations.dart',
  );

  if (!upstreamFile.existsSync()) {
    stderr.writeln('Upstream tracker not found: ${upstreamFile.path}');
    exitCode = 1;
    return;
  }
  if (!targetFile.existsSync()) {
    stderr.writeln('AOPD tracker not found: ${targetFile.path}');
    exitCode = 1;
    return;
  }

  final String upstream = upstreamFile.readAsStringSync();
  final String generated = _generateAopdTracker(upstream);

  if (checkOnly) {
    final String current = targetFile.readAsStringSync();
    if (current != generated) {
      stderr.writeln(
        'AOPD widget-location tracker is out of sync. '
        'Run: dart tool/sync_aop_widget_location_tracker.dart',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('AOPD widget-location tracker is up to date.');
    return;
  }

  targetFile.writeAsStringSync(generated);
  stdout.writeln('Generated ${targetFile.path}');
}

Directory _findCompilerRoot() {
  final File scriptFile = File.fromUri(Platform.script);
  final Directory toolDir = scriptFile.parent;
  final Directory compilerRoot = toolDir.parent;
  final File pubspec = File('${compilerRoot.path}/pubspec.yaml');
  if (!pubspec.existsSync() ||
      !pubspec.readAsStringSync().contains('name: aopd_compiler')) {
    throw StateError(
      'Unable to resolve compiler root from ${scriptFile.path}.',
    );
  }
  return compilerRoot;
}

String _generateAopdTracker(String source) {
  String text = source.replaceAll('\r\n', '\n');

  text = _replaceRequired(
    text,
    oldText:
        "library kernel.transformations.track_widget_constructor_locations;\n\n"
        "import '../ast.dart';\n"
        "import '../target/changed_structure_notifier.dart';",
    newText: "import 'package:kernel/ast.dart';\n"
        "import 'package:kernel/target/changed_structure_notifier.dart';",
    label: 'imports',
  );

  text = _replaceRequiredCount(
    text,
    oldText: 'creationLocationd_0dea112b090073317d4',
    newText: 'creationLocationAopd_0dea112b090073317d4',
    expectedCount: 1,
    label: 'AOPD creation-location parameter name',
  );

  text = _replaceRequiredCount(
    text,
    oldText: "r'_location'",
    newText: "r'aopLocation'",
    expectedCount: 1,
    label: 'AOPD location field name',
  );

  text = _replaceRequired(
    text,
    oldText: '  ConstructorInvocation _constructLocation(\n'
        '    Location location, {\n'
        '    String? name,\n'
        '  }) {',
    newText: '  ConstructorInvocation _constructLocation(\n'
        '    Location location, {\n'
        '    String? name,\n'
        '    String? ownerImportUri,\n'
        '  }) {',
    label: 'ownerImportUri constructor parameter',
  );

  text = _replaceRequired(
    text,
    oldText:
        "      if (name != null) new NamedExpression('name', new StringLiteral(name))",
    newText:
        "      if (name != null) new NamedExpression('name', new StringLiteral(name)),\n"
        '      if (ownerImportUri != null)\n'
        "        new NamedExpression('ownerImportUri', new StringLiteral(ownerImportUri))",
    label: 'ownerImportUri named expression',
  );

  text = _replaceRequired(
    text,
    oldText: '    return _constructLocation(\n'
        '      node.location!,\n'
        '      name: constructedClass?.name ??\n'
        '          // For extension factory methods we use the name of the method.\n'
        '          (function.parent! as Procedure).name.text,\n'
        '    );',
    newText: '    String? ownerImportUri;\n'
        '    if (constructedClass != null) {\n'
        '      ownerImportUri = constructedClass.enclosingLibrary.importUri.toString();\n'
        '    } else {\n'
        '      final TreeNode? parent = function.parent;\n'
        '      if (parent is Procedure) {\n'
        '        ownerImportUri = parent.enclosingLibrary.importUri.toString();\n'
        '      }\n'
        '    }\n'
        '\n'
        '    return _constructLocation(\n'
        '      node.location!,\n'
        '      name: constructedClass?.name ??\n'
        '          // For extension factory methods we use the name of the method.\n'
        '          (function.parent! as Procedure).name.text,\n'
        '      ownerImportUri: ownerImportUri,\n'
        '    );',
    label: 'ownerImportUri computation',
  );

  text = _replaceRequired(
    text,
    oldText: "importUri.path == 'flutter/src/widgets/widget_inspector.dart'",
    newText: "importUri.path == 'aopd/src/location.dart'",
    label: 'AOPD location library URI',
  );

  text = _replaceRequired(
    text,
    oldText: "class_.name == '_HasCreationLocation'",
    newText: "class_.name == 'AopHasCreationLocation'",
    label: 'AOPD has-location class name',
  );

  text = _replaceRequired(
    text,
    oldText: "class_.name == '_Location'",
    newText: "class_.name == 'AopLocation'",
    label: 'AOPD location class name',
  );

  text = _replaceRequired(
    text,
    oldText: "              } else if (class_.name == '_WidgetFactory') {\n"
        '                _widgetFactoryClass = class_;\n',
    newText: '',
    label: 'remove stock widget factory lookup from AOPD location library',
  );

  return text;
}

String _replaceRequired(
  String source, {
  required String oldText,
  required String newText,
  required String label,
}) {
  final int firstIndex = source.indexOf(oldText);
  if (firstIndex == -1) {
    throw StateError('Unable to apply patch: $label');
  }
  final int secondIndex = source.indexOf(oldText, firstIndex + oldText.length);
  if (secondIndex != -1) {
    throw StateError('Patch "$label" matched more than once.');
  }
  return source.replaceFirst(oldText, newText);
}

String _replaceRequiredCount(
  String source, {
  required String oldText,
  required String newText,
  required int expectedCount,
  required String label,
}) {
  final int count = oldText.allMatches(source).length;
  if (count != expectedCount) {
    throw StateError(
      'Patch "$label" expected $expectedCount matches, found $count.',
    );
  }
  return source.replaceAll(oldText, newText);
}
