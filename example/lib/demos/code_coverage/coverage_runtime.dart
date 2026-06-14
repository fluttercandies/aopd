import 'package:example/demos/code_coverage/coverage_manifest.dart';
import 'package:flutter/foundation.dart';

/// Accumulates coverage hits at runtime.
///
/// `CoverageAspect` calls [recordHit] from advice woven over every catalog
/// unit. The page listens to [hits] and renders a live coverage percentage.
/// In production, the same set could be compressed and uploaded on app exit
/// (the demo's [exportJson] prints the equivalent payload instead of sending
/// it).
class CoverageRuntime {
  CoverageRuntime._();

  static final CoverageRuntime instance = CoverageRuntime._();

  /// Ids (matching `CoverageUnit.id`) seen at least once this session.
  final ValueNotifier<Set<String>> hits = ValueNotifier<Set<String>>(
    <String>{},
  );

  /// Records that [unitId] executed. Cheap and idempotent; the woven advice
  /// does only this, then proceeds, so behavior is unchanged.
  void recordHit(String unitId) {
    if (hits.value.contains(unitId)) {
      return;
    }
    hits.value = <String>{...hits.value, unitId};
  }

  /// Number of manifest units that have been hit (hits outside the manifest are
  /// ignored, exactly as production diffs runtime hits against the build list).
  int get coveredCount => kCoverageManifest
      .where((CoverageUnit u) => hits.value.contains(u.id))
      .length;

  int get totalCount => kCoverageManifest.length;

  double get coverageRatio => totalCount == 0 ? 0 : coveredCount / totalCount;

  bool isCovered(String unitId) => hits.value.contains(unitId);

  void reset() {
    hits.value = <String>{};
  }

  /// The payload a production collector would upload. Kept deterministic (sorted
  /// ids, no timestamps) so it is easy to read and test.
  Map<String, Object> exportJson() {
    final List<String> covered = <String>[
      for (final CoverageUnit u in kCoverageManifest)
        if (hits.value.contains(u.id)) u.id,
    ];
    final List<String> uncovered = <String>[
      for (final CoverageUnit u in kCoverageManifest)
        if (!hits.value.contains(u.id)) u.id,
    ];
    return <String, Object>{
      'total': totalCount,
      'covered': covered,
      'uncovered': uncovered,
    };
  }
}
