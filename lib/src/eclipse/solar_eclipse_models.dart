import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'lunar_eclipse_models.dart';

/// The five fixed global solar-eclipse contact slots.
enum SolarEclipseContact {
  partialBegin(0),
  centralBegin(1),
  greatest(2),
  centralEnd(3),
  partialEnd(4);

  const SolarEclipseContact(this.nativeIndex);

  /// Index in the fixed native contact array.
  final int nativeIndex;
}

/// The five fixed contact slots in a local solar-eclipse result.
///
/// Unlike [SolarEclipseContact], local contacts are C1, C2, C3, C4,
/// and greatest eclipse, respectively.
enum LocalSolarEclipseContact {
  partialBegin(0),
  centralBegin(1),
  centralEnd(2),
  partialEnd(3),
  greatest(4);

  const LocalSolarEclipseContact(this.nativeIndex);

  /// Index in the fixed native contact array.
  final int nativeIndex;
}

/// Options for solving one global or local solar-eclipse lunation.
enum SolarEclipseSolveOption {
  /// Requests global contact values where the operation supports them.
  includeContacts(1 << 33),

  /// Uses the loaded TLL1 lunar limb model when polishing contacts.
  lunarLimbCorrection(1 << 38);

  const SolarEclipseSolveOption(this.mask);

  final int mask;
}

/// Options for finding solar eclipses.
enum SolarEclipseSearchOption {
  /// Requests global contact values where the operation supports them.
  includeContacts(1 << 33),

  /// Searches backwards from the supplied start coordinate.
  backward(1 << 35),

  /// Uses the loaded TLL1 lunar limb model when polishing contacts.
  lunarLimbCorrection(1 << 38);

  const SolarEclipseSearchOption(this.mask);

  final int mask;
}

/// Options for global solar-eclipse route calculations.
enum SolarEclipseRouteOption {
  /// Uses the loaded TLL1 lunar limb model for non-center path limits.
  lunarLimbCorrection(1 << 38);

  const SolarEclipseRouteOption(this.mask);

  final int mask;
}

/// Local solar-eclipse visibility bits returned by the native C ABI.
///
/// Solar eclipses have no separate penumbral phase, so lunar-only penumbral
/// begin and end visibility flags are intentionally not represented here.
enum LocalSolarEclipseVisibilityFlag {
  visibleAtObserver(1 << 7),
  maximumVisible(1 << 8),
  partialBeginVisible(1 << 9),
  centralBeginVisible(1 << 10),
  centralEndVisible(1 << 11),
  partialEndVisible(1 << 12);

  const LocalSolarEclipseVisibilityFlag(this.mask);

  final int mask;

  static Set<LocalSolarEclipseVisibilityFlag> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// A global solar eclipse, or the explicit no-eclipse result for one lunation.
final class SolarEclipseResult<S extends TimeScale> {
  SolarEclipseResult({
    required Set<EclipseKind> kinds,
    required this.maximum,
    required this.deltaTSeconds,
    required this.axisDistanceKilometers,
    required this.penumbraRadiusKilometers,
    required this.coreRadiusKilometers,
    required this.penumbralMarginKilometers,
    required this.centralMarginKilometers,
    required this.maximumLatitudeDegrees,
    required this.maximumLongitudeDegrees,
    required Map<SolarEclipseContact, JulianDate<S>?> contacts,
  }) : kinds = Set.unmodifiable(kinds),
       contacts = Map.unmodifiable(contacts);

  final Set<EclipseKind> kinds;

  /// Scalar-JD coordinate of greatest eclipse, if a solar eclipse occurs.
  final JulianDate<S>? maximum;

  /// UT1 minus TT conversion metadata. Present for UT1 results only.
  final double? deltaTSeconds;
  final double? axisDistanceKilometers;
  final double? penumbraRadiusKilometers;

