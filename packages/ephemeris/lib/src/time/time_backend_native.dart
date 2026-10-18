import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../backend/backend_call.dart';
import '../backend/time_backend.dart';
import '../bindings/taiyin_bindings.g.dart';
import '../interop/calendar.dart';
import '../interop/call_result.dart';
import '../interop/julian_date.dart';
import 'astro_date_time.dart';
import 'julian_date.dart';
import 'time_models.dart';
import 'time_scale.dart';

final class NativeTimeBackend implements TimeBackend {
  NativeTimeBackend(this._bindings, this._context);
  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  BackendCall<T> _result<T>(int raw, T Function() read) {
    final d = decodeNativeCallResult(raw);
    return BackendCall(
      status: d.status,
      flags: d.flags,
      value: d.status == 0 ? read() : null,
    );
  }

  @override
  BackendCall<JulianDate<S>> julianDay<S extends TimeScale>(
    AstroDateTime value,
  ) => using((arena) {
    final out = arena<taiyin_split_julian_date>();
    final raw = _bindings.taiyin_julian_day_split(
      writeNativeCalendar(_bindings, arena, value),
      out,
    );
    return _result(raw, () => readJulianDate<S>(out.ref));
  });
  @override
  BackendCall<AstroDateTime> reverseJulianDay(JulianDate<TimeScale> value) =>
      using((arena) {
        final out = arena<taiyin_calendar_datetime>();
        _bindings.taiyin_calendar_datetime_init(out);
        final raw = _bindings.taiyin_reverse_julian_day_split(
          writeJulianDate(arena, value),
          out,
        );
        return _result(raw, () => readCalendarDateTime(out.ref));
      });
  @override
  BackendCall<bool> configure(int operation, List<num> values) {
    final raw = switch (operation) {
      1 => _bindings.taiyin_context_set_allow_utc_out_of_range_estimate(
        _context,
        values[0].toInt(),
      ),
      11 => _bindings.taiyin_context_set_delta_t_model(
        _context,
        values[0].toInt(),
        values[1].toInt(),
      ),
      12 => _bindings.taiyin_context_set_tdb_model(_context, values[0].toInt()),
      _ => throw ArgumentError.value(operation),
    };
    return _result(raw, () => true);
  }

