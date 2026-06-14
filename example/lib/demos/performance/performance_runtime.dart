import 'dart:async';
import 'package:aopd/aopd.dart';
import 'package:example/demos/analytics/route_analytics_runtime.dart';
import 'package:example/demos/performance/performance_events.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class PerformanceRuntime {
  PerformanceRuntime._() {
    _frameMonitor.start();
  }

  static final PerformanceRuntime instance = PerformanceRuntime._();

  final ValueNotifier<List<PerformanceEvent>> events =
      ValueNotifier<List<PerformanceEvent>>(<PerformanceEvent>[]);
  final List<PerformanceEvent> _pendingEvents = <PerformanceEvent>[];
  bool _flushScheduled = false;

  late final _BuildMonitor _buildMonitor = _BuildMonitor(
    routeTracker: RouteAnalyticsRuntime.instance.routeTracker,
    emit: _emit,
  );
  late final _FrameMonitor _frameMonitor = _FrameMonitor(
    routeTracker: RouteAnalyticsRuntime.instance.routeTracker,
    widgetDrainer: _buildMonitor.drainFrameContributors,
    emit: _emit,
  );
  late final _ImageMonitor _imageMonitor = _ImageMonitor(
    routeTracker: RouteAnalyticsRuntime.instance.routeTracker,
    emit: _emit,
  );

  void clear() {
    _pendingEvents.clear();
    events.value = <PerformanceEvent>[];
  }

  void onPerformRebuild(Element element, VoidCallback proceed) {
    _buildMonitor.onPerformRebuild(element, proceed);
  }

  void onBuildScope(VoidCallback proceed) {
    _frameMonitor.onBuildScope(proceed);
  }

  void onFlushLayout(VoidCallback proceed) {
    _frameMonitor.onFlushLayout(proceed);
  }

  void onFlushPaint(VoidCallback proceed) {
    _frameMonitor.onFlushPaint(proceed);
  }

  T onImageCachePutIfAbsent<T>({
    required Object? key,
    required bool Function() cacheMissGetter,
    required T Function() proceed,
  }) {
    return _imageMonitor.onImageCachePutIfAbsent(
      key: key,
      cacheMissGetter: cacheMissGetter,
      proceed: proceed,
    );
  }

  Future<T> onInstantiateImageCodec<T>({
    required String apiName,
    required Object? source,
    required Future<T> Function() proceed,
  }) {
    return _imageMonitor.onInstantiateImageCodec(
      apiName: apiName,
      source: source,
      proceed: proceed,
    );
  }

  void _emit(PerformanceEvent event) {
    _pendingEvents.insert(0, event);
    if (_flushScheduled) {
      return;
    }
    _flushScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _flushScheduled = false;
      if (_pendingEvents.isEmpty) {
        return;
      }
      events.value = <PerformanceEvent>[
        ..._pendingEvents,
        ...events.value,
      ].take(60).toList(growable: false);
      _pendingEvents.clear();
    });
  }
}

class _BuildMonitor {
  _BuildMonitor({required this._routeTracker, required this._emit});

  final RouteTracker _routeTracker;
  final void Function(PerformanceEvent event) _emit;

  Duration _lastFrameTimestamp = Duration.zero;
  final Map<int, int> _rebuildCounts = <int, int>{};
  final List<String> _currentFrameContributors = <String>[];

  List<String> drainFrameContributors() {
    if (_currentFrameContributors.isEmpty) {
      return const <String>[];
    }
    final List<String> result = List<String>.from(_currentFrameContributors);
    _currentFrameContributors.clear();
    return result;
  }

