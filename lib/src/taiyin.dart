import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'bindings/taiyin_bindings.g.dart';
import 'context/context_api.dart';
import 'native_compatibility.dart';
import 'position/position_api.dart';
import 'time/julian_date.dart';
import 'time/time_api.dart';
import 'time/time_scale.dart';

/// A feature module reported by the loaded Taiyin native library.
enum TaiyinCapability {
  runtime(1 << 0),
  time(1 << 1),
  position(1 << 2),
  star(1 << 3),
  visibility(1 << 4),
  phenomena(1 << 5),
  events(1 << 6),
  eclipse(1 << 7),
  occultation(1 << 8),
  heliacal(1 << 9),
  astrology(1 << 10),
  customTargets(1 << 11),
  customAyanamsha(1 << 12),
  customHouses(1 << 13),
  splitTime(taiyinSplitTimeCapability);

  const TaiyinCapability(this.mask);

  final int mask;
}

/// Broad category assigned to a Taiyin status code.
enum TaiyinStatusCategory {
  ok(0),
  generic(1),
  ephemeris(10),
  file(20),
  time(30),
  observer(40),
  event(50),
  runtime(60),
  unknown(999);

  const TaiyinStatusCategory(this.id);

  final int id;

  static TaiyinStatusCategory fromId(int id) {
    return values.firstWhere((value) => value.id == id, orElse: () => unknown);
  }
}

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

/// A non-success status returned by the Taiyin C ABI.
final class TaiyinException implements Exception {
  TaiyinException(this.status, this.name, this.message, {this.diagnostic});

  final int status;
  final String name;
  final String message;

  /// Native route and coverage details for a failed ephemeris calculation.
  final TaiyinEphemerisDiagnostic? diagnostic;

  @override
  String toString() => 'TaiyinException($status, $name): $message';
}

/// An initialized Taiyin runtime and an owned calculation context.
///
/// Call [close] when finished. A native finalizer is also attached as a safety
/// net for contexts that are not closed explicitly.
final class Taiyin implements Finalizable {
  Taiyin._(
    this._library,
    this._bindings,
    this._context,
    this._contextFinalizer,
  ) {
    context = TaiyinContextApi.internal(
      _bindings,
      _context,
      _ensureOpen,
      (status) => _checkStatus(_bindings, status),
    );
    time = TaiyinTime.internal(
      _bindings,
      _context,
      _ensureOpen,
      (status) => _checkStatus(_bindings, status),
    );
    position = TaiyinPositionApi.internal(
      _bindings,
      _context,
      _ensureOpen,
      (status, diagnostic) =>
          _checkStatus(_bindings, status, diagnostic: diagnostic),
    );
    _contextFinalizer.attach(this, _context.cast(), detach: this);
  }

  /// Opens Taiyin, initializes its global runtime, and creates a context.
  ///
  /// [libraryPath] takes precedence over `TAIYIN_LIBRARY_PATH`. If neither is
  /// supplied, the platform's conventional Taiyin library name is used.
  factory Taiyin.open({
    String? libraryPath,
    TaiyinRuntimeOptions options = const TaiyinRuntimeOptions(),
  }) {
    final resolvedPath =
        libraryPath ?? Platform.environment['TAIYIN_LIBRARY_PATH'];
    final library = resolvedPath == null
        ? _openDefaultLibrary()
        : DynamicLibrary.open(resolvedPath);
    return Taiyin.fromDynamicLibrary(library, options: options);
  }

  /// Uses an already-loaded native library.
  ///
  /// This is useful when an application or Flutter plugin bundles Taiyin.
  factory Taiyin.fromDynamicLibrary(
    DynamicLibrary library, {
    TaiyinRuntimeOptions options = const TaiyinRuntimeOptions(),
  }) {
    final bindings = TaiyinBindings(library);
    final abiVersion = bindings.taiyin_get_c_abi_version();
    final capabilities = bindings.taiyin_get_capabilities();
    validateTaiyinNativeCompatibility(
      abiVersion: abiVersion,
      capabilities: capabilities,
    );

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
        config.ref.lunar_limb_path = value
            .toNativeUtf8(allocator: arena)
            .cast();
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

    final context = using((arena) {
      final output = arena<Pointer<taiyin_context>>();
      _checkStatus(bindings, bindings.taiyin_context_create(output));
      return output.value;
    });

    final destroy = library
        .lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'taiyin_context_destroy',
        );
    return Taiyin._(library, bindings, context, NativeFinalizer(destroy));
  }

  final DynamicLibrary _library;
  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final NativeFinalizer _contextFinalizer;
  late final TaiyinContextApi context;
  late final TaiyinTime time;
  late final TaiyinPositionApi position;
  bool _closed = false;

  /// The Taiyin C ABI version.
  int get abiVersion => _bindings.taiyin_get_c_abi_version();

  /// The Taiyin native library's semantic version.
  String get libraryVersion =>
      _bindings.taiyin_get_library_version().cast<Utf8>().toDartString();

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

  /// The number of ephemeris descriptors in the global runtime catalog.
  int get catalogSize => _bindings.taiyin_runtime_catalog_size();

  /// Creates an independent native context without reinitializing the runtime.
  ///
  /// Immutable cloned contexts may be used for concurrent calculations.
  Taiyin clone() {
    _ensureOpen();
    final context = using((arena) {
      final output = arena<Pointer<taiyin_context>>();
      _checkStatus(_bindings, _bindings.taiyin_context_clone(_context, output));
      return output.value;
    });
    return Taiyin._(_library, _bindings, context, _contextFinalizer);
  }

  /// Calculates a position at a TT Julian date.
  TaiyinPosition positionTt(
    TaiyinBody body,
    JulianDate<TtScale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return position.atTt(body, julianDate, flags: flags).value;
  }

  /// Calculates a position at a UT Julian date.
  TaiyinPosition positionUt(
    TaiyinBody body,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return position.atUt1(body, julianDate, flags: flags).value;
  }

  /// Releases the owned native context. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    _contextFinalizer.detach(this);
    _bindings.taiyin_context_destroy(_context);
    // Keep the dynamic library strongly reachable until after destruction.
    _library;
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This Taiyin instance has been closed.');
    }
  }
}

DynamicLibrary _openDefaultLibrary() {
  if (Platform.isIOS) return DynamicLibrary.process();
  if (Platform.isWindows) return DynamicLibrary.open('taiyin.dll');
  if (Platform.isMacOS) return DynamicLibrary.open('libtaiyin.dylib');
  return DynamicLibrary.open('libtaiyin.so');
}

Never _throwStatus(
  TaiyinBindings bindings,
  int status, {
  TaiyinEphemerisDiagnostic? diagnostic,
}) {
  throw TaiyinException(
    status,
    _readNativeString(bindings.taiyin_status_name(status)),
    _readNativeString(bindings.taiyin_status_message(status)),
    diagnostic: diagnostic,
  );
}

void _checkStatus(
  TaiyinBindings bindings,
  int status, {
  TaiyinEphemerisDiagnostic? diagnostic,
}) {
  if (status != 0) {
    _throwStatus(bindings, status, diagnostic: diagnostic);
  }
}

String _readNativeString(Pointer<Char> value) {
  if (value == nullptr) return 'Unknown';
  return value.cast<Utf8>().toDartString();
}
