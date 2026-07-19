import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/taiyin_bindings.g.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_models.dart';
import '../time/time_scale.dart';
import 'position_models.dart';

typedef _SinglePositionCalculation =
    int Function(
      int mask,
      Pointer<Double> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _BatchPositionCalculation =
    int Function(
      Pointer<Int32> targetIds,
      int targetCount,
      int mask,
      Pointer<Double> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostics,
    );
typedef _StateCalculation =
    int Function(
      int mask,
      Pointer<taiyin_cartesian_state> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );

/// Position and Cartesian-state calculations backed by Taiyin.
final class TaiyinPositionApi {
  /// Internal constructor used by an owning Taiyin context.
  TaiyinPositionApi.internal(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final void Function(int status) _checkStatus;

  /// Calculates one body at a TT Julian date.
  TaiyinEphemerisResult<TaiyinPosition> atTt(
    TaiyinBody body,
    JulianDate<TtScale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _position(
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_position_tt(
        _context,
        body.id,
        julianDate.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one body at a UT1 Julian date using Taiyin's time policy.
  TaiyinEphemerisResult<TaiyinPosition> atUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _position(
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_position_ut(
        _context,
        body.id,
        julianDate.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one body with explicit TDB and TT coordinates.
  TaiyinEphemerisResult<TaiyinPosition> atTdb(
    TaiyinBody body,
    JulianDate<TdbScale> tdb,
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _position(
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_position_tdb(
        _context,
        body.id,
        tdb.toDouble(),
        tt.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one body at UT1 with an explicit TT−UT1 value.
  TaiyinEphemerisResult<TaiyinPosition> atUt1WithDeltaT(
    TaiyinBody body,
    JulianDate<Ut1Scale> julianDate,
    double deltaTSeconds, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _position(
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_position_ut_delta_t(
        _context,
        body.id,
        julianDate.toDouble(),
        deltaTSeconds,
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one body from a UTC calendar value.
  TaiyinEphemerisResult<TaiyinPosition> atUtc(
    TaiyinBody body,
    AstroDateTime utc, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return using((arena) {
      final calendar = _writeCalendar(arena, utc);
      return _position(
        flags,
        (mask, output, diagnostic) => _bindings.taiyin_calc_position_utc(
          _context,
          body.id,
          calendar,
          mask,
          output,
          diagnostic,
        ),
      );
    });
  }

  /// Calculates several bodies at one TT Julian date.
  List<TaiyinEphemerisResult<TaiyinPosition>> batchAtTt(
    List<TaiyinBody> bodies,
    JulianDate<TtScale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _positions(
      bodies,
      flags,
      (targetIds, targetCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_positions_tt(
            _context,
            targetIds,
            targetCount,
            julianDate.toDouble(),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several bodies at one UT1 Julian date.
  List<TaiyinEphemerisResult<TaiyinPosition>> batchAtUt1(
    List<TaiyinBody> bodies,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _positions(
      bodies,
      flags,
      (targetIds, targetCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_positions_ut(
            _context,
            targetIds,
            targetCount,
            julianDate.toDouble(),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several bodies with explicit TDB and TT coordinates.
  List<TaiyinEphemerisResult<TaiyinPosition>> batchAtTdb(
    List<TaiyinBody> bodies,
    JulianDate<TdbScale> tdb,
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _positions(
      bodies,
      flags,
      (targetIds, targetCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_positions_tdb(
            _context,
            targetIds,
            targetCount,
            tdb.toDouble(),
            tt.toDouble(),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several bodies at UT1 with an explicit TT−UT1 value.
  List<TaiyinEphemerisResult<TaiyinPosition>> batchAtUt1WithDeltaT(
    List<TaiyinBody> bodies,
    JulianDate<Ut1Scale> julianDate,
    double deltaTSeconds, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _positions(
      bodies,
      flags,
      (targetIds, targetCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_positions_ut_delta_t(
            _context,
            targetIds,
            targetCount,
            julianDate.toDouble(),
            deltaTSeconds,
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several bodies from one UTC calendar value.
  List<TaiyinEphemerisResult<TaiyinPosition>> batchAtUtc(
    List<TaiyinBody> bodies,
    AstroDateTime utc, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return using((arena) {
      final calendar = _writeCalendar(arena, utc);
      return _positions(
        bodies,
        flags,
        (targetIds, targetCount, mask, output, diagnostics) =>
            _bindings.taiyin_calc_positions_utc(
              _context,
              targetIds,
              targetCount,
              calendar,
              mask,
              output,
              diagnostics,
            ),
      );
    });
  }

  /// Calculates a Cartesian state at a TT Julian date.
  TaiyinEphemerisResult<TaiyinCartesianState> stateAtTt(
    TaiyinBody body,
    JulianDate<TtScale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _state(
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_state_tt(
        _context,
        body.id,
        julianDate.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates a Cartesian state at a UT1 Julian date.
  TaiyinEphemerisResult<TaiyinCartesianState> stateAtUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _state(
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_state_ut(
        _context,
        body.id,
        julianDate.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates a Cartesian state with explicit TDB and TT coordinates.
  TaiyinEphemerisResult<TaiyinCartesianState> stateAtTdb(
    TaiyinBody body,
    JulianDate<TdbScale> tdb,
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    return _state(
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_state_tdb(
        _context,
        body.id,
        tdb.toDouble(),
        tt.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates a Cartesian state at UT1 with an explicit TT−UT1 value.
  TaiyinEphemerisResult<TaiyinCartesianState> stateAtUt1WithDeltaT(
    TaiyinBody body,
    JulianDate<Ut1Scale> julianDate,
    double deltaTSeconds, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _state(
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_state_ut_delta_t(
        _context,
        body.id,
        julianDate.toDouble(),
        deltaTSeconds,
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates a Cartesian state from a UTC calendar value.
  TaiyinEphemerisResult<TaiyinCartesianState> stateAtUtc(
    TaiyinBody body,
    AstroDateTime utc, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return using((arena) {
      final calendar = _writeCalendar(arena, utc);
      return _state(
        flags,
        (mask, output, diagnostic) => _bindings.taiyin_calc_state_utc(
          _context,
          body.id,
          calendar,
          mask,
          output,
          diagnostic,
        ),
      );
    });
  }

  TaiyinEphemerisResult<TaiyinPosition> _position(
    Set<TaiyinPositionFlag> flags,
    _SinglePositionCalculation calculate,
  ) {
    _ensureOpen();
    final frozenFlags = Set<TaiyinPositionFlag>.unmodifiable(flags);
    final mask = _flagMask(frozenFlags);
    return using((arena) {
      final output = arena<Double>(6);
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      _checkStatus(calculate(mask, output, diagnostic));
      return TaiyinEphemerisResult(
        value: TaiyinPosition([
          for (var index = 0; index < 6; index++) output[index],
        ], frozenFlags),
        diagnostic: _readDiagnostic(diagnostic.ref),
      );
    });
  }

  List<TaiyinEphemerisResult<TaiyinPosition>> _positions(
    List<TaiyinBody> bodies,
    Set<TaiyinPositionFlag> flags,
    _BatchPositionCalculation calculate,
  ) {
    _ensureOpen();
    if (bodies.isEmpty) return const [];
    final frozenFlags = Set<TaiyinPositionFlag>.unmodifiable(flags);
    final mask = _flagMask(frozenFlags);
    return using((arena) {
      final targetIds = arena<Int32>(bodies.length);
      final output = arena<Double>(bodies.length * 6);
      final diagnostics = arena<taiyin_ephemeris_diagnostic>(bodies.length);
      for (var index = 0; index < bodies.length; index++) {
        targetIds[index] = bodies[index].id;
        _bindings.taiyin_ephemeris_diagnostic_init(diagnostics + index);
      }
      _checkStatus(
        calculate(targetIds, bodies.length, mask, output, diagnostics),
      );
      return List.unmodifiable([
        for (var bodyIndex = 0; bodyIndex < bodies.length; bodyIndex++)
          TaiyinEphemerisResult(
            value: TaiyinPosition([
              for (var valueIndex = 0; valueIndex < 6; valueIndex++)
                output[bodyIndex * 6 + valueIndex],
            ], frozenFlags),
            diagnostic: _readDiagnostic(diagnostics[bodyIndex]),
          ),
      ]);
    });
  }

  TaiyinEphemerisResult<TaiyinCartesianState> _state(
    Set<TaiyinPositionFlag> flags,
    _StateCalculation calculate,
  ) {
    _ensureOpen();
    final mask = _flagMask(flags);
    return using((arena) {
      final output = arena<taiyin_cartesian_state>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_cartesian_state_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      _checkStatus(calculate(mask, output, diagnostic));
      final state = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinCartesianState(
          positionAu: _readVector(state.position_au),
          velocityAuPerDay: _readVector(state.velocity_au_per_day),
          accelerationAuPerDay2: _readVector(state.acceleration_au_per_day2),
        ),
        diagnostic: _readDiagnostic(diagnostic.ref),
      );
    });
  }

  Pointer<taiyin_calendar_datetime> _writeCalendar(
    Arena arena,
    AstroDateTime value,
  ) {
    if (value.year < -2147483648 || value.year > 2147483647) {
      throw RangeError.range(value.year, -2147483648, 2147483647, 'year');
    }
    final native = arena<taiyin_calendar_datetime>();
    _bindings.taiyin_calendar_datetime_init(native);
    native.ref
      ..year = value.year
      ..month = value.month
      ..day = value.day
      ..hour = value.hour
      ..minute = value.minute
      ..second = value.fractionalSecond;
    return native;
  }

  TaiyinEphemerisDiagnostic _readDiagnostic(taiyin_ephemeris_diagnostic value) {
    final timeScaleFlags = {
      for (final flag in TimeScaleDiagnosticFlag.values)
        if (value.time_scale_flags & flag.mask != 0) flag,
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

  TaiyinVector3 _readVector(taiyin_vector3 value) {
    return TaiyinVector3(value.x, value.y, value.z);
  }

  int _flagMask(Set<TaiyinPositionFlag> flags) {
    return flags.fold(0, (value, flag) => value | flag.mask);
  }

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }
}
