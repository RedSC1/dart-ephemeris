part of '../taiyin.dart';

typedef _HeliacalStatusChecker =
    ResultFlags Function(int status, EphemerisDiagnostic? diagnostic);
typedef _HeliacalVisibilityCalculation =
    int Function(
      Arena arena,
      Pointer<taiyin_heliacal_visibility_conditions> conditions,
      Pointer<taiyin_heliacal_visibility_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _HeliacalSearchCalculation =
    int Function(
      Arena arena,
      Pointer<taiyin_heliacal_visibility_conditions> conditions,
      Pointer<taiyin_heliacal_visibility_search_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );

/// Heliacal visibility calculations and morning/evening event searches.
///
/// Calculations use the observer location and heliacal-visibility model on the
/// owning [EphemerisContext]. The native ABI accepts and returns split-JD UT1
/// Julian dates, preserving full precision across the FFI boundary.
final class HeliacalApi {
  HeliacalApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _HeliacalStatusChecker _checkStatus;

  /// Evaluates heliacal visibility of a solar-system [target] at [ut1].
  ///
  /// The Sun, Moon, Earth, and solar-system barycenter are not valid
  /// point-source heliacal targets. Other native body and custom-target IDs
  /// are passed through to the configured context.
  OperationResult<HeliacalVisibilityResult> bodyAtUt1(
    Target target,
    JulianDate<Ut1Scale> ut1, {
    Set<PositionFlag> positionFlags = const {},
    Set<HeliacalFlag> flags = const {},
    HeliacalVisibilityConditions conditions =
        const HeliacalVisibilityConditions(),
  }) {
    _ensureOpen();
    _requireBodyTarget(target);
    final mask = _heliacalMask(positionFlags, flags);
    _validateConditions(conditions);
    return _calculate(conditions, (
      arena,
      nativeConditions,
      output,
      diagnostic,
    ) {
      return _bindings.taiyin_calc_body_heliacal_visibility_ut(
        _context,
        target.id,
        writeJulianDate(arena, ut1),
        mask,
        nativeConditions,
        output,
        diagnostic,
      );
    });
  }

  /// Evaluates heliacal visibility of a catalogued star at [ut1].
  OperationResult<HeliacalVisibilityResult> starAtUt1(
    String starKey,
    JulianDate<Ut1Scale> ut1, {
    Set<PositionFlag> positionFlags = const {},
    Set<HeliacalFlag> flags = const {},
    HeliacalVisibilityConditions conditions =
        const HeliacalVisibilityConditions(),
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    final mask = _heliacalMask(positionFlags, flags);
    _validateConditions(conditions);
    return _calculate(conditions, (
      arena,
      nativeConditions,
      output,
      diagnostic,
    ) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _bindings.taiyin_calc_star_heliacal_visibility_ut(
        _context,
        nativeStarKey,
        writeJulianDate(arena, ut1),
        mask,
        nativeConditions,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next heliacal [event] of a solar-system [target].
  OperationResult<HeliacalVisibilitySearchResult> nextBodyEventAtUt1(
    Target target,
    JulianDate<Ut1Scale> start, {
    required HeliacalEventKind event,
    required double maxSearchDays,
    Set<PositionFlag> positionFlags = const {},
    Set<HeliacalFlag> flags = const {},
    HeliacalVisibilityConditions conditions =
        const HeliacalVisibilityConditions(),
  }) {
    _ensureOpen();
    _requireBodyTarget(target);
    _requireEvent(event);
    _requirePositiveFinite(maxSearchDays, 'maxSearchDays');
    final mask = _heliacalMask(positionFlags, flags);
    _validateConditions(conditions);
    return _search(conditions, (arena, nativeConditions, output, diagnostic) {
      return _bindings.taiyin_search_next_body_heliacal_visibility_ut(
        _context,
        target.id,
        writeJulianDate(arena, start),
        event.id,
        maxSearchDays,
        mask,
        nativeConditions,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next heliacal [event] of a catalogued star.
  OperationResult<HeliacalVisibilitySearchResult> nextStarEventAtUt1(
    String starKey,
    JulianDate<Ut1Scale> start, {
    required HeliacalEventKind event,
    required double maxSearchDays,
    Set<PositionFlag> positionFlags = const {},
    Set<HeliacalFlag> flags = const {},
    HeliacalVisibilityConditions conditions =
        const HeliacalVisibilityConditions(),
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    _requireEvent(event);
    _requirePositiveFinite(maxSearchDays, 'maxSearchDays');
    final mask = _heliacalMask(positionFlags, flags);
    _validateConditions(conditions);
    return _search(conditions, (arena, nativeConditions, output, diagnostic) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _bindings.taiyin_search_next_star_heliacal_visibility_ut(
        _context,
        nativeStarKey,
        writeJulianDate(arena, start),
        event.id,
        maxSearchDays,
        mask,
        nativeConditions,
        output,
        diagnostic,
      );
    });
  }

  OperationResult<HeliacalVisibilityResult> _calculate(
    HeliacalVisibilityConditions conditions,
    _HeliacalVisibilityCalculation calculate,
  ) {
    return using((arena) {
      final nativeConditions = _writeConditions(arena, conditions);
      final output = arena<taiyin_heliacal_visibility_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_heliacal_visibility_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, nativeConditions, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      return operationResult(_readVisibilityResult(output.ref), resultFlags);
    });
  }

  OperationResult<HeliacalVisibilitySearchResult> _search(
    HeliacalVisibilityConditions conditions,
    _HeliacalSearchCalculation calculate,
  ) {
    return using((arena) {
      final nativeConditions = _writeConditions(arena, conditions);
      final output = arena<taiyin_heliacal_visibility_search_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_heliacal_visibility_search_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, nativeConditions, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return operationResult(
        HeliacalVisibilitySearchResult(
          event: HeliacalEventKind.fromId(value.event_kind),
          coordinate: readJulianDate<Ut1Scale>(value.jd_ut),
          windowStart: readJulianDate<Ut1Scale>(value.window_start_jd_ut),
          windowEnd: readJulianDate<Ut1Scale>(value.window_end_jd_ut),
          scannedDayCount: value.scanned_day_count,
          sampledWindowCount: value.sampled_window_count,
          visibilityEvaluationCount: value.visibility_evaluation_count,
          visibility: _readVisibilityResult(value.visibility),
        ),
        resultFlags,
      );
    });
  }

  Pointer<taiyin_heliacal_visibility_conditions> _writeConditions(
    Arena arena,
    HeliacalVisibilityConditions conditions,
  ) {
    final native = arena<taiyin_heliacal_visibility_conditions>();
    _bindings.taiyin_heliacal_visibility_conditions_init(native);
    if (conditions.extinctionMagnitudePerAirmass case final value?) {
      native.ref.extinction_mag_per_airmass = value;
    }
    if (conditions.skyBrightnessNanolambert case final value?) {
      native.ref.sky_brightness_nanolambert = value;
    }
    if (conditions.nightSkyBrightnessNanolambert case final value?) {
      native.ref.night_sky_brightness_nanolambert = value;
    }
    return native;
  }

  HeliacalVisibilityResult _readVisibilityResult(
    taiyin_heliacal_visibility_result value,
  ) {
    return HeliacalVisibilityResult(
      visible: value.visible != 0,
      modelId: value.model_id,
      extinctionModelId: value.extinction_model_id,
      twilightModelId: value.twilight_model_id,
      moonlightModelId: value.moonlight_model_id,
      visualThresholdModelId: value.visual_threshold_model_id,
      targetMagnitude: value.target_magnitude,
      limitingMagnitude: value.limiting_magnitude,
      targetAltitudeRadians: value.target_altitude_rad,
      targetAzimuthRadians: value.target_azimuth_rad,
      sunAltitudeRadians: value.sun_altitude_rad,
      sunAzimuthRadians: value.sun_azimuth_rad,
      targetSunSeparationRadians: value.target_sun_separation_rad,
      airmass: value.airmass,
      extinctionMagnitudePerAirmass: value.extinction_mag_per_airmass,
      extinctionMagnitude: value.extinction_mag,
      skyBrightnessNanolambert: value.sky_brightness_nanolambert,
      moonlightBrightnessNanolambert: value.moonlight_brightness_nanolambert,
      thresholdIlluminanceFootcandles: value.threshold_illuminance_footcandles,
      targetIlluminanceFootcandles: value.target_illuminance_footcandles,
      visibilityMarginMagnitude: value.visibility_margin_magnitude,
      requiredSunAltitudeRadians: _finiteOrNull(
        value.required_sun_altitude_rad,
      ),
      solarDepressionMarginRadians: _finiteOrNull(
        value.solar_depression_margin_rad,
      ),
    );
  }

  int _heliacalMask(Set<PositionFlag> positionFlags, Set<HeliacalFlag> flags) {
    const allowedPositionFlags = {
      PositionFlag.truePosition,
      PositionFlag.noAberration,
      PositionFlag.noGravitationalDeflection,
      PositionFlag.astrometric,
    };
    final unsupported = positionFlags.difference(allowedPositionFlags);
    if (unsupported.isNotEmpty) {
      throw ArgumentError.value(
        positionFlags,
        'positionFlags',
        'heliacal visibility supports only truePosition, astrometric, '
            'noAberration, and noGravitationalDeflection',
      );
    }
    return positionFlags.fold(0, (mask, flag) => mask | flag.mask) |
        flags.fold(0, (mask, flag) => mask | flag.mask);
  }

  void _validateConditions(HeliacalVisibilityConditions conditions) {
    _requirePositiveOptional(
      conditions.extinctionMagnitudePerAirmass,
      'conditions.extinctionMagnitudePerAirmass',
    );
    _requirePositiveOptional(
      conditions.skyBrightnessNanolambert,
      'conditions.skyBrightnessNanolambert',
    );
    _requirePositiveOptional(
      conditions.nightSkyBrightnessNanolambert,
      'conditions.nightSkyBrightnessNanolambert',
    );
  }

  void _requireBodyTarget(Target target) {
    const unsupported = {
      Body.sun,
      Body.moon,
      Body.earth,
      Body.solarSystemBarycenter,
    };
    if (target is Body && unsupported.contains(target)) {
      throw ArgumentError.value(
        target,
        'target',
        'the Sun, Moon, Earth, and solar-system barycenter are not '
            'heliacal point-source targets',
      );
    }
  }

  void _requireStarKey(String starKey) {
    if (starKey.isEmpty) {
      throw ArgumentError.value(starKey, 'starKey', 'must not be empty');
    }
    if (starKey.contains('\u0000')) {
      throw ArgumentError.value(
        starKey,
        'starKey',
        'must not contain a NUL character',
      );
    }
  }

  void _requireEvent(HeliacalEventKind event) {
    if (event == HeliacalEventKind.unknown) {
      throw ArgumentError.value(event, 'event', 'must be a known event kind');
    }
  }

  void _requirePositiveFinite(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        'must be finite and greater than zero',
      );
    }
  }

  void _requirePositiveOptional(double? value, String name) {
    if (value != null) _requirePositiveFinite(value, name);
  }

  double? _finiteOrNull(double value) => value.isFinite ? value : null;
}
