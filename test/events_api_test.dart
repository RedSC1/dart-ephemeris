import 'dart:math' as math;

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  const majorBodiesPath =
      '../taiyin-ephemeris/data/ephemerides/opm2/major-bodies/600y';

  group(
    'TaiyinEventsApi native integration',
    () {
      late Taiyin runtime;
      late TaiyinContext context;

      setUp(() {
        runtime = Taiyin.open(
          libraryPath: libraryPath,
          options: const TaiyinRuntimeOptions(
            sourcePaths: [majorBodiesPath],
            loadPackagedData: false,
            loadBuiltinEop: false,
          ),
        );
        context = runtime.createContext();
        context.configuration
          ..setGeocentricObserver(
            observerId: TaiyinBody.earth.id,
            centerId: TaiyinBody.earth.id,
          )
          ..setStandardAtmosphere()
          ..useSolarDeflector()
          ..setApparentConfig(
            TaiyinApparentConfig(
              flags: {
                TaiyinApparentFlag.spherical,
                TaiyinApparentFlag.lightTime,
                TaiyinApparentFlag.aberration,
                TaiyinApparentFlag.deflection,
              },
              outputFrame: TaiyinApparentFrame.trueEclipticOfDate,
            ),
          )
          ..setRouteRule(TaiyinRouteRule.opm2);
      });

      tearDown(() => context.close());

      test('searches scalar solar and lunar longitude routes', () {
        const equinoxEstimate = 2460380.5;
        final solarUt1 = context.events.solarLongitudeAtUt1(
          0,
          JulianDate<Ut1Scale>.fromDouble(equinoxEstimate),
        );
        final reverseSolar = context.events.solarLongitudeAtUt1(
          0,
          JulianDate<Ut1Scale>.fromDouble(2460395),
          options: {TaiyinEventSearchOption.reverse},
        );
        final solarTt = context.events.solarLongitudeAtTt(
          0,
          JulianDate<TtScale>.fromDouble(equinoxEstimate),
        );
        final moonUt1 = context.events.moonLongitudeAtUt1(
          math.pi / 2,
          JulianDate<Ut1Scale>.fromDouble(equinoxEstimate),
        );
        final moonTt = context.events.moonLongitudeAtTt(
          math.pi / 2,
          JulianDate<TtScale>.fromDouble(equinoxEstimate),
        );

        expect(solarUt1.diagnostic.status, 0);
        expect(solarUt1.value.toDouble(), closeTo(2460389.6294463626, 5e-8));
        expect(
          reverseSolar.value.toDouble(),
          closeTo(2460389.6294463626, 5e-8),
        );
        expect(
          solarTt.value.isAfter(
            JulianDate<TtScale>.fromDouble(equinoxEstimate),
          ),
          isTrue,
        );
        expect(
          moonUt1.value.isAfter(
            JulianDate<Ut1Scale>.fromDouble(equinoxEstimate),
          ),
          isTrue,
        );
        expect(
          moonTt.value.isAfter(JulianDate<TtScale>.fromDouble(equinoxEstimate)),
          isTrue,
        );
        expect(
          context.events.recommendedLongitudeSearchStepDays(TaiyinBody.mercury),
          greaterThan(0),
        );
        expect(
          context.events.recommendedAspectSearchStepDays(
            TaiyinBody.moon,
            TaiyinBody.sun,
          ),
          greaterThan(0),
        );
      });

      test('searches bounded longitude, station, aspect, and phase routes', () {
        final utStart = JulianDate<Ut1Scale>.fromDouble(2460380.5);
        final utEnd = JulianDate<Ut1Scale>.fromDouble(2460420.5);
        final ttStart = JulianDate<TtScale>.fromDouble(2460380.5);
        final ttEnd = JulianDate<TtScale>.fromDouble(2460420.5);

        final longitudeUt1 = context.events.longitudeCrossingsAtUt1(
          TaiyinBody.sun,
          0,
          utStart,
          JulianDate<Ut1Scale>.fromDouble(2460395),
          maxStepDays: 2,
        );
        final longitudeTt = context.events.longitudeCrossingsAtTt(
          TaiyinBody.sun,
          0,
          ttStart,
          JulianDate<TtScale>.fromDouble(2460395),
          maxStepDays: 2,
        );
        final stationsUt1 = context.events.longitudeStationsAtUt1(
          TaiyinBody.mercury,
          JulianDate<Ut1Scale>.fromDouble(2452878.5),
          JulianDate<Ut1Scale>.fromDouble(2452882.5),
          maxStepDays: 0.25,
        );
        final stationsTt = context.events.longitudeStationsAtTt(
          TaiyinBody.mercury,
          JulianDate<TtScale>.fromDouble(2452878.5),
          JulianDate<TtScale>.fromDouble(2452882.5),
          maxStepDays: 0.25,
        );
        final aspectsUt1 = context.events.aspectCrossingsAtUt1(
          TaiyinBody.moon,
          TaiyinBody.sun,
          0,
          utStart,
          utEnd,
          maxStepDays: 1,
        );
        final aspectsTt = context.events.aspectCrossingsAtTt(
          TaiyinBody.moon,
          TaiyinBody.sun,
          math.pi / 2,
          ttStart,
          JulianDate<TtScale>.fromDouble(2460395.5),
          maxStepDays: 0.5,
        );
        final exactUt1 = context.events.exactAspectsAtUt1(
          TaiyinBody.moon,
          TaiyinBody.sun,
          [math.pi / 2],
          utStart,
          utEnd,
          maxStepDays: 0.5,
        );
        final exactTt = context.events.exactAspectsAtTt(
          TaiyinBody.moon,
          TaiyinBody.sun,
          [math.pi / 2],
          ttStart,
          ttEnd,
          maxStepDays: 0.5,
        );
        final phasesUt1 = context.events.lunarPhaseCrossingsAtUt1(
          0,
          utStart,
          utEnd,
          maxStepDays: 1,
        );
        final phasesTt = context.events.lunarPhaseCrossingsAtTt(
          math.pi / 2,
          ttStart,
          JulianDate<TtScale>.fromDouble(2460395.5),
          maxStepDays: 0.5,
        );

        expect(longitudeUt1.value, hasLength(1));
        expect(
          longitudeUt1.value.single.toDouble(),
          closeTo(2460389.6294463626, 5e-8),
        );
        expect(longitudeTt.value, hasLength(1));
        expect(stationsUt1.value, hasLength(1));
        expect(
          stationsUt1.value.single.coordinate.toDouble(),
          closeTo(2452880.070395550, 2 / 86400),
        );
        expect(stationsTt.value, isNotEmpty);
        expect(aspectsUt1.value, hasLength(1));
        expect(aspectsTt.value, hasLength(1));
        expect(exactUt1.value, hasLength(greaterThanOrEqualTo(2)));
        expect(exactTt.value, hasLength(greaterThanOrEqualTo(2)));
        expect(
          exactUt1.value,
          orderedEquals(
            [...exactUt1.value]
              ..sort((a, b) => a.coordinate.compareTo(b.coordinate)),
          ),
        );
        expect(phasesUt1.value, hasLength(1));
        expect(
          phasesUt1.value.single.toDouble(),
          closeTo(aspectsUt1.value.single.toDouble(), 5e-8),
        );
        expect(phasesTt.value, hasLength(1));
      });

      test('reports insufficient bounded-search result capacity', () {
        expect(
          () => context.events.lunarPhaseCrossingsAtUt1(
            0,
            JulianDate<Ut1Scale>.fromDouble(2460380.5),
            JulianDate<Ut1Scale>.fromDouble(2460450.5),
            maxStepDays: 1,
            maxResults: 1,
          ),
          throwsA(isA<TaiyinException>()),
        );
      });

      test('searches extrema and global and local solar transits', () {
        final elongation = context.events.greatestElongationAtUt1(
          TaiyinBody.mercury,
          JulianDate<Ut1Scale>.fromDouble(2460369.5),
          JulianDate<Ut1Scale>.fromDouble(2460414.5),
        );
        final minimumUt1 = context.events.minimumAngularSeparationAtUt1(
          TaiyinBody.moon,
          TaiyinBody.sun,
          JulianDate<Ut1Scale>.fromDouble(2460408.5),
          JulianDate<Ut1Scale>.fromDouble(2460410),
          maxStepDays: 0.05,
        );
        final minimumTt = context.events.minimumAngularSeparationAtTt(
          TaiyinBody.moon,
          TaiyinBody.sun,
          JulianDate<TtScale>.fromDouble(2460408.5),
          JulianDate<TtScale>.fromDouble(2460410),
          maxStepDays: 0.05,
        );
        final transit = context.events.nextSolarTransitAtUt1(
          TaiyinBody.mercury,
          JulianDate<Ut1Scale>.fromDouble(2458799),
        );
        const newYork = TaiyinObserverLocation(
          longitudeDegrees: -74.0060,
          latitudeDegrees: 40.7128,
          heightMeters: 10,
        );
        final localFromGlobal = context.events.localSolarTransitAtUt1(
          transit.value,
          newYork,
        );
        final localSearch = context.events.nextLocalSolarTransitAtUt1(
          TaiyinBody.mercury,
          JulianDate<Ut1Scale>.fromDouble(2458799),
          newYork,
        );

        expect(elongation.value.kind, TaiyinGreatestElongationKind.eastern);
        expect(
          elongation.value.coordinate.toDouble(),
          closeTo(2460394.440334700048, 0.02),
        );
        expect(
          elongation.value.elongationRadians,
          inInclusiveRange(15 * math.pi / 180, 30 * math.pi / 180),
        );
        expect(
          minimumUt1.value.coordinate.toDouble(),
          closeTo(2460409.262042756, 2 / 86400),
        );
        expect(
          minimumUt1.value.separationRadians,
          closeTo(
            0.347680257505077 * math.pi / 180,
            0.1 / 3600 * math.pi / 180,
          ),
        );
        expect(minimumTt.value.separationRadians, lessThan(0.02));
        expect(
          transit.value.greatest.toDouble(),
          closeTo(2458799.138751322404, 1 / 86400),
        );
        expect(transit.value.kinds, contains(TaiyinSolarTransitKind.fullDisk));
        expect(transit.value.t1, isNotNull);
        expect(transit.value.t4, isNotNull);
        expect(transit.value.t1!.isBefore(transit.value.greatest), isTrue);
        expect(transit.value.t4!.isAfter(transit.value.greatest), isTrue);
        expect(
          (localFromGlobal.value.topocentric.greatest.toDouble() -
                  transit.value.greatest.toDouble())
              .abs(),
          greaterThan(0.05 / 86400),
        );
        expect(
          localSearch.value.visibilityFlags,
          contains(TaiyinSolarTransitVisibilityFlag.visibleAtObserver),
        );
        expect(
          localSearch.value.contactSunAltitudeDegrees.every(
            (value) => value.isFinite,
          ),
          isTrue,
        );
        expect(
          localSearch.value.contactSunAzimuthDegrees.every(
            (value) => value.isFinite,
          ),
          isTrue,
        );
      });

      test(
        'rejects invalid Dart inputs and use after close',
        () {
          final start = JulianDate<Ut1Scale>.fromDouble(2460380.5);
          final end = JulianDate<Ut1Scale>.fromDouble(2460390.5);

          expect(
            () => context.events.solarLongitudeAtUt1(
              0,
              start,
              positionFlags: {TaiyinPositionFlag.xyz},
            ),
            throwsArgumentError,
          );
          expect(
            () => context.events.aspectCrossingsAtUt1(
              TaiyinBody.sun,
              TaiyinBody.sun,
              0,
              start,
              end,
              maxStepDays: 1,
            ),
            throwsArgumentError,
          );
          expect(
            () => context.events.exactAspectsAtUt1(
              TaiyinBody.moon,
              TaiyinBody.sun,
              const [],
              start,
              end,
              maxStepDays: 1,
            ),
            throwsArgumentError,
          );
          expect(
            () => context.events.lunarPhaseCrossingsAtUt1(
              0,
              start,
              end,
              maxStepDays: 1,
              maxResults: 0,
            ),
            throwsRangeError,
          );
          expect(
            () => context.events.nextSolarTransitAtUt1(TaiyinBody.mars, start),
            throwsArgumentError,
          );
          expect(
            () => context.events.nextLocalSolarTransitAtUt1(
              TaiyinBody.mercury,
              start,
              const TaiyinObserverLocation(
                longitudeDegrees: 0,
                latitudeDegrees: 0,
              ),
              options: {
                TaiyinEventSearchOption.refraction,
                TaiyinEventSearchOption.noRefraction,
              },
            ),
            throwsArgumentError,
          );
          context.close();
          expect(
            () => context.events.solarLongitudeAtUt1(0, start),
            throwsStateError,
          );
        },
        skip: !nativeLibraryAvailable
            ? 'native test library is unavailable'
            : false,
      );
    },
    skip: !nativeLibraryAvailable
        ? 'native test library is unavailable'
        : false,
  );
}
