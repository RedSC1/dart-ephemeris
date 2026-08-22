import '../position/position_api.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// The requested extremum of a body's distance from its physical primary.
enum ApsisKind {
  pericenter(0),
  apocenter(1);

  const ApsisKind(this.id);

  /// Stable value used by the Taiyin C ABI.
  final int id;

  static ApsisKind fromId(int id) {
    return values.firstWhere(
      (value) => value.id == id,
      orElse: () => throw StateError('Unknown Ephemeris apsis kind: $id'),
    );
  }
}

/// The requested crossing direction through an orbital reference plane.
enum PlaneNodeKind {
  ascending(0),
  descending(1);

  const PlaneNodeKind(this.id);

  /// Stable value used by the Taiyin C ABI.
  final int id;

  static PlaneNodeKind fromId(int id) {
    return values.firstWhere(
      (value) => value.id == id,
      orElse: () => throw StateError('Unknown Ephemeris node kind: $id'),
    );
  }
}

/// Direction in which an orbital-event search advances from its start.
enum OrbitalSearchDirection { forward, reverse }

/// Model used to construct instantaneous orbital reference points.
enum OrbitReferencePointModel {
  osculating(0),
  unknown(-1);

  const OrbitReferencePointModel(this.id);

  final int id;

  static OrbitReferencePointModel fromId(int id) {
    return values.firstWhere((value) => value.id == id, orElse: () => unknown);
  }
}

/// One geometric point on an instantaneous two-body orbit.
final class OrbitReferencePoint {
  const OrbitReferencePoint({
    required this.positionAu,
    required this.longitudeRadians,
    required this.latitudeRadians,
    required this.distanceAu,
  });

  final Vector3 positionAu;
  final double longitudeRadians;
  final double latitudeRadians;
  final double distanceAu;
}

/// Classical osculating elements relative to a body's fixed physical primary.
final class OsculatingOrbit {
  const OsculatingOrbit({
    required this.body,
    required this.center,
    required this.referenceFrame,
    required this.rawReferenceFrameId,
    required this.gravitationalParameterAu3PerDay2,
    required this.semiMajorAxisAu,
    required this.eccentricity,
    required this.inclinationRadians,
    required this.longitudeOfAscendingNodeRadians,
    required this.argumentOfPeriapsisRadians,
    required this.trueAnomalyRadians,
    required this.meanAnomalyRadians,
    required this.periapsisDistanceAu,
    required this.apoapsisDistanceAu,
    required this.osculatingPeriodDays,
    required this.currentDistanceAu,
    required this.radialVelocityAuPerDay,
    required this.allowBarycenterApproximation,
  });

  final Body body;
  final Body center;
  final ApparentFrame referenceFrame;
  final int rawReferenceFrameId;
  final double gravitationalParameterAu3PerDay2;
  final double semiMajorAxisAu;
  final double eccentricity;
  final double inclinationRadians;
  final double longitudeOfAscendingNodeRadians;
  final double argumentOfPeriapsisRadians;
  final double trueAnomalyRadians;
  final double meanAnomalyRadians;
  final double periapsisDistanceAu;
  final double apoapsisDistanceAu;
  final double osculatingPeriodDays;
  final double currentDistanceAu;
  final double radialVelocityAuPerDay;
  final bool allowBarycenterApproximation;
}

/// Geometric nodes, apsides, and second focus of an osculating orbit.
///
/// These are points on the orbit fitted at the requested epoch, not searches
/// for future or past passages through those points.
final class OrbitReferencePoints {
  const OrbitReferencePoints({
    required this.body,
    required this.center,
    required this.referenceFrame,
    required this.rawReferenceFrameId,
    required this.model,
    required this.rawModelId,
    required this.ascendingNode,
    required this.descendingNode,
    required this.periapsis,
    required this.apoapsis,
    required this.secondFocus,
    required this.allowBarycenterApproximation,
  });

  final Body body;
  final Body center;
  final ApparentFrame referenceFrame;
  final int rawReferenceFrameId;
  final OrbitReferencePointModel model;
  final int rawModelId;
  final OrbitReferencePoint ascendingNode;
  final OrbitReferencePoint descendingNode;
  final OrbitReferencePoint periapsis;
  final OrbitReferencePoint apoapsis;
  final OrbitReferencePoint secondFocus;
  final bool allowBarycenterApproximation;
}

/// A searched pericenter or apocenter in a typed astronomical time scale.
final class ApsisEvent<S extends TimeScale> {
  const ApsisEvent({
    required this.body,
    required this.center,
    required this.kind,
    required this.coordinate,
    required this.distanceAu,
    required this.radialVelocityAuPerDay,
    required this.iterationCount,
    required this.evaluationCount,
    required this.direction,
    required this.allowBarycenterApproximation,
  });

  final Body body;
  final Body center;
  final ApsisKind kind;

  /// Event coordinate returned by the native scalar-JD search.
  final JulianDate<S> coordinate;

  final double distanceAu;
  final double radialVelocityAuPerDay;
  final int iterationCount;
  final int evaluationCount;
  final OrbitalSearchDirection direction;
  final bool allowBarycenterApproximation;
}

/// A searched crossing of a selected orbital reference plane.
final class PlaneNodeEvent<S extends TimeScale> {
  const PlaneNodeEvent({
    required this.body,
    required this.center,
    required this.referenceFrame,
    required this.rawReferenceFrameId,
    required this.kind,
    required this.coordinate,
    required this.referencePlaneAngleRadians,
    required this.distanceAu,
    required this.iterationCount,
    required this.evaluationCount,
    required this.direction,
    required this.allowBarycenterApproximation,
  });

  final Body body;
  final Body center;
  final ApparentFrame referenceFrame;
  final int rawReferenceFrameId;
  final PlaneNodeKind kind;

  /// Event coordinate returned by the native scalar-JD search.
  final JulianDate<S> coordinate;

  /// Longitude in an ecliptic frame or right-ascension direction in an
  /// equatorial frame.
  final double referencePlaneAngleRadians;

  final double distanceAu;
  final int iterationCount;
  final int evaluationCount;
  final OrbitalSearchDirection direction;
  final bool allowBarycenterApproximation;
}
