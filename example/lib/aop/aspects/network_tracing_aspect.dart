// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/network_tracing/network_tracing_runtime.dart';
import 'package:example/demos/network_tracing/network_tracing_targets.dart';
import 'package:example/shared/demo_event_log.dart';

const String _vmEntryPoint = 'vm:entry-point';
const String _targets =
    'package:example/demos/network_tracing/network_tracing_targets.dart';

@Aspect()
@pragma(_vmEntryPoint)
class NetworkTracingAspect {
  @pragma(_vmEntryPoint)
  const NetworkTracingAspect();

  @Execute(_targets, 'DemoApiClient', '-fetchOrder')
  @pragma(_vmEntryPoint)
  Future<ApiResponse> DemoApiClient_fetchOrder(PointCut pointCut) {
    return _trace('GET /orders/:id', pointCut);
  }

  @Execute(_targets, 'DemoApiClient', '-submitPayment')
  @pragma(_vmEntryPoint)
  Future<ApiResponse> DemoApiClient_submitPayment(PointCut pointCut) {
    return _trace('POST /orders/:id/payments', pointCut);
  }

  @Execute(_targets, 'DemoApiClient', '-searchProducts')
  @pragma(_vmEntryPoint)
  Future<ApiResponse> DemoApiClient_searchProducts(PointCut pointCut) {
    return _trace('GET /search', pointCut);
  }

  Future<ApiResponse> _trace(String operation, PointCut pointCut) async {
    final NetworkTracingRuntime runtime = NetworkTracingRuntime.instance;
    final String traceId = runtime.nextTraceId();
    final Stopwatch sw = Stopwatch()..start();
    DemoEventLog.instance.addAspect(
      'Network trace start',
      '$traceId $operation',
    );

    try {
      final ApiResponse response =
          await (pointCut.proceed() as Future<ApiResponse>);
      sw.stop();
      runtime.record(
        NetworkTraceRecord(
          traceId: traceId,
          operation: operation,
          statusCode: response.statusCode,
          elapsedMicros: sw.elapsedMicroseconds,
          outcome: response.summary,
        ),
      );
      DemoEventLog.instance.addAspect(
        'Network trace end',
        '$traceId ${response.summary} in ${sw.elapsedMilliseconds} ms',
      );
      return response;
    } catch (error) {
      sw.stop();
      runtime.record(
        NetworkTraceRecord(
          traceId: traceId,
          operation: operation,
          statusCode: 599,
          elapsedMicros: sw.elapsedMicroseconds,
          outcome: '$error',
        ),
      );
      rethrow;
    }
  }
}
