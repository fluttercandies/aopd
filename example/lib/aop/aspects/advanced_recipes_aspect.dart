// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/shared/demo_event_log.dart';

const String _vmEntryPoint = 'vm:entry-point';

@Aspect()
@pragma(_vmEntryPoint)
class AdvancedRecipesAspect {
  @pragma(_vmEntryPoint)
  const AdvancedRecipesAspect();

  @Call(
    'package:example/demos/advanced/advanced_targets.dart',
    'AdvancedTarget',
    '-instanceRecipe',
  )
  @pragma(_vmEntryPoint)
  String AdvancedTarget_instanceRecipe(PointCut pointCut) {
    _logPointCut('Call instance pointcut', pointCut);
    final String original = pointCut.proceed() as String;
    return '$original | instance call observed';
  }

  @Call(
    'package:example/demos/advanced/advanced_targets.dart',
    'AdvancedTarget',
    '+staticRecipe',
  )
  @pragma(_vmEntryPoint)
  static String AdvancedTarget_staticRecipe(PointCut pointCut) {
    _logPointCut('Call static pointcut', pointCut);
    final String original = pointCut.proceed() as String;
    return '$original | static call observed';
  }

  @Call(
    'package:example/demos/advanced/advanced_targets.dart',
    'AdvancedTarget',
    '+AdvancedTarget',
  )
  @pragma(_vmEntryPoint)
  static dynamic AdvancedTarget_constructor(PointCut pointCut) {
    _logPointCut('Call constructor pointcut', pointCut);
    return pointCut.proceed();
  }

  @Call(
    'package:example/demos/advanced/advanced_targets.dart',
    '',
    '+advancedLibraryRecipe',
  )
  @pragma(_vmEntryPoint)
  static String advancedLibraryRecipe(PointCut pointCut) {
    _logPointCut('Call library pointcut', pointCut);
    final String original = pointCut.proceed() as String;
    return '$original | library call observed';
  }

  @Execute(
    'package:example/demos/advanced/advanced_targets.dart',
    'AdvancedTarget',
    '-regex.*',
    isRegex: true,
  )
  @pragma(_vmEntryPoint)
  String regexRecipes(PointCut pointCut) {
    _logPointCut('Regex execute pointcut', pointCut);
    final String original = pointCut.proceed() as String;
    return '$original | regex execute observed';
  }

  static void _logPointCut(String title, PointCut pointCut) {
    DemoEventLog.instance.addAspect(
      title,
      <String>[
        'function=${pointCut.function}',
        'target=${pointCut.target.runtimeType}',
        'positional=${pointCut.positionalParams}',
        'named=${pointCut.namedParams}',
        'members=${pointCut.members?.keys.take(4).join(', ')}',
        'annotations=${pointCut.annotations?.keys.join(', ')}',
        'source=${pointCut.sourceInfos}',
      ].join('\n'),
    );
  }
}
