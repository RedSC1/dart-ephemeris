import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'lunar_eclipse_models.dart';

/// The five fixed global solar-eclipse contact slots.
enum TaiyinSolarEclipseContact {
  partialBegin(0),
  centralBegin(1),
  greatest(2),
  centralEnd(3),
  partialEnd(4);

  const TaiyinSolarEclipseContact(this.nativeIndex);

  /// Index in the fixed native contact array.
  final int nativeIndex;
}

/// The five fixed contact slots in a local solar-eclipse result.
///
/// Unlike [TaiyinSolarEclipseContact], local contacts are C1, C2, C3, C4,
/// and greatest eclipse, respectively.
enum TaiyinLocalSolarEclipseContact {
  partialBegin(0),
  centralBegin(1),
  centralEnd(2),
  partialEnd(3),
  greatest(4);

  const TaiyinLocalSolarEclipseContact(this.nativeIndex);

  /// Index in the fixed native contact array.
  final int nativeIndex;
}

/// Options for solving one global or local solar-eclipse lunation.
enum TaiyinSolarEclipseSolveOption {
  /// Requests global contact values where the operation supports them.
  includeContacts(1 << 33),

  /// Uses the loaded TLL1 lunar limb model when polishing contacts.
  lunarLimbCorrection(1 << 38);

  const TaiyinSolarEclipseSolveOption(this.mask);

  final int mask;
}

/// Options for finding solar eclipses.
enum TaiyinSolarEclipseSearchOption {
  /// Requests global contact values where the operation supports them.
  includeContacts(1 << 33),

  /// Searches backwards from the supplied start coordinate.
  backward(1 << 35),

  /// Uses the loaded TLL1 lunar limb model when polishing contacts.
  lunarLimbCorrection(1 << 38);

  const TaiyinSolarEclipseSearchOption(this.mask);

  final int mask;
}

/// Options for global solar-eclipse route calculations.
enum TaiyinSolarEclipseRouteOption {
  /// Uses the loaded TLL1 lunar limb model for non-center path limits.
  lunarLimbCorrection(1 << 38);

  const TaiyinSolarEclipseRouteOption(this.mask);

  final int mask;
}

/// Local solar-eclipse visibility bits returned by the native C ABI.
///
/// Solar eclipses have no separate penumbral phase, so lunar-only penumbral
/// begin and end visibility flags are intentionally not represented here.
enum TaiyinLocalSolarEclipseVisibilityFlag {
  visibleAtObserver(1 << 7),
  maximumVisible(1 << 8),
  partialBeginVisible(1 << 9),
  centralBeginVisible(1 << 10),
  centralEndVisible(1 << 11),
  partialEndVisible(1 << 12);

  const TaiyinLocalSolarEclipseVisibilityFlag(this.mask);

  final int mask;

  static Set<TaiyinLocalSolarEclipseVisibilityFlag> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// A global solar eclipse, or the explicit no-eclipse result for one lunation.
final class TaiyinSolarEclipseResult<S extends TimeScale> {
  TaiyinSolarEclipseResult({
    required Set<TaiyinEclipseKind> kinds,
    required this.maximum,
    required this.deltaTSeconds,
    required this.axisDistanceKilometers,
    required this.penumbraRadiusKilometers,
    required this.coreRadiusKilometers,
    required this.penumbralMarginKilometers,
    required this.centralMarginKilometers,
    required this.maximumLatitudeDegrees,
    required this.maximumLongitudeDegrees,
    required Map<TaiyinSolarEclipseContact, JulianDate<S>?> contacts,
  }) : kinds = Set.unmodifiable(kinds),
       contacts = Map.unmodifiable(contacts);

  final Set<TaiyinEclipseKind> kinds;

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
  final Map<TaiyinSolarEclipseContact, JulianDate<S>?> contacts;

  /// Whether native code found a solar eclipse at this lunation.
  bool get hasEclipse => kinds.isNotEmpty;
}

/// A solar eclipse at the observer location configured on a context.
final class TaiyinLocalSolarEclipseResult<S extends TimeScale> {
  TaiyinLocalSolarEclipseResult({
    required Set<TaiyinEclipseKind> kinds,
    required Set<TaiyinLocalSolarEclipseVisibilityFlag> visibility,
    required this.maximum,
    required this.deltaTSeconds,
    required this.magnitude,
    required this.obscuration,
    required this.sunAltitudeDegrees,
    required this.sunAzimuthDegrees,
    required Map<TaiyinLocalSolarEclipseContact, JulianDate<S>?> contacts,
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

  final Set<TaiyinEclipseKind> kinds;
  final Set<TaiyinLocalSolarEclipseVisibilityFlag> visibility;
  final JulianDate<S>? maximum;
  final double? deltaTSeconds;
  final double? magnitude;
  final double? obscuration;
  final double? sunAltitudeDegrees;
  final double? sunAzimuthDegrees;
  final Map<TaiyinLocalSolarEclipseContact, JulianDate<S>?> contacts;
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
final class TaiyinLocalSolarEclipseCircumstances<S extends TimeScale> {
  const TaiyinLocalSolarEclipseCircumstances({
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
final class TaiyinSolarEclipseRoutePoint {
  const TaiyinSolarEclipseRoutePoint({
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
final class TaiyinSolarEclipseRouteRow {
  const TaiyinSolarEclipseRouteRow({
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
  final TaiyinSolarEclipseRoutePoint centerLine;
  final TaiyinSolarEclipseRoutePoint penumbralNorthLimit;
  final TaiyinSolarEclipseRoutePoint penumbralSouthLimit;
  final TaiyinSolarEclipseRoutePoint northLimit;
  final TaiyinSolarEclipseRoutePoint southLimit;
  final TaiyinSolarEclipseRoutePoint halfMagnitudeNorthLimit;
  final TaiyinSolarEclipseRoutePoint halfMagnitudeSouthLimit;
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

/// Fundamental-plane quantities for a solar eclipse at one TT coordinate.
///
/// [tHours] is the Besselian time offset associated with the coordinate. The
/// other values retain the conventional Besselian names used by eclipse-path
/// references; angular fields are expressed in degrees.
final class TaiyinSolarBesselianElements {
  const TaiyinSolarBesselianElements({
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
final class TaiyinSolarBesselianPolynomial {
  TaiyinSolarBesselianPolynomial({
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
  final TaiyinSolarBesselianElements center;
  final TaiyinSolarBesselianElements maxResidual;
}

List<double> _freezeBesselianCoefficients(
  Iterable<double> source,
  String name,
  int degree,
) {
  final values = List<double>.of(source, growable: false);
  if (values.length != TaiyinSolarBesselianPolynomial.coefficientCount) {
    throw ArgumentError.value(
      source,
      name,
      'must contain ${TaiyinSolarBesselianPolynomial.coefficientCount} terms',
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
