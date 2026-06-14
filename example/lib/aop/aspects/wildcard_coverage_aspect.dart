// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/code_coverage/wildcard_coverage_runtime.dart';

const String _vmEntryPoint = 'vm:entry-point';

/// The whole point of this demo: ONE pointcut instruments every instance method
/// of every class under `lib/demos/code_coverage/wildcard/`. There is no per-class
/// annotation — the regex matches the import URI, the class name, AND the
/// method name, so a single line covers an entire package subtree.
///
/// This is how a real app-wide coverage build is written:
///   * scope the importUri regex to your OWN business packages,
///   * keep the collector and this aspect OUT of that scope (the collector
///     lives at `lib/demos/code_coverage/wildcard_coverage_runtime.dart`, which the
///     `.../wildcard/.*` regex does not match, so recordHit never weaves
///     itself and recurses),
///   * `@pragma('vm:entry-point')` everywhere so AOT tree-shaking keeps it.
@Aspect()
@pragma(_vmEntryPoint)
class WildcardCoverageAspect {
  @pragma(_vmEntryPoint)
  const WildcardCoverageAspect();

  @Execute(
    'package:example/demos/code_coverage/wildcard/.*',
    '.*',
    '-.*',
    isRegex: true,
  )
  @pragma(_vmEntryPoint)
  dynamic everyInstanceMethod(PointCut pointCut) {
    // The class name comes from the live target; the method name from the
    // pointcut. Together they form `Type.method` without any hand-written list.
    WildcardCoverageRuntime.instance
        .recordHit('${pointCut.target.runtimeType}.${pointCut.function}');
    return pointCut.proceed();
  }
}
