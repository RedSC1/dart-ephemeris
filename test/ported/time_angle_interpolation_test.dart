import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import '../support/native_library.dart';

/// Black-box port of the public time behavior in
/// taiyin-ephemeris/tests/test_time_angle_interpolation.cpp.
void main() {
  group(
    'ported: time_angle_interpolation',
    () {
      late EphemerisContext taiyin;

      setUp(() {
        taiyin = Ephemeris.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('calendar and Julian-date oracles', () {
        final fixtures = <(AstroDateTime, double)>[
          (AstroDateTime(2000, 1, 1, 12), 2451545.0),
          (AstroDateTime(2024, 4, 8, 18, 17, 20), 2460409.262037037),
          (AstroDateTime(1990, 4, 20, 6), 2448001.75),
        ];

        for (final (calendar, expected) in fixtures) {
          final actual = taiyin.time.julianDay<Ut1Scale>(calendar);
          expect(actual.toDouble(), closeTo(expected, 1e-9));

          final roundTrip = taiyin.time.reverseJulianDay(actual);
          expect(roundTrip.year, calendar.year);
          expect(roundTrip.month, calendar.month);
          expect(roundTrip.day, calendar.day);
          expect(roundTrip.hour, calendar.hour);
          expect(roundTrip.minute, calendar.minute);
          expect(
            roundTrip.fractionalSecond,
            closeTo(calendar.fractionalSecond, 1e-5),
          );
        }

        final sample = JulianDate<Ut1Scale>.fromDouble(2460409.262037037);
        expect(
          taiyin.time.decimalYear(sample),
          closeTo(2024.2698416312485, 1e-12),
        );
        expect(
          taiyin.time.julianCenturiesSinceJ2000(
            JulianDate<TtScale>.fromDouble(2451545.0 + 36525.0),
          ),
          closeTo(1, 1e-15),
        );
        expect(
          taiyin.time.julianMillenniaSinceJ2000(
            JulianDate<TtScale>.fromDouble(2451545.0 + 365250.0),
          ),
          closeTo(1, 1e-15),
        );
      });

      test('built-in leap-second table oracles', () {
        expect(
          () =>
              taiyin.time.taiMinusUtc(AstroDateTime(1971, 12, 31, 23, 59, 59)),
          throwsA(isA<EphemerisError>()),
        );
        expect(taiyin.time.taiMinusUtc(AstroDateTime(1972, 1, 1)), 10);
        expect(
          taiyin.time.taiMinusUtc(AstroDateTime(2024, 4, 8, 18, 17, 20)),
          37,
        );
      });

      test('UTC, TAI, TT, and UT1 conversion oracles', () {
        final utc = JulianDate<UtcScale>.fromDouble(2460409.262037037);
        final tai = taiyin.time.utcToTai(utc, taiMinusUtcSeconds: 37);
        final ttFromTai = taiyin.time.taiToTt(tai);
        final ttFromUtc = taiyin.time.utcToTt(utc, taiMinusUtcSeconds: 37);
        final ut1 = taiyin.time.utcToUt1(utc, dut1Seconds: -0.1);

        expect(tai.coordinateSecondsDifference(utc), closeTo(37, 1e-11));
        expect(
          ttFromTai.coordinateSecondsDifference(utc),
          closeTo(69.184, 1e-11),
        );
        expect(ttFromTai.secondsDifference(ttFromUtc), closeTo(0, 1e-11));
        expect(ut1.coordinateSecondsDifference(utc), closeTo(-0.1, 1e-11));
        expect(
          taiyin.time.deltaT(taiMinusUtcSeconds: 37, dut1Seconds: -0.1),
          closeTo(69.284, 1e-12),
        );

        final sourceUt1 = JulianDate<Ut1Scale>.fromDouble(2460409.5);
        final tt = taiyin.time.ut1ToTt(
          sourceUt1,
          deltaTSeconds: 69.17035296181177,
        );
        final roundTrip = taiyin.time.ttToUt1(
          tt,
          deltaTSeconds: 69.17035296181177,
        );
        expect(roundTrip.secondsDifference(sourceUt1), closeTo(0, 1e-7));
      });

      test('explicit precise-scale aggregate oracle', () {
        final scales = taiyin.time.preciseScalesFromUtc(
          AstroDateTime(2024, 4, 8, 18, 17, 20),
          taiMinusUtcSeconds: 37,
          dut1Seconds: -0.1,
        );

        expect(scales.utc.toDouble(), closeTo(2460409.262037037, 1e-12));
        expect(
          scales.tai.coordinateSecondsDifference(scales.utc),
          closeTo(37, 1e-11),
        );
        expect(
          scales.tt.coordinateSecondsDifference(scales.utc),
          closeTo(69.184, 1e-11),
        );
        expect(
          scales.ut1.coordinateSecondsDifference(scales.utc),
          closeTo(-0.1, 1e-11),
        );
        expect(scales.deltaTSeconds, closeTo(69.284, 1e-12));
      });

      test('TT and TDB model oracles', () {
        const fixtures = <(double, TdbModel, double)>[
          (2460000.0, TdbModel.fastPeriodic, 0.0012807796353021415),
          (2440000.0, TdbModel.fastPeriodic, 0.0010610135981240078),
          (2451545.0, TdbModel.fastPeriodic, -0.00009575743486095212),
          (2460000.0, TdbModel.sofaFull, 0.0012746805125203914),
          (2440000.0, TdbModel.sofaFull, 0.0010590942554813256),
          (2451545.0, TdbModel.sofaFull, -0.00009930719894379447),
        ];

        for (final (value, model, expectedOffset) in fixtures) {
          final tt = JulianDate<TtScale>.fromDouble(value);
          final tdb = taiyin.time.ttToTdb(tt, model: model);
          expect(
            tdb.coordinateSecondsDifference(tt),
            closeTo(expectedOffset, 5e-5),
          );
          expect(
            taiyin.time.tdbToTt(tdb, model: model).secondsDifference(tt),
            closeTo(0, 5e-12),
          );
        }
      });

      test('Delta-T decimal-year oracles', () {
        const fixtures = <(double, double)>[
          (-1000.0, 25427.68),
          (-720.0, 20371.848),
          (-719.5, 20363.7843227998),
          (-100.0, 11557.668),
          (0.0, 10441.312575999998),
          (399.999, 6535.125452533171),
          (400.0, 6535.116),
          (1000.0, 1650.393),
          (1150.0, 1056.647),
          (1500.0, 292.343),
          (1600.0, 109.127),
          (1800.0, 18.367),
          (1850.0, 9.338),
          (1900.0, -1.977),
          (1952.999, 30.00175459878804),
          (1953.0, 30.0),
          (1953.25, 30.049765625),
          (1961.5, 33.486875),
          (1972.5, 42.765625),
          (2000.0, 63.83),
          (2016.5, 68.35),
          (2024.25, 69.171171875),
          (2049.5, 71.329375),
          (2050.0, 71.44),
          (2050.5, 72.56600000000005),
          (2100.0, 191.95999999999998),
          (2200.0, 442.08),
        ];

        for (final (year, expected) in fixtures) {
          expect(
            taiyin.time.estimatedDeltaTForDecimalYear(year),
            closeTo(expected, 1e-10),
            reason: 'Delta-T oracle for $year',
          );
        }
      });

      test('Delta-T Julian-date oracles', () {
        const ut1Fixtures = <(double, double)>[
          (2451545.0, 63.83042335736016),
          (2460409.5, 69.17035296181177),
          (2460409.262037037, 69.17037911418967),
          (2448001.75, 57.06055072295038),
          (2086302.5, 1650.4617878426973),
        ];
        const ttFixtures = <(double, double)>[
          (2451545.0, 63.830422732032133),
          (2460409.262837778, 69.17037911417232),
        ];

        for (final (jd, expected) in ut1Fixtures) {
          expect(
            taiyin.time.estimatedDeltaTFromUt1(
              JulianDate<Ut1Scale>.fromDouble(jd),
            ),
            closeTo(expected, 1e-12),
          );
        }
        for (final (jd, expected) in ttFixtures) {
          expect(
            taiyin.time.estimatedDeltaTFromTt(
              JulianDate<TtScale>.fromDouble(jd),
            ),
            closeTo(expected, 1e-12),
          );
        }
      });

      test('estimated-scale aggregate oracles', () {
        final calendar = AstroDateTime(2024, 4, 8, 18, 17, 20);
        final manual = taiyin.time.estimatedScalesFromUt1(
          calendar,
          deltaTSeconds: 69.17035296181177,
        );

        expect(manual.ut1.toDouble(), closeTo(2460409.262037037, 1e-12));
        expect(
          manual.tt.coordinateSecondsDifference(manual.ut1),
          closeTo(69.17035296181177, 1e-11),
        );
        expect(manual.deltaTSeconds, 69.17035296181177);

        final estimated = taiyin.time.estimatedScalesFromUt1(calendar);
        expect(
          estimated.tt.coordinateSecondsDifference(estimated.ut1),
          closeTo(estimated.deltaTSeconds, 1e-11),
        );
        expect(
          estimated.deltaTSeconds,
          closeTo(taiyin.time.estimatedDeltaTFromUt1(estimated.ut1), 1e-12),
        );
        expect(
          taiyin.time.tdbToTt(estimated.tdb).secondsDifference(estimated.tt),
          closeTo(0, 5e-12),
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