  void onPerformRebuild(Element element, VoidCallback proceed) {
    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    final bool inFrame =
        phase != SchedulerPhase.idle &&
        phase != SchedulerPhase.transientCallbacks;

    if (inFrame) {
      final Duration frameTimestamp =
          SchedulerBinding.instance.currentFrameTimeStamp;
      if (frameTimestamp != _lastFrameTimestamp) {
        _lastFrameTimestamp = frameTimestamp;
        _rebuildCounts.clear();
        _currentFrameContributors.clear();
      }
    }

    final int id = identityHashCode(element);
    _rebuildCounts[id] = (_rebuildCounts[id] ?? 0) + 1;
    final int rebuildCount = _rebuildCounts[id]!;

    final Stopwatch stopwatch = Stopwatch()..start();
    proceed();
    stopwatch.stop();

    final Widget widget = element.widget;
    final AopLocation? location = _projectLocation(widget);
    final int durationMicros = stopwatch.elapsedMicroseconds;
    final String? routeName = _routeTracker.topPage?.settings.name;

    final BuildPerformanceEvent event = BuildPerformanceEvent(
      widgetType: widget.runtimeType.toString(),
      durationMicros: durationMicros,
      rebuildCount: rebuildCount,
      file: location?.file,
      line: location?.line,
      routeName: routeName,
    );

    if (location != null && (durationMicros > 1000 || rebuildCount >= 3)) {
      _currentFrameContributors.add(event.contributorLabel);
    }

    if (location == null || (!event.isSlowBuild && !event.isExcessiveRebuild)) {
      return;
    }
    _emit(event.toPerformanceEvent());
  }

  AopLocation? _projectLocation(Widget widget) {
    if (widget is! AopHasCreationLocation) {
      return null;
    }
    final AopLocation location = (widget as AopHasCreationLocation).aopLocation;
    if (location.isFlutterSdk()) {
      return null;
    }
    return location;
  }
}

class _FrameMonitor {
  _FrameMonitor({
    required this._routeTracker,
    required this._widgetDrainer,
    required this._emit,
  });

  static const double _frameBudget60HzMs = 1000.0 / 60.0;

  final RouteTracker _routeTracker;
  final List<String> Function() _widgetDrainer;
  final void Function(PerformanceEvent event) _emit;
  final Map<int, _FramePhaseBucket> _phaseBuckets = <int, _FramePhaseBucket>{};

  int _frameSequence = 0;
  bool _started = false;

  void start() {
    if (_started) {
      return;
    }
    _started = true;
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final FrameTiming timing in timings) {
      _frameSequence += 1;
      final int totalMicros = timing.totalSpan.inMicroseconds;
      final bool isOver60HzBudget = totalMicros > 33333;
      final bool isOver120HzBudget = totalMicros > 16667;
      if (!isOver60HzBudget && !isOver120HzBudget) {
        continue;
      }

      final double ratio = totalMicros / (_frameBudget60HzMs * 1000.0);
      final FramePerformanceEvent event = FramePerformanceEvent(
        frameSequence: _frameSequence,
        totalMicros: totalMicros,
        buildMicros: timing.buildDuration.inMicroseconds,
        rasterMicros: timing.rasterDuration.inMicroseconds,
        droppedFrames60Hz: ratio.floor() > 0 ? ratio.floor() - 1 : 0,
        isOver60HzBudget: isOver60HzBudget,
        isOver120HzBudget: isOver120HzBudget,
        routeName: _routeTracker.topPage?.settings.name,
      );
      _emit(event.toPerformanceEvent());
    }
  }

  void onBuildScope(VoidCallback proceed) {
    _measurePhase(_PhaseKind.buildScope, proceed);
  }

  void onFlushLayout(VoidCallback proceed) {
    _measurePhase(_PhaseKind.layout, proceed);
  }

  void onFlushPaint(VoidCallback proceed) {
    _measurePhase(_PhaseKind.paint, proceed);
  }

  void _measurePhase(_PhaseKind kind, VoidCallback proceed) {
    final int? frameKey = _currentFrameKeyMicros();
    if (frameKey == null) {
      proceed();
      return;
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    proceed();
    stopwatch.stop();

    final _FramePhaseBucket bucket = _phaseBuckets.putIfAbsent(
      frameKey,
      _FramePhaseBucket.new,
    );
    final int elapsedMicros = stopwatch.elapsedMicroseconds;

    switch (kind) {
      case _PhaseKind.buildScope:
        bucket.buildScopeMicros += elapsedMicros;
        break;
      case _PhaseKind.layout:
        bucket.layoutMicros += elapsedMicros;
        break;
      case _PhaseKind.paint:
        bucket.paintMicros += elapsedMicros;
        _emitPhaseEvent(bucket);
        _phaseBuckets.remove(frameKey);
        break;
    }
  }

  int? _currentFrameKeyMicros() {
    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    final bool inFrame =
        phase != SchedulerPhase.idle &&
        phase != SchedulerPhase.transientCallbacks;
    if (!inFrame) {
      return null;
    }
    return SchedulerBinding.instance.currentFrameTimeStamp.inMicroseconds;
  }

  void _emitPhaseEvent(_FramePhaseBucket bucket) {
    final int totalMicros =
        bucket.buildScopeMicros + bucket.layoutMicros + bucket.paintMicros;
    final bool isOver60HzBudget = totalMicros > 20000;
    final bool isOver120HzBudget = totalMicros > 12000;
    if (!isOver60HzBudget && !isOver120HzBudget) {
      return;
    }

    final FramePhasePerformanceEvent event = FramePhasePerformanceEvent(
      buildScopeMicros: bucket.buildScopeMicros,
      layoutMicros: bucket.layoutMicros,
      paintMicros: bucket.paintMicros,
      totalMicros: totalMicros,
      isOver60HzBudget: isOver60HzBudget,
      isOver120HzBudget: isOver120HzBudget,
      routeName: _routeTracker.topPage?.settings.name,
      suspectWidgets: _widgetDrainer(),
    );
    _emit(event.toPerformanceEvent());
  }
}

