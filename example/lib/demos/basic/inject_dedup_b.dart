// Same class name as inject_dedup_a.dart, but a DIFFERENT library. No @Inject
// targets this library, so DedupTarget.compute() here must stay original (1).
class DedupTarget {
  int value = 1;
  int compute() {
    // No injection should land here; this is the cross-library control.
    return value;
  }
}
