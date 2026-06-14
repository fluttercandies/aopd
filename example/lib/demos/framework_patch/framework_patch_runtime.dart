/// One clamp event: an oversized scaled font size the patch reined in.
class ClampEvent {
  const ClampEvent({
    required this.fontSize,
    required this.original,
    required this.clamped,
  });

  final double fontSize;
  final double original;
  final double clamped;
}

/// State for the framework-patch demo.
///
/// The aspect weaves Flutter's own `_LinearTextScaler.scale` (a private SDK
/// method) to clamp runaway accessibility text scaling app-wide -- the kind of
/// framework fix teams normally can't do without forking Flutter. Crucially the
/// patch is GATED: when [enabled] is false the advice just proceed()s, so it has
/// zero effect on the rest of the app. That gate is also what keeps every other
/// demo and test unaffected by a hook on such a hot method.
///
/// IMPORTANT: `scale` runs during layout/paint, so the advice must NOT trigger a
/// widget rebuild from here (that throws "Build scheduled during frame"). The
/// clamp record is therefore plain fields with NO listener notification; the
/// page reads them in its normal setState-driven build.
class FrameworkPatchRuntime {
  FrameworkPatchRuntime._();

  static final FrameworkPatchRuntime instance = FrameworkPatchRuntime._();

  /// Off by default. The aspect is a no-op passthrough until a human turns it
  /// on -- the safe way to ship a framework patch (flag-gated rollout).
  bool enabled = false;

  /// Cap applied when [enabled]: scaled size may not exceed fontSize * this.
  double maxScaleFactor = 1.6;

  /// How many scale() calls the patch has clamped since the last reset. A plain
  /// counter -- updated from inside the woven (layout-phase) advice, so it must
  /// never notify a listener.
  int clampCount = 0;

  /// The most recent clamp, for display. Plain field, same reason.
  ClampEvent? lastClamp;

  void logClamp(double fontSize, double original, double clamped) {
    clampCount += 1;
    lastClamp = ClampEvent(
      fontSize: fontSize,
      original: original,
      clamped: clamped,
    );
  }

  void reset() {
    enabled = false;
    maxScaleFactor = 1.6;
    clampCount = 0;
    lastClamp = null;
  }
}
