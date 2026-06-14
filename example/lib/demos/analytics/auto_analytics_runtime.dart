import 'package:aopd/aopd.dart';
import 'package:example/app/route_info_widget.dart';
import 'package:example/demos/analytics/route_analytics_runtime.dart';
import 'package:example/example_routes.dart';
import 'package:example/shared/demo_event_log.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class AutoAnalyticsRuntime {
  AutoAnalyticsRuntime._();

  static final AutoAnalyticsRuntime instance = AutoAnalyticsRuntime._();

  final _PointerHitTracker _hitTracker = _PointerHitTracker();

  void recordHitTestTarget(HitTestTarget target, PointerEvent event) {
    if (target is RenderObject) {
      _hitTracker.record(target, event);
    }
  }

  void recordGestureCallback(String eventName) {
    if (eventName != 'onTap') {
      return;
    }
    // Only log while the Auto analytics demo is the active page; on any other
    // demo these app-wide tap events are noise (and skipping early avoids the
    // element-tree path walk below on every tap elsewhere).
    final String? pageName =
        RouteAnalyticsRuntime.instance.routeTracker.topPage?.settings.name;
    if (pageName != Routes.aopdAutoAnalytics) {
      return;
    }
    final _PointerHit? hit = _hitTracker.currentHit;
    if (hit == null) {
      return;
    }
    final RenderObject? renderObject = hit.attachedRenderObject;
    if (renderObject == null) {
      return;
    }

    final String? path = _AnalyticsPathBuilder(
      routeTracker: RouteAnalyticsRuntime.instance.routeTracker,
    ).build(renderObject);
    if (path == null || path.isEmpty) {
      return;
    }

    DemoEventLog.instance.addAspect(
      'Auto analytics event',
      'event=tap\npath=$path',
    );
  }
}

class _PointerHitTracker {
  int _currentPointer = -1;
  int _previousPointer = -1;
  final Map<int, _PointerHit> _hits = <int, _PointerHit>{};

  void record(RenderObject renderObject, PointerEvent event) {
    _currentPointer = event.pointer;
    if (_currentPointer > _previousPointer) {
      _hits.clear();
    }
    _hits.putIfAbsent(_currentPointer, () => _PointerHit(renderObject, event));
    _previousPointer = _currentPointer;
  }

  _PointerHit? get currentHit => _hits[_currentPointer];
}

class _PointerHit {
  const _PointerHit(this.renderObject, this.event);

  final RenderObject renderObject;
  final PointerEvent event;

