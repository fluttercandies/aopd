// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/around_advice/around_advice_runtime.dart';

const String _vmEntryPoint = 'vm:entry-point';
const String _targets =
    'package:example/demos/around_advice/around_advice_targets.dart';

/// Demonstrates true AROUND advice -- the part that makes AOP more than
/// logging. Two behaviors no plain hook can do:
///
///   1. ReportService.generate: time the original call (Stopwatch around
///      proceed()) and flag it when it exceeds a threshold. This is the
///      "call duration of key methods" use case the AspectD docs lead with.
///
///   2. PricingService.quote: a CACHE that may NOT call proceed() at all. On a
///      cache hit the advice returns the cached value and the original body
///      never runs. Every other demo in this app proceeds; this one proves
///      advice can short-circuit / replace the target -- the basis for caching,
///      auth gates, debounce, and A/B routing.
@Aspect()
@pragma(_vmEntryPoint)
class AroundAdviceAspect {
  @pragma(_vmEntryPoint)
  const AroundAdviceAspect();

  @Execute(_targets, 'ReportService', '-generate')
  @pragma(_vmEntryPoint)
  dynamic ReportService_generate(PointCut pointCut) {
    final Stopwatch sw = Stopwatch()..start();
    final Object? result = pointCut.proceed();
    sw.stop();
    final List<dynamic>? params = pointCut.positionalParams;
    final Object? rows = params != null && params.isNotEmpty ? params[0] : '?';
    AroundAdviceRuntime.instance
        .recordTiming('generate(rows: $rows)', sw.elapsedMicroseconds);
    return result;
  }

  @Execute(_targets, 'PricingService', '-quote')
  @pragma(_vmEntryPoint)
  dynamic PricingService_quote(PointCut pointCut) {
    final List<dynamic>? params = pointCut.positionalParams;
    final String sku =
        params != null && params.isNotEmpty ? params[0] as String : '';

    final AroundAdviceRuntime runtime = AroundAdviceRuntime.instance;
    final int? cached = runtime.priceCache[sku];
    if (cached != null) {
      // Short-circuit: return WITHOUT proceed(). The real quote() never runs.
      runtime.logCacheHit(sku, cached);
      return cached;
    }

    runtime.logCacheMiss(sku);
    final Object? computed = pointCut.proceed();
    if (computed is int) {
      runtime.priceCache[sku] = computed;
    }
    return computed;
  }
}
