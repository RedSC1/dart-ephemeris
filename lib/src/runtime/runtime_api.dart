part of '../taiyin.dart';

/// Configuration for Taiyin's process-wide native runtime.
final class RuntimeOptions {
  const RuntimeOptions({
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
/// Open this object before creating user [EphemerisContext] instances.
/// Source-path, EOP-table, and lunar-limb mutations are setup-time operations;
/// finish them before starting concurrent calculations.
///
/// Every [open] or [fromDynamicLibrary] call currently reinitializes the
/// process-wide native runtime. Call one of them once in the application's main
/// isolate. Worker isolates must use [EphemerisContext.attach] instead.
final class Ephemeris {
  Ephemeris._(this._library, this._bindings, this._nativeState) {
    starCatalog = StarCatalog._(_bindings);
  }

  final DynamicLibrary _library;
  final TaiyinBindings _bindings;
  final _NativeLibraryState _nativeState;
  late final StarCatalog starCatalog;

  /// Opens Ephemeris and performs process-wide native runtime setup.
  factory Ephemeris.open({
    String? libraryPath,
    RuntimeOptions options = const RuntimeOptions(),
  }) {
    return Ephemeris.fromDynamicLibrary(
      _openLibrary(libraryPath),
      options: options,
    );
  }

  /// Opens Ephemeris from an already-loaded native library.
  factory Ephemeris.fromDynamicLibrary(
    DynamicLibrary library, {
    RuntimeOptions options = const RuntimeOptions(),
  }) {
    final state = _nativeLibraryStateFor(library);
    _initializeRuntime(
      state.bindings,
      options,
      afterNativeInitializationAttempt: () {
        _closeCustomTargetRegistrationsAfterNativeClear(state);
        _closeCustomAyanamshaRegistrationsAfterNativeClear(state);
        _closeCustomHouseSystemRegistrationsAfterNativeClear(state);
      },
    );
    return Ephemeris._(library, state.bindings, state);
  }

  /// Creates a new independent user calculation context.
  EphemerisContext createContext() {
    return EphemerisContext._create(_library, _nativeState);
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
  Set<Capability> get availableCapabilities {
    final mask = capabilities;
    return Set.unmodifiable({
      for (final capability in Capability.values)
        if ((mask & capability.mask) != 0) capability,
    });
  }

  bool hasCapability(Capability capability) {
    return (capabilities & capability.mask) != 0;
  }

  /// Registers a process-wide custom target backed by Dart evaluators.
  ///
  /// [targetId] must be negative and may have only one active registration.
  /// Keep the returned handle and call [CustomTargetRegistration.close]
  /// when the target is no longer needed.
  ///
  /// Evaluators may be invoked by calculations in worker isolates. Dart
  /// therefore requires the evaluator and everything it captures to be
  /// transitively immutable. Registration throws [ArgumentError] when that
  /// requirement is not met. Callback exceptions become
  /// `TAIYIN_ERROR_INTERNAL`; throw [CustomEvaluatorFailure] to return a
  /// deliberate native failure status.
  ///
  /// Register and close custom targets from the long-lived main isolate.
  /// Registration changes must not overlap calculations in any isolate.
  ///
  /// When [stateEvaluator] is omitted, Ephemeris derives state vectors through
  /// its native finite-difference fallback.
  CustomTargetRegistration registerCustomTarget(
    int targetId, {
    required CustomPositionEvaluator positionEvaluator,
    CustomStateEvaluator? stateEvaluator,
  }) {
    if (!hasCapability(Capability.customTargets)) {
      throw UnsupportedError(
        'The loaded Taiyin library does not support custom targets.',
      );
    }
    return _registerCustomTarget(
      _library,
      _nativeLibraryStateFor(_library),
      targetId,
      positionEvaluator,
      stateEvaluator,
    );
  }

  /// Clears every process-wide native custom target.
  ///
  /// This also closes the Dart registration handles owned by this isolate.
  /// Native position evaluators registered through the C ABI by other clients
  /// are removed as well.
  ///
  /// This is a setup-time operation and must not overlap calculations in any
  /// isolate. Existing registration handles become closed.
  void clearCustomTargets() {
    final state = _nativeLibraryStateFor(_library);
    _bindings.taiyin_clear_native_position_evaluators();
    _closeCustomTargetRegistrationsAfterNativeClear(state);
  }

  /// Registers a process-wide custom ayanamsha backed by a Dart evaluator.
  ///
  /// [modelId] must be at least 10000 and may have only one active Dart
  /// registration. Keep the returned handle and call
  /// [CustomAyanamshaRegistration.close] when it is no longer needed.
  ///
  /// Evaluators may be invoked by calculations in worker isolates, so the
  /// evaluator and everything it captures must be transitively immutable.
  /// Callback exceptions become `TAIYIN_ERROR_INTERNAL`. Register and close
  /// models from the long-lived main isolate; those setup changes must not
  /// overlap calculations in any isolate. Reopening Ephemeris resets the native
  /// runtime and clears C-API callbacks; close any handle still retained by a
  /// different isolate before discarding that isolate.
  CustomAyanamshaRegistration registerCustomAyanamshaModel(
    int modelId, {
    required CustomAyanamshaEvaluator evaluator,
    PrecessionModel? referencePrecessionModel,
  }) {
    if (!hasCapability(Capability.customAyanamsha)) {
      throw UnsupportedError(
        'The loaded Taiyin library does not support custom ayanamsha models.',
      );
    }
    return _registerCustomAyanamshaModel(
      _nativeLibraryStateFor(_library),
      modelId,
      evaluator,
      referencePrecessionModel,
    );
  }

  /// Registers a process-wide custom house system backed by a Dart evaluator.
  ///
  /// [modelId] must be at least 10000 and may have only one active Dart
  /// registration. [fallback] is used by Ephemeris when the evaluator rejects a
  /// calculation; omit it to return the native evaluation failure instead.
  /// Keep the returned handle and call [CustomHouseSystemRegistration.close]
  /// when it is no longer needed.
  ///
  /// Evaluators may be invoked by calculations in worker isolates, so the
  /// evaluator and everything it captures must be transitively immutable.
  /// Register and close models from the long-lived main isolate; those setup
  /// changes must not overlap calculations in any isolate. A fallback model
  /// must be closed only after models that select it as their fallback are
  /// closed. Reopening Ephemeris resets the native runtime and clears C-API
  /// callbacks; close any handle still retained by a different isolate before
  /// discarding that isolate.
  CustomHouseSystemRegistration registerCustomHouseSystemModel(
    int modelId, {
    required CustomHouseSystemEvaluator evaluator,
    HouseSystemModel? fallback,
  }) {
    if (!hasCapability(Capability.customHouses)) {
      throw UnsupportedError(
        'The loaded Taiyin library does not support custom house systems.',
      );
    }
    return _registerCustomHouseSystemModel(
      _nativeLibraryStateFor(_library),
      modelId,
      evaluator,
      fallback,
    );
  }

  /// Clears all C-API custom ayanamsha models and closes Dart-owned handles.
  ///
  /// Built-in and non-C-API native models are not affected. This setup-time
  /// operation must not overlap calculations in any isolate. Handles retained
  /// in other isolates become stale but are safe to close later.
  void clearCustomAyanamshaModels() {
    final state = _nativeLibraryStateFor(_library);
    _bindings.taiyin_clear_ayanamsha_models();
    _closeCustomAyanamshaRegistrationsAfterNativeClear(state);
  }

  /// Clears all C-API custom house systems and closes Dart-owned handles.
  ///
  /// Built-in and non-C-API native models are not affected. This setup-time
  /// operation must not overlap calculations in any isolate. Handles retained
  /// in other isolates become stale but are safe to close later.
  void clearCustomHouseSystemModels() {
    final state = _nativeLibraryStateFor(_library);
    _bindings.taiyin_clear_house_system_models();
    _closeCustomHouseSystemRegistrationsAfterNativeClear(state);
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
  StatusCategory statusCategory(int status) {
    return StatusCategory.fromId(_bindings.taiyin_status_category_of(status));
  }

  /// Formats a structured native calculation diagnostic for logs or support.
  ///
  /// The result is the native library's stable, single-line representation.
  /// It is intended for humans rather than as a serialization format.
  String formatEphemerisDiagnostic(EphemerisDiagnostic diagnostic) {
    return using((arena) {
      final nativeDiagnostic = arena<taiyin_ephemeris_diagnostic>();
      _writeEphemerisDiagnostic(nativeDiagnostic, diagnostic);
      final requiredSize = arena<Size>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_format_ephemeris_diagnostic(
          nativeDiagnostic,
          nullptr,
          0,
          requiredSize,
        ),
      );
      if (requiredSize.value == 0) {
        throw StateError(
          'Native diagnostic formatter returned an empty required size.',
        );
      }
      final output = arena<Char>(requiredSize.value);
      // The native C ABI requires out_required_size on both formatting calls.
      final outputRequiredSize = arena<Size>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_format_ephemeris_diagnostic(
          nativeDiagnostic,
          output,
          requiredSize.value,
          outputRequiredSize,
        ),
      );
      return output.cast<Utf8>().toDartString();
    });
  }

  /// Registers Taiyin's built-in node and Lilith targets for position routes.
  ///
  /// After registration, use [AstrologyTarget] with a context's
  /// position or state API. Calling this more than once is harmless. This is
  /// a setup-time operation and must not overlap calculations in any isolate.
  void registerBuiltinAstrologyTargets() {
    if (!hasCapability(Capability.astrology)) {
      throw UnsupportedError(
        'The loaded Taiyin library does not support astrology targets.',
      );
    }
    _checkStatus(
      _bindings,
      _bindings.taiyin_register_builtin_astrology_targets(),
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

void _initializeRuntime(
  TaiyinBindings bindings,
  RuntimeOptions options, {
  void Function()? afterNativeInitializationAttempt,
}) {
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

    final status = bindings.taiyin_runtime_initialize(config);
    // A valid native reset attempt clears callbacks before it can fail.
    // Mirror that transition in this isolate before propagating the status.
    afterNativeInitializationAttempt?.call();
    _checkStatus(bindings, status);
  });
}
