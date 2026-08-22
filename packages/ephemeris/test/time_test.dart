import 'package:ephemeris/ephemeris.dart';
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

    test(
      'converts a civil time to a standard Julian day with a zone offset',
      () {
        // 12:00 UTC+8 is the same instant as 04:00 UTC. The scalar Julian-day
        // merge limits both sides to tens of microseconds, so compare loosely.
        final beijingNoon = AstroDateTime(2024, 1, 1, 12);
        expect(
          beijingNoon.toJulianDay(utcOffsetHours: 8),
          closeTo(AstroDateTime(2024, 1, 1, 4).toJulianDay(), 1e-8),
        );
        expect(
          beijingNoon.toJ2000(utcOffsetHours: 8),
          closeTo(AstroDateTime(2024, 1, 1, 4).toJ2000(), 1e-8),
        );
      },
    );

    test('fromJulianDay materializes a civil value in the chosen zone', () {
      final utcInstant = AstroDateTime(2024, 1, 1, 4).toJulianDay();
      final inBeijing = AstroDateTime.fromJulianDay(
        utcInstant,
        utcOffsetHours: 8,
      );
      // 04:00 UTC shown on a UTC+8 clock reads 12:00.
      expect(inBeijing.hour, 12);
      expect(
        inBeijing.secondsDifference(AstroDateTime(2024, 1, 1, 12)).abs(),
        lessThan(1e-3),
      );
    });

    test('treats an omitted offset as a UTC reading', () {
      final value = AstroDateTime(2026, 7, 19, 12, 34, 56, 123456789);
      // toJulianDay() without an offset is unchanged from the merge form.
      expect(value.toJulianDay(), value.toJulianDate<TtScale>().toDouble());
      // fromJulianDay(value) still round-trips within the double resolution.
      expect(
        AstroDateTime.fromJulianDay(
          value.toJulianDay(),
        ).secondsDifference(value).abs(),
        lessThan(1e-3),
      );
    });

    test('round-trips a zone offset through a standard Julian day', () {
      final original = AstroDateTime(2026, 7, 19, 12, 34, 56, 123456789);
      final roundTrip = AstroDateTime.fromJulianDay(
        original.toJulianDay(utcOffsetHours: 8),
        utcOffsetHours: 8,
      );
      // The double merge is exact to tens of microseconds, so assert a
      // sub-millisecond bound rather than exact field equality.
      expect(roundTrip.secondsDifference(original).abs(), lessThan(1e-3));
    });

    test('toJulianDate applies the zone offset in split precision', () {
      final birth = AstroDateTime(2024, 2, 10, 12, 34, 56, 123456789);
      final utc = AstroDateTime.fromJulianDate(
        birth.toJulianDate<UtcScale>(utcOffsetHours: 8),
      );
      // 12:34:56.123456789 UTC+8 is 04:34:56.123456789 UTC. The split path
      // keeps the nanosecond that a scalar double merge would lose.
      expect(utc, AstroDateTime(2024, 2, 10, 4, 34, 56, 123456789));
    });

    test('toJulianDate offset agrees with the scalar toJulianDay', () {
      final birth = AstroDateTime(2024, 2, 10, 12);
      // The split path shifts then merges; the scalar path merges then
      // subtracts. The two differ by a few microseconds (within the ~40us
      // scalar resolution), so compare loosely rather than bit-for-bit.
      expect(
        birth.toJulianDate<UtcScale>(utcOffsetHours: 8).toDouble(),
        closeTo(birth.toJulianDay(utcOffsetHours: 8), 1e-9),
      );
    });

    test('fromJulianDate materializes a civil value in the chosen zone', () {
      final utc = AstroDateTime(2024, 2, 10, 4, 34, 56, 123456789);
      final beijing = AstroDateTime.fromJulianDate(
        utc.toJulianDate<UtcScale>(),
        utcOffsetHours: 8,
      );
      expect(beijing, AstroDateTime(2024, 2, 10, 12, 34, 56, 123456789));
    });

    test('converts with negative and fractional zone offsets', () {
      // 12:00 UTC-5 is 17:00 UTC; 12:00 UTC+5:45 (Nepal) is 06:15 UTC.
      final localNoon = AstroDateTime(2024, 1, 1, 12);
      expect(
        localNoon.toJulianDay(utcOffsetHours: -5),
        closeTo(AstroDateTime(2024, 1, 1, 17).toJulianDay(), 1e-8),
      );
      expect(
        localNoon.toJulianDay(utcOffsetHours: 5.75),
        closeTo(AstroDateTime(2024, 1, 1, 6, 15).toJulianDay(), 1e-8),
      );
    });

    test('crosses date boundaries when shifting zones', () {
      // 00:30 UTC shown on a UTC-5 clock reads 19:30 the previous day.
      final western = AstroDateTime.fromJulianDate(
        AstroDateTime(2024, 1, 1, 0, 30).toJulianDate<UtcScale>(),
        utcOffsetHours: -5,
      );
      expect(western, AstroDateTime(2023, 12, 31, 19, 30));

      // 23:30 UTC shown on a UTC+14 clock reads 13:30 the next day.
      final eastern = AstroDateTime.fromJulianDate(
        AstroDateTime(2024, 1, 1, 23, 30).toJulianDate<UtcScale>(),
        utcOffsetHours: 14,
      );
      expect(eastern, AstroDateTime(2024, 1, 2, 13, 30));
    });

    test('absorbs a leap second before applying a zone offset', () {
      // The uniform 86,400-second-day split cannot display second 60; the
      // value rolls over to the next day before the offset is applied.
      final utc = AstroDateTime.fromJulianDate(
        AstroDateTime(
          2024,
          6,
          30,
          23,
          59,
          60,
        ).toJulianDate<UtcScale>(utcOffsetHours: 8),
      );
      expect(utc, AstroDateTime(2024, 6, 30, 16, 0, 0));

      final shownInBeijing = AstroDateTime.fromJulianDate(
        AstroDateTime(2016, 12, 31, 23, 59, 60).toJulianDate<UtcScale>(),
        utcOffsetHours: 8,
      );
      expect(shownInBeijing, AstroDateTime(2017, 1, 1, 8, 0, 0));
    });

    test('round-trips a zone offset through toJ2000 and fromJ2000', () {
      final original = AstroDateTime(2024, 2, 10, 12, 34, 56, 123456789);
      final roundTrip = AstroDateTime.fromJ2000(
        original.toJ2000(utcOffsetHours: 8),
        utcOffsetHours: 8,
      );
      // The J2000-relative form avoids the large-JD merge, so this stays
      // well within the tolerance of the scalar path.
      expect(roundTrip.secondsDifference(original).abs(), lessThan(1e-6));
    });

    test('rejects a non-finite utcOffsetHours', () {
      expect(
        () => AstroDateTime(2026, 1, 1).toJulianDay(utcOffsetHours: double.nan),
        throwsArgumentError,
      );
      expect(
        () => AstroDateTime.fromJ2000(0, utcOffsetHours: double.nan),
        throwsArgumentError,
      );
      expect(
        () => AstroDateTime(
          2026,
          1,
          1,
        ).toJulianDate<UtcScale>(utcOffsetHours: double.nan),
        throwsArgumentError,
      );
      expect(
        () =>
            AstroDateTime(2026, 1, 1).toJ2000(utcOffsetHours: double.infinity),
        throwsArgumentError,
      );
      expect(
        () =>
            AstroDateTime.fromJulianDay(2451545.0, utcOffsetHours: double.nan),
        throwsArgumentError,
      );
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

    test('carries a fraction rounded to one at the negative boundary', () {
      final value = JulianDate<TtScale>.fromParts(2451545, -5e-17);

      expect(value.dayNumber, 2451545);
      expect(value.dayFraction, 0);
      expect(value, JulianDate<TtScale>.fromParts(2451545, 0));
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
