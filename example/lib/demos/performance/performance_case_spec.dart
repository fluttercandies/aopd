import 'package:example/demos/performance/performance_workloads.dart';
import 'package:example/demos/performance/performance_events.dart';
import 'package:example/example_route.dart';
import 'package:example/example_routes.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

class PerformanceCaseSpec {
  const PerformanceCaseSpec({
    required this.title,
    required this.description,
    required this.target,
    required this.routeName,
    required this.icon,
    required this.color,
    required this.child,
    required this.eventKinds,
    required this._order,
  });

  final String title;
  final String description;
  final String target;
  final String routeName;
  final IconData icon;
  final Color color;
  final Widget child;
  final Set<PerformanceEventKind> eventKinds;
  final int _order;

  static List<PerformanceCaseSpec> routeCases() {
    final List<PerformanceCaseSpec> cases = <PerformanceCaseSpec>[
      for (final String routeName in routeNames)
        if (_fromRouteName(routeName) case final PerformanceCaseSpec spec) spec,
    ];
    cases.sort(
      (PerformanceCaseSpec a, PerformanceCaseSpec b) =>
          a._order.compareTo(b._order),
    );
    return cases;
  }

  static PerformanceCaseSpec routeCase(String routeName) {
    final PerformanceCaseSpec? spec = _fromRouteName(routeName);
    if (spec == null) {
      throw StateError('Performance route metadata not found: $routeName');
    }
    return spec;
  }

  static PerformanceCaseSpec? _fromRouteName(String routeName) {
    final FFRouteSettings settings = getRouteSettings(name: routeName);
    final Map<String, dynamic> exts =
        settings.exts ?? const <String, dynamic>{};
    if (exts['group'] != 'performance') {
      return null;
    }

    final _PerformanceCaseVisual? visual = _PerformanceCaseVisual.forRoute(
      settings.name ?? routeName,
    );
    if (visual == null) {
      return null;
    }

    return PerformanceCaseSpec(
      title: settings.routeName ?? routeName,
      description: settings.description ?? '',
      target: visual.target,
      routeName: settings.name ?? routeName,
      icon: _iconFor(exts['icon'] as String?),
      color: _colorFor(exts['color'] as String?),
      child: visual.child,
      eventKinds: visual.eventKinds,
      order: int.tryParse(exts['order']?.toString() ?? '') ?? 0,
    );
  }

  static IconData _iconFor(String? value) {
    return switch (value) {
      'timeline' => Icons.timeline_rounded,
      'image' => Icons.image_search_rounded,
      'build' || _ => Icons.precision_manufacturing_rounded,
    };
  }

  static Color _colorFor(String? value) {
    return switch (value) {
      'amber' => const Color(0xFFB45309),
      'blue' => const Color(0xFF1D4ED8),
      'rose' || _ => const Color(0xFFBE123C),
    };
  }
}

class _PerformanceCaseVisual {
  const _PerformanceCaseVisual({
    required this.target,
    required this.child,
    required this.eventKinds,
  });

  final String target;
  final Widget child;
  final Set<PerformanceEventKind> eventKinds;

  static _PerformanceCaseVisual? forRoute(String routeName) {
    return switch (routeName) {
      Routes.aopdPerformanceBuild => const _PerformanceCaseVisual(
        target: 'StatefulElement.performRebuild',
        child: SlowBuildDemoCard(),
        eventKinds: <PerformanceEventKind>{PerformanceEventKind.build},
      ),
      Routes.aopdPerformanceFrame => const _PerformanceCaseVisual(
        target: 'BuildOwner.buildScope + PipelineOwner.flushLayout/flushPaint',
        child: FramePressureDemoCard(),
        eventKinds: <PerformanceEventKind>{
          PerformanceEventKind.frame,
          PerformanceEventKind.phase,
        },
      ),
      Routes.aopdPerformanceImage => const _PerformanceCaseVisual(
        target:
            'ImageCache.putIfAbsent + PaintingBinding.instantiateImageCodec*',
        child: ImageLoadingDemoCard(),
        eventKinds: <PerformanceEventKind>{PerformanceEventKind.image},
      ),
      _ => null,
    };
  }
}
