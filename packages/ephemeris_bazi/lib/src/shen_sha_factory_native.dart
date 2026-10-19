import 'bazi_api.dart';
import 'shen_sha_backend.dart';

BaziShenShaCatalogBackend createShenShaBackend({
  String? libraryPath,
  String? coreLibraryPath,
}) => createNativeBaziShenShaBackend(
  libraryPath: libraryPath,
  coreLibraryPath: coreLibraryPath,
);
