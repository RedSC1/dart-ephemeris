import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  group('AstroDateTime', () {
    test('preserves DateTime microseconds', () {
      final dart = DateTime.utc(2026, 7, 19, 12, 34, 56, 123, 456);
      final astro = AstroDateTime.fromDateTime(dart);

      expect(astro.nanosecond, 123456000);
      expect(astro.toDateTimeUtc(), dart);
    });

    test('round-trips nanoseconds through a split Julian date', () {
      final original = AstroDateTime(2026, 7, 19, 12, 34, 56, 123456789);
      final jd = original.toJulianDate<TtScale>();
      final roundTrip = AstroDateTime.fromJulianDate(jd);

      expect(roundTrip, original);
    });

    test('preserves subsecond Duration arithmetic', () {
      final start = AstroDateTime(2026, 1, 1, 0, 0, 0, 789);

      expect(start.add(const Duration(microseconds: 1)).nanosecond, 1789);
      expect(start.addNanoseconds(1).nanosecond, 790);
    });

    test('crosses the historical Gregorian cutover', () {
      final lastJulianDay = AstroDateTime(1582, 10, 4);
      final firstGregorianDay = lastJulianDay.add(const Duration(days: 1));

      expect(firstGregorianDay, AstroDateTime(1582, 10, 15));
      expect(() => AstroDateTime(1582, 10, 10), throwsArgumentError);
    });

    test('supports astronomical BCE year numbering', () {
      final original = AstroDateTime(-456, 4, 4, 12, 48, 0, 987654321);
      final roundTrip = AstroDateTime.fromJulianDate(
        original.toJulianDate<TtScale>(),
      );

      expect(roundTrip, original);
      expect(original.isBce, isTrue);
      expect(original.bceYear, 457);
    });

    test('represents a leap second without pretending DateTime can', () {
      final leapSecond = AstroDateTime(2016, 12, 31, 23, 59, 60, 500);

      expect(leapSecond.fractionalSecond, closeTo(60.0000005, 1e-12));
      expect(leapSecond.toDateTimeUtc, throwsStateError);
      expect(
        AstroDateTime.fromJulianDate(leapSecond.toJulianDate<UtcScale>()),
        AstroDateTime(2017, 1, 1, 0, 0, 0, 500),
      );
    });

    test('matches J2000 and ISO weekday conventions', () {
      final j2000 = AstroDateTime(2000, 1, 1, 12);
      final jd = j2000.toJulianDate<TtScale>();

      expect(jd.dayNumber, 2451545);
      expect(jd.dayFraction, 0);
      expect(j2000.toJ2000(), 0);
      expect(j2000.weekday, DateTime.saturday);
    });

    test('rejects invalid components', () {
      expect(() => AstroDateTime(2025, 2, 29), throwsRangeError);
      expect(() => AstroDateTime(2026, 1, 1, 0, 0, 60), throwsArgumentError);
      expect(
        () => AstroDateTime(2026, 1, 1, 0, 0, 0, 1000000000),
        throwsRangeError,
      );
    });
  });

  group('JulianDate', () {
    test('normalizes positive and negative fractions', () {
      final negative = JulianDate<TtScale>.fromParts(2451545, -0.25);
      final positive = JulianDate<TtScale>.fromParts(2451545, 1.25);

      expect(negative.dayNumber, 2451544);
      expect(negative.dayFraction, 0.75);
      expect(positive.dayNumber, 2451546);
      expect(positive.dayFraction, 0.25);
    });

    test('preserves nanosecond differences before the ABI merge', () {
      final start = JulianDate<TtScale>.fromParts(2451545, 0);
      final end = start.addNanoseconds(1);

      expect(end.secondsDifference(start), closeTo(1e-9, 1e-21));
      // A single absolute double cannot retain this increment.
      expect(end.toDouble(), start.toDouble());
    });

    test('uses complete Duration microseconds', () {
      final start = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final end = start.add(const Duration(microseconds: 1234567));

      expect(end.secondsDifference(start), closeTo(1.234567, 1e-12));
      expect(end.difference(start), const Duration(microseconds: 1234567));
    });
  });
}
