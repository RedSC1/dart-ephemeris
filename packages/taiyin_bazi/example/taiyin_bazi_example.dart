import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';

void main() {
  final context = Ephemeris.open().createContext();
  final bazi = context.bazi;
  try {
    final result = bazi.calculateLocal(
      AstroDateTime(2003, 3, 13, 14, 15),
      gender: BaziGender.male,
    );
    final dayun = bazi.fillDayun(
      birthCivilTime: result.value.localTime,
      chart: result.value.chart,
      qiyun: result.value.qiyun,
      requestedCount: 5,
    );
    final pillars = result.value.pillars;
    print(
      'Four pillars: ${pillars.year}, ${pillars.month}, '
      '${pillars.day}, ${pillars.hour}',
    );
    print('Qi-yun: ${result.value.qiyun.startCivilTime}');
    print('Da-yun: ${dayun.map((entry) => entry.ganzhi).join(', ')}');
  } finally {
    bazi.close();
    context.close();
  }
}
