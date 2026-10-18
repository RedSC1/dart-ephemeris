import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings/taiyin_bindings.g.dart';
import 'astrology/astrology_models.dart';
import 'chinese_calendar/chinese_calendar_models.dart';
import 'chinese_calendar/calendar_shared.dart';
import 'backend/calendar_backend.dart';
import 'context/context_models.dart';
import 'ganzhi/ganzhi_models.dart';
import 'eclipse/lunar_eclipse_models.dart';
import 'eclipse/eclipse_shared.dart';
import 'backend/eclipse_backend.dart';
export 'eclipse/eclipse_shared.dart';
import 'eclipse/solar_eclipse_models.dart';
import 'events/event_models.dart';
import 'heliacal/heliacal_models.dart';
import 'interop/calendar.dart';
import 'interop/call_result.dart';
import 'interop/julian_date.dart';
import 'interop/native_validation.dart';
import 'native_compatibility.dart';
import 'observed/observed_models.dart';
import 'occultation/occultation_models.dart';
import 'orbital/orbital_models.dart';
import 'phenomena/phenomena_models.dart';
import 'position/position_api.dart';
import 'position/position_native.dart';
import 'backend/backend_call.dart';
import 'runtime/runtime_models.dart';
import 'runtime/runtime_options.dart';
import 'runtime/runtime_errors.dart';
import 'runtime/source_bytes.dart';
import 'result_flags.dart';
import 'solar_time/solar_time_models.dart';
import 'solar_time/solar_time_shared.dart';
import 'backend/solar_time_backend.dart';
export 'solar_time/solar_time_shared.dart';
import 'star/star_models.dart';
import 'star/star_catalog_api.dart';
import 'backend/star_catalog_backend.dart';
import 'time/astro_date_time.dart';
import 'time/julian_date.dart';
import 'time/time_api.dart';
import 'time/time_backend_native.dart';
import 'time/time_models.dart';
import 'time/time_scale.dart';
import 'visibility/visibility_models.dart';

export 'runtime/runtime_errors.dart';
export 'runtime/runtime_options.dart';
export 'star/star_catalog_api.dart';

part 'chinese_calendar/chinese_calendar_api.dart';
part 'context/context_api.dart';
part 'eclipse/eclipse_api.dart';
part 'extension_host.dart';
part 'ganzhi/ganzhi_api.dart';
part 'events/event_api.dart';
part 'occultation/occultation_api.dart';
part 'heliacal/heliacal_api.dart';
part 'astrology/astrology_api.dart';
part 'astrology/custom_model_api.dart';
part 'observed/observed_api.dart';
part 'orbital/orbital_api.dart';
part 'phenomena/phenomena_api.dart';
part 'position/custom_target_api.dart';
part 'runtime/runtime_api.dart';
part 'runtime/runtime_bytes_native.dart';
part 'solar_time/solar_time_api.dart';
part 'star/star_api.dart';
part 'star/star_catalog_native.dart';
part 'visibility/visibility_api.dart';

