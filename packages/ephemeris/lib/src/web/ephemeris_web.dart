import 'dart:typed_data';
import 'dart:js_interop' show JSFunction;

import '../position/position_api.dart';
import '../backend/backend_call.dart';
import '../result_flags.dart';
import '../runtime/runtime_errors.dart';
import '../runtime/runtime_options.dart';
import '../runtime/source_bytes.dart';
import '../time/time_models.dart';
import '../time/time_api.dart';
import '../chinese_calendar/calendar_shared.dart';
import '../chinese_calendar/chinese_calendar_models.dart';
import 'calendar_web.dart';
import '../eclipse/eclipse_shared.dart';
import 'eclipse_web.dart';
import 'diagnostic_web.dart';
import '../solar_time/solar_time_shared.dart';
import 'solar_time_web.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'context_web.dart';
import 'position_web.dart';
import 'time_web.dart';
import 'wasm_module.dart';
import 'runtime_bytes_web.dart';
import 'star_catalog_web.dart';
import '../star/star_catalog_api.dart';

export 'context_web.dart';
export '../eclipse/eclipse_shared.dart';
export '../solar_time/solar_time_shared.dart';

Ephemeris? _active;

/// Experimental browser backend sharing Taiyin's C++ position pipeline.
///
/// Use [initialize], not the native-only synchronous [open]. Data sources are
/// setup-time, global to this Wasm module. Calculation contexts are independent.
final class Ephemeris {
  Ephemeris._(this._backend) {
    _byteBackend = WebRuntimeBytesBackend(_backend, _ensureCurrent);
    starCatalog = StarCatalog.internal(
      WebStarCatalogBackend(_backend, _byteBackend, _ensureCurrent),
      (call) {
        _checkCall(call);
      },
    );
    _byteLoader = RuntimeBytesLoader.internal(_byteBackend, (call) {
      _checkCall(call);
    });
  }
  final WasmBackend _backend;
  late final WebRuntimeBytesBackend _byteBackend;
  late final RuntimeBytesLoader _byteLoader;
  late final StarCatalog starCatalog;

  /// Downloads the JS module and adjacent `.wasm`, then initializes the core.
  ///
  /// [wasmModuleUri] points to the built `taiyin_web.js`. Use the same call in
  /// native applications, where this URI is ignored and [libraryPath] is used.
  /// Web does not accept native directories, file paths, or dynamic libraries.
  static Future<Ephemeris> initialize({
    String? libraryPath,
    Uri? wasmModuleUri,
    RuntimeOptions options = const RuntimeOptions(),
  }) async {
    if (libraryPath != null ||
        options.dataRoot != null ||
        options.sourcePaths.isNotEmpty ||
        options.eopPath != null ||
        options.lunarLimbPath != null) {
      throw UnsupportedError(
        'Native library/data paths cannot be used in a browser. Use addSourceBytes.',
      );
    }
    if (wasmModuleUri == null) {
      throw ArgumentError.notNull('wasmModuleUri');
    }
    final cache = options.segmentCacheMaxEntries;
    if (cache != null && (cache < 1 || cache > 0xffffffff)) {
      throw RangeError.range(cache, 1, 0xffffffff, 'segmentCacheMaxEntries');
    }
    final backend = WasmBackend(await loadWasmModule(wasmModuleUri));
    final runtime = Ephemeris._(backend);
    final reply = backend.initialize([
      options.loadPackagedData ? 1 : 0,
      options.loadBuiltinEop ? 1 : 0,
      cache ?? 0,
      options.strictDiscovery ? 1 : 0,
    ]);
    // The reset has discarded old descriptors/caches. Only now release files.
    final previous = _active;
    _active = null;
    if (previous != null) {
      previous._byteBackend.releaseAfterReset();
    }
    runtime._check(reply);
    _active = runtime;
    return runtime;
  }

  /// Synchronous dynamic-library loading is native-only.
  factory Ephemeris.open({
    String? libraryPath,
    RuntimeOptions options = const RuntimeOptions(),
  }) => throw UnsupportedError(
    'Web initialization is asynchronous. Await Ephemeris.initialize().',
  );

