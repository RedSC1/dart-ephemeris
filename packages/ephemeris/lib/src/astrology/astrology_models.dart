import '../position/position_api.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// An ayanamsha definition recognized by the process-wide native registry.
abstract interface class AyanamshaModel {
  /// Stable identifier used by Taiyin's C ABI.
  int get id;
}

/// A built-in sidereal ayanamsha definition.
enum Ayanamsha implements AyanamshaModel {
  faganBradley(0),
  lahiri(1),
  raman(3),
  krishnamurti(5),
  galacticCenter0Sagittarius(17),
  trueChitra(27);

  const Ayanamsha(this.id);

  /// Stable identifier used by Taiyin's C ABI.
  @override
  final int id;
}

/// A process-wide custom ayanamsha model identifier.
///
/// Obtain an owned Dart-backed registration from
/// [Ephemeris.registerCustomAyanamshaModel]. Constructing this value directly is
/// also useful in a worker isolate to refer to an already registered native
/// model, but it does not register a callback or own its lifecycle.
final class CustomAyanamshaModel implements AyanamshaModel {
  CustomAyanamshaModel(int id) : id = _validateId(id);

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
      other is CustomAyanamshaModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomAyanamshaModel($id)';
}

/// A native position target supplied by Taiyin's astrology extension.
///
/// Call [Ephemeris.registerBuiltinAstrologyTargets] during setup before using one
/// of these targets with a position or state calculation.
///
/// The four node targets are direction-only. Their generic spherical-position
/// distance and distance-rate slots are `double.nan`; Cartesian output is
/// likewise unavailable. Use [AstrologyApi.lunarTrueNodeAtTt] or
/// [AstrologyApi.lunarMeanNodeAtTt] when a node direction is all that is
/// required.
enum AstrologyTarget implements Target {
  trueNode(-100001),
  trueDescendingNode(-100002),
  meanNode(-100003),
  meanDescendingNode(-100004),
  meanLilith(-100005),
  osculatingLilith(-100006),
  fittedLilith(-100007);

  const AstrologyTarget(this.id);

  /// Stable identifier used by Taiyin's C ABI.
  @override
  final int id;
}

/// Relates a historical ayanamsha definition to the selected precession model.
///
/// The native ABI encodes non-default policies as high-word sidereal flags.
enum SiderealPrecessionPolicy {
  compensateToReference(0),
  rawReferenceOffset(1 << 36),
  useReferencePrecession(1 << 37);

  const SiderealPrecessionPolicy(this.nativeFlagMask);

  /// High-word flag passed to Taiyin's C ABI.
  final int nativeFlagMask;
}

/// The ecliptic reference plane requested for a sidereal calculation.
///
/// Equatorial sidereal-coordinate calls deliberately override this selection
/// and return the tropical mean or true equator of date instead.
enum SiderealReferencePlane {
  /// The ordinary sidereal zodiac on the mean ecliptic of the calculation date.
  meanEclipticOfDate(0, false),

  /// A mean ecliptic fixed at [SiderealReferenceEpoch].
  meanEclipticAtEpoch(1 << 32, true),

  /// The solar-system invariable plane, oriented at a reference epoch.
  solarSystemInvariable(1 << 33, true),

  /// The fixed, non-nutated mean ecliptic of J2000.0.
  meanEclipticJ2000(1 << 34, false);

  const SiderealReferencePlane(
    this.nativeFlagMask,
    this.requiresReferenceEpoch,
  );

  /// High-word flag passed to Taiyin's C ABI.
  final int nativeFlagMask;

  /// Whether this plane requires a finite [SiderealReferenceEpoch].
  final bool requiresReferenceEpoch;
}

/// A typed epoch that orients a fixed sidereal reference plane.
///
/// Use [SiderealReferenceEpoch.tt] for a TT epoch or
/// [SiderealReferenceEpoch.ut1] for a UT1 epoch. The native ABI accepts
/// the epoch as a split-JD struct; when no reference plane is selected a null
/// pointer is sent instead.
sealed class SiderealReferenceEpoch {
  const SiderealReferenceEpoch._();

  factory SiderealReferenceEpoch.tt(JulianDate<TtScale> coordinate) =
      SiderealReferenceEpochTt;

  factory SiderealReferenceEpoch.ut1(JulianDate<Ut1Scale> coordinate) =
      SiderealReferenceEpochUt1;

  /// Scalar Julian date equivalent of this epoch, for scalar consumers.
  double get nativeJulianDate;

  /// Whether [nativeJulianDate] is expressed in UT1 rather than TT.
  bool get isUt1;
}

