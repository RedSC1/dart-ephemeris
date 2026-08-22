import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

void main() {
  group(
    'ChineseCalendarApi native integration',
    () {
      late Ephemeris runtime;
      late EphemerisContext context;

      setUp(() {
        runtime = Ephemeris.open(libraryPath: libraryPath);
        context = runtime.createContext();
      });

      tearDown(() {
        context.close();
      });

      test('computes a winter-solstice Chinese calendar year', () {
        final year = context.chineseCalendar
            .calcYearUt(JulianDate<Ut1Scale>.fromDouble(2460348.0))
            .value;

        expect(year.solarTerms, hasLength(25));
        expect(year.solarTermCount, 25);
        expect(year.newMoonCount, greaterThanOrEqualTo(13));
        expect(year.months.length, greaterThanOrEqualTo(12));
        expect(year.firstWinterSolsticeDayNumber, isNonZero);
        expect(
          year.secondWinterSolsticeDayNumber,
          greaterThan(year.firstWinterSolsticeDayNumber),
        );
        // The first term is the winter solstice (冬至, index 0).
        expect(year.solarTerms.first.indexFromWinterSolstice, 0);
        expect(year.solarTerms.first.jdUt, isA<JulianDate<Ut1Scale>>());
        expect(year.solarTerms.first.civilDayNumber, isNonZero);
      });

      test('converts a solar date to the Chinese lunar calendar', () {
        final result = context.chineseCalendar
            .fromSolar(SolarDate(year: 2024, month: 2, day: 10))
            .value;

        expect(context.lastDiagnostic?.status, 0);
        expect(result.year, 2024);
        expect(result.month, 1);
        expect(result.day, 1);
        expect(result.isLeap, isFalse);
      });

      test('rejects date fields before native integer narrowing', () {
        for (final solar in [
          SolarDate(year: 0x1000007e8, month: 2, day: 10),
          SolarDate(year: 2024, month: 258, day: 10),
          SolarDate(year: 2024, month: 2, day: 266),
        ]) {
          expect(
            () => context.chineseCalendar.fromSolar(solar),
            throwsRangeError,
          );
        }

        for (final lunar in [
          LunarDate(
            year: 0x1000007e8,
            month: 1,
            day: 1,
            isLeap: false,
            monthDays: 29,
          ),
          LunarDate(
            year: 2024,
            month: 257,
            day: 1,
            isLeap: false,
            monthDays: 29,
          ),
          LunarDate(
            year: 2024,
            month: 1,
            day: 257,
            isLeap: false,
            monthDays: 29,
          ),
          LunarDate(
            year: 2024,
            month: 1,
            day: 1,
            isLeap: false,
            monthDays: 285,
          ),
        ]) {
          expect(
            () => context.chineseCalendar.fromLunar(lunar),
            throwsRangeError,
          );
        }

        expect(
          () => context.chineseCalendar.getMonthDays(
            lunarYear: 0x1000007e8,
            month: 1,
            isLeap: false,
          ),
          throwsRangeError,
        );
        expect(
          () => context.chineseCalendar.getMonthDays(
            lunarYear: 2024,
            month: 257,
            isLeap: false,
          ),
          throwsRangeError,
        );
        expect(
          () => context.chineseCalendar.getSpecificJieQiUt(
            civilYear: 0x1000007e8,
            termIndexFromVernalEquinox: 0,
          ),
          throwsRangeError,
        );
        expect(
          () => context.chineseCalendar.getSpecificJieQiUt(
            civilYear: 2024,
            termIndexFromVernalEquinox: 0x100,
          ),
          throwsRangeError,
        );
      });

      test('computes the four pillars for a birth moment', () {
        final result = context.chineseCalendar
            .fourPillars(
              instantUtc: JulianDate<UtcScale>.fromDouble(2460351.0),
              virtualTime: AstroDateTime(2024, 2, 10, 12),
            )
            .value;

        expect(context.lastDiagnostic?.status, 0);
        // 2024-02-10 is after 立春, so the year pillar is 甲辰 (stem 0, branch 4).
        expect(result.year.stemId, 0);
        expect(result.year.branchId, 4);
        // 甲 year, first month via 五虎遁 is 丙寅 (stem 2, branch 2).
        expect(result.month.stemId, 2);
        expect(result.month.branchId, 2);
      });

      test('resolves a local clock without manual timezone arithmetic', () {
        final localTime = AstroDateTime(2003, 3, 13, 14, 15);
        final calendar = context.chineseCalendar;
        final instantUtc = calendar.instantFromLocal(localTime);

        expect(
          AstroDateTime.fromJulianDate(instantUtc),
          AstroDateTime(2003, 3, 13, 6, 15),
        );
        expect(calendar.localTimeFromInstant(instantUtc).value, localTime);
        expect(
          calendar.fromLocal(localTime).value.year,
          calendar
              .fromSolar(SolarDate(year: 2003, month: 3, day: 13))
              .value
              .year,
        );

        final concise = calendar.fourPillarsLocal(localTime).value;
        final explicit = calendar
            .fourPillars(instantUtc: instantUtc, virtualTime: localTime)
            .value;
        expect(concise.year, explicit.year);
        expect(concise.month, explicit.month);
        expect(concise.day, explicit.day);
        expect(concise.hour, explicit.hour);

        final fromInstant = calendar.fourPillarsInstant(instantUtc).value;
        expect(fromInstant.year, explicit.year);
        expect(fromInstant.month, explicit.month);
        expect(fromInstant.day, explicit.day);
        expect(fromInstant.hour, explicit.hour);
      });

      test('searches previous and next solar terms', () {
        final jd = JulianDate<Ut1Scale>.fromDouble(2460348.0);
        final prev = context.chineseCalendar.getPrevJieQiUt(jd).value;
        final next = context.chineseCalendar.getNextJieQiUt(jd).value;

        expect(prev.jdUt.toDouble(), lessThanOrEqualTo(jd.toDouble()));
        expect(next.jdUt.toDouble(), greaterThan(jd.toDouble()));
        expect(prev.indexFromWinterSolstice, inInclusiveRange(0, 23));
        expect(next.indexFromWinterSolstice, inInclusiveRange(0, 23));
      });

      test('supports custom calendar configurations', () {
        final custom = context.createChineseCalendar(
          config: const ChineseCalendarConfig.localAstronomicalUtcOffset(0),
        );
        final year = custom
            .calcYearUt(JulianDate<Ut1Scale>.fromDouble(2460348.0))
            .value;
        expect(year.solarTermCount, 25);
        custom.close();
        expect(custom.isClosed, isTrue);
        expect(
          () => custom
              .calcYearUt(JulianDate<Ut1Scale>.fromDouble(2460348.0))
              .value,
          throwsStateError,
        );
      });

      test('rejects calendar UTC offsets outside the native int32 range', () {
        expect(
          () => context.createChineseCalendar(
            config: const ChineseCalendarConfig.localAstronomicalUtcOffset(
              0x1000001e0,
            ),
          ),
          throwsRangeError,
        );
      });

      test('rejects use after closing the owning context', () {
        final cal = context.chineseCalendar;
        context.close();
        expect(
          () =>
              cal.calcYearUt(JulianDate<Ut1Scale>.fromDouble(2460348.0)).value,
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
