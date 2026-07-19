import '../position/position_api.dart';

/// Options for an observed-position calculation.
enum TaiyinObservedFlag {
  /// Calculate velocity and horizontal-coordinate rates.
  speed(1 << 0),

  /// Apply the context's topocentric observer.
  topocentric(1 << 1),

  /// Calculate azimuth, altitude, and distance.
  ///
  /// This requires [topocentric] and an observer location in the context.
  horizontal(1 << 2),

  /// Calculate refracted horizontal coordinates.
  ///
  /// This requires [topocentric], an observer location, and usable atmosphere
  /// data. Horizontal coordinates are calculated even when [horizontal] is
  /// omitted.
  refraction(1 << 3),

  /// Return the geometric position without light-time or apparent corrections.
  truePosition(1 << 4),

  /// Apply light-time but omit aberration, deflection, and Shapiro delay.
  astrometric(1 << 5),

  /// Disable aberration in the apparent-position path.
  noAberration(1 << 6),

  /// Disable gravitational deflection in the apparent-position path.
  noGravitationalDeflection(1 << 7),

  /// Do not use standard-atmosphere fallback for refraction.
  strictMeteorology(1 << 32);

  const TaiyinObservedFlag(this.mask);

  /// The bit used by the Taiyin C ABI.
  final int mask;
}

/// Horizontal coordinates in radians and astronomical units.
final class TaiyinHorizontalCoordinates {
  const TaiyinHorizontalCoordinates({
    required this.azimuthRadians,
    required this.altitudeRadians,
    required this.distanceAu,
  });

  final double azimuthRadians;
  final double altitudeRadians;
  final double distanceAu;
}

/// Time derivatives of horizontal coordinates.
final class TaiyinHorizontalRates {
  const TaiyinHorizontalRates({
    required this.azimuthRadiansPerDay,
    required this.altitudeRadiansPerDay,
    required this.distanceAuPerDay,
  });

  final double azimuthRadiansPerDay;
  final double altitudeRadiansPerDay;
  final double distanceAuPerDay;
}

/// Geometric and apparent state for one major solar-system body.
final class TaiyinApparentPosition {
  const TaiyinApparentPosition({
    required this.body,
    required this.bodyMaskBit,
    required this.status,
    required this.diagnostic,
    required this.geometricState,
    required this.apparentState,
    required this.longitudeRadians,
    required this.latitudeRadians,
    required this.distanceAu,
    required this.lightTimeDays,
    required this.cacheHit,
  });

  final TaiyinBody body;
  final int bodyMaskBit;
  final int status;
  final TaiyinEphemerisDiagnostic diagnostic;
  final TaiyinCartesianState geometricState;
  final TaiyinCartesianState apparentState;
  final double longitudeRadians;
  final double latitudeRadians;
  final double distanceAu;
  final double lightTimeDays;
  final bool cacheHit;
}

/// A complete observed position for one major solar-system body.
final class TaiyinObservedPosition {
  TaiyinObservedPosition({
    required this.body,
    required this.status,
    required this.diagnostic,
    required this.apparent,
    required Set<TaiyinObservedFlag> flags,
    this.horizontal,
    this.horizontalRates,
    this.refractedHorizontal,
    this.refractedHorizontalRates,
  }) : flags = Set.unmodifiable(flags);

  final TaiyinBody body;
  final int status;
  final TaiyinEphemerisDiagnostic diagnostic;
  final TaiyinApparentPosition apparent;
  final Set<TaiyinObservedFlag> flags;

  /// Unrefracted horizontal coordinates, when horizontal output was requested.
  final TaiyinHorizontalCoordinates? horizontal;

  /// Unrefracted horizontal rates, when horizontal output and speed were
  /// requested.
  final TaiyinHorizontalRates? horizontalRates;

  /// Refracted horizontal coordinates, when refraction was requested.
  final TaiyinHorizontalCoordinates? refractedHorizontal;

  /// Refracted horizontal rates, when refraction and speed were requested.
  final TaiyinHorizontalRates? refractedHorizontalRates;
}