  /// Attaches to the already-initialized runtime in this browser application.
  factory Ephemeris.attach({String? libraryPath}) {
    if (libraryPath != null) {
      throw UnsupportedError('Web has no native library path.');
    }
    return _active ?? (throw StateError('Await Ephemeris.initialize first.'));
  }

  void _ensureCurrent() {
    if (_active != this) {
      throw StateError('This runtime facade was replaced by initialization.');
    }
  }

  /// Registers an owned OPM2/SPK/BSP/TKC1/TKE1 source, retaining its basename.
  void addSourceBytes(String name, Uint8List bytes) =>
      _byteLoader.addSourceBytes(name, bytes);

  /// Replaces the EOP table using the original finals2000A parser.
  void loadEopTableBytes(Uint8List bytes) =>
      _byteLoader.loadEopTableBytes(bytes);

  /// Replaces the TLL1 lunar-limb model using the original C++ parser.
  void loadLunarLimbModelBytes(Uint8List bytes) =>
      _byteLoader.loadLunarLimbModelBytes(bytes);

  /// Installs the core's compiled Earth-orientation table.
  void loadBuiltinEopTable() {
    _ensureCurrent();
    _check(_backend.resource(0));
  }

  /// Clears the current EOP table during setup.
  void clearEopTable() {
    _ensureCurrent();
    _check(_backend.resource(1));
  }

  bool get hasEopTable {
    _ensureCurrent();
    final reply = _backend.resource(2);
    _check(reply);
    return reply.values[1] != 0;
  }

  /// Clears the current lunar-limb model during setup.
  void clearLunarLimbModel() {
    _ensureCurrent();
    _check(_backend.resource(3));
  }

  bool get hasLunarLimbModel {
    _ensureCurrent();
    final reply = _backend.resource(4);
    _check(reply);
    return reply.values[1] != 0;
  }

  /// Creates an independent C++ calculation context in Wasm memory.
  EphemerisContext createContext() {
    final reply = _backend.createContext();
    _check(reply);
    return EphemerisContext._(this, reply.values[1].toInt());
  }

  int get abiVersion => _backend.abiVersion;
  String get libraryVersion => _backend.libraryVersion;
  String get libraryCodename => _backend.libraryCodename;

  /// Only modules actually exposed by this first Web adapter are advertised.
  int get capabilities =>
      Capability.runtime.mask |
      Capability.time.mask |
      Capability.eclipse.mask |
      Capability.chineseCalendar.mask |
      Capability.ganzhiCalendar.mask |
      Capability.position.mask |
      Capability.splitTime.mask;
  Set<Capability> get availableCapabilities => Set.unmodifiable({
    for (final c in Capability.values)
      if (hasCapability(c)) c,
  });
  bool hasCapability(Capability capability) =>
      capabilities & capability.mask != 0;

  /// Internal bridge status mapper; no packed int64 travels through JS Number.
  ResultFlags _check(
    WasmReply reply, {
    EphemerisDiagnostic? diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics = const [],
  }) {
    return _checkCall(
      BackendCall(
        status: reply.status,
        flags: ResultFlags(reply.values[0].toInt()),
        value: null,
        diagnostic: diagnostic,
        diagnostics: diagnostics,
      ),
    );
  }

  ResultFlags _checkCall(BackendCall<Object?> call) {
    final flags = call.flags;
    final status = call.status;
    if (status == 0) return flags;
    final category = StatusCategory.fromId(_backend.statusCategory(status));
    final create = switch (status) {
      -1 => InvalidArgumentError.new,
      -2 => EphemerisOutOfMemoryError.new,
      -3 => InternalCalculationError.new,
      -4 => UnsupportedOperationError.new,
      -3001 => EarthOrientationDataError.new,
      -3002 => LeapSecondDataError.new,
      _ => switch (category) {
        StatusCategory.ephemeris => EphemerisRouteError.new,
        StatusCategory.file => DataFileError.new,
        StatusCategory.time => TimeScaleError.new,
        StatusCategory.observer => ObserverError.new,
        StatusCategory.event => EventSearchError.new,
        StatusCategory.runtime => RuntimeServiceError.new,
        _ => UnknownNativeError.new,
      },
    };
    throw create(
      status,
      _backend.statusName(status),
      _backend.statusMessage(status),
      resultFlags: flags,
      diagnostic: call.diagnostic,
      diagnostics: call.diagnostics,
    );
  }
}

