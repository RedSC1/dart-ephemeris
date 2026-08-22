import 'julian_date.dart';
import 'time_scale.dart';

enum TdbModel {
  fastPeriodic(0),
  sofaFull(1);

  const TdbModel(this.id);
  final int id;
}

enum DeltaTModel {
  estimatedDefault(0);

  const DeltaTModel(this.id);
  final int id;
}

enum EphemerisFamily {
  unknown(0),
  de431(431),
  de441(441);

  const EphemerisFamily(this.id);
  final int id;
}

enum TimeScaleRoute {
  none(0),
  preciseUtcEop(1),
  estimatedDeltaT(2),
  unknown(-1);

  const TimeScaleRoute(this.id);
  final int id;

  static TimeScaleRoute fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

enum TimeScaleFallbackReason {
  none(0),
  missingEopTable(1),
  eopOutOfRange(2),
  leapSecondUnavailable(3),
  unknown(-1);

  const TimeScaleFallbackReason(this.id);
  final int id;

  static TimeScaleFallbackReason fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

enum TimeScaleDiagnosticFlag {
  usedLeapSeconds(1 << 0),
  usedEop(1 << 1),
  usedDeltaTModel(1 << 2);

  const TimeScaleDiagnosticFlag(this.mask);
  final int mask;
}

final class PreciseTimeScales {
  const PreciseTimeScales({
    required this.utc,
    required this.tai,
    required this.tt,
    required this.ut1,
    required this.tdb,
    required this.taiMinusUtcSeconds,
    required this.dut1Seconds,
    required this.deltaTSeconds,
  });

  final JulianDate<UtcScale> utc;
  final JulianDate<TaiScale> tai;
  final JulianDate<TtScale> tt;
  final JulianDate<Ut1Scale> ut1;
  final JulianDate<TdbScale> tdb;
  final double taiMinusUtcSeconds;
  final double dut1Seconds;
  final double deltaTSeconds;
}

final class EstimatedTimeScales {
  const EstimatedTimeScales({
    required this.ut1,
    required this.tt,
    required this.tdb,
    required this.deltaTSeconds,
  });

  final JulianDate<Ut1Scale> ut1;
  final JulianDate<TtScale> tt;
  final JulianDate<TdbScale> tdb;
  final double deltaTSeconds;
}

final class TimeScaleDiagnostic {
  TimeScaleDiagnostic({
    required this.route,
    required this.rawRouteId,
    required this.fallbackReason,
    required this.rawFallbackReasonId,
    required Set<TimeScaleDiagnosticFlag> flags,
    required this.tdbModelId,
    required this.deltaTModelId,
    required this.ephemerisFamilyId,
    required this.taiMinusUtcSeconds,
    required this.dut1Seconds,
    required this.deltaTSeconds,
  }) : flags = Set.unmodifiable(flags);

  final TimeScaleRoute route;
  final int rawRouteId;
  final TimeScaleFallbackReason fallbackReason;
  final int rawFallbackReasonId;
  final Set<TimeScaleDiagnosticFlag> flags;
  final int tdbModelId;
  final int deltaTModelId;
  final int ephemerisFamilyId;
  final double taiMinusUtcSeconds;
  final double dut1Seconds;
  final double deltaTSeconds;
}

final class TimeScaleResult<T> {
  const TimeScaleResult({required this.value, required this.diagnostic});

  final T value;
  final TimeScaleDiagnostic diagnostic;
}
