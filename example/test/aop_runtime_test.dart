// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// Runtime verification of AOPD weaving. Unlike widget_test.dart (UI rendering)
// and the compiler-side checks (build succeeds / kernel valid / markers
// present), this asserts the woven app actually BEHAVES correctly at runtime
// and does not crash — the ultimate test of the crash-safety goal.
//
// Run via the AOPD-patched Flutter tool (example has aopd.enabled: true):
//   cd example && flutter clean && flutter test test/aop_runtime_test.dart
//
// IMPORTANT: run on a clean/full build. AOPD only guarantees weaving on a full
// compile; an incremental recompile that newly pulls in a target library may
// leave its call sites un-woven (documented mode-1 limitation, aop-internals
// §6), which would make these assertions fail spuriously. `flutter clean`
// forces the full compile these assertions assume.
//
// If a result equals its un-woven value (e.g. runExecuteDemo == 1), weaving did
// not happen in this run.

import 'package:example/demos/advanced/advanced_targets.dart';
import 'package:example/demos/arg_rewrite/arg_rewrite_targets.dart';
import 'package:example/demos/around_advice/around_advice_runtime.dart';
import 'package:example/demos/around_advice/around_advice_targets.dart';
import 'package:example/demos/basic/basic_targets.dart';
import 'package:example/demos/basic/inject_class_target.dart';
import 'package:example/demos/basic/inject_dedup_a.dart' as dedup_a;
import 'package:example/demos/basic/inject_dedup_b.dart' as dedup_b;
import 'package:example/demos/code_coverage/coverage_runtime.dart';
import 'package:example/demos/code_coverage/coverage_targets.dart';
import 'package:example/demos/code_coverage/wildcard/feature_targets.dart';
import 'package:example/demos/code_coverage/wildcard_coverage_runtime.dart';
import 'package:example/demos/exception_guard/exception_guard_runtime.dart';
import 'package:example/demos/exception_guard/exception_guard_targets.dart';
import 'package:example/demos/feature_flag/feature_flag_runtime.dart';
import 'package:example/demos/feature_flag/feature_flag_targets.dart';
import 'package:example/demos/framework_patch/framework_patch_runtime.dart';
import 'package:example/demos/json_model/json_models.dart';
import 'package:example/demos/network_tracing/network_tracing_runtime.dart';
import 'package:example/demos/network_tracing/network_tracing_targets.dart';
import 'package:example/shared/demo_event_log.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

// Ensure all aspects are reachable so the compiler weaves them.
// ignore: unused_import
import 'package:example/aop/aspects/aspects.dart';

