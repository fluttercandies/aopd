import 'package:flutter/foundation.dart';

/// One recorded method timing.
class TimingRecord {
  const TimingRecord({
    required this.label,
    required this.micros,
    required this.slow,
  });

  final String label;
  final int micros;
  final bool slow;
}

/// State for the around-advice demo: collected timings (from the timing aspect)
/// and the price cache + hit/miss log (from the cache aspect). The aspects are
/// the only writers; the page listens and renders.
class AroundAdviceRuntime {
  AroundAdviceRuntime._();

  static final AroundAdviceRuntime instance = AroundAdviceRuntime._();

  /// Calls slower than this are flagged. Kept generous so the demo's light
  /// workload still trips it on bigger inputs but not on small ones.
  static const int slowThresholdMicros = 8000;

  final ValueNotifier<List<TimingRecord>> timings =
      ValueNotifier<List<TimingRecord>>(<TimingRecord>[]);

  /// The price cache the cache-aspect consults. Public so the aspect can read
  /// and populate it; the page renders its size.
  final Map<String, int> priceCache = <String, int>{};

  /// Human-readable trace of cache hits/misses and computed values.
  final ValueNotifier<List<String>> cacheLog =
      ValueNotifier<List<String>>(<String>[]);

  void recordTiming(String label, int micros) {
    timings.value = <TimingRecord>[
      TimingRecord(label: label, micros: micros, slow: micros >= slowThresholdMicros),
      ...timings.value,
    ].take(20).toList(growable: false);
  }

  void logCacheHit(String sku, int value) {
    _appendCache('HIT   quote("$sku") -> $value  (original method SKIPPED)');
  }

  void logCacheMiss(String sku) {
    _appendCache('MISS  quote("$sku")  (will run the real body)');
  }

  void logComputed(String sku) {
    _appendCache('RAN   real quote("$sku") executed');
  }

  void _appendCache(String line) {
    cacheLog.value = <String>[line, ...cacheLog.value].take(20).toList(growable: false);
  }

  void reset() {
    timings.value = <TimingRecord>[];
    priceCache.clear();
    cacheLog.value = <String>[];
  }
}
