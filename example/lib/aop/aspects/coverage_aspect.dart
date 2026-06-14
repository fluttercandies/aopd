// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/code_coverage/coverage_runtime.dart';

const String _vmEntryPoint = 'vm:entry-point';
const String _targets =
    'package:example/demos/code_coverage/coverage_targets.dart';

/// Weaves non-invasive hit-recording advice over every unit in the coverage
/// catalog. Each advice records the unit, then calls `proceed()` unchanged so
/// the demo can measure execution without changing behavior.
///
/// `-.*` (regex) covers every INSTANCE method of a class with a single
/// pointcut; a `@Call` constructor pointcut records construction; a library
/// pointcut covers the top-level function. All advice, the aspect class, and
/// its constructor carry `@pragma('vm:entry-point')` so release/AOT
/// tree-shaking does not drop the instrumentation.
@Aspect()
@pragma(_vmEntryPoint)
class CoverageAspect {
  @pragma(_vmEntryPoint)
  const CoverageAspect();

  // --- CartService: constructor + all instance methods ---

  @Call(_targets, 'CartService', '+CartService')
  @pragma(_vmEntryPoint)
  static dynamic CartService_ctor(PointCut pointCut) {
    CoverageRuntime.instance.recordHit('CartService.<new>');
    return pointCut.proceed();
  }

  @Execute(_targets, 'CartService', '-.*', isRegex: true)
  @pragma(_vmEntryPoint)
  dynamic CartService_methods(PointCut pointCut) {
    CoverageRuntime.instance.recordHit('CartService.${pointCut.function}');
    return pointCut.proceed();
  }

  // --- CheckoutService: all instance methods ---

  @Execute(_targets, 'CheckoutService', '-.*', isRegex: true)
  @pragma(_vmEntryPoint)
  dynamic CheckoutService_methods(PointCut pointCut) {
    CoverageRuntime.instance.recordHit('CheckoutService.${pointCut.function}');
    return pointCut.proceed();
  }

  // --- OnboardingFlow: all instance methods ---

  @Execute(_targets, 'OnboardingFlow', '-.*', isRegex: true)
  @pragma(_vmEntryPoint)
  dynamic OnboardingFlow_methods(PointCut pointCut) {
    CoverageRuntime.instance.recordHit('OnboardingFlow.${pointCut.function}');
    return pointCut.proceed();
  }

  // --- LegacyExporter: woven, but never invoked by the page (dead-code probe) ---

  @Execute(_targets, 'LegacyExporter', '-.*', isRegex: true)
  @pragma(_vmEntryPoint)
  dynamic LegacyExporter_methods(PointCut pointCut) {
    CoverageRuntime.instance.recordHit('LegacyExporter.${pointCut.function}');
    return pointCut.proceed();
  }

  // --- top-level library function ---

  @Execute(_targets, '', '+formatPrice')
  @pragma(_vmEntryPoint)
  static dynamic formatPrice_fn(PointCut pointCut) {
    CoverageRuntime.instance.recordHit('formatPrice');
    return pointCut.proceed();
  }
}
