// Copyright 2026 AOPD contributors. All rights reserved.
// Use of this source code is governed by the MIT license in the LICENSE file.

// ignore: unused_import
import 'package:example/aop/aspects/advanced_recipes_aspect.dart';
// ignore: unused_import
import 'package:example/aop/aspects/auto_analytics_aspect.dart';
// ignore: unused_import
import 'package:example/aop/aspects/basic_annotations_aspect.dart';
import 'package:example/app/aopd_showcase_app.dart';
import 'package:example/l10n/app_locale_controller.dart';
import 'package:example/shared/demo_event_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    DemoEventLog.instance.clear();
    AppLocaleController.instance.setChoice(AppLocaleChoice.system);
  });

  testWidgets('AOPD showcase home renders catalog entries', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AopdShowcaseApp());
    await tester.pumpAndSettle();

    expect(find.text('AOPD Example'), findsOneWidget);
    expect(find.text('Core annotations'), findsOneWidget);
    expect(find.text('Observability'), findsOneWidget);
    expect(find.text('Runtime behavior'), findsOneWidget);
    expect(find.text('Basic annotations'), findsOneWidget);
    expect(find.text('Advanced recipes'), findsOneWidget);
    expect(find.text('Auto analytics'), findsOneWidget);
    expect(find.text('Network tracing'), findsOneWidget);
    expect(find.text('Feature flags'), findsOneWidget);
    expect(find.text('Result log'), findsNothing);
  });

  testWidgets('AOPD showcase follows Chinese system locale', (
    WidgetTester tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('zh');
    tester.binding.platformDispatcher.localesTestValue = const <Locale>[
      Locale('zh'),
    ];
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const AopdShowcaseApp());
    await tester.pumpAndSettle();

    expect(find.text('AOPD \u793a\u4f8b'), findsOneWidget);
    expect(find.text('\u6838\u5fc3\u6ce8\u89e3'), findsOneWidget);
    expect(find.text('\u53ef\u89c2\u6d4b\u6027'), findsOneWidget);
    expect(find.text('\u7f51\u7edc\u8ffd\u8e2a'), findsOneWidget);
    expect(find.text('\u7070\u5ea6\u5f00\u5173'), findsOneWidget);
  });

  testWidgets('Home language selector overrides system locale', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AopdShowcaseApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u4e2d\u6587'));
    await tester.pumpAndSettle();
    expect(find.text('AOPD \u793a\u4f8b'), findsOneWidget);
    expect(find.text('\u6838\u5fc3\u6ce8\u89e3'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('AOPD Example'), findsOneWidget);
    expect(find.text('Core annotations'), findsOneWidget);
  });

  testWidgets('Basic annotations page shows demo entry cards', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AopdShowcaseApp());
    await tester.pumpAndSettle();
    final Finder basicEntry = find.text('Basic annotations');
    await tester.ensureVisible(basicEntry);
    await tester.pumpAndSettle();
    await tester.tap(basicEntry);
    await tester.pumpAndSettle();

    expect(find.text('@Execute'), findsOneWidget);
    expect(find.text('@Call'), findsOneWidget);
    expect(find.text('Result log'), findsNothing);
  });

  testWidgets('Basic annotation demos append visible result events', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AopdShowcaseApp());
    await tester.pumpAndSettle();
    final Finder basicEntry = find.text('Basic annotations');
    await tester.ensureVisible(basicEntry);
    await tester.pumpAndSettle();
    await tester.tap(basicEntry);
    await tester.pumpAndSettle();

    await _openBasicDemo(tester, 'basic.execute');
    await _tapDemo(tester, 'basic.execute');
    expect(find.text('Execute result'), findsOneWidget);
    expect(find.text('Execute proceed result'), findsOneWidget);
    expect(find.text('101'), findsOneWidget);
    await _backToBasicList(tester);

    await _openBasicDemo(tester, 'basic.call');
    await _tapDemo(tester, 'basic.call');
    expect(find.text('Call result'), findsOneWidget);
    expect(find.text('Call intercepted'), findsOneWidget);
    expect(find.textContaining('decorated by @Call'), findsOneWidget);
    await _backToBasicList(tester);

    await _openBasicDemo(tester, 'basic.field_get');
    await _tapDemo(tester, 'basic.field_get');
    expect(find.text('FieldGet result'), findsOneWidget);
    expect(find.text('FieldGet override'), findsOneWidget);
    expect(find.text('aopd-overridden-channel'), findsOneWidget);
    await _backToBasicList(tester);

    await _openBasicDemo(tester, 'basic.inject');
    await _tapDemo(tester, 'basic.inject');
    expect(find.text('Inject result'), findsOneWidget);
    expect(find.text('Inject marker reached'), findsOneWidget);
    await _backToBasicList(tester);

    await _openBasicDemo(tester, 'basic.add');
    await _tapDemo(tester, 'basic.add');
    expect(find.text('Add result'), findsOneWidget);
    expect(find.text('Add method invoked'), findsOneWidget);
    expect(find.text('generated-basic-badge'), findsOneWidget);
  });

  testWidgets('Advanced recipes page can run the pointcut matrix', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AopdShowcaseApp());
    await tester.pumpAndSettle();
    final Finder advancedEntry = find.text('Advanced recipes');
    await tester.ensureVisible(advancedEntry);
    await tester.pumpAndSettle();
    await tester.tap(advancedEntry);
    await tester.pumpAndSettle();

    expect(find.text('PointCut matrix'), findsOneWidget);

    await _tapDemo(tester, 'advanced.matrix');

    expect(find.text('Advanced result'), findsOneWidget);
    expect(find.text('Call constructor pointcut'), findsOneWidget);
    expect(find.text('Regex execute pointcut'), findsWidgets);
    expect(find.textContaining('instance:'), findsOneWidget);
  });

  testWidgets('Auto analytics page renders practical tracking demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AopdShowcaseApp());
    await tester.pumpAndSettle();
    final Finder analyticsEntry = find.text('Auto analytics');
    await tester.ensureVisible(analyticsEntry);
    await tester.pumpAndSettle();
    await tester.tap(analyticsEntry);
    await tester.pumpAndSettle();

    expect(
      find.text('Full tracking without business-code logging'),
      findsOneWidget,
    );
    expect(find.text('track_widget_creation: true'), findsOneWidget);
    expect(find.text('AOPD Field Notes'), findsOneWidget);
    expect(find.text('Kernel Explorer Mug'), findsOneWidget);
    expect(find.text('Result log'), findsOneWidget);
  });

  testWidgets('Network tracing and feature flag pages render business demos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AopdShowcaseApp());
    await tester.pumpAndSettle();

    final Finder networkEntry = find.text('Network tracing');
    await tester.ensureVisible(networkEntry);
    await tester.pumpAndSettle();
    await tester.tap(networkEntry);
    await tester.pumpAndSettle();
    expect(find.text('Run API calls'), findsOneWidget);
    expect(find.text('Trace records'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    final Finder flagsEntry = find.text('Feature flags');
    await tester.ensureVisible(flagsEntry);
    await tester.pumpAndSettle();
    await tester.tap(flagsEntry);
    await tester.pumpAndSettle();
    expect(find.text('Toggle experiments'), findsOneWidget);
    expect(find.text('Flag decisions'), findsOneWidget);
  });
}

Future<void> _openBasicDemo(WidgetTester tester, String id) async {
  final Finder entry = find.byKey(Key('basic.entry.$id'));
  await tester.ensureVisible(entry);
  await tester.pumpAndSettle();
  await tester.tap(entry);
  await tester.pumpAndSettle();
  expect(find.text('Result log'), findsOneWidget);
}

Future<void> _backToBasicList(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pumpAndSettle();
}

Future<void> _tapDemo(WidgetTester tester, String id) async {
  final Finder runButton = find.byKey(Key('demo.$id.run'));
  await tester.ensureVisible(runButton);
  await tester.pumpAndSettle();
  await tester.tap(runButton);
  await tester.pumpAndSettle();
}
