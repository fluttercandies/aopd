// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Runtime unit test for PointCut.proceed() (M5.4 slice 1).
//
// proceed() is the seam the compiler weaves through. This asserts the new
// decentralized path: when `proceedClosure` is set, proceed() invokes it and
// returns its result; when it is null, proceed() falls back to returning null
// (the compiler injects legacy stubKey branches before that fallback, so the
// null return is only reached by genuinely un-woven pointcuts).
//
// Run: flutter test test/pointcut_test.dart

import 'package:aopd/src/annotations/pointcut.dart';
import 'package:flutter_test/flutter_test.dart';

PointCut _makePointCut({
  Object? Function(PointCut pointCut)? proceedClosure,
  List<dynamic>? positionalParams,
  Map<dynamic, dynamic>? namedParams,
}) {
  return PointCut(
    null,
    null,
    null,
    'aop_stub_0',
    positionalParams,
    namedParams,
    null,
    null,
    proceedClosure: proceedClosure,
  );
}

void main() {
  test('proceed() returns null when no closure and no injected branches', () {
    expect(_makePointCut().proceed(), isNull);
  });

  test('proceed() invokes proceedClosure and returns its result', () {
    final PointCut pc = _makePointCut(proceedClosure: (PointCut _) => 42);
    expect(pc.proceed(), 42);
  });

  test('proceedClosure receives the PointCut so it can read params', () {
    final PointCut pc = _makePointCut(
      positionalParams: <dynamic>[7, 8],
      proceedClosure: (PointCut self) =>
          (self.positionalParams![0] as int) +
          (self.positionalParams![1] as int),
    );
    expect(pc.proceed(), 15);
  });

  test('advice mutating positionalParams is observed by the closure', () {
    final PointCut pc = _makePointCut(
      positionalParams: <dynamic>[1],
      proceedClosure: (PointCut self) => self.positionalParams![0] as int,
    );
    // Advice mutates the shared list before calling proceed().
    pc.positionalParams![0] = 99;
    expect(
      pc.proceed(),
      99,
      reason:
          'closure reads live params, preserving the modify-then-proceed '
          'semantics of the legacy stub mechanism',
    );
  });

  test('PointCut.pointCut() factory still builds a null pointcut', () {
    expect(PointCut.pointCut().proceed(), isNull);
  });
}
