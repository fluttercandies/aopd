// ignore_for_file: non_constant_identifier_names

import 'dart:ui' as ui;

import 'package:aopd/aopd.dart';
import 'package:example/demos/performance/performance_runtime.dart';
import 'package:flutter/widgets.dart';

const String _vmEntryPoint = 'vm:entry-point';

@Aspect()
@pragma(_vmEntryPoint)
class PerformanceAspect {
  @pragma(_vmEntryPoint)
  const PerformanceAspect();

  @Execute(
    'package:flutter/src/widgets/framework.dart',
    'StatefulElement',
    '-performRebuild',
  )
  @pragma(_vmEntryPoint)
  void StatefulElement_performRebuild(PointCut pointCut) {
    final Element? element = pointCut.target as Element?;
    if (element == null) {
      pointCut.proceed();
      return;
    }
    PerformanceRuntime.instance.onPerformRebuild(
      element,
      () => pointCut.proceed(),
    );
  }

  @Execute(
    'package:flutter/src/widgets/framework.dart',
    'BuildOwner',
    '-buildScope',
  )
  @pragma(_vmEntryPoint)
  void BuildOwner_buildScope(PointCut pointCut) {
    PerformanceRuntime.instance.onBuildScope(() => pointCut.proceed());
  }

  @Execute(
    'package:flutter/src/rendering/object.dart',
    'PipelineOwner',
    '-flushLayout',
  )
  @pragma(_vmEntryPoint)
  void PipelineOwner_flushLayout(PointCut pointCut) {
    PerformanceRuntime.instance.onFlushLayout(() => pointCut.proceed());
  }

  @Execute(
    'package:flutter/src/rendering/object.dart',
    'PipelineOwner',
    '-flushPaint',
  )
  @pragma(_vmEntryPoint)
  void PipelineOwner_flushPaint(PointCut pointCut) {
    PerformanceRuntime.instance.onFlushPaint(() => pointCut.proceed());
  }

  @Execute(
    'package:flutter/src/painting/image_cache.dart',
    'ImageCache',
    '-putIfAbsent',
  )
  @pragma(_vmEntryPoint)
  dynamic ImageCache_putIfAbsent(PointCut pointCut) {
    final List<dynamic>? params = pointCut.positionalParams;
    final Object? key = params != null && params.isNotEmpty ? params[0] : null;
    bool cacheMiss = false;

    if (params != null && params.length >= 2) {
      final Object? loader = params[1];
      if (loader is ImageStreamCompleter Function()) {
        final ImageStreamCompleter Function() typedLoader = loader;
        params[1] = () {
          cacheMiss = true;
          return typedLoader();
        };
      }
    }

    return PerformanceRuntime.instance.onImageCachePutIfAbsent(
      key: key,
      cacheMissGetter: () => cacheMiss,
      proceed: () => pointCut.proceed(),
    );
  }

  @Execute(
    'package:flutter/src/painting/binding.dart',
    'PaintingBinding',
    '-instantiateImageCodec',
  )
  @pragma(_vmEntryPoint)
  Future<ui.Codec> PaintingBinding_instantiateImageCodec(PointCut pointCut) {
    return PerformanceRuntime.instance.onInstantiateImageCodec<ui.Codec>(
      apiName: 'instantiateImageCodec',
      source: _firstPositionalParam(pointCut),
      proceed: () => pointCut.proceed() as Future<ui.Codec>,
    );
  }

  @Execute(
    'package:flutter/src/painting/binding.dart',
    'PaintingBinding',
    '-instantiateImageCodecWithSize',
  )
  @pragma(_vmEntryPoint)
  Future<ui.Codec> PaintingBinding_instantiateImageCodecWithSize(
    PointCut pointCut,
  ) {
    return PerformanceRuntime.instance.onInstantiateImageCodec<ui.Codec>(
      apiName: 'instantiateImageCodecWithSize',
      source: _firstPositionalParam(pointCut),
      proceed: () => pointCut.proceed() as Future<ui.Codec>,
    );
  }

  @Execute(
    'package:flutter/src/painting/binding.dart',
    'PaintingBinding',
    '-instantiateImageCodecFromBuffer',
  )
  @pragma(_vmEntryPoint)
  Future<ui.Codec> PaintingBinding_instantiateImageCodecFromBuffer(
    PointCut pointCut,
  ) {
    return PerformanceRuntime.instance.onInstantiateImageCodec<ui.Codec>(
      apiName: 'instantiateImageCodecFromBuffer',
      source: _firstPositionalParam(pointCut),
      proceed: () => pointCut.proceed() as Future<ui.Codec>,
    );
  }

  Object? _firstPositionalParam(PointCut pointCut) {
    final List<dynamic>? params = pointCut.positionalParams;
    return params != null && params.isNotEmpty ? params[0] : null;
  }
}
