import 'dart:io';
import 'dart:math' as math;

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();
  const nativeDataRoot = '../taiyin-ephemeris/data';
  const majorBodiesPath = '$nativeDataRoot/ephemerides/opm2/major-bodies/600y';
  const centerOfBodyPath = '$nativeDataRoot/ephemerides/opm2/cob/full';
  const fixedCatalogPath =
      '$nativeDataRoot/stars/catalogs/stars-fixed-traditional.tsc1';

  group('TaiyinVisibilityApi native integration', () {
    late Taiyin runtime;
    late TaiyinContext context;
    final start = JulianDate<Ut1Scale>.fromDouble(2460408.75);
    final end = JulianDate<Ut1Scale>.fromDouble(2460409.75);
    final centerTt = JulianDate<TtScale>.fromDouble(2460409.0);
    const denver = TaiyinObserverLocation(
      longitudeDegrees: -104.9903,
      latitudeDegrees: 39.7392,
      heightMeters: 1609,
    );

    setUp(() {
      runtime = Taiyin.open(
        libraryPath: libraryPath,
        options: const TaiyinRuntimeOptions(
          sourcePaths: [majorBodiesPath, centerOfBodyPath],
          loadPackagedData: false,
          loadBuiltinEop: false,
        ),
      );
      runtime.starCatalog
        ..clear()
        ..addTsc1(fixedCatalogPath);
      context = runtime.createContext();
      context.configuration
        ..setGeocentricObserver(
          observerId: TaiyinBody.earth.id,
          centerId: TaiyinBody.earth.id,
        )
        ..setObserverLocation(denver)
        ..setStandardAtmosphere()
        ..useSolarDeflector()
        ..setApparentConfig(
          TaiyinApparentConfig(
            flags: const {
              TaiyinApparentFlag.spherical,
              TaiyinApparentFlag.lightTime,
              TaiyinApparentFlag.aberration,
              TaiyinApparentFlag.deflection,
            },
            outputFrame: TaiyinApparentFrame.trueEclipticOfDate,
          ),
        );
    });

    tearDown(() {
      context.close();
      runtime.starCatalog.clear();
    });

    test('searches lunar rise, set, custom horizons, and transits', () {
      final rise = context.visibility.moonRiseSetAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        flags: {TaiyinVisibilityFlag.refraction},
      );
      final fixedDiscRise = context.visibility.moonRiseSetAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        flags: {
          TaiyinVisibilityFlag.fixedDiscSize,
          TaiyinVisibilityFlag.noRefraction,
        },
      );
      final plainSet = context.visibility.moonRiseSetAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.set,
        limb: TaiyinVisibilityLimb.center,
        flags: {TaiyinVisibilityFlag.noRefraction},
      );
      final customSet = context.visibility.moonRiseSetAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.set,
        limb: TaiyinVisibilityLimb.center,
        horizonAltitudeRadians: math.pi / 180,
        flags: {TaiyinVisibilityFlag.noRefraction},
      );
      final transit = context.visibility.moonTransitAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.upperTransit,
      );

      expect(rise.diagnostic.status, 0);
      expect(rise.value.altitudeState, TaiyinVisibilityAltitudeState.crosses);
      expect(
        rise.value.crossingDirection,
        TaiyinVisibilityCrossingDirection.rising,
      );
      expect(
        rise.value.coordinate!.toDouble(),
        closeTo(2460409.020203506574, 5 / JulianDate.secondsPerDay),
      );
      expect(rise.value.residualRadians.abs(), lessThan(1e-8));
      expect(fixedDiscRise.diagnostic.status, 0);
      expect(fixedDiscRise.value.coordinate, isNotNull);
      expect(customSet.diagnostic.status, 0);
      expect(customSet.value.coordinate, isNotNull);
      expect(
        customSet.value.coordinate!.isBefore(plainSet.value.coordinate!),
        isTrue,
      );
      expect(transit.diagnostic.status, 0);
      expect(transit.value.coordinate, isNotNull);
      expect(
        transit.value.coordinate!.toDouble(),
        closeTo(2460409.293405554257, 2 / JulianDate.secondsPerDay),
      );
    });

    test('searches planetary rise, custom horizons, and transits', () {
      final defaultMercuryRise = context.visibility.planetRiseSetAtUt1(
        TaiyinBody.mercury,
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
      );
      final mercuryRise = context.visibility.planetRiseSetAtUt1(
        TaiyinBody.mercury,
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        flags: {TaiyinVisibilityFlag.refraction},
      );
      final unrefractedMercuryRise = context.visibility.planetRiseSetAtUt1(
        TaiyinBody.mercury,
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        flags: {TaiyinVisibilityFlag.noRefraction},
      );
      final customMercuryRise = context.visibility.planetRiseSetAtUt1(
        TaiyinBody.mercury,
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        horizonAltitudeRadians: math.pi / 180,
        flags: {TaiyinVisibilityFlag.noRefraction},
      );
      final venusTransit = context.visibility.planetTransitAtUt1(
        TaiyinBody.venus,
        start,
        end,
        event: TaiyinVisibilityEventKind.upperTransit,
      );

      expect(mercuryRise.diagnostic.status, 0);
      expect(
        mercuryRise.value.altitudeState,
        TaiyinVisibilityAltitudeState.crosses,
      );
      expect(
        mercuryRise.value.crossingDirection,
        TaiyinVisibilityCrossingDirection.rising,
      );
      expect(mercuryRise.value.coordinate, isNotNull);
      expect(
        defaultMercuryRise.value.coordinate!.toDouble(),
        closeTo(mercuryRise.value.coordinate!.toDouble(), 1e-12),
      );
      expect(
        unrefractedMercuryRise.value.coordinate!.toDouble(),
        closeTo(2460409.025837766007, 1 / JulianDate.secondsPerDay),
      );
      expect(mercuryRise.value.residualRadians.abs(), lessThan(1e-8));
      expect(unrefractedMercuryRise.diagnostic.status, 0);
      expect(customMercuryRise.diagnostic.status, 0);
      expect(customMercuryRise.value.coordinate, isNotNull);
      expect(
        customMercuryRise.value.coordinate!.isAfter(
          unrefractedMercuryRise.value.coordinate!,
        ),
        isTrue,
      );
      expect(venusTransit.diagnostic.status, 0);
      expect(
        venusTransit.value.coordinate!.toDouble(),
        closeTo(2460409.256011750549, 2 / JulianDate.secondsPerDay),
      );
    });

    test('searches solar events and evaluates fast solar approximations', () {
      final sunrise = context.visibility.solarRiseSetAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        flags: {TaiyinVisibilityFlag.refraction},
      );
      final customSunrise = context.visibility.solarRiseSetAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        horizonAltitudeRadians: math.pi / 180,
        flags: {TaiyinVisibilityFlag.refraction},
      );
      final fixedDiscSunrise = context.visibility.solarRiseSetAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        flags: {
          TaiyinVisibilityFlag.fixedDiscSize,
          TaiyinVisibilityFlag.noRefraction,
        },
      );
      final twilight = context.visibility.solarTwilightAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.set,
        twilight: TaiyinTwilightKind.nautical,
      );
      final transit = context.visibility.solarTransitAtUt1(
        start,
        end,
        event: TaiyinVisibilityEventKind.upperTransit,
      );
      final fastRiseSet = context.visibility.solarRiseSetFastAtTt(
        centerTt,
        denver,
      );
      final fastTransit = context.visibility.solarTransitFastAtTt(
        centerTt,
        denver,
      );

      expect(sunrise.diagnostic.status, 0);
      expect(
        sunrise.value.coordinate!.toDouble(),
        closeTo(2460409.022335537709, 2 / JulianDate.secondsPerDay),
      );
      expect(customSunrise.diagnostic.status, 0);
      expect(
        customSunrise.value.coordinate!.isAfter(sunrise.value.coordinate!),
        isTrue,
      );
      expect(fixedDiscSunrise.diagnostic.status, 0);
      expect(fixedDiscSunrise.value.coordinate, isNotNull);
      expect(twilight.diagnostic.status, 0);
      expect(
        twilight.value.coordinate!.toDouble(),
        closeTo(2460409.605691832025, 0.25 / JulianDate.secondsPerDay),
      );
      expect(transit.diagnostic.status, 0);
      expect(transit.value.coordinate, isNotNull);
      expect(fastRiseSet.diagnostic.status, 0);
      expect(fastRiseSet.value.rise, isNotNull);
      expect(fastRiseSet.value.set, isNotNull);
      expect(fastTransit.diagnostic.status, 0);
      expect(fastTransit.value.coordinate, isNotNull);
      expect(fastTransit.value.altitudeRadians.isFinite, isTrue);
      expect(fastTransit.value.azimuthRadians.isFinite, isTrue);
    });

    test('searches catalogued-star rise, custom horizons, and transits', () {
      final rise = context.visibility.starRiseSetAtUt1(
        'spica',
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        flags: {TaiyinVisibilityFlag.noRefraction},
      );
      final customRise = context.visibility.starRiseSetAtUt1(
        'spica',
        start,
        end,
        event: TaiyinVisibilityEventKind.rise,
        horizonAltitudeRadians: math.pi / 180,
        flags: {TaiyinVisibilityFlag.noRefraction},
      );
      final transit = context.visibility.starTransitAtUt1(
        'spica',
        start,
        end,
        event: TaiyinVisibilityEventKind.upperTransit,
      );

      expect(rise.diagnostic.status, 0);
      expect(rise.value.altitudeState, TaiyinVisibilityAltitudeState.crosses);
      expect(rise.value.coordinate, isNotNull);
      expect(
        rise.value.crossingDirection,
        TaiyinVisibilityCrossingDirection.rising,
      );
      expect(rise.value.residualRadians.abs(), lessThan(1e-8));
      // Deterministic regression baselines for this bundled Spica catalog and
      // native visibility configuration.
      expect(
        rise.value.coordinate!.toDouble(),
        closeTo(2460409.5787725416, 1 / JulianDate.secondsPerDay),
      );
      expect(customRise.diagnostic.status, 0);
      expect(customRise.value.coordinate, isNotNull);
      expect(
        customRise.value.coordinate!.isAfter(rise.value.coordinate!),
        isTrue,
      );
      expect(transit.diagnostic.status, 0);
      expect(transit.value.coordinate, isNotNull);
      expect(transit.value.residualRadians.abs(), lessThan(1e-8));
      expect(
        transit.value.coordinate!.toDouble(),
        closeTo(2460408.8043549885, 1 / JulianDate.secondsPerDay),
      );
    });

    test(
      'honors strict meteorology only for refracted visibility searches',
      () {
        final strictContext = runtime.createContext();
        addTearDown(strictContext.close);
        strictContext.configuration
          ..setGeocentricObserver(
            observerId: TaiyinBody.earth.id,
            centerId: TaiyinBody.earth.id,
          )
          ..setObserverLocation(denver)
          ..setAtmospherePolicy({
            TaiyinAtmospherePolicyFlag.allowStandardFallback,
          })
          ..useSolarDeflector()
          ..setApparentConfig(
            TaiyinApparentConfig(
              flags: const {
                TaiyinApparentFlag.spherical,
                TaiyinApparentFlag.lightTime,
                TaiyinApparentFlag.aberration,
                TaiyinApparentFlag.deflection,
              },
              outputFrame: TaiyinApparentFrame.trueEclipticOfDate,
            ),
          );

        expect(
          () => strictContext.visibility.solarRiseSetAtUt1(
            start,
            end,
            event: TaiyinVisibilityEventKind.rise,
            flags: {TaiyinVisibilityFlag.strictMeteorology},
          ),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.status,
              'status',
              isNot(0),
            ),
          ),
        );

        final unrefracted = strictContext.visibility.solarRiseSetAtUt1(
          start,
          end,
          event: TaiyinVisibilityEventKind.rise,
          flags: {
            TaiyinVisibilityFlag.strictMeteorology,
            TaiyinVisibilityFlag.noRefraction,
          },
        );
        expect(unrefracted.diagnostic.status, 0);
        expect(unrefracted.value.coordinate, isNotNull);
      },
    );

    test('maps no-event states and rejects invalid Dart inputs', () {
      context.configuration.setObserverLocation(
        const TaiyinObserverLocation(
          longitudeDegrees: 15.6333,
          latitudeDegrees: 78.2232,
          heightMeters: 10,
        ),
      );
      final polarStart = JulianDate<Ut1Scale>.fromDouble(2460482.4166666665);
      final polar = context.visibility.solarRiseSetAtUt1(
        polarStart,
        polarStart.add(const Duration(days: 1)),
        event: TaiyinVisibilityEventKind.set,
      );

      expect(polar.diagnostic.status, 0);
      expect(
        polar.value.altitudeState,
        TaiyinVisibilityAltitudeState.alwaysAbove,
      );
      expect(polar.value.coordinate, isNull);
      expect(
        () => context.visibility.planetRiseSetAtUt1(
          TaiyinBody.earth,
          start,
          end,
          event: TaiyinVisibilityEventKind.rise,
        ),
        throwsArgumentError,
      );
      expect(
        () => context.visibility.planetRiseSetAtUt1(
          TaiyinBody.mercury,
          start,
          end,
          event: TaiyinVisibilityEventKind.rise,
          flags: {TaiyinVisibilityFlag.fixedDiscSize},
        ),
        throwsArgumentError,
      );
      expect(
        () => context.visibility.starRiseSetAtUt1(
          'spica',
          start,
          end,
          event: TaiyinVisibilityEventKind.rise,
          flags: {
            TaiyinVisibilityFlag.refraction,
            TaiyinVisibilityFlag.noRefraction,
          },
        ),
        throwsArgumentError,
      );
      expect(
        () => context.visibility.starTransitAtUt1(
          'spica\u0000suffix',
          start,
          end,
          event: TaiyinVisibilityEventKind.upperTransit,
        ),
        throwsArgumentError,
      );
      expect(
        () => context.visibility.solarTransitAtUt1(
          start,
          end,
          event: TaiyinVisibilityEventKind.rise,
        ),
        throwsArgumentError,
      );
      expect(
        () => context.visibility.solarRiseSetAtUt1(
          end,
          start,
          event: TaiyinVisibilityEventKind.rise,
        ),
        throwsArgumentError,
      );
      context.close();
      expect(
        () => context.visibility.solarTransitAtUt1(
          start,
          end,
          event: TaiyinVisibilityEventKind.upperTransit,
        ),
        throwsStateError,
      );
    });
  }, skip: !nativeLibraryAvailable);
}
