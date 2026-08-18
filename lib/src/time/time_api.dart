import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/taiyin_bindings.g.dart';
import '../interop/calendar.dart';
import '../interop/julian_date.dart';
import 'astro_date_time.dart';
import 'julian_date.dart';
import 'time_models.dart';
import 'time_scale.dart';

typedef _UnarySplitConversion =
    int Function(
      Pointer<taiyin_split_julian_date>,
      Pointer<taiyin_split_julian_date>,
    );
typedef _OffsetSplitConversion =
    int Function(
      Pointer<taiyin_split_julian_date>,
      double,
      Pointer<taiyin_split_julian_date>,
    );
typedef _ModeledSplitConversion =
    int Function(
      Pointer<taiyin_split_julian_date>,
      int,
      Pointer<taiyin_split_julian_date>,
    );

/// Time-scale conversion and Delta-T operations backed by Ephemeris.
final class Time {
  /// Internal constructor used by an owning [EphemerisContext].
  Time.internal(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final void Function(int status) _checkStatus;

  /// Converts a calendar value to a Julian date through Taiyin's native
  /// calendar implementation.
  ///
  /// The type parameter labels the scale in which [value] is interpreted; no
  /// time-scale conversion is performed.
  JulianDate<S> julianDay<S extends TimeScale>(AstroDateTime value) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, value);
      final output = arena<taiyin_split_julian_date>();
      _checkStatus(_bindings.taiyin_julian_day_split(calendar, output));
      return readJulianDate<S>(output.ref);
    });
  }

  /// Converts a Julian date to a calendar value through Taiyin's native
  /// calendar implementation.
  ///
  /// Taiyin's C ABI returns the seconds component as a `double`. It is rounded
  /// to the nearest nanosecond when constructing [AstroDateTime].
  AstroDateTime reverseJulianDay<S extends TimeScale>(JulianDate<S> value) {
    _ensureOpen();
    return using((arena) {
      final input = writeJulianDate(arena, value);
      final output = arena<taiyin_calendar_datetime>();
      _bindings.taiyin_calendar_datetime_init(output);
      _checkStatus(_bindings.taiyin_reverse_julian_day_split(input, output));
      final calendar = output.ref;
      final minute = AstroDateTime(
        calendar.year,
        calendar.month,
        calendar.day,
        calendar.hour,
        calendar.minute,
      );
      return minute.addNanoseconds(
        (calendar.second * Duration.microsecondsPerSecond * 1000).round(),
      );
    });
  }

  /// Allows UTC entry points to fall back to an approximate UT1 plus
  /// Delta-T estimate when UTC/EOP data is missing or out of range.
  ///
  /// UTC entry points are strict by default. This never changes the
  /// semantics of UT1 entry points. Context configuration must finish before
  /// concurrent calculations begin.
  void setAllowUtcOutOfRangeEstimate(bool allow) {
    _ensureOpen();
    _checkStatus(
      _bindings.taiyin_context_set_allow_utc_out_of_range_estimate(
        _context,
        allow ? 1 : 0,
      ),
    );
  }

  /// Selects the TT/TDB conversion model on this context.
  void setTdbModel(TdbModel model) {
    _ensureOpen();
    _checkStatus(_bindings.taiyin_context_set_tdb_model(_context, model.id));
  }

  /// Selects the estimated Delta-T model and ephemeris family.
  void setDeltaTModel(
    DeltaTModel model, {
    EphemerisFamily family = EphemerisFamily.unknown,
  }) {
    _ensureOpen();
    _checkStatus(
      _bindings.taiyin_context_set_delta_t_model(_context, model.id, family.id),
    );
  }

  double decimalYear<S extends TimeScale>(JulianDate<S> value) {
    _ensureOpen();
    return _finite(
      _bindings.taiyin_decimal_year_from_jd(value.toDouble()),
      'decimal year',
    );
  }

  double julianCenturiesSinceJ2000<S extends TimeScale>(JulianDate<S> value) {
    _ensureOpen();
    return _finite(
      _bindings.taiyin_julian_centuries_from_j2000(value.toDouble()),
      'Julian centuries',
    );
  }

  double julianMillenniaSinceJ2000<S extends TimeScale>(JulianDate<S> value) {
    _ensureOpen();
    return _finite(
      _bindings.taiyin_julian_millennia_from_j2000(value.toDouble()),
      'Julian millennia',
    );
  }

  double estimatedDeltaTForDecimalYear(double decimalYear) {
    _ensureOpen();
    if (!decimalYear.isFinite) {
      throw ArgumentError.value(decimalYear, 'decimalYear', 'must be finite');
    }
    return _finite(
      _bindings.taiyin_estimated_delta_t_seconds_for_decimal_year(decimalYear),
      'estimated Delta-T',
    );
  }

  double estimatedDeltaTFromUt1(JulianDate<Ut1Scale> ut1) {
    _ensureOpen();
    return _finite(
      _bindings.taiyin_estimated_delta_t_seconds_from_ut1(ut1.toDouble()),
      'estimated Delta-T',
    );
  }

  double estimatedDeltaTFromTt(JulianDate<TtScale> tt) {
    _ensureOpen();
    return _finite(
      _bindings.taiyin_estimated_delta_t_seconds_from_tt(tt.toDouble()),
      'estimated Delta-T',
    );
  }

  JulianDate<TdbScale> ttToTdb(
    JulianDate<TtScale> tt, {
    TdbModel model = TdbModel.fastPeriodic,
  }) {
    _ensureOpen();
    return _convertModeled<TdbScale, TtScale>(
      tt,
      model,
      _bindings.taiyin_tt_to_tdb_split,
    );
  }

  JulianDate<TtScale> tdbToTt(
    JulianDate<TdbScale> tdb, {
    TdbModel model = TdbModel.fastPeriodic,
  }) {
    _ensureOpen();
    return _convertModeled<TtScale, TdbScale>(
      tdb,
      model,
      _bindings.taiyin_tdb_to_tt_split,
    );
  }

  /// Looks up TAI−UTC using Taiyin's built-in leap-second table.
  double taiMinusUtc(AstroDateTime utc) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      final output = arena<Double>();
      _checkStatus(_bindings.taiyin_tai_minus_utc_seconds(calendar, output));
      return output.value;
    });
  }

  JulianDate<TaiScale> utcToTai(
    JulianDate<UtcScale> utc, {
    required double taiMinusUtcSeconds,
  }) {
    _ensureOpen();
    _requireFinite(taiMinusUtcSeconds, 'taiMinusUtcSeconds');
    return _convertWithOffset<TaiScale, UtcScale>(
      utc,
      taiMinusUtcSeconds,
      _bindings.taiyin_utc_to_tai_split,
    );
  }

  JulianDate<TtScale> taiToTt(JulianDate<TaiScale> tai) {
    _ensureOpen();
    return _convert<TtScale, TaiScale>(tai, _bindings.taiyin_tai_to_tt_split);
  }

  JulianDate<TtScale> utcToTt(
    JulianDate<UtcScale> utc, {
    required double taiMinusUtcSeconds,
  }) {
    _ensureOpen();
    _requireFinite(taiMinusUtcSeconds, 'taiMinusUtcSeconds');
    return _convertWithOffset<TtScale, UtcScale>(
      utc,
      taiMinusUtcSeconds,
      _bindings.taiyin_utc_to_tt_split,
    );
  }

  JulianDate<Ut1Scale> utcToUt1(
    JulianDate<UtcScale> utc, {
    required double dut1Seconds,
  }) {
    _ensureOpen();
    _requireFinite(dut1Seconds, 'dut1Seconds');
    return _convertWithOffset<Ut1Scale, UtcScale>(
      utc,
      dut1Seconds,
      _bindings.taiyin_utc_to_ut1_split,
    );
  }

  double deltaT({
    required double taiMinusUtcSeconds,
    required double dut1Seconds,
  }) {
    _ensureOpen();
    _requireFinite(taiMinusUtcSeconds, 'taiMinusUtcSeconds');
    _requireFinite(dut1Seconds, 'dut1Seconds');
    return _finite(
      _bindings.taiyin_delta_t_from_tai_minus_utc_and_dut1(
        taiMinusUtcSeconds,
        dut1Seconds,
      ),
      'Delta-T',
    );
  }

  JulianDate<Ut1Scale> ttToUt1(
    JulianDate<TtScale> tt, {
    required double deltaTSeconds,
  }) {
    _ensureOpen();
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _convertWithOffset<Ut1Scale, TtScale>(
      tt,
      deltaTSeconds,
      _bindings.taiyin_tt_to_ut1_split,
    );
  }

  JulianDate<TtScale> ut1ToTt(
    JulianDate<Ut1Scale> ut1, {
    required double deltaTSeconds,
  }) {
    _ensureOpen();
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _convertWithOffset<TtScale, Ut1Scale>(
      ut1,
      deltaTSeconds,
      _bindings.taiyin_ut1_to_tt_split,
    );
  }

  /// Builds every time scale from UTC using explicit offsets.
  PreciseTimeScales preciseScalesFromUtc(
    AstroDateTime utc, {
    required double taiMinusUtcSeconds,
    required double dut1Seconds,
    TdbModel tdbModel = TdbModel.fastPeriodic,
  }) {
    _ensureOpen();
    _requireFinite(taiMinusUtcSeconds, 'taiMinusUtcSeconds');
    _requireFinite(dut1Seconds, 'dut1Seconds');
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      final output = arena<taiyin_split_precise_time_scales>();
      _bindings.taiyin_split_precise_time_scales_init(output);
      _checkStatus(
        _bindings.taiyin_make_split_precise_time_scales_from_utc(
          calendar,
          taiMinusUtcSeconds,
          dut1Seconds,
          tdbModel.id,
          output,
        ),
      );
      return _readPrecise(output.ref);
    });
  }

  /// Builds every time scale according to this context's policy and runtime
  /// EOP/leap-second data, returning the selected route as a diagnostic.
  TimeScaleResult<PreciseTimeScales> scalesFromUtc(AstroDateTime utc) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      final output = arena<taiyin_split_precise_time_scales>();
      final diagnostic = arena<taiyin_time_scale_diagnostic>();
      _bindings
        ..taiyin_split_precise_time_scales_init(output)
        ..taiyin_time_scale_diagnostic_init(diagnostic);
      _checkStatus(
        _bindings.taiyin_make_split_time_scales_from_utc(
          _context,
          calendar,
          output,
          diagnostic,
        ),
      );
      return TimeScaleResult(
        value: _readPrecise(output.ref),
        diagnostic: _readDiagnostic(diagnostic.ref),
      );
    });
  }

  /// Builds UT1, TT, and TDB from a calendar value interpreted as UT1.
  ///
  /// When [deltaTSeconds] is omitted, Taiyin's configured estimate is used.
  EstimatedTimeScales estimatedScalesFromUt1(
    AstroDateTime ut1, {
    double? deltaTSeconds,
    TdbModel tdbModel = TdbModel.fastPeriodic,
  }) {
    _ensureOpen();
    if (deltaTSeconds != null) {
      _requireFinite(deltaTSeconds, 'deltaTSeconds');
    }
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, ut1);
      final output = arena<taiyin_split_estimated_time_scales>();
      _bindings.taiyin_split_estimated_time_scales_init(output);
      final status = deltaTSeconds == null
          ? _bindings.taiyin_make_split_estimated_time_scales_from_ut(
              calendar,
              tdbModel.id,
              output,
            )
          : _bindings.taiyin_make_split_time_scales_from_ut_delta_t(
              calendar,
              deltaTSeconds,
              tdbModel.id,
              output,
            );
      _checkStatus(status);
      return _readEstimated(output.ref);
    });
  }

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

  double _finite(double value, String description) {
    if (!value.isFinite) {
      throw StateError('Taiyin returned a non-finite $description.');
    }
    return value;
  }

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }

  JulianDate<Output> _convert<
    Output extends TimeScale,
    Input extends TimeScale
  >(JulianDate<Input> value, _UnarySplitConversion conversion) {
    return using((arena) {
      final input = writeJulianDate(arena, value);
      final output = arena<taiyin_split_julian_date>();
      _checkStatus(conversion(input, output));
      return readJulianDate<Output>(output.ref);
    });
  }

  JulianDate<Output>
  _convertWithOffset<Output extends TimeScale, Input extends TimeScale>(
    JulianDate<Input> value,
    double offsetSeconds,
    _OffsetSplitConversion conversion,
  ) {
    return using((arena) {
      final input = writeJulianDate(arena, value);
      final output = arena<taiyin_split_julian_date>();
      _checkStatus(conversion(input, offsetSeconds, output));
      return readJulianDate<Output>(output.ref);
    });
  }

  JulianDate<Output>
  _convertModeled<Output extends TimeScale, Input extends TimeScale>(
    JulianDate<Input> value,
    TdbModel model,
    _ModeledSplitConversion conversion,
  ) {
    return using((arena) {
      final input = writeJulianDate(arena, value);
      final output = arena<taiyin_split_julian_date>();
      _checkStatus(conversion(input, model.id, output));
      return readJulianDate<Output>(output.ref);
    });
  }
}
