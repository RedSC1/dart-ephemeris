import '../position/position_models.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'backend_call.dart';

enum PositionTimeKind { tt, ut1, tdb, ut1WithDeltaT, utc }

/// An explicit time coordinate; conversion is performed by the C++ kernel.
final class PositionTime {
  const PositionTime._(
    this.kind, {
    this.date,
    this.tt,
    this.utc,
    this.deltaT = 0,
  });
  factory PositionTime.atTt(TtJulianDate date) =>
      PositionTime._(PositionTimeKind.tt, date: date);
  factory PositionTime.atUt1(Ut1JulianDate date) =>
      PositionTime._(PositionTimeKind.ut1, date: date);
  factory PositionTime.atTdb(TdbJulianDate date, TtJulianDate tt) =>
      PositionTime._(PositionTimeKind.tdb, date: date, tt: tt);
  factory PositionTime.atUtc(AstroDateTime utc) =>
      PositionTime._(PositionTimeKind.utc, utc: utc);
  factory PositionTime.atUt1WithDeltaT(Ut1JulianDate date, double deltaT) {
    return PositionTime._(
      PositionTimeKind.ut1WithDeltaT,
      date: date,
      deltaT: deltaT,
    );
  }
  final PositionTimeKind kind;
  final JulianDate<TimeScale>? date;
  final TtJulianDate? tt;
  final AstroDateTime? utc;
  final double deltaT;
}

/// Internal typed service, implemented independently of the public Dart API.
/// Each instance borrows exactly one owning calculation context.
abstract interface class PositionBackend {
  BackendCall<List<double>> position(int target, PositionTime time, int flags);
  BackendCall<List<List<double>>> positions(
    List<int> targets,
    PositionTime time,
    int flags,
  );
  BackendCall<CartesianState> state(int target, PositionTime time, int flags);
}
