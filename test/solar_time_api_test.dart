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
        final localMean = JulianDate<LocalMeanSolarTimeScale>.fromDouble(
          ut1.toDouble() + longitudeRadians / (2.0 * math.pi),
        );

        final apparent = context.solarTime.meanToApparent(
          localMean,
          longitudeRadians,
        );
        final roundTrip = context.solarTime.apparentToMean(
          apparent.value,
          longitudeRadians,
        );

        expect(
          apparent.value.coordinateSecondsDifference(localMean),
          closeTo(equation.equationSeconds, 1e-4),
        );
        expect(
          roundTrip.value.coordinateSecondsDifference(localMean),
          closeTo(0.0, 1e-4),
        );
        expect(apparent.diagnostic.status, 0);
        expect(roundTrip.diagnostic.status, 0);
      });

      test('rejects invalid longitude and use after close', () {
        final localMean = JulianDate<LocalMeanSolarTimeScale>.fromDouble(
          2460311.0,
        );
        expect(
          () => context.solarTime.meanToApparent(localMean, double.nan),
          throwsArgumentError,
        );
        expect(
          () => context.solarTime.meanToApparent(localMean, math.pi + 0.01),
          throwsArgumentError,
        );

        context.close();
        expect(
          () => context.solarTime.equationOfTimeAtUt1(ut1),
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