/// A TT reference epoch for [SiderealReferencePlane.meanEclipticAtEpoch]
/// or [SiderealReferencePlane.solarSystemInvariable].
final class SiderealReferenceEpochTt extends SiderealReferenceEpoch {
  const SiderealReferenceEpochTt(this.coordinate) : super._();

  final JulianDate<TtScale> coordinate;

  @override
  double get nativeJulianDate => coordinate.toDouble();

  @override
  bool get isUt1 => false;

  @override
  bool operator ==(Object other) =>
      other is SiderealReferenceEpochTt && other.coordinate == coordinate;

  @override
  int get hashCode => Object.hash(SiderealReferenceEpochTt, coordinate);

  @override
  String toString() => 'SiderealReferenceEpoch.tt($coordinate)';
}

/// A UT1 reference epoch for
/// [SiderealReferencePlane.meanEclipticAtEpoch] or
/// [SiderealReferencePlane.solarSystemInvariable].
final class SiderealReferenceEpochUt1 extends SiderealReferenceEpoch {
  const SiderealReferenceEpochUt1(this.coordinate) : super._();

  final JulianDate<Ut1Scale> coordinate;

  @override
  double get nativeJulianDate => coordinate.toDouble();

  @override
  bool get isUt1 => true;

  @override
  bool operator ==(Object other) =>
      other is SiderealReferenceEpochUt1 && other.coordinate == coordinate;

  @override
  int get hashCode => Object.hash(SiderealReferenceEpochUt1, coordinate);

  @override
  String toString() => 'SiderealReferenceEpoch.ut1($coordinate)';
}

/// The output reference frame used by a generic sidereal-coordinate result.
///
/// The ecliptic variant has a sidereal origin. Equatorial variants follow the
/// conventional Swiss Ephemeris-compatible behavior and are tropical
/// mean/true equators of date instead.
enum SiderealCoordinateFrame {
  meanEclipticOfDate(0),
  meanEquatorOfDate(1),
  trueEquatorOfDate(2),
  fixedMeanEclipticAtEpoch(3),
  solarSystemInvariable(4),
  j2000Ecliptic(5),
  unknown(-1);

  const SiderealCoordinateFrame(this.id);

  /// Stable identifier returned by Taiyin's C ABI.
  final int id;

  static SiderealCoordinateFrame fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

/// A house-system definition recognized by the process-wide native registry.
abstract interface class HouseSystemModel {
  /// Stable identifier used by Taiyin's C ABI.
  int get id;
}

/// A built-in astrological house system.
enum HouseSystem implements HouseSystemModel {
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

  const HouseSystem(this.id);

  /// Stable identifier used by Taiyin's C ABI.
  @override
  final int id;

