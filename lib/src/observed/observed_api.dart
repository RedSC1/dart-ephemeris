part of '../taiyin.dart';

typedef _ObservedCalculation =
    int Function(
      Arena arena,
      Pointer<Int32> bodyIds,
      int bodyCount,
      int mask,
      Pointer<taiyin_observed_position> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostics,
    );
typedef _ObservedStatusChecker =
    void Function(
      int status,
      EphemerisDiagnostic? diagnostic,
      List<EphemerisDiagnostic> diagnostics,
    );

/// Apparent and observed positions for major solar-system bodies.
///
/// Native observed-position batches contain at most ten bodies. Horizontal
/// output requires [ObservedFlag.topocentric] and a context observer
/// location. See [ContextConfiguration] for observer and atmosphere
/// configuration.
///
/// A failure for any requested body makes the native batch fail. Batch-level
/// failures throw [EphemerisError]; partial results are not returned.
///
/// The native observed API does not currently propagate its internal
/// time-scale diagnostic into the returned ephemeris diagnostic. Consequently,
/// time-scale fields such as [EphemerisDiagnostic.timeScaleRoute] retain
/// their default values for both UT1 and UTC observed calculations.
final class ObservedApi {
  ObservedApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _ObservedStatusChecker _checkStatus;

  /// Calculates one observed position at a UT1 Julian date.
  ///
  /// This native route estimates the remaining scales from the configured
  /// Delta-T model. It does not apply EOP-backed celestial-pole offsets. Prefer
  /// [atUtc] when EOP data is available and maximum topocentric precision is
  /// required.
  ObservedPosition atUt1(
    Body body,
    JulianDate<Ut1Scale> julianDate, {
    Set<ObservedFlag> flags = const {},
  }) {
    return batchAtUt1([body], julianDate, flags: flags).single;
  }

