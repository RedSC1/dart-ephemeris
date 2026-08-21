import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings/taiyin_bindings.g.dart';
import 'astrology/astrology_models.dart';
import 'chinese_calendar/chinese_calendar_models.dart';
import 'context/context_models.dart';
import 'ganzhi/ganzhi_models.dart';
import 'eclipse/lunar_eclipse_models.dart';
import 'eclipse/solar_eclipse_models.dart';
import 'events/event_models.dart';
import 'heliacal/heliacal_models.dart';
import 'interop/calendar.dart';
import 'interop/call_result.dart';
import 'interop/julian_date.dart';
import 'native_compatibility.dart';
import 'observed/observed_models.dart';
import 'occultation/occultation_models.dart';
import 'orbital/orbital_models.dart';
import 'phenomena/phenomena_models.dart';
import 'position/position_api.dart';
import 'runtime/runtime_models.dart';
import 'result_flags.dart';
import 'solar_time/solar_time_models.dart';
import 'star/star_models.dart';
import 'time/astro_date_time.dart';
import 'time/julian_date.dart';
import 'time/time_api.dart';
import 'time/time_models.dart';
import 'time/time_scale.dart';
import 'visibility/visibility_models.dart';

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
part 'solar_time/solar_time_api.dart';
part 'star/star_api.dart';
part 'visibility/visibility_api.dart';

/// A feature module reported by the loaded Taiyin native library.
enum Capability {
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
  splitTime(taiyinSplitTimeCapability),
  chineseCalendar(taiyinChineseCalendarCapability),
  ganzhiCalendar(taiyinGanzhiCalendarCapability);

  const Capability(this.mask);

  final int mask;
}

/// Broad category assigned to an Ephemeris status code.
enum StatusCategory {
  ok(0),
  generic(1),
  ephemeris(10),
  file(20),
  time(30),
  observer(40),
  event(50),
  runtime(60),
  unknown(999);

  const StatusCategory(this.id);

  final int id;

  static StatusCategory fromId(int id) {
    return values.firstWhere((value) => value.id == id, orElse: () => unknown);
  }
}

/// A non-success status returned by the Taiyin C ABI.
class EphemerisError implements Exception {
  EphemerisError(
    this.status,
    this.name,
    this.message, {
    this.resultFlags = ResultFlags.none,
    this.diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics = const [],
  }) : diagnostics = List.unmodifiable(
         diagnostics.isEmpty && diagnostic != null ? [diagnostic] : diagnostics,
       );

  final int status;
  final String name;
  final String message;

  /// Execution facts reported before this operation failed.
  final ResultFlags resultFlags;

  /// Native route and coverage details for a failed ephemeris calculation.
  final EphemerisDiagnostic? diagnostic;

  /// Every native diagnostic available for the failed operation.
  ///
  /// Single-target failures contain [diagnostic]. Batch failures may contain
  /// several entries while [diagnostic] remains the primary first failure.
  final List<EphemerisDiagnostic> diagnostics;

  @override
  String toString() => 'EphemerisError($status, $name): $message';
}

final class InvalidArgumentError extends EphemerisError {
  InvalidArgumentError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class EphemerisOutOfMemoryError extends EphemerisError {
  EphemerisOutOfMemoryError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class InternalCalculationError extends EphemerisError {
  InternalCalculationError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class UnsupportedOperationError extends EphemerisError {
  UnsupportedOperationError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class EphemerisRouteError extends EphemerisError {
  EphemerisRouteError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class DataFileError extends EphemerisError {
  DataFileError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class TimeScaleError extends EphemerisError {
  TimeScaleError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class ObserverError extends EphemerisError {
  ObserverError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class EventSearchError extends EphemerisError {
  EventSearchError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class RuntimeServiceError extends EphemerisError {
  RuntimeServiceError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

final class UnknownNativeError extends EphemerisError {
  UnknownNativeError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

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
    this._nativeState,
  ) {
    var finalizerAttached = false;
    try {
      _contextFinalizer.attach(this, _context.cast(), detach: this);
      finalizerAttached = true;
      configuration = ContextConfiguration._(
        _bindings,
        _context,
        _ensureOpen,
        (status) => _completeOperation(status),
      );
      time = Time.internal(
        _bindings,
        _context,
        _ensureOpen,
        (status) => _completeOperation(status),
      );
      astrology = AstrologyApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
      position = PositionApi.internal(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
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
      solarTime = SolarTimeApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
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
      eclipses = EclipseApi._(_bindings, _context, _ensureOpen, (
        status,
        diagnostic,
      ) {
        return _completeOperation(status, diagnostic: diagnostic);
      });
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
    if (diagnostic != null) _recordDiagnostic(diagnostic);
    final flags = _checkStatus(
      _bindings,
      rawResult,
      diagnostic: diagnostic,
      diagnostics: diagnostics,
    );
    _lastResultFlags = flags;
    return flags;
  }

  /// Every calendar context created from this context, tracked so closing the
  /// owner invalidates caller-created children that borrow its native state.
  final Set<ChineseCalendarContext> _calendarChildren = {};
  bool _closed = false;

  /// Creates an independent native context without reinitializing the runtime.
  ///
  /// Immutable cloned contexts may be used for concurrent calculations.
  EphemerisContext clone() {
    _ensureOpen();
    final context = using((arena) {
      final output = arena<Pointer<taiyin_context>>();
      _checkStatus(_bindings, _bindings.taiyin_context_clone(_context, output));
      return output.value;
    });
    return EphemerisContext._(
      _library,
      _bindings,
      context,
      _contextFinalizer,
      _nativeState,
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
    final child = ChineseCalendarContext._create(
      _nativeState,
      _bindings,
      _context,
      config,
      this,
    );
    _calendarChildren.add(child);
    return child;
  }

  /// FFI handle for the official extension packages (for example
  /// `package:taiyin_bazi` and `package:taiyin_ziwei`).
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
  final fileName = Platform.isWindows
      ? 'taiyin.dll'
      : Platform.isMacOS
      ? 'libtaiyin.dylib'
      : 'libtaiyin.so';
  final resolved = Isolate.resolvePackageUriSync(
    Uri.parse('package:taiyin/native/$fileName'),
  );
  if (resolved == null || resolved.scheme != 'file') return null;
  final path = resolved.toFilePath();
  return File(path).existsSync() ? path : null;
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
