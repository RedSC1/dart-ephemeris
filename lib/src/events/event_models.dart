import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// High-level options supported by a particular event-search entry point.
///
/// Not every option applies to every method. Longitude searches and global
/// solar-transit searches accept [reverse]; local solar-transit methods accept
/// [refraction] or [noRefraction]. Other event searches reject options.
enum TaiyinEventSearchOption {
  reverse(1 << 32),
  refraction(1 << 33),
  noRefraction(1 << 34);

  const TaiyinEventSearchOption(this.mask);

  /// Bit used by the Taiyin C ABI.
  final int mask;
}

/// Direction of an elongation maximum relative to the Sun.
enum TaiyinGreatestElongationKind {
  eastern(1 << 0),
  western(1 << 1),
  unknown(0);

  const TaiyinGreatestElongationKind(this.mask);

  final int mask;

  static TaiyinGreatestElongationKind fromMask(int mask) {
    return values.firstWhere(
      (value) => value.mask == mask,
      orElse: () => unknown,
    );
  }
}

/// Physical classification of a solar transit.
enum TaiyinSolarTransitKind {
  partial(1 << 0),
  fullDisk(1 << 1);

  const TaiyinSolarTransitKind(this.mask);

  final int mask;
}

/// Whether a local observer can see an individual solar-transit contact.
enum TaiyinSolarTransitVisibilityFlag {
  visibleAtObserver(1 << 8),
  t1Visible(1 << 9),
  t2Visible(1 << 10),
  greatestVisible(1 << 11),
  t3Visible(1 << 12),
  t4Visible(1 << 13);

  const TaiyinSolarTransitVisibilityFlag(this.mask);

  final int mask;

  static Set<TaiyinSolarTransitVisibilityFlag> fromMask(int mask) {
    return Set.unmodifiable(values.where((value) => (mask & value.mask) != 0));
  }
}

/// A station in ecliptic longitude returned by a bounded event search.
final class TaiyinLongitudeStation<S extends TimeScale> {
  const TaiyinLongitudeStation({
    required this.coordinate,
    required this.longitudeRadians,
  });

  /// Scalar-JD coordinate returned by native code.
  final JulianDate<S> coordinate;
  final double longitudeRadians;
}

/// A matching exact aspect returned by a bounded event search.
final class TaiyinExactAspectEvent<S extends TimeScale> {
  const TaiyinExactAspectEvent({
    required this.coordinate,
    required this.aspectRadians,
  });

  /// Scalar-JD coordinate returned by native code.
  final JulianDate<S> coordinate;
  final double aspectRadians;
}

/// Physical diagnostics embedded in a greatest-elongation result.
final class TaiyinEventPhenomena {
  const TaiyinEventPhenomena({
    required this.phaseAngleRadians,
    required this.illuminatedFraction,
    required this.solarElongationRadians,
    required this.apparentDiameterRadians,
    required this.apparentMagnitude,
    required this.horizontalParallaxRadians,
  });

  final double phaseAngleRadians;
  final double illuminatedFraction;
  final double solarElongationRadians;
  final double apparentDiameterRadians;
  final double apparentMagnitude;

  /// Geocentric horizontal parallax, when native code provides it.
  ///
  /// This is normally available for lunar results. Other targets can have no
  /// meaningful horizontal parallax, which native code represents as a
  /// non-finite value.
  final double? horizontalParallaxRadians;
}

/// A maximum solar elongation of Mercury or Venus in UT1.
final class TaiyinGreatestElongationEvent {
  const TaiyinGreatestElongationEvent({
    required this.bodyId,
    required this.coordinate,
    required this.elongationRadians,
    required this.relativeLongitudeRadians,
    required this.kind,
    required this.iterationCount,
    required this.evaluationCount,
    required this.phenomena,
  });

  final int bodyId;

  /// Scalar-JD UT1 coordinate returned by native code.
  final JulianDate<Ut1Scale> coordinate;
  final double elongationRadians;
  final double relativeLongitudeRadians;
  final TaiyinGreatestElongationKind kind;
  final int iterationCount;
  final int evaluationCount;
  final TaiyinEventPhenomena phenomena;
}

/// The local minimum of angular separation between two targets.
final class TaiyinMinimumAngularSeparationEvent<S extends TimeScale> {
  const TaiyinMinimumAngularSeparationEvent({
    required this.bodyAId,
    required this.bodyBId,
    required this.coordinate,
    required this.separationRadians,
    required this.separationRateRadiansPerDay,
    required this.iterationCount,
    required this.evaluationCount,
  });

  final int bodyAId;
  final int bodyBId;

  /// Scalar-JD coordinate returned by native code.
  final JulianDate<S> coordinate;
  final double separationRadians;
  final double separationRateRadiansPerDay;
  final int iterationCount;
  final int evaluationCount;
}

/// Global or topocentric contact geometry of a Mercury or Venus solar transit.
final class TaiyinSolarTransitEvent {
  TaiyinSolarTransitEvent({
    required this.bodyId,
    required Set<TaiyinSolarTransitKind> kinds,
    required this.greatest,
    required this.minimumSeparationRadians,
    required this.sunRadiusRadians,
    required this.bodyRadiusRadians,
    required this.t1,
    required this.t2,
    required this.t3,
    required this.t4,
    required this.iterationCount,
    required this.evaluationCount,
  }) : kinds = Set.unmodifiable(kinds);

  final int bodyId;
  final Set<TaiyinSolarTransitKind> kinds;

  /// Scalar-JD UT1 coordinate of greatest transit.
  final JulianDate<Ut1Scale> greatest;
  final double minimumSeparationRadians;
  final double sunRadiusRadians;
  final double bodyRadiusRadians;
  final JulianDate<Ut1Scale>? t1;
  final JulianDate<Ut1Scale>? t2;
  final JulianDate<Ut1Scale>? t3;
  final JulianDate<Ut1Scale>? t4;
  final int iterationCount;
  final int evaluationCount;
}

/// Local visibility and contact geometry for a solar transit.
///
/// Contact altitudes and azimuths are ordered `T1`, `T2`, greatest, `T3`,
/// `T4`. Values preserve the native output, including its zero or non-finite
/// sentinel where a contact does not exist.
final class TaiyinLocalSolarTransitEvent {
  TaiyinLocalSolarTransitEvent({
    required this.global,
    required this.topocentric,
    required Set<TaiyinSolarTransitVisibilityFlag> visibilityFlags,
    required List<double> contactSunAltitudeDegrees,
    required List<double> contactSunAzimuthDegrees,
    required this.sunrise,
    required this.sunset,
  }) : visibilityFlags = Set.unmodifiable(visibilityFlags),
       contactSunAltitudeDegrees = List.unmodifiable(contactSunAltitudeDegrees),
       contactSunAzimuthDegrees = List.unmodifiable(contactSunAzimuthDegrees);

  final TaiyinSolarTransitEvent global;
  final TaiyinSolarTransitEvent topocentric;
  final Set<TaiyinSolarTransitVisibilityFlag> visibilityFlags;
  final List<double> contactSunAltitudeDegrees;
  final List<double> contactSunAzimuthDegrees;
  final JulianDate<Ut1Scale>? sunrise;
  final JulianDate<Ut1Scale>? sunset;
}
