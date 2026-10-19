import 'dart:typed_data';
import 'backend_call.dart';

abstract interface class StarCatalogBackend {
  BackendCall<bool> addPath(String path, {required bool compiled});
  BackendCall<bool> addBytes(Uint8List bytes, {required bool compiled});
  void clear();
  int get count;
  BackendCall<double> magnitudeOf(String key);
}
