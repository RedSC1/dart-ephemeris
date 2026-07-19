import 'dart:io';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();

  group(
    'TaiyinTime native integration',
    () {
      late TaiyinContext taiyin;
      late AstroDateTime utcCalendar;
      late JulianDate<UtcScale> utc;

      setUp(() {
        taiyin = Taiyin.open(libraryPath: libraryPath).createContext();
        utcCalendar = AstroDateTime(2000, 1, 1, 0, 0, 0, 123456789);
        utc = utcCalendar.toJulianDate<UtcScale>();
      });

      tearDown(() {
        taiyin.close();
      });

      test('converts UTC, TAI, TT, and UT1 with typed results', () {
        final tai = taiyin.time.utcToTai(utc, taiMinusUtcSeconds: 32);
        final ttFromTai = taiyin.time.taiToTt(tai);
        final ttFromUtc = taiyin.time.utcToTt(utc, taiMinusUtcSeconds: 32);
        final ut1 = taiyin.time.utcToUt1(utc, dut1Seconds: 0.25);

        expect(ttFromTai.secondsDifference(ttFromUtc), closeTo(0, 0.00005));
        expect(
          ttFromUtc.coordinateSecondsDifference(utc),
          closeTo(64.184, 0.00005),
        );
        expect(ut1.coordinateSecondsDifference(utc), closeTo(0.25, 0.00005));
        expect(
          taiyin.time.deltaT(taiMinusUtcSeconds: 32, dut1Seconds: 0.25),
          closeTo(63.934, 1e-12),
        );
      });

      test('round-trips nanoseconds through the native split calendar ABI', () {
        final jd = taiyin.time.julianDay<UtcScale>(utcCalendar);
        final roundTrip = taiyin.time.reverseJulianDay(jd);

        expect(roundTrip, utcCalendar);
      });

      test('preserves nanosecond separation across scale conversions', () {
        final first = JulianDate<UtcScale>.fromParts(2451545, 0.25);
        final second = first.addNanoseconds(1);

        final firstTt = taiyin.time.utcToTt(first, taiMinusUtcSeconds: 37);
        final secondTt = taiyin.time.utcToTt(second, taiMinusUtcSeconds: 37);
        final firstUt1 = taiyin.time.utcToUt1(first, dut1Seconds: -0.1);
        final secondUt1 = taiyin.time.utcToUt1(second, dut1Seconds: -0.1);
        final firstTdb = taiyin.time.ttToTdb(firstTt, model: TdbModel.sofaFull);
        final secondTdb = taiyin.time.ttToTdb(
          secondTt,
          model: TdbModel.sofaFull,
        );

        expect(secondTt.secondsDifference(firstTt), closeTo(1e-9, 5e-12));
        expect(secondUt1.secondsDifference(firstUt1), closeTo(1e-9, 5e-12));
        expect(secondTdb.secondsDifference(firstTdb), closeTo(1e-9, 5e-12));
        expect(
          taiyin.time
              .tdbToTt(firstTdb, model: TdbModel.sofaFull)
              .secondsDifference(firstTt),
          closeTo(0, 5e-12),
        );
        expect(
          taiyin.time
              .ttToUt1(firstTt, deltaTSeconds: 69.284)
              .coordinateSecondsDifference(firstUt1),
          closeTo(0, 1e-11),
        );
      });

      test('rejects non-finite linear conversion offsets', () {
        expect(
          () => taiyin.time.utcToTai(utc, taiMinusUtcSeconds: double.nan),
          throwsArgumentError,
        );
        expect(
          () => taiyin.time.utcToUt1(utc, dut1Seconds: double.infinity),
          throwsArgumentError,
        );
        expect(
          () => taiyin.time.ut1ToTt(
            JulianDate<Ut1Scale>.fromDouble(2451545),
            deltaTSeconds: double.negativeInfinity,
          ),
          throwsArgumentError,
        );
      });

      test('builds explicit precise time scales', () {
        final scales = taiyin.time.preciseScalesFromUtc(
          utcCalendar,
          taiMinusUtcSeconds: 32,
          dut1Seconds: 0.25,
          tdbModel: TdbModel.sofaFull,
        );

        expect(scales.taiMinusUtcSeconds, 32);
        expect(scales.dut1Seconds, 0.25);
        expect(scales.deltaTSeconds, closeTo(63.934, 1e-12));
        expect(
          scales.tt.coordinateSecondsDifference(scales.utc),
          closeTo(64.184, 0.00005),
        );
        expect(
          scales.ut1.coordinateSecondsDifference(scales.utc),
          closeTo(0.25, 0.00005),
        );
        expect(scales.tdb.toDouble().isFinite, isTrue);
      });

      test('uses precise EOP and leap-second runtime data', () {
        taiyin.time.setPolicy(TimeScalePolicy.precise);
        taiyin.time.setTdbModel(TdbModel.sofaFull);
        final result = taiyin.time.scalesFromUtc(utcCalendar);

        expect(result.diagnostic.route, TimeScaleRoute.preciseUtcEop);
        expect(
          result.diagnostic.flags,
          containsAll({
            TimeScaleDiagnosticFlag.usedLeapSeconds,
            TimeScaleDiagnosticFlag.usedEop,
          }),
        );
        expect(result.value.taiMinusUtcSeconds, 32);
        expect(result.value.tt.toDouble().isFinite, isTrue);
      });

      test('can force the estimated Delta-T route', () {
        taiyin.time
          ..setPolicy(TimeScalePolicy.estimated)
          ..setDeltaTModel(
            DeltaTModel.estimatedDefault,
            family: EphemerisFamily.de441,
          );
        final result = taiyin.time.scalesFromUtc(utcCalendar);

        expect(result.diagnostic.route, TimeScaleRoute.estimatedDeltaT);
        expect(
          result.diagnostic.flags,
          contains(TimeScaleDiagnosticFlag.usedDeltaTModel),
        );
        expect(result.diagnostic.ephemerisFamilyId, 441);
        expect(result.value.deltaTSeconds.isFinite, isTrue);
        expect(result.value.tai.toDouble(), 0);
        expect(
          result.value.tt.coordinateSecondsDifference(result.value.ut1),
          closeTo(result.value.deltaTSeconds, 1e-11),
        );
      });

      test('builds estimated scales with supplied or modeled Delta-T', () {
        final explicit = taiyin.time.estimatedScalesFromUt1(
          utcCalendar,
          deltaTSeconds: 64,
        );
        final modeled = taiyin.time.estimatedScalesFromUt1(utcCalendar);

        expect(explicit.deltaTSeconds, 64);
        expect(
          explicit.tt.coordinateSecondsDifference(explicit.ut1),
          closeTo(64, 1e-11),
        );
        expect(modeled.deltaTSeconds.isFinite, isTrue);
        expect(modeled.tt.toDouble().isFinite, isTrue);
        expect(modeled.tdb.toDouble().isFinite, isTrue);
      });

      test('round-trips TT and TDB models', () {
        final tt = JulianDate<TtScale>.fromDouble(2451545.0);
        for (final model in TdbModel.values) {
          final tdb = taiyin.time.ttToTdb(tt, model: model);
          final roundTrip = taiyin.time.tdbToTt(tdb, model: model);
          expect(roundTrip.secondsDifference(tt), closeTo(0, 5e-12));
        }
      });

      test('provides Delta-T and epoch helpers', () {
        final ut1 = JulianDate<Ut1Scale>.fromDouble(2451544.5);
        final tt = JulianDate<TtScale>.fromDouble(2451544.5);

        expect(taiyin.time.taiMinusUtc(utcCalendar), 32);
        expect(taiyin.time.decimalYear(ut1), closeTo(2000, 0.01));
        expect(
          taiyin.time.julianCenturiesSinceJ2000(tt),
          closeTo(-0.5 / 36525, 1e-16),
        );
        expect(
          taiyin.time.julianMillenniaSinceJ2000(tt),
          closeTo(-0.5 / 365250, 1e-17),
        );
        expect(taiyin.time.estimatedDeltaTFromUt1(ut1).isFinite, isTrue);
        expect(taiyin.time.estimatedDeltaTFromTt(tt).isFinite, isTrue);
        expect(
          taiyin.time.estimatedDeltaTForDecimalYear(2000).isFinite,
          isTrue,
        );
      });

      test('rejects use after its owning context closes', () {
        final time = taiyin.time;
        taiyin.close();

        expect(() => time.decimalYear(utc), throwsStateError);
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
