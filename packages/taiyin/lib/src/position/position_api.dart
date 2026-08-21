import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/taiyin_bindings.g.dart';
import '../interop/calendar.dart';
import '../interop/call_result.dart';
import '../interop/julian_date.dart';
import '../result_flags.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_models.dart';
import '../time/time_scale.dart';

part 'position_models.dart';

typedef _SinglePositionCalculation =
    int Function(
      Arena arena,
      int mask,
      Pointer<Double> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _BatchPositionCalculation =
    int Function(
      Arena arena,
      Pointer<Int32> targetIds,
      int targetCount,
      int mask,
      Pointer<Double> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostics,
    );
typedef _StateCalculation =
    int Function(
      Arena arena,
      int mask,
      Pointer<taiyin_cartesian_state> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _PositionStatusChecker =
    ResultFlags Function(int status, EphemerisDiagnostic? diagnostic);

/// Position and Cartesian-state calculations backed by Ephemeris.
///
/// Julian dates cross the native boundary as split `taiyin_split_julian_date`
/// structs, preserving the full day-number/fraction precision. Batch methods
/// return one result per requested body even when individual targets fail;
/// the batch's final diagnostic is published on
/// [EphemerisContext.lastDiagnostic]. Failures that occur before native
/// per-target diagnostics are available still throw.
final class PositionApi {
  /// Internal constructor used by an owning [EphemerisContext].
  PositionApi.internal(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _PositionStatusChecker _checkStatus;

  /// Calculates one body at a TT Julian date.
  OperationResult<Position> atTt(
    Target body,
    JulianDate<TtScale> julianDate, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _position(
      flags,
      (arena, mask, output, diagnostic) => _bindings.taiyin_calc_position_tt(
        _context,
        body.id,
        writeJulianDate(arena, julianDate),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one body at a UT1 Julian date using Taiyin's time policy.
  OperationResult<Position> atUt1(
    Target body,
    JulianDate<Ut1Scale> julianDate, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _position(
      flags,
      (arena, mask, output, diagnostic) => _bindings.taiyin_calc_position_ut(
        _context,
        body.id,
        writeJulianDate(arena, julianDate),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one body with explicit TDB and TT coordinates.
  OperationResult<Position> atTdb(
    Target body,
    JulianDate<TdbScale> tdb,
    JulianDate<TtScale> tt, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _position(
      flags,
      (arena, mask, output, diagnostic) => _bindings.taiyin_calc_position_tdb(
        _context,
        body.id,
        writeJulianDate(arena, tdb),
        writeJulianDate(arena, tt),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one body at UT1 with an explicit TT−UT1 value.
  OperationResult<Position> atUt1WithDeltaT(
    Target body,
    JulianDate<Ut1Scale> julianDate,
    double deltaTSeconds, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _position(
      flags,
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_position_ut_delta_t(
            _context,
            body.id,
            writeJulianDate(arena, julianDate),
            deltaTSeconds,
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates one body from a UTC calendar value.
  OperationResult<Position> atUtc(
    Target body,
    AstroDateTime utc, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      return _position(
        flags,
        (_, mask, output, diagnostic) => _bindings.taiyin_calc_position_utc(
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
  OperationResult<List<Position>> batchAtTt(
    List<Target> bodies,
    JulianDate<TtScale> julianDate, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _positions(
      bodies,
      flags,
      (arena, targetIds, targetCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_positions_tt(
            _context,
            targetIds,
            targetCount,
            writeJulianDate(arena, julianDate),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several bodies at one UT1 Julian date.
  OperationResult<List<Position>> batchAtUt1(
    List<Target> bodies,
    JulianDate<Ut1Scale> julianDate, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _positions(
      bodies,
      flags,
      (arena, targetIds, targetCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_positions_ut(
            _context,
            targetIds,
            targetCount,
            writeJulianDate(arena, julianDate),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several bodies with explicit TDB and TT coordinates.
  OperationResult<List<Position>> batchAtTdb(
    List<Target> bodies,
    JulianDate<TdbScale> tdb,
    JulianDate<TtScale> tt, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _positions(
      bodies,
      flags,
      (arena, targetIds, targetCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_positions_tdb(
            _context,
            targetIds,
            targetCount,
            writeJulianDate(arena, tdb),
            writeJulianDate(arena, tt),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several bodies at UT1 with an explicit TT−UT1 value.
  OperationResult<List<Position>> batchAtUt1WithDeltaT(
    List<Target> bodies,
    JulianDate<Ut1Scale> julianDate,
    double deltaTSeconds, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _positions(
      bodies,
      flags,
      (arena, targetIds, targetCount, mask, output, diagnostics) =>
          _bindings.taiyin_calc_positions_ut_delta_t(
            _context,
            targetIds,
            targetCount,
            writeJulianDate(arena, julianDate),
            deltaTSeconds,
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several bodies from one UTC calendar value.
  OperationResult<List<Position>> batchAtUtc(
    List<Target> bodies,
    AstroDateTime utc, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      return _positions(
        bodies,
        flags,
        (_, targetIds, targetCount, mask, output, diagnostics) =>
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
  ///
  /// Cartesian position, velocity, and acceleration are always returned, so
  /// [PositionFlag.xyz] and [PositionFlag.speed] are implied and
  /// have no effect. Frame and apparent-correction flags still apply.
  OperationResult<CartesianState> stateAtTt(
    Target body,
    JulianDate<TtScale> julianDate, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _state(
      flags,
      (arena, mask, output, diagnostic) => _bindings.taiyin_calc_state_tt(
        _context,
        body.id,
        writeJulianDate(arena, julianDate),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates a Cartesian state at a UT1 Julian date.
  ///
  /// Position and derivative flags behave as described by [stateAtTt].
  OperationResult<CartesianState> stateAtUt1(
    Target body,
    JulianDate<Ut1Scale> julianDate, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _state(
      flags,
      (arena, mask, output, diagnostic) => _bindings.taiyin_calc_state_ut(
        _context,
        body.id,
        writeJulianDate(arena, julianDate),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates a Cartesian state with explicit TDB and TT coordinates.
  ///
  /// Position and derivative flags behave as described by [stateAtTt].
  OperationResult<CartesianState> stateAtTdb(
    Target body,
    JulianDate<TdbScale> tdb,
    JulianDate<TtScale> tt, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _state(
      flags,
      (arena, mask, output, diagnostic) => _bindings.taiyin_calc_state_tdb(
        _context,
        body.id,
        writeJulianDate(arena, tdb),
        writeJulianDate(arena, tt),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates a Cartesian state at UT1 with an explicit TT−UT1 value.
  ///
  /// Position and derivative flags behave as described by [stateAtTt].
  OperationResult<CartesianState> stateAtUt1WithDeltaT(
    Target body,
    JulianDate<Ut1Scale> julianDate,
    double deltaTSeconds, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _state(
      flags,
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_state_ut_delta_t(
            _context,
            body.id,
            writeJulianDate(arena, julianDate),
            deltaTSeconds,
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates a Cartesian state from a UTC calendar value.
  ///
  /// Position and derivative flags behave as described by [stateAtTt].
  OperationResult<CartesianState> stateAtUtc(
    Target body,
    AstroDateTime utc, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      return _state(
        flags,
        (_, mask, output, diagnostic) => _bindings.taiyin_calc_state_utc(
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

  OperationResult<Position> _position(
    Set<PositionFlag> flags,
    _SinglePositionCalculation calculate,
  ) {
    final frozenFlags = Set<PositionFlag>.unmodifiable(flags);
    final mask = _flagMask(frozenFlags);
    return using((arena) {
      final output = arena<Double>(6);
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, mask, output, diagnostic);
      final mappedDiagnostic = _readDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      return operationResult(
        Position._([
          for (var index = 0; index < 6; index++) output[index],
        ], frozenFlags),
        resultFlags,
      );
    });
  }

  OperationResult<List<Position>> _positions(
    List<Target> bodies,
    Set<PositionFlag> flags,
    _BatchPositionCalculation calculate,
  ) {
    if (bodies.isEmpty) {
      return operationResult(const <Position>[], ResultFlags.none);
    }
    final frozenFlags = Set<PositionFlag>.unmodifiable(flags);
    final mask = _flagMask(frozenFlags);
    return using((arena) {
      final targetIds = arena<Int32>(bodies.length);
      final output = arena<Double>(bodies.length * 6);
      final diagnostics = arena<taiyin_ephemeris_diagnostic>(bodies.length);
      for (var index = 0; index < bodies.length; index++) {
        targetIds[index] = bodies[index].id;
        _bindings.taiyin_ephemeris_diagnostic_init(diagnostics + index);
      }
      final rawResult = calculate(
        arena,
        targetIds,
        bodies.length,
        mask,
        output,
        diagnostics,
      );
      final elementDiagnostics = [
        for (var bodyIndex = 0; bodyIndex < bodies.length; bodyIndex++)
          _readDiagnostic(diagnostics[bodyIndex]),
      ];
      final decoded = decodeNativeCallResult(rawResult);
      if (decoded.status != 0 &&
          !elementDiagnostics.any((diagnostic) => diagnostic.status != 0)) {
        _checkStatus(rawResult, null);
      }
      // Publish the batch's final diagnostic without converting a per-target
      // failure into a whole-batch exception.
      final resultFlags = _checkStatus(
        decoded.flags.mask,
        elementDiagnostics.last,
      );
      return operationResult(
        List<Position>.unmodifiable([
          for (var bodyIndex = 0; bodyIndex < bodies.length; bodyIndex++)
            Position._([
              for (var valueIndex = 0; valueIndex < 6; valueIndex++)
                output[bodyIndex * 6 + valueIndex],
            ], frozenFlags),
        ]),
        resultFlags,
      );
    });
  }

  OperationResult<CartesianState> _state(
    Set<PositionFlag> flags,
    _StateCalculation calculate,
  ) {
    final mask = _flagMask(flags);
    return using((arena) {
      final output = arena<taiyin_cartesian_state>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_cartesian_state_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, mask, output, diagnostic);
      final mappedDiagnostic = _readDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      final state = output.ref;
      return operationResult(
        CartesianState(
          positionAu: _readVector(state.position_au),
          velocityAuPerDay: _readVector(state.velocity_au_per_day),
          accelerationAuPerDay2: _readVector(state.acceleration_au_per_day2),
        ),
        resultFlags,
      );
    });
  }

  EphemerisDiagnostic _readDiagnostic(taiyin_ephemeris_diagnostic value) {
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

  Vector3 _readVector(taiyin_vector3 value) {
    return Vector3(value.x, value.y, value.z);
  }

  int _flagMask(Set<PositionFlag> flags) {
    return flags.fold(0, (value, flag) => value | flag.mask);
  }

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }
}