/// One user-owned Ephemeris calculation context.
///
/// Call [close] when finished. A native finalizer is also attached as a safety
/// net for contexts that are not closed explicitly.
///
/// This object does not own or reconfigure the process-wide [Ephemeris] runtime.
/// Create it through [Ephemeris.createContext]. Worker isolates first obtain a
/// local runtime facade with [Ephemeris.attach], then create their own context
/// through the same method.
final class EphemerisContext implements Finalizable {
  EphemerisContext._(
    this._library,
    this._bindings,
    this._context,
    this._contextFinalizer,
    this._nativeState, [
    TdbModel initialTdbModel = TdbModel.fastPeriodic,
  ]) : _configuredTdbModel = initialTdbModel {
    var finalizerAttached = false;
    try {
      _contextFinalizer.attach(this, _context.cast(), detach: this);
      finalizerAttached = true;
      time = Time.internal(
        NativeTimeBackend(_bindings, _context),
        _ensureOpen,
        (call) {
          _completeBackendCall(call);
        },
        (error) => error is LeapSecondDataError,
        () => _configuredTdbModel,
        (model) => _configuredTdbModel = model,
      );
      configuration = ContextConfiguration._(
        _bindings,
        _context,
        _ensureOpen,
        (status) => _completeOperation(status),
        (model) => _configuredTdbModel = model,
      );
      astrology = AstrologyApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
      position = PositionApi.internal(
        NativePositionBackend(_bindings, _context),
        _ensureOpen,
        (call) {
          _completeBackendCall(call);
        },
      );
      observed = ObservedApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
        diagnostics,
      ) {
        return _completeOperation(
          status,
          diagnostic: diagnostic,
          diagnostics: diagnostics,
        );
      });
      orbits = OrbitalApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
      phenomena = PhenomenaApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
      solarTime = SolarTimeApi.internal(
        _NativeSolarTimeBackend(_bindings, _context, _ensureOpen, (
          status,
          diagnostic,
        ) {
          return _completeOperation(status, diagnostic: diagnostic);
        }),
        _ensureOpen,
      );
      visibility = VisibilityApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
      heliacal = HeliacalApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
      events = EventsApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
      eclipses = EclipseApi.internal(
        _NativeEclipseBackend(_bindings, _context, _ensureOpen, (
          status,
          diagnostic,
        ) {
          return _completeOperation(status, diagnostic: diagnostic);
        }),
        _ensureOpen,
      );
      occultation = OccultationApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
      stars = StarApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
        diagnostics,
      ) {
        return _completeOperation(
          status,
          diagnostic: diagnostic,
          diagnostics: diagnostics,
        );
      }, observed);
      ganzhi = GanzhiApi._(_bindings, _nativeState.capabilities);
    } catch (_) {
      if (finalizerAttached) {
        _contextFinalizer.detach(this);
      }
      _bindings.taiyin_context_destroy(_context);
      rethrow;
    }
  }

  factory EphemerisContext._create(
    DynamicLibrary library,
    _NativeLibraryState nativeState,
  ) {
    final context = using((arena) {
      final output = arena<Pointer<taiyin_context>>();
      _checkStatus(
        nativeState.bindings,
        nativeState.bindings.taiyin_context_create(output),
      );
      return output.value;
    });
    return EphemerisContext._(
      library,
      nativeState.bindings,
      context,
      nativeState.contextFinalizer,
      nativeState,
    );
  }

  final DynamicLibrary _library;
  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final NativeFinalizer _contextFinalizer;
  final _NativeLibraryState _nativeState;
  late final ContextConfiguration configuration;
  late final Time time;
  late final AstrologyApi astrology;
  late final PositionApi position;
  late final ObservedApi observed;
  late final OrbitalApi orbits;
  late final PhenomenaApi phenomena;
  late final SolarTimeApi solarTime;
  late final VisibilityApi visibility;
  late final HeliacalApi heliacal;
  late final EventsApi events;
  late final EclipseApi eclipses;
  late final OccultationApi occultation;
  late final StarApi stars;
  late final GanzhiApi ganzhi;
  ChineseCalendarContext? _chineseCalendar;
  EphemerisDiagnostic? _lastDiagnostic;
  ResultFlags _lastResultFlags = ResultFlags.none;

  /// The diagnostic snapshot published by the most recent operation that
  /// produced one, or null when no such operation has run yet.
  ///
  /// Diagnostics describe the route a calculation took (method, frame, and
  /// time-scale conversions); failures also publish their diagnostic here
  /// before throwing.
  EphemerisDiagnostic? get lastDiagnostic => _lastDiagnostic;

  /// Execution facts reported by the most recently completed native call.
  ///
  /// Prefer the `flags` field returned with an [OperationResult]. This
  /// snapshot exists for diagnostics and for mutating APIs that return no
  /// value; it is not a substitute for the call-scoped record.
  ResultFlags get lastResultFlags => _lastResultFlags;

  void _recordDiagnostic(EphemerisDiagnostic diagnostic) {
    _lastDiagnostic = diagnostic;
  }

  ResultFlags _completeOperation(
    int rawResult, {
    EphemerisDiagnostic? diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics = const [],
  }) {
    final decoded = decodeNativeCallResult(rawResult);
    return _completeDecoded(
      decoded.status,
      decoded.flags,
      diagnostic: diagnostic,
      diagnostics: diagnostics,
    );
  }

  ResultFlags _completeBackendCall(BackendCall<Object?> call) =>
      _completeDecoded(
        call.status,
        call.flags,
        diagnostic: call.diagnostic,
        diagnostics: call.diagnostics,
      );

  ResultFlags _completeDecoded(
    int status,
    ResultFlags flags, {
    EphemerisDiagnostic? diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics = const [],
  }) {
    if (diagnostic != null) _recordDiagnostic(diagnostic);
    _lastResultFlags = flags;
    if (status != 0) {
      _throwStatus(
        _bindings,
        status,
        resultFlags: flags,
        diagnostic: diagnostic,
        diagnostics: diagnostics,
      );
    }
    return flags;
  }

  /// Every calendar context created from this context, tracked so closing the
  /// owner invalidates caller-created children that borrow its native state.
  final Set<ChineseCalendarContext> _calendarChildren = {};
  TdbModel _configuredTdbModel;
  bool _closed = false;

  /// Creates an independent native context without reinitializing the runtime.
  ///
  /// Immutable cloned contexts may be used for concurrent calculations.
  EphemerisContext clone() {
    _ensureOpen();
    final context = using((arena) {
      final output = arena<Pointer<taiyin_context>>();
      _completeOperation(_bindings.taiyin_context_clone(_context, output));
      return output.value;
    });
    return EphemerisContext._(
      _library,
      _bindings,
      context,
      _contextFinalizer,
      _nativeState,
      time.configuredTdbModel,
    );
  }

  /// A Chinese-calendar context using the default astronomical configuration.
  ///
  /// The first access creates and caches the native context; [close] releases
  /// it together with the owning context. A cache entry closed by the caller
  /// is replaced on the next access.
  ChineseCalendarContext get chineseCalendar {
    final cached = _chineseCalendar;
    if (cached != null && !cached.isClosed) return cached;
    return _chineseCalendar = createChineseCalendar();
  }

  /// Creates an independent Chinese-calendar context owned by the caller.
  ///
  /// Call [ChineseCalendarContext.close] when it is no longer needed.
  ChineseCalendarContext createChineseCalendar({
    ChineseCalendarConfig config = const ChineseCalendarConfig(),
  }) {
    _ensureOpen();
    final backend = _NativeChineseCalendarBackend._create(
      _nativeState,
      _bindings,
      _context,
      config,
      this,
    );
    final child = ChineseCalendarContext._(backend, this, config);
    _calendarChildren.add(child);
    return child;
  }

  /// FFI handle for the official extension packages (for example
  /// `package:ephemeris_bazi` and `package:ephemeris_ziwei`).
  TaiyinExtensionHost get extensionHost => TaiyinExtensionHost._(
    _nativeState,
    _context.cast(),
    _ensureOpen,
    _recordDiagnostic,
    _completeOperation,
  );

  /// Calculates a position at a TT Julian date.
  OperationResult<Position> positionTt(
    Target body,
    JulianDate<TtScale> julianDate, {
    Set<PositionFlag> flags = const {},
  }) {
    return position.atTt(body, julianDate, flags: flags);
  }

  /// Calculates a position at a UT Julian date.
  OperationResult<Position> positionUt(
    Target body,
    JulianDate<Ut1Scale> julianDate, {
    Set<PositionFlag> flags = const {},
  }) {
    return position.atUt1(body, julianDate, flags: flags);
  }

  /// Releases the owned native context. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    for (final child in List.of(_calendarChildren)) {
      child.close();
    }
    _calendarChildren.clear();
    _contextFinalizer.detach(this);
    _bindings.taiyin_context_destroy(_context);
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This EphemerisContext has been closed.');
    }
  }
}

