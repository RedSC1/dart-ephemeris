/// Chinese-calendar models backed by the Ephemeris Chinese-calendar module.
library;

import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// Rule profile applied when constructing a Chinese calendar.
enum ChineseCalendarMode {
  /// China-standard historical: mean solar terms and new moons with
  /// compressed day-correction tables and a fixed UTC+8 civil boundary.
  chinaStandardHistorical(0),

  /// Local astronomical: always uses Taiyin's precise 定气 (solar terms) and
  /// 定朔 (new moons); the civil boundary is a fixed UTC offset or mean-solar
  /// meridian.
  localAstronomical(1),

  /// China-standard astronomical: precise solar terms and new moons rendered
  /// against the China-standard (UTC+8) civil day.
  chinaStandardAstronomical(2);

  const ChineseCalendarMode(this.id);

  final int id;
}

/// How the civil (local) day boundary is determined.
enum ChineseCalendarDayBoundaryMode {
  /// The civil day starts at a fixed UTC offset (e.g. UTC+8 = 480 minutes).
  fixedUtcOffset(0),

  /// The civil day starts at the mean-solar meridian through the configured
  /// longitude.
  meanSolarMeridian(1);

  const ChineseCalendarDayBoundaryMode(this.id);

  final int id;
}

/// Historical exceptional month names used by the `chinaStandardHistorical`
/// profile.
enum ChineseCalendarMonthName {
  normal(0),
  thirteen(1),
  laterNine(2),
  altTwelve(3),
  altOne(4),
  laterSameName(5);

  const ChineseCalendarMonthName(this.id);

  final int id;

  static ChineseCalendarMonthName fromId(int id) {
    for (final name in values) {
      if (name.id == id) return name;
    }
    throw ArgumentError.value(id, 'id', 'unknown Chinese month name');
  }
}

/// Configuration for a Chinese-calendar context.
final class ChineseCalendarConfig {
  const ChineseCalendarConfig({
    this.mode = ChineseCalendarMode.chinaStandardHistorical,
    this.dayBoundaryMode = ChineseCalendarDayBoundaryMode.fixedUtcOffset,
    this.utcOffsetMinutes = 480,
    this.calendarMeridianDegrees = 0,
  });

  /// China-standard astronomical profile with a fixed UTC+8 civil day.
  const ChineseCalendarConfig.chinaStandardAstronomical({
    int utcOffsetMinutes = 480,
  }) : this(
         mode: ChineseCalendarMode.chinaStandardAstronomical,
         utcOffsetMinutes: utcOffsetMinutes,
       );

  /// Historical China-standard profile with the given civil-day UTC offset.
  const ChineseCalendarConfig.historicalChina({int utcOffsetMinutes = 480})
    : this(utcOffsetMinutes: utcOffsetMinutes);

  /// Local astronomical profile with a fixed [utcOffsetMinutes] civil
  /// boundary.
  const ChineseCalendarConfig.localAstronomicalUtcOffset(int utcOffsetMinutes)
    : this(
        mode: ChineseCalendarMode.localAstronomical,
        utcOffsetMinutes: utcOffsetMinutes,
      );

  /// Local astronomical profile with a mean-solar-meridian civil boundary at
  /// [longitudeDegrees].
  const ChineseCalendarConfig.localAstronomicalMeridian(double longitudeDegrees)
    : this(
        mode: ChineseCalendarMode.localAstronomical,
        dayBoundaryMode: ChineseCalendarDayBoundaryMode.meanSolarMeridian,
        calendarMeridianDegrees: longitudeDegrees,
      );

  final ChineseCalendarMode mode;
  final ChineseCalendarDayBoundaryMode dayBoundaryMode;

  /// Civil-day offset from UTC in minutes, meaningful for
  /// [ChineseCalendarDayBoundaryMode.fixedUtcOffset].
  final int utcOffsetMinutes;

  /// Longitude used for the mean-solar-meridian civil boundary.
  final double calendarMeridianDegrees;
}

/// A proleptic Gregorian (solar) calendar date.
final class SolarDate {
  const SolarDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;
}

/// A Chinese lunar calendar date.
final class LunarDate {
  const LunarDate({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeap,
    required this.monthDays,
    this.monthName = ChineseCalendarMonthName.normal,
  });

  final int year;
  final int month;
  final int day;
  final bool isLeap;

  /// Number of days in this lunar month (29 or 30).
  final int monthDays;

  /// Historical exceptional month name, when applicable.
  final ChineseCalendarMonthName monthName;
}

/// A solar-term (节气) crossing.
final class ChineseSolarTermEvent {
  const ChineseSolarTermEvent({
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
final class ChineseNewMoonEvent {
  const ChineseNewMoonEvent({required this.jdUt, required this.civilDayNumber});

  final JulianDate<Ut1Scale> jdUt;
  final int civilDayNumber;
}

/// One lunar month within a Chinese-calendar year.
final class ChineseCalendarMonth {
  const ChineseCalendarMonth({
    required this.lunarYear,
    required this.month,
    required this.isLeap,
    required this.dayCount,
    required this.monthName,
    this.monthBuildingBranch = 0,
    required this.firstCivilDayNumber,
    required this.astronomicalNewMoonJdUt,
  });

  final int lunarYear;
  final int month;
  final bool isLeap;
  final int dayCount;
  final ChineseCalendarMonthName monthName;

  /// Earthly-branch id (0=Zi … 11=Hai) the month is built from.
  final int monthBuildingBranch;
  final int firstCivilDayNumber;
  final JulianDate<Ut1Scale> astronomicalNewMoonJdUt;
}

/// A full winter-solstice-based Chinese calendar year.
final class ChineseCalendarYear {
  const ChineseCalendarYear({
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

  final List<ChineseSolarTermEvent> solarTerms;
  final List<ChineseNewMoonEvent> newMoons;
  final List<ChineseCalendarMonth> months;
  final int solarTermCount;
  final int newMoonCount;
  final int monthCount;

  /// Index of the leap month within [months], or -1 when there is none.
  final int leapMonthIndex;
  final int firstWinterSolsticeDayNumber;
  final int secondWinterSolsticeDayNumber;
}
