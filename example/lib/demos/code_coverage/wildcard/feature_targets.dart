// Targets for the WILDCARD coverage demo.
//
// None of these classes are annotated, registered, or referenced by any
// pointcut individually. A SINGLE wildcard pointcut in
// aop/aspects/wildcard_coverage_aspect.dart instruments every instance method
// of every class in this folder at once, in contrast to the per-class demo next
// door which trades that breadth for a precise denominator.
//
// IMPORTANT: the collector (WildcardCoverageRuntime) deliberately lives OUTSIDE
// this folder. The wildcard regex matches `package:example/demos/code_coverage/
// wildcard/.*`, so if the collector were here it would be woven too and its
// recordHit would call itself forever. Keeping instrumentation infrastructure
// out of the matched path is the real-world fix for that recursion trap.

class SearchFeature {
  List<String> query(String term) => <String>['result for "$term"'];

  void clearHistory() {}
}

class CartFeature {
  final List<String> _skus = <String>[];

  int addToCart(String sku) {
    _skus.add(sku);
    return _skus.length;
  }

  double subtotal() => _skus.length * 12.5;
}

class ProfileFeature {
  String displayName() => 'AOPD user';

  void signOut() {}
}
