import '../backend/solar_time_backend.dart';
import '../result_flags.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'solar_time_models.dart';

/// Shared facade; true-solar-time evaluation and inversion use the C++ core.
final class SolarTimeApi {
  SolarTimeApi.internal(this._backend, this._ensureOpen);
  final SolarTimeBackend _backend;
  final void Function() _ensureOpen;
  OperationResult<EquationOfTime> equationOfTimeAtUt1(
    JulianDate<Ut1Scale> ut1,
  ) {
    _ensureOpen();
    return _backend.equationOfTimeAtUt1(ut1);
  }

  OperationResult<EquationOfTime> equationOfTimeAtTt(JulianDate<TtScale> tt) {
    _ensureOpen();
    return _backend.equationOfTimeAtTt(tt);
  }

  OperationResult<LocalApparentSolarTime> meanToApparent(
    LocalMeanSolarTime localMean,
  ) {
    _ensureOpen();
    return _backend.meanToApparent(localMean);
  }

  OperationResult<LocalMeanSolarTime> apparentToMean(
    LocalApparentSolarTime localApparent,
  ) {
    _ensureOpen();
    return _backend.apparentToMean(localApparent);
  }
}
