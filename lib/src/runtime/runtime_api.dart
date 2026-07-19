part of '../taiyin.dart';

/// Process-wide Taiyin runtime data and cache management.
///
/// Every [Taiyin] instance loaded from the same native library shares this
/// state. Source-path, EOP-table, and lunar-limb mutations are setup-time
/// operations; finish them before starting concurrent calculations.
final class TaiyinRuntimeApi {
  TaiyinRuntimeApi._(this._bindings, this._ensureOpen, this._checkStatus);

  final TaiyinBindings _bindings;
  final void Function() _ensureOpen;
  final void Function(int status) _checkStatus;

  /// Adds [path] to the global ephemeris source catalog.
  ///
  /// Discovery happens immediately. Existing contexts see the updated global
  /// catalog.
  void addSourcePath(String path) {
    _ensureOpen();
    _requirePath(path, 'path');
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      _checkStatus(_bindings.taiyin_runtime_add_source_path(nativePath));
    });
  }

  /// Loads an Earth-orientation table from [path], replacing the current one.
  void loadEopTable(String path) {
    _ensureOpen();
    _requirePath(path, 'path');
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      _checkStatus(_bindings.taiyin_runtime_load_eop_table(nativePath));
    });
  }

  /// Installs Taiyin's built-in Earth-orientation table.
  void loadBuiltinEopTable() {
    _ensureOpen();
    _checkStatus(_bindings.taiyin_runtime_load_builtin_eop_table());
  }

  /// Removes the global Earth-orientation table.
  void clearEopTable() {
    _ensureOpen();
    _bindings.taiyin_runtime_clear_eop_table();
  }

  /// Whether a global Earth-orientation table is installed.
  bool get hasEopTable {
    _ensureOpen();
    return _bindings.taiyin_runtime_has_eop_table() != 0;
  }

  /// Loads a lunar-limb model from [path], replacing the current one.
  void loadLunarLimbModel(String path) {
    _ensureOpen();
    _requirePath(path, 'path');
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      _checkStatus(_bindings.taiyin_runtime_load_lunar_limb_model(nativePath));
    });
  }

  /// Removes the global lunar-limb model.
  void clearLunarLimbModel() {
    _ensureOpen();
    _bindings.taiyin_runtime_clear_lunar_limb_model();
  }

  /// Whether a global lunar-limb model is installed.
  bool get hasLunarLimbModel {
    _ensureOpen();
    return _bindings.taiyin_runtime_has_lunar_limb_model() != 0;
  }

  /// Clears every entry in the global ephemeris segment cache.
  void clearEphemerisCache() {
    _ensureOpen();
    _bindings.taiyin_runtime_clear_ephemeris_cache();
  }

  /// The number of descriptors in the global ephemeris catalog.
  int get catalogSize {
    _ensureOpen();
    return _bindings.taiyin_runtime_catalog_size();
  }

  /// The number of entries currently held in the global segment cache.
  int get cacheEntryCount {
    _ensureOpen();
    return _bindings.taiyin_runtime_cache_entry_count();
  }

  void _requirePath(String path, String name) {
    if (path.isEmpty) {
      throw ArgumentError.value(path, name, 'must not be empty');
    }
    if (path.contains('\u0000')) {
      throw ArgumentError.value(path, name, 'must not contain a NUL character');
    }
  }
}
