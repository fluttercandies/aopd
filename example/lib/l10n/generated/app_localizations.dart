import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AOPD Example'**
  String get appTitle;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFound;

  /// No description provided for @commonRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get commonRun;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get commonTarget;

  /// No description provided for @commonAspect.
  ///
  /// In en, this message translates to:
  /// **'Aspect'**
  String get commonAspect;

  /// No description provided for @resultLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Result log'**
  String get resultLogTitle;

  /// No description provided for @resultLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Run a demo to see target and aspect events here.'**
  String get resultLogEmpty;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A focused Flutter showcase for AOPD annotations and compiler-time weaving.'**
  String get homeSubtitle;

  /// No description provided for @homeHeroPill.
  ///
  /// In en, this message translates to:
  /// **'Compiler extension showcase'**
  String get homeHeroPill;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'See AOPD weaving happen through visible app behavior.'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Each demo has a target, an aspect, a run button, and a live result log. That makes the example easy to extend without hiding the AOP mechanics.'**
  String get homeHeroBody;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// No description provided for @basicPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose one annotation at a time. Each detail page keeps the demo and result log together.'**
  String get basicPageSubtitle;

  /// No description provided for @basicExecuteDescription.
  ///
  /// In en, this message translates to:
  /// **'Wraps the target method body and can change its return value.'**
  String get basicExecuteDescription;

  /// No description provided for @basicExecuteDetail.
  ///
  /// In en, this message translates to:
  /// **'The aspect runs around the original method body and then calls proceed.'**
  String get basicExecuteDetail;

  /// No description provided for @basicCallDescription.
  ///
  /// In en, this message translates to:
  /// **'Rewrites a callsite so the aspect can inspect arguments before proceed.'**
  String get basicCallDescription;

  /// No description provided for @basicCallDetail.
  ///
  /// In en, this message translates to:
  /// **'The target method stays unchanged; the callsite is redirected through the aspect.'**
  String get basicCallDetail;

  /// No description provided for @basicFieldGetDescription.
  ///
  /// In en, this message translates to:
  /// **'Intercepts reads of a field and replaces the observed value.'**
  String get basicFieldGetDescription;

  /// No description provided for @basicFieldGetDetail.
  ///
  /// In en, this message translates to:
  /// **'The field remains original, but reads from matching callsites see the aspect value.'**
  String get basicFieldGetDetail;

  /// No description provided for @basicInjectDescription.
  ///
  /// In en, this message translates to:
  /// **'Inserts statements at a stable line inside a target function.'**
  String get basicInjectDescription;

  /// No description provided for @basicInjectDetail.
  ///
  /// In en, this message translates to:
  /// **'The injected statement appears at the marker line inside the target function.'**
  String get basicInjectDetail;

  /// No description provided for @basicInjectClassTitle.
  ///
  /// In en, this message translates to:
  /// **'@Inject (class field)'**
  String get basicInjectClassTitle;

  /// No description provided for @basicInjectClassDescription.
  ///
  /// In en, this message translates to:
  /// **'Injects a statement into a class method; the injected code references the target class field, which is remapped on inject.'**
  String get basicInjectClassDescription;

  /// No description provided for @basicInjectClassDetail.
  ///
  /// In en, this message translates to:
  /// **'InjectClassTarget.compute() gets value = value + 100 injected before its return; the value reference is remapped to the target field.'**
  String get basicInjectClassDetail;

  /// No description provided for @basicInjectScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'@Inject (library-scoped)'**
  String get basicInjectScopeTitle;

  /// No description provided for @basicInjectScopeDescription.
  ///
  /// In en, this message translates to:
  /// **'Two libraries declare the same class and method; @Inject targets only one and respects importUri.'**
  String get basicInjectScopeDescription;

  /// No description provided for @basicInjectScopeDetail.
  ///
  /// In en, this message translates to:
  /// **'inject_dedup_a and inject_dedup_b both declare DedupTarget.compute; only inject_dedup_a is targeted, so only it is woven.'**
  String get basicInjectScopeDetail;

  /// No description provided for @basicAddDescription.
  ///
  /// In en, this message translates to:
  /// **'Adds a new method to a target class and calls it through dynamic dispatch.'**
  String get basicAddDescription;

  /// No description provided for @basicAddDetail.
  ///
  /// In en, this message translates to:
  /// **'The method does not exist in source code; AOPD adds it during compilation.'**
  String get basicAddDetail;

  /// No description provided for @basicExecuteResult.
  ///
  /// In en, this message translates to:
  /// **'Execute result'**
  String get basicExecuteResult;

  /// No description provided for @basicCallResult.
  ///
  /// In en, this message translates to:
  /// **'Call result'**
  String get basicCallResult;

  /// No description provided for @basicFieldGetResult.
  ///
  /// In en, this message translates to:
  /// **'FieldGet result'**
  String get basicFieldGetResult;

  /// No description provided for @basicInjectResult.
  ///
  /// In en, this message translates to:
  /// **'Inject result'**
  String get basicInjectResult;

  /// No description provided for @basicInjectClassResult.
  ///
  /// In en, this message translates to:
  /// **'Inject (class field) result'**
  String get basicInjectClassResult;

  /// No description provided for @basicInjectScopeResult.
  ///
  /// In en, this message translates to:
  /// **'Inject (library-scoped) result'**
  String get basicInjectScopeResult;

  /// No description provided for @basicAddResult.
  ///
  /// In en, this message translates to:
  /// **'Add result'**
  String get basicAddResult;

  /// No description provided for @advancedMatrixTitle.
  ///
  /// In en, this message translates to:
  /// **'PointCut matrix'**
  String get advancedMatrixTitle;

  /// No description provided for @advancedMatrixDescription.
  ///
  /// In en, this message translates to:
  /// **'Runs every pointcut flavor and logs source, target, members, annotations, and arguments.'**
  String get advancedMatrixDescription;

  /// No description provided for @advancedMatrixResult.
  ///
  /// In en, this message translates to:
  /// **'Advanced result'**
  String get advancedMatrixResult;

  /// No description provided for @argSendDirtyInput.
  ///
  /// In en, this message translates to:
  /// **'Send dirty input'**
  String get argSendDirtyInput;

  /// No description provided for @argSendDirtyInputBody.
  ///
  /// In en, this message translates to:
  /// **'Each button calls a method with raw input. The advice rewrites the arguments before the method body sees them.'**
  String get argSendDirtyInputBody;

  /// No description provided for @argLogPii.
  ///
  /// In en, this message translates to:
  /// **'Log line with PII'**
  String get argLogPii;

  /// No description provided for @argRegisterMessy.
  ///
  /// In en, this message translates to:
  /// **'Register messy input'**
  String get argRegisterMessy;

  /// No description provided for @argNoRewrites.
  ///
  /// In en, this message translates to:
  /// **'No rewrites yet.'**
  String get argNoRewrites;

  /// No description provided for @argBefore.
  ///
  /// In en, this message translates to:
  /// **'before'**
  String get argBefore;

  /// No description provided for @argAfter.
  ///
  /// In en, this message translates to:
  /// **'after'**
  String get argAfter;

  /// No description provided for @argReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'What the method actually received'**
  String get argReceivedTitle;

  /// No description provided for @argReceivedBody.
  ///
  /// In en, this message translates to:
  /// **'Proof the inputs were changed, not just logged: the body reports the post-rewrite value.'**
  String get argReceivedBody;

  /// No description provided for @argNothingReceived.
  ///
  /// In en, this message translates to:
  /// **'Nothing received yet.'**
  String get argNothingReceived;

  /// No description provided for @coverageExerciseUnits.
  ///
  /// In en, this message translates to:
  /// **'Exercise units'**
  String get coverageExerciseUnits;

  /// No description provided for @coverageExerciseUnitsBody.
  ///
  /// In en, this message translates to:
  /// **'Each button runs real catalog code. The woven advice records the hit before proceeding; behavior is unchanged.'**
  String get coverageExerciseUnitsBody;

  /// No description provided for @coverageUseCart.
  ///
  /// In en, this message translates to:
  /// **'Use cart'**
  String get coverageUseCart;

  /// No description provided for @coverageRunCheckout.
  ///
  /// In en, this message translates to:
  /// **'Run checkout'**
  String get coverageRunCheckout;

  /// No description provided for @coverageOnboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Onboarding start'**
  String get coverageOnboardingStart;

  /// No description provided for @coverageOnboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Onboarding finish'**
  String get coverageOnboardingFinish;

  /// No description provided for @coverageFormatPrice.
  ///
  /// In en, this message translates to:
  /// **'Format price'**
  String get coverageFormatPrice;

  /// No description provided for @coverageRunAll.
  ///
  /// In en, this message translates to:
  /// **'Run all reachable'**
  String get coverageRunAll;

  /// No description provided for @coverageExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get coverageExportJson;

  /// No description provided for @coverageUploadPayload.
  ///
  /// In en, this message translates to:
  /// **'Upload payload'**
  String get coverageUploadPayload;

  /// No description provided for @coverageClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get coverageClose;

  /// No description provided for @coverageCatalogUnits.
  ///
  /// In en, this message translates to:
  /// **'Catalog units'**
  String get coverageCatalogUnits;

  /// No description provided for @coverageNeverInvoked.
  ///
  /// In en, this message translates to:
  /// **'never invoked - dead-code candidate'**
  String get coverageNeverInvoked;

  /// No description provided for @coverageCovered.
  ///
  /// In en, this message translates to:
  /// **'covered'**
  String get coverageCovered;

  /// No description provided for @coverageUnitsHit.
  ///
  /// In en, this message translates to:
  /// **'units hit'**
  String get coverageUnitsHit;

  /// No description provided for @aroundTimingTitle.
  ///
  /// In en, this message translates to:
  /// **'Timing + slow-call alert'**
  String get aroundTimingTitle;

  /// No description provided for @aroundTimingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A Stopwatch wraps proceed(). Bigger input crosses the {thresholdMs} ms threshold and is flagged - no timing code in ReportService itself.'**
  String aroundTimingSubtitle(int thresholdMs);

  /// No description provided for @aroundFastReport.
  ///
  /// In en, this message translates to:
  /// **'Fast report (1)'**
  String get aroundFastReport;

  /// No description provided for @aroundHeavyReport.
  ///
  /// In en, this message translates to:
  /// **'Heavy report (12)'**
  String get aroundHeavyReport;

  /// No description provided for @aroundTimingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Run a report to see its measured duration.'**
  String get aroundTimingEmpty;

  /// No description provided for @aroundSlowBadge.
  ///
  /// In en, this message translates to:
  /// **'SLOW'**
  String get aroundSlowBadge;

  /// No description provided for @aroundCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Cache by short-circuit'**
  String get aroundCacheTitle;

  /// No description provided for @aroundCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On a cache hit the advice returns without proceed(), so the real quote() never runs. The counter is the proof: it only moves when the original body executes.'**
  String get aroundCacheSubtitle;

  /// No description provided for @aroundQuoteSkuA.
  ///
  /// In en, this message translates to:
  /// **'Quote SKU-A'**
  String get aroundQuoteSkuA;

  /// No description provided for @aroundQuoteSkuB.
  ///
  /// In en, this message translates to:
  /// **'Quote SKU-B'**
  String get aroundQuoteSkuB;

  /// No description provided for @aroundCacheEmpty.
  ///
  /// In en, this message translates to:
  /// **'Quote a SKU twice: first MISS runs the body, second HIT skips it.'**
  String get aroundCacheEmpty;

  /// No description provided for @aroundRealComputations.
  ///
  /// In en, this message translates to:
  /// **'Real computations'**
  String get aroundRealComputations;

  /// No description provided for @guardTriggerTitle.
  ///
  /// In en, this message translates to:
  /// **'Trigger a failure'**
  String get guardTriggerTitle;

  /// No description provided for @guardTriggerBody.
  ///
  /// In en, this message translates to:
  /// **'Each button calls a method that throws. Without the guard the tap handler would throw; with it you get a fallback value below.'**
  String get guardTriggerBody;

  /// No description provided for @guardParseThrows.
  ///
  /// In en, this message translates to:
  /// **'Parse \"12x\" -> throws'**
  String get guardParseThrows;

  /// No description provided for @guardDivideThrows.
  ///
  /// In en, this message translates to:
  /// **'Divide by 0 -> throws'**
  String get guardDivideThrows;

  /// No description provided for @guardFeedThrows.
  ///
  /// In en, this message translates to:
  /// **'Flaky feed -> throws once'**
  String get guardFeedThrows;

  /// No description provided for @guardParseOk.
  ///
  /// In en, this message translates to:
  /// **'Parse \"42\" -> ok'**
  String get guardParseOk;

  /// No description provided for @guardReturnedValue.
  ///
  /// In en, this message translates to:
  /// **'Value returned to the UI: {value}'**
  String guardReturnedValue(String value);

  /// No description provided for @guardCaughtTitle.
  ///
  /// In en, this message translates to:
  /// **'Caught & recovered'**
  String get guardCaughtTitle;

  /// No description provided for @guardCaughtEmpty.
  ///
  /// In en, this message translates to:
  /// **'No failures yet. Trigger one - it will be caught here, not thrown to the UI.'**
  String get guardCaughtEmpty;

  /// No description provided for @guardThrew.
  ///
  /// In en, this message translates to:
  /// **'threw'**
  String get guardThrew;

  /// No description provided for @guardFallback.
  ///
  /// In en, this message translates to:
  /// **'fallback'**
  String get guardFallback;

  /// No description provided for @jsonModelPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'The model (no toJson logic)'**
  String get jsonModelPanelTitle;

  /// No description provided for @jsonOutputTitle.
  ///
  /// In en, this message translates to:
  /// **'sampleUser.toJson() - produced by AOP'**
  String get jsonOutputTitle;

  /// No description provided for @jsonWovenStatus.
  ///
  /// In en, this message translates to:
  /// **'Woven: {count} fields serialized from the stub.'**
  String jsonWovenStatus(int count);

  /// No description provided for @jsonUnwovenStatus.
  ///
  /// In en, this message translates to:
  /// **'Un-woven: toJson() returned an empty map (run a full build).'**
  String get jsonUnwovenStatus;

  /// No description provided for @jsonNote.
  ///
  /// In en, this message translates to:
  /// **'Deserialization (writing fields) is the complementary direction; AOPD\'s members capture is read-oriented, so fromJson would use a factory or a write-capable transformer. The read side - the part that usually needs mirrors or codegen - is fully automatic here.'**
  String get jsonNote;

  /// No description provided for @patchEnableTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable framework patch'**
  String get patchEnableTitle;

  /// No description provided for @patchActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active: scaled size capped at {factor}x font size.'**
  String patchActiveSubtitle(String factor);

  /// No description provided for @patchOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Off: advice proceeds untouched - pure Flutter behavior.'**
  String get patchOffSubtitle;

  /// No description provided for @patchSystemScale.
  ///
  /// In en, this message translates to:
  /// **'System text scale: {scale}x'**
  String patchSystemScale(String scale);

  /// No description provided for @patchCap.
  ///
  /// In en, this message translates to:
  /// **'Patch cap: {scale}x (max accessible enlargement before layouts break)'**
  String patchCap(String scale);

  /// No description provided for @patchPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Live preview'**
  String get patchPreviewTitle;

  /// No description provided for @patchPreviewBody.
  ///
  /// In en, this message translates to:
  /// **'The same Text rendered through the woven scaler. Crank the system scale up: without the patch it overflows; with it on, it stops at the cap.'**
  String get patchPreviewBody;

  /// No description provided for @patchPreviewText.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get patchPreviewText;

  /// No description provided for @patchNoClamps.
  ///
  /// In en, this message translates to:
  /// **'No clamps yet.'**
  String get patchNoClamps;

  /// No description provided for @patchClampsApplied.
  ///
  /// In en, this message translates to:
  /// **'Clamps applied (from the woven SDK method): {count}'**
  String patchClampsApplied(int count);

  /// No description provided for @patchScaleReturned.
  ///
  /// In en, this message translates to:
  /// **'scale({size}) returned'**
  String patchScaleReturned(double size);

  /// No description provided for @patchPatched.
  ///
  /// In en, this message translates to:
  /// **'patched'**
  String get patchPatched;

  /// No description provided for @patchPureFlutter.
  ///
  /// In en, this message translates to:
  /// **'pure Flutter'**
  String get patchPureFlutter;

  /// No description provided for @analyticsBriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Full tracking without business-code logging'**
  String get analyticsBriefTitle;

  /// No description provided for @analyticsBriefBody.
  ///
  /// In en, this message translates to:
  /// **'The aspect hooks HitTestTarget.handleEvent and GestureRecognizer.invokeCallback. Tap any card, button, or dialog action to generate a unified analytics event with AOPD widget creation locations.'**
  String get analyticsBriefBody;

  /// No description provided for @analyticsClearLog.
  ///
  /// In en, this message translates to:
  /// **'Clear log'**
  String get analyticsClearLog;

  /// No description provided for @analyticsProductNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A compact notebook for compiler experiments'**
  String get analyticsProductNotesSubtitle;

  /// No description provided for @analyticsProductMugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Warm drinks for long dill-dump sessions'**
  String get analyticsProductMugSubtitle;

  /// No description provided for @analyticsConfirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'Confirm purchase'**
  String get analyticsConfirmPurchase;

  /// No description provided for @analyticsDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This dialog also has no analytics code. Tap actions and watch the log.'**
  String get analyticsDialogBody;

  /// No description provided for @analyticsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get analyticsCancel;

  /// No description provided for @analyticsConfirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm order'**
  String get analyticsConfirmOrder;

  /// No description provided for @analyticsBuyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get analyticsBuyNow;

  /// No description provided for @analyticsApplyCoupon.
  ///
  /// In en, this message translates to:
  /// **'Apply coupon'**
  String get analyticsApplyCoupon;

  /// No description provided for @analyticsContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get analyticsContactSupport;

  /// No description provided for @wildcardDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'One pointcut, three classes'**
  String get wildcardDemoTitle;

  /// No description provided for @wildcardDemoDescription.
  ///
  /// In en, this message translates to:
  /// **'Each button runs real code in a different class. None of them is annotated; a single @Execute regex covers them all.'**
  String get wildcardDemoDescription;

  /// No description provided for @wildcardWhyTitle.
  ///
  /// In en, this message translates to:
  /// **'Why no percentage here?'**
  String get wildcardWhyTitle;

  /// No description provided for @wildcardWhyBody.
  ///
  /// In en, this message translates to:
  /// **'A wildcard pointcut can weave classes never declared up front, and Flutter has no runtime reflection to enumerate them. So this demo discovers units as they run. In production the denominator comes from a build-time class list; coverage is computed offline from uploaded hits and that list.'**
  String get wildcardWhyBody;

  /// No description provided for @wildcardCollectorNote.
  ///
  /// In en, this message translates to:
  /// **'The collector lives outside the matched folder on purpose; otherwise the advice would weave itself and recurse.'**
  String get wildcardCollectorNote;

  /// No description provided for @wildcardDiscoveredUnits.
  ///
  /// In en, this message translates to:
  /// **'Discovered units ({count})'**
  String wildcardDiscoveredUnits(int count);

  /// No description provided for @wildcardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Run the demo to see units appear as their woven advice records them.'**
  String get wildcardEmpty;

  /// No description provided for @sectionCoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Core annotations'**
  String get sectionCoreTitle;

  /// No description provided for @sectionCoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Small loops for each weaving primitive.'**
  String get sectionCoreSubtitle;

  /// No description provided for @sectionObservabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Observability'**
  String get sectionObservabilityTitle;

  /// No description provided for @sectionObservabilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics, tracing, performance, and coverage.'**
  String get sectionObservabilitySubtitle;

  /// No description provided for @sectionBehaviorTitle.
  ///
  /// In en, this message translates to:
  /// **'Runtime behavior'**
  String get sectionBehaviorTitle;

  /// No description provided for @sectionBehaviorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guards, flags, caching, and input control.'**
  String get sectionBehaviorSubtitle;

  /// No description provided for @sectionCompilerTitle.
  ///
  /// In en, this message translates to:
  /// **'Compiler recipes'**
  String get sectionCompilerTitle;

  /// No description provided for @sectionCompilerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Patch and generation-style examples.'**
  String get sectionCompilerSubtitle;

  /// No description provided for @sectionOtherTitle.
  ///
  /// In en, this message translates to:
  /// **'Other demos'**
  String get sectionOtherTitle;

  /// No description provided for @sectionOtherSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Additional AOPD examples.'**
  String get sectionOtherSubtitle;

  /// No description provided for @routeAdvancedRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced recipes'**
  String get routeAdvancedRecipesTitle;

  /// No description provided for @routeAdvancedRecipesDescription.
  ///
  /// In en, this message translates to:
  /// **'Instance, static, constructor, library, regex pointcuts, and PointCut data.'**
  String get routeAdvancedRecipesDescription;

  /// No description provided for @routeArgumentRewriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Argument rewrite'**
  String get routeArgumentRewriteTitle;

  /// No description provided for @routeArgumentRewriteDescription.
  ///
  /// In en, this message translates to:
  /// **'Advice rewrites a method\'s inputs before it runs - PII redaction and input sanitizing.'**
  String get routeArgumentRewriteDescription;

  /// No description provided for @routeAroundAdviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Around advice'**
  String get routeAroundAdviceTitle;

  /// No description provided for @routeAroundAdviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Time a method, flag slow calls, and cache another by skipping the original body.'**
  String get routeAroundAdviceDescription;

  /// No description provided for @routeAutoAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto analytics'**
  String get routeAutoAnalyticsTitle;

  /// No description provided for @routeAutoAnalyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'A practical full-tracking demo inspired by real click analytics instrumentation.'**
  String get routeAutoAnalyticsDescription;

  /// No description provided for @routeBasicAnnotationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic annotations'**
  String get routeBasicAnnotationsTitle;

  /// No description provided for @routeBasicAnnotationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Aspect, Execute, Call, FieldGet, Inject, and Add in small loops.'**
  String get routeBasicAnnotationsDescription;

  /// No description provided for @routeCodeCoverageTitle.
  ///
  /// In en, this message translates to:
  /// **'Code coverage'**
  String get routeCodeCoverageTitle;

  /// No description provided for @routeCodeCoverageDescription.
  ///
  /// In en, this message translates to:
  /// **'Method-level coverage via woven hit-recording advice.'**
  String get routeCodeCoverageDescription;

  /// No description provided for @routeExceptionGuardTitle.
  ///
  /// In en, this message translates to:
  /// **'Exception guard'**
  String get routeExceptionGuardTitle;

  /// No description provided for @routeExceptionGuardDescription.
  ///
  /// In en, this message translates to:
  /// **'Woven try/catch turns a throwing method into a safe fallback so the app never crashes.'**
  String get routeExceptionGuardDescription;

  /// No description provided for @routeFeatureFlagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature flags'**
  String get routeFeatureFlagsTitle;

  /// No description provided for @routeFeatureFlagsDescription.
  ///
  /// In en, this message translates to:
  /// **'Route gray-release behavior through advice while business methods stay stable.'**
  String get routeFeatureFlagsDescription;

  /// No description provided for @routeFrameworkPatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Framework patch'**
  String get routeFrameworkPatchTitle;

  /// No description provided for @routeFrameworkPatchDescription.
  ///
  /// In en, this message translates to:
  /// **'Patch a private Flutter SDK method to clamp font scaling without an SDK fork.'**
  String get routeFrameworkPatchDescription;

  /// No description provided for @routeJsonModelTitle.
  ///
  /// In en, this message translates to:
  /// **'JSON model'**
  String get routeJsonModelTitle;

  /// No description provided for @routeJsonModelDescription.
  ///
  /// In en, this message translates to:
  /// **'Auto-serialize models with AOP instead of dart:mirrors; toJson has no field code.'**
  String get routeJsonModelDescription;

  /// No description provided for @routeNetworkTracingTitle.
  ///
  /// In en, this message translates to:
  /// **'Network tracing'**
  String get routeNetworkTracingTitle;

  /// No description provided for @routeNetworkTracingDescription.
  ///
  /// In en, this message translates to:
  /// **'Trace API calls with ids, latency, and status without request-code logging.'**
  String get routeNetworkTracingDescription;

  /// No description provided for @routePerformanceBuildTitle.
  ///
  /// In en, this message translates to:
  /// **'Build tracking'**
  String get routePerformanceBuildTitle;

  /// No description provided for @routePerformanceBuildDescription.
  ///
  /// In en, this message translates to:
  /// **'Measure slow widget rebuilds produced by performRebuild.'**
  String get routePerformanceBuildDescription;

  /// No description provided for @routePerformanceFrameTitle.
  ///
  /// In en, this message translates to:
  /// **'Frame phases'**
  String get routePerformanceFrameTitle;

  /// No description provided for @routePerformanceFrameDescription.
  ///
  /// In en, this message translates to:
  /// **'Measure frame timing and build/layout/paint phase costs.'**
  String get routePerformanceFrameDescription;

  /// No description provided for @routePerformanceImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Image loading'**
  String get routePerformanceImageTitle;

  /// No description provided for @routePerformanceImageDescription.
  ///
  /// In en, this message translates to:
  /// **'Measure image cache miss and decode behavior.'**
  String get routePerformanceImageDescription;

  /// No description provided for @routePerformanceMonitoringTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance monitoring'**
  String get routePerformanceMonitoringTitle;

  /// No description provided for @routePerformanceMonitoringDescription.
  ///
  /// In en, this message translates to:
  /// **'A practical AOP demo for widget rebuilds, frame phases, and image loading.'**
  String get routePerformanceMonitoringDescription;

  /// No description provided for @routeWildcardCoverageTitle.
  ///
  /// In en, this message translates to:
  /// **'Wildcard coverage'**
  String get routeWildcardCoverageTitle;

  /// No description provided for @routeWildcardCoverageDescription.
  ///
  /// In en, this message translates to:
  /// **'One regex pointcut instruments a whole package subtree with no per-class annotation.'**
  String get routeWildcardCoverageDescription;

  /// No description provided for @networkTitle.
  ///
  /// In en, this message translates to:
  /// **'Network tracing'**
  String get networkTitle;

  /// No description provided for @networkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A practical observability pattern: API methods return business data, while woven advice adds trace id, latency, status, and result logs.'**
  String get networkSubtitle;

  /// No description provided for @networkRunApiCalls.
  ///
  /// In en, this message translates to:
  /// **'Run API calls'**
  String get networkRunApiCalls;

  /// No description provided for @networkRunApiCallsBody.
  ///
  /// In en, this message translates to:
  /// **'Each button calls a plain service method. The trace appears because @Execute wraps the method, not because the target logs it.'**
  String get networkRunApiCallsBody;

  /// No description provided for @networkFetchOrder.
  ///
  /// In en, this message translates to:
  /// **'Fetch order'**
  String get networkFetchOrder;

  /// No description provided for @networkSubmitPayment.
  ///
  /// In en, this message translates to:
  /// **'Submit payment'**
  String get networkSubmitPayment;

  /// No description provided for @networkPaymentReview.
  ///
  /// In en, this message translates to:
  /// **'Payment review'**
  String get networkPaymentReview;

  /// No description provided for @networkSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get networkSearch;

  /// No description provided for @networkTraceRecords.
  ///
  /// In en, this message translates to:
  /// **'Trace records'**
  String get networkTraceRecords;

  /// No description provided for @networkTraceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No traces yet. Run an API call to see woven metadata.'**
  String get networkTraceEmpty;

  /// No description provided for @featureTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature flags'**
  String get featureTitle;

  /// No description provided for @featureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AOP is often used for gray releases: keep stable business methods in place, then layer experiments, routing, or short-circuits in advice.'**
  String get featureSubtitle;

  /// No description provided for @featureToggleExperiments.
  ///
  /// In en, this message translates to:
  /// **'Toggle experiments'**
  String get featureToggleExperiments;

  /// No description provided for @featureToggleExperimentsBody.
  ///
  /// In en, this message translates to:
  /// **'The target service contains only legacy rules. Advice reads the flags and decides whether to proceed, decorate, or short-circuit.'**
  String get featureToggleExperimentsBody;

  /// No description provided for @featureCheckoutV2Title.
  ///
  /// In en, this message translates to:
  /// **'checkout_v2 discount'**
  String get featureCheckoutV2Title;

  /// No description provided for @featureCheckoutV2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Decorates proceed() result'**
  String get featureCheckoutV2Subtitle;

  /// No description provided for @featureGatewayV2Title.
  ///
  /// In en, this message translates to:
  /// **'gateway_v2 routing'**
  String get featureGatewayV2Title;

  /// No description provided for @featureGatewayV2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Can return without proceed()'**
  String get featureGatewayV2Subtitle;

  /// No description provided for @featureVipDiscount.
  ///
  /// In en, this message translates to:
  /// **'VIP discount'**
  String get featureVipDiscount;

  /// No description provided for @featureLargeCart.
  ///
  /// In en, this message translates to:
  /// **'Large cart'**
  String get featureLargeCart;

  /// No description provided for @featureEuGateway.
  ///
  /// In en, this message translates to:
  /// **'EU gateway'**
  String get featureEuGateway;

  /// No description provided for @featureUsGateway.
  ///
  /// In en, this message translates to:
  /// **'US gateway'**
  String get featureUsGateway;

  /// No description provided for @featureFlagDecisions.
  ///
  /// In en, this message translates to:
  /// **'Flag decisions'**
  String get featureFlagDecisions;

  /// No description provided for @featureFlagEmpty.
  ///
  /// In en, this message translates to:
  /// **'No decisions yet. Toggle a flag and run a service method.'**
  String get featureFlagEmpty;

  /// No description provided for @featureFlagOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get featureFlagOn;

  /// No description provided for @featureFlagOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get featureFlagOff;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
