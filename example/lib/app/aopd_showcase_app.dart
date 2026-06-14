import 'package:example/app/route_info_widget.dart';
import 'package:example/demos/analytics/route_analytics_runtime.dart';
import 'package:example/example_route.dart';
import 'package:example/example_routes.dart';
import 'package:example/l10n/app_locale_controller.dart';
import 'package:example/l10n/generated/app_localizations.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

class AopdShowcaseApp extends StatelessWidget {
  const AopdShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLocaleChoice>(
      valueListenable: AppLocaleController.instance.choice,
      builder: (BuildContext context, AppLocaleChoice _, Widget? child) {
        return MaterialApp(
          locale: AppLocaleController.instance.locale,
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF6F1E8),
          ),
          navigatorObservers: <NavigatorObserver>[
            RouteAnalyticsRuntime.instance.routeObserver,
          ],
          initialRoute: Routes.aopdHome,
          onGenerateRoute: (RouteSettings settings) {
            return onGenerateRoute(
              settings: settings,
              getRouteSettings: getRouteSettings,
              notFoundPageBuilder: () => Scaffold(
                body: Center(
                  child: Builder(
                    builder: (BuildContext context) =>
                        Text(AppLocalizations.of(context).routeNotFound),
                  ),
                ),
              ),
              routeSettingsWrapper: (FFRouteSettings ffRouteSettings) {
                return ffRouteSettings.copyWith(
                  builder: () => RouteInfoWidget(
                    settings: ffRouteSettings,
                    child: ffRouteSettings.builder(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
