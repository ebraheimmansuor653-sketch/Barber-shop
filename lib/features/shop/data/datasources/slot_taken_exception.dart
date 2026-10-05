/// Thrown inside the booking transaction when the chosen slot is no
/// longer available — either this barber was just taken by someone else,
/// or the shop's chairs are all occupied at that time.
///
/// Caught by the existing generic `catch (e)` in `safeCall` and turned
/// into a `ServerFailure(e.toString())`; overriding [toString] keeps that
/// message clean instead of showing "Exception: ...".
class SlotTakenException implements Exception {
  final String message;
  const SlotTakenException(this.message);

  @override
  String toString() => message;
}
