import 'package:taiyin/taiyin.dart';
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
