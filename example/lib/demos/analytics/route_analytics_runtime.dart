import 'package:example/app/route_info_widget.dart';
import 'package:flutter/material.dart';

class RouteAnalyticsRuntime {
  RouteAnalyticsRuntime._();

  static final RouteAnalyticsRuntime instance = RouteAnalyticsRuntime._();

  final RouteTracker routeTracker = RouteTracker();

  NavigatorObserver get routeObserver =>
      AppRouteObserver(routeTracker: routeTracker);
}

class AppRouteObserver extends NavigatorObserver {
  AppRouteObserver({required this._routeTracker});

  final RouteTracker _routeTracker;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeTracker.onRoutePush(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeTracker.onRoutePop(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeTracker.onRoutePop(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _routeTracker.onRoutePop(oldRoute);
    }
    if (newRoute != null) {
      _routeTracker.onRoutePush(newRoute);
    }
  }
}

class RouteTracker {
  final List<Route<dynamic>> _routes = <Route<dynamic>>[];

  void onRoutePush(Route<dynamic>? route) {
    if (route != null) {
      _routes.add(route);
    }
  }

  void onRoutePop(Route<dynamic>? route) {
    if (route != null) {
      _routes.remove(route);
    }
  }

  Route<dynamic>? get currentRoute => _routes.isEmpty ? null : _routes.last;

  PageRoute<dynamic>? get topPage {
    for (final Route<dynamic> route in _routes.reversed) {
      if (route is PageRoute<dynamic>) {
        return route;
      }
    }
    return null;
  }

  bool isCurrentOverlayWidget(Widget widget) {
    final Route<dynamic>? route = currentRoute;
    if (route is! ModalRoute<dynamic> || route is PageRoute<dynamic>) {
      return false;
    }
    final BuildContext? context = route.subtreeContext;
    if (context == null) {
      return false;
    }

    bool found = false;
    void visit(BuildContext currentContext) {
      if (found) {
        return;
      }
      if (currentContext.widget == widget) {
        found = true;
        return;
      }
      currentContext.visitChildElements(visit);
    }

    visit(context);
    return found;
  }

  RouteInfoWidget? findTopPageRouteInfoWidget() {
    final BuildContext? context = topPage?.subtreeContext;
    if (context == null) {
      return null;
    }

    RouteInfoWidget? result;
    void visit(BuildContext currentContext) {
      if (result != null) {
        return;
      }
      final Widget widget = currentContext.widget;
      if (widget is RouteInfoWidget) {
        result = widget;
        return;
      }
      currentContext.visitChildElements(visit);
    }

    visit(context);
    return result;
  }
}
