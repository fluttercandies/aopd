import 'package:example/demos/exception_guard/exception_guard_runtime.dart';

// Targets for the exception-guard demo. Every method here THROWS on bad input.
// None has its own try/catch -- the guarding is supplied entirely by the woven
// aspect. This is the first demo to exercise the ERROR path: every other demo
// is happy-path only.
//
// The point: a method that would crash the caller is wrapped by advice that
// catches the throw, records it with context, and returns a safe fallback so
// the app keeps running -- the "degrade but loud" idea applied to business code
// instead of the compiler.

class ParsingService {
  /// Throws FormatException on non-numeric input. The aspect turns a throw into
  /// a safe 0 so a malformed value never takes down the screen.
  int parseAmount(String raw) {
    AmountTrace.instance.markAttempt(raw);
    return int.parse(raw);
  }
}

class MathService {
  /// Throws on divide-by-zero (integer division). Guarded to a fallback.
  int safeRatio(int numerator, int denominator) {
    return numerator ~/ denominator;
  }
}

class FeedService {
  bool _firstCall = true;

  /// Simulates a flaky network read: throws the first time, succeeds after.
  /// The guard lets the UI render a fallback instead of crashing on the first,
  /// transient failure.
  List<String> latestHeadlines() {
    if (_firstCall) {
      _firstCall = false;
      throw StateError('transient feed error');
    }
    return <String>['AOPD ships', 'Around advice lands', 'Guards everywhere'];
  }
}
