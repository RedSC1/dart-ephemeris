import 'time_scale.dart';

/// A Julian date split into an integer day and a normalized day fraction.
///
/// Keeping the two parts separate avoids the precision loss caused by
/// subtracting or incrementing absolute Julian dates around 2.4 million.
/// Taiyin's split-Julian-Date C ABI preserves both parts across the FFI
/// boundary.
final class JulianDate<S extends TimeScale>
    implements Comparable<JulianDate<S>> {
  const JulianDate._(this.dayNumber, this.dayFraction);

  /// Creates a split value from an ordinary absolute Julian date.
  factory JulianDate.fromDouble(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    final day = value.floor();
    return JulianDate._(day, value - day);
  }

  /// Creates a value from two parts and normalizes the fraction to `[0, 1)`.
  factory JulianDate.fromParts(int dayNumber, double dayFraction) {
    if (!dayFraction.isFinite) {
      throw ArgumentError.value(dayFraction, 'dayFraction', 'must be finite');
    }
    final carry = dayFraction.floor();
    var normalizedDay = dayNumber + carry;
    var fraction = dayFraction - carry;
    if (fraction == 1.0) {
      normalizedDay += 1;
      fraction = 0.0;
    }
    return JulianDate._(normalizedDay, fraction == -0.0 ? 0.0 : fraction);
  }

  static const int microsecondsPerDay = 86400000000;
  static const int nanosecondsPerDay = 86400000000000;
  static const double secondsPerDay = 86400.0;

  /// The integral part of the absolute Julian date.
  final int dayNumber;

  /// The normalized fractional day in the range `[0, 1)`.
  final double dayFraction;

  /// Merges both parts into a single, precision-reducing `double`.
  double toDouble() => dayNumber + dayFraction;

  /// Returns a value offset by a Dart [Duration].
  ///
  /// [Duration] has microsecond resolution. Unlike `Duration.inSeconds`, this
  /// preserves its complete subsecond component.
  JulianDate<S> add(Duration duration) {
    final microseconds = duration.inMicroseconds;
    final wholeDays = microseconds ~/ microsecondsPerDay;
    final remainder = microseconds - wholeDays * microsecondsPerDay;
    return JulianDate<S>.fromParts(
      dayNumber + wholeDays,
      dayFraction + remainder / microsecondsPerDay,
    );
  }

  JulianDate<S> subtract(Duration duration) => add(-duration);

  /// Returns a value offset by a possibly fractional number of seconds.
  JulianDate<S> addSeconds(double seconds) {
    if (!seconds.isFinite) {
      throw ArgumentError.value(seconds, 'seconds', 'must be finite');
    }
    return JulianDate<S>.fromParts(
      dayNumber,
      dayFraction + seconds / secondsPerDay,
    );
  }

  /// Returns a value offset by an exact integer number of nanoseconds.
  JulianDate<S> addNanoseconds(int nanoseconds) {
    final wholeDays = nanoseconds ~/ nanosecondsPerDay;
    final remainder = nanoseconds - wholeDays * nanosecondsPerDay;
    return JulianDate<S>.fromParts(
      dayNumber + wholeDays,
      dayFraction + remainder / nanosecondsPerDay,
    );
  }

  /// `this - other`, expressed as fractional seconds.
  double secondsDifference(JulianDate<S> other) {
    return coordinateSecondsDifference(other);
  }

  /// Difference between the numeric coordinates of two possibly distinct
  /// time scales.
  ///
  /// This is useful for inspecting values such as TT−UT1. It does not by
  /// itself perform a time-scale conversion.
  double coordinateSecondsDifference<Other extends TimeScale>(
    JulianDate<Other> other,
  ) {
    final days = dayNumber - other.dayNumber;
    final fraction = dayFraction - other.dayFraction;
    return days * secondsPerDay + fraction * secondsPerDay;
  }

  /// `this - other`, rounded to Dart's microsecond [Duration] resolution.
  Duration difference(JulianDate<S> other) {
    return Duration(microseconds: (secondsDifference(other) * 1000000).round());
  }

  bool isBefore(JulianDate<S> other) => compareTo(other) < 0;
  bool isAfter(JulianDate<S> other) => compareTo(other) > 0;

  @override
  int compareTo(JulianDate<S> other) {
    final dayComparison = dayNumber.compareTo(other.dayNumber);
    if (dayComparison != 0) return dayComparison;
    return dayFraction.compareTo(other.dayFraction);
  }

  @override
  bool operator ==(Object other) {
    return other is JulianDate<S> &&
        other.dayNumber == dayNumber &&
        other.dayFraction == dayFraction;
  }

  @override
  int get hashCode => Object.hash(S, dayNumber, dayFraction);

  @override
  String toString() {
    return 'JulianDate<$S>($dayNumber + $dayFraction)';
  }
}

typedef UtcJulianDate = JulianDate<UtcScale>;
typedef TaiJulianDate = JulianDate<TaiScale>;
typedef TtJulianDate = JulianDate<TtScale>;
typedef Ut1JulianDate = JulianDate<Ut1Scale>;
typedef TdbJulianDate = JulianDate<TdbScale>;
typedef LocalMeanSolarJulianDate = JulianDate<LocalMeanSolarTimeScale>;
typedef LocalApparentSolarJulianDate = JulianDate<LocalApparentSolarTimeScale>;