  /// Positive for an umbra and negative for an antumbra at Earth.
  final double? coreRadiusKilometers;
  final double? penumbralMarginKilometers;
  final double? centralMarginKilometers;
  final double? maximumLatitudeDegrees;
  final double? maximumLongitudeDegrees;
  final Map<SolarEclipseContact, JulianDate<S>?> contacts;

  /// Whether native code found a solar eclipse at this lunation.
  bool get hasEclipse => kinds.isNotEmpty;
}

/// A solar eclipse at the observer location configured on a context.
final class LocalSolarEclipseResult<S extends TimeScale> {
  LocalSolarEclipseResult({
    required Set<EclipseKind> kinds,
    required Set<LocalSolarEclipseVisibilityFlag> visibility,
    required this.maximum,
    required this.deltaTSeconds,
    required this.magnitude,
    required this.obscuration,
    required this.sunAltitudeDegrees,
    required this.sunAzimuthDegrees,
    required Map<LocalSolarEclipseContact, JulianDate<S>?> contacts,
    required this.positionAngleC1Degrees,
    required this.positionAngleC4Degrees,
    required this.vertexAngleC1Degrees,
    required this.vertexAngleC4Degrees,
    required this.sunriseMagnitude,
    required this.sunsetMagnitude,
    required this.durationSeconds,
    required this.moonSunRadiusRatio,
  }) : kinds = Set.unmodifiable(kinds),
       visibility = Set.unmodifiable(visibility),
       contacts = Map.unmodifiable(contacts);

  final Set<EclipseKind> kinds;
  final Set<LocalSolarEclipseVisibilityFlag> visibility;
  final JulianDate<S>? maximum;
  final double? deltaTSeconds;
  final double? magnitude;
  final double? obscuration;
  final double? sunAltitudeDegrees;
  final double? sunAzimuthDegrees;
  final Map<LocalSolarEclipseContact, JulianDate<S>?> contacts;
  final double? positionAngleC1Degrees;
  final double? positionAngleC4Degrees;
  final double? vertexAngleC1Degrees;
  final double? vertexAngleC4Degrees;
  final double? sunriseMagnitude;
  final double? sunsetMagnitude;
  final double? durationSeconds;
  final double? moonSunRadiusRatio;

  bool get hasEclipse => kinds.isNotEmpty;
}

/// Instantaneous local solar-eclipse geometry at a configured observer.
final class LocalSolarEclipseCircumstances<S extends TimeScale> {
  const LocalSolarEclipseCircumstances({
    required this.coordinate,
    required this.deltaTSeconds,
    required this.magnitude,
    required this.obscuration,
    required this.centerSeparationDegrees,
    required this.sunAngularRadiusDegrees,
    required this.moonAngularRadiusDegrees,
    required this.sunAltitudeDegrees,
    required this.sunAzimuthDegrees,
  });

  final JulianDate<S> coordinate;
  final double? deltaTSeconds;
  final double magnitude;
  final double obscuration;
  final double centerSeparationDegrees;
  final double sunAngularRadiusDegrees;
  final double moonAngularRadiusDegrees;
  final double sunAltitudeDegrees;
  final double sunAzimuthDegrees;
}

/// One geodetic point in a global solar-eclipse route row.
///
/// A route limit that does not intersect Earth has null coordinates and
/// geometry. Both native time coordinates are retained when available.
final class SolarEclipseRoutePoint {
  const SolarEclipseRoutePoint({
    required this.coordinateTt,
    required this.coordinateUt1,
    required this.latitudeDegrees,
    required this.longitudeDegrees,
    required this.elevationMeters,
    required this.sunAltitudeDegrees,
    required this.sunAzimuthDegrees,
  });

  final JulianDate<TtScale>? coordinateTt;
  final JulianDate<Ut1Scale>? coordinateUt1;
  final double? latitudeDegrees;
  final double? longitudeDegrees;
  final double? elevationMeters;
  final double? sunAltitudeDegrees;
  final double? sunAzimuthDegrees;

