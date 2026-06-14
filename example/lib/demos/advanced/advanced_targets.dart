import 'package:example/shared/demo_event_log.dart';

class DemoTag {
  const DemoTag(this.name);

  final String name;
}

@DemoTag('advanced-target')
class AdvancedTarget {
  AdvancedTarget(this.name) {
    DemoEventLog.instance.addTarget(
      'Constructor body',
      'AdvancedTarget($name) was created.',
    );
  }

  final String name;
  final int importance = 10;

  String instanceRecipe(int count, {String mode = 'balanced'}) {
    DemoEventLog.instance.addTarget(
      'Instance body',
      'count=$count, mode=$mode, name=$name.',
    );
    return 'instance:$count:$mode';
  }

  static String staticRecipe(String label) {
    DemoEventLog.instance.addTarget(
      'Static body',
      'label=$label.',
    );
    return 'static:$label';
  }

  String regexAlpha() {
    DemoEventLog.instance.addTarget('Regex alpha body', 'Original alpha body.');
    return 'regex-alpha';
  }

  String regexBeta() {
    DemoEventLog.instance.addTarget('Regex beta body', 'Original beta body.');
    return 'regex-beta';
  }
}

String advancedLibraryRecipe(String input) {
  DemoEventLog.instance.addTarget(
    'Library body',
    'input=$input.',
  );
  return 'library:$input';
}

class AdvancedRunner {
  List<String> runAll() {
    DemoEventLog.instance.addUser(
      'Run advanced recipes',
      'Executing instance, static, constructor, library, and regex pointcuts.',
    );
    final AdvancedTarget target = AdvancedTarget('showcase');
    return <String>[
      target.instanceRecipe(3, mode: 'verbose'),
      AdvancedTarget.staticRecipe('matrix'),
      advancedLibraryRecipe('catalog'),
      target.regexAlpha(),
      target.regexBeta(),
    ];
  }
}
