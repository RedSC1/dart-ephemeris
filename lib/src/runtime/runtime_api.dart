part of '../taiyin.dart';

/// Configuration for Taiyin's process-wide native runtime.
final class TaiyinRuntimeOptions {
  const TaiyinRuntimeOptions({
    this.dataRoot,
    this.sourcePaths = const [],
    this.eopPath,
    this.lunarLimbPath,
    this.segmentCacheMaxEntries,
    this.loadPackagedData = true,
    this.loadBuiltinEop = true,
    this.strictDiscovery = false,
  });

  final String? dataRoot;
  final List<String> sourcePaths;
  final String? eopPath;
  final String? lunarLimbPath;
  final int? segmentCacheMaxEntries;
  final bool loadPackagedData;
  final bool loadBuiltinEop;
  final bool strictDiscovery;
}

/// The process-wide Taiyin library facade and its global resources.
///
/// [open] loads the native library and performs its internal default runtime
/// setup. It does not create or own a user calculation context.
///
/// Open this object before creating user [TaiyinContext] instances.
/// Source-path, EOP-table, and lunar-limb mutations are setup-time operations;
/// finish them before starting concurrent calculations.
///
/// Every [open] or [fromDynamicLibrary] call currently reinitializes the
/// process-wide native runtime. Call one of them once in the application's main
/// isolate. Worker isolates must use [TaiyinContext.attach] instead.
final class Taiyin {
  Taiyin._(this._library, this._bindings, this._contextFinalizer) {
    starCatalog = TaiyinStarCatalog._(_bindings);
  }

  final DynamicLibrary _library;
  final TaiyinBindings _bindings;
  final NativeFinalizer _contextFinalizer;
  late final TaiyinStarCatalog starCatalog;

  /// Opens Taiyin and performs process-wide native runtime setup.
  factory Taiyin.open({
    String? libraryPath,
    TaiyinRuntimeOptions options = const TaiyinRuntimeOptions(),
  }) {
    return Taiyin.fromDynamicLibrary(
      _openLibrary(libraryPath),
      options: options,
    );
  }

  /// Opens Taiyin from an already-loaded native library.
  factory Taiyin.fromDynamicLibrary(
    DynamicLibrary library, {
    TaiyinRuntimeOptions options = const TaiyinRuntimeOptions(),
  }) {
    final state = _nativeLibraryStateFor(library);
    _initializeRuntime(state.bindings, options);
    return Taiyin._(library, state.bindings, state.contextFinalizer);
  }

  /// Creates a new independent user calculation context.
  TaiyinContext createContext() {
    return TaiyinContext._create(_library, _bindings, _contextFinalizer);
  }

  /// The Taiyin C ABI version.
  int get abiVersion => _bindings.taiyin_get_c_abi_version();

  /// The Taiyin native library's semantic version.
  String get libraryVersion =>
      _bindings.taiyin_get_library_version().cast<Utf8>().toDartString();

  /// The codename shared by this semantic-version major release.
  String get libraryCodename =>
      _bindings.taiyin_get_library_codename().cast<Utf8>().toDartString();

  /// The native module capability bitset.
  int get capabilities => _bindings.taiyin_get_capabilities();

  /// Native modules available in the loaded Taiyin library.
  Set<TaiyinCapability> get availableCapabilities {
    final mask = capabilities;
    return Set.unmodifiable({
      for (final capability in TaiyinCapability.values)
        if ((mask & capability.mask) != 0) capability,
    });
  }

  bool hasCapability(TaiyinCapability capability) {
    return (capabilities & capability.mask) != 0;
  }

  /// Stable symbolic name for a native status code.
  String statusName(int status) {
    return _readNativeString(_bindings.taiyin_status_name(status));
  }

  /// Human-readable description for a native status code.
  String statusMessage(int status) {
    return _readNativeString(_bindings.taiyin_status_message(status));
  }

  /// Broad category for a native status code.
  TaiyinStatusCategory statusCategory(int status) {
    return TaiyinStatusCategory.fromId(
      _bindings.taiyin_status_category_of(status),
    );
  }