final class _NativeLibraryState {
  _NativeLibraryState(
    this.bindings,
    this.contextFinalizer,
    this.chineseCalendarFinalizer,
    this.capabilities,
  );

  final TaiyinBindings bindings;
  final NativeFinalizer contextFinalizer;
  final NativeFinalizer chineseCalendarFinalizer;
  final int capabilities;
  Directory? byteSourceDirectory;
  final Set<String> byteSources = {};
  int byteSourceSequence = 0;

  void clearByteSourcesAfterRuntimeReset() {
    final directory = byteSourceDirectory;
    // A caller can re-register a reported source path in RuntimeOptions. Do
    // not remove files that the new catalog still references after its reset.
    if (directory != null && _catalogReferences(directory.path)) return;
    byteSourceDirectory = null;
    byteSources.clear();
    // Only remove the unique directory created by addSourceBytes, after the
    // native runtime has dropped the catalog/cache that referred to its files.
    if (directory != null) {
      try {
        directory.deleteSync(recursive: true);
      } on FileSystemException {
        // Best-effort cleanup must not mask the runtime initialization result.
      }
    }
  }

  bool _catalogReferences(String directory) {
    String normalized(String value) {
      final path = value.replaceAll('\\', '/');
      return Platform.isWindows ? path.toLowerCase() : path;
    }

    final prefix = '${normalized(directory)}/';
    return using((arena) {
      final count = bindings.taiyin_runtime_registered_data_source_count();
      for (var i = 0; i < count; ++i) {
        final info = arena<taiyin_runtime_registered_data_source>();
        final size = arena<Size>();
        bindings.taiyin_runtime_registered_data_source_init(info);
        var result = bindings.taiyin_runtime_get_registered_data_source(
          i,
          info,
          nullptr,
          0,
          size,
        );
        if (result < 0 || size.value == 0) {
          return true; // Conservatively retain on query failure.
        }
        final path = arena<Char>(size.value);
        result = bindings.taiyin_runtime_get_registered_data_source(
          i,
          info,
          path,
          size.value,
          size,
        );
        if (result < 0) return true;
        if (normalized(_readNativeString(path)).startsWith(prefix)) {
          return true;
        }
      }
      return false;
    });
  }

