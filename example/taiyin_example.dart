import 'package:taiyin/taiyin.dart';

/// A small end-to-end tour of the Taiyin Dart API.
///
/// Run with a path to a built ABI-5 Taiyin shared library:
///
/// ```sh
/// dart run example/taiyin_example.dart ../taiyin-ephemeris/build-bazi/libtaiyin.dylib
/// ```
void main(List<String> arguments) {
  final taiyin = Taiyin.open(libraryPath: arguments.firstOrNull);
  final context = taiyin.createContext();

  try {
    // Core ephemeris: a Moon position and its native diagnostic.
    final moon = context.positionTt(
      TaiyinBody.moon,
      JulianDate<TtScale>.fromDouble(2460409.0),
      flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
    );
    print('Taiyin ${taiyin.libraryVersion}, ABI ${taiyin.abiVersion}');
    print('Moon position: ${moon.coordinates}');
    print('Moon velocity: ${moon.rates}');

    // Chinese calendar: solar -> lunar conversion.
    final lunar = context.chineseCalendar.fromSolar(
      const TaiyinSolarDate(year: 2024, month: 2, day: 10),
    );
    print('2024-02-10 -> lunar ${lunar.value.year}-${lunar.value.month}-${lunar.value.day}');

    // Ganzhi: the day pillar of a civil date.
    final dayPillar = context.ganzhi.dayPillar(AstroDateTime(2024, 2, 10));
    print('Day pillar: $dayPillar (nayin ${context.ganzhi.nayinElement(dayPillar)})');

    // BaZi (requires a library built with the BaZi extension): four pillars,
    // the natal chart, and the first da-yun.
    if (taiyin.hasCapability(TaiyinCapability.bazi)) {
      final pillars = context.chineseCalendar.fourPillars(
        instantUtc: JulianDate<UtcScale>.fromDouble(2460351.0),
        virtualTime: AstroDateTime(2024, 2, 10, 12),
      );
      print('Four pillars: ${pillars.value.year} ${pillars.value.month} '
          '${pillars.value.day} ${pillars.value.hour}');

      final chart = context.bazi.calcChart(pillars.value);
      final qiyun = context.bazi.calcQiyun(
        birthJdUt: JulianDate<Ut1Scale>.fromDouble(2460351.0),
        birthCivilTime: AstroDateTime(2024, 2, 10, 12),
        chart: chart,
        gender: TaiyinBaziGender.male,
        calendar: context.chineseCalendar,
      );
      final dayun = context.bazi.fillDayun(
        birthCivilTime: AstroDateTime(2024, 2, 10, 12),
        chart: chart,
        qiyun: qiyun.value,
        requestedCount: 3,
      );
      print('Qi-yun starts at age ${qiyun.value.startAgeYears.toStringAsFixed(2)}');
      print('Da-yun: ${dayun.map((entry) => entry.ganzhi).join(', ')}');
    } else {
      print('(library built without the BaZi extension; BaZi demo skipped)');
    }
  } finally {
    context.close();
  }
}
