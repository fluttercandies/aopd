// Class-level @Inject aspect: injects a statement into InjectClassTarget.compute
// that touches the target's `value` field (exercises field remapping).

import 'package:aopd/aopd.dart';

const String _vmEntryPoint = 'vm:entry-point';

@Aspect()
@pragma(_vmEntryPoint)
class InjectClassAspect {
  @pragma(_vmEntryPoint)
  InjectClassAspect();

  // This field exists so `value = value + 100;` below compiles in this library.
  // On inject, the reference is remapped to InjectClassTarget.value (same name).
  @pragma(_vmEntryPoint)
  int value = 0;

  @Inject(
    'package:example/demos/basic/inject_class_target.dart',
    'InjectClassTarget',
    '-compute',
    lineNum: 6,
  )
  @pragma(_vmEntryPoint)
  void injectCompute(PointCut pointCut) {
    value = value + 100;
  }

  // Targets ONLY inject_dedup_a.dart. inject_dedup_b.dart has a class with the
  // same name (DedupTarget) and method (compute) but must stay un-woven —
  // exercises the dedup / cross-library-scan behavior (M3.2).
  @Inject(
    'package:example/demos/basic/inject_dedup_a.dart',
    'DedupTarget',
    '-compute',
    lineNum: 6,
  )
  @pragma(_vmEntryPoint)
  void injectDedupA(PointCut pointCut) {
    value = value + 100;
  }
}
