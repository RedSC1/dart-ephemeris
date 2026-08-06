import 'julian_date.dart';
import 'time_scale.dart';

/// A timezone- and time-scale-neutral astronomical calendar date and time.
///
/// Years use astronomical numbering: year `0` is 1 BCE, `-1` is 2 BCE, and
/// so on. Dates through 1582-10-04 use the Julian calendar; dates from
/// 1582-10-15 use the Gregorian calendar. The historical gap is rejected.
///
/// Subseconds are stored as an exact integer nanosecond component. Converting
/// to Taiyin's C calendar structure turns [second] and [nanosecond] into one
/// fractional `double` second.
///
/// ## Julian-day convention
///
/// Every Julian day produced or consumed by this class is a **standard Julian
/// day**: the true instant on a UTC timeline, never tied to a local civil
/// timezone. This package has no "Beijing-time Julian day" or other
/// zone-labelled Julian day variant.
///
/// A civil value alone does not identify an instant. Its relationship to a
/// standard Julian day is decided by the caller-supplied `utcOffsetHours`
/// argument of [toJulianDay], [toJ2000], [toJulianDate], [fromJulianDay],
/// and [fromJulianDate]:
///
/// * [toJulianDay] / [toJ2000] / [toJulianDate] convert a civil value
///   expressed in `utcOffsetHours` into the standard Julian day of the same
///   instant (the offset is subtracted).
/// * [fromJulianDay] / [fromJulianDate] convert a standard Julian day into
///   the civil value shown by a clock at `utcOffsetHours` (the offset is
///   added).
///
/// [toJulianDate] and [fromJulianDate] operate on the split representation
/// and keep full precision; the scalar [toJulianDay] / [fromJulianDay]
/// merge through a `double` and are exact only to about 40 microseconds.
///
/// The uniform 86,400-second-day split cannot display a leap second
/// (`second: 60`): such a value rolls over to the next day, and a non-zero
/// `utcOffsetHours` applies the same rollover before the offset shift. Read
/// leap-second instants as UTC (offset 0) if their exact display matters.
///
/// An omitted offset (0) treats the civil fields as a UTC reading. The
/// offset is a conversion argument, never a stored property: two civil
/// values with the same fields are the same wall-clock reading regardless of
/// how each is later converted to an instant.
final class AstroDateTime implements Comparable<AstroDateTime> {
  factory AstroDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int nanosecond = 0,
  ]) {
    _validate(year, month, day, hour, minute, second, nanosecond);
    return AstroDateTime._(year, month, day, hour, minute, second, nanosecond);
  }

  const AstroDateTime._(
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
    this.second,
    this.nanosecond,
  );

  /// Preserves Dart's millisecond and microsecond components.
  factory AstroDateTime.fromDateTime(DateTime value) {
    return AstroDateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond * 1000000 + value.microsecond * 1000,
    );
  }

  /// Converts a standard Julian day to a civil value.
  ///
  /// [value] is a standard Julian day (a true UTC instant). [utcOffsetHours]
  /// selects the civil timezone in which the result is displayed: the clock
  /// reads the instant plus that offset. An omitted offset shows the value as
  /// UTC. See the Julian-day convention documented on this class.
  factory AstroDateTime.fromJulianDay(
    double value, {
    double utcOffsetHours = 0,
  }) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    _requireFiniteOffset(utcOffsetHours);
    return AstroDateTime.fromJulianDate(
      JulianDate<TtScale>.fromDouble(value + utcOffsetHours / 24),
    );
  }

  /// Converts a number of days relative to J2000.0.
  ///
  /// [days] is a standard Julian-day offset from J2000.0. [utcOffsetHours]
  /// selects the civil timezone in which the result is displayed, exactly as
  /// in [fromJulianDay]. See the Julian-day convention documented on this
  /// class.
  factory AstroDateTime.fromJ2000(double days, {double utcOffsetHours = 0}) {
    if (!days.isFinite) {
      throw ArgumentError.value(days, 'days', 'must be finite');
    }
    _requireFiniteOffset(utcOffsetHours);
    return AstroDateTime.fromJulianDate(
      JulianDate<TtScale>.fromParts(j2000DayNumber, days),
      utcOffsetHours: utcOffsetHours,
    );
  }

  /// Converts a split Julian date to a civil value without first collapsing
  /// it to one double.
  ///
  /// [value] is a standard Julian day (a true UTC instant). [utcOffsetHours]
  /// selects the civil timezone in which the result is displayed: the clock
  /// reads the instant plus that offset. An omitted offset shows the value as
  /// UTC. See the Julian-day convention documented on this class.
  static AstroDateTime fromJulianDate<S extends TimeScale>(
    JulianDate<S> value, {
    double utcOffsetHours = 0,
  }) {
    _requireFiniteOffset(utcOffsetHours);
    if (utcOffsetHours != 0) {
      value = value.addSeconds(utcOffsetHours * 3600);
    }
    var z = value.dayNumber;
    var shiftedFraction = value.dayFraction + 0.5;
    final carry = shiftedFraction.floor();
    z += carry;
    shiftedFraction -= carry;

    var nanosecondsOfDay = (shiftedFraction * JulianDate.nanosecondsPerDay)
        .round();
    if (nanosecondsOfDay >= JulianDate.nanosecondsPerDay) {
      nanosecondsOfDay -= JulianDate.nanosecondsPerDay;
      z += 1;
    } else if (nanosecondsOfDay < 0) {
      nanosecondsOfDay += JulianDate.nanosecondsPerDay;
      z -= 1;
    }

    var a = z;
    if (z >= 2299161) {
      final alpha = ((z - 1867216.25) / 36524.25).floor();
      a = z + 1 + alpha - alpha ~/ 4;
    }

    final b = a + 1524;
    final c = ((b - 122.1) / 365.25).floor();
    final d = (365.25 * c).floor();
    final e = ((b - d) / 30.6001).floor();

    final day = b - d - (30.6001 * e).floor();
    final month = e < 14 ? e - 1 : e - 13;
    final year = month > 2 ? c - 4716 : c - 4715;

    final hour = nanosecondsOfDay ~/ _nanosecondsPerHour;
    nanosecondsOfDay -= hour * _nanosecondsPerHour;
    final minute = nanosecondsOfDay ~/ _nanosecondsPerMinute;
    nanosecondsOfDay -= minute * _nanosecondsPerMinute;
    final second = nanosecondsOfDay ~/ _nanosecondsPerSecond;
    final nanosecond = nanosecondsOfDay - second * _nanosecondsPerSecond;

    return AstroDateTime._(year, month, day, hour, minute, second, nanosecond);
  }

  static const int j2000DayNumber = 2451545;
  static const double j2000 = 2451545.0;
  static const int _nanosecondsPerSecond = 1000000000;
  static const int _nanosecondsPerMinute = 60 * _nanosecondsPerSecond;
  static const int _nanosecondsPerHour = 60 * _nanosecondsPerMinute;

  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;

  /// Whole second, normally `0–59`; `60` represents a UTC leap second.
  final int second;

  /// Nanoseconds after [second], in the range `0–999,999,999`.
  final int nanosecond;

  bool get isBce => year <= 0;
  int? get bceYear => isBce ? 1 - year : null;

  /// Fractional second used by Taiyin's native calendar structure.
  double get fractionalSecond => second + nanosecond / 1000000000.0;

  /// ISO weekday number: Monday is 1 and Sunday is 7.
  int get weekday {
    final value = toJulianDate<TtScale>();
    final julianDayNumber = value.dayNumber + (value.dayFraction + 0.5).floor();
    return julianDayNumber % 7 + 1;
  }

  /// Interprets this calendar value in [S] and returns a split Julian date.
  ///
  /// [utcOffsetHours] is the civil timezone in which this value is
  /// expressed; the returned Julian date subtracts that offset, so it names
  /// the true UTC instant at full split precision. An omitted offset leaves
  /// the value unchanged. See the Julian-day convention documented on this
  /// class.
  ///
  /// This method does not convert between time scales. A UTC calendar value
  /// must go through Taiyin's UTC/TAI/TT conversion API rather than merely
  /// being relabeled as [TtScale].
  JulianDate<S> toJulianDate<S extends TimeScale>({double utcOffsetHours = 0}) {
    _requireFiniteOffset(utcOffsetHours);
    var adjustedYear = year;
    var adjustedMonth = month;
    if (adjustedMonth <= 2) {
      adjustedYear -= 1;
      adjustedMonth += 12;
    }

    var correction = 0;
    if (_isGregorianDate(year, month, day)) {
      final century = adjustedYear ~/ 100;
      correction = 2 - century + century ~/ 4;
    }

    final midnight =
        (365.25 * (adjustedYear + 4716)).floor() +
        (30.6001 * (adjustedMonth + 1)).floor() +
        day +
        correction -
        1524.5;
    final integerPart = midnight.floor();
    final nanosecondsOfDay =
        hour * _nanosecondsPerHour +
        minute * _nanosecondsPerMinute +
        second * _nanosecondsPerSecond +
        nanosecond;

    final value = JulianDate<S>.fromParts(
      integerPart,
      midnight - integerPart + nanosecondsOfDay / JulianDate.nanosecondsPerDay,
    );
    if (utcOffsetHours == 0) {
      return value;
    }
    return value.addSeconds(-utcOffsetHours * 3600);
  }

  /// Converts this civil value to a standard Julian day.
  ///
  /// [utcOffsetHours] is the civil timezone in which this value is
  /// expressed; the returned Julian day subtracts that offset, so it names
  /// the true UTC instant. An omitted offset treats the civil fields as a
  /// UTC reading. See the Julian-day convention documented on this class.
  ///
  /// This merge has roughly 40 microseconds of representational resolution
  /// around the present epoch. Prefer [toJulianDate] for Dart-side arithmetic.
  double toJulianDay({double utcOffsetHours = 0}) {
    return toJulianDate<TtScale>(utcOffsetHours: utcOffsetHours).toDouble();
  }

  /// Returns the number of days from J2000.0 to this civil value's standard
  /// Julian day without a large subtraction.
  ///
  /// [utcOffsetHours] is the civil timezone in which this value is
  /// expressed; the offset is subtracted exactly as in [toJulianDay]. An
  /// omitted offset treats the civil fields as a UTC reading.
  double toJ2000({double utcOffsetHours = 0}) {
    final value = toJulianDate<TtScale>(utcOffsetHours: utcOffsetHours);
    return value.dayNumber - j2000DayNumber + value.dayFraction;
  }

  /// Uniform 86,400-second-day arithmetic preserving microseconds.
  AstroDateTime add(Duration duration) {
    final value = toJulianDate<TtScale>().add(duration);
    return AstroDateTime.fromJulianDate(value);
  }

  AstroDateTime subtract(Duration duration) => add(-duration);

  /// Uniform-day arithmetic with a possibly fractional second offset.
  AstroDateTime addSeconds(double seconds) {
    final value = toJulianDate<TtScale>().addSeconds(seconds);
    return AstroDateTime.fromJulianDate(value);
  }

  /// Uniform-day arithmetic preserving an integer nanosecond offset.
  AstroDateTime addNanoseconds(int nanoseconds) {
    final value = toJulianDate<TtScale>().addNanoseconds(nanoseconds);
    return AstroDateTime.fromJulianDate(value);
  }

  /// `this - other`, expressed as fractional seconds.
  double secondsDifference(AstroDateTime other) {
    return toJulianDate<TtScale>().secondsDifference(
      other.toJulianDate<TtScale>(),
    );
  }

  /// `this - other`, rounded to Dart's microsecond [Duration] resolution.
  Duration difference(AstroDateTime other) {
    return toJulianDate<TtScale>().difference(other.toJulianDate<TtScale>());
  }

  /// Converts to a UTC Dart [DateTime].
  ///
  /// Dart cannot represent a leap second or sub-microsecond precision. The
  /// conversion throws in those cases unless [allowNanosecondTruncation] is
  /// true for the latter.
  DateTime toDateTimeUtc({bool allowNanosecondTruncation = false}) {
    if (second == 60) {
      throw StateError('Dart DateTime cannot represent a leap second.');
    }
    if (!allowNanosecondTruncation && nanosecond % 1000 != 0) {
      throw StateError(
        'Dart DateTime cannot represent sub-microsecond precision.',
      );
    }
    final microseconds = nanosecond ~/ 1000;
    return DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
      microseconds ~/ 1000,
      microseconds % 1000,
    );
  }

  bool isBefore(AstroDateTime other) => compareTo(other) < 0;
  bool isAfter(AstroDateTime other) => compareTo(other) > 0;

  @override
  int compareTo(AstroDateTime other) {
    return toJulianDate<TtScale>().compareTo(other.toJulianDate<TtScale>());
  }

  @override
  bool operator ==(Object other) {
    return other is AstroDateTime &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.hour == hour &&
        other.minute == minute &&
        other.second == second &&
        other.nanosecond == nanosecond;
  }

  @override
  int get hashCode {
    return Object.hash(year, month, day, hour, minute, second, nanosecond);
  }

  @override
  String toString() {
    final yearText = year < 0
        ? '-${(-year).toString().padLeft(4, '0')}'
        : year.toString().padLeft(4, '0');
    final monthText = month.toString().padLeft(2, '0');
    final dayText = day.toString().padLeft(2, '0');
    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');
    final secondText = second.toString().padLeft(2, '0');
    final fractionText = nanosecond == 0
        ? ''
        : '.${nanosecond.toString().padLeft(9, '0').replaceFirst(RegExp(r'0+$'), '')}';
    return '$yearText-$monthText-${dayText}T'
        '$hourText:$minuteText:$secondText$fractionText';
  }

  static void _requireFiniteOffset(double utcOffsetHours) {
    if (!utcOffsetHours.isFinite) {
      throw ArgumentError.value(
        utcOffsetHours,
        'utcOffsetHours',
        'must be finite',
      );
    }
  }

  static void _validate(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
    int nanosecond,
  ) {
    if (month < 1 || month > 12) {
      throw RangeError.range(month, 1, 12, 'month');
    }
    if (_isGregorianGap(year, month, day)) {
      throw ArgumentError.value(
        '$year-$month-$day',
        'date',
        'does not exist in the Julian/Gregorian cutover calendar',
      );
    }
    final maximumDay = _daysInMonth(year, month, day);
    if (day < 1 || day > maximumDay) {
      throw RangeError.range(day, 1, maximumDay, 'day');
    }
    if (hour < 0 || hour > 23) {
      throw RangeError.range(hour, 0, 23, 'hour');
    }
    if (minute < 0 || minute > 59) {
      throw RangeError.range(minute, 0, 59, 'minute');
    }
    if (second < 0 || second > 60) {
      throw RangeError.range(second, 0, 60, 'second');
    }
    if (second == 60 && (hour != 23 || minute != 59)) {
      throw ArgumentError.value(
        second,
        'second',
        'a leap second is only valid at 23:59',
      );
    }
    if (nanosecond < 0 || nanosecond >= _nanosecondsPerSecond) {
      throw RangeError.range(
        nanosecond,
        0,
        _nanosecondsPerSecond - 1,
        'nanosecond',
      );
    }
  }

  static int _daysInMonth(int year, int month, int day) {
    if (month == 2) {
      return _isLeapYear(year, month, day) ? 29 : 28;
    }
    return const {4, 6, 9, 11}.contains(month) ? 30 : 31;
  }

  static bool _isLeapYear(int year, int month, int day) {
    if (!_isGregorianDate(year, month, day)) return year % 4 == 0;
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  static bool _isGregorianDate(int year, int month, int day) {
    return year > 1582 ||
        (year == 1582 && (month > 10 || (month == 10 && day >= 15)));
  }

  static bool _isGregorianGap(int year, int month, int day) {
    return year == 1582 && month == 10 && day >= 5 && day <= 14;
  }
}
