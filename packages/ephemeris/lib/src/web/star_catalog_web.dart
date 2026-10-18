import 'dart:typed_data';
import '../backend/backend_call.dart';
import '../backend/star_catalog_backend.dart';
import '../result_flags.dart';
import '../runtime/source_bytes.dart';
import 'runtime_bytes_web.dart';
import 'wasm_module.dart';

final class WebStarCatalogBackend implements StarCatalogBackend {
  WebStarCatalogBackend(this._backend, this._files, this._ensureCurrent);
  final WasmBackend _backend;
  final WebRuntimeBytesBackend _files;
  final void Function() _ensureCurrent;
  @override
  BackendCall<bool> addPath(
    String path, {
    required bool compiled,
  }) => throw UnsupportedError(
    'Native star-catalog paths are not available on Web. Use addTsc1Bytes/addTsf1Bytes.',
  );
  @override
  BackendCall<bool> addBytes(Uint8List bytes, {required bool compiled}) {
    _ensureCurrent();
    if (!compiled) {
      return _files.load(RuntimeByteSourceKind.starText, 'stars.tsf1', bytes);
    }
    final reply = _backend.starCatalogBytes(bytes);
    return BackendCall(
      status: reply.status,
      flags: ResultFlags(reply.values[0].toInt()),
      value: reply.status == 0,
    );
  }

  @override
  void clear() {
    _ensureCurrent();
    _backend.resource(5);
  }

  @override
  int get count {
    _ensureCurrent();
    return _backend.resource(6).values[1].toInt();
  }

  @override
  BackendCall<double> magnitudeOf(String key) {
    _ensureCurrent();
    final reply = _backend.starMagnitude(key);
    return BackendCall(
      status: reply.status,
      flags: ResultFlags(reply.values[0].toInt()),
      value: reply.values[1],
    );
  }
}
