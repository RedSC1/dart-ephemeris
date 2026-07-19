import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'bindings/taiyin_bindings.g.dart';
import 'time/julian_date.dart';
import 'time/time_scale.dart';

const int _supportedAbiVersion = 1;

/// A solar-system body understood by Taiyin.
enum TaiyinBody {
  solarSystemBarycenter(0),
  mercuryBarycenter(1),
  venusBarycenter(2),
  earthMoonBarycenter(3),
  marsBarycenter(4),
  jupiterBarycenter(5),
  saturnBarycenter(6),
  uranusBarycenter(7),
  neptuneBarycenter(8),
  plutoBarycenter(9),
  sun(10),
  mercury(199),
  venus(299),
  moon(301),
  earth(399),
  mars(499),
  jupiter(599),
  saturn(699),
  uranus(799),
  neptune(899),
  pluto(999);

  const TaiyinBody(this.id);

  /// The stable body ID from the Taiyin C ABI.
  final int id;
}

/// Modifiers for a position calculation.
enum TaiyinPositionFlag {
  speed(1 << 0),
  xyz(1 << 1),
  equatorial(1 << 2),
  radians(1 << 3),
  truePosition(1 << 4),
  noAberration(1 << 5),
  noGravitationalDeflection(1 << 6),
  astrometric(1 << 7),
  noNutation(1 << 8),
  topocentric(1 << 9),
  allowBarycenterApproximation(1 << 10);

  const TaiyinPositionFlag(this.mask);

  /// The bit used by the Taiyin C ABI.
  final int mask;
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

/// The six values returned by a Taiyin position calculation.
///
/// Values 0–2 are the primary coordinates. Values 3–5 are their rates when
/// [TaiyinPositionFlag.speed] is requested. Their coordinate system and units
/// are described by [flags].
final class TaiyinPosition {
  TaiyinPosition._(List<double> values, this.flags)
    : values = List.unmodifiable(values);

  final List<double> values;
  final Set<TaiyinPositionFlag> flags;

  List<double> get coordinates => values.sublist(0, 3);
  List<double> get rates => values.sublist(3, 6);
  bool get isCartesian => flags.contains(TaiyinPositionFlag.xyz);
  bool get isEquatorial => flags.contains(TaiyinPositionFlag.equatorial);
  bool get isRadians => flags.contains(TaiyinPositionFlag.radians);

  @override
  String toString() => 'TaiyinPosition($values)';
}

/// A non-success status returned by the Taiyin C ABI.
final class TaiyinException implements Exception {
  const TaiyinException(this.status, this.name, this.message);

  final int status;
  final String name;
  final String message;

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
    if (abiVersion != _supportedAbiVersion) {
      throw StateError(
        'Unsupported Taiyin C ABI $abiVersion; '
        'this package supports ABI $_supportedAbiVersion.',
      );
    }

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
  bool _closed = false;

  /// The Taiyin C ABI version.
  int get abiVersion => _bindings.taiyin_get_c_abi_version();

  /// The Taiyin native library's semantic version.
  String get libraryVersion =>
      _bindings.taiyin_get_library_version().cast<Utf8>().toDartString();

  /// The native module capability bitset.
  int get capabilities => _bindings.taiyin_get_capabilities();

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
    return _position(
      flags,
      (mask, output) => _bindings.taiyin_calc_position_tt(
        _context,
        body.id,
        julianDate.toDouble(),
        mask,
        output,
        nullptr,
      ),
    );
  }

  /// Calculates a position at a UT Julian date.
  TaiyinPosition positionUt(
    TaiyinBody body,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _position(
      flags,
      (mask, output) => _bindings.taiyin_calc_position_ut(
        _context,
        body.id,
        julianDate.toDouble(),
        mask,
        output,
        nullptr,
      ),
    );
  }

  TaiyinPosition _position(
    Set<TaiyinPositionFlag> flags,
    int Function(int mask, Pointer<Double> output) calculate,
  ) {
    _ensureOpen();
    final frozenFlags = Set<TaiyinPositionFlag>.unmodifiable(flags);
    final mask = frozenFlags.fold(0, (value, flag) => value | flag.mask);
    return using((arena) {
      final output = arena<Double>(6);
      _checkStatus(_bindings, calculate(mask, output));
      return TaiyinPosition._([
        for (var index = 0; index < 6; index++) output[index],
      ], frozenFlags);
    });
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

Never _throwStatus(TaiyinBindings bindings, int status) {
  String read(Pointer<Char> value) {
    if (value == nullptr) return 'Unknown';
    return value.cast<Utf8>().toDartString();
  }

  throw TaiyinException(
    status,
    read(bindings.taiyin_status_name(status)),
    read(bindings.taiyin_status_message(status)),
  );
}

void _checkStatus(TaiyinBindings bindings, int status) {
  if (status != 0) _throwStatus(bindings, status);
}
