import 'package:flutter/foundation.dart';

/// One guarded failure: what threw, where, and what fallback was returned.
class GuardedError {
  const GuardedError({
    required this.method,
    required this.error,
    required this.fallback,
  });

  final String method;
  final String error;
  final String fallback;
}

/// State for the exception-guard demo. The aspect records each caught throw
/// here; the page renders the log and the still-alive fallback values.
class ExceptionGuardRuntime {
  ExceptionGuardRuntime._();

  static final ExceptionGuardRuntime instance = ExceptionGuardRuntime._();

  final ValueNotifier<List<GuardedError>> caught =
      ValueNotifier<List<GuardedError>>(<GuardedError>[]);

  /// The last value the UI received — always a usable value, never a thrown
  /// exception, because the guard substitutes a fallback.
  final ValueNotifier<String> lastValue = ValueNotifier<String>('—');

  void recordCaught(String method, Object error, Object? fallback) {
    caught.value = <GuardedError>[
      GuardedError(
        method: method,
        error: '${error.runtimeType}: $error',
        fallback: '$fallback',
      ),
      ...caught.value,
    ].take(20).toList(growable: false);
  }

  void publishValue(String value) {
    lastValue.value = value;
  }

  void reset() {
    caught.value = <GuardedError>[];
    lastValue.value = '—';
  }
}

/// Tiny side-channel so a target can note its attempt without depending on the
/// guard runtime's richer types.
class AmountTrace {
  AmountTrace._();

  static final AmountTrace instance = AmountTrace._();

  String lastRaw = '';

  void markAttempt(String raw) => lastRaw = raw;
}
