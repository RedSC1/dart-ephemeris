import '../position/position_api.dart';

/// An ayanamsha definition recognized by the process-wide native registry.
abstract interface class TaiyinAyanamshaModel {
  /// Stable identifier used by Taiyin's C ABI.
  int get id;
}

/// A built-in sidereal ayanamsha definition.
enum TaiyinAyanamsha implements TaiyinAyanamshaModel {
  faganBradley(0),
  lahiri(1),
  raman(3),
  krishnamurti(5),
  galacticCenter0Sagittarius(17),
  trueChitra(27);

  const TaiyinAyanamsha(this.id);

  /// Stable identifier used by Taiyin's C ABI.
  @override
  final int id;
}

/// A process-wide custom ayanamsha model backed by a Dart evaluator.
///
/// Obtain an instance from [Taiyin.registerCustomAyanamshaModel].
final class TaiyinCustomAyanamshaModel implements TaiyinAyanamshaModel {
  TaiyinCustomAyanamshaModel(int id) : id = _validateId(id);

  @override
  final int id;

  static int _validateId(int id) {
    if (id < 10000 || id > 0x7fffffff) {
      throw ArgumentError.value(
        id,
        'id',
        'must fit the native signed 32-bit range and be at least 10000',
      );
    }
    return id;
  }

  @override
  bool operator ==(Object other) =>
      other is TaiyinCustomAyanamshaModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TaiyinCustomAyanamshaModel($id)';
}

/// A native position target supplied by Taiyin's astrology extension.
///
/// Call [Taiyin.registerBuiltinAstrologyTargets] during setup before using one
/// of these targets with a position or state calculation.
///
/// The four node targets are direction-only. Their generic spherical-position
/// distance and distance-rate slots are `double.nan`; Cartesian output is
/// likewise unavailable. Use [TaiyinAstrologyApi.lunarTrueNodeAtTt] or
/// [TaiyinAstrologyApi.lunarMeanNodeAtTt] when a node direction is all that is
/// required.
enum TaiyinAstrologyTarget implements TaiyinTarget {
  trueNode(-100001),
  trueDescendingNode(-100002),
  meanNode(-100003),
  meanDescendingNode(-100004),
  meanLilith(-100005),
  osculatingLilith(-100006),
  fittedLilith(-100007);

  const TaiyinAstrologyTarget(this.id);

  /// Stable identifier used by Taiyin's C ABI.
  @override
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

/// A house-system definition recognized by the process-wide native registry.
abstract interface class TaiyinHouseSystemModel {
  /// Stable identifier used by Taiyin's C ABI.
  int get id;
}

/// A built-in astrological house system.
enum TaiyinHouseSystem implements TaiyinHouseSystemModel {
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
  @override
  final int id;

