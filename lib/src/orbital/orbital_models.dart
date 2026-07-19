import '../position/position_api.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// The requested extremum of a body's distance from its physical primary.
enum TaiyinApsisKind {
  pericenter(0),
  apocenter(1);

  const TaiyinApsisKind(this.id);

  /// Stable value used by the Taiyin C ABI.
  final int id;

  static TaiyinApsisKind fromId(int id) {
    return values.firstWhere(
      (value) => value.id == id,
      orElse: () => throw StateError('Unknown Taiyin apsis kind: $id'),
    );
  }
}

/// The requested crossing direction through an orbital reference plane.
enum TaiyinPlaneNodeKind {
  ascending(0),
  descending(1);

  const TaiyinPlaneNodeKind(this.id);

  /// Stable value used by the Taiyin C ABI.
  final int id;

  static TaiyinPlaneNodeKind fromId(int id) {
    return values.firstWhere(
      (value) => value.id == id,
      orElse: () => throw StateError('Unknown Taiyin node kind: $id'),
    );
  }
}

/// Direction in which an orbital-event search advances from its start.
enum TaiyinOrbitalSearchDirection { forward, reverse }

/// Model used to construct instantaneous orbital reference points.
enum TaiyinOrbitReferencePointModel {
  osculating(0),
  unknown(-1);

  const TaiyinOrbitReferencePointModel(this.id);

  final int id;

  static TaiyinOrbitReferencePointModel fromId(int id) {
    return values.firstWhere((value) => value.id == id, orElse: () => unknown);
  }
}

/// One geometric point on an instantaneous two-body orbit.
final class TaiyinOrbitReferencePoint {
  const TaiyinOrbitReferencePoint({
    required this.positionAu,
    required this.longitudeRadians,
    required this.latitudeRadians,
    required this.distanceAu,
  });

  final TaiyinVector3 positionAu;
  final double longitudeRadians;
  final double latitudeRadians;
  final double distanceAu;
}

/// Classical osculating elements relative to a body's fixed physical primary.
final class TaiyinOsculatingOrbit {
  const TaiyinOsculatingOrbit({
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

  final TaiyinBody body;
  final TaiyinBody center;
  final TaiyinApparentFrame referenceFrame;
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
final class TaiyinOrbitReferencePoints {
  const TaiyinOrbitReferencePoints({
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

  final TaiyinBody body;
  final TaiyinBody center;
  final TaiyinApparentFrame referenceFrame;
  final int rawReferenceFrameId;
  final TaiyinOrbitReferencePointModel model;
  final int rawModelId;
  final TaiyinOrbitReferencePoint ascendingNode;
  final TaiyinOrbitReferencePoint descendingNode;
  final TaiyinOrbitReferencePoint periapsis;
  final TaiyinOrbitReferencePoint apoapsis;
  final TaiyinOrbitReferencePoint secondFocus;
  final bool allowBarycenterApproximation;
}

/// A searched pericenter or apocenter in a typed astronomical time scale.
final class TaiyinApsisEvent<S extends TimeScale> {
  const TaiyinApsisEvent({
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

  final TaiyinBody body;
  final TaiyinBody center;
  final TaiyinApsisKind kind;

  /// Event coordinate returned by the native scalar-JD search.
  final JulianDate<S> coordinate;

  final double distanceAu;
  final double radialVelocityAuPerDay;
  final int iterationCount;
  final int evaluationCount;
  final TaiyinOrbitalSearchDirection direction;
  final bool allowBarycenterApproximation;
}

/// A searched crossing of a selected orbital reference plane.
final class TaiyinPlaneNodeEvent<S extends TimeScale> {
  const TaiyinPlaneNodeEvent({
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

  final TaiyinBody body;
  final TaiyinBody center;
  final TaiyinApparentFrame referenceFrame;
  final int rawReferenceFrameId;
  final TaiyinPlaneNodeKind kind;

  /// Event coordinate returned by the native scalar-JD search.
  final JulianDate<S> coordinate;

  /// Longitude in an ecliptic frame or right-ascension direction in an
  /// equatorial frame.
  final double referencePlaneAngleRadians;

  final double distanceAu;
  final int iterationCount;
  final int evaluationCount;
  final TaiyinOrbitalSearchDirection direction;
  final bool allowBarycenterApproximation;
}
