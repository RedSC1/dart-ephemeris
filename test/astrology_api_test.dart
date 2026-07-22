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

      test('supports generic sidereal ecliptic, equatorial, and XYZ modes', () {
        final structured = context.astrology.siderealPositionAtTt(
          TaiyinBody.sun,
          tt,
          ayanamsha: TaiyinAyanamsha.lahiri,
          flags: {TaiyinPositionFlag.speed},
        );
        final ecliptic = context.astrology.siderealCoordinatesAtTt(
          TaiyinBody.sun,
          tt,
          ayanamsha: TaiyinAyanamsha.lahiri,
          flags: {TaiyinPositionFlag.speed},
        );
        final equatorial = context.astrology.siderealCoordinatesAtTt(
          TaiyinBody.sun,
          tt,
          ayanamsha: TaiyinAyanamsha.lahiri,
          flags: {TaiyinPositionFlag.speed, TaiyinPositionFlag.equatorial},
        );
        final equatorialXyz = context.astrology.siderealCoordinatesAtTt(
          TaiyinBody.sun,
          tt,
          ayanamsha: TaiyinAyanamsha.lahiri,
          flags: {
            TaiyinPositionFlag.speed,
            TaiyinPositionFlag.equatorial,
            TaiyinPositionFlag.xyz,
          },
        );
        final meanEquatorial = context.astrology.siderealCoordinatesAtTt(
          TaiyinBody.sun,
          tt,
          ayanamsha: TaiyinAyanamsha.lahiri,
          flags: {
            TaiyinPositionFlag.speed,
            TaiyinPositionFlag.equatorial,
            TaiyinPositionFlag.noNutation,
          },
        );
        final faganEquatorial = context.astrology.siderealCoordinatesAtTt(
          TaiyinBody.sun,
          tt,
          flags: {
            TaiyinPositionFlag.speed,
            TaiyinPositionFlag.equatorial,
            TaiyinPositionFlag.radians,
          },
        );
        final explicitMean = context.astrology.siderealCoordinatesAtTt(
          TaiyinBody.sun,
          tt,
          ayanamsha: TaiyinAyanamsha.lahiri,
          flags: {TaiyinPositionFlag.noNutation},
        );
        final genericUt1 = context.astrology.siderealCoordinatesAtUt1(
          TaiyinBody.sun,
          ut1,
          flags: {TaiyinPositionFlag.xyz},
        );

        expect(
          ecliptic.value.coordinateFrame,
          TaiyinSiderealCoordinateFrame.meanEclipticOfDate,
        );
        expect(
          equatorial.value.coordinateFrame,
          TaiyinSiderealCoordinateFrame.trueEquatorOfDate,
        );
        expect(
          equatorialXyz.value.coordinateFrame,
          TaiyinSiderealCoordinateFrame.trueEquatorOfDate,
        );
        expect(
          meanEquatorial.value.coordinateFrame,
          TaiyinSiderealCoordinateFrame.meanEquatorOfDate,
        );
        expect(ecliptic.value.isCartesian, isFalse);
        expect(ecliptic.value.isEquatorial, isFalse);
        expect(equatorial.value.isCartesian, isFalse);
        expect(equatorial.value.isEquatorial, isTrue);
        expect(equatorialXyz.value.isCartesian, isTrue);
        expect(equatorialXyz.value.isEquatorial, isTrue);
        expect(
          equatorialXyz.value.flags,
          containsAll({
            TaiyinPositionFlag.speed,
            TaiyinPositionFlag.equatorial,
            TaiyinPositionFlag.xyz,
            TaiyinPositionFlag.radians,
          }),
        );
        expect(ecliptic.value.values, hasLength(6));
        expect(ecliptic.value.values.every((value) => value.isFinite), isTrue);
        expect(
          ecliptic.value.values[0],
          closeTo(structured.value.siderealLongitudeRadians, 1e-12),
        );
        expect(
          ecliptic.value.values[1],
          closeTo(structured.value.latitudeRadians, 1e-12),
        );
        expect(
          ecliptic.value.values[2],
          closeTo(structured.value.distanceAu, 1e-12),
        );
        expect(
          ecliptic.value.values[3],
          closeTo(structured.value.siderealLongitudeRateRadiansPerDay, 1e-12),
        );

        final nativeTrueEquatorial = context.positionTt(
          TaiyinBody.sun,
          tt,
          flags: {
            TaiyinPositionFlag.speed,
            TaiyinPositionFlag.equatorial,
            TaiyinPositionFlag.radians,
          },
        );
        final nativeMeanEquatorial = context.positionTt(
          TaiyinBody.sun,
          tt,
          flags: {
            TaiyinPositionFlag.speed,
            TaiyinPositionFlag.equatorial,
            TaiyinPositionFlag.noNutation,
            TaiyinPositionFlag.radians,
          },
        );
        for (var index = 0; index < 6; index++) {
          expect(
            equatorial.value.values[index],
            closeTo(nativeTrueEquatorial.values[index], 1e-12),
          );
          expect(
            meanEquatorial.value.values[index],
            closeTo(nativeMeanEquatorial.values[index], 1e-12),
          );
          expect(
            faganEquatorial.value.values[index],
            closeTo(equatorial.value.values[index], 1e-12),
          );
        }

        final xyz = equatorialXyz.value.coordinates;
        final xy = math.sqrt(xyz[0] * xyz[0] + xyz[1] * xyz[1]);
        expect(
          _normalizeRadians(math.atan2(xyz[1], xyz[0])),
          closeTo(equatorial.value.values[0], 1e-12),
        );
        expect(
          math.atan2(xyz[2], xy),
          closeTo(equatorial.value.values[1], 1e-12),
        );
        expect(
          math.sqrt(xy * xy + xyz[2] * xyz[2]),
          closeTo(equatorial.value.values[2], 1e-12),
        );
        expect(
          explicitMean.value.values[0],
          closeTo(
            context.astrology
                .siderealCoordinatesAtTt(
                  TaiyinBody.sun,
                  tt,
                  ayanamsha: TaiyinAyanamsha.lahiri,
                )
                .value
                .values[0],
            1e-12,
          ),
        );
        expect(genericUt1.value.isCartesian, isTrue);
        expect(
          genericUt1.value.values.every((value) => value.isFinite),
          isTrue,
        );
        expect(genericUt1.diagnostic.status, 0);
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

        final finalSpan = _normalizeRadians(
          houses.cuspLongitudesRadians[0] - houses.cuspLongitudesRadians[11],
        );
        final wrapped = context.astrology.housePositionOf(
          houses,
          houses.cuspLongitudesRadians[11] + finalSpan / 2,
        );
        expect(wrapped.houseNumber, 12);
        expect(wrapped.fraction, closeTo(0.5, 1e-12));
        expect(wrapped.continuousHousePosition, closeTo(12.5, 1e-12));
      });

      test(
        'maps house fallbacks and suppresses discontinuous whole-sign rates',
        () {
          context.configuration.setObserverLocation(
            const TaiyinObserverLocation(
              longitudeDegrees: 0,
              latitudeDegrees: 70,
            ),
          );
          final fallback = context.astrology.housesAtUt1(
            ut1,
            system: TaiyinHouseSystem.placidus,
          );
          final porphyry = context.astrology.housesAtUt1(
            ut1,
            system: TaiyinHouseSystem.porphyry,
          );

          expect(fallback.requestedSystem, TaiyinHouseSystem.placidus);
          expect(fallback.resolvedSystem, TaiyinHouseSystem.porphyry);
          expect(
            fallback.flags,
            containsAll({
              TaiyinHouseResultFlag.usedFallback,
              TaiyinHouseResultFlag.fallbackPorphyry,
            }),
          );
          for (var index = 0; index < 12; index++) {
            expect(
              _normalizeSignedRadians(
                fallback.cuspLongitudesRadians[index] -
                    porphyry.cuspLongitudesRadians[index],
              ),
              closeTo(0, 1e-12),
            );
          }

          final ingress = _findWholeSignIngress(context, ut1);
          expect(
            ingress.flags,
            contains(TaiyinHouseResultFlag.speedUnavailable),
          );
          expect(ingress.armcRateRadiansPerDay.isNaN, isTrue);
          expect(ingress.cuspLongitudeRatesRadiansPerDay[0].isNaN, isTrue);
        },
      );

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
          expect(
            () => context.astrology.housesFromArmc(
              armcRadians: 0,
              observerLatitudeRadians: math.pi / 2,
              trueObliquityRadians: math.pi / 6,
            ),
            throwsRangeError,
          );
          expect(
            () => context.astrology.housesFromArmc(
              armcRadians: 0,
              observerLatitudeRadians: 0,
              trueObliquityRadians: 0,
            ),
            throwsRangeError,
          );
          expect(
            () => TaiyinHousePosition(
              houseNumber: 0,
              fraction: 0,
              continuousHousePosition: 0,
            ),
            throwsRangeError,
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

TaiyinHouses _findWholeSignIngress(
  TaiyinContext context,
  JulianDate<Ut1Scale> start,
) {
  var lowerJulianDate = start.toDouble();
  var lower = context.astrology.housesAtUt1(
    JulianDate<Ut1Scale>.fromDouble(lowerJulianDate),
    system: TaiyinHouseSystem.wholeSign,
  );
  var upperJulianDate = double.nan;

  for (var sample = 1; sample <= 288; sample++) {
    final sampleJulianDate = start.toDouble() + sample * 5 / 1440;
    final candidate = context.astrology.housesAtUt1(
      JulianDate<Ut1Scale>.fromDouble(sampleJulianDate),
      system: TaiyinHouseSystem.wholeSign,
    );
    if (_angularDistance(
          candidate.cuspLongitudesRadians[0],
          lower.cuspLongitudesRadians[0],
        ) >
        math.pi / 180) {
      upperJulianDate = sampleJulianDate;
      break;
    }
    lowerJulianDate = sampleJulianDate;
    lower = candidate;
  }
  if (!upperJulianDate.isFinite) {
    throw StateError('Could not find a Whole Sign cusp ingress.');
  }

  for (var iteration = 0; iteration < 48; iteration++) {
    final middleJulianDate = (lowerJulianDate + upperJulianDate) / 2;
    final middle = context.astrology.housesAtUt1(
      JulianDate<Ut1Scale>.fromDouble(middleJulianDate),
      system: TaiyinHouseSystem.wholeSign,
    );
    if (_angularDistance(
          middle.cuspLongitudesRadians[0],
          lower.cuspLongitudesRadians[0],
        ) <
        1e-12) {
      lowerJulianDate = middleJulianDate;
      lower = middle;
    } else {
      upperJulianDate = middleJulianDate;
    }
  }
  return context.astrology.housesAtUt1(
    JulianDate<Ut1Scale>.fromDouble((lowerJulianDate + upperJulianDate) / 2),
    system: TaiyinHouseSystem.wholeSign,
  );
}

double _angularDistance(double left, double right) =>
    _normalizeSignedRadians(left - right).abs();
