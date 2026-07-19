import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// A local mean solar-time coordinate bound to its geographic longitude.
///
/// Keeping the longitude with the coordinate prevents a conversion from
/// accidentally using a different meridian.
final class LocalMeanSolarTime {
  LocalMeanSolarTime.fromUt1(
    JulianDate<Ut1Scale> ut1, {
    required double longitudeRadians,
  }) : longitudeRadians = _requireSolarLongitude(longitudeRadians),
       coordinate = JulianDate<LocalMeanSolarTimeScale>.fromParts(
         ut1.dayNumber,
         ut1.dayFraction + longitudeRadians / (2.0 * _pi),
       );

  LocalMeanSolarTime.fromCoordinate(
    this.coordinate, {
    required double longitudeRadians,
  }) : longitudeRadians = _requireSolarLongitude(longitudeRadians);

  /// The split local-mean Julian-date coordinate.
  final JulianDate<LocalMeanSolarTimeScale> coordinate;

  /// East-positive geographic longitude in radians.
  final double longitudeRadians;

  /// Recovers the UT1 coordinate without collapsing the split representation.
  JulianDate<Ut1Scale> toUt1() {
    return JulianDate<Ut1Scale>.fromParts(
      coordinate.dayNumber,
      coordinate.dayFraction - longitudeRadians / (2.0 * _pi),
    );
  }
}

/// A local apparent solar-time coordinate bound to its geographic longitude.
final class LocalApparentSolarTime {
  LocalApparentSolarTime.fromCoordinate(
    this.coordinate, {
    required double longitudeRadians,
  }) : longitudeRadians = _requireSolarLongitude(longitudeRadians);

  /// The split local-apparent Julian-date coordinate.
  final JulianDate<LocalApparentSolarTimeScale> coordinate;

  /// East-positive geographic longitude in radians.
  final double longitudeRadians;
}

/// The equation of time and the native coordinates used to evaluate it.
final class TaiyinEquationOfTime {
  const TaiyinEquationOfTime({
    required this.ut1,
    required this.tt,
    required this.equationDays,
    required this.equationSeconds,
    required this.apparentSunRightAscensionRadians,
    required this.greenwichApparentSiderealTimeRadians,
  });

  /// The resolved UT1 coordinate.
  final JulianDate<Ut1Scale> ut1;

  /// The resolved TT coordinate.
  final JulianDate<TtScale> tt;

  /// Apparent solar time minus mean solar time, in days.
  final double equationDays;

  /// Apparent solar time minus mean solar time, in seconds.
  final double equationSeconds;

  /// Apparent right ascension of the Sun.
  final double apparentSunRightAscensionRadians;

  /// Greenwich apparent sidereal time.
  final double greenwichApparentSiderealTimeRadians;
}

const double _pi = 3.14159265358979323846264338327950288;

double _requireSolarLongitude(double value) {
  if (!value.isFinite || value < -_pi || value > _pi) {
    throw ArgumentError.value(
      value,
      'longitudeRadians',
      'must be finite and in [-pi, pi]',
    );
  }
  return value;
}
