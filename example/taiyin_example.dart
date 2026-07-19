import 'package:taiyin/taiyin.dart';

void main(List<String> arguments) {
  final taiyin = Taiyin.open(libraryPath: arguments.firstOrNull);

  try {
    final moon = taiyin.positionTt(
      TaiyinBody.moon,
      2460409.0,
      flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
    );

    print('Taiyin ${taiyin.libraryVersion}, ABI ${taiyin.abiVersion}');
    print('Moon position: ${moon.coordinates}');
    print('Moon velocity: ${moon.rates}');
  } finally {
    taiyin.close();
  }
}
