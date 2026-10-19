import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_models.dart';
import '../time/time_scale.dart';
import 'backend_call.dart';

enum TimeConversion {
  ttToTdb,
  tdbToTt,
  utcToTai,
  taiToTt,
  utcToTt,
  utcToUt1,
  ttToUt1,
  ut1ToTt,
}

enum TimeScalar {
  decimalYear,
  centuries,
  millennia,
  deltaTYear,
  deltaTUt1,
  deltaTTt,
  deltaTOffsets,
}

/// Typed kernel operations; the public Time facade owns conversion pipelines.
abstract interface class TimeBackend {
  BackendCall<JulianDate<S>> julianDay<S extends TimeScale>(
    AstroDateTime value,
  );
  BackendCall<AstroDateTime> reverseJulianDay(JulianDate<TimeScale> value);
  BackendCall<bool> configure(int operation, List<num> values);
  double scalar(TimeScalar operation, double value, [double second = 0]);
  BackendCall<JulianDate<S>> convert<S extends TimeScale>(
    TimeConversion conversion,
    JulianDate<TimeScale> value, {
    double offset = 0,
    TdbModel model = TdbModel.fastPeriodic,
  });
  BackendCall<double> taiMinusUtc(AstroDateTime value);
  BackendCall<PreciseTimeScales> preciseScales(
    AstroDateTime value,
    double taiMinusUtc,
    double dut1,
    TdbModel model,
  );
  BackendCall<TimeScaleResult<PreciseTimeScales>> scalesFromUtc(
    AstroDateTime value,
  );
  BackendCall<EstimatedTimeScales> estimatedScales(
    AstroDateTime value,
    double? deltaT,
    TdbModel model,
  );
}
