import 'package:example/demos/around_advice/around_advice_runtime.dart';

// Targets for the "around advice" demo. Two services, neither annotated:
//   * ReportService.generate is wrapped by timing advice (measures duration,
//     flags slow calls) -- the classic @Execute use case the AspectD docs lead
//     with: "call duration of key methods".
//   * PricingService.quote is wrapped by CACHE advice that may NOT proceed()
//     at all on a cache hit. `_realComputations` is the proof: it only
//     increments inside the real body, so if a cached call returns without
//     bumping it, the original method genuinely did not run.

class ReportService {
  /// Simulates real work whose cost scales with [rows]. Pure CPU so the demo
  /// shows a real, measurable duration without any timer/Future.
  int generate(int rows) {
    int checksum = 0;
    for (int i = 0; i < rows * 200000; i++) {
      checksum = (checksum + i) & 0xFFFFFF;
    }
    return checksum;
  }
}

class PricingService {
  PricingService._();

  static final PricingService instance = PricingService._();

  /// Increments ONLY when the real body runs. The cache aspect short-circuits
  /// before proceed() on a hit, so this stays flat across repeated same-arg
  /// calls -- the demo's hard proof that the original method was skipped.
  int _realComputations = 0;

  int get realComputations => _realComputations;

  void resetComputations() => _realComputations = 0;

  /// "Expensive" priced quote for a SKU. Returns a deterministic number so the
  /// cached value is verifiably identical to a freshly computed one.
  int quote(String sku) {
    _realComputations += 1;
    AroundAdviceRuntime.instance.logComputed(sku);
    int hash = 7;
    for (final int code in sku.codeUnits) {
      hash = (hash * 31 + code) & 0xFFFF;
    }
    return hash;
  }
}
