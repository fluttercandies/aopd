// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/exception_guard/exception_guard_runtime.dart';

const String _vmEntryPoint = 'vm:entry-point';
const String _targets =
    'package:example/demos/exception_guard/exception_guard_targets.dart';

/// Demonstrates AOP on the ERROR path. Each advice wraps proceed() in
/// try/catch: if the original method throws, the guard records the failure
/// with context and returns a safe fallback, so a throw that would crash the
/// caller is degraded into a usable value -- "degrade but loud" applied to
/// business code. No target here has its own try/catch.
@Aspect()
@pragma(_vmEntryPoint)
class ExceptionGuardAspect {
  @pragma(_vmEntryPoint)
  const ExceptionGuardAspect();

  @Execute(_targets, 'ParsingService', '-parseAmount')
  @pragma(_vmEntryPoint)
  dynamic ParsingService_parseAmount(PointCut pointCut) {
    try {
      return pointCut.proceed();
    } catch (error) {
      const int fallback = 0;
      ExceptionGuardRuntime.instance
          .recordCaught('parseAmount', error, fallback);
      return fallback;
    }
  }

  @Execute(_targets, 'MathService', '-safeRatio')
  @pragma(_vmEntryPoint)
  dynamic MathService_safeRatio(PointCut pointCut) {
    try {
      return pointCut.proceed();
    } catch (error) {
      const int fallback = -1;
      ExceptionGuardRuntime.instance.recordCaught('safeRatio', error, fallback);
      return fallback;
    }
  }

  @Execute(_targets, 'FeedService', '-latestHeadlines')
  @pragma(_vmEntryPoint)
  dynamic FeedService_latestHeadlines(PointCut pointCut) {
    try {
      return pointCut.proceed();
    } catch (error) {
      final List<String> fallback = <String>['(headlines unavailable)'];
      ExceptionGuardRuntime.instance
          .recordCaught('latestHeadlines', error, fallback);
      return fallback;
    }
  }
}
