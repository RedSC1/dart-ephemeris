/// A reverse conversion landed on an inserted UTC leap second that cannot be
/// represented by [UtcJulianDate]'s uniform 86,400-second-day coordinate.
///
/// Use a calendar API capable of preserving `second: 60`, or move the request
/// away from the leap-second label. Returning either adjacent UTC coordinate
/// would silently change the physical instant by one second, so the split-JD
/// conversion rejects the value instead.
final class UtcLeapSecondRepresentationError implements Exception {
  const UtcLeapSecondRepresentationError();

  @override
  String toString() =>
      'UtcLeapSecondRepresentationError: the physical instant is an inserted '
      'UTC leap second, which UtcJulianDate cannot represent.';
}

/// An automatic time-scale inversion did not converge to the requested
/// physical coordinate.
final class TimeScaleConvergenceError implements Exception {
  const TimeScaleConvergenceError(this.message);

  final String message;

  @override
  String toString() => 'TimeScaleConvergenceError: $message';
}