/// An explicitly owned browser calculation context. Close it after use.
final class EphemerisContext {
  EphemerisContext._(this._runtime, this._handle) {
    configuration = ContextConfiguration.internal(_configure, _setTdbModel);
    position = PositionApi.internal(
      WebPositionBackend(_runtime._backend, _handle),
      _ensureOpen,
      (call) {
        _completeBackendCall(call);
      },
    );
    time = Time.internal(
      WebTimeBackend(_runtime._backend, _handle),
      _ensureOpen,
      (call) {
        _completeBackendCall(call);
      },
      (error) => error is LeapSecondDataError,
      () => _tdbModel,
      _setTdbModel,
    );
    eclipses = EclipseApi.internal(
      WebEclipseBackend(_runtime._backend, _handle, (call) {
        _completeBackendCall(call);
      }),
      _ensureOpen,
    );
  }
  final Ephemeris _runtime;
  final int _handle;
  late final ContextConfiguration configuration;
  late final PositionApi position;
  late final Time time;
  late final EclipseApi eclipses;
  late final SolarTimeApi solarTime = SolarTimeApi.internal(
    WebSolarTimeBackend(_runtime._backend, _handle, (call) {
      _completeBackendCall(call);
    }),
    _ensureOpen,
  );
  final Set<ChineseCalendarContext> _calendarChildren = {};
  ChineseCalendarContext? _chineseCalendar;
  ChineseCalendarContext get chineseCalendar {
    final cached = _chineseCalendar;
    if (cached != null && !cached.isClosed) return cached;
    return _chineseCalendar = createChineseCalendar();
  }

  ChineseCalendarContext createChineseCalendar({
    ChineseCalendarConfig config = const ChineseCalendarConfig(),
  }) {
    _ensureOpen();
    final offset = config.utcOffsetMinutes;
    if (offset < -840 || offset > 840) {
      throw RangeError.range(offset, -840, 840, 'utcOffsetMinutes');
    }
    final reply = _runtime._backend.createCalendar(_handle, [
      config.mode.id,
      config.dayBoundaryMode.id,
      offset,
      config.calendarMeridianDegrees,
    ]);
    _complete(reply);
    final backend = WebChineseCalendarBackend(
      _runtime._backend,
      reply.values[1].toInt(),
      () {
        _ensureOpen();
      },
      (call) {
        _completeBackendCall(call);
      },
    );
    final calendar = ChineseCalendarContext._(backend, this, config);
    _calendarChildren.add(calendar);
    return calendar;
  }

  bool _closed = false;
  TdbModel _tdbModel = TdbModel.fastPeriodic;
  EphemerisDiagnostic? _lastDiagnostic;
  ResultFlags _lastResultFlags = ResultFlags.none;
  EphemerisDiagnostic? get lastDiagnostic => _lastDiagnostic;
  ResultFlags get lastResultFlags => _lastResultFlags;

  void _ensureOpen() {
    if (_closed) throw StateError('This EphemerisContext has been closed.');
  }

  void _setTdbModel(TdbModel model) => _tdbModel = model;
  TaiyinExtensionHost get extensionHost => TaiyinExtensionHost.internal(
    _ensureOpen,
    backend: _runtime._backend,
    complete: (call) {
      _completeBackendCall(call);
    },
  );

  void _configure(int operation, List<num> values) {
    _ensureOpen();
    _complete(_runtime._backend.configure(_handle, operation, values));
  }

  ResultFlags _complete(
    WasmReply reply, {
    EphemerisDiagnostic? diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics = const [],
  }) {
    return _completeBackendCall(
      BackendCall(
        status: reply.status,
        flags: ResultFlags(reply.values[0].toInt()),
        value: reply.values,
        diagnostic: diagnostic,
        diagnostics: diagnostics,
      ),
    );
  }

