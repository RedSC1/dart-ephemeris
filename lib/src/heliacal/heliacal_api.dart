part of '../taiyin.dart';

typedef _HeliacalStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);
typedef _HeliacalVisibilityCalculation =
    int Function(
      Pointer<taiyin_heliacal_visibility_conditions> conditions,
      Pointer<taiyin_heliacal_visibility_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _HeliacalSearchCalculation =
    int Function(
      Pointer<taiyin_heliacal_visibility_conditions> conditions,
      Pointer<taiyin_heliacal_visibility_search_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );

/// Heliacal visibility calculations and morning/evening event searches.
///
/// Calculations use the observer location and heliacal-visibility model on the
/// owning [TaiyinContext]. The native ABI accepts and returns scalar UT1 Julian
/// dates; [JulianDate] keeps its split representation everywhere else in Dart.
final class TaiyinHeliacalApi {
  TaiyinHeliacalApi._(
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
  TaiyinEphemerisResult<TaiyinHeliacalVisibilityResult> bodyAtUt1(
    TaiyinTarget target,
    JulianDate<Ut1Scale> ut1, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinHeliacalFlag> flags = const {},
    TaiyinHeliacalVisibilityConditions conditions =
        const TaiyinHeliacalVisibilityConditions(),
  }) {
    _ensureOpen();
    _requireBodyTarget(target);
    final mask = _heliacalMask(positionFlags, flags);
    _validateConditions(conditions);
    return _calculate(conditions, (nativeConditions, output, diagnostic) {
      return _bindings.taiyin_calc_body_heliacal_visibility_ut(
        _context,
        target.id,
        ut1.toDouble(),
        mask,
        nativeConditions,
        output,
        diagnostic,
      );
    });
  }

  /// Evaluates heliacal visibility of a catalogued star at [ut1].
  TaiyinEphemerisResult<TaiyinHeliacalVisibilityResult> starAtUt1(
    String starKey,
    JulianDate<Ut1Scale> ut1, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinHeliacalFlag> flags = const {},
    TaiyinHeliacalVisibilityConditions conditions =
        const TaiyinHeliacalVisibilityConditions(),
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    final mask = _heliacalMask(positionFlags, flags);
    _validateConditions(conditions);
    return using((arena) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _calculate(conditions, (nativeConditions, output, diagnostic) {
        return _bindings.taiyin_calc_star_heliacal_visibility_ut(
          _context,
          nativeStarKey,
          ut1.toDouble(),
          mask,
          nativeConditions,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next heliacal [event] of a solar-system [target].
  TaiyinEphemerisResult<TaiyinHeliacalVisibilitySearchResult>
  nextBodyEventAtUt1(
    TaiyinTarget target,
    JulianDate<Ut1Scale> start, {
    required TaiyinHeliacalEventKind event,
    required double maxSearchDays,
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinHeliacalFlag> flags = const {},
    TaiyinHeliacalVisibilityConditions conditions =
        const TaiyinHeliacalVisibilityConditions(),
  }) {
    _ensureOpen();
    _requireBodyTarget(target);
    _requireEvent(event);
    _requirePositiveFinite(maxSearchDays, 'maxSearchDays');
    final mask = _heliacalMask(positionFlags, flags);
    _validateConditions(conditions);
    return _search(conditions, (nativeConditions, output, diagnostic) {
      return _bindings.taiyin_search_next_body_heliacal_visibility_ut(
        _context,
        target.id,
        start.toDouble(),
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
  TaiyinEphemerisResult<TaiyinHeliacalVisibilitySearchResult>
  nextStarEventAtUt1(
    String starKey,
    JulianDate<Ut1Scale> start, {
    required TaiyinHeliacalEventKind event,
    required double maxSearchDays,
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinHeliacalFlag> flags = const {},
    TaiyinHeliacalVisibilityConditions conditions =
        const TaiyinHeliacalVisibilityConditions(),
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    _requireEvent(event);
    _requirePositiveFinite(maxSearchDays, 'maxSearchDays');
    final mask = _heliacalMask(positionFlags, flags);
    _validateConditions(conditions);
    return using((arena) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _search(conditions, (nativeConditions, output, diagnostic) {
        return _bindings.taiyin_search_next_star_heliacal_visibility_ut(
          _context,
          nativeStarKey,
          start.toDouble(),
          event.id,
          maxSearchDays,
          mask,
          nativeConditions,
          output,
          diagnostic,
        );
      });
    });
  }

  TaiyinEphemerisResult<TaiyinHeliacalVisibilityResult> _calculate(
    TaiyinHeliacalVisibilityConditions conditions,
    _HeliacalVisibilityCalculation calculate,
  ) {
    return using((arena) {
      final nativeConditions = _writeConditions(arena, conditions);
      final output = arena<taiyin_heliacal_visibility_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_heliacal_visibility_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(nativeConditions, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readVisibilityResult(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinHeliacalVisibilitySearchResult> _search(
    TaiyinHeliacalVisibilityConditions conditions,
    _HeliacalSearchCalculation calculate,
  ) {
    return using((arena) {
      final nativeConditions = _writeConditions(arena, conditions);
      final output = arena<taiyin_heliacal_visibility_search_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_heliacal_visibility_search_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(nativeConditions, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinHeliacalVisibilitySearchResult(
          event: TaiyinHeliacalEventKind.fromId(value.event_kind),
          coordinate: JulianDate<Ut1Scale>.fromDouble(value.jd_ut),
          windowStart: JulianDate<Ut1Scale>.fromDouble(
            value.window_start_jd_ut,
          ),
          windowEnd: JulianDate<Ut1Scale>.fromDouble(value.window_end_jd_ut),
          scannedDayCount: value.scanned_day_count,
          sampledWindowCount: value.sampled_window_count,
          visibilityEvaluationCount: value.visibility_evaluation_count,
          visibility: _readVisibilityResult(value.visibility),
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  Pointer<taiyin_heliacal_visibility_conditions> _writeConditions(
    Arena arena,
    TaiyinHeliacalVisibilityConditions conditions,
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

  TaiyinHeliacalVisibilityResult _readVisibilityResult(
    taiyin_heliacal_visibility_result value,
  ) {
    return TaiyinHeliacalVisibilityResult(
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

  int _heliacalMask(
    Set<TaiyinPositionFlag> positionFlags,
    Set<TaiyinHeliacalFlag> flags,
  ) {
    const allowedPositionFlags = {
      TaiyinPositionFlag.truePosition,
      TaiyinPositionFlag.noAberration,
      TaiyinPositionFlag.noGravitationalDeflection,
      TaiyinPositionFlag.astrometric,
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

  void _validateConditions(TaiyinHeliacalVisibilityConditions conditions) {
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

  void _requireBodyTarget(TaiyinTarget target) {
    const unsupported = {
      TaiyinBody.sun,
      TaiyinBody.moon,
      TaiyinBody.earth,
      TaiyinBody.solarSystemBarycenter,
    };
    if (target is TaiyinBody && unsupported.contains(target)) {
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

  void _requireEvent(TaiyinHeliacalEventKind event) {
    if (event == TaiyinHeliacalEventKind.unknown) {
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
