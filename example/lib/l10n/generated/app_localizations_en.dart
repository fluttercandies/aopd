// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AOPD Example';

  @override
  String get routeNotFound => 'Route not found';

  @override
  String get commonRun => 'Run';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonTarget => 'Target';

  @override
  String get commonAspect => 'Aspect';

  @override
  String get resultLogTitle => 'Result log';

  @override
  String get resultLogEmpty =>
      'Run a demo to see target and aspect events here.';

  @override
  String get homeSubtitle =>
      'A focused Flutter showcase for AOPD annotations and compiler-time weaving.';

  @override
  String get homeHeroPill => 'Compiler extension showcase';

  @override
  String get homeHeroTitle =>
      'See AOPD weaving happen through visible app behavior.';

  @override
  String get homeHeroBody =>
      'Each demo has a target, an aspect, a run button, and a live result log. That makes the example easy to extend without hiding the AOP mechanics.';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'EN';

  @override
  String get languageChinese => '中文';

  @override
  String get languageTooltip => 'Language';

  @override
  String get basicPageSubtitle =>
      'Choose one annotation at a time. Each detail page keeps the demo and result log together.';

  @override
  String get basicExecuteDescription =>
      'Wraps the target method body and can change its return value.';

  @override
  String get basicExecuteDetail =>
      'The aspect runs around the original method body and then calls proceed.';

  @override
  String get basicCallDescription =>
      'Rewrites a callsite so the aspect can inspect arguments before proceed.';

  @override
  String get basicCallDetail =>
      'The target method stays unchanged; the callsite is redirected through the aspect.';

  @override
  String get basicFieldGetDescription =>
      'Intercepts reads of a field and replaces the observed value.';

  @override
  String get basicFieldGetDetail =>
      'The field remains original, but reads from matching callsites see the aspect value.';

  @override
  String get basicInjectDescription =>
      'Inserts statements at a stable line inside a target function.';

  @override
  String get basicInjectDetail =>
      'The injected statement appears at the marker line inside the target function.';

  @override
  String get basicInjectClassTitle => '@Inject (class field)';

  @override
  String get basicInjectClassDescription =>
      'Injects a statement into a class method; the injected code references the target class field, which is remapped on inject.';

  @override
  String get basicInjectClassDetail =>
      'InjectClassTarget.compute() gets value = value + 100 injected before its return; the value reference is remapped to the target field.';

  @override
  String get basicInjectScopeTitle => '@Inject (library-scoped)';

  @override
  String get basicInjectScopeDescription =>
      'Two libraries declare the same class and method; @Inject targets only one and respects importUri.';

  @override
  String get basicInjectScopeDetail =>
      'inject_dedup_a and inject_dedup_b both declare DedupTarget.compute; only inject_dedup_a is targeted, so only it is woven.';

  @override
  String get basicAddDescription =>
      'Adds a new method to a target class and calls it through dynamic dispatch.';

  @override
  String get basicAddDetail =>
      'The method does not exist in source code; AOPD adds it during compilation.';

  @override
  String get basicExecuteResult => 'Execute result';

  @override
  String get basicCallResult => 'Call result';

  @override
  String get basicFieldGetResult => 'FieldGet result';

  @override
  String get basicInjectResult => 'Inject result';

  @override
  String get basicInjectClassResult => 'Inject (class field) result';

  @override
  String get basicInjectScopeResult => 'Inject (library-scoped) result';

  @override
  String get basicAddResult => 'Add result';

  @override
  String get advancedMatrixTitle => 'PointCut matrix';

  @override
  String get advancedMatrixDescription =>
      'Runs every pointcut flavor and logs source, target, members, annotations, and arguments.';

  @override
  String get advancedMatrixResult => 'Advanced result';

  @override
  String get argSendDirtyInput => 'Send dirty input';

  @override
  String get argSendDirtyInputBody =>
      'Each button calls a method with raw input. The advice rewrites the arguments before the method body sees them.';

  @override
  String get argLogPii => 'Log line with PII';

  @override
  String get argRegisterMessy => 'Register messy input';

  @override
  String get argNoRewrites => 'No rewrites yet.';

  @override
  String get argBefore => 'before';

  @override
  String get argAfter => 'after';

  @override
  String get argReceivedTitle => 'What the method actually received';

  @override
  String get argReceivedBody =>
      'Proof the inputs were changed, not just logged: the body reports the post-rewrite value.';

  @override
  String get argNothingReceived => 'Nothing received yet.';

  @override
  String get coverageExerciseUnits => 'Exercise units';

  @override
  String get coverageExerciseUnitsBody =>
      'Each button runs real catalog code. The woven advice records the hit before proceeding; behavior is unchanged.';

  @override
  String get coverageUseCart => 'Use cart';

  @override
  String get coverageRunCheckout => 'Run checkout';

  @override
  String get coverageOnboardingStart => 'Onboarding start';

  @override
  String get coverageOnboardingFinish => 'Onboarding finish';

  @override
  String get coverageFormatPrice => 'Format price';

  @override
  String get coverageRunAll => 'Run all reachable';

  @override
  String get coverageExportJson => 'Export JSON';

  @override
  String get coverageUploadPayload => 'Upload payload';

  @override
  String get coverageClose => 'Close';

  @override
  String get coverageCatalogUnits => 'Catalog units';

  @override
  String get coverageNeverInvoked => 'never invoked - dead-code candidate';

  @override
  String get coverageCovered => 'covered';

  @override
  String get coverageUnitsHit => 'units hit';

  @override
  String get aroundTimingTitle => 'Timing + slow-call alert';

  @override
  String aroundTimingSubtitle(int thresholdMs) {
    return 'A Stopwatch wraps proceed(). Bigger input crosses the $thresholdMs ms threshold and is flagged - no timing code in ReportService itself.';
  }

  @override
  String get aroundFastReport => 'Fast report (1)';

  @override
  String get aroundHeavyReport => 'Heavy report (12)';

  @override
  String get aroundTimingEmpty => 'Run a report to see its measured duration.';

  @override
  String get aroundSlowBadge => 'SLOW';

  @override
  String get aroundCacheTitle => 'Cache by short-circuit';

  @override
  String get aroundCacheSubtitle =>
      'On a cache hit the advice returns without proceed(), so the real quote() never runs. The counter is the proof: it only moves when the original body executes.';

  @override
  String get aroundQuoteSkuA => 'Quote SKU-A';

  @override
  String get aroundQuoteSkuB => 'Quote SKU-B';

  @override
  String get aroundCacheEmpty =>
      'Quote a SKU twice: first MISS runs the body, second HIT skips it.';

  @override
  String get aroundRealComputations => 'Real computations';

  @override
  String get guardTriggerTitle => 'Trigger a failure';

  @override
  String get guardTriggerBody =>
      'Each button calls a method that throws. Without the guard the tap handler would throw; with it you get a fallback value below.';

  @override
  String get guardParseThrows => 'Parse \"12x\" -> throws';

  @override
  String get guardDivideThrows => 'Divide by 0 -> throws';

  @override
  String get guardFeedThrows => 'Flaky feed -> throws once';

  @override
  String get guardParseOk => 'Parse \"42\" -> ok';

  @override
  String guardReturnedValue(String value) {
    return 'Value returned to the UI: $value';
  }

  @override
  String get guardCaughtTitle => 'Caught & recovered';

  @override
  String get guardCaughtEmpty =>
      'No failures yet. Trigger one - it will be caught here, not thrown to the UI.';

  @override
  String get guardThrew => 'threw';

  @override
  String get guardFallback => 'fallback';

  @override
  String get jsonModelPanelTitle => 'The model (no toJson logic)';

  @override
  String get jsonOutputTitle => 'sampleUser.toJson() - produced by AOP';

  @override
  String jsonWovenStatus(int count) {
    return 'Woven: $count fields serialized from the stub.';
  }

  @override
  String get jsonUnwovenStatus =>
      'Un-woven: toJson() returned an empty map (run a full build).';

  @override
  String get jsonNote =>
      'Deserialization (writing fields) is the complementary direction; AOPD\'s members capture is read-oriented, so fromJson would use a factory or a write-capable transformer. The read side - the part that usually needs mirrors or codegen - is fully automatic here.';

  @override
  String get patchEnableTitle => 'Enable framework patch';

  @override
  String patchActiveSubtitle(String factor) {
    return 'Active: scaled size capped at ${factor}x font size.';
  }

  @override
  String get patchOffSubtitle =>
      'Off: advice proceeds untouched - pure Flutter behavior.';

  @override
  String patchSystemScale(String scale) {
    return 'System text scale: ${scale}x';
  }

  @override
  String patchCap(String scale) {
    return 'Patch cap: ${scale}x (max accessible enlargement before layouts break)';
  }

  @override
  String get patchPreviewTitle => 'Live preview';

  @override
  String get patchPreviewBody =>
      'The same Text rendered through the woven scaler. Crank the system scale up: without the patch it overflows; with it on, it stops at the cap.';

  @override
  String get patchPreviewText => 'Checkout';

  @override
  String get patchNoClamps => 'No clamps yet.';

  @override
  String patchClampsApplied(int count) {
    return 'Clamps applied (from the woven SDK method): $count';
  }

  @override
  String patchScaleReturned(double size) {
    return 'scale($size) returned';
  }

  @override
  String get patchPatched => 'patched';

  @override
  String get patchPureFlutter => 'pure Flutter';

  @override
  String get analyticsBriefTitle =>
      'Full tracking without business-code logging';

  @override
  String get analyticsBriefBody =>
      'The aspect hooks HitTestTarget.handleEvent and GestureRecognizer.invokeCallback. Tap any card, button, or dialog action to generate a unified analytics event with AOPD widget creation locations.';

  @override
  String get analyticsClearLog => 'Clear log';

  @override
  String get analyticsProductNotesSubtitle =>
      'A compact notebook for compiler experiments';

  @override
  String get analyticsProductMugSubtitle =>
      'Warm drinks for long dill-dump sessions';

  @override
  String get analyticsConfirmPurchase => 'Confirm purchase';

  @override
  String get analyticsDialogBody =>
      'This dialog also has no analytics code. Tap actions and watch the log.';

  @override
  String get analyticsCancel => 'Cancel';

  @override
  String get analyticsConfirmOrder => 'Confirm order';

  @override
  String get analyticsBuyNow => 'Buy now';

  @override
  String get analyticsApplyCoupon => 'Apply coupon';

  @override
  String get analyticsContactSupport => 'Contact support';

  @override
  String get wildcardDemoTitle => 'One pointcut, three classes';

  @override
  String get wildcardDemoDescription =>
      'Each button runs real code in a different class. None of them is annotated; a single @Execute regex covers them all.';

  @override
  String get wildcardWhyTitle => 'Why no percentage here?';

  @override
  String get wildcardWhyBody =>
      'A wildcard pointcut can weave classes never declared up front, and Flutter has no runtime reflection to enumerate them. So this demo discovers units as they run. In production the denominator comes from a build-time class list; coverage is computed offline from uploaded hits and that list.';

  @override
  String get wildcardCollectorNote =>
      'The collector lives outside the matched folder on purpose; otherwise the advice would weave itself and recurse.';

  @override
  String wildcardDiscoveredUnits(int count) {
    return 'Discovered units ($count)';
  }

  @override
  String get wildcardEmpty =>
      'Nothing yet. Run the demo to see units appear as their woven advice records them.';

  @override
  String get sectionCoreTitle => 'Core annotations';

  @override
  String get sectionCoreSubtitle => 'Small loops for each weaving primitive.';

  @override
  String get sectionObservabilityTitle => 'Observability';

  @override
  String get sectionObservabilitySubtitle =>
      'Analytics, tracing, performance, and coverage.';

  @override
  String get sectionBehaviorTitle => 'Runtime behavior';

  @override
  String get sectionBehaviorSubtitle =>
      'Guards, flags, caching, and input control.';

  @override
  String get sectionCompilerTitle => 'Compiler recipes';

  @override
  String get sectionCompilerSubtitle => 'Patch and generation-style examples.';

  @override
  String get sectionOtherTitle => 'Other demos';

  @override
  String get sectionOtherSubtitle => 'Additional AOPD examples.';

  @override
  String get routeAdvancedRecipesTitle => 'Advanced recipes';

  @override
  String get routeAdvancedRecipesDescription =>
      'Instance, static, constructor, library, regex pointcuts, and PointCut data.';

  @override
  String get routeArgumentRewriteTitle => 'Argument rewrite';

  @override
  String get routeArgumentRewriteDescription =>
      'Advice rewrites a method\'s inputs before it runs - PII redaction and input sanitizing.';

  @override
  String get routeAroundAdviceTitle => 'Around advice';

  @override
  String get routeAroundAdviceDescription =>
      'Time a method, flag slow calls, and cache another by skipping the original body.';

  @override
  String get routeAutoAnalyticsTitle => 'Auto analytics';

  @override
  String get routeAutoAnalyticsDescription =>
      'A practical full-tracking demo inspired by real click analytics instrumentation.';

  @override
  String get routeBasicAnnotationsTitle => 'Basic annotations';

  @override
  String get routeBasicAnnotationsDescription =>
      'Aspect, Execute, Call, FieldGet, Inject, and Add in small loops.';

  @override
  String get routeCodeCoverageTitle => 'Code coverage';

  @override
  String get routeCodeCoverageDescription =>
      'Method-level coverage via woven hit-recording advice.';

  @override
  String get routeExceptionGuardTitle => 'Exception guard';

  @override
  String get routeExceptionGuardDescription =>
      'Woven try/catch turns a throwing method into a safe fallback so the app never crashes.';

  @override
  String get routeFeatureFlagsTitle => 'Feature flags';

  @override
  String get routeFeatureFlagsDescription =>
      'Route gray-release behavior through advice while business methods stay stable.';

  @override
  String get routeFrameworkPatchTitle => 'Framework patch';

  @override
  String get routeFrameworkPatchDescription =>
      'Patch a private Flutter SDK method to clamp font scaling without an SDK fork.';

  @override
  String get routeJsonModelTitle => 'JSON model';

  @override
  String get routeJsonModelDescription =>
      'Auto-serialize models with AOP instead of dart:mirrors; toJson has no field code.';

  @override
  String get routeNetworkTracingTitle => 'Network tracing';

  @override
  String get routeNetworkTracingDescription =>
      'Trace API calls with ids, latency, and status without request-code logging.';

  @override
  String get routePerformanceBuildTitle => 'Build tracking';

  @override
  String get routePerformanceBuildDescription =>
      'Measure slow widget rebuilds produced by performRebuild.';

  @override
  String get routePerformanceFrameTitle => 'Frame phases';

  @override
  String get routePerformanceFrameDescription =>
      'Measure frame timing and build/layout/paint phase costs.';

  @override
  String get routePerformanceImageTitle => 'Image loading';

  @override
  String get routePerformanceImageDescription =>
      'Measure image cache miss and decode behavior.';

  @override
  String get routePerformanceMonitoringTitle => 'Performance monitoring';

  @override
  String get routePerformanceMonitoringDescription =>
      'A practical AOP demo for widget rebuilds, frame phases, and image loading.';

  @override
  String get routeWildcardCoverageTitle => 'Wildcard coverage';

  @override
  String get routeWildcardCoverageDescription =>
      'One regex pointcut instruments a whole package subtree with no per-class annotation.';

  @override
  String get networkTitle => 'Network tracing';

  @override
  String get networkSubtitle =>
      'A practical observability pattern: API methods return business data, while woven advice adds trace id, latency, status, and result logs.';

  @override
  String get networkRunApiCalls => 'Run API calls';

  @override
  String get networkRunApiCallsBody =>
      'Each button calls a plain service method. The trace appears because @Execute wraps the method, not because the target logs it.';

  @override
  String get networkFetchOrder => 'Fetch order';

  @override
  String get networkSubmitPayment => 'Submit payment';

  @override
  String get networkPaymentReview => 'Payment review';

  @override
  String get networkSearch => 'Search';

  @override
  String get networkTraceRecords => 'Trace records';

  @override
  String get networkTraceEmpty =>
      'No traces yet. Run an API call to see woven metadata.';

  @override
  String get featureTitle => 'Feature flags';

  @override
  String get featureSubtitle =>
      'AOP is often used for gray releases: keep stable business methods in place, then layer experiments, routing, or short-circuits in advice.';

  @override
  String get featureToggleExperiments => 'Toggle experiments';

  @override
  String get featureToggleExperimentsBody =>
      'The target service contains only legacy rules. Advice reads the flags and decides whether to proceed, decorate, or short-circuit.';

  @override
  String get featureCheckoutV2Title => 'checkout_v2 discount';

  @override
  String get featureCheckoutV2Subtitle => 'Decorates proceed() result';

  @override
  String get featureGatewayV2Title => 'gateway_v2 routing';

  @override
  String get featureGatewayV2Subtitle => 'Can return without proceed()';

  @override
  String get featureVipDiscount => 'VIP discount';

  @override
  String get featureLargeCart => 'Large cart';

  @override
  String get featureEuGateway => 'EU gateway';

  @override
  String get featureUsGateway => 'US gateway';

  @override
  String get featureFlagDecisions => 'Flag decisions';

  @override
  String get featureFlagEmpty =>
      'No decisions yet. Toggle a flag and run a service method.';

  @override
  String get featureFlagOn => 'ON';

  @override
  String get featureFlagOff => 'OFF';
}
