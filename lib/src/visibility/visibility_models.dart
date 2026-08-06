import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// Event requested from a rise/set or meridian-transit visibility search.
enum VisibilityEventKind {
  rise(1),
  set(2),
  upperTransit(3),
  lowerTransit(4);

  const VisibilityEventKind(this.id);

  /// Stable value used by the Taiyin C ABI.
  final int id;

  bool get isRiseOrSet => this == rise || this == set;
  bool get isTransit => this == upperTransit || this == lowerTransit;
}

/// Apparent limb used for a rise or set search.
enum VisibilityLimb {
  upper(1),
  center(2),
  lower(3);

  const VisibilityLimb(this.id);

  /// Stable value used by the Taiyin C ABI.
  final int id;
}

/// Solar depression convention used for a twilight search.
enum TwilightKind {
  civil(1),
  nautical(2),
  astronomical(3);

  const TwilightKind(this.id);

  /// Stable value used by the Taiyin C ABI.
  final int id;
}

/// Classification of a target altitude over a requested search interval.
enum VisibilityAltitudeState {
  notFound(0),
  crosses(1),
  alwaysAbove(2),
  alwaysBelow(3),
  tangent(4),
  unknown(-1);

  const VisibilityAltitudeState(this.id);

  final int id;

  static VisibilityAltitudeState fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

/// Direction of the altitude crossing reported by a visibility search.
enum VisibilityCrossingDirection {
  any(0),
  rising(1),
  setting(2),
  unknown(-1);

  const VisibilityCrossingDirection(this.id);

  final int id;

  static VisibilityCrossingDirection fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

/// Options for rise/set visibility searches.
///
/// With an empty set, native rise/set searches use atmospheric refraction by
/// default. Pass [noRefraction] to explicitly disable it. [fixedDiscSize] is
/// available for solar and lunar searches only; planet and star searches
/// reject it because their native implementations always use physical discs.
enum VisibilityFlag {
  refraction(1 << 0),
  fixedDiscSize(1 << 1),
  noRefraction(1 << 2),
  strictMeteorology(1 << 32);

  const VisibilityFlag(this.mask);

  /// Bit used by the Taiyin C ABI.
  final int mask;
}

/// The result of a UT1 visibility search.
///
/// A successful search need not find an event: [coordinate] is `null` for
/// [VisibilityAltitudeState.alwaysAbove],
/// [VisibilityAltitudeState.alwaysBelow], or a non-localizable result.
final class VisibilityEvent {
  const VisibilityEvent({
    required this.requestedEvent,
    required this.altitudeState,
    required this.crossingDirection,
    required this.coordinate,
    required this.residualRadians,
    required this.minimumResidualRadians,
    required this.maximumResidualRadians,
    required this.minimumResidualCoordinate,
    required this.maximumResidualCoordinate,
    required this.sampleCount,
    required this.refineCount,
  });

  final VisibilityEventKind requestedEvent;
  final VisibilityAltitudeState altitudeState;
  final VisibilityCrossingDirection crossingDirection;

  /// UT1 coordinate of the located event, or `null` when none was located.
  final JulianDate<Ut1Scale>? coordinate;

  /// Altitude residual at [coordinate], in radians.
  final double residualRadians;
  final double minimumResidualRadians;
  final double maximumResidualRadians;
  final JulianDate<Ut1Scale>? minimumResidualCoordinate;
  final JulianDate<Ut1Scale>? maximumResidualCoordinate;
  final int sampleCount;
  final int refineCount;

  bool get isFound => coordinate != null;

  @override
  String toString() {
    return 'VisibilityEvent($requestedEvent, $altitudeState, '
        '$coordinate)';
  }
}

/// Approximate solar rise and set times around a TT date.
///
/// [rise] and [set] are `null` when the corresponding event does not occur
/// near the requested date.
final class SolarRiseSetFastResult {
  const SolarRiseSetFastResult({
    required this.altitudeState,
    required this.rise,
    required this.set,
    required this.sampleCount,
    required this.refineCount,
  });

  final VisibilityAltitudeState altitudeState;
  final JulianDate<TtScale>? rise;
  final JulianDate<TtScale>? set;
  final int sampleCount;
  final int refineCount;
}

/// Approximate solar meridian transit near a TT date.
final class SolarTransitFastResult {
  const SolarTransitFastResult({
    required this.coordinate,
    required this.altitudeRadians,
    required this.azimuthRadians,
    required this.sampleCount,
    required this.refineCount,
  });

  final JulianDate<TtScale>? coordinate;
  final double altitudeRadians;
  final double azimuthRadians;
  final int sampleCount;
  final int refineCount;
}
