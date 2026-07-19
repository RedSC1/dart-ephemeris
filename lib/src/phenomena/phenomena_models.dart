import '../position/position_api.dart';

/// Observer origin used for a body-phenomena calculation.
enum TaiyinPhenomenaOrigin {
  /// Evaluate observer-dependent quantities from the geocenter.
  geocentric,

  /// Evaluate observer-dependent quantities from the context's observer.
  topocentric,
}

/// Phase, illumination, angular size, and brightness of a solar-system body.
final class TaiyinBodyPhenomena {
  TaiyinBodyPhenomena({
    required this.body,
    required this.phaseAngleRadians,
    required this.illuminatedFraction,
    required this.solarElongationRadians,
    required this.apparentDiameterRadians,
    required this.apparentMagnitude,
    required this.geocentricHorizontalParallaxRadians,
    required this.origin,
    required Set<TaiyinPositionFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final TaiyinBody body;
  final double phaseAngleRadians;
  final double illuminatedFraction;
  final double solarElongationRadians;
  final double apparentDiameterRadians;
  final double apparentMagnitude;

  /// Geocentric horizontal parallax for the Moon, otherwise `null`.
  ///
  /// This remains geocentric even when [origin] is
  /// [TaiyinPhenomenaOrigin.topocentric].
  final double? geocentricHorizontalParallaxRadians;

  /// Observer origin used for phase, elongation, diameter, and magnitude.
  final TaiyinPhenomenaOrigin origin;

  /// Position-route flags used by the native phenomena calculation.
  ///
  /// Observer origin is represented separately by [origin], so this set never
  /// contains [TaiyinPositionFlag.topocentric].
  final Set<TaiyinPositionFlag> flags;
}
