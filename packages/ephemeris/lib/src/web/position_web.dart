import '../backend/backend_call.dart';
import '../backend/position_backend.dart';
import '../position/position_models.dart';
import '../result_flags.dart';
import '../time/julian_date.dart';
import '../time/time_models.dart';
import 'wasm_module.dart';

/// Web transport only; the public PositionApi is shared with native builds.
final class WebPositionBackend implements PositionBackend {
  WebPositionBackend(this._backend, this._handle);
  final WasmBackend _backend;
  final int _handle;

  @override
  BackendCall<List<double>> position(int target, PositionTime time, int flags) {
    final reply = _backend.position(
      _handle,
      false,
      _payload(target, time, flags),
    );
    return BackendCall(
      status: reply.status,
      flags: ResultFlags(reply.values[0].toInt()),
      value: reply.values.sublist(1, 7),
      diagnostic: _diagnostic(reply),
    );
  }

  @override
  BackendCall<CartesianState> state(int target, PositionTime time, int flags) {
    final reply = _backend.position(
      _handle,
      true,
      _payload(target, time, flags),
    );
    final v = reply.values;
    return BackendCall(
      status: reply.status,
      flags: ResultFlags(v[0].toInt()),
      value: CartesianState(
        positionAu: Vector3(v[1], v[2], v[3]),
        velocityAuPerDay: Vector3(v[4], v[5], v[6]),
        accelerationAuPerDay2: Vector3(v[7], v[8], v[9]),
      ),
      diagnostic: _diagnostic(reply),
    );
  }

  @override
  BackendCall<List<List<double>>> positions(
    List<int> targets,
    PositionTime time,
    int flags,
  ) {
    final reply = _backend.positions(
      _handle,
      targets,
      _payload(0, time, flags),
    );
    return BackendCall(
      status: reply.status,
      flags: ResultFlags(reply.values.first[0].toInt()),
      value: [for (final values in reply.values) values.sublist(1, 7)],
      diagnostics: [
        for (final values in reply.values)
          _diagnostic((status: reply.status, values: values)),
      ],
    );
  }

  List<num> _payload(int target, PositionTime time, int flags) {
    for (final date in [time.date, time.tt]) {
      if (date != null &&
          (date.dayNumber < -9007199254740991 ||
              date.dayNumber > 9007199254740991)) {
        throw RangeError(
          'Julian day must be exactly representable at the JS boundary.',
        );
      }
    }
    final utc = time.utc;
    return [
      time.kind.index,
      target,
      time.date?.dayNumber ?? 0,
      time.date?.dayFraction ?? 0,
      time.tt?.dayNumber ?? 0,
      time.tt?.dayFraction ?? 0,
      time.deltaT,
      flags,
      utc?.year ?? 0,
      utc?.month ?? 0,
      utc?.day ?? 0,
      utc?.hour ?? 0,
      utc?.minute ?? 0,
      utc?.fractionalSecond ?? 0,
    ];
  }

  EphemerisDiagnostic _diagnostic(WasmReply reply) {
    final v = reply.values;
    return EphemerisDiagnostic(
      status: v[10].toInt(),
      targetId: v[11].toInt(),
      centerId: v[12].toInt(),
      frame: ApparentFrame.fromId(v[13].toInt()),
      rawFrameId: v[13].toInt(),
      julianDateTdb: TdbJulianDate.fromParts(v[14].toInt(), v[15]),
      candidateCount: v[16].toInt(),
      attemptedMethodId: v[17].toInt(),
      nearestCoverageStart: v[18],
      nearestCoverageEnd: v[19],
      componentTargetId: v[20].toInt(),
      componentCenterId: v[21].toInt(),
      componentMethodId: v[22].toInt(),
      timeScaleRoute: TimeScaleRoute.fromId(v[23].toInt()),
      rawTimeScaleRouteId: v[23].toInt(),
      timeScaleFallbackReason: TimeScaleFallbackReason.fromId(v[24].toInt()),
      rawTimeScaleFallbackReasonId: v[24].toInt(),
      timeScaleFlags: {
        for (final f in TimeScaleDiagnosticFlag.values)
          if (v[25].toInt() & f.mask != 0) f,
      },
      taiMinusUtcSeconds: v[26],
      dut1Seconds: v[27],
      deltaTSeconds: v[28],
    );
  }
}
