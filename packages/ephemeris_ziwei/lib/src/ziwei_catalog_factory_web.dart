import 'ziwei_api_web.dart';

ZiweiDataCatalog createZiweiCatalog({
  String? profilePath,
  String? libraryPath,
  String? coreLibraryPath,
}) => createWebZiweiCatalog(
  profilePath: profilePath,
  libraryPath: libraryPath,
  coreLibraryPath: coreLibraryPath,
);
