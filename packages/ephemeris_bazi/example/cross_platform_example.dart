import 'package:ephemeris/ephemeris.dart' as eph;
import 'package:ephemeris_bazi/ephemeris_bazi.dart';

/// Deploy the JS/Wasm pair at this URL for Web. Native ignores this URI.
Future<void> main() async {
  final runtime = await eph.Ephemeris.initialize(
    wasmModuleUri: Uri.parse('assets/taiyin_web.js'),
  );
  final context = runtime.createContext();
  final bazi = context.bazi;
  try {
    final result = bazi.calculateLocal(
      eph.AstroDateTime(2003, 3, 13, 14, 15),
      gender: BaziGender.male,
      clock: const BaziClock(
        mode: BaziClockMode.apparentSolar,
        longitudeRadians: 118.582 * 3.141592653589793 / 180,
      ),
    );
    print(result.value.pillars);
    print(result.value.qiyun.startCivilTime);
    print(result.flags.values);
  } finally {
    bazi.close();
    context.close();
  }
}
