import 'dart:math' as math;

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  const degreesToRadians = math.pi / 180.0;
  // The frozen lunar model documents a 5.22 arcsecond held-out maximum.
  const semiAnalyticLunarAngleTolerance = (6 / 3600) * degreesToRadians;

  group(
    'PhenomenaApi native integration',
    () {
      late EphemerisContext context;

      setUp(() {
        context = Ephemeris.open(libraryPath: libraryPath).createContext();
        context.configuration
          ..useSolarDeflector()
          ..setApparentConfig(
            ApparentConfig(
              flags: {
                ApparentFlag.spherical,
                ApparentFlag.lightTime,
                ApparentFlag.aberration,
                ApparentFlag.deflection,
              },
            ),
          );
      });

      tearDown(() {
        context.close();
      });

      test(
        'matches the first-quarter Moon oracle on the semi-analytical route',
        () {
          context.configuration.setRouteRule(RouteRule.semiAnalytic);
          final result = context.phenomena.atUt1(
            Body.moon,
            JulianDate<Ut1Scale>.fromDouble(2460416.2916666665),
          );
          final value = result;

          expect(
            value.phaseAngleRadians,
            closeTo(
              89.952673424033108 * degreesToRadians,
              0.012 * degreesToRadians,
            ),
          );
          expect(value.illuminatedFraction, closeTo(0.500413002240195, 1e-4));
          expect(
            value.solarElongationRadians,
            closeTo(
              89.896332647082019 * degreesToRadians,
              semiAnalyticLunarAngleTolerance,
            ),
          );
          expect(
            value.apparentDiameterRadians,
            closeTo(
              0.503260123339875 * degreesToRadians,
              6e-5 * degreesToRadians,
            ),
          );
          expect(value.apparentMagnitude, closeTo(-10.048877989411316, 0.09));
          expect(
            value.geocentricHorizontalParallaxRadians,
            closeTo(
              0.923829244641875 * degreesToRadians,
              1e-6 * degreesToRadians,
            ),
          );
          expect(value.body, Body.moon);
          expect(value.origin, PhenomenaOrigin.geocentric);
          expect(context.lastDiagnostic?.status, 0);
          expect(context.lastDiagnostic?.targetId, Body.moon.id);
        },
      );

      test('covers the TT route and nullable non-lunar parallax', () {
        final result = context.phenomena.atTt(
          Body.sun,
          JulianDate<TtScale>.fromDouble(2460409.2508),
          flags: {PositionFlag.truePosition},
        );

        expect(result.phaseAngleRadians, 0.0);
        expect(result.illuminatedFraction, 1.0);
        expect(result.solarElongationRadians, 0.0);
        expect(result.apparentDiameterRadians.isFinite, isTrue);
        expect(result.apparentMagnitude.isFinite, isTrue);
        expect(result.geocentricHorizontalParallaxRadians, isNull);
        expect(result.origin, PhenomenaOrigin.geocentric);
        expect(result.flags, contains(PositionFlag.truePosition));
        expect(context.lastDiagnostic?.status, 0);
      });

      test(
        'makes topocentric origin explicit while parallax stays geocentric',
        () {
          final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.25);
          final tt = context.solarTime.equationOfTimeAtUt1(ut1).tt;
          final geocentric = context.phenomena.atUt1(Body.moon, ut1);

          context.configuration.setSimpleTopocentricObserver(
            const ObserverLocation(
              longitudeDegrees: -104.9903,
              latitudeDegrees: 39.7392,
              heightMeters: 1609.3,
            ),
            ut1: ut1,
            tt: tt,
          );
          final topocentric = context.phenomena.atUt1(
            Body.moon,
            ut1,
            origin: PhenomenaOrigin.topocentric,
          );

          expect(topocentric.origin, PhenomenaOrigin.topocentric);
          expect(
            topocentric.geocentricHorizontalParallaxRadians,
            closeTo(geocentric.geocentricHorizontalParallaxRadians!, 1e-15),
          );
          expect(
            (topocentric.apparentDiameterRadians -
                    geocentric.apparentDiameterRadians)
                .abs(),
            greaterThan(1e-12),
          );
        },
      );

      test('rejects unsupported bodies and use after close', () {
        final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.25);
        expect(
          () => context.phenomena.atUt1(Body.earth, ut1),
          throwsArgumentError,
        );
        expect(
          () => context.phenomena.atUt1(Body.jupiterBarycenter, ut1),
          throwsArgumentError,
        );
        expect(
          () => context.phenomena.atUt1(
            Body.moon,
            ut1,
            flags: {PositionFlag.topocentric},
          ),
          throwsArgumentError,
        );

        context.close();
        expect(() => context.phenomena.atUt1(Body.moon, ut1), throwsStateError);
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
