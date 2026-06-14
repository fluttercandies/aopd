import 'package:aopd/aopd.dart';
import 'package:example/shared/demo_event_log.dart';

const String _vmEntryPoint = 'vm:entry-point';

@Aspect()
@pragma(_vmEntryPoint)
class BasicAnnotationsAspect {
  @pragma(_vmEntryPoint)
  const BasicAnnotationsAspect();

  @Execute(
    'package:example/demos/basic/basic_targets.dart',
    'BasicTarget',
    '-runExecuteDemo',
  )
  @pragma(_vmEntryPoint)
  int runExecuteDemo(PointCut pointCut) {
    DemoEventLog.instance.addAspect(
      'Execute before',
      'The original method body is wrapped by @Execute.',
    );
    final int result = pointCut.proceed() as int;
    DemoEventLog.instance.addAspect(
      'Execute proceed result',
      'Original method returned $result.',
    );
    return result + 100;
  }

  @Call(
    'package:example/demos/basic/basic_targets.dart',
    'BasicTarget',
    '-createGreeting',
  )
  @pragma(_vmEntryPoint)
  String createGreeting(PointCut pointCut) {
    DemoEventLog.instance.addAspect(
      'Call intercepted',
      'Callsite arguments: ${pointCut.positionalParams}.',
    );
    final String original = pointCut.proceed() as String;
    return '$original | decorated by @Call';
  }

  @FieldGet(
    'package:example/demos/basic/basic_targets.dart',
    'BasicFieldStore',
    'releaseChannel',
    true,
  )
  @pragma(_vmEntryPoint)
  static String releaseChannel(PointCut pointCut) {
    DemoEventLog.instance.addAspect(
      'FieldGet override',
      'Static field reads can be replaced at callsites.',
    );
    return 'aopd-overridden-channel';
  }

  @Inject(
    'package:example/demos/basic/inject_target.dart',
    '',
    '+runInjectTarget',
    lineNum: 8,
  )
  @pragma(_vmEntryPoint)
  static void injectMarker(PointCut pointCut) {
    DemoEventLog.instance.addAspect(
      'Inject marker reached',
      'This statement was inserted into the target function.',
    );
  }

  @Add(
    'package:example/demos/basic/basic_targets.dart',
    'AddedMethodTarget',
  )
  @pragma(_vmEntryPoint)
  String generatedBadge(PointCut pointCut) {
    DemoEventLog.instance.addAspect(
      'Add method invoked',
      'AOPD added generatedBadge() to AddedMethodTarget.',
    );
    return 'generated-basic-badge';
  }
}
