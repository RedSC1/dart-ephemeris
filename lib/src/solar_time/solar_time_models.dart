import '../time/julian_date.dart';
import '../time/time_scale.dart';

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
