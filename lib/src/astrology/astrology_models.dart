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

/// The output reference frame used by a generic sidereal-coordinate result.
///
/// The ecliptic variant has a sidereal origin. Equatorial variants follow the
/// conventional Swiss Ephemeris-compatible behavior and are tropical
/// mean/true equators of date instead.
enum TaiyinSiderealCoordinateFrame {
  meanEclipticOfDate(0),
  meanEquatorOfDate(1),
  trueEquatorOfDate(2),
  unknown(-1);

  const TaiyinSiderealCoordinateFrame(this.id);

  /// Stable identifier returned by Taiyin's C ABI.
  final int id;

  static TaiyinSiderealCoordinateFrame fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
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

  /// Tropical ecliptic longitude in radians.
  final double tropicalLongitudeRadians;

  /// Sidereal ecliptic longitude in radians.
  final double siderealLongitudeRadians;

  /// Ecliptic latitude in radians.
  final double latitudeRadians;

  /// Distance in astronomical units.
  final double distanceAu;

  /// Tropical ecliptic-longitude rate in radians per day.
  ///
  /// This is `double.nan` unless [flags] contains
  /// [TaiyinPositionFlag.speed]. This result intentionally contains longitude
  /// rates only, not latitude or distance rates.
  final double tropicalLongitudeRateRadiansPerDay;

  /// Sidereal ecliptic-longitude rate in radians per day.
  ///
  /// This is `double.nan` unless [flags] contains
  /// [TaiyinPositionFlag.speed]. This result intentionally contains longitude
  /// rates only, not latitude or distance rates.
  final double siderealLongitudeRateRadiansPerDay;

  /// Native position options resolved for this ecliptic calculation.
  ///
  /// [TaiyinPositionFlag.radians] is always present. Longitude rates are
  /// available only when this set contains [TaiyinPositionFlag.speed].
  final Set<TaiyinPositionFlag> flags;
}

/// Generic sidereal coordinates in a sidereal ecliptic or tropical equatorial
/// frame.
///
/// [values] use the usual six-value position convention. Without
/// [TaiyinPositionFlag.xyz], values 0–2 are longitude/right ascension,
/// latitude/declination, and distance; values 3–5 are the corresponding rates
/// when [TaiyinPositionFlag.speed] is present. With `xyz`, they are Cartesian
/// position and velocity. The Dart API always adds
/// [TaiyinPositionFlag.radians], so angular spherical values are always in
/// radians. Without [TaiyinPositionFlag.speed], values 3–5 are `0.0`, as in
/// the generic native-position convention; this differs from
/// [TaiyinSiderealPosition], whose unavailable rate fields are `double.nan`.
/// Without
/// [TaiyinPositionFlag.equatorial], the frame is sidereal mean ecliptic of
/// date. With it, the result follows Swiss Ephemeris-compatible behavior:
/// tropical mean equator of date with [TaiyinPositionFlag.noNutation], or
/// tropical true equator of date without it.
final class TaiyinSiderealCoordinates {
  TaiyinSiderealCoordinates({
    required this.target,
    required this.ayanamsha,
    required this.precessionPolicy,
    required this.coordinateFrame,
    required this.rawCoordinateFrameId,
    required List<double> values,
    required Set<TaiyinPositionFlag> flags,
  }) : values = List.unmodifiable(values),
       flags = Set.unmodifiable(flags) {
    if (values.length != 6) {
      throw ArgumentError.value(values, 'values', 'must contain six values');
    }
  }

  final TaiyinTarget target;
  final TaiyinAyanamsha ayanamsha;
  final TaiyinSiderealPrecessionPolicy precessionPolicy;

  /// Output coordinate frame used by these values.
  final TaiyinSiderealCoordinateFrame coordinateFrame;

  /// Unrecognized C ABI coordinate-frame ID, if any.
  ///
  /// This preserves a future native frame ID even when this Dart package has
  /// not yet added a corresponding enum value.
  final int rawCoordinateFrameId;

  final List<double> values;

  /// Resolved native position options for this calculation.
  ///
  /// This always includes [TaiyinPositionFlag.radians].
  final Set<TaiyinPositionFlag> flags;

  List<double> get coordinates => values.sublist(0, 3);

  /// Velocity or angular-rate slots, or three `0.0` values without `speed`.
  List<double> get rates => values.sublist(3, 6);
  bool get isCartesian => flags.contains(TaiyinPositionFlag.xyz);
  bool get isEquatorial => flags.contains(TaiyinPositionFlag.equatorial);
  bool get isRadians => flags.contains(TaiyinPositionFlag.radians);

  @override
  String toString() => 'TaiyinSiderealCoordinates($values)';
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

  /// Twelve ecliptic cusp longitudes in radians.
  ///
  /// This is a zero-indexed list: index `i` is the cusp of house `i + 1`.
  final List<double> cuspLongitudesRadians;

  /// Ecliptic cusp-longitude rates in radians per day.
  ///
  /// This is zero-indexed in the same way as [cuspLongitudesRadians]. Values
  /// are `NaN` for direct ARMC calculations and when
  /// [TaiyinHouseResultFlag.speedUnavailable] is set.
  final List<double> cuspLongitudeRatesRadiansPerDay;

  TaiyinHouseSystem? get requestedSystem =>
      TaiyinHouseSystem.fromIdOrNull(requestedSystemId);
  TaiyinHouseSystem? get resolvedSystem =>
      TaiyinHouseSystem.fromIdOrNull(resolvedSystemId);
}

/// The house containing an ecliptic longitude.
final class TaiyinHousePosition {
  TaiyinHousePosition({
    required this.houseNumber,
    required this.fraction,
    required this.continuousHousePosition,
  }) {
    if (houseNumber < 1 || houseNumber > 12) {
      throw RangeError.range(houseNumber, 1, 12, 'houseNumber');
    }
    if (!fraction.isFinite || fraction < 0 || fraction >= 1) {
      throw RangeError.range(fraction, 0, 1, 'fraction', 'must be in [0, 1)');
    }
    if (!continuousHousePosition.isFinite ||
        continuousHousePosition < 1 ||
        continuousHousePosition >= 13) {
      throw RangeError.range(
        continuousHousePosition,
        1,
        13,
        'continuousHousePosition',
        'must be in [1, 13)',
      );
    }
  }

  /// One-based house index in the range 1–12.
  final int houseNumber;

  /// Fractional progress from the leading cusp to the next cusp.
  final double fraction;

  /// One-based continuous position, such as `1.5` at the middle of house 1.
  final double continuousHousePosition;
}
