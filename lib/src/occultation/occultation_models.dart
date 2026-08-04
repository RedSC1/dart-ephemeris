import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// Search options for lunar occultations.
///
/// Search options are distinct from [TaiyinPositionFlag] corrections. Type
/// filters are combined as a union: an event matching any selected filter is
/// eligible.
enum TaiyinOccultationSearchOption {
  backward(1 << 32),
  oneCandidate(1 << 33),
  filterPartial(1 << 40),
  filterTotal(1 << 41),
  filterGrazing(1 << 42),
  filterCentral(1 << 43),
  filterNoncentral(1 << 44),
  lunarLimbCorrection(1 << 45);

  const TaiyinOccultationSearchOption(this.mask);

  /// Bit used by the Taiyin C ABI.
  final int mask;
}

/// Options used when calculating local occultation visibility or location.
enum TaiyinOccultationVisibilityOption {
  /// Uses the configured atmospheric refraction model for horizontal samples.
  refraction(1 << 34);

  const TaiyinOccultationVisibilityOption(this.mask);

  /// Bit used by the Taiyin C ABI.
  final int mask;
}

/// Target family of a lunar occultation.
enum TaiyinLunarOccultationKind {
  none(0),
  lunarStar(1),
  lunarBody(2),
  unknown(-1);

  const TaiyinLunarOccultationKind(this.id);

  final int id;

  static TaiyinLunarOccultationKind fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

/// Classifications that can apply to a lunar occultation.
enum TaiyinOccultationType {
  partial(1 << 0),
  total(1 << 1),
  annular(1 << 2),
  grazing(1 << 3),
  central(1 << 4),
  noncentral(1 << 5),
  centralityUnavailable(1 << 6);

  const TaiyinOccultationType(this.mask);

  final int mask;

  static Set<TaiyinOccultationType> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// Visibility state at one local occultation sample.
enum TaiyinOccultationSampleFlag {
  moonAboveHorizon(1 << 0),
  targetAboveHorizon(1 << 1),
  sunBelowHorizon(1 << 2);

  const TaiyinOccultationSampleFlag(this.mask);

  final int mask;

  static Set<TaiyinOccultationSampleFlag> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// Aggregate local-visibility state for an occultation.
enum TaiyinOccultationVisibilityFlag {
  hasVisibleSample(1 << 0),
  maximumVisible(1 << 1),
  hasDarkSample(1 << 2),
  maximumDark(1 << 3),
  hasVisibleInterval(1 << 4),
  hasDarkInterval(1 << 5);

  const TaiyinOccultationVisibilityFlag(this.mask);

  final int mask;

  static Set<TaiyinOccultationVisibilityFlag> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// Photometric and geometric values at occultation maximum.
///
/// Native code uses non-finite values when a measure does not apply. Dart maps
/// those values to `null`.
final class TaiyinLunarOccultationPhenomena {
  const TaiyinLunarOccultationPhenomena({
    required this.angularDistanceRadians,
    required this.diameterRatio,
    required this.magnitude,
    required this.obscuration,
    required this.occultedFraction,
  });

  final double? angularDistanceRadians;
  final double? diameterRatio;
  final double? magnitude;
  final double? obscuration;
  final double? occultedFraction;
}

/// A geocentric or local lunar occultation found by a native search.
///
/// All dates are split native UT1 Julian dates; a missing contact maps from
/// the native non-finite sentinel to `null`.
final class TaiyinLunarOccultationResult {
  TaiyinLunarOccultationResult({
    required this.kind,
    required Set<TaiyinOccultationType> types,
    required this.coordinate,
    required this.begin,
    required this.end,
    required this.firstContact,
    required this.secondContact,
    required this.thirdContact,
    required this.fourthContact,
    required this.separationRadians,
    required this.moonRadiusRadians,
    required this.targetRadiusRadians,
    required this.marginRadians,
    required this.phenomena,
    required this.candidate,
    required this.nextSearch,
    required this.candidateCount,
    required this.iterationCount,
    required this.evaluationCount,
  }) : types = Set.unmodifiable(types);

