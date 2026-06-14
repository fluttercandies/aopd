import 'package:flutter/foundation.dart';

/// Discover-on-hit collector for the wildcard coverage demo.
///
/// Unlike the per-class demo, there is NO manifest here: one wildcard pointcut
/// can weave classes that were never declared up front, so the app cannot show
/// a percentage -- only "what has run so far". In production the denominator
/// comes from a build-time class list (see doc/optimization-backlog.md);
/// this demo honestly shows units as they are discovered instead of
/// pretending to know the total.
///
/// This file lives OUTSIDE lib/demos/code_coverage/wildcard/ on purpose: the
/// wildcard regex matches `.../coverage/wildcard/.*`, and if the collector were
/// inside that path it would be woven too and [recordHit] would recurse
/// infinitely. Keeping the collector out of the matched path is the fix.
class WildcardCoverageRuntime {
  WildcardCoverageRuntime._();

  static final WildcardCoverageRuntime instance = WildcardCoverageRuntime._();

  /// Ids seen so far, formatted as `Type.method`.
  final ValueNotifier<Set<String>> hits = ValueNotifier<Set<String>>(
    <String>{},
  );

  void recordHit(String unitId) {
    if (hits.value.contains(unitId)) {
      return;
    }
    hits.value = <String>{...hits.value, unitId};
  }

  void reset() {
    hits.value = <String>{};
  }
}
