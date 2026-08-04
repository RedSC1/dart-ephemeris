import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings/taiyin_bindings.g.dart';
import 'astrology/astrology_models.dart';
import 'bazi/bazi_models.dart';
import 'chinese_calendar/chinese_calendar_models.dart';
import 'context/context_models.dart';
import 'ganzhi/ganzhi_models.dart';
import 'eclipse/lunar_eclipse_models.dart';
import 'eclipse/solar_eclipse_models.dart';
import 'events/event_models.dart';
import 'heliacal/heliacal_models.dart';
import 'interop/calendar.dart';
import 'interop/julian_date.dart';
import 'native_compatibility.dart';
import 'observed/observed_models.dart';
import 'occultation/occultation_models.dart';
import 'orbital/orbital_models.dart';
import 'phenomena/phenomena_models.dart';
import 'position/position_api.dart';
import 'solar_time/solar_time_models.dart';
import 'star/star_models.dart';
import 'time/astro_date_time.dart';
import 'time/julian_date.dart';
import 'time/time_api.dart';
import 'time/time_models.dart';
import 'time/time_scale.dart';
import 'visibility/visibility_models.dart';

part 'bazi/bazi_api.dart';
part 'chinese_calendar/chinese_calendar_api.dart';
part 'context/context_api.dart';
part 'eclipse/eclipse_api.dart';
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
  splitTime(taiyinSplitTimeCapability),
  chineseCalendar(taiyinChineseCalendarCapability),
  bazi(taiyinBaziCapability),
  ganzhiCalendar(taiyinGanzhiCalendarCapability);

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

/// A non-success status returned by the Taiyin C ABI.
final class TaiyinException implements Exception {
  TaiyinException(
    this.status,
    this.name,
    this.message, {
    this.diagnostic,
    Iterable<TaiyinEphemerisDiagnostic> diagnostics = const [],
  }) : diagnostics = List.unmodifiable(
         diagnostics.isEmpty && diagnostic != null ? [diagnostic] : diagnostics,
       );

  final int status;
  final String name;
  final String message;

  /// Native route and coverage details for a failed ephemeris calculation.
  final TaiyinEphemerisDiagnostic? diagnostic;

  /// Every native diagnostic available for the failed operation.
  ///
  /// Single-target failures contain [diagnostic]. Batch failures may contain
  /// several entries while [diagnostic] remains the primary first failure.
  final List<TaiyinEphemerisDiagnostic> diagnostics;

  @override
  String toString() => 'TaiyinException($status, $name): $message';
}

