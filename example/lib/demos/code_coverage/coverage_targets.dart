// The instrumented catalog for the code-coverage demo.
//
// Every public unit declared here is woven by `CoverageAspect` (see
// aop/aspects/coverage_aspect.dart), and `coverage_manifest.dart` lists them as
// the coverage denominator. These classes are example-local and are invoked
// ONLY from the coverage page, so the coverage numbers reflect deliberate user
// actions instead of incidental framework traffic.
//
// Advice is woven over each unit, records a hit when the body runs, and
// coverage is the hit set divided by the known unit list.

/// A tiny stand-in for a feature with a constructor + a couple of methods.
class CartService {
  CartService();

  final List<int> _itemCents = <int>[];

  int addItem(int priceCents) {
    _itemCents.add(priceCents);
    return _itemCents.length;
  }

  int total() => _itemCents.fold(0, (int sum, int cents) => sum + cents);
}

/// A second feature, exercised by a different button.
class CheckoutService {
  String applyCoupon(String code) =>
      code.toUpperCase() == 'AOPD' ? 'applied' : 'rejected';

  String pay(int amountCents) => 'charged:$amountCents';
}

/// A flow whose two steps are exercised independently, so the demo can show
/// partial coverage of a single class.
class OnboardingFlow {
  String start() => 'onboarding:start';

  String finish() => 'onboarding:finish';
}

/// A unit the demo page NEVER invokes. It stays uncovered no matter what the
/// user presses, illustrating how never-executed code can surface as a cleanup
/// candidate.
class LegacyExporter {
  String exportCsv() => 'legacy:csv';
}

/// A top-level (library) function, woven via a library pointcut.
String formatPrice(int cents) {
  final String dollars = (cents ~/ 100).toString();
  final String remainder = (cents % 100).toString().padLeft(2, '0');
  return '\$$dollars.$remainder';
}