  /// Calculates observed positions at a UT1 Julian date.
  ///
  /// This has the same model-based precision behavior as [atUt1].
  List<ObservedPosition> batchAtUt1(
    List<Body> bodies,
    JulianDate<Ut1Scale> julianDate, {
    Set<ObservedFlag> flags = const {},
  }) {
    _ensureOpen();
    return _calculate(
      bodies,
      flags,
      (arena, bodyIds, bodyCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_observed_bodies_ut(
            _context,
            writeJulianDate(arena, julianDate),
            bodyIds,
            bodyCount,
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates one observed position from a UTC calendar value.
  ///
  /// The native runtime must have Earth-orientation data covering [utc]. This
  /// route uses EOP-backed time scales and celestial-pole offsets.
  ObservedPosition atUtc(
    Body body,
    AstroDateTime utc, {
    Set<ObservedFlag> flags = const {},
  }) {
    return batchAtUtc([body], utc, flags: flags).single;
  }

  /// Calculates observed positions from a UTC calendar value.
  ///
  /// The native runtime must have Earth-orientation data covering [utc]. This
  /// route uses EOP-backed time scales and celestial-pole offsets.
  List<ObservedPosition> batchAtUtc(
    List<Body> bodies,
    AstroDateTime utc, {
    Set<ObservedFlag> flags = const {},
  }) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      return _calculate(
        bodies,
        flags,
        (arena, bodyIds, bodyCount, mask, output, diagnostics) =>
            _bindings.taiyin_calc_observed_bodies_utc(
              _context,
              calendar,
              bodyIds,
              bodyCount,
              mask,
              output,
              diagnostics,
            ),
      );
    });
  }

  List<ObservedPosition> _calculate(
    List<Body> bodies,
    Set<ObservedFlag> flags,
    _ObservedCalculation calculate,
  ) {
    if (bodies.isEmpty) return const [];
    if (bodies.length > 10) {
      throw ArgumentError.value(
        bodies.length,
        'bodies',
        'must contain at most ten major bodies',
      );
    }
    _validateBodies(bodies);
    _validateFlags(flags);

    final frozenFlags = Set<ObservedFlag>.unmodifiable(flags);
    final mask = frozenFlags.fold(0, (value, flag) => value | flag.mask);
    return using((arena) {
      final bodyIds = arena<Int32>(bodies.length);
      final output = arena<taiyin_observed_position>(bodies.length);
      final diagnostics = arena<taiyin_ephemeris_diagnostic>(bodies.length);
      for (var index = 0; index < bodies.length; index++) {
        bodyIds[index] = bodies[index].id;
        _bindings
          ..taiyin_observed_position_init(output + index)
          ..taiyin_ephemeris_diagnostic_init(diagnostics + index);
      }

      final status = calculate(
        arena,
        bodyIds,
        bodies.length,
        mask,
        output,
        diagnostics,
      );
      if (status != 0) {
        final mapped = [
          for (var index = 0; index < bodies.length; index++)
            _readObservedDiagnostic(diagnostics[index]),
        ];
        final failures = [
          for (final diagnostic in mapped)
            if (diagnostic.status != 0) diagnostic,
        ];
        _checkStatus(status, failures.firstOrNull ?? mapped.first, mapped);
      }

      return List.unmodifiable([
        for (var index = 0; index < bodies.length; index++)
          _readObservedPosition(output[index], bodies[index], frozenFlags),
      ]);
    });
  }

  void _validateBodies(List<Body> bodies) {
    const supported = {
      Body.sun,
      Body.moon,
      Body.mercury,
      Body.venus,
      Body.mars,
      Body.jupiter,
      Body.saturn,
      Body.uranus,
      Body.neptune,
      Body.pluto,
    };
    for (final body in bodies) {
      if (!supported.contains(body)) {
        throw ArgumentError.value(
          body,
          'bodies',
          'observed positions support the ten major bodies only',
        );
      }
    }
  }

  void _validateFlags(Set<ObservedFlag> flags) {
    final wantsHorizontal =
        flags.contains(ObservedFlag.horizontal) ||
        flags.contains(ObservedFlag.refraction);
    if (wantsHorizontal && !flags.contains(ObservedFlag.topocentric)) {
      throw ArgumentError(
        'Horizontal and refracted output require the topocentric flag.',
      );
    }
  }

  ObservedPosition _readObservedPosition(
    taiyin_observed_position value,
    Body body,
    Set<ObservedFlag> flags,
  ) {
    final wantsHorizontal =
        flags.contains(ObservedFlag.horizontal) ||
        flags.contains(ObservedFlag.refraction);
    final wantsSpeed = flags.contains(ObservedFlag.speed);
    final wantsRefraction = flags.contains(ObservedFlag.refraction);
    return ObservedPosition(
      body: body,
      status: value.status,
      diagnostic: _readObservedDiagnostic(value.diagnostic),
      apparent: _readApparentPosition(value.apparent, body),
      flags: flags,
      horizontal: wantsHorizontal ? _readHorizontal(value.horizontal) : null,
      horizontalRates: wantsHorizontal && wantsSpeed
          ? _readHorizontalRates(value.horizontal_rates)
          : null,
      refractedHorizontal: wantsRefraction
          ? _readHorizontal(value.refracted_horizontal)
          : null,
      refractedHorizontalRates: wantsRefraction && wantsSpeed
          ? _readHorizontalRates(value.refracted_horizontal_rates)
          : null,
    );
  }

  ApparentPosition _readApparentPosition(
    taiyin_apparent_position value,
    Body body,
  ) {
    return ApparentPosition(
      body: body,
      bodyMaskBit: value.body_mask_bit,
      status: value.status,
      diagnostic: _readObservedDiagnostic(value.diagnostic),
      geometricState: _readObservedState(value.geometric_state),
      apparentState: _readObservedState(value.apparent_state),
      longitudeRadians: value.longitude_rad,
      latitudeRadians: value.latitude_rad,
      distanceAu: value.distance_au,
      lightTimeDays: value.light_time_days,
      cacheHit: value.cache_hit != 0,
    );
  }

  CartesianState _readObservedState(taiyin_cartesian_state value) {
    return CartesianState(
      positionAu: _readObservedVector(value.position_au),
      velocityAuPerDay: _readObservedVector(value.velocity_au_per_day),
      accelerationAuPerDay2: _readObservedVector(
        value.acceleration_au_per_day2,
      ),
    );
  }

  Vector3 _readObservedVector(taiyin_vector3 value) {
    return Vector3(value.x, value.y, value.z);
  }

  HorizontalCoordinates _readHorizontal(taiyin_horizontal_coordinates value) {
    return HorizontalCoordinates(
      azimuthRadians: value.azimuth_rad,
      altitudeRadians: value.altitude_rad,
      distanceAu: value.distance_au,
    );
  }

  HorizontalRates _readHorizontalRates(taiyin_horizontal_rates value) {
    return HorizontalRates(
      azimuthRadiansPerDay: value.azimuth_rate_rad_per_day,
      altitudeRadiansPerDay: value.altitude_rate_rad_per_day,
      distanceAuPerDay: value.distance_rate_au_per_day,
    );
  }

  EphemerisDiagnostic _readObservedDiagnostic(
    taiyin_ephemeris_diagnostic value,
  ) {
    return _readEphemerisDiagnostic(value);
  }
}
