enum PerformanceEventKind { build, frame, phase, image }

class PerformanceEvent {
  const PerformanceEvent({
    required this.kind,
    required this.title,
    required this.message,
    required this.isIssue,
    required this.time,
    this.routeName,
  });

  final PerformanceEventKind kind;
  final String title;
  final String message;
  final bool isIssue;
  final DateTime time;
  final String? routeName;
}

class BuildPerformanceEvent {
  const BuildPerformanceEvent({
    required this.widgetType,
    required this.durationMicros,
    required this.rebuildCount,
    this.file,
    this.line,
    this.routeName,
  });

  static const int slowThresholdMicros = 8000;

  final String widgetType;
  final int durationMicros;
  final int rebuildCount;
  final String? file;
  final int? line;
  final String? routeName;

  bool get isSlowBuild => durationMicros >= slowThresholdMicros;
  bool get isExcessiveRebuild => rebuildCount >= 5;

  String get contributorLabel {
    final String location =
        file == null ? '' : ' ${_shortFile(file!)}:${line ?? 0}';
    return '$widgetType$location ${_formatMicros(durationMicros)} x$rebuildCount';
  }

  PerformanceEvent toPerformanceEvent() {
    final String location = file == null
        ? 'source location unavailable'
        : '${_shortFile(file!)}:$line';
    final String route = routeName == null ? 'unknown route' : routeName!;
    return PerformanceEvent(
      kind: PerformanceEventKind.build,
      title: isSlowBuild ? 'Slow widget build' : 'Repeated rebuild',
      message: '$widgetType\n'
          'duration=${_formatMicros(durationMicros)}\n'
          'rebuilds in frame=$rebuildCount\n'
          'location=$location\n'
          'route=$route',
      isIssue: isSlowBuild || isExcessiveRebuild,
      time: DateTime.now(),
      routeName: routeName,
    );
  }
}

class FramePerformanceEvent {
  const FramePerformanceEvent({
    required this.frameSequence,
    required this.totalMicros,
    required this.buildMicros,
    required this.rasterMicros,
    required this.droppedFrames60Hz,
    required this.isOver60HzBudget,
    required this.isOver120HzBudget,
    this.routeName,
  });

  final int frameSequence;
  final int totalMicros;
  final int buildMicros;
  final int rasterMicros;
  final int droppedFrames60Hz;
  final bool isOver60HzBudget;
  final bool isOver120HzBudget;
  final String? routeName;

  PerformanceEvent toPerformanceEvent() {
    return PerformanceEvent(
      kind: PerformanceEventKind.frame,
      title:
          isOver60HzBudget ? 'Dropped frame risk' : 'Frame over 120Hz budget',
      message: 'frame=#$frameSequence\n'
          'total=${_formatMicros(totalMicros)}\n'
          'build=${_formatMicros(buildMicros)}\n'
          'raster=${_formatMicros(rasterMicros)}\n'
          'estimated dropped frames at 60Hz=$droppedFrames60Hz\n'
          'route=${routeName ?? 'unknown route'}',
      isIssue: isOver60HzBudget || isOver120HzBudget,
      time: DateTime.now(),
      routeName: routeName,
    );
  }
}

class FramePhasePerformanceEvent {
  const FramePhasePerformanceEvent({
    required this.buildScopeMicros,
    required this.layoutMicros,
    required this.paintMicros,
    required this.totalMicros,
    required this.isOver60HzBudget,
    required this.isOver120HzBudget,
    required this.suspectWidgets,
    this.routeName,
  });

  final int buildScopeMicros;
  final int layoutMicros;
  final int paintMicros;
  final int totalMicros;
  final bool isOver60HzBudget;
  final bool isOver120HzBudget;
  final List<String> suspectWidgets;
  final String? routeName;

  PerformanceEvent toPerformanceEvent() {
    final String suspects =
        suspectWidgets.isEmpty ? 'none' : suspectWidgets.take(4).join('\n');
    return PerformanceEvent(
      kind: PerformanceEventKind.phase,
      title: isOver60HzBudget ? 'Slow UI pipeline phase' : 'Phase over budget',
      message: 'buildScope=${_formatMicros(buildScopeMicros)}\n'
          'layout=${_formatMicros(layoutMicros)}\n'
          'paint=${_formatMicros(paintMicros)}\n'
          'total=${_formatMicros(totalMicros)}\n'
          'route=${routeName ?? 'unknown route'}\n'
          'suspects=$suspects',
      isIssue: isOver60HzBudget || isOver120HzBudget,
      time: DateTime.now(),
      routeName: routeName,
    );
  }
}

enum ImagePerformanceEventType { cacheHit, cacheMiss, decode }

class ImagePerformanceEvent {
  const ImagePerformanceEvent({
    required this.type,
    required this.durationMicros,
    required this.isSlow,
    this.key,
    this.codecApi,
    this.routeName,
    this.error,
  });

  static const int slowCacheLookupMicros = 3000;
  static const int slowDecodeMicros = 4000;

  final ImagePerformanceEventType type;
  final int durationMicros;
  final bool isSlow;
  final Object? key;
  final String? codecApi;
  final String? routeName;
  final Object? error;

  PerformanceEvent toPerformanceEvent() {
    return PerformanceEvent(
      kind: PerformanceEventKind.image,
      title: switch (type) {
        ImagePerformanceEventType.cacheHit => 'Image cache hit',
        ImagePerformanceEventType.cacheMiss => 'Image cache miss',
        ImagePerformanceEventType.decode => 'Image decode',
      },
      message: 'duration=${_formatMicros(durationMicros)}\n'
          'slow=$isSlow\n'
          'api=${codecApi ?? 'image cache'}\n'
          'key=${_shortValue(key)}\n'
          'route=${routeName ?? 'unknown route'}'
          '${error == null ? '' : '\nerror=$error'}',
      isIssue: isSlow ||
          type == ImagePerformanceEventType.cacheMiss ||
          error != null,
      time: DateTime.now(),
      routeName: routeName,
    );
  }
}

String _formatMicros(int micros) {
  if (micros >= 1000) {
    return '${(micros / 1000).toStringAsFixed(2)}ms';
  }
  return '${micros}us';
}

String _shortFile(String file) {
  final String normalized = file.replaceAll(r'\', '/');
  final int index = normalized.lastIndexOf('/');
  return index >= 0 ? normalized.substring(index + 1) : normalized;
}

String _shortValue(Object? value) {
  if (value == null) {
    return 'none';
  }
  final String text = value.toString().replaceAll('\n', ' ');
  return text.length <= 120 ? text : '${text.substring(0, 117)}...';
}
