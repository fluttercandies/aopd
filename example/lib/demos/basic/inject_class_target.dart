// Class-level @Inject target (exercises field remapping of injected
// statements; the library-level inject_target.dart does not cover this).
class InjectClassTarget {
  int value = 1;
  int compute() {
    // AOPD inject marker (line 6): injected `value = value + 100;` runs here,
    return value;
  }
}
