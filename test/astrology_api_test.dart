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
    'TaiyinAstrologyApi native integration',
    () {
      late TaiyinContext context;
      final tt = JulianDate<TtScale>.fromDouble(2460409.0);
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460311.0);

      setUp(() {
        context = Taiyin.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        context.close();
      });

      test('evaluates built-in ayanamshas and exposes their availability', () {
        final fagan = context.astrology.ayanamshaAtTt(
          JulianDate<TtScale>.fromDouble(2433282.42346),
          precessionPolicy:
              TaiyinSiderealPrecessionPolicy.useReferencePrecession,
        );
        final lahiri = context.astrology.ayanamshaAtTt(
          JulianDate<TtScale>.fromDouble(2435553.5),
          ayanamsha: TaiyinAyanamsha.lahiri,
          precessionPolicy:
              TaiyinSiderealPrecessionPolicy.useReferencePrecession,
        );

        expect(fagan * 180 / math.pi, closeTo(24.042044444444445, 1e-9));
        expect(lahiri * 180 / math.pi, closeTo(23.245524742777778, 1e-9));
        for (final ayanamsha in TaiyinAyanamsha.values) {
          expect(context.astrology.hasAyanamshaModel(ayanamsha), isTrue);
        }
        for (final system in TaiyinHouseSystem.values) {
          expect(context.astrology.hasHouseSystemModel(system), isTrue);
        }
      });

      test('calculates sidereal ecliptic positions with a diagnostic', () {
        final fromTt = context.astrology.siderealPositionAtTt(
          TaiyinBody.sun,
          tt,
          ayanamsha: TaiyinAyanamsha.lahiri,
          flags: {TaiyinPositionFlag.speed},
        );
        final fromUt1 = context.astrology.siderealPositionAtUt1(
          TaiyinBody.sun,
          ut1,
        );
        final position = fromTt.value;
        final offset = _normalizeSignedRadians(
          position.tropicalLongitudeRadians - position.siderealLongitudeRadians,
        );

        expect(
          position.flags,
          containsAll({TaiyinPositionFlag.radians, TaiyinPositionFlag.speed}),
        );
        expect(
          [
            position.tropicalLongitudeRadians,
            position.siderealLongitudeRadians,
            position.latitudeRadians,
            position.distanceAu,
            position.tropicalLongitudeRateRadiansPerDay,
            position.siderealLongitudeRateRadiansPerDay,
            fromUt1.value.tropicalLongitudeRadians,
          ].every((value) => value.isFinite),
          isTrue,
        );
        expect(
          _normalizeSignedRadians(
            offset -
                context.astrology.ayanamshaAtTt(
                  tt,
                  ayanamsha: TaiyinAyanamsha.lahiri,
                ),
          ),
          closeTo(0, 1e-12),
        );
        expect(fromTt.diagnostic.status, 0);
        expect(fromTt.diagnostic.targetId, TaiyinBody.sun.id);
        expect(fromUt1.diagnostic.status, 0);
        expect(fromUt1.value.tropicalLongitudeRateRadiansPerDay.isNaN, isTrue);
        expect(fromUt1.value.siderealLongitudeRateRadiansPerDay.isNaN, isTrue);
      });

      test('calculates and locates houses from a configured observer', () {
        context.configuration.setObserverLocation(
          const TaiyinObserverLocation(
            longitudeDegrees: 116.3833,
            latitudeDegrees: 39.9167,
          ),
        );
        final houses = context.astrology.housesAtUt1(ut1);
        final ttFromUt1 = context.time.ut1ToTt(
          ut1,
          deltaTSeconds: context.time.estimatedDeltaTFromUt1(ut1),
        );
        final fromTt = context.astrology.housesAtTt(ttFromUt1);
        final exactCusp = context.astrology.housePositionOf(
          houses,
          houses.cuspLongitudesRadians[4],
        );
        final firstSpan = _normalizeRadians(
          houses.cuspLongitudesRadians[1] - houses.cuspLongitudesRadians[0],
        );
        final midpoint = context.astrology.housePositionOf(
          houses,
          houses.cuspLongitudesRadians[0] + firstSpan / 2,
        );

        expect(houses.requestedSystem, TaiyinHouseSystem.porphyry);
        expect(houses.resolvedSystem, TaiyinHouseSystem.porphyry);
        expect(houses.flags, isEmpty);
        expect(
          houses.ascendantRadians * 180 / math.pi,
          closeTo(137.955986373727, 3e-6),
        );
        expect(
          houses.midheavenRadians * 180 / math.pi,
          closeTo(39.424973002554, 3e-6),
        );
        expect(
          houses.cuspLongitudesRadians
              .followedBy(houses.cuspLongitudeRatesRadiansPerDay)
              .every((value) => value.isFinite),
          isTrue,
        );
        expect(
          _normalizeSignedRadians(
            fromTt.ascendantRadians - houses.ascendantRadians,
          ),
          closeTo(0, 1e-9),
        );
        expect(exactCusp.houseNumber, 5);
        expect(exactCusp.fraction, 0);
        expect(exactCusp.continuousHousePosition, 5);
        expect(midpoint.houseNumber, 1);
        expect(midpoint.fraction, closeTo(0.5, 1e-12));
        expect(midpoint.continuousHousePosition, closeTo(1.5, 1e-12));
      });

      test('calculates houses directly from ARMC', () {
        final houses = context.astrology.housesFromArmc(
          armcRadians: 123.456 * math.pi / 180,
          observerLatitudeRadians: 39.9167 * math.pi / 180,
          trueObliquityRadians: 23.436 * math.pi / 180,
          system: TaiyinHouseSystem.placidus,
        );

        expect(houses.resolvedSystem, TaiyinHouseSystem.placidus);
        expect(
          houses.cuspLongitudesRadians[0] * 180 / math.pi,
          closeTo(206.656040425304212, 1e-9),
        );
        expect(houses.flags, isEmpty);
        expect(houses.armcRateRadiansPerDay.isNaN, isTrue);
      });

      test(
        'rejects unsupported sidereal coordinate modes and use after close',
        () {
          expect(
            () => context.astrology.housesAtUt1(ut1),
            throwsA(isA<TaiyinException>()),
          );
          expect(
            () => context.astrology.siderealPositionAtTt(
              TaiyinBody.sun,
              tt,
              flags: {TaiyinPositionFlag.xyz},
            ),
            throwsArgumentError,
          );
          expect(
            () => context.astrology.housesFromArmc(
              armcRadians: double.nan,
              observerLatitudeRadians: 0,
              trueObliquityRadians: 0,
            ),
            throwsArgumentError,
          );

          context.close();
          expect(() => context.astrology.ayanamshaAtTt(tt), throwsStateError);
          expect(() => context.astrology.housesAtUt1(ut1), throwsStateError);
        },
      );
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}

double _normalizeRadians(double value) {
  final normalized = value % (2 * math.pi);
  return normalized < 0 ? normalized + 2 * math.pi : normalized;
}

double _normalizeSignedRadians(double value) {
  final normalized = _normalizeRadians(value);
  return normalized > math.pi ? normalized - 2 * math.pi : normalized;
}
