import 'dart:typed_data';
import 'package:ephemeris/ephemeris.dart' as eph;

/// Obtain [sources] from your HTTP client, asset bundle or native file API.
Future<void> calculate(Map<String, Uint8List> sources) async {
  final runtime = await eph.Ephemeris.initialize(
    wasmModuleUri: Uri.parse('assets/taiyin_web.js'),
  );
  for (final source in sources.entries) {
    runtime.addSourceBytes(source.key, source.value);
  }
  final context = runtime.createContext();
  try {
    final result = context.position.atUt1(
      eph.Body.moon,
      eph.Ut1JulianDate.fromDouble(2460409.25),
      flags: {eph.PositionFlag.speed},
    );
    print(result.value.coordinates);
    print(result.flags.values);
    final calendar = context.chineseCalendar;
    final local = eph.AstroDateTime(2003, 3, 13, 14, 15);
    print(calendar.fromLocal(local).value);
    print(calendar.fourPillarsLocal(local).value);
    final utc = calendar.instantFromLocal(local).value;
    final utcClock = context.time.reverseJulianDay(utc).value;
    print(context.time.scalesFromUtc(utcClock).value);
    final lunar = context.eclipses.nextLunarAtUt1(
      eph.Ut1JulianDate.fromDouble(2460925.5),
      options: {eph.LunarEclipseSearchOption.includeContacts},
    );
    print(lunar.value.maximum);
  } finally {
    context.close();
  }
}

// Empty input uses the built-in semi-analytic routes.
Future<void> main() => calculate({});
