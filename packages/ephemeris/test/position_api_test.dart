import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  group(
    'PositionApi native integration',
    () {
      late EphemerisContext taiyin;
      final tt = JulianDate<TtScale>.fromDouble(2460409.0);
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final tdb = JulianDate<TdbScale>.fromDouble(2460409.0);
      final utc = AstroDateTime(2024, 4, 8, 18);

      setUp(() {
        taiyin = Ephemeris.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('returns a position with its native diagnostic', () {
        final result = taiyin.position
            .atTt(Body.moon, tt, flags: {PositionFlag.xyz, PositionFlag.speed})
            .value;

        expect(result.values, hasLength(6));
        expect(result.values.every((value) => value.isFinite), isTrue);
        expect(result.isCartesian, isTrue);
        expect(taiyin.lastDiagnostic?.status, 0);
        expect(taiyin.lastDiagnostic?.targetId, Body.moon.id);
        expect(
          taiyin.lastDiagnostic?.julianDateTdb.toDouble().isFinite,
          isTrue,
        );
        expect(taiyin.lastDiagnostic?.candidateCount, greaterThanOrEqualTo(0));
      });

      test('covers TDB, UT1, explicit Delta-T, and UTC routes', () {
        final calls = [
          () => taiyin.position.atTdb(Body.sun, tdb, tt).value,
          () => taiyin.position.atUt1(Body.sun, ut1).value,
          () => taiyin.position.atUt1WithDeltaT(Body.sun, ut1, 69.184).value,
          () => taiyin.position.atUtc(Body.sun, utc).value,
        ];

        for (final call in calls) {
          final result = call();
          expect(result.values.every((value) => value.isFinite), isTrue);
          expect(taiyin.lastDiagnostic?.status, 0);
          expect(taiyin.lastDiagnostic?.targetId, Body.sun.id);
        }
      });

      test('batch calculations preserve target order and match singles', () {
        const bodies = [Body.sun, Body.moon];
        final batch = taiyin.position.batchAtTt(bodies, tt).value;

        expect(batch, hasLength(bodies.length));
        for (var index = 0; index < bodies.length; index++) {
          final single = taiyin.position.atTt(bodies[index], tt).value;
          expect(batch[index].values, single.values);
          expect(taiyin.lastDiagnostic?.targetId, bodies[index].id);
        }
        expect(taiyin.position.batchAtTt(const [], tt).value, isEmpty);
      });

      test('covers batch TDB, UT1, explicit Delta-T, and UTC routes', () {
        const bodies = [Body.sun, Body.moon];
        final calls = [
          () => taiyin.position.batchAtTdb(bodies, tdb, tt).value,
          () => taiyin.position.batchAtUt1(bodies, ut1).value,
          () => taiyin.position.batchAtUt1WithDeltaT(bodies, ut1, 69.184).value,
          () => taiyin.position.batchAtUtc(bodies, utc).value,
        ];

        for (final call in calls) {
          final batch = call();
          expect(batch, hasLength(bodies.length));
          expect(
            batch.every(
              (result) => result.values.every((value) => value.isFinite),
            ),
            isTrue,
          );
          expect(taiyin.lastDiagnostic?.status, 0);
        }
      });

      test('throws atomically and retains every batch diagnostic', () {
        const bodies = [Body.sun, Body.saturn];
        expect(
          () => taiyin.position.batchAtTt(bodies, tt).value,
          throwsA(
            isA<EphemerisError>()
                .having(
                  (error) => error.diagnostic?.targetId,
                  'primary diagnostic target',
                  Body.saturn.id,
                )
                .having(
                  (error) => error.diagnostics.length,
                  'diagnostic count',
                  bodies.length,
                )
                .having(
                  (error) => error.diagnostics.first.status,
                  'successful target status',
                  0,
                )
                .having(
                  (error) => error.diagnostics.last.targetId,
                  'failed target id',
                  Body.saturn.id,
                ),
          ),
        );
        expect(taiyin.lastDiagnostic?.status, isNot(0));
        expect(taiyin.lastDiagnostic?.targetId, Body.saturn.id);
      });

      test('attaches native diagnostics to single-target failures', () {
        expect(
          () => taiyin.position.atTt(Body.saturn, tt).value,
          throwsA(
            isA<EphemerisError>()
                .having(
                  (error) => error.diagnostic?.targetId,
                  'diagnostic target',
                  Body.saturn.id,
                )
                .having(
                  (error) => error.diagnostic?.status,
                  'diagnostic status',
                  isNot(0),
                ),
          ),
        );

        expect(
          () => taiyin.position.stateAtTt(Body.earth, tt).value,
          throwsA(
            isA<EphemerisError>().having(
              (error) => error.diagnostic?.targetId,
              'state diagnostic target',
              Body.earth.id,
            ),
          ),
        );
      });

      test('returns finite Cartesian position, velocity, and acceleration', () {
        final result = taiyin.position.stateAtTt(Body.moon, tt).value;
        final state = result;

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
        expect(taiyin.lastDiagnostic?.targetId, Body.moon.id);
      });

      test('covers Cartesian-state time routes', () {
        final calls = [
          () => taiyin.position.stateAtTdb(Body.moon, tdb, tt).value,
          () => taiyin.position.stateAtUt1(Body.moon, ut1).value,
          () => taiyin.position
              .stateAtUt1WithDeltaT(Body.moon, ut1, 69.184)
              .value,
          () => taiyin.position.stateAtUtc(Body.moon, utc).value,
        ];

        for (final call in calls) {
          final result = call();
          expect(
            result.positionAu.values.every((value) => value.isFinite),
            isTrue,
          );
          expect(taiyin.lastDiagnostic?.status, 0);
        }
      });

      test('rejects non-finite Delta-T and use after close', () {
        expect(
          () =>
              taiyin.position.atUt1WithDeltaT(Body.sun, ut1, double.nan).value,
          throwsArgumentError,
        );

        taiyin.close();
        expect(
          () => taiyin.position.atTt(Body.sun, tt).value,
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
