import 'package:example/example_routes.dart';
import 'package:example/l10n/generated/app_localizations.dart';

String localizedRouteTitle(
  AppLocalizations l10n,
  String routeName,
  String fallback,
) {
  return switch (routeName) {
    Routes.aopdAdvancedRecipes => l10n.routeAdvancedRecipesTitle,
    Routes.aopdArgRewrite => l10n.routeArgumentRewriteTitle,
    Routes.aopdAroundAdvice => l10n.routeAroundAdviceTitle,
    Routes.aopdAutoAnalytics => l10n.routeAutoAnalyticsTitle,
    Routes.aopdBasicAnnotations => l10n.routeBasicAnnotationsTitle,
    Routes.aopdCodeCoverage => l10n.routeCodeCoverageTitle,
    Routes.aopdExceptionGuard => l10n.routeExceptionGuardTitle,
    Routes.aopdFeatureFlags => l10n.routeFeatureFlagsTitle,
    Routes.aopdFrameworkPatch => l10n.routeFrameworkPatchTitle,
    Routes.aopdJsonModel => l10n.routeJsonModelTitle,
    Routes.aopdNetworkTracing => l10n.routeNetworkTracingTitle,
    Routes.aopdPerformanceBuild => l10n.routePerformanceBuildTitle,
    Routes.aopdPerformanceFrame => l10n.routePerformanceFrameTitle,
    Routes.aopdPerformanceImage => l10n.routePerformanceImageTitle,
    Routes.aopdPerformanceMonitoring => l10n.routePerformanceMonitoringTitle,
    Routes.aopdWildcardCoverage => l10n.routeWildcardCoverageTitle,
    _ => fallback,
  };
}

String localizedRouteDescription(
  AppLocalizations l10n,
  String routeName,
  String fallback,
) {
  return switch (routeName) {
    Routes.aopdAdvancedRecipes => l10n.routeAdvancedRecipesDescription,
    Routes.aopdArgRewrite => l10n.routeArgumentRewriteDescription,
    Routes.aopdAroundAdvice => l10n.routeAroundAdviceDescription,
    Routes.aopdAutoAnalytics => l10n.routeAutoAnalyticsDescription,
    Routes.aopdBasicAnnotations => l10n.routeBasicAnnotationsDescription,
    Routes.aopdCodeCoverage => l10n.routeCodeCoverageDescription,
    Routes.aopdExceptionGuard => l10n.routeExceptionGuardDescription,
    Routes.aopdFeatureFlags => l10n.routeFeatureFlagsDescription,
    Routes.aopdFrameworkPatch => l10n.routeFrameworkPatchDescription,
    Routes.aopdJsonModel => l10n.routeJsonModelDescription,
    Routes.aopdNetworkTracing => l10n.routeNetworkTracingDescription,
    Routes.aopdPerformanceBuild => l10n.routePerformanceBuildDescription,
    Routes.aopdPerformanceFrame => l10n.routePerformanceFrameDescription,
    Routes.aopdPerformanceImage => l10n.routePerformanceImageDescription,
    Routes.aopdPerformanceMonitoring =>
      l10n.routePerformanceMonitoringDescription,
    Routes.aopdWildcardCoverage => l10n.routeWildcardCoverageDescription,
    _ => fallback,
  };
}
