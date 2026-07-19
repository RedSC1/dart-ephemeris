import 'package:taiyin/taiyin.dart';

void main(List<String> arguments) {
  final taiyin = Taiyin.open(libraryPath: arguments.firstOrNull);
  final context = taiyin.createContext();

  try {
    final moon = context.positionTt(
      TaiyinBody.moon,
      JulianDate<TtScale>.fromDouble(2460409.0),
      flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
    );

    print('Taiyin ${taiyin.libraryVersion}, ABI ${taiyin.abiVersion}');
    print('Moon position: ${moon.coordinates}');
    print('Moon velocity: ${moon.rates}');
  } finally {
    context.close();
  }
}
