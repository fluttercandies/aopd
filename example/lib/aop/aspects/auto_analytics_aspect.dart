// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/analytics/auto_analytics_runtime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const String _vmEntryPoint = 'vm:entry-point';

@Aspect()
@pragma(_vmEntryPoint)
class AutoAnalyticsAspect {
  @pragma(_vmEntryPoint)
  const AutoAnalyticsAspect();

  @Call(
    'package:flutter/src/gestures/hit_test.dart',
    'HitTestTarget',
    '-handleEvent',
  )
  @pragma(_vmEntryPoint)
  void HitTestTarget_handleEvent(PointCut pointCut) {
    pointCut.proceed();
    final Object? target = pointCut.target;
    final PointerEvent event = pointCut.positionalParams![0] as PointerEvent;
    if (target is RenderObject) {
      AutoAnalyticsRuntime.instance.recordHitTestTarget(target, event);
    }
  }

  @Execute(
    'package:flutter/src/gestures/recognizer.dart',
    'GestureRecognizer',
    '-invokeCallback',
  )
  @pragma(_vmEntryPoint)
  dynamic GestureRecognizer_invokeCallback(PointCut pointCut) {
    final Object? eventName = pointCut.positionalParams![0];
    AutoAnalyticsRuntime.instance.recordGestureCallback(eventName.toString());
    return pointCut.proceed();
  }

  @Execute(
    'package:flutter/src/widgets/framework.dart',
    'RenderObjectElement',
    '-mount',
  )
  @pragma(_vmEntryPoint)
  void RenderObjectElement_mount(PointCut pointCut) {
    pointCut.proceed();
    final Element? element = pointCut.target as Element?;
    if (element != null && (kReleaseMode || kProfileMode)) {
      element.renderObject?.debugCreator = DebugCreator(element);
    }
  }

  @Execute(
    'package:flutter/src/widgets/framework.dart',
    'RenderObjectElement',
    '-update',
  )
  @pragma(_vmEntryPoint)
  void RenderObjectElement_update(PointCut pointCut) {
    pointCut.proceed();
    final Element? element = pointCut.target as Element?;
    if (element != null && (kReleaseMode || kProfileMode)) {
      element.renderObject?.debugCreator = DebugCreator(element);
    }
  }
}
