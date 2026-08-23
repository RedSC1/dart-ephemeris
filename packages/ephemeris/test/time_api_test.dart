import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  group(
    'Time native integration',
    () {
      late EphemerisContext taiyin;
      late AstroDateTime utcCalendar;
      late JulianDate<UtcScale> utc;

      setUp(() {
        taiyin = Ephemeris.open(libraryPath: libraryPath).createContext();
        utcCalendar = AstroDateTime(2000, 1, 1, 0, 0, 0, 123456789);
        utc = utcCalendar.toJulianDate<UtcScale>();
      });

      tearDown(() {
        taiyin.close();
      });

      test('converts UTC, TAI, TT, and UT1 with typed results', () {
        final tai = taiyin.time.utcToTai(utc, taiMinusUtcSeconds: 32).value;
        final ttFromTai = taiyin.time.taiToTt(tai).value;
        final ttFromUtc = taiyin.time
            .utcToTt(utc, taiMinusUtcSeconds: 32)
            .value;
        final ut1 = taiyin.time.utcToUt1(utc, dut1Seconds: 0.25).value;

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
        final jd = taiyin.time.julianDay<UtcScale>(utcCalendar).value;
        final roundTrip = taiyin.time.reverseJulianDay(jd).value;

        expect(roundTrip, utcCalendar);
      });

      test('preserves nanosecond separation across scale conversions', () {
        final first = JulianDate<UtcScale>.fromParts(2451545, 0.25);
        final second = first.addNanoseconds(1);

        final firstTt = taiyin.time
            .utcToTt(first, taiMinusUtcSeconds: 37)
            .value;
        final secondTt = taiyin.time
            .utcToTt(second, taiMinusUtcSeconds: 37)
            .value;
        final firstUt1 = taiyin.time.utcToUt1(first, dut1Seconds: -0.1).value;
        final secondUt1 = taiyin.time.utcToUt1(second, dut1Seconds: -0.1).value;
        final firstTdb = taiyin.time
            .ttToTdb(firstTt, model: TdbModel.sofaFull)
            .value;
        final secondTdb = taiyin.time
            .ttToTdb(secondTt, model: TdbModel.sofaFull)
            .value;

        expect(secondTt.secondsDifference(firstTt), closeTo(1e-9, 5e-12));
        expect(secondUt1.secondsDifference(firstUt1), closeTo(1e-9, 5e-12));
        expect(secondTdb.secondsDifference(firstTdb), closeTo(1e-9, 5e-12));
        expect(
          taiyin.time
              .tdbToTt(firstTdb, model: TdbModel.sofaFull)
              .value
              .secondsDifference(firstTt),
          closeTo(0, 5e-12),
        );
        expect(
          taiyin.time
              .ttToUt1(firstTt, deltaTSeconds: 69.284)
              .value
              .coordinateSecondsDifference(firstUt1),
          closeTo(0, 1e-11),
        );
      });

      test('rejects non-finite linear conversion offsets', () {
        expect(
          () => taiyin.time.utcToTai(utc, taiMinusUtcSeconds: double.nan).value,
          throwsArgumentError,
        );
        expect(
          () => taiyin.time.utcToUt1(utc, dut1Seconds: double.infinity).value,
          throwsArgumentError,
        );
        expect(
          () => taiyin.time
              .ut1ToTt(
                JulianDate<Ut1Scale>.fromDouble(2451545),
                deltaTSeconds: double.negativeInfinity,
              )
              .value,
          throwsArgumentError,
        );
      });

      test('builds explicit precise time scales', () {
        final scales = taiyin.time
            .preciseScalesFromUtc(
              utcCalendar,
              taiMinusUtcSeconds: 32,
              dut1Seconds: 0.25,
              tdbModel: TdbModel.sofaFull,
            )
            .value;

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
        taiyin.time.setTdbModel(TdbModel.sofaFull);
        final operation = taiyin.time.scalesFromUtc(utcCalendar);
        final result = operation.value;

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

      test('converts every physical scale back to UTC and UT1', () {
        final baseline = taiyin.time.scalesFromUtc(utcCalendar).value.value;

        final utcFromTai = taiyin.time.taiToUtc(baseline.tai);
        final utcFromTt = taiyin.time.ttToUtc(baseline.tt);
        final utcFromUt1 = taiyin.time.ut1ToUtc(baseline.ut1);
        final utcFromTdb = taiyin.time.tdbToUtc(baseline.tdb);

        for (final converted in [
          utcFromTai,
          utcFromTt,
          utcFromUt1,
          utcFromTdb,
        ]) {
          expect(
            converted.value.secondsDifference(baseline.utc),
            closeTo(0, 5e-7),
          );
        }

        final ut1FromUtc = taiyin.time.utcToUt1(baseline.utc);
        final ut1FromTai = taiyin.time.taiToUt1(baseline.tai);
        final ut1FromTt = taiyin.time.ttToUt1(baseline.tt);
        final ut1FromTdb = taiyin.time.tdbToUt1(baseline.tdb);

        for (final converted in [
          ut1FromUtc,
          ut1FromTai,
          ut1FromTt,
          ut1FromTdb,
        ]) {
          expect(
            converted.value.secondsDifference(baseline.ut1),
            closeTo(0, 5e-7),
          );
        }

        expect(
          taiyin.time.calendarFromUt1(baseline.ut1).value,
          AstroDateTime.fromJulianDate(baseline.ut1),
        );
        final utcCalendarRoundTrip = taiyin.time
            .utcCalendarFromUt1(baseline.ut1)
            .value
            .toUtcJulianDate();
        expect(
          utcCalendarRoundTrip.secondsDifference(baseline.utc),
          closeTo(0, 5e-7),
        );
      });

      test('uses the configured TDB model for automatic reverse routes', () {
        taiyin.time.setTdbModel(TdbModel.sofaFull);
        final baseline = taiyin.time.scalesFromUtc(utcCalendar).value.value;

        expect(
          taiyin.time
              .tdbToUtc(baseline.tdb)
              .value
              .secondsDifference(baseline.utc),
          closeTo(0, 5e-7),
        );
        expect(
          taiyin.time
              .tdbToUt1(baseline.tdb)
              .value
              .secondsDifference(baseline.ut1),
          closeTo(0, 5e-7),
        );

        final cloned = taiyin.clone();
        try {
          final clonedBaseline = cloned.time
              .scalesFromUtc(utcCalendar)
              .value
              .value;
          expect(
            cloned.time
                .tdbToUtc(clonedBaseline.tdb)
                .value
                .secondsDifference(clonedBaseline.utc),
            closeTo(0, 5e-7),
          );
        } finally {
          cloned.close();
        }
      });

      test('keeps the TDB model synchronized through configuration APIs', () {
        taiyin.configuration.setAstroModels(
          const AstroModelConfig(tdbModel: TdbModel.sofaFull),
        );
        expect(taiyin.time.configuredTdbModel, TdbModel.sofaFull);
        final sofaScales = taiyin.time.scalesFromUtc(utcCalendar).value.value;
        expect(
          taiyin.time
              .tdbToUtc(sofaScales.tdb)
              .value
              .secondsDifference(sofaScales.utc),
          closeTo(0, 5e-7),
        );
        final clone = taiyin.clone();
        try {
          expect(clone.time.configuredTdbModel, TdbModel.sofaFull);
        } finally {
          clone.close();
        }

        taiyin.configuration.reset();
        expect(taiyin.time.configuredTdbModel, TdbModel.fastPeriodic);
        final fastScales = taiyin.time.scalesFromUtc(utcCalendar).value.value;
        expect(
          taiyin.time
              .tdbToUtc(fastScales.tdb)
              .value
              .secondsDifference(fastScales.utc),
          closeTo(0, 5e-7),
        );

        taiyin.configuration.setAstroModels(
          const AstroModelConfig(tdbModel: TdbModel.sofaFull),
        );
        final precise = taiyin.time.preciseScalesFromUtc(
          utcCalendar,
          taiMinusUtcSeconds: 32,
          dut1Seconds: 0.25,
        );
        final estimated = taiyin.time.estimatedScalesFromUt1(
          AstroDateTime.fromJulianDate(precise.value.ut1),
          deltaTSeconds: precise.value.deltaTSeconds,
        );
        expect(
          precise.value.tdb.secondsDifference(
            taiyin.time
                .ttToTdb(precise.value.tt, model: TdbModel.sofaFull)
                .value,
          ),
          closeTo(0, 1e-10),
        );
        expect(
          estimated.value.tdb.secondsDifference(
            taiyin.time
                .ttToTdb(estimated.value.tt, model: TdbModel.sofaFull)
                .value,
          ),
          closeTo(0, 1e-10),
        );
      });

      test('seeds inverse iteration inside the EOP coverage edge', () {
        final boundary = taiyin.time
            .scalesFromUtc(AstroDateTime(2026, 5, 20))
            .value
            .value;

        expect(
          taiyin.time
              .ttToUt1(boundary.tt)
              .value
              .secondsDifference(boundary.ut1),
          closeTo(0, 5e-7),
        );
        expect(
          taiyin.time
              .ut1ToUtc(boundary.ut1)
              .value
              .secondsDifference(boundary.utc),
          closeTo(0, 5e-7),
        );
      });

      test('rejects an unrepresentable inserted UTC leap second', () {
        final leap = taiyin.time
            .scalesFromUtc(AstroDateTime(2016, 12, 31, 23, 59, 60))
            .value
            .value;

        expect(
          () => taiyin.time.taiToUtc(leap.tai),
          throwsA(isA<UtcLeapSecondRepresentationError>()),
        );
        expect(
          () => taiyin.time.ttToUtc(leap.tt),
          throwsA(isA<UtcLeapSecondRepresentationError>()),
        );
        expect(
          () => taiyin.time.tdbToUtc(leap.tdb),
          throwsA(isA<UtcLeapSecondRepresentationError>()),
        );

        for (final converted in [
          taiyin.time.taiToUt1(leap.tai),
          taiyin.time.ttToUt1(leap.tt),
          taiyin.time.tdbToUt1(leap.tdb),
        ]) {
          expect(converted.value.secondsDifference(leap.ut1), closeTo(0, 5e-7));
        }
      });

      test('strict UTC conversion reports missing EOP data explicitly', () {
        taiyin.close();
        taiyin = Ephemeris.open(
          libraryPath: libraryPath,
          options: const RuntimeOptions(loadBuiltinEop: false),
        ).createContext();

        expect(
          () => taiyin.time.scalesFromUtc(utcCalendar),
          throwsA(
            isA<EarthOrientationDataError>()
                .having((error) => error.status, 'status', -3001)
                .having(
                  (error) => error.name,
                  'name',
                  'TAIYIN_TIME_ERROR_EOP_OUT_OF_RANGE',
                ),
          ),
        );
        expect(
          () => taiyin.time.ut1ToUtc(
            Ut1JulianDate.fromParts(utc.dayNumber, utc.dayFraction),
          ),
          throwsA(isA<EarthOrientationDataError>()),
        );
      });

      test('strict UTC conversion reports EOP coverage gaps explicitly', () {
        expect(
          () => taiyin.time.scalesFromUtc(AstroDateTime(2200, 1, 1)),
          throwsA(isA<EarthOrientationDataError>()),
        );
      });

      test('reports unavailable leap-second data explicitly', () {
        expect(
          () => taiyin.time.taiMinusUtc(AstroDateTime(1900, 1, 1)),
          throwsA(
            isA<LeapSecondDataError>()
                .having((error) => error.status, 'status', -3002)
                .having(
                  (error) => error.name,
                  'name',
                  'TAIYIN_TIME_ERROR_LEAP_SECOND_UNAVAILABLE',
                ),
          ),
        );
        expect(
          () => taiyin.time.ttToUtc(
            AstroDateTime(1900, 1, 1).toJulianDate<TtScale>(),
          ),
          throwsA(isA<LeapSecondDataError>()),
        );
        expect(
          () => taiyin.time.ttToUt1(
            AstroDateTime(1900, 1, 1).toJulianDate<TtScale>(),
          ),
          throwsA(isA<LeapSecondDataError>()),
        );
      });

      test('falls back to the estimated Delta-T route when allowed', () {
        taiyin.close();
        taiyin = Ephemeris.open(
          libraryPath: libraryPath,
          options: const RuntimeOptions(loadBuiltinEop: false),
        ).createContext();
        taiyin.time
          ..setAllowUtcOutOfRangeEstimate(true)
          ..setDeltaTModel(
            DeltaTModel.estimatedDefault,
            family: EphemerisFamily.de441,
          );
        final operation = taiyin.time.scalesFromUtc(utcCalendar);
        final result = operation.value;

        expect(result.diagnostic.route, TimeScaleRoute.estimatedDeltaT);
        expect(
          result.diagnostic.flags,
          contains(TimeScaleDiagnosticFlag.usedDeltaTModel),
        );
        expect(result.diagnostic.ephemerisFamilyId, 441);
        expect(result.value.deltaTSeconds.isFinite, isTrue);
        expect(result.value.tai.toDouble(), 0);
        expect(operation.flags.contains(ResultFlag.timeScaleFallback), isTrue);
        final inverse = taiyin.time.ut1ToUtc(
          Ut1JulianDate.fromParts(utc.dayNumber, utc.dayFraction),
        );
        expect(inverse.flags.contains(ResultFlag.timeScaleFallback), isTrue);
        final ttToUt1 = taiyin.time.ttToUt1(result.value.tt);
        expect(ttToUt1.flags.contains(ResultFlag.timeScaleFallback), isTrue);

        final historicalTt = AstroDateTime(1900, 1, 1).toJulianDate<TtScale>();
        final historicalUt1 = taiyin.time.ttToUt1(historicalTt);
        final historicalTdb = taiyin.time.ttToTdb(historicalTt).value;
        final historicalUt1FromTdb = taiyin.time.tdbToUt1(historicalTdb);
        final historicalScales = taiyin.time
            .scalesFromUtc(AstroDateTime(1900, 1, 1))
            .value
            .value;
        final historicalTai = JulianDate<TaiScale>.fromParts(
          historicalScales.tt.dayNumber,
          historicalScales.tt.dayFraction,
        ).addSeconds(-32.184);
        final historicalUtcFromTai = taiyin.time.taiToUtc(historicalTai);
        final historicalUtcFromTt = taiyin.time.ttToUtc(historicalScales.tt);
        final historicalUtcFromTdb = taiyin.time.tdbToUtc(historicalScales.tdb);
        expect(
          historicalUt1.flags.contains(ResultFlag.timeScaleFallback),
          isTrue,
        );
        expect(
          historicalUt1FromTdb.flags.contains(ResultFlag.timeScaleFallback),
          isTrue,
        );
        expect(
          historicalUt1FromTdb.value.secondsDifference(historicalUt1.value),
          closeTo(0, 5e-7),
        );
        for (final inverse in [
          historicalUtcFromTai,
          historicalUtcFromTt,
          historicalUtcFromTdb,
        ]) {
          expect(
            inverse.value.secondsDifference(historicalScales.utc),
            closeTo(0, 5e-7),
          );
          expect(inverse.flags.contains(ResultFlag.timeScaleFallback), isTrue);
        }
        expect(taiyin.lastResultFlags, operation.flags);

        EphemerisError? failure;
        try {
          taiyin.position
              .atTt(
                CustomTarget(-210099),
                JulianDate<TtScale>.fromDouble(2460409.0),
              )
              .value;
        } on EphemerisError catch (error) {
          failure = error;
        }
        expect(failure, isNotNull);
        expect(taiyin.lastResultFlags, failure!.resultFlags);
        expect(taiyin.lastResultFlags, isNot(operation.flags));
        expect(
          result.value.tt.coordinateSecondsDifference(result.value.ut1),
          closeTo(result.value.deltaTSeconds, 1e-11),
        );
      });

      test('builds estimated scales with supplied or modeled Delta-T', () {
        final explicit = taiyin.time
            .estimatedScalesFromUt1(utcCalendar, deltaTSeconds: 64)
            .value;
        final modeled = taiyin.time.estimatedScalesFromUt1(utcCalendar).value;

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
          final tdb = taiyin.time.ttToTdb(tt, model: model).value;
          final roundTrip = taiyin.time.tdbToTt(tdb, model: model).value;
          expect(roundTrip.secondsDifference(tt), closeTo(0, 5e-12));
        }
      });

      test('provides Delta-T and epoch helpers', () {
        final ut1 = JulianDate<Ut1Scale>.fromDouble(2451544.5);
        final tt = JulianDate<TtScale>.fromDouble(2451544.5);

        expect(taiyin.time.taiMinusUtc(utcCalendar).value, 32);
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