  static HouseSystem? fromIdOrNull(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// A process-wide custom house-system model identifier.
///
/// Obtain an owned Dart-backed registration from
/// [Ephemeris.registerCustomHouseSystemModel]. Constructing this value directly
/// only identifies an already registered native model; it does not register a
/// callback or own its lifecycle.
final class CustomHouseSystemModel implements HouseSystemModel {
  CustomHouseSystemModel(int id) : id = _validateId(id);

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
      other is CustomHouseSystemModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomHouseSystemModel($id)';
}

/// A condition reported while calculating time-based astrological houses.
enum HouseResultFlag {
  usedFallback(1 << 0),
  fallbackPorphyry(1 << 1),

  /// A UT1/TT calculation could not estimate its time derivatives.
  ///
  /// Direct ARMC calculations have no time coordinate, so their rate fields
  /// are `NaN` without setting this flag.
  speedUnavailable(1 << 2);

  const HouseResultFlag(this.mask);

  /// Bit used by Taiyin's C ABI.
  final int mask;
}

/// The requested lunar-node direction.
enum LunarNodeKind {
  ascending(0),
  descending(1);

  const LunarNodeKind(this.id);

  /// Stable value used by Taiyin's C ABI.
  final int id;
}

/// The convention used to define a lunar apogee result.
enum LunarApsisDefinition {
  /// A conventional direction derived from IERS 2003 Delaunay arguments.
  delaunayMean(0),

  /// The apoapsis of the Moon's instantaneous two-body osculating ellipse.
  osculatingTwoBody(1),

  /// A continuous natural-apogee direction fitted to DE441 apoapsis events.
  de441FittedNatural(2),
  unknown(-1);

  const LunarApsisDefinition(this.id);

  /// Stable value returned by Taiyin's C ABI.
  final int id;

  static LunarApsisDefinition fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

/// Unshifted and sidereal ecliptic longitudes for one target.
final class SiderealPosition {
  SiderealPosition({
    required this.target,
    required this.ayanamsha,
    required this.precessionPolicy,
    required this.referencePlane,
    required this.referenceEpoch,
    required this.coordinateFrame,
    required this.rawCoordinateFrameId,
    required this.tropicalLongitudeRadians,
    required this.siderealLongitudeRadians,
    required this.latitudeRadians,
    required this.distanceAu,
    required this.tropicalLongitudeRateRadiansPerDay,
    required this.siderealLongitudeRateRadiansPerDay,
    required Set<PositionFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final Target target;
  final AyanamshaModel ayanamsha;
  final SiderealPrecessionPolicy precessionPolicy;

  /// Requested ecliptic reference-plane policy.
  final SiderealReferencePlane referencePlane;

  /// Epoch used to orient [referencePlane], when that plane requires one.
  final SiderealReferenceEpoch? referenceEpoch;

  /// Ecliptic coordinate frame used by these longitudes.
  final SiderealCoordinateFrame coordinateFrame;

  /// Raw native frame ID, retained when a newer native library adds a frame.
  final int rawCoordinateFrameId;

  /// Unshifted longitude in [coordinateFrame], in radians.
  ///
  /// On a fixed or invariable plane this is not tropical ecliptic-of-date
  /// longitude.
  final double tropicalLongitudeRadians;

  /// [tropicalLongitudeRadians] named by its frame-neutral meaning.
  ///
  /// Prefer this name when [coordinateFrame] is a fixed or invariable plane.
  double get unshiftedLongitudeRadians => tropicalLongitudeRadians;

  /// Sidereal ecliptic longitude in radians.
  final double siderealLongitudeRadians;

  /// Ecliptic latitude in radians.
  final double latitudeRadians;

  /// Distance in astronomical units.
  final double distanceAu;

  /// Rate of [tropicalLongitudeRadians] in radians per day.
  ///
  /// On a fixed or invariable plane this is the rate of the unshifted
  /// longitude on that plane, not a tropical ecliptic-of-date rate.
  ///
  /// This is `double.nan` unless [flags] contains
  /// [PositionFlag.speed]. This result intentionally contains longitude
  /// rates only, not latitude or distance rates.
  final double tropicalLongitudeRateRadiansPerDay;

  /// [tropicalLongitudeRateRadiansPerDay] named by its frame-neutral meaning.
  double get unshiftedLongitudeRateRadiansPerDay =>
      tropicalLongitudeRateRadiansPerDay;

  /// Sidereal ecliptic-longitude rate in radians per day.
  ///
  /// This is `double.nan` unless [flags] contains
  /// [PositionFlag.speed]. This result intentionally contains longitude
  /// rates only, not latitude or distance rates.
  final double siderealLongitudeRateRadiansPerDay;

  /// Native position options resolved for this ecliptic calculation.
  ///
  /// [PositionFlag.radians] is always present. Longitude rates are
  /// available only when this set contains [PositionFlag.speed].
  final Set<PositionFlag> flags;
}

/// Generic sidereal coordinates in a selected ecliptic or tropical equatorial
/// frame.
///
/// [values] use the usual six-value position convention. Without
/// [PositionFlag.xyz], values 0–2 are longitude/right ascension,
/// latitude/declination, and distance; values 3–5 are the corresponding rates
/// when [PositionFlag.speed] is present. With `xyz`, they are Cartesian
/// position and velocity. The Dart API always adds
/// [PositionFlag.radians], so angular spherical values are always in
/// radians. Without [PositionFlag.speed], values 3–5 are `0.0`, as in
/// the generic native-position convention; this differs from
/// [SiderealPosition], whose unavailable rate fields are `double.nan`.
/// Without
/// [PositionFlag.equatorial], the frame is selected by [referencePlane].
/// With it, the result follows Swiss Ephemeris-compatible behavior:
/// tropical mean equator of date with [PositionFlag.noNutation], or
/// tropical true equator of date without it.
final class SiderealCoordinates {
  SiderealCoordinates({
    required this.target,
    required this.ayanamsha,
    required this.precessionPolicy,
    required this.referencePlane,
    required this.referenceEpoch,
    required this.coordinateFrame,
    required this.rawCoordinateFrameId,
    required List<double> values,
    required Set<PositionFlag> flags,
  }) : values = List.unmodifiable(values),
       flags = Set.unmodifiable(flags) {
    if (values.length != 6) {
      throw ArgumentError.value(values, 'values', 'must contain six values');
    }
  }

  final Target target;
  final AyanamshaModel ayanamsha;
  final SiderealPrecessionPolicy precessionPolicy;

  /// Requested ecliptic reference-plane policy.
  ///
  /// This is ignored by an equatorial output request; [coordinateFrame] always
  /// identifies the frame actually returned by the native calculation.
  final SiderealReferencePlane referencePlane;

  /// Epoch used to orient [referencePlane], when that plane requires one.
  final SiderealReferenceEpoch? referenceEpoch;

  /// Output coordinate frame used by these values.
  final SiderealCoordinateFrame coordinateFrame;

  /// Unrecognized C ABI coordinate-frame ID, if any.
  ///
  /// This preserves a future native frame ID even when this Dart package has
  /// not yet added a corresponding enum value.
  final int rawCoordinateFrameId;

  final List<double> values;

  /// Resolved native position options for this calculation.
  ///
  /// This always includes [PositionFlag.radians].
  final Set<PositionFlag> flags;

  List<double> get coordinates => values.sublist(0, 3);

  /// Velocity or angular-rate slots, or three `0.0` values without `speed`.
  List<double> get rates => values.sublist(3, 6);
  bool get isCartesian => flags.contains(PositionFlag.xyz);
  bool get isEquatorial => flags.contains(PositionFlag.equatorial);
  bool get isRadians => flags.contains(PositionFlag.radians);

  @override
  String toString() => 'SiderealCoordinates($values)';
}

/// A geocentric lunar-node direction and its instantaneous longitude rate.
///
/// The node is an angular direction, not a physical body position. Its
/// longitude is measured in [referenceFrame]; this is right ascension for an
/// equatorial frame. Results are always in radians and radians per day.
final class LunarNodePosition {
  LunarNodePosition({
    required this.kind,
    required this.referenceFrame,
    required this.rawReferenceFrameId,
    required this.longitudeRadians,
    required this.longitudeRateRadiansPerDay,
    required Set<PositionFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final LunarNodeKind kind;
  final ApparentFrame referenceFrame;

  /// Raw native frame ID, retained if a newer native library adds a frame.
  final int rawReferenceFrameId;
  final double longitudeRadians;
  final double longitudeRateRadiansPerDay;

  /// Accepted native physical-correction and frame-selection options.
  final Set<PositionFlag> flags;

  @override
  String toString() =>
      'LunarNodePosition(kind: $kind, frame: $referenceFrame, '
      'longitudeRadians: $longitudeRadians, '
      'longitudeRateRadiansPerDay: $longitudeRateRadiansPerDay)';
}

/// A lunar apogee direction under one explicit astronomical convention.
///
/// Angular values are radians and radians per day. [distanceAu] and
/// [distanceRateAuPerDay] are null for [LunarApsisDefinition.delaunayMean],
/// which is a conventional direction rather than a physical point.
final class LunarApsisPosition {
  LunarApsisPosition({
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
    required Set<PositionFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final ApparentFrame referenceFrame;

  /// Raw native frame ID, retained if a newer native library adds a frame.
  final int rawReferenceFrameId;
  final LunarApsisDefinition definition;

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
  final Set<PositionFlag> flags;

  @override
  String toString() =>
      'LunarApsisPosition(definition: $definition, '
      'frame: $referenceFrame, longitudeRadians: $longitudeRadians, '
      'latitudeRadians: $latitudeRadians, distanceAu: $distanceAu, '
      'extrapolated: $extrapolated)';
}

/// Twelve house cusps and derived angular points.
final class Houses {
  Houses({
    required this.requestedSystemId,
    required this.resolvedSystemId,
    required this.rawFlags,
    required Set<HouseResultFlag> flags,
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
  final Set<HouseResultFlag> flags;
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
  /// [HouseResultFlag.speedUnavailable] is set.
  final List<double> cuspLongitudeRatesRadiansPerDay;

  /// The requested system's ID as a built-in or custom type tag.
  ///
  /// A custom result only identifies an ID; it does not imply that this Dart
  /// isolate owns or has registered that callback.
  HouseSystemModel? get requestedSystem =>
      _houseSystemModelFromId(requestedSystemId);

  /// The resolved system's ID as a built-in or custom type tag.
  ///
  /// See [requestedSystem] for the ownership semantics of custom IDs.
  HouseSystemModel? get resolvedSystem =>
      _houseSystemModelFromId(resolvedSystemId);

  static HouseSystemModel? _houseSystemModelFromId(int id) {
    return HouseSystem.fromIdOrNull(id) ??
        (id >= 10000 ? CustomHouseSystemModel(id) : null);
  }
}

/// The house containing an ecliptic longitude.
final class HousePosition {
  HousePosition({
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
