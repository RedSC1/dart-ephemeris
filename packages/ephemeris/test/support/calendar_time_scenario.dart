import 'package:ephemeris/ephemeris.dart';
import 'backend_scenario.dart' show require;

/// Runs unchanged on the VM, Dart2JS and Dart2Wasm.
List<Object?> exerciseCalendarTime(Ephemeris runtime) {
  final ctx = runtime.createContext();
  final rows = <Object?>[];
  void row(
    String label,
    List<num> values, [
    ResultFlags flags = ResultFlags.none,
  ]) => rows.add({'label': label, 'values': values, 'flags': flags.mask});
  void jd(
    String label,
    JulianDate<TimeScale> date, [
    ResultFlags flags = ResultFlags.none,
  ]) => row(label, [date.dayNumber, date.dayFraction], flags);
  try {
    final time = ctx.time;
    final calendar = AstroDateTime(2024, 4, 8, 18, 0, 0, 123456789);
    final utc = time.julianDay<UtcScale>(calendar);
    jd('time/julian', utc.value, utc.flags);
    final reversed = time.reverseJulianDay(utc.value).value;
    require(reversed == calendar, 'Calendar nanosecond roundtrip failed');
    final precise = time
        .preciseScalesFromUtc(
          calendar,
          taiMinusUtcSeconds: 37,
          dut1Seconds: 0.1,
        )
        .value;
    for (final value in [
      precise.utc,
      precise.tai,
      precise.tt,
      precise.ut1,
      precise.tdb,
    ]) {
      jd('time/precise', value);
    }
    for (final model in TdbModel.values) {
      final result = time.ttToTdb(precise.tt, model: model);
      jd('time/tdb/${model.id}', result.value, result.flags);
      require(
        time
                .tdbToTt(result.value, model: model)
                .value
                .secondsDifference(precise.tt)
                .abs() <
            1e-8,
        'TT/TDB roundtrip failed',
      );
    }
    runtime.clearEopTable();
    try {
      time.scalesFromUtc(calendar);
      throw StateError('Missing EOP accepted');
    } on EarthOrientationDataError {
      /* strict policy */
    }
    time.setAllowUtcOutOfRangeEstimate(true);
    final estimated = time.scalesFromUtc(calendar);
    require(
      estimated.flags.contains(ResultFlag.timeScaleFallback),
      'Missing estimate flag',
    );
    jd('time/estimate', estimated.value.value.ut1, estimated.flags);
    final reverse = time.ut1ToUtc(estimated.value.value.ut1);
    require(
      reverse.value.secondsDifference(utc.value).abs() < 1e-7,
      'UTC inverse failed',
    );
    time.setAllowUtcOutOfRangeEstimate(false);
    runtime.loadBuiltinEopTable();
    final scales = time.scalesFromUtc(calendar);
    jd('time/eop', scales.value.value.ut1, scales.flags);
    for (final value in [
      time.ttToUtc(precise.tt).value,
      time.taiToUtc(precise.tai).value,
      time.tdbToUtc(precise.tdb).value,
    ]) {
      jd('time/reverse', value);
    }
    row('time/scalars', [
      time.estimatedDeltaTForDecimalYear(-750),
      time.decimalYear(precise.tt),
      time.julianCenturiesSinceJ2000(precise.tt),
    ]);

    for (final mode in ChineseCalendarMode.values) {
      final config = ChineseCalendarConfig(mode: mode);
      final cal = ctx.createChineseCalendar(config: config);
      try {
        final lunar = cal.fromSolar(
          const SolarDate(year: 2024, month: 2, day: 10),
        );
        require(
          lunar.value.month == 1 && lunar.value.day == 1,
          'New Year mismatch',
        );
        row('calendar/${mode.id}/lunar', [
          lunar.value.year,
          lunar.value.month,
          lunar.value.day,
          lunar.value.isLeap ? 1 : 0,
          lunar.value.monthName.id,
          lunar.value.monthDays,
        ], lunar.flags);
        final solar = cal.fromLunar(lunar.value).value;
        require(
          solar.year == 2024 && solar.month == 2 && solar.day == 10,
          'Lunar inverse failed',
        );
        final year = cal.calcYearUt(Ut1JulianDate.fromDouble(2460348));
        row('calendar/${mode.id}/header', [
          year.value.solarTermCount,
          year.value.newMoonCount,
          year.value.monthCount,
          year.value.leapMonthIndex,
        ], year.flags);
        for (final m in year.value.months) {
          row('calendar/${mode.id}/month', [
            m.lunarYear,
            m.month,
            m.isLeap ? 1 : 0,
            m.dayCount,
            m.monthName.id,
            m.monthBuildingBranch,
            m.firstCivilDayNumber,
            m.astronomicalNewMoonJdUt.dayNumber,
            m.astronomicalNewMoonJdUt.dayFraction,
          ]);
        }
        for (final t in year.value.solarTerms) {
          jd('calendar/${mode.id}/term', t.jdUt);
        }
        for (final m in year.value.newMoons) {
          jd('calendar/${mode.id}/moon', m.jdUt);
        }
        final term = cal
            .getSpecificJieQiUt(civilYear: 2024, termIndexFromVernalEquinox: 0)
            .value;
        for (final t in [
          cal.getPrevJieQiUt(term.jdUt),
          cal.getNextJieQiUt(term.jdUt),
          cal.getPrevJieUt(term.jdUt),
          cal.getNextJieUt(term.jdUt),
          cal.getPrevQiUt(term.jdUt),
          cal.getNextQiUt(term.jdUt),
        ]) {
          jd('calendar/${mode.id}/search', t.value.jdUt, t.flags);
        }
        for (final rat in GanzhiRatHourMode.values) {
          final p = cal.fourPillarsLocal(
            AstroDateTime(2003, 3, 13, 23),
            ratHourMode: rat,
          );
          row('calendar/${mode.id}/pillars/${rat.id}', [
            p.value.year.raw,
            p.value.month.raw,
            p.value.day.raw,
            p.value.hour.raw,
          ], p.flags);
        }
        row('calendar/${mode.id}/days', [
          cal.getMonthDays(lunarYear: 2024, month: 1, isLeap: false).value,
        ]);
      } finally {
        cal.close();
      }
    }
    final historical = ctx.chineseCalendar
        .fromSolar(const SolarDate(year: 23, month: 12, day: 2))
        .value;
    row('calendar/reform', [
      historical.year,
      historical.month,
      historical.day,
      historical.monthName.id,
    ]);
    final a = ctx.createChineseCalendar(
      config: const ChineseCalendarConfig.localAstronomicalUtcOffset(420),
    );
    final b = ctx.createChineseCalendar(
      config: const ChineseCalendarConfig.localAstronomicalMeridian(
        105,
        utcOffsetMinutes: 420,
      ),
    );
    try {
      final date = const SolarDate(year: 2024, month: 2, day: 10);
      require(
        a.fromSolar(date).value.toString() ==
            b.fromSolar(date).value.toString(),
        'UTC+7 != 105E',
      );
    } finally {
      a.close();
      b.close();
    }
    final borrowed = ctx.chineseCalendar;
    require(
      identical(borrowed, ctx.chineseCalendar),
      'Default calendar not cached',
    );
    ctx.close();
    require(borrowed.isClosed, 'Owner did not close its calendar');
    try {
      borrowed.fromSolar(const SolarDate(year: 2024, month: 1, day: 1));
      throw StateError('Closed calendar accepted');
    } on StateError catch (e) {
      require(e.message.toString().contains('closed'), 'Wrong close error');
    }
  } finally {
    ctx.close();
  }
  return rows;
}
