import '../observed/observed_models.dart';
import '../position/position_api.dart';

/// The six values returned by a fixed-star position calculation.
///
/// Values 0–2 are the primary coordinates. Values 3–5 are their rates when
/// [PositionFlag.speed] is requested. Their coordinate system and units
/// are described by [flags].
final class StarPosition {
  StarPosition({
    required this.starKey,
    required List<double> values,
    required Set<PositionFlag> flags,
  }) : values = List.unmodifiable(values),
       flags = Set.unmodifiable(flags) {
    if (values.length != 6) {
      throw ArgumentError.value(values, 'values', 'must contain six values');
    }
  }

  final String starKey;
  final List<double> values;
  final Set<PositionFlag> flags;

  List<double> get coordinates => values.sublist(0, 3);
  List<double> get rates => values.sublist(3, 6);
  bool get isCartesian => flags.contains(PositionFlag.xyz);
  bool get isEquatorial => flags.contains(PositionFlag.equatorial);
  bool get isRadians => flags.contains(PositionFlag.radians);

  @override
  String toString() => 'StarPosition($starKey, $values)';
}

/// Geometric and apparent state for one fixed star.
final class ApparentStarPosition {
  const ApparentStarPosition({
    required this.starKey,
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

  final String starKey;
  final int status;
  final EphemerisDiagnostic diagnostic;
  final CartesianState geometricState;
  final CartesianState apparentState;
  final double longitudeRadians;
  final double latitudeRadians;
  final double distanceAu;
  final double lightTimeDays;
  final bool cacheHit;
}

/// A complete observed position for one fixed star.
final class ObservedStarPosition {
  ObservedStarPosition({
    required this.starKey,
    required this.status,
    required this.diagnostic,
    required this.apparent,
    required Set<ObservedFlag> flags,
    this.horizontal,
    this.horizontalRates,
    this.refractedHorizontal,
    this.refractedHorizontalRates,
  }) : flags = Set.unmodifiable(flags);

  final String starKey;
  final int status;
  final EphemerisDiagnostic diagnostic;
  final ApparentStarPosition apparent;
  final Set<ObservedFlag> flags;
  final HorizontalCoordinates? horizontal;
  final HorizontalRates? horizontalRates;
  final HorizontalCoordinates? refractedHorizontal;
  final HorizontalRates? refractedHorizontalRates;
}
