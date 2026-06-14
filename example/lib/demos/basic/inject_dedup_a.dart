// Same class name as inject_dedup_b.dart, but a DIFFERENT library. Only the
// @Inject that targets THIS library's importUri should be woven here.
class DedupTarget {
  int value = 1;
  int compute() {
    // AOPD inject marker (line 6): `value = value + 100;` is injected here.
    return value;
  }
}