  @override
  double scalar(
    TimeScalar operation,
    double value, [
    double second = 0,
  ]) => switch (operation) {
    TimeScalar.decimalYear => _bindings.taiyin_decimal_year_from_jd(value),
    TimeScalar.centuries => _bindings.taiyin_julian_centuries_from_j2000(value),
    TimeScalar.millennia => _bindings.taiyin_julian_millennia_from_j2000(value),
    TimeScalar.deltaTYear =>
      _bindings.taiyin_estimated_delta_t_seconds_for_decimal_year(value),
    TimeScalar.deltaTUt1 => _bindings.taiyin_estimated_delta_t_seconds_from_ut1(
      value,
    ),
    TimeScalar.deltaTTt => _bindings.taiyin_estimated_delta_t_seconds_from_tt(
      value,
    ),
    TimeScalar.deltaTOffsets =>
      _bindings.taiyin_delta_t_from_tai_minus_utc_and_dut1(value, second),
  };
  @override
  BackendCall<JulianDate<S>> convert<S extends TimeScale>(
    TimeConversion conversion,
    JulianDate<TimeScale> value, {
    double offset = 0,
    TdbModel model = TdbModel.fastPeriodic,
  }) => using((arena) {
    final input = writeJulianDate(arena, value),
        out = arena<taiyin_split_julian_date>();
    final raw = switch (conversion) {
      TimeConversion.ttToTdb => _bindings.taiyin_tt_to_tdb_split(
        input,
        model.id,
        out,
      ),
      TimeConversion.tdbToTt => _bindings.taiyin_tdb_to_tt_split(
        input,
        model.id,
        out,
      ),
      TimeConversion.utcToTai => _bindings.taiyin_utc_to_tai_split(
        input,
        offset,
        out,
      ),
      TimeConversion.taiToTt => _bindings.taiyin_tai_to_tt_split(input, out),
      TimeConversion.utcToTt => _bindings.taiyin_utc_to_tt_split(
        input,
        offset,
        out,
      ),
      TimeConversion.utcToUt1 => _bindings.taiyin_utc_to_ut1_split(
        input,
        offset,
        out,
      ),
      TimeConversion.ttToUt1 => _bindings.taiyin_tt_to_ut1_split(
        input,
        offset,
        out,
      ),
      TimeConversion.ut1ToTt => _bindings.taiyin_ut1_to_tt_split(
        input,
        offset,
        out,
      ),
    };
    return _result(raw, () => readJulianDate<S>(out.ref));
  });
  @override
  BackendCall<double> taiMinusUtc(AstroDateTime value) => using((arena) {
    final out = arena<Double>();
    final raw = _bindings.taiyin_tai_minus_utc_seconds(
      writeNativeCalendar(_bindings, arena, value),
      out,
    );
    return _result(raw, () => out.value);
  });
  @override
  BackendCall<PreciseTimeScales> preciseScales(
    AstroDateTime value,
    double taiMinusUtc,
    double dut1,
    TdbModel model,
  ) => using((arena) {
    final out = arena<taiyin_split_precise_time_scales>();
    _bindings.taiyin_split_precise_time_scales_init(out);
    final raw = _bindings.taiyin_make_split_precise_time_scales_from_utc(
      writeNativeCalendar(_bindings, arena, value),
      taiMinusUtc,
      dut1,
      model.id,
      out,
    );
    return _result(raw, () => _readPrecise(out.ref));
  });
  @override
  BackendCall<TimeScaleResult<PreciseTimeScales>> scalesFromUtc(
    AstroDateTime value,
  ) => using((arena) {
    final out = arena<taiyin_split_precise_time_scales>(),
        diag = arena<taiyin_time_scale_diagnostic>();
    _bindings.taiyin_split_precise_time_scales_init(out);
    _bindings.taiyin_time_scale_diagnostic_init(diag);
    final raw = _bindings.taiyin_make_split_time_scales_from_utc(
      _context,
      writeNativeCalendar(_bindings, arena, value),
      out,
      diag,
    );
    return _result(
      raw,
      () => TimeScaleResult(
        value: _readPrecise(out.ref),
        diagnostic: _readDiagnostic(diag.ref),
      ),
    );
  });
  @override
  BackendCall<EstimatedTimeScales> estimatedScales(
    AstroDateTime value,
    double? deltaT,
    TdbModel model,
  ) => using((arena) {
    final out = arena<taiyin_split_estimated_time_scales>();
    _bindings.taiyin_split_estimated_time_scales_init(out);
    final input = writeNativeCalendar(_bindings, arena, value);
    final raw = deltaT == null
        ? _bindings.taiyin_make_split_estimated_time_scales_from_ut(
            input,
            model.id,
            out,
          )
        : _bindings.taiyin_make_split_time_scales_from_ut_delta_t(
            input,
            deltaT,
            model.id,
            out,
          );
    return _result(raw, () => _readEstimated(out.ref));
  });
  PreciseTimeScales _readPrecise(taiyin_split_precise_time_scales value) {
    return PreciseTimeScales(
      utc: readJulianDate<UtcScale>(value.utc),
      tai: readJulianDate<TaiScale>(value.tai),
      tt: readJulianDate<TtScale>(value.tt),
      ut1: readJulianDate<Ut1Scale>(value.ut1),
      tdb: readJulianDate<TdbScale>(value.tdb),
      taiMinusUtcSeconds: value.tai_minus_utc_seconds,
      dut1Seconds: value.dut1_seconds,
      deltaTSeconds: value.delta_t_seconds,
    );
  }

  EstimatedTimeScales _readEstimated(taiyin_split_estimated_time_scales value) {
    return EstimatedTimeScales(
      ut1: readJulianDate<Ut1Scale>(value.ut1),
      tt: readJulianDate<TtScale>(value.tt),
      tdb: readJulianDate<TdbScale>(value.tdb),
      deltaTSeconds: value.delta_t_seconds,
    );
  }

  TimeScaleDiagnostic _readDiagnostic(taiyin_time_scale_diagnostic value) {
    final flags = {
      for (final flag in TimeScaleDiagnosticFlag.values)
        if ((value.flags & flag.mask) != 0) flag,
    };
    return TimeScaleDiagnostic(
      route: TimeScaleRoute.fromId(value.route),
      rawRouteId: value.route,
      fallbackReason: TimeScaleFallbackReason.fromId(value.fallback_reason),
      rawFallbackReasonId: value.fallback_reason,
      flags: flags,
      tdbModelId: value.tdb_model_id,
      deltaTModelId: value.delta_t_model_id,
      ephemerisFamilyId: value.ephemeris_family_id,
      taiMinusUtcSeconds: value.tai_minus_utc_seconds,
      dut1Seconds: value.dut1_seconds,
      deltaTSeconds: value.delta_t_seconds,
    );
  }
}
