import '../backend/backend_call.dart';
import '../backend/time_backend.dart';
import '../result_flags.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_models.dart';
import '../time/time_scale.dart';
import '../interop/value_validation.dart';
import 'wasm_module.dart';

/// Transport adapter; conversion and reverse-solver policy lives in Time.
final class WebTimeBackend implements TimeBackend {
  WebTimeBackend(this._backend, this._handle);
  final WasmBackend _backend;
  final int _handle;
  BackendCall<T> _result<T>(WasmReply reply, T Function(List<double>) read) =>
      BackendCall(
        status: reply.status,
        flags: ResultFlags(reply.values[0].toInt()),
        value: reply.status == 0 ? read(reply.values) : null,
      );
  List<num> _calendar(
    AstroDateTime value, {
    int model = 0,
    bool hasDeltaT = false,
    double deltaT = 0,
    double tai = 0,
    double dut1 = 0,
  }) {
    validateNativeInt32(value.year, 'year');
    return [
      0,
      0,
      0,
      hasDeltaT ? 1 : 0,
      model,
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.fractionalSecond,
      hasDeltaT ? deltaT : tai,
      dut1,
    ];
  }

  JulianDate<S> _jd<S extends TimeScale>(List<double> v, int start) =>
      JulianDate<S>.fromParts(v[start].toInt(), v[start + 1]);
  List<num> _date(JulianDate<TimeScale> value) {
    if (value.dayNumber.abs() > 9007199254740991) {
      throw RangeError('Julian day exceeds the exact JS integer range.');
    }
    return [value.dayNumber, value.dayFraction];
  }

  @override
  BackendCall<JulianDate<S>> julianDay<S extends TimeScale>(
    AstroDateTime value,
  ) =>
      _result(_backend.time(_handle, 0, _calendar(value)), (v) => _jd<S>(v, 1));
  @override
  BackendCall<AstroDateTime> reverseJulianDay(JulianDate<TimeScale> value) =>
      _result(
        _backend.time(_handle, 1, [0, ..._date(value)]),
        (v) => AstroDateTime(
          v[1].toInt(),
          v[2].toInt(),
          v[3].toInt(),
          v[4].toInt(),
          v[5].toInt(),
        ).addNanoseconds((v[6] * 1e9).round()),
      );
  @override
  BackendCall<bool> configure(int operation, List<num> values) =>
      _result(_backend.configure(_handle, operation, values), (_) => true);
  @override
  double scalar(TimeScalar operation, double value, [double second = 0]) =>
      _backend.time(_handle, 2, [operation.index, value, second]).values[1];
  @override
  BackendCall<JulianDate<S>> convert<S extends TimeScale>(
    TimeConversion conversion,
    JulianDate<TimeScale> value, {
    double offset = 0,
    TdbModel model = TdbModel.fastPeriodic,
  }) => _result(
    _backend.time(_handle, 3, [
      conversion.index,
      ..._date(value),
      offset,
      model.id,
    ]),
    (v) => _jd<S>(v, 1),
  );
  @override
  BackendCall<double> taiMinusUtc(AstroDateTime value) =>
      _result(_backend.time(_handle, 4, _calendar(value)), (v) => v[1]);
  PreciseTimeScales _precise(List<double> v) => PreciseTimeScales(
    utc: _jd<UtcScale>(v, 1),
    tai: _jd<TaiScale>(v, 3),
    tt: _jd<TtScale>(v, 5),
    ut1: _jd<Ut1Scale>(v, 7),
    tdb: _jd<TdbScale>(v, 9),
    taiMinusUtcSeconds: v[11],
    dut1Seconds: v[12],
    deltaTSeconds: v[13],
  );
  @override
  BackendCall<PreciseTimeScales> preciseScales(
    AstroDateTime value,
    double taiMinusUtc,
    double dut1,
    TdbModel model,
  ) => _result(
    _backend.time(
      _handle,
      5,
      _calendar(value, model: model.id, tai: taiMinusUtc, dut1: dut1),
    ),
    _precise,
  );
  @override
  BackendCall<TimeScaleResult<PreciseTimeScales>> scalesFromUtc(
    AstroDateTime value,
  ) => _result(
    _backend.time(_handle, 6, _calendar(value)),
    (v) => TimeScaleResult(
      value: _precise(v),
      diagnostic: TimeScaleDiagnostic(
        route: TimeScaleRoute.fromId(v[14].toInt()),
        rawRouteId: v[14].toInt(),
        fallbackReason: TimeScaleFallbackReason.fromId(v[15].toInt()),
        rawFallbackReasonId: v[15].toInt(),
        flags: {
          for (final f in TimeScaleDiagnosticFlag.values)
            if ((v[16].toInt() & f.mask) != 0) f,
        },
        tdbModelId: v[17].toInt(),
        deltaTModelId: v[18].toInt(),
        ephemerisFamilyId: v[19].toInt(),
        taiMinusUtcSeconds: v[20],
        dut1Seconds: v[21],
        deltaTSeconds: v[22],
      ),
    ),
  );
  @override
  BackendCall<EstimatedTimeScales> estimatedScales(
    AstroDateTime value,
    double? deltaT,
    TdbModel model,
  ) => _result(
    _backend.time(
      _handle,
      7,
      _calendar(
        value,
        model: model.id,
        hasDeltaT: deltaT != null,
        deltaT: deltaT ?? 0,
      ),
    ),
    (v) => EstimatedTimeScales(
      ut1: _jd<Ut1Scale>(v, 1),
      tt: _jd<TtScale>(v, 3),
      tdb: _jd<TdbScale>(v, 5),
      deltaTSeconds: v[7],
    ),
  );
}
