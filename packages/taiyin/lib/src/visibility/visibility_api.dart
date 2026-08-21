part of '../taiyin.dart';

typedef _VisibilityStatusChecker =
    ResultFlags Function(int status, EphemerisDiagnostic? diagnostic);
typedef _VisibilityEventCalculation =
    int Function(
      Arena arena,
      Pointer<taiyin_visibility_event_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarRiseSetFastCalculation =
    int Function(
      Arena arena,
      Pointer<taiyin_solar_rise_set_fast_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarTransitFastCalculation =
    int Function(
      Arena arena,
      Pointer<taiyin_solar_transit_fast_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );

/// Rise, set, twilight, and meridian-transit searches.
///
/// Rise/set and transit searches use the observer location configured on the
/// owning [EphemerisContext]. They require a finite, non-empty UT1 interval. The
/// native ABI accepts and returns split Julian dates end to end, so the
/// [JulianDate] split representation crosses the FFI boundary intact.
final class VisibilityApi {
  VisibilityApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _VisibilityStatusChecker _checkStatus;

  /// Searches a UT1 interval for lunar rise or set.
  ///
  /// Set [horizonAltitudeRadians] to search against a custom geometric
  /// horizon. Otherwise the native standard-horizon route is used.
  OperationResult<VisibilityEvent> moonRiseSetAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
    VisibilityLimb limb = VisibilityLimb.upper,
    double? horizonAltitudeRadians,
    Set<VisibilityFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireRiseOrSet(event);
    _validateInterval(start, end);
    _validateHorizon(horizonAltitudeRadians);
    final mask = _visibilityMask(flags);
    return _searchEvent(event, (arena, output, diagnostic) {
      if (horizonAltitudeRadians == null) {
        return _bindings.taiyin_search_moon_rise_set_ut(
          _context,
          writeJulianDate(arena, start),
          writeJulianDate(arena, end),
          event.id,
          limb.id,
          mask,
          output,
          diagnostic,
        );
      }
      return _bindings.taiyin_search_moon_rise_set_at_horizon_ut(
        _context,
        writeJulianDate(arena, start),
        writeJulianDate(arena, end),
        event.id,
        limb.id,
        horizonAltitudeRadians,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Searches a UT1 interval for an upper or lower lunar meridian transit.
  OperationResult<VisibilityEvent> moonTransitAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
  }) {
    _ensureOpen();
    _requireTransit(event);
    _validateInterval(start, end);
    return _searchEvent(
      event,
      (arena, output, diagnostic) => _bindings.taiyin_search_moon_transit_ut(
        _context,
        writeJulianDate(arena, start),
        writeJulianDate(arena, end),
        event.id,
        output,
        diagnostic,
      ),
    );
  }

  /// Searches a UT1 interval for rise or set of a physical planet.
  ///
  /// [body] may be Mercury through Pluto. The Sun and Moon have dedicated
  /// methods. [VisibilityFlag.fixedDiscSize] is not supported here.
  OperationResult<VisibilityEvent> planetRiseSetAtUt1(
    Body body,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
    VisibilityLimb limb = VisibilityLimb.upper,
    double? horizonAltitudeRadians,
    Set<VisibilityFlag> flags = const {},
  }) {
    _ensureOpen();
    _requirePlanet(body);
    _requireRiseOrSet(event);
    _validateInterval(start, end);
    _validateHorizon(horizonAltitudeRadians);
    final mask = _visibilityMask(flags, allowsFixedDiscSize: false);
    return _searchEvent(event, (arena, output, diagnostic) {
      if (horizonAltitudeRadians == null) {
        return _bindings.taiyin_search_planet_rise_set_ut(
          _context,
          body.id,
          writeJulianDate(arena, start),
          writeJulianDate(arena, end),
          event.id,
          limb.id,
          mask,
          output,
          diagnostic,
        );
      }
      return _bindings.taiyin_search_planet_rise_set_at_horizon_ut(
        _context,
        body.id,
        writeJulianDate(arena, start),
        writeJulianDate(arena, end),
        event.id,
        limb.id,
        horizonAltitudeRadians,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Searches a UT1 interval for an upper or lower planetary transit.
  OperationResult<VisibilityEvent> planetTransitAtUt1(
    Body body,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    _requirePlanet(body);
    _requireTransit(event);
    _validateInterval(start, end);
    return _searchEvent(
      event,
      (arena, output, diagnostic) => _bindings.taiyin_search_planet_transit_ut(
        _context,
        body.id,
        writeJulianDate(arena, start),
        writeJulianDate(arena, end),
        event.id,
        flags.fold(0, (value, flag) => value | flag.mask),
        output,
        diagnostic,
      ),
    );
  }

  /// Searches a UT1 interval for solar rise or set.
  ///
  /// Set [horizonAltitudeRadians] to search against a custom geometric
  /// horizon. Otherwise the native standard-horizon route is used.
  OperationResult<VisibilityEvent> solarRiseSetAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
    VisibilityLimb limb = VisibilityLimb.upper,
    double? horizonAltitudeRadians,
    Set<VisibilityFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireRiseOrSet(event);
    _validateInterval(start, end);
    _validateHorizon(horizonAltitudeRadians);
    final mask = _visibilityMask(flags);
    return _searchEvent(event, (arena, output, diagnostic) {
      if (horizonAltitudeRadians == null) {
        return _bindings.taiyin_search_solar_rise_set_ut(
          _context,
          writeJulianDate(arena, start),
          writeJulianDate(arena, end),
          event.id,
          limb.id,
          mask,
          output,
          diagnostic,
        );
      }
      return _bindings.taiyin_search_solar_rise_set_at_horizon_ut(
        _context,
        writeJulianDate(arena, start),
        writeJulianDate(arena, end),
        event.id,
        limb.id,
        horizonAltitudeRadians,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Searches a UT1 interval for a selected morning or evening twilight.
  ///
  /// [VisibilityEventKind.rise] finds morning twilight (dawn), while
  /// [VisibilityEventKind.set] finds evening twilight (dusk).
  OperationResult<VisibilityEvent> solarTwilightAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
    required TwilightKind twilight,
  }) {
    _ensureOpen();
    _requireRiseOrSet(event);
    _validateInterval(start, end);
    return _searchEvent(
      event,
      (arena, output, diagnostic) => _bindings.taiyin_search_solar_twilight_ut(
        _context,
        writeJulianDate(arena, start),
        writeJulianDate(arena, end),
        event.id,
        twilight.id,
        output,
        diagnostic,
      ),
    );
  }

  /// Searches a UT1 interval for an upper or lower solar meridian transit.
  OperationResult<VisibilityEvent> solarTransitAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
  }) {
    _ensureOpen();
    _requireTransit(event);
    _validateInterval(start, end);
    return _searchEvent(
      event,
      (arena, output, diagnostic) => _bindings.taiyin_search_solar_transit_ut(
        _context,
        writeJulianDate(arena, start),
        writeJulianDate(arena, end),
        event.id,
        output,
        diagnostic,
      ),
    );
  }

  /// Computes approximate solar rise and set around a TT coordinate.
  ///
  /// This fast route receives [observer] directly; it does not use the
  /// context's configured observer location for the supplied coordinates.
  /// [limb] selects the solar disc limb whose crossing defines the event;
  /// [flags] controls refraction and disc-size handling, with the same default
  /// and rejection semantics as [solarRiseSetAtUt1].
  OperationResult<SolarRiseSetFastResult> solarRiseSetFastAtTt(
    JulianDate<TtScale> center,
    ObserverLocation observer, {
    VisibilityLimb limb = VisibilityLimb.upper,
    double horizonAltitudeRadians = 0,
    Set<VisibilityFlag> flags = const {},
  }) {
    _ensureOpen();
    _validateObserver(observer);
    _requireFinite(horizonAltitudeRadians, 'horizonAltitudeRadians');
    final mask = _visibilityMask(flags);
    return _solarRiseSetFast((arena, output, diagnostic) {
      return _bindings.taiyin_compute_solar_rise_set_fast_tt(
        _context,
        writeJulianDate(arena, center),
        observer.longitudeDegrees,
        observer.latitudeDegrees,
        observer.heightMeters,
        limb.id,
        horizonAltitudeRadians,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Computes an approximate solar meridian transit near a TT coordinate.
  ///
  /// This fast route receives [observer] directly; it does not use the
  /// context's configured observer location for the supplied coordinates.
  OperationResult<SolarTransitFastResult> solarTransitFastAtTt(
    JulianDate<TtScale> center,
    ObserverLocation observer,
  ) {
    _ensureOpen();
    _validateObserver(observer);
    return _solarTransitFast((arena, output, diagnostic) {
      return _bindings.taiyin_compute_solar_transit_fast_tt(
        _context,
        writeJulianDate(arena, center),
        observer.longitudeDegrees,
        observer.latitudeDegrees,
        observer.heightMeters,
        output,
        diagnostic,
      );
    });
  }

  /// Searches a UT1 interval for rise or set of a catalogued star.
  ///
  /// The runtime star catalog must contain [starKey]. Set
  /// [horizonAltitudeRadians] to search against a custom geometric horizon.
  OperationResult<VisibilityEvent> starRiseSetAtUt1(
    String starKey,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
    double? horizonAltitudeRadians,
    Set<VisibilityFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    _requireRiseOrSet(event);
    _validateInterval(start, end);
    _validateHorizon(horizonAltitudeRadians);
    final mask = _visibilityMask(flags, allowsFixedDiscSize: false);
    return using((arena) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _searchEvent(event, (searchArena, output, diagnostic) {
        if (horizonAltitudeRadians == null) {
          return _bindings.taiyin_search_star_rise_set_ut(
            _context,
            nativeStarKey,
            writeJulianDate(searchArena, start),
            writeJulianDate(searchArena, end),
            event.id,
            mask,
            output,
            diagnostic,
          );
        }
        return _bindings.taiyin_search_star_rise_set_at_horizon_ut(
          _context,
          nativeStarKey,
          writeJulianDate(searchArena, start),
          writeJulianDate(searchArena, end),
          event.id,
          horizonAltitudeRadians,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Searches a UT1 interval for an upper or lower catalogued-star transit.
  OperationResult<VisibilityEvent> starTransitAtUt1(
    String starKey,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required VisibilityEventKind event,
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    _requireTransit(event);
    _validateInterval(start, end);
    return using((arena) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _searchEvent(
        event,
        (searchArena, output, diagnostic) =>
            _bindings.taiyin_search_star_transit_ut(
              _context,
              nativeStarKey,
              writeJulianDate(searchArena, start),
              writeJulianDate(searchArena, end),
              event.id,
              output,
              diagnostic,
            ),
      );
    });
  }

  OperationResult<VisibilityEvent> _searchEvent(
    VisibilityEventKind event,
    _VisibilityEventCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_visibility_event_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_visibility_event_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return operationResult(
        VisibilityEvent(
          requestedEvent: event,
          altitudeState: VisibilityAltitudeState.fromId(value.altitude_state),
          crossingDirection: VisibilityCrossingDirection.fromId(
            value.crossing_direction,
          ),
          coordinate: _ut1OrNull(value.jd_ut),
          residualRadians: value.residual_rad,
          minimumResidualRadians: value.min_residual_rad,
          maximumResidualRadians: value.max_residual_rad,
          minimumResidualCoordinate: _ut1OrNull(value.min_residual_jd_ut),
          maximumResidualCoordinate: _ut1OrNull(value.max_residual_jd_ut),
          sampleCount: value.sample_count,
          refineCount: value.refine_count,
        ),
        resultFlags,
      );
    });
  }

  OperationResult<SolarRiseSetFastResult> _solarRiseSetFast(
    _SolarRiseSetFastCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_rise_set_fast_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_rise_set_fast_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return operationResult(
        SolarRiseSetFastResult(
          altitudeState: VisibilityAltitudeState.fromId(value.altitude_state),
          rise: _ttOrNull(value.rise_jd_tt),
          set: _ttOrNull(value.set_jd_tt),
          sampleCount: value.sample_count,
          refineCount: value.refine_count,
        ),
        resultFlags,
      );
    });
  }

  OperationResult<SolarTransitFastResult> _solarTransitFast(
    _SolarTransitFastCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_transit_fast_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_transit_fast_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return operationResult(
        SolarTransitFastResult(
          coordinate: _ttOrNull(value.transit_jd_tt),
          altitudeRadians: value.altitude_rad,
          azimuthRadians: value.azimuth_rad,
          sampleCount: value.sample_count,
          refineCount: value.refine_count,
        ),
        resultFlags,
      );
    });
  }

  int _visibilityMask(
    Set<VisibilityFlag> flags, {
    bool allowsFixedDiscSize = true,
  }) {
    if (flags.contains(VisibilityFlag.refraction) &&
        flags.contains(VisibilityFlag.noRefraction)) {
      throw ArgumentError(
        'Refraction and noRefraction cannot be requested together.',
      );
    }
    if (!allowsFixedDiscSize && flags.contains(VisibilityFlag.fixedDiscSize)) {
      throw ArgumentError.value(
        flags,
        'flags',
        'fixedDiscSize is supported only for Sun and Moon searches',
      );
    }
    return flags.fold(0, (mask, flag) => mask | flag.mask);
  }

  void _validateInterval(JulianDate<Ut1Scale> start, JulianDate<Ut1Scale> end) {
    if (end.compareTo(start) <= 0) {
      throw ArgumentError.value(end, 'end', 'must be later than start');
    }
  }

  void _validateHorizon(double? horizonAltitudeRadians) {
    if (horizonAltitudeRadians != null) {
      _requireFinite(horizonAltitudeRadians, 'horizonAltitudeRadians');
    }
  }

  void _validateObserver(ObserverLocation observer) {
    _requireFinite(observer.longitudeDegrees, 'observer.longitudeDegrees');
    _requireFinite(observer.latitudeDegrees, 'observer.latitudeDegrees');
    _requireFinite(observer.heightMeters, 'observer.heightMeters');
    if (observer.latitudeDegrees < -90 || observer.latitudeDegrees > 90) {
      throw RangeError.range(
        observer.latitudeDegrees,
        -90,
        90,
        'observer.latitudeDegrees',
      );
    }
  }

  void _requireRiseOrSet(VisibilityEventKind event) {
    if (!event.isRiseOrSet) {
      throw ArgumentError.value(event, 'event', 'must be rise or set');
    }
  }

  void _requireTransit(VisibilityEventKind event) {
    if (!event.isTransit) {
      throw ArgumentError.value(
        event,
        'event',
        'must be upperTransit or lowerTransit',
      );
    }
  }

  void _requirePlanet(Body body) {
    const supported = {
      Body.mercury,
      Body.venus,
      Body.mars,
      Body.jupiter,
      Body.saturn,
      Body.uranus,
      Body.neptune,
      Body.pluto,
    };
    if (!supported.contains(body)) {
      throw ArgumentError.value(
        body,
        'body',
        'must be a physical planet from Mercury through Pluto',
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

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }

  JulianDate<Ut1Scale>? _ut1OrNull(taiyin_split_julian_date value) {
    return value.day_fraction.isFinite ? readJulianDate<Ut1Scale>(value) : null;
  }

  JulianDate<TtScale>? _ttOrNull(taiyin_split_julian_date value) {
    return value.day_fraction.isFinite ? readJulianDate<TtScale>(value) : null;
  }
}
