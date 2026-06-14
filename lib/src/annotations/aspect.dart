/// Marks a class as an AOP aspect container.
@pragma('vm:entry-point')
class Aspect {
  /// Creates an aspect marker annotation.
  const factory Aspect() = Aspect._;

  @pragma('vm:entry-point')
  const Aspect._();
}
