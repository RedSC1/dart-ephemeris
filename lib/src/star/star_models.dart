import '../observed/observed_models.dart';
import '../position/position_api.dart';

/// The six values returned by a fixed-star position calculation.
///
/// Values 0–2 are the primary coordinates. Values 3–5 are their rates when
/// [TaiyinPositionFlag.speed] is requested. Their coordinate system and units
/// are described by [flags].
final class TaiyinStarPosition {
  TaiyinStarPosition({
    required this.starKey,
    required List<double> values,
    required Set<TaiyinPositionFlag> flags,
  }) : values = List.unmodifiable(values),
       flags = Set.unmodifiable(flags) {
    if (values.length != 6) {
      throw ArgumentError.value(values, 'values', 'must contain six values');
    }
  }

  final String starKey;
  final List<double> values;
  final Set<TaiyinPositionFlag> flags;

  List<double> get coordinates => values.sublist(0, 3);
  List<double> get rates => values.sublist(3, 6);
  bool get isCartesian => flags.contains(TaiyinPositionFlag.xyz);
  bool get isEquatorial => flags.contains(TaiyinPositionFlag.equatorial);
  bool get isRadians => flags.contains(TaiyinPositionFlag.radians);

  @override
  String toString() => 'TaiyinStarPosition($starKey, $values)';
}

/// Geometric and apparent state for one fixed star.
final class TaiyinApparentStarPosition {
  const TaiyinApparentStarPosition({
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
  final TaiyinEphemerisDiagnostic diagnostic;
  final TaiyinCartesianState geometricState;
  final TaiyinCartesianState apparentState;
  final double longitudeRadians;
  final double latitudeRadians;
  final double distanceAu;
  final double lightTimeDays;
  final bool cacheHit;
}

/// A complete observed position for one fixed star.
final class TaiyinObservedStarPosition {
  TaiyinObservedStarPosition({
    required this.starKey,
    required this.status,
    required this.diagnostic,
    required this.apparent,
    required Set<TaiyinObservedFlag> flags,
    this.horizontal,
    this.horizontalRates,
    this.refractedHorizontal,
    this.refractedHorizontalRates,
  }) : flags = Set.unmodifiable(flags);

  final String starKey;
  final int status;
  final TaiyinEphemerisDiagnostic diagnostic;
  final TaiyinApparentStarPosition apparent;
  final Set<TaiyinObservedFlag> flags;
  final TaiyinHorizontalCoordinates? horizontal;
  final TaiyinHorizontalRates? horizontalRates;
  final TaiyinHorizontalCoordinates? refractedHorizontal;
  final TaiyinHorizontalRates? refractedHorizontalRates;
}
