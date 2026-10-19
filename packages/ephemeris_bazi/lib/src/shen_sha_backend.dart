import 'package:ephemeris/ephemeris.dart';
import 'bazi_models.dart';
import 'shen_sha_models.dart';

abstract interface class BaziShenShaCatalogBackend {
  BaziShenShaCatalogBackend addModule(BaziShenShaModule module);
  BaziShenShaCatalogBackend removeModule(String label);
  BaziShenShaContextBackend createContext({
    List<String> disabledIds = const [],
  });
  void close();
}

abstract interface class BaziShenShaContextBackend {
  List<BaziShenShaMatch> evaluate({
    required BaziChart chart,
    required Ganzhi target,
    required BaziShenShaTargetKind targetKind,
    BaziGender? gender,
  });
  void close();
}
