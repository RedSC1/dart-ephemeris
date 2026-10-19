import 'dart:typed_data';
import '../backend/backend_call.dart';
import '../backend/star_catalog_backend.dart';

/// Process-wide fixed-star catalogs. Complete setup before calculations start.
final class StarCatalog {
  StarCatalog.internal(this._backend, this._complete);
  final StarCatalogBackend _backend;
  final BackendCallCompletion _complete;

  /// Adds a compiled catalog from a native filesystem path (native only).
  void addTsc1(String path) => _addPath(path, true);

  /// Adds an editable catalog from a native filesystem path (native only).
  void addTsf1(String path) => _addPath(path, false);

  /// Adds an owned copy of a compiled TSC1 catalog on either platform.
  void addTsc1Bytes(Uint8List bytes) => _addBytes(bytes, true);

  /// Adds an owned copy of an editable TSF1 catalog on either platform.
  void addTsf1Bytes(Uint8List bytes) => _addBytes(bytes, false);

  /// Removes all process-wide fixed-star catalogs during setup.
  void clear() => _backend.clear();

  /// Number of loaded catalogs, not number of stars.
  int get count => _backend.count;

  /// Looks up visual magnitude by catalog ID, name or alias.
  double magnitudeOf(String starKey) {
    _validateString(starKey, 'starKey');
    final call = _backend.magnitudeOf(starKey);
    _complete(call);
    return call.value;
  }

  void _addPath(String path, bool compiled) {
    _validateString(path, 'path');
    _complete(_backend.addPath(path, compiled: compiled));
  }

  void _addBytes(Uint8List bytes, bool compiled) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'must not be empty');
    }
    _complete(_backend.addBytes(bytes, compiled: compiled));
  }

  static void _validateString(String value, String name) {
    if (value.isEmpty || value.contains('\u0000')) {
      throw ArgumentError.value(
        value,
        name,
        'must not be empty or contain NUL',
      );
    }
  }
}