  static TaiyinHouseSystem? fromIdOrNull(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// A process-wide custom house-system model backed by a Dart evaluator.
///
/// Obtain an instance from [Taiyin.registerCustomHouseSystemModel].
final class TaiyinCustomHouseSystemModel implements TaiyinHouseSystemModel {
  TaiyinCustomHouseSystemModel(int id) : id = _validateId(id);

  @override
  final int id;

  static int _validateId(int id) {
    if (id < 10000 || id > 0x7fffffff) {
      throw ArgumentError.value(
        id,
        'id',
        'must fit the native signed 32-bit range and be at least 10000',
      );
    }
    return id;
  }

  @override
  bool operator ==(Object other) =>
      other is TaiyinCustomHouseSystemModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TaiyinCustomHouseSystemModel($id)';
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

/// The requested lunar-node direction.
enum TaiyinLunarNodeKind {
  ascending(0),
  descending(1);

  const TaiyinLunarNodeKind(this.id);

  /// Stable value used by Taiyin's C ABI.
  final int id;
}

/// The convention used to define a lunar apogee result.
enum TaiyinLunarApsisDefinition {
  /// A conventional direction derived from IERS 2003 Delaunay arguments.
  delaunayMean(0),

  /// The apoapsis of the Moon's instantaneous two-body osculating ellipse.
  osculatingTwoBody(1),

  /// A continuous natural-apogee direction fitted to DE441 apoapsis events.
  de441FittedNatural(2),
  unknown(-1);

  const TaiyinLunarApsisDefinition(this.id);

  /// Stable value returned by Taiyin's C ABI.
  final int id;

  static TaiyinLunarApsisDefinition fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
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
  final TaiyinAyanamshaModel ayanamsha;
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
  final TaiyinAyanamshaModel ayanamsha;
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

/// A geocentric lunar-node direction and its instantaneous longitude rate.
///
/// The node is an angular direction, not a physical body position. Its
/// longitude is measured in [referenceFrame]; this is right ascension for an
/// equatorial frame. Results are always in radians and radians per day.
final class TaiyinLunarNodePosition {
  TaiyinLunarNodePosition({
    required this.kind,
    required this.referenceFrame,
    required this.rawReferenceFrameId,
    required this.longitudeRadians,
    required this.longitudeRateRadiansPerDay,
    required Set<TaiyinPositionFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final TaiyinLunarNodeKind kind;
  final TaiyinApparentFrame referenceFrame;

  /// Raw native frame ID, retained if a newer native library adds a frame.
  final int rawReferenceFrameId;
  final double longitudeRadians;
  final double longitudeRateRadiansPerDay;

  /// Accepted native physical-correction and frame-selection options.
  final Set<TaiyinPositionFlag> flags;

  @override
  String toString() =>
      'TaiyinLunarNodePosition(kind: $kind, frame: $referenceFrame, '
      'longitudeRadians: $longitudeRadians, '
      'longitudeRateRadiansPerDay: $longitudeRateRadiansPerDay)';
}

/// A lunar apogee direction under one explicit astronomical convention.
///
/// Angular values are radians and radians per day. [distanceAu] and
/// [distanceRateAuPerDay] are null for [TaiyinLunarApsisDefinition.delaunayMean],
/// which is a conventional direction rather than a physical point.
final class TaiyinLunarApsisPosition {
  TaiyinLunarApsisPosition({
    required this.referenceFrame,
    required this.rawReferenceFrameId,
    required this.definition,
    required this.rawDefinitionId,
    required this.longitudeRadians,
    required this.latitudeRadians,
    required this.longitudeRateRadiansPerDay,
    required this.latitudeRateRadiansPerDay,
    required this.distanceAu,
    required this.distanceRateAuPerDay,
    required this.extrapolated,
    required Set<TaiyinPositionFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final TaiyinApparentFrame referenceFrame;

  /// Raw native frame ID, retained if a newer native library adds a frame.
  final int rawReferenceFrameId;
  final TaiyinLunarApsisDefinition definition;

  /// Raw native definition ID, retained if a newer library adds one.
  final int rawDefinitionId;
  final double longitudeRadians;
  final double latitudeRadians;
  final double longitudeRateRadiansPerDay;
  final double latitudeRateRadiansPerDay;
  final double? distanceAu;
  final double? distanceRateAuPerDay;

  /// Whether the DE441 fitted-natural model extrapolated a boundary segment.
  ///
  /// This is always false for the mean and osculating definitions.
  final bool extrapolated;

  /// Accepted native physical-correction and frame-selection options.
  final Set<TaiyinPositionFlag> flags;

  @override
  String toString() =>
      'TaiyinLunarApsisPosition(definition: $definition, '
      'frame: $referenceFrame, longitudeRadians: $longitudeRadians, '
      'latitudeRadians: $latitudeRadians, distanceAu: $distanceAu, '
      'extrapolated: $extrapolated)';
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

  TaiyinHouseSystemModel? get requestedSystem =>
      _houseSystemModelFromId(requestedSystemId);
  TaiyinHouseSystemModel? get resolvedSystem =>
      _houseSystemModelFromId(resolvedSystemId);

  static TaiyinHouseSystemModel? _houseSystemModelFromId(int id) {
    return TaiyinHouseSystem.fromIdOrNull(id) ??
        (id >= 10000 ? TaiyinCustomHouseSystemModel(id) : null);
  }
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
