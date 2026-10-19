import '../position/position_models.dart';
import '../time/julian_date.dart';
import '../time/time_models.dart';

EphemerisDiagnostic readWebDiagnostic(List<double> v) {
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
