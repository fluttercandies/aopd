import 'package:flutter/foundation.dart';

class NetworkTraceRecord {
  const NetworkTraceRecord({
    required this.traceId,
    required this.operation,
    required this.statusCode,
    required this.elapsedMicros,
    required this.outcome,
  });

  final String traceId;
  final String operation;
  final int statusCode;
  final int elapsedMicros;
  final String outcome;

  bool get failed => statusCode >= 400;
}

class NetworkTracingRuntime {
  NetworkTracingRuntime._();

  static final NetworkTracingRuntime instance = NetworkTracingRuntime._();

  final ValueNotifier<List<NetworkTraceRecord>> traces =
      ValueNotifier<List<NetworkTraceRecord>>(<NetworkTraceRecord>[]);

  int _nextId = 1000;

  String nextTraceId() {
    _nextId += 1;
    return 'trace-$_nextId';
  }

  void record(NetworkTraceRecord record) {
    traces.value = <NetworkTraceRecord>[
      record,
      ...traces.value,
    ].take(12).toList(growable: false);
  }

  void reset() {
    _nextId = 1000;
    traces.value = <NetworkTraceRecord>[];
  }
}
