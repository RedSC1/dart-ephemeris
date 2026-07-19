part of '../taiyin.dart';

typedef _ObservedCalculation =
    int Function(
      Pointer<Int32> bodyIds,
      int bodyCount,
      int mask,
      Pointer<taiyin_observed_position> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostics,
    );
typedef _ObservedStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);

/// Apparent and observed positions for major solar-system bodies.
///
/// Native observed-position batches contain at most ten bodies. Horizontal
/// output requires [TaiyinObservedFlag.topocentric] and a context observer
/// location. See [TaiyinContextApi] for observer and atmosphere configuration.
final class TaiyinObservedApi {
  TaiyinObservedApi._(
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
  TaiyinObservedPosition atUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinObservedFlag> flags = const {},
  }) {
    return batchAtUt1([body], julianDate, flags: flags).single;
  }

  /// Calculates observed positions at a UT1 Julian date.
  List<TaiyinObservedPosition> batchAtUt1(
    List<TaiyinBody> bodies,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinObservedFlag> flags = const {},
  }) {
    _ensureOpen();
    return _calculate(
      bodies,
      flags,
      (bodyIds, bodyCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_observed_bodies_ut(
            _context,
            julianDate.toDouble(),
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
  /// The native runtime must have Earth-orientation data covering [utc].
  TaiyinObservedPosition atUtc(
    TaiyinBody body,
    AstroDateTime utc, {
    Set<TaiyinObservedFlag> flags = const {},
  }) {
    return batchAtUtc([body], utc, flags: flags).single;
  }

  /// Calculates observed positions from a UTC calendar value.
  ///
  /// The native runtime must have Earth-orientation data covering [utc].
  List<TaiyinObservedPosition> batchAtUtc(
    List<TaiyinBody> bodies,
    AstroDateTime utc, {
    Set<TaiyinObservedFlag> flags = const {},
  }) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      return _calculate(
        bodies,
        flags,
        (bodyIds, bodyCount, mask, output, diagnostics) =>
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

  List<TaiyinObservedPosition> _calculate(
    List<TaiyinBody> bodies,
    Set<TaiyinObservedFlag> flags,
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

    final frozenFlags = Set<TaiyinObservedFlag>.unmodifiable(flags);
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
        final diagnostic = mapped.firstWhere(
          (value) => value.status != 0,
          orElse: () => mapped.first,
        );
        _checkStatus(status, diagnostic);
      }

      return List.unmodifiable([
        for (var index = 0; index < bodies.length; index++)
          _readObservedPosition(output[index], bodies[index], frozenFlags),
      ]);
    });
  }

  void _validateBodies(List<TaiyinBody> bodies) {
    const supported = {
      TaiyinBody.sun,
      TaiyinBody.moon,
      TaiyinBody.mercury,
      TaiyinBody.venus,
      TaiyinBody.mars,
      TaiyinBody.jupiter,
      TaiyinBody.saturn,
      TaiyinBody.uranus,
      TaiyinBody.neptune,
      TaiyinBody.pluto,
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

  void _validateFlags(Set<TaiyinObservedFlag> flags) {
    final wantsHorizontal =
        flags.contains(TaiyinObservedFlag.horizontal) ||
        flags.contains(TaiyinObservedFlag.refraction);
    if (wantsHorizontal && !flags.contains(TaiyinObservedFlag.topocentric)) {
      throw ArgumentError(
        'Horizontal and refracted output require the topocentric flag.',
      );
    }
  }

  TaiyinObservedPosition _readObservedPosition(
    taiyin_observed_position value,
    TaiyinBody body,
    Set<TaiyinObservedFlag> flags,
  ) {
    final wantsHorizontal =
        flags.contains(TaiyinObservedFlag.horizontal) ||
        flags.contains(TaiyinObservedFlag.refraction);
    final wantsSpeed = flags.contains(TaiyinObservedFlag.speed);
    final wantsRefraction = flags.contains(TaiyinObservedFlag.refraction);
    return TaiyinObservedPosition(
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

  TaiyinApparentPosition _readApparentPosition(
    taiyin_apparent_position value,
    TaiyinBody body,
  ) {
    return TaiyinApparentPosition(
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

  TaiyinCartesianState _readObservedState(taiyin_cartesian_state value) {
    return TaiyinCartesianState(
      positionAu: _readObservedVector(value.position_au),
      velocityAuPerDay: _readObservedVector(value.velocity_au_per_day),
      accelerationAuPerDay2: _readObservedVector(
        value.acceleration_au_per_day2,
      ),
    );
  }

  TaiyinVector3 _readObservedVector(taiyin_vector3 value) {
    return TaiyinVector3(value.x, value.y, value.z);
  }

  TaiyinHorizontalCoordinates _readHorizontal(
    taiyin_horizontal_coordinates value,
  ) {
    return TaiyinHorizontalCoordinates(
      azimuthRadians: value.azimuth_rad,
      altitudeRadians: value.altitude_rad,
      distanceAu: value.distance_au,
    );
  }

  TaiyinHorizontalRates _readHorizontalRates(taiyin_horizontal_rates value) {
    return TaiyinHorizontalRates(
      azimuthRadiansPerDay: value.azimuth_rate_rad_per_day,
      altitudeRadiansPerDay: value.altitude_rate_rad_per_day,
      distanceAuPerDay: value.distance_rate_au_per_day,
    );
  }

  TaiyinEphemerisDiagnostic _readObservedDiagnostic(
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
      julianDateTdb: value.jd_tdb,
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
}