  /// Whether this route branch intersects Earth at the sampled time.
  bool get intersectsEarth =>
      latitudeDegrees != null && longitudeDegrees != null;
}

/// Global solar-eclipse path geometry at one TT/UT1 coordinate pair.
final class SolarEclipseRouteRow {
  const SolarEclipseRouteRow({
    required this.coordinateTt,
    required this.coordinateUt1,
    required this.centerLine,
    required this.penumbralNorthLimit,
    required this.penumbralSouthLimit,
    required this.northLimit,
    required this.southLimit,
    required this.halfMagnitudeNorthLimit,
    required this.halfMagnitudeSouthLimit,
    required this.pathWidthKilometers,
    required this.durationSeconds,
    required this.sunAltitudeDegrees,
    required this.sunAzimuthDegrees,
  });

  final JulianDate<TtScale> coordinateTt;
  final JulianDate<Ut1Scale> coordinateUt1;
  final SolarEclipseRoutePoint centerLine;
  final SolarEclipseRoutePoint penumbralNorthLimit;
  final SolarEclipseRoutePoint penumbralSouthLimit;
  final SolarEclipseRoutePoint northLimit;
  final SolarEclipseRoutePoint southLimit;
  final SolarEclipseRoutePoint halfMagnitudeNorthLimit;
  final SolarEclipseRoutePoint halfMagnitudeSouthLimit;
  final double? pathWidthKilometers;
  final double? durationSeconds;
  final double? sunAltitudeDegrees;
  final double? sunAzimuthDegrees;

  /// Whether at least one route branch intersects Earth at this time.
  bool get hasRoute =>
      centerLine.intersectsEarth ||
      penumbralNorthLimit.intersectsEarth ||
      penumbralSouthLimit.intersectsEarth ||
      northLimit.intersectsEarth ||
      southLimit.intersectsEarth;
}

/// Identifies one curve in a global solar-eclipse map.
///
/// Points returned by a route-curve calculation are grouped by this value.
enum SolarEclipseRouteCurveKind {
  partialBeginA(0),
  partialBeginB(1),
  partialEndA(2),
  partialEndB(3),
  sunriseMaximumA(4),
  sunriseMaximumB(5),
  sunsetMaximumA(6),
  sunsetMaximumB(7),
  centerLine(8),
  penumbralNorth(9),
  penumbralSouth(10),
  coreNorth(11),
  coreSouth(12),
  halfMagnitudeNorth(13),
  halfMagnitudeSouth(14),
  umbraOutline(15),
  penumbraOutline(16),
  terminator(17),
  coreBeginHorizon(18),
  coreEndHorizon(19),
  halfMagnitudeSunriseA(20),
  halfMagnitudeSunriseB(21),
  halfMagnitudeSunsetA(22),
  halfMagnitudeSunsetB(23);

  const SolarEclipseRouteCurveKind(this.nativeIndex);

  /// Numeric value used by the Taiyin C ABI.
  final int nativeIndex;

  static SolarEclipseRouteCurveKind fromNativeIndex(int index) {
    for (final value in values) {
      if (value.nativeIndex == index) return value;
    }
    throw StateError('Native solar eclipse route returned curve kind $index');
  }
}

/// One time-tagged geographic sample of a solar-eclipse map curve.
final class SolarEclipseRouteCurvePoint {
  const SolarEclipseRouteCurvePoint({
    required this.coordinateTt,
    required this.coordinateUt1,
    required this.kind,
    required this.latitudeDegrees,
    required this.longitudeDegrees,
  });