  final TaiyinLunarOccultationKind kind;
  final Set<TaiyinOccultationType> types;
  final JulianDate<Ut1Scale> coordinate;
  final JulianDate<Ut1Scale>? begin;
  final JulianDate<Ut1Scale>? end;
  final JulianDate<Ut1Scale>? firstContact;
  final JulianDate<Ut1Scale>? secondContact;
  final JulianDate<Ut1Scale>? thirdContact;
  final JulianDate<Ut1Scale>? fourthContact;
  final double separationRadians;
  final double moonRadiusRadians;
  final double targetRadiusRadians;
  final double marginRadians;
  final TaiyinLunarOccultationPhenomena phenomena;
  final JulianDate<Ut1Scale>? candidate;
  final JulianDate<Ut1Scale>? nextSearch;
  final int candidateCount;
  final int iterationCount;
  final int evaluationCount;
}

/// One valid interval during which a local occultation is visible.
final class TaiyinLunarOccultationVisibilityInterval {
  const TaiyinLunarOccultationVisibilityInterval({
    required this.begin,
    required this.end,
  });

  final JulianDate<Ut1Scale> begin;
  final JulianDate<Ut1Scale> end;
}

/// Horizontal coordinates and sky-state flags at one occultation contact.
final class TaiyinLunarOccultationVisibilitySample {
  TaiyinLunarOccultationVisibilitySample({
    required this.coordinate,
    required this.moonAltitudeRadians,
    required this.moonAzimuthRadians,
    required this.targetAltitudeRadians,
    required this.targetAzimuthRadians,
    required this.sunAltitudeRadians,
    required this.sunAzimuthRadians,
    required Set<TaiyinOccultationSampleFlag> flags,
  }) : flags = Set.unmodifiable(flags);

  final JulianDate<Ut1Scale> coordinate;
  final double moonAltitudeRadians;
  final double moonAzimuthRadians;
  final double targetAltitudeRadians;
  final double targetAzimuthRadians;
  final double sunAltitudeRadians;
  final double sunAzimuthRadians;
  final Set<TaiyinOccultationSampleFlag> flags;
}

/// Local visibility summary for a previously found lunar occultation.
final class TaiyinLunarOccultationLocalVisibility {
  TaiyinLunarOccultationLocalVisibility({
    required this.firstContact,
    required this.secondContact,
    required this.maximum,
    required this.thirdContact,
    required this.fourthContact,
    required this.targetRise,
    required this.targetSet,
    required this.visibleBegin,
    required this.visibleEnd,
    required this.darkVisibleBegin,
    required this.darkVisibleEnd,
    required List<TaiyinLunarOccultationVisibilityInterval> visibleIntervals,
    required List<TaiyinLunarOccultationVisibilityInterval>
    darkVisibleIntervals,
    required Set<TaiyinOccultationVisibilityFlag> flags,
  }) : visibleIntervals = List.unmodifiable(visibleIntervals),
       darkVisibleIntervals = List.unmodifiable(darkVisibleIntervals),
       flags = Set.unmodifiable(flags);

  /// Mirrors `TAIYIN_C_OCCULTATION_MAX_VISIBILITY_INTERVALS`.
  static const int maxIntervals = 8;

  final TaiyinLunarOccultationVisibilitySample? firstContact;
  final TaiyinLunarOccultationVisibilitySample? secondContact;
  final TaiyinLunarOccultationVisibilitySample? maximum;
  final TaiyinLunarOccultationVisibilitySample? thirdContact;
  final TaiyinLunarOccultationVisibilitySample? fourthContact;
  final JulianDate<Ut1Scale>? targetRise;
  final JulianDate<Ut1Scale>? targetSet;
  final JulianDate<Ut1Scale>? visibleBegin;
  final JulianDate<Ut1Scale>? visibleEnd;
  final JulianDate<Ut1Scale>? darkVisibleBegin;
  final JulianDate<Ut1Scale>? darkVisibleEnd;
  final List<TaiyinLunarOccultationVisibilityInterval> visibleIntervals;
  final List<TaiyinLunarOccultationVisibilityInterval> darkVisibleIntervals;
  final Set<TaiyinOccultationVisibilityFlag> flags;
}

/// A point on a global occultation path or visible-region polygon.
///
/// Native count fields include only valid entries. The Dart API therefore
/// rejects a malformed result with an invalid entry inside that count.
final class TaiyinLunarOccultationPathPoint {
  const TaiyinLunarOccultationPathPoint({
    required this.valid,
    required this.coordinate,
    required this.longitudeDegrees,
    required this.latitudeDegrees,
    required this.heightMeters,
  });

