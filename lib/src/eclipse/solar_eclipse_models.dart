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

/// Local solar-eclipse visibility bits returned by the native C ABI.
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
