import 'dart:math' as math;

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  group(
    'SolarTimeApi native integration',
    () {
      late EphemerisContext context;
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460311.0);

      setUp(() {
        context = Ephemeris.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        context.close();
      });

      test('calculates equation of time from UT1 and TT', () {
        final fromUt1 = context.solarTime.equationOfTimeAtUt1(ut1).value;
        final equation = fromUt1;
        final fromTt = context.solarTime.equationOfTimeAtTt(equation.tt).value;

        expect(equation.equationSeconds, inExclusiveRange(-250.0, -150.0));
        expect(equation.equationSeconds, closeTo(-198.9342282623329, 2.0));
        expect(
          equation.equationDays * JulianDate.secondsPerDay,
          closeTo(equation.equationSeconds, 1e-12),
        );
        expect(fromTt.equationSeconds, closeTo(equation.equationSeconds, 2e-5));
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
        expect(context.lastDiagnostic?.status, 0);
      });

      test('round-trips local mean and apparent solar time', () {
        final longitudeRadians = 116.3833 * math.pi / 180.0;
        final equation = context.solarTime.equationOfTimeAtUt1(ut1).value;
        final localMean = LocalMeanSolarTime.fromUt1(
          ut1,
          longitudeRadians: longitudeRadians,
        );

        final apparent = context.solarTime.meanToApparent(localMean).value;
        final roundTrip = context.solarTime.apparentToMean(apparent).value;

        expect(
          apparent.coordinate.coordinateSecondsDifference(localMean.coordinate),
          closeTo(equation.equationSeconds, 1e-4),
        );
        expect(
          roundTrip.coordinate.coordinateSecondsDifference(
            localMean.coordinate,
          ),
          closeTo(0.0, 1e-4),
        );
        expect(roundTrip.longitudeRadians, longitudeRadians);
        expect(context.lastDiagnostic?.status, 0);
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
          () => context.solarTime.equationOfTimeAtUt1(ut1).value,
          throwsStateError,
        );
        expect(
          () => context.solarTime.meanToApparent(localMean).value,
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
