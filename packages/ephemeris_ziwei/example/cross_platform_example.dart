import 'package:ephemeris/ephemeris.dart' as eph;
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';

/// Default TOML tables are embedded in the opt-in C++ Wasm build.
Future<void> main() async {
  final runtime = await eph.Ephemeris.initialize(
    wasmModuleUri: Uri.parse('assets/taiyin_web.js'),
  );
  final context = runtime.createContext();
  final ziwei = context.ziwei;
  try {
    final chart = ziwei
        .calculateLocal(
          eph.AstroDateTime(2003, 3, 13, 14, 15),
          gender: ZiweiGender.male,
        )
        .value;
    try {
      print(chart.anchors.values);
      print(chart.palace(ZiweiPalace.life).stars.map((star) => star.key));
      final target = context.chineseCalendar
          .instantFromLocal(eph.AstroDateTime(2026, 10, 18, 12))
          .value;
      print(
        chart
            .setFlow(
              targetInstantUtc: target,
              targetVirtualTime: eph.AstroDateTime(2026, 10, 18, 12),
            )
            .value
            .targetMonthBuildingBranch,
      );
    } finally {
      chart.close();
    }
    final casting = ziwei.castingFromNumber(
      '20261018',
      gender: ZiweiGender.male,
    );
    try {
      print(casting.summary.palaceBranches);
    } finally {
      casting.close();
    }
  } finally {
    ziwei.close();
    context.close();
  }
}
