import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../backend/backend_call.dart';
import '../backend/position_backend.dart';
import '../bindings/taiyin_bindings.g.dart';
import '../interop/calendar.dart';
import '../interop/call_result.dart';
import '../interop/julian_date.dart';
import '../time/time_models.dart';
import '../time/time_scale.dart';
import 'position_models.dart';

/// Native marshalling only. Public method selection, flag snapshots, result
/// construction, atomic batch semantics and completion live in PositionApi.
final class NativePositionBackend implements PositionBackend {
  NativePositionBackend(this._bindings, this._context);
  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;

  @override
  BackendCall<List<double>> position(
    int target,
    PositionTime time,
    int flags,
  ) => using((arena) {
    final output = arena<Double>(6);
    final diag = arena<taiyin_ephemeris_diagnostic>();
    _bindings.taiyin_ephemeris_diagnostic_init(diag);
    final raw = _positionCall(arena, target, time, flags, output, diag);
    final decoded = decodeNativeCallResult(raw);
    return BackendCall(
      status: decoded.status,
      flags: decoded.flags,
      value: [for (var i = 0; i < 6; i++) output[i]],
      diagnostic: _readDiagnostic(diag.ref),
    );
  });

  @override
  BackendCall<List<List<double>>> positions(
    List<int> targets,
    PositionTime time,
    int flags,
  ) => using((arena) {
    final ids = arena<Int32>(targets.length);
    final output = arena<Double>(targets.length * 6);
    final diags = arena<taiyin_ephemeris_diagnostic>(targets.length);
    for (var i = 0; i < targets.length; i++) {
      ids[i] = targets[i];
      _bindings.taiyin_ephemeris_diagnostic_init(diags + i);
    }
    final raw = _positionsCall(
      arena,
      ids,
      targets.length,
      time,
      flags,
      output,
      diags,
    );
    final decoded = decodeNativeCallResult(raw);
    return BackendCall(
      status: decoded.status,
      flags: decoded.flags,
      value: [
        for (var i = 0; i < targets.length; i++)
          [for (var k = 0; k < 6; k++) output[i * 6 + k]],
      ],
      diagnostics: [
        for (var i = 0; i < targets.length; i++) _readDiagnostic(diags[i]),
      ],
    );
  });

  @override
  BackendCall<CartesianState> state(int target, PositionTime time, int flags) =>
      using((arena) {
        final output = arena<taiyin_cartesian_state>();
        final diag = arena<taiyin_ephemeris_diagnostic>();
        _bindings.taiyin_cartesian_state_init(output);
        _bindings.taiyin_ephemeris_diagnostic_init(diag);
        final raw = _stateCall(arena, target, time, flags, output, diag);
        final decoded = decodeNativeCallResult(raw);
        final v = output.ref;
        return BackendCall(
          status: decoded.status,
          flags: decoded.flags,
          value: CartesianState(
            positionAu: _readVector(v.position_au),
            velocityAuPerDay: _readVector(v.velocity_au_per_day),
            accelerationAuPerDay2: _readVector(v.acceleration_au_per_day2),
          ),
          diagnostic: _readDiagnostic(diag.ref),
        );
      });

  int _positionCall(
    Arena arena,
    int target,
    PositionTime time,
    int flags,
    Pointer<Double> output,
    Pointer<taiyin_ephemeris_diagnostic> diagnostic,
  ) {
    switch (time.kind) {
      case PositionTimeKind.tt:
        return _bindings.taiyin_calc_position_tt(
          _context,
          target,
          writeJulianDate(arena, time.date!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.ut1:
        return _bindings.taiyin_calc_position_ut(
          _context,
          target,
          writeJulianDate(arena, time.date!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.tdb:
        return _bindings.taiyin_calc_position_tdb(
          _context,
          target,
          writeJulianDate(arena, time.date!),
          writeJulianDate(arena, time.tt!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.ut1WithDeltaT:
        return _bindings.taiyin_calc_position_ut_delta_t(
          _context,
          target,
          writeJulianDate(arena, time.date!),
          time.deltaT,
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.utc:
        return _bindings.taiyin_calc_position_utc(
          _context,
          target,
          writeNativeCalendar(_bindings, arena, time.utc!),
          flags,
          output,
          diagnostic,
        );
    }
  }

  int _positionsCall(
    Arena arena,
    Pointer<Int32> targets,
    int count,
    PositionTime time,
    int flags,
    Pointer<Double> output,
    Pointer<taiyin_ephemeris_diagnostic> diagnostic,
  ) {
    switch (time.kind) {
      case PositionTimeKind.tt:
        return _bindings.taiyin_calc_positions_tt(
          _context,
          targets,
          count,
          writeJulianDate(arena, time.date!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.ut1:
        return _bindings.taiyin_calc_positions_ut(
          _context,
          targets,
          count,
          writeJulianDate(arena, time.date!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.tdb:
        return _bindings.taiyin_calc_positions_tdb(
          _context,
          targets,
          count,
          writeJulianDate(arena, time.date!),
          writeJulianDate(arena, time.tt!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.ut1WithDeltaT:
        return _bindings.taiyin_calc_positions_ut_delta_t(
          _context,
          targets,
          count,
          writeJulianDate(arena, time.date!),
          time.deltaT,
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.utc:
        return _bindings.taiyin_calc_positions_utc(
          _context,
          targets,
          count,
          writeNativeCalendar(_bindings, arena, time.utc!),
          flags,
          output,
          diagnostic,
        );
    }
  }

  int _stateCall(
    Arena arena,
    int target,
    PositionTime time,
    int flags,
    Pointer<taiyin_cartesian_state> output,
    Pointer<taiyin_ephemeris_diagnostic> diagnostic,
  ) {
    switch (time.kind) {
      case PositionTimeKind.tt:
        return _bindings.taiyin_calc_state_tt(
          _context,
          target,
          writeJulianDate(arena, time.date!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.ut1:
        return _bindings.taiyin_calc_state_ut(
          _context,
          target,
          writeJulianDate(arena, time.date!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.tdb:
        return _bindings.taiyin_calc_state_tdb(
          _context,
          target,
          writeJulianDate(arena, time.date!),
          writeJulianDate(arena, time.tt!),
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.ut1WithDeltaT:
        return _bindings.taiyin_calc_state_ut_delta_t(
          _context,
          target,
          writeJulianDate(arena, time.date!),
          time.deltaT,
          flags,
          output,
          diagnostic,
        );
      case PositionTimeKind.utc:
        return _bindings.taiyin_calc_state_utc(
          _context,
          target,
          writeNativeCalendar(_bindings, arena, time.utc!),
          flags,
          output,
          diagnostic,
        );
    }
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
}
