part of 'position_api.dart';

/// A calculation target understood by Taiyin.
abstract interface class TaiyinTarget {
  int get id;
}

/// A solar-system body built into Taiyin.
enum TaiyinBody implements TaiyinTarget {
  solarSystemBarycenter(0),
  mercuryBarycenter(1),
  venusBarycenter(2),
  earthMoonBarycenter(3),
  marsBarycenter(4),
  jupiterBarycenter(5),
  saturnBarycenter(6),
  uranusBarycenter(7),
  neptuneBarycenter(8),
  plutoBarycenter(9),
  sun(10),
  mercury(199),
  venus(299),
  moon(301),
  earth(399),
  mars(499),
  jupiter(599),
  saturn(699),
  uranus(799),
  neptune(899),
  pluto(999);

  const TaiyinBody(this.id);

  /// The stable body ID from the Taiyin C ABI.
  @override
  final int id;
}

/// A process-wide custom calculation target backed by a Dart evaluator.
final class TaiyinCustomTarget implements TaiyinTarget {
  TaiyinCustomTarget(int id) : id = _validateId(id);

  @override
  final int id;

  static int _validateId(int id) {
    if (id >= 0 || id < -0x80000000) {
      throw ArgumentError.value(
        id,
        'id',
        'must fit the native signed 32-bit range and be negative',
      );
    }
    return id;
  }

  @override
  bool operator ==(Object other) =>
      other is TaiyinCustomTarget && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TaiyinCustomTarget($id)';
}

/// Modifiers for a position or Cartesian-state calculation.
enum TaiyinPositionFlag {
  speed(1 << 0),
  xyz(1 << 1),
  equatorial(1 << 2),
  radians(1 << 3),
  truePosition(1 << 4),
  noAberration(1 << 5),
  noGravitationalDeflection(1 << 6),
  astrometric(1 << 7),
  noNutation(1 << 8),
  topocentric(1 << 9),
  allowBarycenterApproximation(1 << 10);

  const TaiyinPositionFlag(this.mask);

  /// The bit used by the Taiyin C ABI.
  final int mask;
}

/// Reference frame reported by an ephemeris diagnostic.
enum TaiyinApparentFrame {
  icrf(0),
  trueEquatorOfDate(1),
  trueEclipticOfDate(2),
  j2000MeanEquator(3),
  j2000Ecliptic(4),
  meanEquatorOfDate(5),
  meanEclipticOfDate(6),
  cirs(7),
  unknown(-1);

  const TaiyinApparentFrame(this.id);

  final int id;

  static TaiyinApparentFrame fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

/// The six values returned by a Taiyin position calculation.
///
/// Values 0–2 are the primary coordinates. Values 3–5 are their rates when
/// [TaiyinPositionFlag.speed] is requested. Their coordinate system and units
/// are described by [flags].
final class TaiyinPosition {
  TaiyinPosition._(List<double> values, Set<TaiyinPositionFlag> flags)
    : values = List.unmodifiable(values),
      flags = Set.unmodifiable(flags) {
    if (values.length != 6) {
      throw ArgumentError.value(values, 'values', 'must contain six values');
    }
  }

  final List<double> values;
  final Set<TaiyinPositionFlag> flags;

  List<double> get coordinates => values.sublist(0, 3);
  List<double> get rates => values.sublist(3, 6);
  bool get isCartesian => flags.contains(TaiyinPositionFlag.xyz);
  bool get isEquatorial => flags.contains(TaiyinPositionFlag.equatorial);
  bool get isRadians => flags.contains(TaiyinPositionFlag.radians);

  @override
  String toString() => 'TaiyinPosition($values)';
}

/// A three-dimensional vector.
final class TaiyinVector3 {
  const TaiyinVector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  List<double> get values => List.unmodifiable([x, y, z]);

  @override
  String toString() => 'TaiyinVector3($x, $y, $z)';
}

/// Cartesian position, velocity, and acceleration returned by Taiyin.
final class TaiyinCartesianState {
  const TaiyinCartesianState({
    required this.positionAu,
    required this.velocityAuPerDay,
    required this.accelerationAuPerDay2,
  });

  final TaiyinVector3 positionAu;
  final TaiyinVector3 velocityAuPerDay;
  final TaiyinVector3 accelerationAuPerDay2;
}

/// Details about the route used for an ephemeris calculation.
final class TaiyinEphemerisDiagnostic {
  TaiyinEphemerisDiagnostic({
    required this.status,
    required this.targetId,
    required this.centerId,
    required this.frame,
    required this.rawFrameId,
    required this.julianDateTdb,
    required this.candidateCount,
    required this.attemptedMethodId,
    required this.nearestCoverageStart,
    required this.nearestCoverageEnd,
    required this.componentTargetId,
    required this.componentCenterId,
    required this.componentMethodId,
    required this.timeScaleRoute,
    required this.rawTimeScaleRouteId,
    required this.timeScaleFallbackReason,
    required this.rawTimeScaleFallbackReasonId,
    required Set<TimeScaleDiagnosticFlag> timeScaleFlags,
    required this.taiMinusUtcSeconds,
    required this.dut1Seconds,
    required this.deltaTSeconds,
  }) : timeScaleFlags = Set.unmodifiable(timeScaleFlags);

  final int status;
  final int targetId;
  final int centerId;
  final TaiyinApparentFrame frame;
  final int rawFrameId;
  final JulianDate<TdbScale> julianDateTdb;
  final int candidateCount;
  final int attemptedMethodId;
  final double nearestCoverageStart;
  final double nearestCoverageEnd;
  final int componentTargetId;
  final int componentCenterId;
  final int componentMethodId;
  final TimeScaleRoute timeScaleRoute;
  final int rawTimeScaleRouteId;
  final TimeScaleFallbackReason timeScaleFallbackReason;
  final int rawTimeScaleFallbackReasonId;
  final Set<TimeScaleDiagnosticFlag> timeScaleFlags;
  final double taiMinusUtcSeconds;
  final double dut1Seconds;
  final double deltaTSeconds;
}

/// A calculated value together with its native ephemeris diagnostic.
final class TaiyinEphemerisResult<T> {
  const TaiyinEphemerisResult({required this.value, required this.diagnostic});

  final T value;
  final TaiyinEphemerisDiagnostic diagnostic;
}
