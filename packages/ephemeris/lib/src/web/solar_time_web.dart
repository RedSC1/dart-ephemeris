import '../backend/backend_call.dart';
import '../backend/solar_time_backend.dart';
import '../result_flags.dart';
import '../solar_time/solar_time_models.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'wasm_module.dart';
import 'diagnostic_web.dart';

final class WebSolarTimeBackend implements SolarTimeBackend {
  WebSolarTimeBackend(this._backend, this._handle, this._complete);
  final WasmBackend _backend;
  final int _handle;
  final BackendCallCompletion _complete;
  OperationResult<T> _call<T>(
    int op,
    JulianDate<TimeScale> jd,
    double lon,
    T Function(List<double>) read,
  ) {
    if (jd.dayNumber.abs() > 9007199254740991) {
      throw RangeError('JD outside exact JS range');
    }
    final reply = _backend.solarTime(_handle, op, [
      jd.dayNumber,
      jd.dayFraction,
      lon,
    ]);
    final flags = ResultFlags(reply.values[0].toInt());
    _complete(
      BackendCall<Object?>(
        status: reply.status,
        flags: flags,
        value: null,
        diagnostic: readWebDiagnostic(reply.values),
      ),
    );
    return operationResult(read(reply.values), flags);
  }

  EquationOfTime _equation(List<double> v) => EquationOfTime(
    ut1: Ut1JulianDate.fromParts(v[1].toInt(), v[2]),
    tt: TtJulianDate.fromParts(v[3].toInt(), v[4]),
    equationDays: v[5],
    equationSeconds: v[6],
    apparentSunRightAscensionRadians: v[7],
    greenwichApparentSiderealTimeRadians: v[8],
  );
  @override
  OperationResult<EquationOfTime> equationOfTimeAtUt1(
    JulianDate<Ut1Scale> ut1,
  ) => _call(0, ut1, 0, _equation);
  @override
  OperationResult<EquationOfTime> equationOfTimeAtTt(JulianDate<TtScale> tt) =>
      _call(1, tt, 0, _equation);
  @override
  OperationResult<LocalApparentSolarTime> meanToApparent(
    LocalMeanSolarTime value,
  ) => _call(
    2,
    value.coordinate,
    value.longitudeRadians,
    (v) => LocalApparentSolarTime.fromCoordinate(
      LocalApparentSolarJulianDate.fromParts(v[1].toInt(), v[2]),
      longitudeRadians: value.longitudeRadians,
    ),
  );
  @override
  OperationResult<LocalMeanSolarTime> apparentToMean(
    LocalApparentSolarTime value,
  ) => _call(
    3,
    value.coordinate,
    value.longitudeRadians,
    (v) => LocalMeanSolarTime.fromCoordinate(
      LocalMeanSolarJulianDate.fromParts(v[1].toInt(), v[2]),
      longitudeRadians: value.longitudeRadians,
    ),
  );
}
