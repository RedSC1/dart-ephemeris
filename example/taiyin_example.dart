import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';

/// A small end-to-end tour of the Ephemeris Dart API.
///
/// Run with a path to a built ABI-8 Taiyin shared library (or no argument to
/// use the copy bundled in `lib/native/`):
///
/// ```sh
/// dart run example/taiyin_example.dart
/// ```
void main(List<String> arguments) {
  final ephemeris = Ephemeris.open(libraryPath: arguments.firstOrNull);
  final context = ephemeris.createContext();

  try {
    // Core ephemeris: a Moon position; the native diagnostic lands on
    // context.lastDiagnostic.
    final moon = context.positionTt(
      Body.moon,
      JulianDate<TtScale>.fromDouble(2460409.0),
      flags: {PositionFlag.xyz, PositionFlag.speed},
    );
    print('Taiyin ${ephemeris.libraryVersion}, ABI ${ephemeris.abiVersion}');
    print('Moon position: ${moon.coordinates}');
    print('Moon velocity: ${moon.rates}');

    // Chinese calendar: solar -> lunar conversion.
    final lunar = context.chineseCalendar.fromSolar(
      const SolarDate(year: 2024, month: 2, day: 10),
    );
    print('2024-02-10 -> lunar ${lunar.year}-${lunar.month}-${lunar.day}');

    // Ganzhi: the day pillar of a civil date.
    final dayPillar = context.ganzhi.dayPillar(AstroDateTime(2024, 2, 10));
    print(
      'Day pillar: $dayPillar (nayin ${context.ganzhi.nayinElement(dayPillar)})',
    );

    // BaZi (requires a library built with the BaZi extension): four pillars,
    // the natal chart, and the first da-yun.
    if (ephemeris.hasCapability(Capability.bazi)) {
      final pillars = context.chineseCalendar.fourPillars(
        instantUtc: JulianDate<UtcScale>.fromDouble(2460351.0),
        virtualTime: AstroDateTime(2024, 2, 10, 12),
      );
      print(
        'Four pillars: ${pillars.year} ${pillars.month} '
        '${pillars.day} ${pillars.hour}',
      );

      final chart = context.bazi.calcChart(pillars);
      final qiyun = context.bazi.calcQiyun(
        birthJdUt: JulianDate<Ut1Scale>.fromDouble(2460351.0),
        birthCivilTime: AstroDateTime(2024, 2, 10, 12),
        chart: chart,
        gender: BaziGender.male,
      );
      final dayun = context.bazi.fillDayun(
        birthCivilTime: AstroDateTime(2024, 2, 10, 12),
        chart: chart,
        qiyun: qiyun,
        requestedCount: 3,
      );
      print('Qi-yun starts at age ${qiyun.startAgeYears.toStringAsFixed(2)}');
      print('Da-yun: ${dayun.map((entry) => entry.ganzhi).join(', ')}');
    } else {
      print('(library built without the BaZi extension; BaZi demo skipped)');
    }
  } finally {
    context.close();
  }
}
