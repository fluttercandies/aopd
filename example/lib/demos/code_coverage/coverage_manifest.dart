// The coverage denominator: every unit the aspect can weave, declared once.
//
// A production coverage system would derive this list at BUILD time from
// the compiled package's class list, because Flutter forbids `dart:mirrors` and
// the app cannot enumerate its own members at runtime. This demo declares the
// catalog explicitly so it is self-contained and deterministic; a build-time
// generator that emits this file is a natural follow-up (see
// doc/optimization-backlog.md).
//
// Each `id` here must match exactly what `CoverageAspect` records at runtime.

/// One trackable unit of code.
class CoverageUnit {
  const CoverageUnit({
    required this.id,
    required this.label,
    required this.group,
    this.isDeadCodeProbe = false,
  });

  /// Stable identifier recorded by the woven advice (e.g. `CartService.total`).
  final String id;

  /// Human-readable label for the UI.
  final String label;

  /// The owning feature, used to group rows in the UI.
  final String group;

  /// True for a unit the demo intentionally never invokes, to show how an
  /// always-uncovered unit surfaces as a dead-code candidate.
  final bool isDeadCodeProbe;
}

/// The full catalog. Order is display order.
const List<CoverageUnit> kCoverageManifest = <CoverageUnit>[
  CoverageUnit(
    id: 'CartService.<new>',
    label: 'CartService() constructor',
    group: 'CartService',
  ),
  CoverageUnit(
    id: 'CartService.addItem',
    label: 'CartService.addItem',
    group: 'CartService',
  ),
  CoverageUnit(
    id: 'CartService.total',
    label: 'CartService.total',
    group: 'CartService',
  ),
  CoverageUnit(
    id: 'CheckoutService.applyCoupon',
    label: 'CheckoutService.applyCoupon',
    group: 'CheckoutService',
  ),
  CoverageUnit(
    id: 'CheckoutService.pay',
    label: 'CheckoutService.pay',
    group: 'CheckoutService',
  ),
  CoverageUnit(
    id: 'OnboardingFlow.start',
    label: 'OnboardingFlow.start',
    group: 'OnboardingFlow',
  ),
  CoverageUnit(
    id: 'OnboardingFlow.finish',
    label: 'OnboardingFlow.finish',
    group: 'OnboardingFlow',
  ),
  CoverageUnit(
    id: 'formatPrice',
    label: 'formatPrice (library function)',
    group: 'library',
  ),
  CoverageUnit(
    id: 'LegacyExporter.exportCsv',
    label: 'LegacyExporter.exportCsv',
    group: 'LegacyExporter',
    isDeadCodeProbe: true,
  ),
];