  final JulianDate<TtScale> coordinateTt;
  final JulianDate<Ut1Scale> coordinateUt1;
  final SolarEclipseRouteCurveKind kind;
  final double latitudeDegrees;
  final double longitudeDegrees;
}

/// Flags describing which layers are present in a solar-eclipse route product.
enum SolarEclipseRouteProductFlag {
  hasCenterLine(1 << 0),
  hasCoreLimits(1 << 1),
  hasPenumbralLimits(1 << 2),
  hasCorePolygon(1 << 3),
  crossesAntimeridian(1 << 4),
  hasHalfMagnitudeLimits(1 << 5),
  hasPenumbralPolygon(1 << 6),
  hasHalfMagnitudePolygon(1 << 7);

  const SolarEclipseRouteProductFlag(this.mask);

  final int mask;

  static Set<SolarEclipseRouteProductFlag> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// Role of a point within a polygonal solar-eclipse route product.
enum SolarEclipseRouteProductPointKind {
  coreNorth(0),
  coreSouth(1),
  polygonClose(2),
  penumbralNorth(3),
  penumbralSouth(4),
  halfMagnitudeNorth(5),
  halfMagnitudeSouth(6),
  coreBeginHorizon(7),
  coreEndHorizon(8);

  const SolarEclipseRouteProductPointKind(this.nativeIndex);

  final int nativeIndex;

  static SolarEclipseRouteProductPointKind fromNativeIndex(int index) {
    for (final value in values) {
      if (value.nativeIndex == index) return value;
    }
    throw StateError('Native solar eclipse route returned point kind $index');
  }
}

/// One point in a closed eclipse-path polygon.
///
/// [longitudeDegrees] is normalized for conventional geographic display while
/// [unwrappedLongitudeDegrees] preserves path continuity across the
/// antimeridian.
final class SolarEclipseRouteProductPoint {
  const SolarEclipseRouteProductPoint({
    required this.coordinateTt,
    required this.coordinateUt1,
    required this.kind,
    required this.sourceCurveKind,
    required this.latitudeDegrees,
    required this.longitudeDegrees,
    required this.unwrappedLongitudeDegrees,
  });

  final JulianDate<TtScale> coordinateTt;
  final JulianDate<Ut1Scale> coordinateUt1;
  final SolarEclipseRouteProductPointKind kind;
  final SolarEclipseRouteCurveKind sourceCurveKind;
  final double latitudeDegrees;
  final double longitudeDegrees;
  final double unwrappedLongitudeDegrees;
}

/// Metadata accompanying a solar-eclipse route product.
final class SolarEclipseRouteProductSummary {
  SolarEclipseRouteProductSummary({
    required Set<SolarEclipseRouteProductFlag> flags,
    required this.curvePointCount,
    required this.centerLineCount,
    required this.coreNorthCount,
    required this.coreSouthCount,
    required this.coreBeginHorizonCount,
    required this.coreEndHorizonCount,
    required this.penumbralNorthCount,
    required this.penumbralSouthCount,
    required this.halfMagnitudeNorthCount,
    required this.halfMagnitudeSouthCount,
    required this.corePolygonPointCount,
    required this.penumbralPolygonPointCount,
    required this.halfMagnitudePolygonPointCount,
    required this.polygonPointCount,
    required this.minimumLatitudeDegrees,
    required this.maximumLatitudeDegrees,
    required this.minimumUnwrappedLongitudeDegrees,
    required this.maximumUnwrappedLongitudeDegrees,
  }) : flags = Set.unmodifiable(flags);

  final Set<SolarEclipseRouteProductFlag> flags;

  /// Number of source route-curve samples used to construct this product.
  ///
  /// This diagnostic count does not necessarily equal the number of returned
  /// [SolarEclipseRouteProduct.points].
  final int curvePointCount;
  final int centerLineCount;
  final int coreNorthCount;
  final int coreSouthCount;
  final int coreBeginHorizonCount;
  final int coreEndHorizonCount;
  final int penumbralNorthCount;
  final int penumbralSouthCount;
  final int halfMagnitudeNorthCount;
  final int halfMagnitudeSouthCount;
  final int corePolygonPointCount;
  final int penumbralPolygonPointCount;
  final int halfMagnitudePolygonPointCount;
  final int polygonPointCount;

