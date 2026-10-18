import '../result_flags.dart';
import '../solar_time/solar_time_models.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';

abstract interface class SolarTimeBackend {
  OperationResult<EquationOfTime> equationOfTimeAtUt1(JulianDate<Ut1Scale> ut1);
  OperationResult<EquationOfTime> equationOfTimeAtTt(JulianDate<TtScale> tt);
  OperationResult<LocalApparentSolarTime> meanToApparent(
    LocalMeanSolarTime value,
  );
  OperationResult<LocalMeanSolarTime> apparentToMean(
    LocalApparentSolarTime value,
  );
}
