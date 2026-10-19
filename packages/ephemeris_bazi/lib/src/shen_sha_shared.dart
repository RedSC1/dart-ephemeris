import 'package:ephemeris/ephemeris.dart';
import 'bazi_models.dart';
import 'shen_sha_models.dart';
import 'shen_sha_backend.dart';
import 'shen_sha_factory_native.dart'
    if (dart.library.js_interop) 'shen_sha_factory_web.dart';
import 'shen_sha_lifetime.dart'
    if (dart.library.ffi) 'dart:ffi'
    show Finalizable;

/// Immutable catalog facade shared by native and Web.
final class BaziShenShaCatalog implements Finalizable {
  factory BaziShenShaCatalog({String? libraryPath, String? coreLibraryPath}) =>
      BaziShenShaCatalog._(
        createShenShaBackend(
          libraryPath: libraryPath,
          coreLibraryPath: coreLibraryPath,
        ),
      );
  BaziShenShaCatalog._(this._backend);
  final BaziShenShaCatalogBackend _backend;
  BaziShenShaCatalog addModule(BaziShenShaModule module) =>
      BaziShenShaCatalog._(_backend.addModule(module));
  BaziShenShaCatalog removeModule(String label) =>
      BaziShenShaCatalog._(_backend.removeModule(label));
  BaziShenShaContext createContext({List<String> disabledIds = const []}) =>
      BaziShenShaContext._(_backend.createContext(disabledIds: disabledIds));
  void close() => _backend.close();
}

final class BaziShenShaContext implements Finalizable {
  BaziShenShaContext._(this._backend);
  final BaziShenShaContextBackend _backend;
  List<BaziShenShaMatch> evaluate({
    required BaziChart chart,
    required Ganzhi target,
    required BaziShenShaTargetKind targetKind,
    BaziGender? gender,
  }) => _backend.evaluate(
    chart: chart,
    target: target,
    targetKind: targetKind,
    gender: gender,
  );
  void close() => _backend.close();
}
