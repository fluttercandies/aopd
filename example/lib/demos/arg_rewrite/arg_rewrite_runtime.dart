import 'package:flutter/foundation.dart';

/// One argument rewrite: the value before and after the advice cleaned it.
class RewriteEvent {
  const RewriteEvent({
    required this.method,
    required this.before,
    required this.after,
  });

  final String method;
  final String before;
  final String after;
}

/// State for the argument-rewriting demo. The aspect records what it rewrote;
/// the targets record what they actually received (post-rewrite). The page
/// shows both, side by side. These run from button taps (not layout), so a
/// ValueNotifier is safe here.
class ArgRewriteRuntime {
  ArgRewriteRuntime._();

  static final ArgRewriteRuntime instance = ArgRewriteRuntime._();

  final ValueNotifier<List<RewriteEvent>> rewrites =
      ValueNotifier<List<RewriteEvent>>(<RewriteEvent>[]);

  /// What each target body actually received, e.g. `AuditLog.record  value`.
  final ValueNotifier<List<String>> received =
      ValueNotifier<List<String>>(<String>[]);

  void noteRewrite(String method, String before, String after) {
    rewrites.value = <RewriteEvent>[
      RewriteEvent(method: method, before: before, after: after),
      ...rewrites.value,
    ].take(20).toList(growable: false);
  }

  void noteReceived(String method, String value) {
    received.value = <String>[
      '$method  ←  $value',
      ...received.value,
    ].take(20).toList(growable: false);
  }

  void reset() {
    rewrites.value = <RewriteEvent>[];
    received.value = <String>[];
  }
}