  final Map<int, CustomTargetRegistration> customTargetRegistrations = {};
  final Map<int, CustomAyanamshaRegistration> customAyanamshaRegistrations = {};
  final Map<int, CustomHouseSystemRegistration> customHouseSystemRegistrations =
      {};
}

// NativeFinalizer itself must stay reachable until its attachments have run.
// Keying by the destroy symbol also reuses bindings when the same native module
// is opened through more than one DynamicLibrary wrapper in this isolate.
final Map<int, _NativeLibraryState> _nativeLibraryStates = {};

DynamicLibrary _openLibrary(String? libraryPath) {
  final resolvedPath =
      libraryPath ?? Platform.environment['TAIYIN_LIBRARY_PATH'];
  return resolvedPath == null
      ? _openDefaultLibrary()
      : DynamicLibrary.open(resolvedPath);
}

DynamicLibrary _openDefaultLibrary() {
  if (Platform.isIOS) return DynamicLibrary.process();
  final bundled = _bundledLibraryPath();
  if (bundled != null) return DynamicLibrary.open(bundled);
  // Modular builds expose a stable versionless file name; ABI compatibility is
  // checked immediately after loading rather than encoded in the file name.
  if (Platform.isWindows) return DynamicLibrary.open('taiyin.dll');
  if (Platform.isMacOS) return DynamicLibrary.open('libtaiyin.dylib');
  return DynamicLibrary.open('libtaiyin.so');
}

/// The shared library bundled inside the package, when it ships one for this
/// platform.
String? _bundledLibraryPath() {
  // The bundled release baseline currently covers macOS arm64, Linux x64,
  // and Windows x64. Other architectures fall through to the platform loader
  // so applications can provide a compatible native build themselves.
  if (!_supportsBundledNativeAbi()) return null;
  final fileName = Platform.isWindows
      ? 'taiyin.dll'
      : Platform.isMacOS
      ? 'libtaiyin.dylib'
      : 'libtaiyin.so';
  final resolved = Isolate.resolvePackageUriSync(
    Uri.parse('package:ephemeris/native/$fileName'),
  );
  if (resolved == null || resolved.scheme != 'file') return null;
  final path = resolved.toFilePath();
  if (!File(path).existsSync()) return null;
  if (Platform.isWindows) _preloadBundledWindowsRuntimes(File(path).parent);
  return path;
}

/// The lite fixed-star catalog bundled as a package resource.
String? _bundledLiteStarCatalogPath() {
  final resolved = Isolate.resolvePackageUriSync(
    Uri.parse(
      'package:ephemeris/data/stars/catalogs/lite/stars-bright-v5.tsc1',
    ),
  );
  if (resolved == null || resolved.scheme != 'file') return null;
  final path = resolved.toFilePath();
  return File(path).existsSync() ? path : null;
}

bool _supportsBundledNativeAbi() {
  final abi = Abi.current();
  if (Platform.isMacOS) return abi == Abi.macosArm64;
  if (Platform.isLinux) return abi == Abi.linuxX64;
  if (Platform.isWindows) return abi == Abi.windowsX64;
  return false;
}

// Loading a DLL by absolute path does not add its directory to the Windows DLL
// search path. Keep the MinGW-w64 dependencies loaded explicitly so taiyin.dll
// and the optional extension DLLs can resolve them on machines without GCC.
final List<DynamicLibrary> _bundledWindowsRuntimes = [];

