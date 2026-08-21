import 'package:taiyin/taiyin.dart';
import 'package:taiyin_ziwei/taiyin_ziwei.dart';

void main() {
  final context = Ephemeris.open().createContext();
  final ziwei = context.ziwei;
  try {
    final chart = ziwei
        .calculateLocal(
          AstroDateTime(2003, 3, 13, 14, 15),
          gender: ZiweiGender.male,
        )
        .value;
    try {
      print('Bureau: ${chart.anchors.bureau}');
      print('Ziwei branch: ${chart.anchors.ziwei}');
    } finally {
      chart.close();
    }
  } finally {
    ziwei.close();
    context.close();
  }
}
