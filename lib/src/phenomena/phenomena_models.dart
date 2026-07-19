import '../position/position_api.dart';

/// Phase, illumination, angular size, and brightness of a solar-system body.
final class TaiyinBodyPhenomena {
  TaiyinBodyPhenomena({
    required this.body,
    required this.phaseAngleRadians,
    required this.illuminatedFraction,
    required this.solarElongationRadians,
    required this.apparentDiameterRadians,
    required this.apparentMagnitude,
    required this.horizontalParallaxRadians,
    required Set<TaiyinPositionFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final TaiyinBody body;
  final double phaseAngleRadians;
  final double illuminatedFraction;
  final double solarElongationRadians;
  final double apparentDiameterRadians;
  final double apparentMagnitude;

  /// Geocentric horizontal parallax for the Moon, otherwise `null`.
  final double? horizontalParallaxRadians;

  /// Position-route flags used by the native phenomena calculation.
  final Set<TaiyinPositionFlag> flags;
}
