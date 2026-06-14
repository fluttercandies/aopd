// ignore_for_file: non_constant_identifier_names

import 'package:aopd/aopd.dart';
import 'package:example/demos/framework_patch/framework_patch_runtime.dart';

const String _vmEntryPoint = 'vm:entry-point';

/// Patches a Flutter FRAMEWORK method without forking the SDK -- the original
/// motivation behind AspectD ("remove invasive framework code").
///
/// Target: `_LinearTextScaler.scale` in package:flutter/src/painting/
/// text_scaler.dart. It returns `fontSize * textScaleFactor`; when the user's
/// accessibility font scale is extreme, layouts overflow. This advice clamps
/// the scaled size app-wide so a single hook fixes every Text in the app.
///
/// Safety: the patch is flag-gated (FrameworkPatchRuntime.enabled, default
/// false). While off, the advice just proceed()s -- a transparent no-op -- so
/// hooking this very hot, private SDK method costs nothing and cannot affect
/// other demos. This mirrors how a real framework patch is rolled out behind a
/// switch.
@Aspect()
@pragma(_vmEntryPoint)
class FrameworkPatchAspect {
  @pragma(_vmEntryPoint)
  const FrameworkPatchAspect();

  @Execute(
    'package:flutter/src/painting/text_scaler.dart',
    '_LinearTextScaler',
    '-scale',
  )
  @pragma(_vmEntryPoint)
  dynamic LinearTextScaler_scale(PointCut pointCut) {
    final Object? scaled = pointCut.proceed();
    final FrameworkPatchRuntime runtime = FrameworkPatchRuntime.instance;
    if (!runtime.enabled || scaled is! double) {
      return scaled;
    }
    final List<dynamic>? params = pointCut.positionalParams;
    final double fontSize =
        params != null && params.isNotEmpty && params[0] is double
            ? params[0] as double
            : 0;
    final double cap = fontSize * runtime.maxScaleFactor;
    if (scaled > cap) {
      runtime.logClamp(fontSize, scaled, cap);
      return cap;
    }
    return scaled;
  }
}
