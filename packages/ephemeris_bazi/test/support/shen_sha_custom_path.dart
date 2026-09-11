import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_bazi/ephemeris_bazi.dart';

void main(List<String> args) {
  // The parent sets TAIYIN_LIBRARY_PATH to an invalid default deliberately.
  final runtime = Ephemeris.open(libraryPath: args.single);
  final astro = runtime.createContext();
  final catalog = BaziShenShaCatalog(coreLibraryPath: args.single);
  final rules = catalog.createContext();
  rules.close();
  catalog.close();
  astro.close();
  print('custom-core-ok');
}
