import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  group(
    'ObservedApi native integration',
    () {
      late EphemerisContext taiyin;
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final utc = AstroDateTime(2024, 4, 8, 18);

      setUp(() {
        taiyin = Ephemeris.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('maps complete UT1 apparent state and diagnostic', () {
        final result = taiyin.observed.atUt1(
          Body.sun,
          ut1,
          flags: {ObservedFlag.speed, ObservedFlag.truePosition},
        );

        expect(result.body, Body.sun);
        expect(result.status, 0);
        expect(result.diagnostic.status, 0);
        expect(result.diagnostic.targetId, Body.sun.id);
        expect(result.apparent.body, Body.sun);
        expect(result.apparent.status, 0);
        expect(result.apparent.bodyMaskBit, 1);
        expect(result.apparent.longitudeRadians.isFinite, isTrue);
        expect(result.apparent.latitudeRadians.isFinite, isTrue);
        expect(result.apparent.distanceAu, greaterThan(0));
        expect(result.apparent.lightTimeDays.isFinite, isTrue);
        expect(
          result.apparent.geometricState.positionAu.values.every(
            (value) => value.isFinite,
          ),
          isTrue,
        );
        expect(
          result.apparent.apparentState.velocityAuPerDay.values.every(
            (value) => value.isFinite,
          ),
          isTrue,
        );
        expect(
          result.apparent.geometricState.accelerationAuPerDay2.values,
          everyElement(0),
        );
        expect(
          result.apparent.apparentState.accelerationAuPerDay2.values,
          everyElement(0),
        );
        expect(result.horizontal, isNull);
        expect(result.horizontalRates, isNull);
        expect(result.refractedHorizontal, isNull);
        expect(result.refractedHorizontalRates, isNull);
      });

      test('single and batch UT1 routes preserve order and values', () {
        const bodies = [Body.sun, Body.moon];
        const flags = {ObservedFlag.truePosition};
        final batch = taiyin.observed.batchAtUt1(bodies, ut1, flags: flags);

        expect(batch, hasLength(2));
        for (var index = 0; index < bodies.length; index++) {
          final single = taiyin.observed.atUt1(
            bodies[index],
            ut1,
            flags: flags,
          );
          expect(batch[index].body, bodies[index]);
          expect(batch[index].diagnostic.targetId, bodies[index].id);
          expect(
            batch[index].apparent.longitudeRadians,
            closeTo(single.apparent.longitudeRadians, 1e-15),
          );
          expect(
            batch[index].apparent.latitudeRadians,
            closeTo(single.apparent.latitudeRadians, 1e-15),
          );
          expect(
            batch[index].apparent.distanceAu,
            closeTo(single.apparent.distanceAu, 1e-15),
          );
        }
      });

      test('throws with the failed target when any batch body fails', () {
        expect(
          () => taiyin.observed.batchAtUt1(
            const [Body.sun, Body.mars],
            ut1,
            flags: {ObservedFlag.truePosition},
          ),
          throwsA(
            isA<EphemerisError>()
                .having((error) => error.status, 'status', isNot(0))
                .having(
                  (error) => error.diagnostic?.targetId,
                  'failed target',
                  Body.mars.id,
                )
                .having(
                  (error) => error.diagnostics,
                  'all native batch diagnostics',
                  hasLength(2),
                ),
          ),
        );
      });

      test('covers UTC single and batch routes with precise time data', () {
        const flags = {ObservedFlag.truePosition};
        final single = taiyin.observed.atUtc(Body.sun, utc, flags: flags);
        final batch = taiyin.observed.batchAtUtc(
          const [Body.sun, Body.moon],
          utc,
          flags: flags,
        );

        expect(single.status, 0);
        expect(single.diagnostic.julianDateTdb.toDouble().isFinite, isTrue);
        expect(single.diagnostic.timeScaleRoute, TimeScaleRoute.none);
        expect(single.diagnostic.timeScaleFlags, isEmpty);
        expect(batch, hasLength(2));
        expect(batch.every((result) => result.status == 0), isTrue);
        expect(
          batch.every((result) => result.apparent.longitudeRadians.isFinite),
          isTrue,
        );
      });

      test('calculates topocentric horizontal coordinates and rates', () {
        taiyin.configuration.setObserverLocation(
          const ObserverLocation(
            longitudeDegrees: 116.391,
            latitudeDegrees: 39.907,
            heightMeters: 50,
          ),
        );

        final result = taiyin.observed.atUt1(
          Body.sun,
          ut1,
          flags: {
            ObservedFlag.speed,
            ObservedFlag.topocentric,
            ObservedFlag.horizontal,
            ObservedFlag.truePosition,
          },
        );

        expect(result.horizontal, isNotNull);
        expect(result.horizontal!.azimuthRadians.isFinite, isTrue);
        expect(result.horizontal!.altitudeRadians.isFinite, isTrue);
        expect(result.horizontal!.distanceAu, greaterThan(0));
        expect(result.horizontalRates, isNotNull);
        expect(result.horizontalRates!.azimuthRadiansPerDay.isFinite, isTrue);
        expect(result.horizontalRates!.altitudeRadiansPerDay.isFinite, isTrue);
        expect(result.horizontalRates!.distanceAuPerDay.isFinite, isTrue);
        expect(result.refractedHorizontal, isNull);
      });

      test('supports atmosphere fallback and strict meteorology', () {
        taiyin.configuration
          ..setObserverLocation(
            const ObserverLocation(
              longitudeDegrees: 0,
              latitudeDegrees: 0,
              heightMeters: 0,
            ),
          )
          ..setAtmospherePolicy({AtmospherePolicyFlag.allowStandardFallback});

        final fallback = taiyin.observed.atUt1(
          Body.sun,
          ut1,
          flags: {
            ObservedFlag.topocentric,
            ObservedFlag.refraction,
            ObservedFlag.truePosition,
          },
        );

        expect(fallback.horizontal, isNotNull);
        expect(fallback.refractedHorizontal, isNotNull);
        expect(fallback.refractedHorizontal!.altitudeRadians.isFinite, isTrue);
        expect(
          fallback.refractedHorizontal!.altitudeRadians,
          isNot(fallback.horizontal!.altitudeRadians),
        );

        expect(
          () => taiyin.observed.atUt1(
            Body.sun,
            ut1,
            flags: {
              ObservedFlag.topocentric,
              ObservedFlag.refraction,
              ObservedFlag.truePosition,
              ObservedFlag.strictMeteorology,
            },
          ),
          throwsA(
            isA<EphemerisError>()
                .having((error) => error.status, 'status', isNot(0))
                .having(
                  (error) => error.diagnostic?.targetId,
                  'diagnostic target',
                  Body.sun.id,
                ),
          ),
        );
      });

      test('solar deflector skips self-deflection for the Sun', () {
        taiyin.configuration.useSolarDeflector();

        final result = taiyin.observed.atUt1(Body.sun, ut1);

        expect(result.status, 0);
        expect(result.apparent.longitudeRadians.isFinite, isTrue);
        expect(result.apparent.latitudeRadians.isFinite, isTrue);
      });

      test('rejects invalid bodies, batches, and flag dependencies', () {
        expect(
          () => taiyin.observed.atUt1(Body.earth, ut1),
          throwsArgumentError,
        );
        expect(
          () => taiyin.observed.batchAtUt1(List.filled(11, Body.sun), ut1),
          throwsArgumentError,
        );
        expect(
          () => taiyin.observed.atUt1(
            Body.sun,
            ut1,
            flags: {ObservedFlag.horizontal},
          ),
          throwsArgumentError,
        );
        expect(
          () => taiyin.observed.atUt1(
            Body.sun,
            ut1,
            flags: {ObservedFlag.refraction},
          ),
          throwsArgumentError,
        );
      });

      test('empty batches are immutable and use after close is rejected', () {
        final emptyUt1 = taiyin.observed.batchAtUt1(const [], ut1);
        final emptyUtc = taiyin.observed.batchAtUtc(const [], utc);

        expect(emptyUt1, isEmpty);
        expect(emptyUtc, isEmpty);
        expect(() => emptyUt1.clear(), throwsUnsupportedError);

        taiyin.close();
        expect(
          () => taiyin.observed.atUt1(
            Body.sun,
            ut1,
            flags: {ObservedFlag.truePosition},
          ),
          throwsStateError,
        );
        expect(
          () => taiyin.observed.atUtc(
            Body.sun,
            utc,
            flags: {ObservedFlag.truePosition},
          ),
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
