import 'dart:typed_data';
import '../backend/backend_call.dart';
import '../result_flags.dart';
import '../runtime/source_bytes.dart';
import 'wasm_module.dart';

/// Web storage/registration only. No filesystem details escape to the facade.
final class WebRuntimeBytesBackend implements RuntimeBytesBackend {
  WebRuntimeBytesBackend(this._backend, this._ensureCurrent);
  final WasmBackend _backend;
  final void Function() _ensureCurrent;
  final Set<String> _sources = {};
  final Set<String> _files = {};
  int _sequence = 0;

  @override
  BackendCall<bool> load(
    RuntimeByteSourceKind kind,
    String name,
    Uint8List bytes,
  ) {
    _ensureCurrent();
    final source = kind == RuntimeByteSourceKind.ephemeris;
    if (source && _sources.contains(name.toLowerCase())) {
      throw StateError('Byte source already registered: $name');
    }
    final group = source ? 'ephemeris' : '${kind.name}-${_sequence++}';
    // Keep owned storage outside the core's conventional /data discovery root.
    // Otherwise reinitialization could rediscover files just before cleanup.
    final path = '/ephemeris-bytes/$group/$name';
    _backend.writeBytes(path, bytes);
    try {
      final reply = _backend.loadFile(kind.index, path);
      if (reply.status == 0) {
        _files.add(path);
        if (source) _sources.add(name.toLowerCase());
      } else {
        _backend.unlink(path);
      }
      return BackendCall(
        status: reply.status,
        flags: ResultFlags(reply.values[0].toInt()),
        value: reply.status == 0,
      );
    } catch (_) {
      // Only this new, unpublished path can be removed on registration failure.
      try {
        _backend.unlink(path);
      } catch (_) {
        /* preserve the loading error */
      }
      rethrow;
    }
  }

  /// Invoke only after the C++ runtime has released its old file consumers.
  void releaseAfterReset() {
    for (final path in _files) {
      _backend.unlink(path);
    }
    _files.clear();
    _sources.clear();
  }
}