class _ImageMonitor {
  _ImageMonitor({required this._routeTracker, required this._emit});

  final RouteTracker _routeTracker;
  final void Function(PerformanceEvent event) _emit;

  T onImageCachePutIfAbsent<T>({
    required Object? key,
    required bool Function() cacheMissGetter,
    required T Function() proceed,
  }) {
    final Stopwatch stopwatch = Stopwatch()..start();
    final T result = proceed();
    stopwatch.stop();

    final bool cacheMiss = cacheMissGetter();
    final int durationMicros = stopwatch.elapsedMicroseconds;
    final bool isSlow =
        durationMicros >= ImagePerformanceEvent.slowCacheLookupMicros;
    if (cacheMiss || isSlow) {
      final ImagePerformanceEvent event = ImagePerformanceEvent(
        type: cacheMiss
            ? ImagePerformanceEventType.cacheMiss
            : ImagePerformanceEventType.cacheHit,
        durationMicros: durationMicros,
        isSlow: isSlow,
        key: key,
        routeName: _routeTracker.topPage?.settings.name,
      );
      _emit(event.toPerformanceEvent());
    }

    return result;
  }

  Future<T> onInstantiateImageCodec<T>({
    required String apiName,
    required Object? source,
    required Future<T> Function() proceed,
  }) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    try {
      final T result = await proceed();
      stopwatch.stop();
      final int durationMicros = stopwatch.elapsedMicroseconds;
      final bool isSlow =
          durationMicros >= ImagePerformanceEvent.slowDecodeMicros;
      if (isSlow) {
        final ImagePerformanceEvent event = ImagePerformanceEvent(
          type: ImagePerformanceEventType.decode,
          durationMicros: durationMicros,
          isSlow: true,
          key: source,
          codecApi: apiName,
          routeName: _routeTracker.topPage?.settings.name,
        );
        _emit(event.toPerformanceEvent());
      }
      return result;
    } catch (error) {
      stopwatch.stop();
      final ImagePerformanceEvent event = ImagePerformanceEvent(
        type: ImagePerformanceEventType.decode,
        durationMicros: stopwatch.elapsedMicroseconds,
        isSlow: true,
        key: source,
        codecApi: apiName,
        routeName: _routeTracker.topPage?.settings.name,
        error: error,
      );
      _emit(event.toPerformanceEvent());
      rethrow;
    }
  }
}

class _FramePhaseBucket {
  int buildScopeMicros = 0;
  int layoutMicros = 0;
  int paintMicros = 0;
}

enum _PhaseKind { buildScope, layout, paint }
