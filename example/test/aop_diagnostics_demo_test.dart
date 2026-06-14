// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Runnable DEMO for AOPD's compile-time semantic diagnostics. This is not a
// behavioral test — it deliberately declares an aspect with conflicts so that
// building it surfaces the `[AOPD]` diagnostics in the log:
//
//   * #13 — two AOP annotations on one method -> ERROR, the member is skipped:
//       [AOPD] ERROR : multiple AOP annotations on
//       DiagnosticsDemoAspect.multiAnno are not supported; skipping this
//       member. Put each aspect in its own method.
//
//   * #27 — two aspects targeting the same exact join point -> WARNING with a
//       deterministic last-wins winner:
//       [AOPD] WARNING mode=call ... 2 @call aspects target the same
//       DupTarget.dup (...dupA::<off>, ...dupB::<off>) — last-wins: only
//       ...dupB takes effect.
//
// Run it and read the build output (the lines print BEFORE the test result):
//   cd example && flutter clean && flutter test test/aop_diagnostics_demo_test.dart
//
// Every target below is intentionally FAKE (no such library/class exists), so
// nothing is woven and no real code is affected — only the diagnostics fire.

import 'package:aopd/aopd.dart';
import 'package:flutter_test/flutter_test.dart';

const String _vmEntryPoint = 'vm:entry-point';

@Aspect()
@pragma(_vmEntryPoint)
class DiagnosticsDemoAspect {
  @pragma(_vmEntryPoint)
  const DiagnosticsDemoAspect();

  // #13: stacking two AOP annotations on one method is forbidden -> the
  // compiler emits an ERROR and skips this member entirely.
  @Call('package:example/__demo_fake.dart', 'FakeTarget', '-fakeMethod')
  @Execute('package:example/__demo_fake.dart', 'FakeTarget', '-fakeMethod')
  @pragma(_vmEntryPoint)
  dynamic multiAnno(PointCut pointCut) => pointCut.proceed();

  // #27: two aspects matching the SAME exact (non-regex) target -> the compiler
  // emits a conflict WARNING and resolves deterministically (last-wins). dupB
  // wins because it sorts after dupA by source offset.
  @Call('package:example/__demo_dup.dart', 'DupTarget', '-dup')
  @pragma(_vmEntryPoint)
  dynamic dupA(PointCut pointCut) => pointCut.proceed();

  @Call('package:example/__demo_dup.dart', 'DupTarget', '-dup')
  @pragma(_vmEntryPoint)
  dynamic dupB(PointCut pointCut) => pointCut.proceed();
}

void main() {
  test('AOPD prints #13/#27 diagnostics at build time (see [AOPD] log above)',
      () {
    // There is nothing to assert at runtime: the demo IS the compile-time
    // [AOPD] log. Fake targets match nothing, so the app is unaffected.
    expect(const DiagnosticsDemoAspect(), isNotNull);
  });
}
