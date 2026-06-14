import 'dart:async';

import 'package:example/shared/demo_event_log.dart';

class ApiResponse {
  const ApiResponse({
    required this.method,
    required this.path,
    required this.statusCode,
    required this.body,
  });

  final String method;
  final String path;
  final int statusCode;
  final String body;

  String get summary => '$method $path -> $statusCode';
}

class DemoApiClient {
  Future<ApiResponse> fetchOrder(String orderId) async {
    DemoEventLog.instance.addTarget(
      'HTTP target',
      'fetchOrder($orderId) runs with no tracing code in the method body.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 8));
    return ApiResponse(
      method: 'GET',
      path: '/orders/$orderId',
      statusCode: 200,
      body: 'order:$orderId:ready',
    );
  }

  Future<ApiResponse> submitPayment(String orderId, int cents) async {
    DemoEventLog.instance.addTarget(
      'HTTP target',
      'submitPayment($orderId, $cents) returns a business response only.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 12));
    final int statusCode = cents > 5000 ? 402 : 201;
    return ApiResponse(
      method: 'POST',
      path: '/orders/$orderId/payments',
      statusCode: statusCode,
      body: statusCode == 201 ? 'payment:accepted' : 'payment:requires_review',
    );
  }

  Future<ApiResponse> searchProducts(String query) async {
    DemoEventLog.instance.addTarget(
      'HTTP target',
      'searchProducts("$query") knows nothing about trace ids or timers.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return ApiResponse(
      method: 'GET',
      path: '/search?q=$query',
      statusCode: 200,
      body: 'results:$query:3',
    );
  }
}
