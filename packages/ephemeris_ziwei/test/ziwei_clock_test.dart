import 'dart:math' as math;
import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  group(
    'explicit chart clocks',
    () {
      late EphemerisContext context;
      late ZiweiContext ziwei;
      setUp(() {
        context = Ephemeris.open(libraryPath: libraryPath).createContext();
        ziwei = context.ziwei;
      });
      tearDown(() => context.close());
      for (final mode in ZiweiClockMode.values) {
        test('$mode conversion, navigation and flow', () {
          final clock = ZiweiClock(
            mode: mode,
            longitudeRadians: 118.582 * math.pi / 180,
          );
          final instant = ziwei
              .chartTimeToUt1(AstroDateTime(2003, 3, 13, 22), clock: clock)
              .value;
          final mapped = ziwei.chartTimeFromUt1(instant, clock: clock).value;
          expect(
            [mapped.year, mapped.month, mapped.day, mapped.hour, mapped.minute],
            [2003, 3, 13, 22, 0],
          );
          final chart = ziwei
              .createChartAtUt1(
                instantUt1: instant,
                gender: ZiweiGender.male,
                clock: clock,
              )
              .value;
          for (final rat in GanzhiRatHourMode.values) {
            final target = ziwei
                .stepFlowHourAtUt1(
                  instantUt1: instant,
                  clock: clock,
                  ratHourMode: rat,
                )
                .value;
            final hour = rat == GanzhiRatHourMode.noSplit ? 0 : 23;
            expect(target.virtualTime.hour, hour);
            expect(target.virtualTime.minute, 0);
            expect(
              ziwei
                  .chartTimeFromUt1(target.instantUt1, clock: clock)
                  .value
                  .hour,
              hour,
            );
            final flow = chart
                .setFlowAtUt1(
                  targetInstantUt1: target.instantUt1,
                  clock: clock,
                  options: ZiweiFlowOptions(ratHourMode: rat),
                )
                .value;
            expect(flow.targetHourIndex, 0);
          }
          final next = ziwei
              .stepFlowDayAtUt1(instantUt1: instant, clock: clock)
              .value;
          expect([next.virtualTime.day, next.virtualTime.hour], [14, 22]);
          if (mode == ZiweiClockMode.apparentSolar) {
            expect(
              ((next.instantUt1.toDouble() - instant.toDouble()) * 86400 -
                      86400)
                  .abs(),
              greaterThan(0.01),
            );
          }
        });
        test('$mode reverse search returns physical slot start', () {
          final clock = ZiweiClock(
            mode: mode,
            longitudeRadians: 118.582 * math.pi / 180,
          );
          JulianDate<Ut1Scale> at(int h, [int m = 0]) => ziwei
              .chartTimeToUt1(AstroDateTime(2003, 3, 13, h, m), clock: clock)
              .value;
          final chart = ziwei
              .createChartAtUt1(
                instantUt1: at(14, 15),
                gender: ZiweiGender.male,
                clock: clock,
              )
              .value;
          final candidates = ziwei
              .reverseLookupTier1AtUt1(
                startInstantUt1: at(12),
                endInstantUt1: at(15),
                gender: ZiweiGender.male,
                clock: clock,
                query: ZiweiTier1ReverseQuery(
                  ziweiBranch: chart.starPosition(ziwei.findStar('ziwei')!.id),
                ),
              )
              .value;
          final found = candidates.firstWhere((c) => c.virtualTime.hour == 13);
          expect(
            (found.instantUt1.toDouble() - at(13).toDouble()).abs(),
            lessThan(1e-9),
          );
        });
      }
      test('invalid solar longitude and closed calendar reject', () {
        final time = AstroDateTime(2003, 3, 13);
        expect(
          () => ziwei.chartTimeToUt1(
            time,
            clock: const ZiweiClock(
              mode: ZiweiClockMode.meanSolar,
              longitudeRadians: double.nan,
            ),
          ),
          throwsArgumentError,
        );
        ziwei.chartTimeToUt1(
          time,
          clock: const ZiweiClock(longitudeRadians: double.nan),
        );
        ziwei.chineseCalendar.close();
        expect(() => ziwei.chartTimeToUt1(time), throwsStateError);
      });
      test('midnight date carry stays valid', () {
        for (final fields in [
          [1984, 2, 29, 1984, 3, 1],
          [2026, 12, 31, 2027, 1, 1],
          [1582, 10, 4, 1582, 10, 15],
        ]) {
          final instant = ziwei
              .chartTimeToUt1(
                AstroDateTime(fields[0], fields[1], fields[2], 23),
              )
              .value;
          final target = ziwei
              .stepFlowHourAtUt1(
                instantUt1: instant,
                ratHourMode: GanzhiRatHourMode.todayGan,
              )
              .value
              .virtualTime;
          expect(
            [target.year, target.month, target.day, target.hour],
            [...fields.sublist(3), 0],
          );
        }
      });
    },
    skip: nativeLibraryAvailable ? false : libraryUnavailableSkip,
  );
}
