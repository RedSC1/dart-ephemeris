import '../position/position_api.dart';

/// A built-in sidereal ayanamsha definition.
enum TaiyinAyanamsha {
  faganBradley(0),
  lahiri(1),
  raman(3),
  krishnamurti(5),
  galacticCenter0Sagittarius(17),
  trueChitra(27);

  const TaiyinAyanamsha(this.id);

  /// Stable identifier used by Taiyin's C ABI.
  final int id;
}

/// Relates a historical ayanamsha definition to the selected precession model.
enum TaiyinSiderealPrecessionPolicy {
  compensateToReference(0),
  rawReferenceOffset(1),
  useReferencePrecession(2);

  const TaiyinSiderealPrecessionPolicy(this.id);

  /// Stable identifier used by Taiyin's C ABI.
  final int id;
}

/// A built-in astrological house system.
enum TaiyinHouseSystem {
  wholeSign(0),
  equal(1),
  porphyry(2),
  placidus(3),
  koch(4),
  regiomontanus(5),
  campanus(6),
  alcabitius(7),
  polichPage(8),
  morinus(9);

  const TaiyinHouseSystem(this.id);

  /// Stable identifier used by Taiyin's C ABI.
  final int id;

  static TaiyinHouseSystem? fromIdOrNull(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// A condition reported while calculating time-based astrological houses.
enum TaiyinHouseResultFlag {
  usedFallback(1 << 0),
  fallbackPorphyry(1 << 1),

  /// A UT1/TT calculation could not estimate its time derivatives.
  ///
  /// Direct ARMC calculations have no time coordinate, so their rate fields
  /// are `NaN` without setting this flag.
  speedUnavailable(1 << 2);

  const TaiyinHouseResultFlag(this.mask);

  /// Bit used by Taiyin's C ABI.
  final int mask;
}

/// Tropical and sidereal ecliptic coordinates for one target.
final class TaiyinSiderealPosition {
  TaiyinSiderealPosition({
    required this.target,
    required this.ayanamsha,
    required this.precessionPolicy,
    required this.tropicalLongitudeRadians,
    required this.siderealLongitudeRadians,
    required this.latitudeRadians,
    required this.distanceAu,
    required this.tropicalLongitudeRateRadiansPerDay,
    required this.siderealLongitudeRateRadiansPerDay,
    required Set<TaiyinPositionFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final TaiyinTarget target;
  final TaiyinAyanamsha ayanamsha;
  final TaiyinSiderealPrecessionPolicy precessionPolicy;
  final double tropicalLongitudeRadians;
  final double siderealLongitudeRadians;
  final double latitudeRadians;
  final double distanceAu;
  final double tropicalLongitudeRateRadiansPerDay;
  final double siderealLongitudeRateRadiansPerDay;

  /// Native position options resolved for this ecliptic calculation.
  ///
  /// [TaiyinPositionFlag.radians] is always present. Longitude rates are
  /// available only when this set contains [TaiyinPositionFlag.speed].
  final Set<TaiyinPositionFlag> flags;
}

/// Twelve house cusps and derived angular points.
final class TaiyinHouses {
  TaiyinHouses({
    required this.requestedSystemId,
    required this.resolvedSystemId,
    required this.rawFlags,
    required Set<TaiyinHouseResultFlag> flags,
    required this.armcRadians,
    required this.ascendantRadians,
    required this.midheavenRadians,
    required this.vertexRadians,
    required this.eastPointRadians,
    required this.armcRateRadiansPerDay,
    required this.ascendantRateRadiansPerDay,
    required this.midheavenRateRadiansPerDay,
    required this.vertexRateRadiansPerDay,
    required this.eastPointRateRadiansPerDay,
    required List<double> cuspLongitudesRadians,
    required List<double> cuspLongitudeRatesRadiansPerDay,
  }) : flags = Set.unmodifiable(flags),
       cuspLongitudesRadians = List.unmodifiable(cuspLongitudesRadians),
       cuspLongitudeRatesRadiansPerDay = List.unmodifiable(
         cuspLongitudeRatesRadiansPerDay,
       ) {
    if (cuspLongitudesRadians.length != 12) {
      throw ArgumentError.value(
        cuspLongitudesRadians,
        'cuspLongitudesRadians',
        'must contain twelve house cusps',
      );
    }
    if (cuspLongitudeRatesRadiansPerDay.length != 12) {
      throw ArgumentError.value(
        cuspLongitudeRatesRadiansPerDay,
        'cuspLongitudeRatesRadiansPerDay',
        'must contain twelve house-cusp rates',
      );
    }
  }

  final int requestedSystemId;
  final int resolvedSystemId;
  final int rawFlags;
  final Set<TaiyinHouseResultFlag> flags;
  final double armcRadians;
  final double ascendantRadians;
  final double midheavenRadians;
  final double vertexRadians;
  final double eastPointRadians;
  final double armcRateRadiansPerDay;
  final double ascendantRateRadiansPerDay;
  final double midheavenRateRadiansPerDay;
  final double vertexRateRadiansPerDay;
  final double eastPointRateRadiansPerDay;
  final List<double> cuspLongitudesRadians;
  final List<double> cuspLongitudeRatesRadiansPerDay;

  TaiyinHouseSystem? get requestedSystem =>
      TaiyinHouseSystem.fromIdOrNull(requestedSystemId);
  TaiyinHouseSystem? get resolvedSystem =>
      TaiyinHouseSystem.fromIdOrNull(resolvedSystemId);
}

/// The house containing an ecliptic longitude.
final class TaiyinHousePosition {
  const TaiyinHousePosition({
    required this.houseNumber,
    required this.fraction,
    required this.continuousHousePosition,
  });

  /// One-based house index in the range 1–12.
  final int houseNumber;

  /// Fractional progress from the leading cusp to the next cusp.
  final double fraction;

  /// One-based continuous position, such as `1.5` at the middle of house 1.
  final double continuousHousePosition;
}
