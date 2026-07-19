import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/taiyin_bindings.g.dart';
import 'astro_date_time.dart';
import 'julian_date.dart';
import 'time_models.dart';
import 'time_scale.dart';

/// Time-scale conversion and Delta-T operations backed by Taiyin.
final class TaiyinTime {
  /// Internal constructor used by an owning Taiyin context.
  TaiyinTime.internal(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final void Function(int status) _checkStatus;

  /// Selects how UTC conversions obtain UT1 and Delta-T.
  ///
  /// Context configuration must finish before concurrent calculations begin.
  void setPolicy(TimeScalePolicy policy) {
    _ensureOpen();
    _checkStatus(
      _bindings.taiyin_context_set_time_scale_policy(_context, policy.id),
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
    return JulianDate<TdbScale>.fromDouble(
      _finite(
        _bindings.taiyin_tt_to_tdb(tt.toDouble(), model.id),
        'TDB Julian date',
      ),
    );
  }

  JulianDate<TtScale> tdbToTt(
    JulianDate<TdbScale> tdb, {
    TdbModel model = TdbModel.fastPeriodic,
  }) {
    _ensureOpen();
    return JulianDate<TtScale>.fromDouble(
      _finite(
        _bindings.taiyin_tdb_to_tt(tdb.toDouble(), model.id),
        'TT Julian date',
      ),
    );
  }

  /// Looks up TAI−UTC using Taiyin's built-in leap-second table.
  double taiMinusUtc(AstroDateTime utc) {
    _ensureOpen();
    return using((arena) {
      final calendar = _writeCalendar(arena, utc);
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
    return JulianDate<TaiScale>.fromDouble(
      _finite(
        _bindings.taiyin_utc_to_tai(utc.toDouble(), taiMinusUtcSeconds),
        'TAI Julian date',
      ),
    );
  }

  JulianDate<TtScale> taiToTt(JulianDate<TaiScale> tai) {
    _ensureOpen();
    return JulianDate<TtScale>.fromDouble(
      _finite(_bindings.taiyin_tai_to_tt(tai.toDouble()), 'TT Julian date'),
    );
  }

  JulianDate<TtScale> utcToTt(
    JulianDate<UtcScale> utc, {
    required double taiMinusUtcSeconds,
  }) {
    _ensureOpen();
    _requireFinite(taiMinusUtcSeconds, 'taiMinusUtcSeconds');
    return JulianDate<TtScale>.fromDouble(
      _finite(
        _bindings.taiyin_utc_to_tt(utc.toDouble(), taiMinusUtcSeconds),
        'TT Julian date',
      ),
    );
  }

  JulianDate<Ut1Scale> utcToUt1(
    JulianDate<UtcScale> utc, {
    required double dut1Seconds,
  }) {
    _ensureOpen();
    _requireFinite(dut1Seconds, 'dut1Seconds');
    return JulianDate<Ut1Scale>.fromDouble(
      _finite(
        _bindings.taiyin_utc_to_ut1(utc.toDouble(), dut1Seconds),
        'UT1 Julian date',
      ),
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
    return JulianDate<Ut1Scale>.fromDouble(
      _finite(
        _bindings.taiyin_tt_to_ut1(tt.toDouble(), deltaTSeconds),
        'UT1 Julian date',
      ),
    );
  }

  JulianDate<TtScale> ut1ToTt(
    JulianDate<Ut1Scale> ut1, {
    required double deltaTSeconds,
  }) {
    _ensureOpen();
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return JulianDate<TtScale>.fromDouble(
      _finite(
        _bindings.taiyin_ut1_to_tt(ut1.toDouble(), deltaTSeconds),
        'TT Julian date',
      ),
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
      final calendar = _writeCalendar(arena, utc);
      final output = arena<taiyin_precise_time_scales>();
      _bindings.taiyin_precise_time_scales_init(output);
      _checkStatus(
        _bindings.taiyin_make_precise_time_scales_from_utc(
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
      final calendar = _writeCalendar(arena, utc);
      final output = arena<taiyin_precise_time_scales>();
      final diagnostic = arena<taiyin_time_scale_diagnostic>();
      _bindings
        ..taiyin_precise_time_scales_init(output)
        ..taiyin_time_scale_diagnostic_init(diagnostic);
      _checkStatus(
        _bindings.taiyin_make_time_scales_from_utc(
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
      final calendar = _writeCalendar(arena, ut1);
      final output = arena<taiyin_estimated_time_scales>();
      _bindings.taiyin_estimated_time_scales_init(output);
      final status = deltaTSeconds == null
          ? _bindings.taiyin_make_estimated_time_scales_from_ut(
              calendar,
              tdbModel.id,
              output,
            )
          : _bindings.taiyin_make_time_scales_from_ut_delta_t(
              calendar,
              deltaTSeconds,
              tdbModel.id,
              output,
            );
      _checkStatus(status);
      return _readEstimated(output.ref);
    });
  }

  Pointer<taiyin_calendar_datetime> _writeCalendar(
    Arena arena,
    AstroDateTime value,
  ) {
    if (value.year < -2147483648 || value.year > 2147483647) {
      throw RangeError.range(value.year, -2147483648, 2147483647, 'year');
    }
    final native = arena<taiyin_calendar_datetime>();
    _bindings.taiyin_calendar_datetime_init(native);
    native.ref
      ..year = value.year
      ..month = value.month
      ..day = value.day
      ..hour = value.hour
      ..minute = value.minute
      ..second = value.fractionalSecond;
    return native;
  }

  PreciseTimeScales _readPrecise(taiyin_precise_time_scales value) {
    return PreciseTimeScales(
      utc: JulianDate<UtcScale>.fromDouble(value.jd_utc),
      tai: JulianDate<TaiScale>.fromDouble(value.jd_tai),
      tt: JulianDate<TtScale>.fromDouble(value.jd_tt),
      ut1: JulianDate<Ut1Scale>.fromDouble(value.jd_ut1),
      tdb: JulianDate<TdbScale>.fromDouble(value.jd_tdb),
      taiMinusUtcSeconds: value.tai_minus_utc_seconds,
      dut1Seconds: value.dut1_seconds,
      deltaTSeconds: value.delta_t_seconds,
    );
  }

  EstimatedTimeScales _readEstimated(taiyin_estimated_time_scales value) {
    return EstimatedTimeScales(
      ut1: JulianDate<Ut1Scale>.fromDouble(value.jd_ut1),
      tt: JulianDate<TtScale>.fromDouble(value.jd_tt),
      tdb: JulianDate<TdbScale>.fromDouble(value.jd_tdb),
      deltaTSeconds: value.delta_t_seconds,
    );
  }

  TimeScaleDiagnostic _readDiagnostic(taiyin_time_scale_diagnostic value) {
    final flags = {
      for (final flag in TimeScaleDiagnosticFlag.values)
        if (value.flags & flag.mask != 0) flag,
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
}
