// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Minimal zero-dependency test harness for AOPD compiler tests.
//
// We intentionally do NOT depend on package:test here, to avoid re-resolving
// the compiler workspace (which uses local pkg/* path overrides). Each test is
// a plain `dart run` script that imports this harness.
//
// Run a single test:
//   dart --packages=compiler/.dart_tool/package_config.json \
//        compiler/test/<name>_test.dart
//
// Run all tests:
//   dart --packages=compiler/.dart_tool/package_config.json \
//        compiler/test/run_all.dart

import 'dart:io';

int _failures = 0;
int _checks = 0;

/// Asserts [condition] holds, printing a pass/fail line tagged with [desc].
void check(bool condition, String desc) {
  _checks++;
  if (condition) {
    stdout.writeln('  ok    $desc');
  } else {
    _failures++;
    stdout.writeln('  FAIL  $desc');
  }
}

/// Asserts [haystack] contains [needle].
void expectContains(String haystack, String needle, String desc) {
  check(haystack.contains(needle), '$desc — contains "$needle"');
}

/// Asserts [haystack] does NOT contain [needle].
void expectNotContains(String haystack, String needle, String desc) {
  check(!haystack.contains(needle), '$desc — does not contain "$needle"');
}

/// Runs [body] under a named group header.
void group(String name, void Function() body) {
  stdout.writeln('== $name ==');
  body();
}

/// Prints the summary and sets the process exit code (non-zero on failure).
/// Call once at the end of a test file's `main`.
void finish() {
  stdout.writeln('---');
  if (_failures > 0) {
    stdout.writeln('FAILED: $_failures/$_checks check(s) failed');
    exitCode = 1;
  } else {
    stdout.writeln('PASSED: all $_checks check(s)');
  }
}