  final bool valid;
  final JulianDate<Ut1Scale>? coordinate;
  final double? longitudeDegrees;
  final double? latitudeDegrees;
  final double? heightMeters;
}

/// Global location of occultation maximum or its derived path products.
final class TaiyinLunarOccultationWhereResult {
  TaiyinLunarOccultationWhereResult({
    required this.centerLineHitsEarth,
    required Set<TaiyinOccultationType> types,
    required this.coordinate,
    required this.centerLineBegin,
    required this.centerLineEnd,
    required List<TaiyinLunarOccultationPathPoint> centerLinePath,
    required this.centerLineMinLongitudeDegrees,
    required this.centerLineMaxLongitudeDegrees,
    required this.centerLineMinLatitudeDegrees,
    required this.centerLineMaxLatitudeDegrees,
    required this.centerLinePathDistanceKilometers,
    required List<TaiyinLunarOccultationPathPoint> outerNorthPath,
    required List<TaiyinLunarOccultationPathPoint> outerSouthPath,
    required this.outerLimitMeanWidthKilometers,
    required this.outerLimitMaxWidthKilometers,
    required List<TaiyinLunarOccultationPathPoint> visibleRegionPolygon,
    required this.visibleRegionMinLongitudeDegrees,
    required this.visibleRegionMaxLongitudeDegrees,
    required this.visibleRegionMinLatitudeDegrees,
    required this.visibleRegionMaxLatitudeDegrees,
    required this.maximumLocation,
    required this.separationRadians,
    required this.moonRadiusRadians,
    required this.targetRadiusRadians,
    required this.marginRadians,
    required this.phenomena,
    required this.localSample,
    required Set<TaiyinOccultationVisibilityFlag> visibilityFlags,
  }) : types = Set.unmodifiable(types),
       centerLinePath = List.unmodifiable(centerLinePath),
       outerNorthPath = List.unmodifiable(outerNorthPath),
       outerSouthPath = List.unmodifiable(outerSouthPath),
       visibleRegionPolygon = List.unmodifiable(visibleRegionPolygon),
       visibilityFlags = Set.unmodifiable(visibilityFlags);

  /// Mirrors `TAIYIN_C_OCCULTATION_WHERE_MAX_PATH_POINTS`.
  static const int maxPathPoints = 16;

  /// Mirrors `TAIYIN_C_OCCULTATION_WHERE_MAX_POLYGON_POINTS`.
  static const int maxPolygonPoints = 32;

  final bool centerLineHitsEarth;
  final Set<TaiyinOccultationType> types;
  final JulianDate<Ut1Scale>? coordinate;
  final JulianDate<Ut1Scale>? centerLineBegin;
  final JulianDate<Ut1Scale>? centerLineEnd;
  final List<TaiyinLunarOccultationPathPoint> centerLinePath;
  final double? centerLineMinLongitudeDegrees;
  final double? centerLineMaxLongitudeDegrees;
  final double? centerLineMinLatitudeDegrees;
  final double? centerLineMaxLatitudeDegrees;
  final double? centerLinePathDistanceKilometers;
  final List<TaiyinLunarOccultationPathPoint> outerNorthPath;
  final List<TaiyinLunarOccultationPathPoint> outerSouthPath;
  final double? outerLimitMeanWidthKilometers;
  final double? outerLimitMaxWidthKilometers;
  final List<TaiyinLunarOccultationPathPoint> visibleRegionPolygon;
  final double? visibleRegionMinLongitudeDegrees;
  final double? visibleRegionMaxLongitudeDegrees;
  final double? visibleRegionMinLatitudeDegrees;
  final double? visibleRegionMaxLatitudeDegrees;
  final TaiyinLunarOccultationPathPoint? maximumLocation;
  final double? separationRadians;
  final double? moonRadiusRadians;
  final double? targetRadiusRadians;
  final double? marginRadians;
  final TaiyinLunarOccultationPhenomena phenomena;
  final TaiyinLunarOccultationVisibilitySample? localSample;
  final Set<TaiyinOccultationVisibilityFlag> visibilityFlags;
}
