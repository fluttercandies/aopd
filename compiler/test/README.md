# AOPD compiler tests

Zero-dependency test harness (no `package:test`, to avoid re-resolving the
compiler workspace that uses local `pkg/*` path overrides). Each test is a
plain `dart run` script that imports `_harness.dart`.

## Running

Single test:

```shell
dart --packages=compiler/.dart_tool/package_config.json compiler/test/aop_diagnostic_reporter_test.dart
```

All tests:

```shell
dart --packages=compiler/.dart_tool/package_config.json compiler/test/run_all.dart
```

The process exits non-zero on failure.

## Two layers

- **L1 / unit**: pure functions and small components (e.g. `AopDiagnosticReporter`,
  helpers) that need no kernel. Run directly with `dart run`; sub-second. The
  `*_test.dart` files here are this layer.
- **L2 / kernel**: construct `Component`/`Library` directly, run a rewriter, and
  assert on the AST (e.g. `execute_transform_test.dart`, `call_transform_test.dart`,
  `field_get_transform_test.dart`).

## End-to-end (loop B) and crash-safety (loop C)

The real verification of the transform's main path and crash-safety goes through
the end-to-end loops documented in `doc/README.md`:

1. Compile the example from source:
   `dart --packages=compiler/.dart_tool/package_config.json bin/debug_server.dart example`
2. `dart bin/dump.dart` -> `example/out.dill.txt`
3. `dart bin/validate_example_dill.dart` (asserts weave markers are present)
4. `cd example && flutter test test/aop_runtime_test.dart` (runtime behavior)

Crash-safety negative cases (bad regex / missing target / missing lineNum /
constructor `@Execute` / malformed annotation / missing SDK helper): inject a
broken aspect and assert **build succeeds + a diagnostic is emitted + other
aspects still weave + the app does not crash**.