  /// Null when the native product contains no polygonal layers.
  final double? minimumLatitudeDegrees;

  /// Null when the native product contains no polygonal layers.
  final double? maximumLatitudeDegrees;

  /// Null when the native product contains no polygonal layers.
  final double? minimumUnwrappedLongitudeDegrees;

  /// Null when the native product contains no polygonal layers.
  final double? maximumUnwrappedLongitudeDegrees;
}

/// Complete polygonal output for either the core path or all map layers.
///
/// Map products concatenate up to three independently closed rings in this
/// order: core, penumbral, then half-magnitude. Slice [points] using the
/// three polygon-point counts in [summary]; every non-empty slice ends with a
/// [SolarEclipseRouteProductPointKind.polygonClose] point.
final class SolarEclipseRouteProduct {
  SolarEclipseRouteProduct({
    required Iterable<SolarEclipseRouteProductPoint> points,
    required this.summary,
  }) : points = List.unmodifiable(points);

  final List<SolarEclipseRouteProductPoint> points;
  final SolarEclipseRouteProductSummary summary;
}

/// Local Earth-intersection boundaries of the solar shadow at one instant.
///
/// Every coordinate and [umbraWidthKilometers] is null when that particular
/// shadow feature does not intersect Earth at the requested instant.
final class LocalSolarEclipseBoundary {
  LocalSolarEclipseBoundary({
    required Set<EclipseKind> centerKinds,
    required this.centerLongitudeDegrees,
    required this.centerLatitudeDegrees,
    required this.umbraNorthLongitudeDegrees,
    required this.umbraNorthLatitudeDegrees,
    required this.umbraSouthLongitudeDegrees,
    required this.umbraSouthLatitudeDegrees,
    required this.penumbraNorthLongitudeDegrees,
    required this.penumbraNorthLatitudeDegrees,
    required this.penumbraSouthLongitudeDegrees,
    required this.penumbraSouthLatitudeDegrees,
    required this.umbraWidthKilometers,
  }) : centerKinds = Set.unmodifiable(centerKinds);

  final Set<EclipseKind> centerKinds;
  final double? centerLongitudeDegrees;
  final double? centerLatitudeDegrees;
  final double? umbraNorthLongitudeDegrees;
  final double? umbraNorthLatitudeDegrees;
  final double? umbraSouthLongitudeDegrees;
  final double? umbraSouthLatitudeDegrees;
  final double? penumbraNorthLongitudeDegrees;
  final double? penumbraNorthLatitudeDegrees;
  final double? penumbraSouthLongitudeDegrees;
  final double? penumbraSouthLatitudeDegrees;
  final double? umbraWidthKilometers;

  /// Whether the central shadow axis intersects Earth at this instant.
  bool get hasCentralPath => centerKinds.isNotEmpty;
}

/// Fundamental-plane quantities for a solar eclipse at one TT coordinate.
///
/// [tHours] is the Besselian time offset associated with the coordinate. The
/// other values retain the conventional Besselian names used by eclipse-path
/// references; angular fields are expressed in degrees.
final class SolarBesselianElements {
  const SolarBesselianElements({
    required this.tHours,
    required this.x,
    required this.y,
    required this.zeta,
    required this.dDegrees,
    required this.muDegrees,
    required this.l1,
    required this.l2,
    required this.f1Degrees,
    required this.f2Degrees,
    required this.tanF1,
    required this.tanF2,
    required this.gamma,
  });

