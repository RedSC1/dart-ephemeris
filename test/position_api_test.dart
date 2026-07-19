import 'dart:io';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();

  group(
    'TaiyinPositionApi native integration',
    () {
      late TaiyinContext taiyin;
      final tt = JulianDate<TtScale>.fromDouble(2460409.0);
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final tdb = JulianDate<TdbScale>.fromDouble(2460409.0);
      final utc = AstroDateTime(2024, 4, 8, 18);

      setUp(() {
        taiyin = Taiyin.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('returns a position with its native diagnostic', () {
        final result = taiyin.position.atTt(
          TaiyinBody.moon,
          tt,
          flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
        );

        expect(result.value.values, hasLength(6));
        expect(result.value.values.every((value) => value.isFinite), isTrue);
        expect(result.value.isCartesian, isTrue);
        expect(result.diagnostic.status, 0);
        expect(result.diagnostic.targetId, TaiyinBody.moon.id);
        expect(result.diagnostic.julianDateTdb.isFinite, isTrue);
        expect(result.diagnostic.candidateCount, greaterThanOrEqualTo(0));
      });

      test('covers TDB, UT1, explicit Delta-T, and UTC routes', () {
        final results = [
          taiyin.position.atTdb(TaiyinBody.sun, tdb, tt),
          taiyin.position.atUt1(TaiyinBody.sun, ut1),
          taiyin.position.atUt1WithDeltaT(TaiyinBody.sun, ut1, 69.184),
          taiyin.position.atUtc(TaiyinBody.sun, utc),
        ];

        for (final result in results) {
          expect(result.value.values.every((value) => value.isFinite), isTrue);
          expect(result.diagnostic.status, 0);
          expect(result.diagnostic.targetId, TaiyinBody.sun.id);
        }
      });

      test('batch calculations preserve target order and match singles', () {
        const bodies = [TaiyinBody.sun, TaiyinBody.moon];
        final batch = taiyin.position.batchAtTt(bodies, tt);

        expect(batch, hasLength(bodies.length));
        for (var index = 0; index < bodies.length; index++) {
          final single = taiyin.position.atTt(bodies[index], tt);
          expect(batch[index].value.values, single.value.values);
          expect(batch[index].diagnostic.targetId, bodies[index].id);
        }
        expect(taiyin.position.batchAtTt(const [], tt), isEmpty);
      });

      test('covers batch TDB, UT1, explicit Delta-T, and UTC routes', () {
        const bodies = [TaiyinBody.sun, TaiyinBody.moon];
        final batches = [
          taiyin.position.batchAtTdb(bodies, tdb, tt),
          taiyin.position.batchAtUt1(bodies, ut1),
          taiyin.position.batchAtUt1WithDeltaT(bodies, ut1, 69.184),
          taiyin.position.batchAtUtc(bodies, utc),
        ];

        for (final batch in batches) {
          expect(batch, hasLength(bodies.length));
          expect(
            batch.every(
              (result) =>
                  result.value.values.every((value) => value.isFinite) &&
                  result.diagnostic.status == 0,
            ),
            isTrue,
          );
        }
      });

      test('preserves successful targets when a batch target fails', () {
        const bodies = [TaiyinBody.sun, TaiyinBody.mars];
        final batch = taiyin.position.batchAtTt(bodies, tt);

        expect(batch, hasLength(2));
        expect(batch[0].diagnostic.status, 0);
        expect(batch[0].value.values.every((value) => value.isFinite), isTrue);
        expect(batch[1].diagnostic.status, isNot(0));
        expect(batch[1].diagnostic.targetId, TaiyinBody.mars.id);
      });

      test('attaches native diagnostics to single-target failures', () {
        expect(
          () => taiyin.position.atTt(TaiyinBody.mars, tt),
          throwsA(
            isA<TaiyinException>()
                .having(
                  (error) => error.diagnostic?.targetId,
                  'diagnostic target',
                  TaiyinBody.mars.id,
                )
                .having(
                  (error) => error.diagnostic?.status,
                  'diagnostic status',
                  isNot(0),
                ),
          ),
        );

        expect(
          () => taiyin.position.stateAtTt(TaiyinBody.earth, tt),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.diagnostic?.targetId,
              'state diagnostic target',
              TaiyinBody.earth.id,
            ),
          ),
        );
      });

      test('returns finite Cartesian position, velocity, and acceleration', () {
        final result = taiyin.position.stateAtTt(TaiyinBody.moon, tt);
        final state = result.value;

        expect(
          state.positionAu.values.every((value) => value.isFinite),
          isTrue,
        );
        expect(
          state.velocityAuPerDay.values.every((value) => value.isFinite),
          isTrue,
        );
        expect(
          state.accelerationAuPerDay2.values.every((value) => value.isFinite),
          isTrue,
        );
        expect(result.diagnostic.targetId, TaiyinBody.moon.id);
      });

      test('covers Cartesian-state time routes', () {
        final results = [
          taiyin.position.stateAtTdb(TaiyinBody.moon, tdb, tt),
          taiyin.position.stateAtUt1(TaiyinBody.moon, ut1),
          taiyin.position.stateAtUt1WithDeltaT(TaiyinBody.moon, ut1, 69.184),
          taiyin.position.stateAtUtc(TaiyinBody.moon, utc),
        ];

        for (final result in results) {
          expect(
            result.value.positionAu.values.every((value) => value.isFinite),
            isTrue,
          );
          expect(result.diagnostic.status, 0);
        }
      });

      test('rejects non-finite Delta-T and use after close', () {
        expect(
          () =>
              taiyin.position.atUt1WithDeltaT(TaiyinBody.sun, ut1, double.nan),
          throwsArgumentError,
        );

        taiyin.close();
        expect(
          () => taiyin.position.atTt(TaiyinBody.sun, tt),
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
