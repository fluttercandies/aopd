import 'package:aopd/aopd.dart';
import 'package:example/demos/basic/inject_target.dart';
import 'package:example/shared/demo_event_log.dart';

class BasicTarget {
  int _counter = 0;

  int runExecuteDemo() {
    _counter += 1;
    DemoEventLog.instance.addTarget(
      'Target execute body',
      'Original body incremented the counter to $_counter.',
    );
    return _counter;
  }

  String createGreeting(String name, {String tone = 'friendly'}) {
    DemoEventLog.instance.addTarget(
      'Target call body',
      'Original greeting created for $name with tone=$tone.',
    );
    return 'Hello $name, tone=$tone';
  }

  String runCallDemo() {
    DemoEventLog.instance.addUser(
      'Run Call demo',
      'Calling createGreeting from a normal callsite.',
    );
    return createGreeting('AOPD', tone: 'curious');
  }

  String runFieldGetDemo() {
    DemoEventLog.instance.addUser(
      'Run FieldGet demo',
      'Reading BasicFieldStore.releaseChannel.',
    );
    return BasicFieldStore.releaseChannel;
  }

  String runInjectDemo() {
    DemoEventLog.instance.addUser(
      'Run Inject demo',
      'Calling a library function with a stable injection marker.',
    );
    return runInjectTarget();
  }

  String runAddDemo() {
    DemoEventLog.instance.addUser(
      'Run Add demo',
      'Calling generatedBadge on AddedMethodTarget through dynamic dispatch.',
    );
    final dynamic target = AddedMethodTarget('basic-target');
    return target.generatedBadge(PointCut.pointCut()) as String;
  }
}

class BasicFieldStore {
  static String releaseChannel = 'original-channel';
}

class AddedMethodTarget {
  const AddedMethodTarget(this.name);

  final String name;
}
