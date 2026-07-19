import 'dart:io';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();

  group(
    'TaiyinObservedApi native integration',
    () {
      late TaiyinContext taiyin;
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final utc = AstroDateTime(2024, 4, 8, 18);

      setUp(() {
        taiyin = Taiyin.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('maps complete UT1 apparent state and diagnostic', () {
        final result = taiyin.observed.atUt1(
          TaiyinBody.sun,
          ut1,
          flags: {TaiyinObservedFlag.speed, TaiyinObservedFlag.truePosition},
        );

        expect(result.body, TaiyinBody.sun);
        expect(result.status, 0);
        expect(result.diagnostic.status, 0);
        expect(result.diagnostic.targetId, TaiyinBody.sun.id);
        expect(result.apparent.body, TaiyinBody.sun);
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
        const bodies = [TaiyinBody.sun, TaiyinBody.moon];
        const flags = {TaiyinObservedFlag.truePosition};
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
            const [TaiyinBody.sun, TaiyinBody.mars],
            ut1,
            flags: {TaiyinObservedFlag.truePosition},
          ),
          throwsA(
            isA<TaiyinException>()
                .having((error) => error.status, 'status', isNot(0))
                .having(
                  (error) => error.diagnostic?.targetId,
                  'failed target',
                  TaiyinBody.mars.id,
                ),
          ),
        );
      });

      test('covers UTC single and batch routes with precise time data', () {
        const flags = {TaiyinObservedFlag.truePosition};
        final single = taiyin.observed.atUtc(TaiyinBody.sun, utc, flags: flags);
        final batch = taiyin.observed.batchAtUtc(
          const [TaiyinBody.sun, TaiyinBody.moon],
          utc,
          flags: flags,
        );

        expect(single.status, 0);
        expect(single.diagnostic.julianDateTdb.isFinite, isTrue);
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
          const TaiyinObserverLocation(
            longitudeDegrees: 116.391,
            latitudeDegrees: 39.907,
            heightMeters: 50,
          ),
        );

        final result = taiyin.observed.atUt1(
          TaiyinBody.sun,
          ut1,
          flags: {
            TaiyinObservedFlag.speed,
            TaiyinObservedFlag.topocentric,
            TaiyinObservedFlag.horizontal,
            TaiyinObservedFlag.truePosition,
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
            const TaiyinObserverLocation(
              longitudeDegrees: 0,
              latitudeDegrees: 0,
              heightMeters: 0,
            ),
          )
          ..setAtmospherePolicy({
            TaiyinAtmospherePolicyFlag.allowStandardFallback,
          });

        final fallback = taiyin.observed.atUt1(
          TaiyinBody.sun,
          ut1,
          flags: {
            TaiyinObservedFlag.topocentric,
            TaiyinObservedFlag.refraction,
            TaiyinObservedFlag.truePosition,
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
            TaiyinBody.sun,
            ut1,
            flags: {
              TaiyinObservedFlag.topocentric,
              TaiyinObservedFlag.refraction,
              TaiyinObservedFlag.truePosition,
              TaiyinObservedFlag.strictMeteorology,
            },
          ),
          throwsA(
            isA<TaiyinException>()
                .having((error) => error.status, 'status', isNot(0))
                .having(
                  (error) => error.diagnostic?.targetId,
                  'diagnostic target',
                  TaiyinBody.sun.id,
                ),
          ),
        );
      });

      test('solar deflector skips self-deflection for the Sun', () {
        taiyin.configuration.useSolarDeflector();

        final result = taiyin.observed.atUt1(TaiyinBody.sun, ut1);

        expect(result.status, 0);
        expect(result.apparent.longitudeRadians.isFinite, isTrue);
        expect(result.apparent.latitudeRadians.isFinite, isTrue);
      });

      test('rejects invalid bodies, batches, and flag dependencies', () {
        expect(
          () => taiyin.observed.atUt1(TaiyinBody.earth, ut1),
          throwsArgumentError,
        );
        expect(
          () =>
              taiyin.observed.batchAtUt1(List.filled(11, TaiyinBody.sun), ut1),
          throwsArgumentError,
        );
        expect(
          () => taiyin.observed.atUt1(
            TaiyinBody.sun,
            ut1,
            flags: {TaiyinObservedFlag.horizontal},
          ),
          throwsArgumentError,
        );
        expect(
          () => taiyin.observed.atUt1(
            TaiyinBody.sun,
            ut1,
            flags: {TaiyinObservedFlag.refraction},
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
            TaiyinBody.sun,
            ut1,
            flags: {TaiyinObservedFlag.truePosition},
          ),
          throwsStateError,
        );
        expect(
          () => taiyin.observed.atUtc(
            TaiyinBody.sun,
            utc,
            flags: {TaiyinObservedFlag.truePosition},
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
