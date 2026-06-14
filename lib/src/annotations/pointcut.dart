/// Runtime context passed to AOP advice methods.
@pragma('vm:entry-point')
class PointCut {
  /// Creates a pointcut context.
  @pragma('vm:entry-point')
  PointCut(
    this.sourceInfos,
    this.target,
    this.function,
    this.stubKey,
    this.positionalParams,
    this.namedParams,
    this.members,
    this.annotations, {
    this.proceedClosure,
  });

  static PointCut pointCut() {
    return PointCut(null, null, null, null, null, null, null, null);
  }

  /// Source information such as file and line number for a call.
  final Map<dynamic, dynamic>? sourceInfos;

  /// Receiver target for a call, for example `x` in `x.foo()`.
  final Object? target;

  /// Function name for a call, for example `foo` in `x.foo()`.
  final String? function;

  /// Unique key used by generated proceed stubs.
  final String? stubKey;

  /// Positional parameters for a call.
  final List<dynamic>? positionalParams;

  /// Named parameters for a call.
  final Map<dynamic, dynamic>? namedParams;

  /// Class members captured by the transform.
  ///
  /// In call mode these are caller members. In execute mode these are members
  /// from the execution class.
  final Map<dynamic, dynamic>? members;

  /// Class annotations captured by the transform.
  ///
  /// In call mode these are caller annotations. In execute mode these are
  /// annotations from the execution class.
  final Map<dynamic, dynamic>? annotations;

  /// Direct reference to the original implementation (M5.4).
  ///
  /// The compiler transform sets this at each woven site to a closure that
  /// performs the original call/body/field-read, reading
  /// [positionalParams]/[namedParams] so advice can mutate arguments before
  /// calling [proceed]. Each woven site is therefore self-contained -- there is
  /// no central stub-dispatch table -- which makes weaving incremental/
  /// hot-reload safe. It is null only for a PointCut that was never woven.
  final Object? Function(PointCut pointCut)? proceedClosure;

  /// Calls the original implementation.
  ///
  /// Invokes [proceedClosure] (set by the compiler at the woven site). Returns
  /// null only when no closure is present (an un-woven PointCut).
  @pragma('vm:entry-point')
  Object? proceed() {
    final Object? Function(PointCut pointCut)? closure = proceedClosure;
    if (closure != null) {
      return closure(this);
    }
    return null;
  }
}