  ResultFlags _completeBackendCall(BackendCall<Object?> call) {
    if (call.diagnostic != null) _lastDiagnostic = call.diagnostic;
    _lastResultFlags = call.flags;
    return _runtime._checkCall(call);
  }

  EphemerisContext clone() {
    _ensureOpen();
    final reply = _runtime._backend.cloneContext(_handle);
    _complete(reply);
    return EphemerisContext._(_runtime, reply.values[1].toInt())
      .._tdbModel = _tdbModel;
  }

  OperationResult<Position> positionTt(
    Target body,
    JulianDate<TtScale> jd, {
    Set<PositionFlag> flags = const {},
  }) => position.atTt(body, jd, flags: flags);
  OperationResult<Position> positionUt(
    Target body,
    JulianDate<Ut1Scale> jd, {
    Set<PositionFlag> flags = const {},
  }) => position.atUt1(body, jd, flags: flags);
  void close() {
    if (_closed) return;
    for (final calendar in _calendarChildren.toList()) {
      calendar.close();
    }
    _closed = true;
    _runtime._backend.destroyContext(_handle);
  }
}

/// Opaque extension host; Web does not expose FFI pointers or native libraries.
final class TaiyinExtensionHost {
  TaiyinExtensionHost.internal(
    this._ensureOpen, {
    required WasmBackend backend,
    int calendarHandle = 0,
    required BackendCallCompletion complete,
  }) : _backend = backend,
       _calendarHandle = calendarHandle,
       _complete = complete;
  factory TaiyinExtensionHost.open({String? libraryPath}) {
    if (libraryPath != null) {
      throw UnsupportedError('Web has no native library path.');
    }
    final runtime = Ephemeris.attach();
    return TaiyinExtensionHost.internal(
      () {},
      backend: runtime._backend,
      complete: (call) {
        runtime._checkCall(call);
      },
    );
  }
  final WasmBackend _backend;
  final int _calendarHandle;
  final BackendCallCompletion _complete;
  final void Function() _ensureOpen;
  void ensureOpen() => _ensureOpen();

  /// Internal official-extension transport. No memory view escapes the call.
  WasmReply callBazi(
    int context,
    int operation,
    List<num> input, {
    bool check = true,
  }) {
    if (operation == 0 || operation == 15 || operation == 17) ensureOpen();
    final reply = _backend.bazi(context, _calendarHandle, operation, input);
    if (check) {
      checkExtensionReply(
        reply,
        diagnostic: operation == 15 || operation == 17,
      );
    }
    return reply;
  }

  void checkExtensionReply(WasmReply reply, {bool diagnostic = false}) =>
      _complete(
        BackendCall<Object?>(
          status: reply.status,
          flags: ResultFlags(reply.values[0].toInt()),
          value: null,
          diagnostic: diagnostic ? readWebDiagnostic(reply.values) : null,
        ),
      );
  void destroyBazi(int context) => _backend.destroyBazi(context);

  /// Official Ziwei adapter: handles stay opaque and results are copied.
  WasmReply callZiwei(
    int context,
    int chart,
    int operation,
    List<num> input, {
    bool diagnostic = false,
    bool check = true,
  }) {
    final reply = _backend.ziwei(
      context,
      chart,
      _calendarHandle,
      operation,
      input,
    );
    if (check) checkExtensionReply(reply, diagnostic: diagnostic);
    return reply;
  }

  void installBaziPredicate(JSFunction callback) {
    _backend.module.taiyinBaziPredicate = callback;
  }
}

/// The same calendar facade as native, with browser-owned transport resources.
final class ChineseCalendarContext extends CalendarContextBase {
  ChineseCalendarContext._(
    this._webBackend,
    this.owner,
    ChineseCalendarConfig config,
  ) : super.internal(_webBackend, owner.time, config, owner._ensureOpen, (
        call,
      ) {
        owner._completeBackendCall(call);
      });
  final WebChineseCalendarBackend _webBackend;
  final EphemerisContext owner;
  TaiyinExtensionHost get extensionHost => _webBackend.extensionHost;
  @override
  void close() {
    owner._calendarChildren.remove(this);
    super.close();
  }
}