/// One user-owned Taiyin calculation context.
///
/// Call [close] when finished. A native finalizer is also attached as a safety
/// net for contexts that are not closed explicitly.
///
/// This object does not own or reconfigure the process-wide [Taiyin] runtime.
/// Create it through [Taiyin.createContext], or use [attach] in a Dart
/// isolate after another isolate has initialized the runtime.
final class TaiyinContext implements Finalizable {
  TaiyinContext._(
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
      configuration = TaiyinContextConfiguration._(
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
      astrology = TaiyinAstrologyApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      position = TaiyinPositionApi.internal(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      observed = TaiyinObservedApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic, diagnostics) => _checkStatus(
          _bindings,
          status,
          diagnostic: diagnostic,
          diagnostics: diagnostics,
        ),
      );
      orbits = TaiyinOrbitalApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      phenomena = TaiyinPhenomenaApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      solarTime = TaiyinSolarTimeApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      visibility = TaiyinVisibilityApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      heliacal = TaiyinHeliacalApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      events = TaiyinEventsApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      eclipses = TaiyinEclipseApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      occultation = TaiyinOccultationApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic) =>
            _checkStatus(_bindings, status, diagnostic: diagnostic),
      );
      stars = TaiyinStarApi._(
        _bindings,
        _context,
        _ensureOpen,
        (status, diagnostic, diagnostics) => _checkStatus(
          _bindings,
          status,
          diagnostic: diagnostic,
          diagnostics: diagnostics,
        ),
        observed,
      );
      ganzhi = TaiyinGanzhiApi._(_bindings, _nativeState.capabilities);
    } catch (_) {
      if (finalizerAttached) {
        _contextFinalizer.detach(this);
      }
      _bindings.taiyin_context_destroy(_context);
      rethrow;
    }
  }

  /// Opens the native library and creates a context without initializing the
  /// process-wide runtime.
  ///
  /// [Taiyin.open] must already have configured the runtime in this process.
  /// This constructor is intended for worker isolates that need an independent
  /// context while sharing the existing native runtime.
  ///
  /// The current C ABI does not expose an initialization-state query, so this
  /// precondition cannot be checked here. Calling [attach] first is unsupported
  /// and may report an ephemeris error only when a calculation is attempted.
  factory TaiyinContext.attach({String? libraryPath}) {
    return TaiyinContext.attachToDynamicLibrary(_openLibrary(libraryPath));
  }

  /// Attaches a context to an already-loaded native library without
  /// reconfiguring the process-wide runtime.
  factory TaiyinContext.attachToDynamicLibrary(DynamicLibrary library) {
    final state = _nativeLibraryStateFor(library);
    return TaiyinContext._create(library, state);
  }

  factory TaiyinContext._create(
    DynamicLibrary library,
    _TaiyinNativeLibraryState nativeState,
  ) {
    final context = using((arena) {
      final output = arena<Pointer<taiyin_context>>();
      _checkStatus(
        nativeState.bindings,
        nativeState.bindings.taiyin_context_create(output),
      );
      return output.value;
    });
    return TaiyinContext._(
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
  final _TaiyinNativeLibraryState _nativeState;
  late final TaiyinContextConfiguration configuration;
  late final TaiyinTime time;
  late final TaiyinAstrologyApi astrology;
  late final TaiyinPositionApi position;
  late final TaiyinObservedApi observed;
  late final TaiyinOrbitalApi orbits;
  late final TaiyinPhenomenaApi phenomena;
  late final TaiyinSolarTimeApi solarTime;
  late final TaiyinVisibilityApi visibility;
  late final TaiyinHeliacalApi heliacal;
  late final TaiyinEventsApi events;
  late final TaiyinEclipseApi eclipses;
  late final TaiyinOccultationApi occultation;
  late final TaiyinStarApi stars;
  late final TaiyinGanzhiApi ganzhi;
  TaiyinChineseCalendarContext? _chineseCalendar;

  /// Every calendar context created from this context, tracked so closing the
  /// owner invalidates caller-created children that borrow its native state.
  final Set<TaiyinChineseCalendarContext> _calendarChildren = {};
  TaiyinBaziContext? _bazi;
  bool _closed = false;

  /// Creates an independent native context without reinitializing the runtime.
  ///
  /// Immutable cloned contexts may be used for concurrent calculations.
  TaiyinContext clone() {
    _ensureOpen();
    final context = using((arena) {
      final output = arena<Pointer<taiyin_context>>();
      _checkStatus(_bindings, _bindings.taiyin_context_clone(_context, output));
      return output.value;
    });
    return TaiyinContext._(
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
  TaiyinChineseCalendarContext get chineseCalendar {
    final cached = _chineseCalendar;
    if (cached != null && !cached.isClosed) return cached;
    return _chineseCalendar = createChineseCalendar();
  }

  /// Creates an independent Chinese-calendar context owned by the caller.
  ///
  /// Call [TaiyinChineseCalendarContext.close] when it is no longer needed.
  TaiyinChineseCalendarContext createChineseCalendar({
    TaiyinChineseCalendarConfig config = const TaiyinChineseCalendarConfig(),
  }) {
    _ensureOpen();
    final child = TaiyinChineseCalendarContext._create(
      _nativeState,
      _bindings,
      _context,
      config,
      this,
    );
    _calendarChildren.add(child);
    return child;
  }

  /// A BaZi context using the default astronomical configuration.
  ///
  /// The first access creates and caches the native context; [close] releases
  /// it together with the owning context. A cache entry closed by the caller
  /// is replaced on the next access.
  TaiyinBaziContext get bazi {
    final cached = _bazi;
    if (cached != null && !cached.isClosed) return cached;
    return _bazi = createBazi();
  }

  /// Creates an independent BaZi context owned by the caller.
  ///
  /// Call [TaiyinBaziContext.close] when it is no longer needed.
  TaiyinBaziContext createBazi({
    TaiyinBaziContextConfig config = const TaiyinBaziContextConfig(),
  }) {
    _ensureOpen();
    return TaiyinBaziContext._create(_nativeState, _bindings, config);
  }

  /// Calculates a position at a TT Julian date.
  TaiyinPosition positionTt(
    TaiyinTarget body,
    JulianDate<TtScale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return position.atTt(body, julianDate, flags: flags).value;
  }

  /// Calculates a position at a UT Julian date.
  TaiyinPosition positionUt(
    TaiyinTarget body,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return position.atUt1(body, julianDate, flags: flags).value;
  }

  /// Releases the owned native context. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    // Destroy borrowed child contexts before the owning native context.
    for (final child in List.of(_calendarChildren)) {
      child.close();
    }
    _calendarChildren.clear();
    _bazi?.close();
    _contextFinalizer.detach(this);
    _bindings.taiyin_context_destroy(_context);
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This TaiyinContext has been closed.');
    }
  }
}

final class _TaiyinNativeLibraryState {
  _TaiyinNativeLibraryState(
    this.bindings,
    this.contextFinalizer,
    this.chineseCalendarFinalizer,
    this.capabilities,
    this._library,
  );

  final TaiyinBindings bindings;
  final NativeFinalizer contextFinalizer;
  final NativeFinalizer chineseCalendarFinalizer;
  final int capabilities;
  final DynamicLibrary _library;
  final Map<int, TaiyinCustomTargetRegistration> customTargetRegistrations = {};
  final Map<int, TaiyinCustomAyanamshaRegistration>
  customAyanamshaRegistrations = {};
  final Map<int, TaiyinCustomHouseSystemRegistration>
  customHouseSystemRegistrations = {};

  NativeFinalizer? _baziFinalizer;

  /// The BaZi context finalizer, created lazily and only after the BaZi
  /// capability has been confirmed. The symbol does not exist in a build
  /// without `TAIYIN_BUILD_BAZI_EXTENSION=ON`, so it must never be looked up
  /// otherwise.
  NativeFinalizer? get baziFinalizer {
    if ((capabilities & taiyinBaziCapability) == 0) return null;
    return _baziFinalizer ??= NativeFinalizer(
      _library.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
        'taiyin_bazi_context_destroy',
      ),
    );
  }
}

