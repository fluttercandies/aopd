import 'package:example/demos/performance/performance_case_page.dart';
import 'package:example/demos/performance/performance_case_spec.dart';
import 'package:example/demos/performance/performance_catalog.dart';
import 'package:example/example_routes.dart';
import 'package:ff_annotation_route_library/ff_annotation_route_library.dart';
import 'package:flutter/material.dart';

@FFRoute(
  name: 'aopd://performance-monitoring',
  routeName: 'Performance monitoring',
  description:
      'A practical AOP demo for widget rebuilds, frame phases, and image loading.',
  exts: <String, dynamic>{
    'group': 'demo',
    'subgroup': 'observability',
    'order': '2',
    'icon': 'speed',
    'color': 'rose',
  },
)
class PerformanceMonitoringPage extends StatelessWidget {
  const PerformanceMonitoringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PerformanceCatalog();
  }
}

@FFRoute(
  name: 'aopd://performance-build',
  routeName: 'Build tracking',
  description: 'Measure slow widget rebuilds produced by performRebuild.',
  exts: <String, dynamic>{
    'group': 'performance',
    'order': '1',
    'icon': 'build',
    'color': 'rose',
  },
)
class PerformanceBuildPage extends StatelessWidget {
  const PerformanceBuildPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PerformanceCasePage(
      spec: PerformanceCaseSpec.routeCase(Routes.aopdPerformanceBuild),
    );
  }
}

@FFRoute(
  name: 'aopd://performance-frame',
  routeName: 'Frame phases',
  description: 'Measure frame timing and build/layout/paint phase costs.',
  exts: <String, dynamic>{
    'group': 'performance',
    'order': '2',
    'icon': 'timeline',
    'color': 'amber',
  },
)
class PerformanceFramePage extends StatelessWidget {
  const PerformanceFramePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PerformanceCasePage(
      spec: PerformanceCaseSpec.routeCase(Routes.aopdPerformanceFrame),
    );
  }
}

@FFRoute(
  name: 'aopd://performance-image',
  routeName: 'Image loading',
  description: 'Measure image cache miss and decode behavior.',
  exts: <String, dynamic>{
    'group': 'performance',
    'order': '3',
    'icon': 'image',
    'color': 'blue',
  },
)
class PerformanceImagePage extends StatelessWidget {
  const PerformanceImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PerformanceCasePage(
      spec: PerformanceCaseSpec.routeCase(Routes.aopdPerformanceImage),
    );
  }
}