  RenderObject? get attachedRenderObject {
    if (renderObject.attached) {
      return renderObject;
    }

    final HitTestResult result = HitTestResult();
    try {
      WidgetsBinding.instance.hitTestInView(
        result,
        event.position,
        event.viewId,
      );
    } catch (error, stackTrace) {
      debugPrint('AOPD analytics hit test fallback failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }

    for (final HitTestEntry<HitTestTarget> entry in result.path) {
      final HitTestTarget target = entry.target;
      if (target is RenderObject && target.attached) {
        return target;
      }
    }
    return null;
  }
}

class _AnalyticsPathBuilder {
  _AnalyticsPathBuilder({required RouteTracker routeTracker})
    : _routeTracker = routeTracker;

  static const String _packageName = 'example';

  final RouteTracker _routeTracker;

  String? build(RenderObject renderObject) {
    final DebugCreator? debugCreator =
        renderObject.debugCreator as DebugCreator?;
    final Element? element = debugCreator?.element;
    if (element == null) {
      return null;
    }

    final List<String> contentNodes = <String>[];
    final List<String> widgetNodes = <String>[];
    _collectContent(element, contentNodes);
    final RouteInfoWidget? nearestRouteInfo = _collectProjectAncestors(
      element,
      widgetNodes,
    );

    final List<String> nodes = <String>[
      _routeNode(nearestRouteInfo, element),
      _overlayNode(element),
      ...widgetNodes.reversed,
      ...contentNodes,
    ].where((String node) => node.isNotEmpty).toList();

    if (nodes.isEmpty) {
      return element.widget.runtimeType.toString();
    }
    return nodes.join(' / ');
  }

  RouteInfoWidget? _collectProjectAncestors(
    Element element,
    List<String> nodes,
  ) {
    Element? current = element;
    RouteInfoWidget? nearestRouteInfo;
    while (current != null) {
      final Widget widget = current.widget;
      if (widget is RouteInfoWidget) {
        nearestRouteInfo = widget;
        break;
      }
      final _WidgetLocation? location = _projectLocationOf(current.widget);
      if (location != null) {
        nodes.add(location.toPathNode(current.widget.runtimeType.toString()));
      }
      Element? parent;
      current.visitAncestorElements((Element ancestor) {
        parent = ancestor;
        return false;
      });
      current = parent;
    }
    return nearestRouteInfo;
  }

  String _routeNode(RouteInfoWidget? nearestRouteInfo, Element element) {
    final RouteInfoWidget? routeInfo =
        nearestRouteInfo ?? _routeTracker.findTopPageRouteInfoWidget();
    if (routeInfo != null) {
      final String routeTitle = routeInfo.settings.routeName ?? '';
      return routeTitle.isEmpty
          ? routeInfo.settings.name ?? ''
          : '${routeInfo.settings.name}($routeTitle)';
    }

    if (_routeTracker.isCurrentOverlayWidget(element.widget)) {
      final PageRoute<dynamic>? pageRoute = _routeTracker.topPage;
      final String pageName = pageRoute?.settings.name ?? 'page';
      return 'overlay($pageName)';
    }

    return _routeTracker.topPage?.settings.name ?? '';
  }

  String _overlayNode(Element element) {
    if (!_routeTracker.isCurrentOverlayWidget(element.widget)) {
      return '';
    }
    final Route<dynamic>? currentRoute = _routeTracker.currentRoute;
    return switch (currentRoute) {
      RawDialogRoute<dynamic>() => 'overlay(dialog)',
      ModalRoute<dynamic>(settings: final RouteSettings settings) =>
        'overlay(${settings.name ?? 'modal'})',
      _ => 'overlay',
    };
  }

  void _collectContent(Element element, List<String> nodes) {
    final Object? renderObject = element.renderObject;
    if (renderObject is RenderParagraph) {
      final String text = renderObject.text.toPlainText().trim();
      if (text.isNotEmpty) {
        nodes.add('"$text"');
      }
      return;
    }

    final Widget widget = element.widget;
    if (widget is Image) {
      nodes.add('Image');
      return;
    }

    element.visitChildElements((Element child) {
      if (nodes.length >= 3) {
        return;
      }
      _collectContent(child, nodes);
    });
  }

  _WidgetLocation? _projectLocationOf(Widget widget) {
    if (widget is! AopHasCreationLocation) {
      return null;
    }
    final AopLocation location = (widget as AopHasCreationLocation).aopLocation;
    if (!_isProjectLocation(location)) {
      return null;
    }
    return _WidgetLocation(location);
  }

  bool _isProjectLocation(AopLocation location) {
    final String? ownerImportUri = location.ownerImportUri;
    if (ownerImportUri != null && ownerImportUri.isNotEmpty) {
      return ownerImportUri.startsWith('package:$_packageName/');
    }
    final String normalized = location.file.replaceAll('\\', '/');
    return normalized.contains('/$_packageName/lib/') ||
        normalized.startsWith('package:$_packageName/');
  }
}

class _WidgetLocation {
  const _WidgetLocation(this.location);

  final AopLocation location;

  String toPathNode(String widgetType) {
    final String source = location.ownerImportUri ?? _shortFile(location.file);
    return '$widgetType($source:${location.line}:${location.column})';
  }

  static String _shortFile(String file) {
    final String normalized = file.replaceAll('\\', '/');
    final int index = normalized.lastIndexOf('/');
    return index >= 0 ? normalized.substring(index + 1) : normalized;
  }
}