  /// Adds [path] to the global ephemeris source catalog.
  ///
  /// Discovery happens immediately. Existing contexts see the updated global
  /// catalog.
  void addSourcePath(String path) {
    _requirePath(path, 'path');
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_runtime_add_source_path(nativePath),
      );
    });
  }

  /// Loads an Earth-orientation table from [path], replacing the current one.
  ///
  /// This is a setup-time operation and must not overlap calculations in any
  /// isolate.
  void loadEopTable(String path) {
    _requirePath(path, 'path');
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_runtime_load_eop_table(nativePath),
      );
    });
  }

  /// Installs Taiyin's built-in Earth-orientation table.
  ///
  /// This is a setup-time operation and must not overlap calculations in any
  /// isolate.
  void loadBuiltinEopTable() {
    _checkStatus(_bindings, _bindings.taiyin_runtime_load_builtin_eop_table());
  }

  /// Removes the global Earth-orientation table.
  ///
  /// This is a setup-time operation and must not overlap calculations in any
  /// isolate.
  void clearEopTable() {
    _bindings.taiyin_runtime_clear_eop_table();
  }

  /// Whether a global Earth-orientation table is installed.
  bool get hasEopTable => _bindings.taiyin_runtime_has_eop_table() != 0;

  /// Loads a lunar-limb model from [path], replacing the current one.
  ///
  /// This is a setup-time operation and must not overlap calculations in any
  /// isolate. The native runtime releases the previous model immediately.
  void loadLunarLimbModel(String path) {
    _requirePath(path, 'path');
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_runtime_load_lunar_limb_model(nativePath),
      );
    });
  }

  /// Removes the global lunar-limb model.
  ///
  /// This is a setup-time operation and must not overlap calculations in any
  /// isolate. The native runtime releases the current model immediately.
  void clearLunarLimbModel() {
    _bindings.taiyin_runtime_clear_lunar_limb_model();
  }

  /// Whether a global lunar-limb model is installed.
  bool get hasLunarLimbModel =>
      _bindings.taiyin_runtime_has_lunar_limb_model() != 0;

  /// Clears every entry in the global ephemeris segment cache.
  void clearEphemerisCache() {
    _bindings.taiyin_runtime_clear_ephemeris_cache();
  }

  /// The number of descriptors in the global ephemeris catalog.
  int get catalogSize => _bindings.taiyin_runtime_catalog_size();

  /// The number of entries currently held in the global segment cache.
  int get cacheEntryCount => _bindings.taiyin_runtime_cache_entry_count();

  void _requirePath(String path, String name) {
    if (path.isEmpty) {
      throw ArgumentError.value(path, name, 'must not be empty');
    }
    if (path.contains('\u0000')) {
      throw ArgumentError.value(path, name, 'must not contain a NUL character');
    }
  }
}

void _initializeRuntime(TaiyinBindings bindings, TaiyinRuntimeOptions options) {
  using((arena) {
    final config = arena<taiyin_runtime_config>();
    bindings.taiyin_runtime_config_init(config);

    if (options.segmentCacheMaxEntries case final value?) {
      if (value <= 0) {
        throw ArgumentError.value(
          value,
          'segmentCacheMaxEntries',
          'must be positive',
        );
      }
      config.ref.segment_cache_max_entries = value;
    }

    config.ref
      ..load_packaged_data = options.loadPackagedData ? 1 : 0
      ..load_builtin_eop = options.loadBuiltinEop ? 1 : 0
      ..strict_discovery = options.strictDiscovery ? 1 : 0;

    if (options.dataRoot case final value?) {
      config.ref.data_root = value.toNativeUtf8(allocator: arena).cast();
    }
    if (options.eopPath case final value?) {
      config.ref.eop_path = value.toNativeUtf8(allocator: arena).cast();
    }
    if (options.lunarLimbPath case final value?) {
      config.ref.lunar_limb_path = value.toNativeUtf8(allocator: arena).cast();
    }
    if (options.sourcePaths.isNotEmpty) {
      final paths = arena<Pointer<Char>>(options.sourcePaths.length);
      for (var index = 0; index < options.sourcePaths.length; index++) {
        paths[index] = options.sourcePaths[index]
            .toNativeUtf8(allocator: arena)
            .cast();
      }
      config.ref
        ..source_paths = paths
        ..source_path_count = options.sourcePaths.length;
    }

    _checkStatus(bindings, bindings.taiyin_runtime_initialize(config));
  });
}
