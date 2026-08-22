import 'dart:math' as math;

import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  const nativeDataRoot = '../taiyin-ephemeris/data';
  const majorBodiesPath = '$nativeDataRoot/ephemerides/opm2/major-bodies/600y';
  const centerOfBodyPath = '$nativeDataRoot/ephemerides/opm2/cob/full';
  const fixedCatalogPath =
      '$nativeDataRoot/stars/catalogs/stars-fixed-traditional.tsc1';

  group('VisibilityApi native integration', () {
    late Ephemeris runtime;
    late EphemerisContext context;
    final start = JulianDate<Ut1Scale>.fromDouble(2460408.75);
    final end = JulianDate<Ut1Scale>.fromDouble(2460409.75);
    final centerTt = JulianDate<TtScale>.fromDouble(2460409.0);
    const denver = ObserverLocation(
      longitudeDegrees: -104.9903,
      latitudeDegrees: 39.7392,
      heightMeters: 1609,
    );

    setUp(() {
      runtime = Ephemeris.open(
        libraryPath: libraryPath,
        options: const RuntimeOptions(
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
          observerId: Body.earth.id,
          centerId: Body.earth.id,
        )
        ..setObserverLocation(denver)
        ..setStandardAtmosphere()
        ..useSolarDeflector()
        ..setApparentConfig(
          ApparentConfig(
            flags: const {
              ApparentFlag.spherical,
              ApparentFlag.lightTime,
              ApparentFlag.aberration,
              ApparentFlag.deflection,
            },
            outputFrame: ApparentFrame.trueEclipticOfDate,
          ),
        );
    });

    tearDown(() {
      context.close();
      runtime.starCatalog.clear();
    });

    test('searches lunar rise, set, custom horizons, and transits', () {
      final rise = context.visibility
          .moonRiseSetAtUt1(
            start,
            end,
            event: VisibilityEventKind.rise,
            flags: {VisibilityFlag.refraction},
          )
          .value;
      final fixedDiscRise = context.visibility
          .moonRiseSetAtUt1(
            start,
            end,
            event: VisibilityEventKind.rise,
            flags: {VisibilityFlag.fixedDiscSize, VisibilityFlag.noRefraction},
          )
          .value;
      final plainSet = context.visibility
          .moonRiseSetAtUt1(
            start,
            end,
            event: VisibilityEventKind.set,
            limb: VisibilityLimb.center,
            flags: {VisibilityFlag.noRefraction},
          )
          .value;
      final customSet = context.visibility
          .moonRiseSetAtUt1(
            start,
            end,
            event: VisibilityEventKind.set,
            limb: VisibilityLimb.center,
            horizonAltitudeRadians: math.pi / 180,
            flags: {VisibilityFlag.noRefraction},
          )
          .value;
      final transit = context.visibility
          .moonTransitAtUt1(start, end, event: VisibilityEventKind.upperTransit)
          .value;

      expect(rise.altitudeState, VisibilityAltitudeState.crosses);
      expect(rise.crossingDirection, VisibilityCrossingDirection.rising);
      expect(
        rise.coordinate!.toDouble(),
        closeTo(2460409.020203506574, 5 / JulianDate.secondsPerDay),
      );
      expect(rise.residualRadians.abs(), lessThan(1e-8));
      expect(fixedDiscRise.coordinate, isNotNull);
      expect(customSet.coordinate, isNotNull);
      expect(customSet.coordinate!.isBefore(plainSet.coordinate!), isTrue);
      expect(transit.coordinate, isNotNull);
      expect(
        transit.coordinate!.toDouble(),
        closeTo(2460409.293405554257, 2 / JulianDate.secondsPerDay),
      );
    });

    test('searches planetary rise, custom horizons, and transits', () {
      final defaultMercuryRise = context.visibility
          .planetRiseSetAtUt1(
            Body.mercury,
            start,
            end,
            event: VisibilityEventKind.rise,
          )
          .value;
      final mercuryRise = context.visibility
          .planetRiseSetAtUt1(
            Body.mercury,
            start,
            end,
            event: VisibilityEventKind.rise,
            flags: {VisibilityFlag.refraction},
          )
          .value;
      final unrefractedMercuryRise = context.visibility
          .planetRiseSetAtUt1(
            Body.mercury,
            start,
            end,
            event: VisibilityEventKind.rise,
            flags: {VisibilityFlag.noRefraction},
          )
          .value;
      final customMercuryRise = context.visibility
          .planetRiseSetAtUt1(
            Body.mercury,
            start,
            end,
            event: VisibilityEventKind.rise,
            horizonAltitudeRadians: math.pi / 180,
            flags: {VisibilityFlag.noRefraction},
          )
          .value;
      final venusTransit = context.visibility
          .planetTransitAtUt1(
            Body.venus,
            start,
            end,
            event: VisibilityEventKind.upperTransit,
          )
          .value;

      expect(mercuryRise.altitudeState, VisibilityAltitudeState.crosses);
      expect(mercuryRise.crossingDirection, VisibilityCrossingDirection.rising);
      expect(mercuryRise.coordinate, isNotNull);
      expect(
        defaultMercuryRise.coordinate!.toDouble(),
        closeTo(mercuryRise.coordinate!.toDouble(), 1e-12),
      );
      expect(
        unrefractedMercuryRise.coordinate!.toDouble(),
        closeTo(2460409.025837766007, 1 / JulianDate.secondsPerDay),
      );
      expect(mercuryRise.residualRadians.abs(), lessThan(1e-8));
      expect(customMercuryRise.coordinate, isNotNull);
      expect(
        customMercuryRise.coordinate!.isAfter(
          unrefractedMercuryRise.coordinate!,
        ),
        isTrue,
      );
      expect(
        venusTransit.coordinate!.toDouble(),
        closeTo(2460409.256011750549, 2 / JulianDate.secondsPerDay),
      );
    });

    test('searches solar events and evaluates fast solar approximations', () {
      final sunrise = context.visibility
          .solarRiseSetAtUt1(
            start,
            end,
            event: VisibilityEventKind.rise,
            flags: {VisibilityFlag.refraction},
          )
          .value;
      final customSunrise = context.visibility
          .solarRiseSetAtUt1(
            start,
            end,
            event: VisibilityEventKind.rise,
            horizonAltitudeRadians: math.pi / 180,
            flags: {VisibilityFlag.refraction},
          )
          .value;
      final fixedDiscSunrise = context.visibility
          .solarRiseSetAtUt1(
            start,
            end,
            event: VisibilityEventKind.rise,
            flags: {VisibilityFlag.fixedDiscSize, VisibilityFlag.noRefraction},
          )
          .value;
      final twilight = context.visibility
          .solarTwilightAtUt1(
            start,
            end,
            event: VisibilityEventKind.set,
            twilight: TwilightKind.nautical,
          )
          .value;
      final transit = context.visibility
          .solarTransitAtUt1(
            start,
            end,
            event: VisibilityEventKind.upperTransit,
          )
          .value;
      final fastRiseSet = context.visibility
          .solarRiseSetFastAtTt(centerTt, denver)
          .value;
      final fastTransit = context.visibility
          .solarTransitFastAtTt(centerTt, denver)
          .value;

      expect(
        sunrise.coordinate!.toDouble(),
        closeTo(2460409.022335537709, 2 / JulianDate.secondsPerDay),
      );
      expect(customSunrise.coordinate!.isAfter(sunrise.coordinate!), isTrue);
      expect(fixedDiscSunrise.coordinate, isNotNull);
      expect(
        twilight.coordinate!.toDouble(),
        closeTo(2460409.605691832025, 0.25 / JulianDate.secondsPerDay),
      );
      expect(transit.coordinate, isNotNull);
      expect(fastRiseSet.rise, isNotNull);
      expect(fastRiseSet.set, isNotNull);
      expect(fastTransit.coordinate, isNotNull);
      expect(fastTransit.altitudeRadians.isFinite, isTrue);
      expect(fastTransit.azimuthRadians.isFinite, isTrue);
    });

    test('searches catalogued-star rise, custom horizons, and transits', () {
      final rise = context.visibility
          .starRiseSetAtUt1(
            'spica',
            start,
            end,
            event: VisibilityEventKind.rise,
            flags: {VisibilityFlag.noRefraction},
          )
          .value;
      final customRise = context.visibility
          .starRiseSetAtUt1(
            'spica',
            start,
            end,
            event: VisibilityEventKind.rise,
            horizonAltitudeRadians: math.pi / 180,
            flags: {VisibilityFlag.noRefraction},
          )
          .value;
      final transit = context.visibility
          .starTransitAtUt1(
            'spica',
            start,
            end,
            event: VisibilityEventKind.upperTransit,
          )
          .value;

      expect(rise.altitudeState, VisibilityAltitudeState.crosses);
      expect(rise.coordinate, isNotNull);
      expect(rise.crossingDirection, VisibilityCrossingDirection.rising);
      expect(rise.residualRadians.abs(), lessThan(1e-8));
      // Deterministic regression baselines for this bundled Spica catalog and
      // native visibility configuration.
      expect(
        rise.coordinate!.toDouble(),
        closeTo(2460409.5787725416, 1 / JulianDate.secondsPerDay),
      );
      expect(customRise.coordinate, isNotNull);
      expect(customRise.coordinate!.isAfter(rise.coordinate!), isTrue);
      expect(transit.coordinate, isNotNull);
      expect(transit.residualRadians.abs(), lessThan(1e-8));
      expect(
        transit.coordinate!.toDouble(),
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
            observerId: Body.earth.id,
            centerId: Body.earth.id,
          )
          ..setObserverLocation(denver)
          ..setAtmospherePolicy({AtmospherePolicyFlag.allowStandardFallback})
          ..useSolarDeflector()
          ..setApparentConfig(
            ApparentConfig(
              flags: const {
                ApparentFlag.spherical,
                ApparentFlag.lightTime,
                ApparentFlag.aberration,
                ApparentFlag.deflection,
              },
              outputFrame: ApparentFrame.trueEclipticOfDate,
            ),
          );

        expect(
          () => strictContext.visibility
              .solarRiseSetAtUt1(
                start,
                end,
                event: VisibilityEventKind.rise,
                flags: {VisibilityFlag.strictMeteorology},
              )
              .value,
          throwsA(
            isA<EphemerisError>().having(
              (error) => error.status,
              'status',
              isNot(0),
            ),
          ),
        );

        final unrefracted = strictContext.visibility
            .solarRiseSetAtUt1(
              start,
              end,
              event: VisibilityEventKind.rise,
              flags: {
                VisibilityFlag.strictMeteorology,
                VisibilityFlag.noRefraction,
              },
            )
            .value;
        expect(unrefracted.coordinate, isNotNull);

        // The fast rise/set route enforces the same strict-meteorology rule:
        // strict refraction without complete atmosphere data fails, while
        // strict combined with noRefraction is allowed and ignores the flag.
        expect(
          () => strictContext.visibility
              .solarRiseSetFastAtTt(
                centerTt,
                denver,
                flags: {VisibilityFlag.strictMeteorology},
              )
              .value,
          throwsA(isA<EphemerisError>()),
        );
        final unrefractedFast = strictContext.visibility
            .solarRiseSetFastAtTt(
              centerTt,
              denver,
              flags: {
                VisibilityFlag.strictMeteorology,
                VisibilityFlag.noRefraction,
              },
            )
            .value;
        expect(unrefractedFast.rise, isNotNull);
      },
    );

    test(
      'honors limb, refraction, and disc-size options for fast rise/set',
      () {
        final upperGeometric = context.visibility
            .solarRiseSetFastAtTt(
              centerTt,
              denver,
              limb: VisibilityLimb.upper,
              flags: {VisibilityFlag.noRefraction},
            )
            .value;
        final centerGeometric = context.visibility
            .solarRiseSetFastAtTt(
              centerTt,
              denver,
              limb: VisibilityLimb.center,
              flags: {VisibilityFlag.noRefraction},
            )
            .value;
        final lowerFixed = context.visibility
            .solarRiseSetFastAtTt(
              centerTt,
              denver,
              limb: VisibilityLimb.lower,
              flags: {
                VisibilityFlag.fixedDiscSize,
                VisibilityFlag.noRefraction,
              },
            )
            .value;
        final upperRefracted = context.visibility
            .solarRiseSetFastAtTt(
              centerTt,
              denver,
              limb: VisibilityLimb.upper,
              flags: {VisibilityFlag.refraction},
            )
            .value;

        expect(upperGeometric.rise, isNotNull);
        expect(upperGeometric.set, isNotNull);
        expect(centerGeometric.rise, isNotNull);
        expect(lowerFixed.rise, isNotNull);
        expect(upperRefracted.rise, isNotNull);

        // At sunrise the upper limb crosses the horizon first, then the center,
        // then the lower limb; refraction raises the apparent altitude, so the
        // refracted event precedes the geometric one for the same limb.
        expect(upperGeometric.rise!.isBefore(centerGeometric.rise!), isTrue);
        expect(centerGeometric.rise!.isBefore(lowerFixed.rise!), isTrue);
        expect(upperRefracted.rise!.isBefore(upperGeometric.rise!), isTrue);

        // Mutually exclusive refraction flags are rejected by the Dart API.
        expect(
          () => context.visibility
              .solarRiseSetFastAtTt(
                centerTt,
                denver,
                flags: {VisibilityFlag.refraction, VisibilityFlag.noRefraction},
              )
              .value,
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('maps no-event states and rejects invalid Dart inputs', () {
      context.configuration.setObserverLocation(
        const ObserverLocation(
          longitudeDegrees: 15.6333,
          latitudeDegrees: 78.2232,
          heightMeters: 10,
        ),
      );
      final polarStart = JulianDate<Ut1Scale>.fromDouble(2460482.4166666665);
      final polar = context.visibility
          .solarRiseSetAtUt1(
            polarStart,
            polarStart.add(const Duration(days: 1)),
            event: VisibilityEventKind.set,
          )
          .value;

      expect(polar.altitudeState, VisibilityAltitudeState.alwaysAbove);
      expect(polar.coordinate, isNull);
      expect(
        () => context.visibility
            .planetRiseSetAtUt1(
              Body.earth,
              start,
              end,
              event: VisibilityEventKind.rise,
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.visibility
            .planetRiseSetAtUt1(
              Body.mercury,
              start,
              end,
              event: VisibilityEventKind.rise,
              flags: {VisibilityFlag.fixedDiscSize},
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.visibility
            .starRiseSetAtUt1(
              'spica',
              start,
              end,
              event: VisibilityEventKind.rise,
              flags: {VisibilityFlag.refraction, VisibilityFlag.noRefraction},
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.visibility
            .starTransitAtUt1(
              'spica\u0000suffix',
              start,
              end,
              event: VisibilityEventKind.upperTransit,
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.visibility
            .solarTransitAtUt1(start, end, event: VisibilityEventKind.rise)
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.visibility
            .solarRiseSetAtUt1(end, start, event: VisibilityEventKind.rise)
            .value,
        throwsArgumentError,
      );
      context.close();
      expect(
        () => context.visibility
            .solarTransitAtUt1(
              start,
              end,
              event: VisibilityEventKind.upperTransit,
            )
            .value,
        throwsStateError,
      );
    });
  }, skip: !nativeLibraryAvailable);
}