  final double tHours;
  final double x;
  final double y;
  final double zeta;
  final double dDegrees;
  final double muDegrees;
  final double l1;
  final double l2;
  final double f1Degrees;
  final double f2Degrees;
  final double tanF1;
  final double tanF2;
  final double gamma;
}

/// A fitted, fixed-capacity Besselian polynomial around one TT epoch.
///
/// Each coefficient list has [coefficientCount] entries. Only indices through
/// [degree] are meaningful; later entries are normalized to zero to preserve
/// the fixed native layout. [maxResidual] records the largest fit residual at
/// native sample coordinates.
final class SolarBesselianPolynomial {
  SolarBesselianPolynomial({
    required this.referenceEpoch,
    required this.spanHours,
    required this.sampleStepHours,
    required this.degree,
    required Iterable<double> xCoefficients,
    required Iterable<double> yCoefficients,
    required Iterable<double> zetaCoefficients,
    required Iterable<double> dDegreesCoefficients,
    required Iterable<double> muDegreesCoefficients,
    required Iterable<double> l1Coefficients,
    required Iterable<double> l2Coefficients,
    required this.f1Degrees,
    required this.f2Degrees,
    required this.tanF1,
    required this.tanF2,
    required this.center,
    required this.maxResidual,
  }) : xCoefficients = _freezeBesselianCoefficients(
         xCoefficients,
         'xCoefficients',
         degree,
       ),
       yCoefficients = _freezeBesselianCoefficients(
         yCoefficients,
         'yCoefficients',
         degree,
       ),
       zetaCoefficients = _freezeBesselianCoefficients(
         zetaCoefficients,
         'zetaCoefficients',
         degree,
       ),
       dDegreesCoefficients = _freezeBesselianCoefficients(
         dDegreesCoefficients,
         'dDegreesCoefficients',
         degree,
       ),
       muDegreesCoefficients = _freezeBesselianCoefficients(
         muDegreesCoefficients,
         'muDegreesCoefficients',
         degree,
       ),
       l1Coefficients = _freezeBesselianCoefficients(
         l1Coefficients,
         'l1Coefficients',
         degree,
       ),
       l2Coefficients = _freezeBesselianCoefficients(
         l2Coefficients,
         'l2Coefficients',
         degree,
       ) {
    if (!spanHours.isFinite || spanHours <= 0) {
      throw ArgumentError.value(
        spanHours,
        'spanHours',
        'must be a positive finite number',
      );
    }
    if (!sampleStepHours.isFinite || sampleStepHours <= 0) {
      throw ArgumentError.value(
        sampleStepHours,
        'sampleStepHours',
        'must be a positive finite number',
      );
    }
    if (degree < 1 || degree >= coefficientCount) {
      throw RangeError.range(degree, 1, coefficientCount - 1, 'degree');
    }
    for (final value in [f1Degrees, f2Degrees, tanF1, tanF2]) {
      if (!value.isFinite) {
        throw ArgumentError.value(value, 'Besselian polynomial field');
      }
    }
  }

  /// Number of terms in every coefficient array in the C ABI.
  static const coefficientCount = 8;

  final JulianDate<TtScale> referenceEpoch;
  final double spanHours;
  final double sampleStepHours;
  final int degree;
  final List<double> xCoefficients;
  final List<double> yCoefficients;
  final List<double> zetaCoefficients;
  final List<double> dDegreesCoefficients;
  final List<double> muDegreesCoefficients;
  final List<double> l1Coefficients;
  final List<double> l2Coefficients;
  final double f1Degrees;
  final double f2Degrees;
  final double tanF1;
  final double tanF2;
  final SolarBesselianElements center;
  final SolarBesselianElements maxResidual;
}

List<double> _freezeBesselianCoefficients(
  Iterable<double> source,
  String name,
  int degree,
) {
  final values = List<double>.of(source, growable: false);
  if (values.length != SolarBesselianPolynomial.coefficientCount) {
    throw ArgumentError.value(
      source,
      name,
      'must contain ${SolarBesselianPolynomial.coefficientCount} terms',
    );
  }
  if (values.any((value) => !value.isFinite)) {
    throw ArgumentError.value(source, name, 'must contain only finite values');
  }
  return List.unmodifiable([
    for (var index = 0; index < values.length; index++)
      index <= degree ? values[index] : 0.0,
  ]);
}
