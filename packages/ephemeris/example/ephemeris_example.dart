import 'package:ephemeris/ephemeris.dart';

/// A small end-to-end tour of the Ephemeris Dart API.
///
/// Run with a path to a built ABI-9 Taiyin shared library (or no argument to
/// use the copy bundled in `lib/native/`):
///
/// ```sh
/// dart run example/ephemeris_example.dart
/// ```
void main(List<String> arguments) {
  final ephemeris = Ephemeris.open(libraryPath: arguments.firstOrNull);
  final context = ephemeris.createContext();

  try {
    // Core ephemeris: a Moon position; the native diagnostic lands on
    // context.lastDiagnostic.
    final (value: moon, flags: moonFlags) = context.positionTt(
      Body.moon,
      JulianDate<TtScale>.fromDouble(2460409.0),
      flags: {PositionFlag.xyz, PositionFlag.speed},
    );
    print('Taiyin ${ephemeris.libraryVersion}, ABI ${ephemeris.abiVersion}');
    print('Moon position: ${moon.coordinates}');
    print('Moon velocity: ${moon.rates}');
    print('Moon result flags: ${moonFlags.values}');

    // Chinese calendar: solar -> lunar conversion.
    final lunar = context.chineseCalendar
        .fromSolar(const SolarDate(year: 2024, month: 2, day: 10))
        .value;
    print('2024-02-10 -> lunar ${lunar.year}-${lunar.month}-${lunar.day}');

    // Ganzhi: the day pillar of a civil date.
    final dayPillar = context.ganzhi.dayPillar(AstroDateTime(2024, 2, 10));
    print(
      'Day pillar: $dayPillar (nayin ${context.ganzhi.nayinElement(dayPillar)})',
    );
  } finally {
    context.close();
  }
}
