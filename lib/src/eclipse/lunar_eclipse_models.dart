import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// Eclipse classifications returned by the native C ABI.
///
/// Lunar results use [penumbral], [partial], and [total]. The remaining
/// classifications are shared with the solar-eclipse APIs that follow.
enum TaiyinEclipseKind {
  penumbral(1 << 0),
  partial(1 << 1),
  total(1 << 2),
  annular(1 << 3),
  hybrid(1 << 4),
  central(1 << 5),
  noncentral(1 << 6);

  const TaiyinEclipseKind(this.mask);

  /// Bit used by the Taiyin C ABI.
  final int mask;

  static Set<TaiyinEclipseKind> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// The seven global lunar-eclipse contact slots.
enum TaiyinLunarEclipseContact {
  penumbralBegin(0),
  partialBegin(1),
  totalBegin(2),
  greatest(3),
  totalEnd(4),
  partialEnd(5),
  penumbralEnd(6);

  const TaiyinLunarEclipseContact(this.nativeIndex);

  /// Index in the fixed native contact array.
  final int nativeIndex;
}

/// Options for solving one lunar-eclipse lunation.
enum TaiyinLunarEclipseSolveOption {
  /// Requests all applicable P/U contacts in addition to greatest eclipse.
  includeContacts(1 << 33),

  /// Uses the loaded TLL1 lunar limb model when polishing contacts.
  lunarLimbCorrection(1 << 38);

  const TaiyinLunarEclipseSolveOption(this.mask);

  final int mask;
}

/// Options for finding lunar eclipses.
enum TaiyinLunarEclipseSearchOption {
  /// Requests all applicable P/U contacts in each returned event.
  includeContacts(1 << 33),

  /// Omits penumbral-only lunar eclipses from a search result.
  excludePenumbral(1 << 34),

  /// Searches backwards from the supplied start coordinate.
  backward(1 << 35),

  /// Uses the loaded TLL1 lunar limb model when polishing contacts.
  lunarLimbCorrection(1 << 38);

  const TaiyinLunarEclipseSearchOption(this.mask);

  final int mask;
}

/// Options for deriving local lunar-eclipse visibility.
enum TaiyinLocalLunarEclipseVisibilityOption {
  /// Applies the context's atmospheric refraction model to Moon altitudes.
  refraction(1 << 37);

  const TaiyinLocalLunarEclipseVisibilityOption(this.mask);

  final int mask;
}

/// Whether an eclipse or individual contact is visible to the local observer.
enum TaiyinLocalLunarEclipseVisibilityFlag {
  visibleAtObserver(1 << 7),
  maximumVisible(1 << 8),
  partialBeginVisible(1 << 9),
  totalBeginVisible(1 << 10),
  totalEndVisible(1 << 11),
  partialEndVisible(1 << 12),
  penumbralBeginVisible(1 << 13),
  penumbralEndVisible(1 << 14);

  const TaiyinLocalLunarEclipseVisibilityFlag(this.mask);

  final int mask;

  static Set<TaiyinLocalLunarEclipseVisibilityFlag> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// One local lunar-eclipse contact and the Moon's horizontal coordinates.
final class TaiyinLocalLunarEclipseContact<S extends TimeScale> {
  const TaiyinLocalLunarEclipseContact({
    required this.coordinate,
    required this.moonAltitudeDegrees,
    required this.moonAzimuthDegrees,
  });

  /// Scalar-JD coordinate returned by native code.
  final JulianDate<S> coordinate;
  final double? moonAltitudeDegrees;
  final double? moonAzimuthDegrees;
}

/// A global lunar eclipse, or the explicit no-eclipse result for one lunation.
///
/// [maximum] and all physical measures are `null` when native code reports no
/// eclipse for the requested lunation. Contact values are non-null only when
/// they were requested and applicable to the eclipse kind.
final class TaiyinLunarEclipseResult<S extends TimeScale> {
  TaiyinLunarEclipseResult({
    required Set<TaiyinEclipseKind> kinds,
    required this.maximum,
    required this.deltaTSeconds,
    required this.umbralMagnitude,
    required this.penumbralMagnitude,
    required this.axisDistanceRadians,
    required this.umbraRadiusRadians,
    required this.penumbraRadiusRadians,
    required this.moonRadiusRadians,
    required Map<TaiyinLunarEclipseContact, JulianDate<S>?> contacts,
  }) : kinds = Set.unmodifiable(kinds),
       contacts = Map.unmodifiable(contacts);

  final Set<TaiyinEclipseKind> kinds;

  /// Scalar-JD coordinate of greatest eclipse, if a lunar eclipse occurs.
  final JulianDate<S>? maximum;

  /// UT1 minus TT conversion metadata. Present for UT1 results only.
  final double? deltaTSeconds;
  final double? umbralMagnitude;
  final double? penumbralMagnitude;
  final double? axisDistanceRadians;
  final double? umbraRadiusRadians;
  final double? penumbraRadiusRadians;
  final double? moonRadiusRadians;
  final Map<TaiyinLunarEclipseContact, JulianDate<S>?> contacts;

  /// Whether native code found an eclipse at this lunation.
  bool get hasEclipse => kinds.isNotEmpty;
}

/// A global lunar eclipse as seen from the observer configured on a context.
final class TaiyinLocalLunarEclipseResult<S extends TimeScale> {
  TaiyinLocalLunarEclipseResult({
    required Set<TaiyinEclipseKind> kinds,
    required Set<TaiyinLocalLunarEclipseVisibilityFlag> visibility,
    required this.maximum,
    required this.deltaTSeconds,
    required this.umbralMagnitude,
    required this.penumbralMagnitude,
    required Map<TaiyinLunarEclipseContact, TaiyinLocalLunarEclipseContact<S>?>
    contacts,
    required this.moonrise,
    required this.moonset,
  }) : kinds = Set.unmodifiable(kinds),
       visibility = Set.unmodifiable(visibility),
       contacts = Map.unmodifiable(contacts);

  final Set<TaiyinEclipseKind> kinds;
  final Set<TaiyinLocalLunarEclipseVisibilityFlag> visibility;
  final JulianDate<S>? maximum;
  final double? deltaTSeconds;
  final double? umbralMagnitude;
  final double? penumbralMagnitude;
  final Map<TaiyinLunarEclipseContact, TaiyinLocalLunarEclipseContact<S>?>
  contacts;
  final JulianDate<S>? moonrise;
  final JulianDate<S>? moonset;

  bool get hasEclipse => kinds.isNotEmpty;
}