void _preloadBundledWindowsRuntimes(Directory nativeDirectory) {
  if (_bundledWindowsRuntimes.isNotEmpty) return;
  for (final fileName in const [
    'libwinpthread-1.dll',
    'libgcc_s_seh-1.dll',
    'libstdc++-6.dll',
  ]) {
    final file = File.fromUri(nativeDirectory.uri.resolve(fileName));
    _bundledWindowsRuntimes.add(DynamicLibrary.open(file.path));
  }
}

_NativeLibraryState _nativeLibraryStateFor(DynamicLibrary library) {
  final destroy = library.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
    'taiyin_context_destroy',
  );
  return _nativeLibraryStates.putIfAbsent(destroy.address, () {
    final bindings = TaiyinBindings(library);
    final capabilities = bindings.taiyin_get_capabilities();
    validateTaiyinNativeCompatibility(
      abiVersion: bindings.taiyin_get_c_abi_version(),
      capabilities: capabilities,
    );
    validateTaiyinRequiredSymbols(providesSymbol: library.providesSymbol);
    return _NativeLibraryState(
      bindings,
      NativeFinalizer(destroy),
      NativeFinalizer(
        library.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'taiyin_chinese_calendar_context_destroy',
        ),
      ),
      capabilities,
    );
  });
}

Never _throwStatus(
  TaiyinBindings bindings,
  int status, {
  ResultFlags resultFlags = ResultFlags.none,
  EphemerisDiagnostic? diagnostic,
  Iterable<EphemerisDiagnostic> diagnostics = const [],
}) {
  final name = _readNativeString(bindings.taiyin_status_name(status));
  final message = _readNativeString(bindings.taiyin_status_message(status));
  final category = StatusCategory.fromId(
    bindings.taiyin_status_category_of(status),
  );
  final arguments = (
    status: status,
    name: name,
    message: message,
    resultFlags: resultFlags,
    diagnostic: diagnostic,
    diagnostics: diagnostics,
  );
  if (status == -1) {
    throw InvalidArgumentError(
      arguments.status,
      arguments.name,
      arguments.message,
      resultFlags: arguments.resultFlags,
      diagnostic: arguments.diagnostic,
      diagnostics: arguments.diagnostics,
    );
  }
  if (status == -2) {
    throw EphemerisOutOfMemoryError(
      arguments.status,
      arguments.name,
      arguments.message,
      resultFlags: arguments.resultFlags,
      diagnostic: arguments.diagnostic,
      diagnostics: arguments.diagnostics,
    );
  }
  if (status == -3) {
    throw InternalCalculationError(
      arguments.status,
      arguments.name,
      arguments.message,
      resultFlags: arguments.resultFlags,
      diagnostic: arguments.diagnostic,
      diagnostics: arguments.diagnostics,
    );
  }
  if (status == -4) {
    throw UnsupportedOperationError(
      arguments.status,
      arguments.name,
      arguments.message,
      resultFlags: arguments.resultFlags,
      diagnostic: arguments.diagnostic,
      diagnostics: arguments.diagnostics,
    );
  }
  if (status == taiyin_status_code.TAIYIN_TIME_ERROR_EOP_OUT_OF_RANGE) {
    throw EarthOrientationDataError(
      arguments.status,
      arguments.name,
      arguments.message,
      resultFlags: arguments.resultFlags,
      diagnostic: arguments.diagnostic,
      diagnostics: arguments.diagnostics,
    );
  }
  if (status == taiyin_status_code.TAIYIN_TIME_ERROR_LEAP_SECOND_UNAVAILABLE) {
    throw LeapSecondDataError(
      arguments.status,
      arguments.name,
      arguments.message,
      resultFlags: arguments.resultFlags,
      diagnostic: arguments.diagnostic,
      diagnostics: arguments.diagnostics,
    );
  }
  final error = switch (category) {
    StatusCategory.ephemeris => EphemerisRouteError.new,
    StatusCategory.file => DataFileError.new,
    StatusCategory.time => TimeScaleError.new,
    StatusCategory.observer => ObserverError.new,
    StatusCategory.event => EventSearchError.new,
    StatusCategory.runtime => RuntimeServiceError.new,
    _ => UnknownNativeError.new,
  };
  throw error(
    arguments.status,
    arguments.name,
    arguments.message,
    resultFlags: arguments.resultFlags,
    diagnostic: arguments.diagnostic,
    diagnostics: arguments.diagnostics,
  );
}

