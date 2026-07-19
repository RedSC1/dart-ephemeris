import 'dart:io';
import 'dart:math' as math;

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();

  group(
    'TaiyinSolarTimeApi native integration',
    () {
      late TaiyinContext context;
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460311.0);

      setUp(() {
        context = Taiyin.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        context.close();
      });

      test('calculates equation of time from UT1 and TT', () {
        final fromUt1 = context.solarTime.equationOfTimeAtUt1(ut1);
        final equation = fromUt1.value;
        final fromTt = context.solarTime.equationOfTimeAtTt(equation.tt);

        expect(equation.equationSeconds, inExclusiveRange(-250.0, -150.0));
        expect(equation.equationSeconds, closeTo(-198.9342282623329, 2.0));
        expect(
          equation.equationDays * JulianDate.secondsPerDay,
          closeTo(equation.equationSeconds, 1e-12),
        );
        expect(
          fromTt.value.equationSeconds,
          closeTo(equation.equationSeconds, 2e-5),
        );
        expect(
          equation.ut1.coordinateSecondsDifference(ut1),
          closeTo(0, 5e-12),
        );
        expect(
          [
            equation.apparentSunRightAscensionRadians,
            equation.greenwichApparentSiderealTimeRadians,
          ].every((value) => value.isFinite),
          isTrue,
        );
        expect(fromUt1.diagnostic.status, 0);
        expect(fromTt.diagnostic.status, 0);
      });

      test('round-trips local mean and apparent solar time', () {
        final longitudeRadians = 116.3833 * math.pi / 180.0;
        final equation = context.solarTime.equationOfTimeAtUt1(ut1).value;
        final localMean = LocalMeanSolarTime.fromUt1(
          ut1,
          longitudeRadians: longitudeRadians,
        );

        final apparent = context.solarTime.meanToApparent(localMean);
        final roundTrip = context.solarTime.apparentToMean(apparent.value);

        expect(
          apparent.value.coordinate.coordinateSecondsDifference(
            localMean.coordinate,
          ),
          closeTo(equation.equationSeconds, 1e-4),
        );
        expect(
          roundTrip.value.coordinate.coordinateSecondsDifference(
            localMean.coordinate,
          ),
          closeTo(0.0, 1e-4),
        );
        expect(roundTrip.value.longitudeRadians, longitudeRadians);
        expect(apparent.diagnostic.status, 0);
        expect(roundTrip.diagnostic.status, 0);
      });

      test('preserves nanosecond-separated split local coordinates', () {
        final preciseUt1 = JulianDate<Ut1Scale>.fromParts(
          2460311,
          0.123456789012345,
        );
        const longitudeRadians = -1.23456789012345;

        final localMean = LocalMeanSolarTime.fromUt1(
          preciseUt1,
          longitudeRadians: longitudeRadians,
        );
        final shiftedLocalMean = LocalMeanSolarTime.fromCoordinate(
          localMean.coordinate.addNanoseconds(1),
          longitudeRadians: longitudeRadians,
        );
        final apparent = context.solarTime.meanToApparent(localMean);
        final shiftedApparent = context.solarTime.meanToApparent(
          shiftedLocalMean,
        );

        expect(
          localMean.toUt1().coordinateSecondsDifference(preciseUt1),
          closeTo(0, 5e-12),
        );
        expect(
          shiftedApparent.value.coordinate.coordinateSecondsDifference(
            apparent.value.coordinate,
          ),
          closeTo(1e-9, 5e-12),
        );
      });

      test('rejects invalid longitude and use after close', () {
        final localMean = LocalMeanSolarTime.fromUt1(ut1, longitudeRadians: 0);
        expect(
          () => LocalMeanSolarTime.fromUt1(ut1, longitudeRadians: double.nan),
          throwsArgumentError,
        );
        expect(
          () =>
              LocalMeanSolarTime.fromUt1(ut1, longitudeRadians: math.pi + 0.01),
          throwsArgumentError,
        );

        context.close();
        expect(
          () => context.solarTime.equationOfTimeAtUt1(ut1),
          throwsStateError,
        );
        expect(
          () => context.solarTime.meanToApparent(localMean),
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
