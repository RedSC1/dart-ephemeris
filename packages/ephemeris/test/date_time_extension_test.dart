import 'package:ephemeris/ephemeris.dart' as eph;
import 'package:test/test.dart';

void main() {
  test('DateTime adapter is available through the public prefixed import', () {
    final instant = DateTime.parse('2003-03-13T14:15:00+08:00');

    expect(instant.toUtcJulianDate(), isA<eph.UtcJulianDate>());
  });
}