ResultFlags _checkStatus(
  TaiyinBindings bindings,
  int rawResult, {
  EphemerisDiagnostic? diagnostic,
  Iterable<EphemerisDiagnostic> diagnostics = const [],
}) {
  final decoded = decodeNativeCallResult(rawResult);
  final status = decoded.status;
  if (status != 0) {
    _throwStatus(
      bindings,
      status,
      resultFlags: decoded.flags,
      diagnostic: diagnostic,
      diagnostics: diagnostics,
    );
  }
  return decoded.flags;
}

String _readNativeString(Pointer<Char> value) {
  if (value == nullptr) return 'Unknown';
  return value.cast<Utf8>().toDartString();
}

void _writeEphemerisDiagnostic(
  Pointer<taiyin_ephemeris_diagnostic> output,
  EphemerisDiagnostic value,
) {
  for (final field in [
    (value: value.status, name: 'status'),
    (value: value.targetId, name: 'targetId'),
    (value: value.centerId, name: 'centerId'),
    (value: value.rawFrameId, name: 'rawFrameId'),
    (value: value.candidateCount, name: 'candidateCount'),
    (value: value.attemptedMethodId, name: 'attemptedMethodId'),
    (value: value.componentTargetId, name: 'componentTargetId'),
    (value: value.componentCenterId, name: 'componentCenterId'),
    (value: value.componentMethodId, name: 'componentMethodId'),
  ]) {
    validateNativeInt32(field.value, field.name);
  }
  validateNativeUint8(value.rawTimeScaleRouteId, 'rawTimeScaleRouteId');
  validateNativeUint8(
    value.rawTimeScaleFallbackReasonId,
    'rawTimeScaleFallbackReasonId',
  );
  validateNativeJulianDate(value.julianDateTdb);
  output.ref
    ..struct_size = sizeOf<taiyin_ephemeris_diagnostic>()
    ..status = value.status
    ..target_id = value.targetId
    ..center_id = value.centerId
    ..frame = value.rawFrameId
    ..jd_tdb.day_number = value.julianDateTdb.dayNumber
    ..jd_tdb.day_fraction = value.julianDateTdb.dayFraction
    ..candidate_count = value.candidateCount
    ..attempted_method_id = value.attemptedMethodId
    ..nearest_coverage_start = value.nearestCoverageStart
    ..nearest_coverage_end = value.nearestCoverageEnd
    ..component_target_id = value.componentTargetId
    ..component_center_id = value.componentCenterId
    ..component_method_id = value.componentMethodId
    ..time_scale_route = value.rawTimeScaleRouteId
    ..time_scale_fallback_reason = value.rawTimeScaleFallbackReasonId
    ..time_scale_flags = value.timeScaleFlags.fold(
      0,
      (mask, flag) => mask | flag.mask,
    )
    ..reserved0 = 0
    ..tai_minus_utc_seconds = value.taiMinusUtcSeconds
    ..dut1_seconds = value.dut1Seconds
    ..delta_t_seconds = value.deltaTSeconds;
}

EphemerisDiagnostic _readEphemerisDiagnostic(
  taiyin_ephemeris_diagnostic value,
) {
  final timeScaleFlags = {
    for (final flag in TimeScaleDiagnosticFlag.values)
      if ((value.time_scale_flags & flag.mask) != 0) flag,
  };
  return EphemerisDiagnostic(
    status: value.status,
    targetId: value.target_id,
    centerId: value.center_id,
    frame: ApparentFrame.fromId(value.frame),
    rawFrameId: value.frame,
    julianDateTdb: readJulianDate<TdbScale>(value.jd_tdb),
    candidateCount: value.candidate_count,
    attemptedMethodId: value.attempted_method_id,
    nearestCoverageStart: value.nearest_coverage_start,
    nearestCoverageEnd: value.nearest_coverage_end,
    componentTargetId: value.component_target_id,
    componentCenterId: value.component_center_id,
    componentMethodId: value.component_method_id,
    timeScaleRoute: TimeScaleRoute.fromId(value.time_scale_route),
    rawTimeScaleRouteId: value.time_scale_route,
    timeScaleFallbackReason: TimeScaleFallbackReason.fromId(
      value.time_scale_fallback_reason,
    ),
    rawTimeScaleFallbackReasonId: value.time_scale_fallback_reason,
    timeScaleFlags: timeScaleFlags,
    taiMinusUtcSeconds: value.tai_minus_utc_seconds,
    dut1Seconds: value.dut1_seconds,
    deltaTSeconds: value.delta_t_seconds,
  );
}