// NativeFinalizer itself must stay reachable until its attachments have run.
// Keying by the destroy symbol also reuses bindings when the same native module
// is opened through more than one DynamicLibrary wrapper in this isolate.
final Map<int, _TaiyinNativeLibraryState> _nativeLibraryStates = {};

DynamicLibrary _openLibrary(String? libraryPath) {
  final resolvedPath =
      libraryPath ?? Platform.environment['TAIYIN_LIBRARY_PATH'];
  return resolvedPath == null
      ? _openDefaultLibrary()
      : DynamicLibrary.open(resolvedPath);
}

DynamicLibrary _openDefaultLibrary() {
  if (Platform.isIOS) return DynamicLibrary.process();
  // Windows shared libraries are named by C ABI version; macOS and Linux build
  // and install trees provide versionless symlinks.
  if (Platform.isWindows) return DynamicLibrary.open('taiyin-5.dll');
  if (Platform.isMacOS) return DynamicLibrary.open('libtaiyin.dylib');
  return DynamicLibrary.open('libtaiyin.so');
}

_TaiyinNativeLibraryState _nativeLibraryStateFor(DynamicLibrary library) {
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
    if ((capabilities & taiyinBaziCapability) != 0) {
      validateTaiyinRequiredSymbols(
        providesSymbol: library.providesSymbol,
        requiredSymbols: taiyinBaziSymbols,
      );
    }
    return _TaiyinNativeLibraryState(
      bindings,
      NativeFinalizer(destroy),
      NativeFinalizer(
        library.lookup<NativeFunction<Void Function(Pointer<Void>)>>(
          'taiyin_chinese_calendar_context_destroy',
        ),
      ),
      capabilities,
      library,
    );
  });
}

Never _throwStatus(
  TaiyinBindings bindings,
  int status, {
  TaiyinEphemerisDiagnostic? diagnostic,
  Iterable<TaiyinEphemerisDiagnostic> diagnostics = const [],
}) {
  throw TaiyinException(
    status,
    _readNativeString(bindings.taiyin_status_name(status)),
    _readNativeString(bindings.taiyin_status_message(status)),
    diagnostic: diagnostic,
    diagnostics: diagnostics,
  );
}

void _checkStatus(
  TaiyinBindings bindings,
  int status, {
  TaiyinEphemerisDiagnostic? diagnostic,
  Iterable<TaiyinEphemerisDiagnostic> diagnostics = const [],
}) {
  if (status != 0) {
    _throwStatus(
      bindings,
      status,
      diagnostic: diagnostic,
      diagnostics: diagnostics,
    );
  }
}

String _readNativeString(Pointer<Char> value) {
  if (value == nullptr) return 'Unknown';
  return value.cast<Utf8>().toDartString();
}

void _writeEphemerisDiagnostic(
  Pointer<taiyin_ephemeris_diagnostic> output,
  TaiyinEphemerisDiagnostic value,
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

TaiyinEphemerisDiagnostic _readEphemerisDiagnostic(
  taiyin_ephemeris_diagnostic value,
) {
  final timeScaleFlags = {
    for (final flag in TimeScaleDiagnosticFlag.values)
      if ((value.time_scale_flags & flag.mask) != 0) flag,
  };
  return TaiyinEphemerisDiagnostic(
    status: value.status,
    targetId: value.target_id,
    centerId: value.center_id,
    frame: TaiyinApparentFrame.fromId(value.frame),
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
