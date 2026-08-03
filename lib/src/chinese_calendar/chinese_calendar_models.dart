/// Chinese-calendar models backed by the Taiyin Chinese-calendar module.
library;

import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// Rule profile applied when constructing a Chinese calendar.
enum TaiyinChineseCalendarRuleMode {
  /// Historical China: mean solar terms and new moons with compressed
  /// day-correction tables and a fixed UTC+8 civil boundary.
  historicalChina(0),

  /// Astronomical: always uses Taiyin's precise 定气 (solar terms) and 定朔
  /// (new moons); the civil boundary is a fixed UTC offset or mean-solar
  /// meridian.
  astronomical(1);

  const TaiyinChineseCalendarRuleMode(this.id);

  final int id;
}

/// How the civil (local) day boundary is determined.
enum TaiyinChineseCalendarDayBoundaryMode {
  /// The civil day starts at a fixed UTC offset (e.g. UTC+8 = 480 minutes).
  fixedUtcOffset(0),

  /// The civil day starts at the mean-solar meridian through the configured
  /// longitude.
  meanSolarMeridian(1);

  const TaiyinChineseCalendarDayBoundaryMode(this.id);

  final int id;
}

/// Historical exceptional month names used by the `historicalChina` profile.
enum TaiyinChineseCalendarMonthName {
  normal(0),
  thirteen(1),
  laterNine(2),
  altTwelve(3),
  altOne(4);

  const TaiyinChineseCalendarMonthName(this.id);

  final int id;

  static TaiyinChineseCalendarMonthName fromId(int id) {
    for (final name in values) {
      if (name.id == id) return name;
    }
    throw ArgumentError.value(id, 'id', 'unknown Chinese month name');
  }
}

/// Configuration for a Chinese-calendar context.
final class TaiyinChineseCalendarConfig {
  const TaiyinChineseCalendarConfig({
    this.ruleMode = TaiyinChineseCalendarRuleMode.astronomical,
    this.dayBoundaryMode = TaiyinChineseCalendarDayBoundaryMode.fixedUtcOffset,
    this.utcOffsetMinutes = 480,
    this.calendarMeridianDegrees = 0,
  });

  /// Default astronomical profile with a fixed UTC+8 civil day.
  const TaiyinChineseCalendarConfig.astronomical() : this();

  /// Astronomical profile with a fixed [utcOffsetMinutes] civil boundary.
  const TaiyinChineseCalendarConfig.utcOffset(int utcOffsetMinutes)
    : this(
        dayBoundaryMode: TaiyinChineseCalendarDayBoundaryMode.fixedUtcOffset,
        utcOffsetMinutes: utcOffsetMinutes,
      );

  /// Astronomical profile with a mean-solar-meridian civil boundary at
  /// [longitudeDegrees].
  const TaiyinChineseCalendarConfig.meridian(double longitudeDegrees)
    : this(
        dayBoundaryMode: TaiyinChineseCalendarDayBoundaryMode.meanSolarMeridian,
        calendarMeridianDegrees: longitudeDegrees,
      );

  final TaiyinChineseCalendarRuleMode ruleMode;
  final TaiyinChineseCalendarDayBoundaryMode dayBoundaryMode;

  /// Civil-day offset from UTC in minutes, meaningful for [fixedUtcOffset].
  final int utcOffsetMinutes;

  /// Longitude used for the mean-solar-meridian civil boundary.
  final double calendarMeridianDegrees;
}

/// A proleptic Gregorian (solar) calendar date.
final class TaiyinSolarDate {
  const TaiyinSolarDate({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;
}

/// A Chinese lunar calendar date.
final class TaiyinLunarDate {
  const TaiyinLunarDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeap,
    required this.monthDays,
    this.monthName = TaiyinChineseCalendarMonthName.normal,
  });

  final int year;
  final int month;
  final int day;
  final bool isLeap;

  /// Number of days in this lunar month (29 or 30).
  final int monthDays;

  /// Historical exceptional month name, when applicable.
  final TaiyinChineseCalendarMonthName monthName;
}

/// A solar-term (节气) crossing.
final class TaiyinChineseSolarTermEvent {
  const TaiyinChineseSolarTermEvent({
    required this.indexFromWinterSolstice,
    required this.targetLongitudeRadians,
    required this.jdUt,
    required this.civilDayNumber,
  });

  /// Term index counted from the winter solstice; 0 = 冬至 … 23 = 大雪.
  final int indexFromWinterSolstice;

  /// The solar-ecliptic longitude the term targets, in radians.
  final double targetLongitudeRadians;

  /// UT instant of the term crossing.
  final JulianDate<Ut1Scale> jdUt;

  /// Civil (Gregorian) day number of the term.
  final int civilDayNumber;
}

/// A geocentric new moon (朔) within a Chinese-calendar year.
final class TaiyinChineseNewMoonEvent {
  const TaiyinChineseNewMoonEvent({
    required this.jdUt,
    required this.civilDayNumber,
  });

  final JulianDate<Ut1Scale> jdUt;
  final int civilDayNumber;
}

/// One lunar month within a Chinese-calendar year.
final class TaiyinChineseCalendarMonth {
  const TaiyinChineseCalendarMonth({
    required this.lunarYear,
    required this.month,
    required this.isLeap,
    required this.dayCount,
    required this.monthName,
    required this.firstCivilDayNumber,
    required this.astronomicalNewMoonJdUt,
  });

  final int lunarYear;
  final int month;
  final bool isLeap;
  final int dayCount;
  final TaiyinChineseCalendarMonthName monthName;
  final int firstCivilDayNumber;
  final JulianDate<Ut1Scale> astronomicalNewMoonJdUt;
}

/// A full winter-solstice-based Chinese calendar year.
final class TaiyinChineseCalendarYear {
  const TaiyinChineseCalendarYear({
    required this.solarTerms,
    required this.newMoons,
    required this.months,
    required this.solarTermCount,
    required this.newMoonCount,
    required this.monthCount,
    required this.leapMonthIndex,
    required this.firstWinterSolsticeDayNumber,
    required this.secondWinterSolsticeDayNumber,
  });

  final List<TaiyinChineseSolarTermEvent> solarTerms;
  final List<TaiyinChineseNewMoonEvent> newMoons;
  final List<TaiyinChineseCalendarMonth> months;
  final int solarTermCount;
  final int newMoonCount;
  final int monthCount;

  /// Index of the leap month within [months], or -1 when there is none.
  final int leapMonthIndex;
  final int firstWinterSolsticeDayNumber;
  final int secondWinterSolsticeDayNumber;
}
