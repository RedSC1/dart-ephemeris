import 'ziwei_api.dart';

ZiweiDataCatalog createZiweiCatalog({
  String? profilePath,
  String? libraryPath,
  String? coreLibraryPath,
}) => createNativeZiweiCatalog(
  profilePath: profilePath,
  libraryPath: libraryPath,
  coreLibraryPath: coreLibraryPath,
);