void main() {
  setUp(() => DemoEventLog.instance.clear());

  test('@Execute wraps the body; proceed() runs the original (+100)', () {
    // Original returns the counter (1 on a fresh instance); advice returns
    // proceed() + 100. Un-woven this would be 1.
    expect(BasicTarget().runExecuteDemo(), 101);
  });

  test('@Call rewrites the callsite inside runCallDemo', () {
    final String result = BasicTarget().runCallDemo();
    expect(
      result,
      contains('Hello AOPD, tone=curious'),
      reason: 'proceed() returns the original greeting',
    );
    expect(
      result,
      contains('decorated by @Call'),
      reason: 'advice decorates the result',
    );
  });

  test('@FieldGet overrides the static field read', () {
    // Un-woven this would be the field literal "original-channel".
    expect(BasicTarget().runFieldGetDemo(), 'aopd-overridden-channel');
  });

  test('@Add injects a method (un-woven would NoSuchMethod-crash)', () {
    expect(BasicTarget().runAddDemo(), 'generated-basic-badge');
  });

  test('@Inject inserts a statement into the target function', () {
    DemoEventLog.instance.clear();
    final String result = BasicTarget().runInjectDemo();
    expect(
      result,
      'inject-target-result',
      reason: 'inject adds a statement but does not change the return value',
    );
    final List<String> titles = DemoEventLog.instance.events.value
        .map((DemoEvent e) => e.title)
        .toList();
    expect(
      titles,
      contains('Inject marker reached'),
      reason: 'the injected statement ran',
    );
  });

  test('@Inject into a CLASS method remaps a field reference', () {
    // Injected `value = value + 100;` is remapped to InjectClassTarget.value,
    // so compute() returns 1 + 100 = 101 (un-injected it returns 1).
    expect(InjectClassTarget().compute(), 101);
  });

  test('@Inject targets only the annotated library (same class name elsewhere '
      'is untouched)', () {
    // inject_dedup_a and inject_dedup_b both declare `DedupTarget.compute`.
    // The aspect targets only inject_dedup_a.
    expect(
      dedup_a.DedupTarget().compute(),
      101,
      reason: 'targeted library is injected',
    );
    expect(
      dedup_b.DedupTarget().compute(),
      1,
      reason: 'same-named class in another library must stay un-woven',
    );
  });

  test('advanced: instance/static/library @Call + regex @Execute decorate', () {
    final List<String> results = AdvancedRunner().runAll();
    expect(
      results[0],
      'instance:3:verbose | instance call observed',
      reason: 'instance @Call rewrote the callsite',
    );
    expect(
      results[1],
      'static:matrix | static call observed',
      reason: 'static @Call rewrote the callsite',
    );
    expect(
      results[2],
      'library:catalog | library call observed',
      reason: 'library-function @Call rewrote the callsite',
    );
    expect(
      results[3],
      'regex-alpha | regex execute observed',
      reason: 'regex @Execute wrapped regexAlpha',
    );
    expect(
      results[4],
      'regex-beta | regex execute observed',
      reason: 'regex @Execute wrapped regexBeta',
    );

    // Constructor @Call is transparent in the return value (the advice just
    // proceeds), so assert it fired via the event log it writes. This guards
    // the capability at the model level (widget_test only shows a capped log).
    final List<String> titles = DemoEventLog.instance.events.value
        .map((DemoEvent e) => e.title)
        .toList();
    expect(
      titles,
      contains('Call constructor pointcut'),
      reason: 'constructor @Call advice fired when AdvancedTarget was built',
    );
  });

  test('woven app runs all demos in sequence without crashing', () {
    final BasicTarget target = BasicTarget();
    expect(() {
      target.runExecuteDemo();
      target.runCallDemo();
      target.runFieldGetDemo();
      target.runAddDemo();
      target.runInjectDemo();
      AdvancedRunner().runAll();
    }, returnsNormally);
  });

  // Code-coverage demo: CoverageAspect weaves hit-recording advice over the
  // catalog. These assert the weave actually happened (un-woven, the hit set
  // stays empty) and that the advice is transparent.
  group('coverage demo (CoverageAspect)', () {
    setUp(CoverageRuntime.instance.reset);

    test('regex @Execute records every instance method that runs', () {
      final CartService cart = CartService();
      cart.addItem(500);
      cart.total();
      final Set<String> hits = CoverageRuntime.instance.hits.value;
      expect(
        hits,
        contains('CartService.addItem'),
        reason: 'regex -.* wove addItem; un-woven this set would be empty',
      );
      expect(hits, contains('CartService.total'));
    });

    test('@Call records the constructor', () {
      CartService();
      expect(
        CoverageRuntime.instance.hits.value,
        contains('CartService.<new>'),
      );
    });

    test('library pointcut records the top-level function', () {
      formatPrice(1299);
      expect(CoverageRuntime.instance.hits.value, contains('formatPrice'));
    });

    test('advice is transparent — return values are unchanged', () {
      expect(CheckoutService().applyCoupon('AOPD'), 'applied');
      expect(CheckoutService().pay(1200), 'charged:1200');
      expect(formatPrice(1299), r'$12.99');
    });

    test(
      'coverage ratio reflects hits; an un-invoked unit stays uncovered',
      () {
        final CartService cart = CartService();
        cart.addItem(500);
        cart.total();
        CheckoutService().applyCoupon('AOPD');
        CheckoutService().pay(1200);
        OnboardingFlow().start();
        OnboardingFlow().finish();
        formatPrice(1299);

        final CoverageRuntime runtime = CoverageRuntime.instance;
        // Everything except the never-invoked LegacyExporter (dead-code probe).
        expect(runtime.coveredCount, runtime.totalCount - 1);
        expect(runtime.isCovered('LegacyExporter.exportCsv'), isFalse);

        // Invoking it flips coverage to 100% and confirms that unit wove too.
        LegacyExporter().exportCsv();
        expect(runtime.isCovered('LegacyExporter.exportCsv'), isTrue);
        expect(runtime.coveredCount, runtime.totalCount);
      },
    );
  });

  // Wildcard demo: a SINGLE regex pointcut weaves every instance method of
  // every class under lib/demos/code_coverage/wildcard/. These assert that one
  // pointcut covered THREE different classes with no per-class annotation.
  group('wildcard coverage (one pointcut, many classes)', () {
    setUp(WildcardCoverageRuntime.instance.reset);

    test('one pointcut records methods across multiple classes', () {
      SearchFeature().query('aopd');
      final CartFeature cart = CartFeature();
      cart.addToCart('sku-1');
      cart.subtotal();
      ProfileFeature().displayName();

      final Set<String> hits = WildcardCoverageRuntime.instance.hits.value;
      expect(
        hits,
        containsAll(<String>[
          'SearchFeature.query',
          'CartFeature.addToCart',
          'CartFeature.subtotal',
          'ProfileFeature.displayName',
        ]),
        reason:
            'a single regex pointcut wove all three classes; un-woven '
            'this set would be empty',
      );
    });

    test('advice is transparent — return values are unchanged', () {
      expect(SearchFeature().query('x'), <String>['result for "x"']);
      expect(CartFeature().addToCart('s'), 1);
    });
  });

  // Around advice: the timing aspect measures the target; the cache aspect can
  // return WITHOUT proceed(), so the original body is skipped on a hit.
  group('around advice (measure + short-circuit)', () {
    setUp(() {
      AroundAdviceRuntime.instance.reset();
      PricingService.instance.resetComputations();
    });

    test('timing advice records a measured duration around proceed()', () {
      final int result = ReportService().generate(1);
      // proceed() still returns the real checksum (advice is around, not
      // replacing here); un-woven, no timing would be recorded.
      expect(result, isA<int>());
      expect(AroundAdviceRuntime.instance.timings.value, isNotEmpty);
      expect(
        AroundAdviceRuntime.instance.timings.value.first.label,
        contains('generate'),
      );
    });

    test('cache advice SKIPS the original body on a hit (no proceed)', () {
      // First call: miss -> real body runs once.
      final int first = PricingService.instance.quote('SKU-A');
      expect(
        PricingService.instance.realComputations,
        1,
        reason: 'first call missed the cache and ran the real body',
      );

      // Second + third same-arg calls: hit -> advice returns without proceed(),
      // so the real body does NOT run again. This is the short-circuit proof.
      final int second = PricingService.instance.quote('SKU-A');
      final int third = PricingService.instance.quote('SKU-A');
      expect(
        PricingService.instance.realComputations,
        1,
        reason: 'cache hits must not run the original method again',
      );
      expect(
        second,
        first,
        reason: 'cached value is identical to the computed one',
      );
      expect(third, first);

      // A different SKU misses and runs the body once more.
      PricingService.instance.quote('SKU-B');
      expect(PricingService.instance.realComputations, 2);
    });
  });

  // Exception guard: woven try/catch on the error path. The target throws; the
  // advice catches it, records context, and returns a fallback so nothing
  // escapes to the caller.
  group('exception guard (woven try/catch)', () {
    setUp(ExceptionGuardRuntime.instance.reset);

    test(
      'a throwing method is caught and returns the fallback, not a throw',
      () {
        // Un-woven, int.parse('12x') throws FormatException out of this call.
        late int result;
        expect(
          () => result = ParsingService().parseAmount('12x'),
          returnsNormally,
          reason: 'the guard must swallow the throw',
        );
        expect(result, 0, reason: 'fallback value is returned');
        expect(ExceptionGuardRuntime.instance.caught.value, isNotEmpty);
        expect(
          ExceptionGuardRuntime.instance.caught.value.first.method,
          'parseAmount',
        );
      },
    );

    test('divide-by-zero is guarded to the fallback', () {
      late int result;
      expect(() => result = MathService().safeRatio(10, 0), returnsNormally);
      expect(result, -1);
    });

    test('valid input passes through unguarded (advice is transparent)', () {
      expect(ParsingService().parseAmount('42'), 42);
      // No error recorded for the success path.
      expect(ExceptionGuardRuntime.instance.caught.value, isEmpty);
    });

    test('flaky method: first call throws (guarded), retry succeeds', () {
      final FeedService feed = FeedService();
      final List<String> first = feed.latestHeadlines(); // throws -> fallback
      expect(first, <String>['(headlines unavailable)']);
      expect(ExceptionGuardRuntime.instance.caught.value, isNotEmpty);

      final List<String> second = feed.latestHeadlines(); // succeeds
      expect(second, isNot(<String>['(headlines unavailable)']));
      expect(second.length, 3);
    });
  });

  group('network tracing (woven API observability)', () {
    setUp(NetworkTracingRuntime.instance.reset);

    test('async API call records trace id, status, and duration', () async {
      final ApiResponse response = await DemoApiClient().fetchOrder('T-42');
      expect(response.summary, 'GET /orders/T-42 -> 200');

      final List<NetworkTraceRecord> traces =
          NetworkTracingRuntime.instance.traces.value;
      expect(
        traces,
        hasLength(1),
        reason: 'un-woven API calls would not create trace records',
      );
      expect(traces.first.traceId, startsWith('trace-'));
      expect(traces.first.statusCode, 200);
      expect(traces.first.operation, 'GET /orders/:id');
      expect(traces.first.elapsedMicros, greaterThan(0));
    });

    test('non-2xx response is still traced', () async {
      final ApiResponse response = await DemoApiClient().submitPayment(
        'T-42',
        8800,
      );
      expect(response.statusCode, 402);
      expect(NetworkTracingRuntime.instance.traces.value.first.failed, isTrue);
    });
  });

  group('feature flags (woven gray-release decisions)', () {
    setUp(() {
      FeatureFlagRuntime.instance.reset();
      DemoEventLog.instance.clear();
    });

    test('flag OFF proceeds to legacy discount', () {
      final int discount = CheckoutDecisionService().loyaltyDiscountPercent(
        'vip',
        7600,
      );
      expect(discount, 10);
      expect(
        FeatureFlagRuntime.instance.decisions.value.first.enabled,
        isFalse,
      );
    });

    test('checkout_v2 flag decorates proceed() result', () {
      FeatureFlagRuntime.instance.setCheckoutV2(true);
      final int discount = CheckoutDecisionService().loyaltyDiscountPercent(
        'vip',
        7600,
      );
      expect(
        discount,
        15,
        reason: 'advice layers experiment logic over the legacy result',
      );
      expect(
        FeatureFlagRuntime.instance.decisions.value.first.flag,
        'checkout_v2',
      );
    });

    test('gateway_v2 can short-circuit without running the target', () {
      FeatureFlagRuntime.instance.setGatewayV2(true);
      final String gateway = CheckoutDecisionService().paymentGateway('EU');
      expect(gateway, 'aopd-pay-v2');
      expect(
        DemoEventLog.instance.events.value.where(
          (DemoEvent event) => event.title == 'Flag target',
        ),
        isEmpty,
        reason: 'short-circuit advice returned without proceed()',
      );
    });
  });

  // Framework patch: the aspect weaves Flutter's own private
  // _LinearTextScaler.scale. NOTE: package:flutter is precompiled into the
  // flutter_tester platform, so framework weaves do NOT take effect under
  // `flutter test` (the same reason the performance/analytics demos, which also
  // target package:flutter, are only render-tested). The clamp is observable in
  // a real build (`flutter run` / `flutter build`). What we CAN assert here is
  // the transparency contract: with the patch disabled, scaling is exactly
  // stock Flutter — a woven build must not corrupt it.
  group('framework patch (woven SDK method)', () {
    setUp(FrameworkPatchRuntime.instance.reset);

    test('flag OFF: scale() is exactly stock Flutter (transparent)', () {
      expect(TextScaler.linear(2.5).scale(16), 40);
      expect(FrameworkPatchRuntime.instance.clampCount, 0);
    });

    test(
      'flag ON: clamps the framework result',
      () {
        FrameworkPatchRuntime.instance.enabled = true;
        FrameworkPatchRuntime.instance.maxScaleFactor = 1.6;
        // Un-patched 16 * 2.5 = 40; the woven advice caps it at 16 * 1.6 = 25.6.
        final double scaled = TextScaler.linear(2.5).scale(16);
        expect(
          scaled,
          closeTo(25.6, 1e-9),
          reason: 'the woven SDK method returned the clamped value',
        );
        expect(FrameworkPatchRuntime.instance.clampCount, greaterThan(0));
      },
      skip:
          'package:flutter weaving only applies in a real build, not '
          'flutter_tester (framework is precompiled into the test platform).',
    );
  });

  // JSON model: a single @Execute weaves toJson on every model, reading fields
  // from PointCut.members. The models' toJson are stubs returning {} -- so a
  // full nested map proves AOP filled them (the dart:mirrors replacement).
  // These models are app code (not package:flutter), so the weave applies here.
  group('json model (AOP serialization, no mirrors)', () {
    test(
      'stub toJson() is filled from fields, including nested model + list',
      () {
        final Map<String, dynamic> json = sampleUser.toJson();
        // Un-woven the stub returns {}; woven it has every field.
        expect(json, isNotEmpty, reason: 'un-woven toJson would be {}');
        expect(json['name'], 'Ada Lovelace');
        expect(json['age'], 36);
        expect(json['premium'], true);
        expect(json['tags'], <String>['compiler', 'aop', 'kernel']);
        // Nested Address.toJson is woven by the same regex pointcut.
        expect(json['address'], <String, dynamic>{
          'city': 'London',
          'zip': 'NW1',
        });
      },
    );

    test('nested model serializes on its own too', () {
      const Address address = Address(city: 'Paris', zip: '75001');
      expect(address.toJson(), <String, dynamic>{
        'city': 'Paris',
        'zip': '75001',
      });
    });
  });

  // Argument rewrite: advice mutates pointCut.positionalParams BEFORE proceed(),
  // so the original method receives cleaned inputs. The target returns exactly
  // what it received -- the proof the arguments (not just outputs) were changed.
  group('argument rewrite (mutate inputs before proceed)', () {
    test('PII is redacted before the log method sees it', () {
      final String received = AuditLog().record(
        'reach me at 13800001111 or ada@example.com',
      );
      // The body returns what it actually received; un-woven it would be the
      // raw string.
      expect(
        received,
        contains('138****1111'),
        reason: 'phone redacted before proceed',
      );
      expect(
        received,
        contains('***@example.com'),
        reason: 'email redacted before proceed',
      );
      expect(received, isNot(contains('13800001111')));
      expect(received, isNot(contains('ada@example.com')));
    });

    test('signup inputs are normalized and clamped before the body runs', () {
      // Raw: untrimmed mixed-case email, out-of-range age.
      final String result = SignupService().register('  ADA@Example.COM ', 200);
      expect(
        result,
        'registered:ada@example.com:120',
        reason: 'email trimmed+lowercased, age clamped to 120 before proceed',
      );
    });

    test('already-clean input is passed through unchanged', () {
      expect(
        SignupService().register('ok@x.com', 30),
        'registered:ok@x.com:30',
      );
    });
  });
}
