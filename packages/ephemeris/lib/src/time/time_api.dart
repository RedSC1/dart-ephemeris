import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/taiyin_bindings.g.dart';
import '../interop/calendar.dart';
import '../interop/julian_date.dart';
import '../result_flags.dart';
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

/// A reverse conversion landed on an inserted UTC leap second that cannot be
/// represented by [UtcJulianDate]'s uniform 86,400-second-day coordinate.
///
/// Use a calendar API capable of preserving `second: 60`, or move the request
/// away from the leap-second label. Returning either adjacent UTC coordinate
/// would silently change the physical instant by one second, so the split-JD
/// conversion rejects the value instead.
final class UtcLeapSecondRepresentationError implements Exception {
  const UtcLeapSecondRepresentationError();

  @override
  String toString() =>
      'UtcLeapSecondRepresentationError: the physical instant is an inserted '
      'UTC leap second, which UtcJulianDate cannot represent.';
}

/// An automatic time-scale inversion did not converge to the requested
/// physical coordinate.
final class TimeScaleConvergenceError implements Exception {
  const TimeScaleConvergenceError(this.message);

  final String message;

  @override
  String toString() => 'TimeScaleConvergenceError: $message';
}

/// Time-scale conversion and Delta-T operations backed by Ephemeris.
final class Time {
  /// Internal constructor used by an owning [EphemerisContext].
  Time.internal(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
    this._configuredTdbModel,
    this._synchronizeTdbModel,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final ResultFlags Function(int status) _checkStatus;
  final TdbModel Function() _configuredTdbModel;
  final void Function(TdbModel model) _synchronizeTdbModel;

  /// TDB model used when a conversion does not supply an explicit override.
  TdbModel get configuredTdbModel => _configuredTdbModel();

  /// Converts a calendar value to a Julian date through Taiyin's native
  /// calendar implementation.
  ///
  /// The type parameter labels the scale in which [value] is interpreted; no
  /// time-scale conversion is performed.
  OperationResult<JulianDate<S>> julianDay<S extends TimeScale>(
    AstroDateTime value,
  ) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, value);
      final output = arena<taiyin_split_julian_date>();
      final flags = _checkStatus(
        _bindings.taiyin_julian_day_split(calendar, output),
      );
      return operationResult(readJulianDate<S>(output.ref), flags);
    });
  }

  /// Converts a Julian date to a calendar value through Taiyin's native
  /// calendar implementation.
  ///
  /// Taiyin's C ABI returns the seconds component as a `double`. It is rounded
  /// to the nearest nanosecond when constructing [AstroDateTime].
  OperationResult<AstroDateTime> reverseJulianDay<S extends TimeScale>(
    JulianDate<S> value,
  ) {
    _ensureOpen();
    return using((arena) {
      final input = writeJulianDate(arena, value);
      final output = arena<taiyin_calendar_datetime>();
      _bindings.taiyin_calendar_datetime_init(output);
      final flags = _checkStatus(
        _bindings.taiyin_reverse_julian_day_split(input, output),
      );
      final calendar = output.ref;
      final minute = AstroDateTime(
        calendar.year,
        calendar.month,
        calendar.day,
        calendar.hour,
        calendar.minute,
      );
      return operationResult(
        minute.addNanoseconds(
          (calendar.second * Duration.microsecondsPerSecond * 1000).round(),
        ),
        flags,
      );
    });
  }

  /// Allows conversions involving UTC and UT1 to fall back to an approximate
  /// UT1 plus Delta-T route when UTC/EOP data is missing or out of range.
  ///
  /// UTC conversion is strict by default. This policy also applies to reverse
  /// helpers such as [ut1ToUtc], but does not alter pure UT1 calculations or
  /// event searches. Context configuration must finish before concurrent
  /// calculations begin.
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
    _synchronizeTdbModel(model);
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

  OperationResult<JulianDate<TdbScale>> ttToTdb(
    JulianDate<TtScale> tt, {
    TdbModel? model,
  }) {
    _ensureOpen();
    return _convertModeled<TdbScale, TtScale>(
      tt,
      model ?? configuredTdbModel,
      _bindings.taiyin_tt_to_tdb_split,
    );
  }

  OperationResult<JulianDate<TtScale>> tdbToTt(
    JulianDate<TdbScale> tdb, {
    TdbModel? model,
  }) {
    _ensureOpen();
    return _convertModeled<TtScale, TdbScale>(
      tdb,
      model ?? configuredTdbModel,
      _bindings.taiyin_tdb_to_tt_split,
    );
  }

  /// Looks up TAI−UTC using Taiyin's built-in leap-second table.
  OperationResult<double> taiMinusUtc(AstroDateTime utc) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      final output = arena<Double>();
      final flags = _checkStatus(
        _bindings.taiyin_tai_minus_utc_seconds(calendar, output),
      );
      return operationResult(output.value, flags);
    });
  }

  OperationResult<JulianDate<TaiScale>> utcToTai(
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

  OperationResult<JulianDate<TtScale>> taiToTt(JulianDate<TaiScale> tai) {
    _ensureOpen();
    return _convert<TtScale, TaiScale>(tai, _bindings.taiyin_tai_to_tt_split);
  }

  OperationResult<JulianDate<TtScale>> utcToTt(
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

  OperationResult<JulianDate<Ut1Scale>> utcToUt1(
    JulianDate<UtcScale> utc, {
    double? dut1Seconds,
  }) {
    _ensureOpen();
    if (dut1Seconds == null) {
      final scales = _scalesFromUtcJulianDate(utc);
      return operationResult(scales.value.value.ut1, scales.flags);
    }
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

  OperationResult<JulianDate<Ut1Scale>> ttToUt1(
    JulianDate<TtScale> tt, {
    double? deltaTSeconds,
  }) {
    _ensureOpen();
    if (deltaTSeconds == null) {
      return _invertScaleToUt1<TtScale>(tt, (scales) => scales.tt);
    }
    _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _convertWithOffset<Ut1Scale, TtScale>(
      tt,
      deltaTSeconds,
      _bindings.taiyin_tt_to_ut1_split,
    );
  }

  OperationResult<JulianDate<TtScale>> ut1ToTt(
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
  OperationResult<PreciseTimeScales> preciseScalesFromUtc(
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
      final flags = _checkStatus(
        _bindings.taiyin_make_split_precise_time_scales_from_utc(
          calendar,
          taiMinusUtcSeconds,
          dut1Seconds,
          tdbModel.id,
          output,
        ),
      );
      return operationResult(_readPrecise(output.ref), flags);
    });
  }

  /// Builds every time scale according to this context's policy and runtime
  /// EOP/leap-second data, returning the selected route as a diagnostic.
  OperationResult<TimeScaleResult<PreciseTimeScales>> scalesFromUtc(
    AstroDateTime utc,
  ) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, utc);
      final output = arena<taiyin_split_precise_time_scales>();
      final diagnostic = arena<taiyin_time_scale_diagnostic>();
      _bindings
        ..taiyin_split_precise_time_scales_init(output)
        ..taiyin_time_scale_diagnostic_init(diagnostic);
      final flags = _checkStatus(
        _bindings.taiyin_make_split_time_scales_from_utc(
          _context,
          calendar,
          output,
          diagnostic,
        ),
      );
      return operationResult(
        TimeScaleResult(
          value: _readPrecise(output.ref),
          diagnostic: _readDiagnostic(diagnostic.ref),
        ),
        flags,
      );
    });
  }

  /// Converts a TAI instant to UTC using the runtime leap-second table.
  ///
  /// Missing coverage throws [LeapSecondDataError]. UTC is discontinuous at
  /// an inserted leap second, and [UtcJulianDate] cannot preserve its
  /// `second: 60` label; such an instant throws
  /// [UtcLeapSecondRepresentationError] instead of silently returning an
  /// adjacent coordinate.
  OperationResult<JulianDate<UtcScale>> taiToUtc(JulianDate<TaiScale> tai) {
    _ensureOpen();
    var candidate = JulianDate<UtcScale>.fromParts(
      tai.dayNumber,
      tai.dayFraction,
    );
    var flags = ResultFlags.none;
    var converged = false;
    for (var iteration = 0; iteration < _inverseScaleIterations; iteration++) {
      final offset = taiMinusUtc(AstroDateTime.fromJulianDate(candidate));
      flags = flags | offset.flags;
      final evaluated = JulianDate<TaiScale>.fromParts(
        candidate.dayNumber,
        candidate.dayFraction,
      ).addSeconds(offset.value);
      final correction = tai.coordinateSecondsDifference(evaluated);
      candidate = candidate.addSeconds(correction);
      if (correction.abs() <= _inverseScaleToleranceSeconds) {
        converged = true;
        break;
      }
    }
    if (!converged) {
      throw const UtcLeapSecondRepresentationError();
    }
    return operationResult(candidate, flags);
  }

  /// Converts a TT instant to UTC using the runtime leap-second table.
  OperationResult<JulianDate<UtcScale>> ttToUtc(JulianDate<TtScale> tt) {
    _ensureOpen();
    final tai = JulianDate<TaiScale>.fromParts(
      tt.dayNumber,
      tt.dayFraction,
    ).addSeconds(-32.184);
    return taiToUtc(tai);
  }

  /// Converts a UT1 instant to UTC according to this context's time policy.
  ///
  /// Strict contexts require EOP coverage and throw
  /// `EarthOrientationDataError` when it is unavailable. A context configured
  /// with [setAllowUtcOutOfRangeEstimate] may return an estimated result; the
  /// returned flags then contain [ResultFlag.timeScaleFallback].
  OperationResult<JulianDate<UtcScale>> ut1ToUtc(JulianDate<Ut1Scale> ut1) {
    _ensureOpen();
    return _invertUtcScale<Ut1Scale>(ut1, (scales) => scales.ut1);
  }

  /// Converts a TDB instant to UTC using [model] and the leap-second table.
  OperationResult<JulianDate<UtcScale>> tdbToUtc(
    JulianDate<TdbScale> tdb, {
    TdbModel? model,
  }) {
    _ensureOpen();
    final tt = tdbToTt(tdb, model: model);
    final utc = ttToUtc(tt.value);
    return operationResult(utc.value, tt.flags | utc.flags);
  }

  /// Converts a TAI instant to UT1 through TT and the context's EOP/Delta-T
  /// policy. An allowed historical estimate does not require leap-second
  /// coverage.
  OperationResult<JulianDate<Ut1Scale>> taiToUt1(JulianDate<TaiScale> tai) {
    _ensureOpen();
    final tt = taiToTt(tai);
    final ut1 = ttToUt1(tt.value);
    return operationResult(ut1.value, tt.flags | ut1.flags);
  }

  /// Converts a TDB instant to UT1 through TT and the context's EOP/Delta-T
  /// policy. An allowed historical estimate does not require leap-second
  /// coverage.
  OperationResult<JulianDate<Ut1Scale>> tdbToUt1(
    JulianDate<TdbScale> tdb, {
    TdbModel? model,
  }) {
    _ensureOpen();
    final tt = tdbToTt(tdb, model: model);
    final ut1 = ttToUt1(tt.value);
    return operationResult(ut1.value, tt.flags | ut1.flags);
  }

  /// Formats a UT1 Julian date as an [AstroDateTime] in the UT1 scale.
  ///
  /// This performs no time-scale conversion and never requires EOP data.
  OperationResult<AstroDateTime> calendarFromUt1(JulianDate<Ut1Scale> ut1) =>
      reverseJulianDay(ut1);

  /// Converts UT1 to UTC and formats the result as a UTC [AstroDateTime].
  ///
  /// The same strict/fallback policy as [ut1ToUtc] applies.
  OperationResult<AstroDateTime> utcCalendarFromUt1(JulianDate<Ut1Scale> ut1) {
    final utc = ut1ToUtc(ut1);
    final calendar = reverseJulianDay(utc.value);
    return operationResult(calendar.value, utc.flags | calendar.flags);
  }

  /// Builds UT1, TT, and TDB from a calendar value interpreted as UT1.
  ///
  /// When [deltaTSeconds] is omitted, Taiyin's configured estimate is used.
  OperationResult<EstimatedTimeScales> estimatedScalesFromUt1(
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
      final flags = _checkStatus(status);
      return operationResult(_readEstimated(output.ref), flags);
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

  OperationResult<JulianDate<Output>> _convert<
    Output extends TimeScale,
    Input extends TimeScale
  >(JulianDate<Input> value, _UnarySplitConversion conversion) {
    return using((arena) {
      final input = writeJulianDate(arena, value);
      final output = arena<taiyin_split_julian_date>();
      final flags = _checkStatus(conversion(input, output));
      return operationResult(readJulianDate<Output>(output.ref), flags);
    });
  }

  OperationResult<JulianDate<Output>>
  _convertWithOffset<Output extends TimeScale, Input extends TimeScale>(
    JulianDate<Input> value,
    double offsetSeconds,
    _OffsetSplitConversion conversion,
  ) {
    return using((arena) {
      final input = writeJulianDate(arena, value);
      final output = arena<taiyin_split_julian_date>();
      final flags = _checkStatus(conversion(input, offsetSeconds, output));
      return operationResult(readJulianDate<Output>(output.ref), flags);
    });
  }

  OperationResult<JulianDate<Output>>
  _convertModeled<Output extends TimeScale, Input extends TimeScale>(
    JulianDate<Input> value,
    TdbModel model,
    _ModeledSplitConversion conversion,
  ) {
    return using((arena) {
      final input = writeJulianDate(arena, value);
      final output = arena<taiyin_split_julian_date>();
      final flags = _checkStatus(conversion(input, model.id, output));
      return operationResult(readJulianDate<Output>(output.ref), flags);
    });
  }

  OperationResult<TimeScaleResult<PreciseTimeScales>> _scalesFromUtcJulianDate(
    JulianDate<UtcScale> utc,
  ) {
    return scalesFromUtc(AstroDateTime.fromJulianDate(utc));
  }

  OperationResult<JulianDate<UtcScale>> _invertUtcScale<S extends TimeScale>(
    JulianDate<S> target,
    JulianDate<S> Function(PreciseTimeScales scales) select,
  ) {
    final initial = _initialUtcCandidate(target, const [0.0, -2.0, 2.0]);
    var candidate = initial.candidate;
    var flags = ResultFlags.none;
    var converged = false;
    for (var iteration = 0; iteration < _inverseScaleIterations; iteration++) {
      final scales = iteration == 0
          ? initial.scales
          : _scalesFromUtcJulianDate(candidate);
      flags = flags | scales.flags;
      final evaluated = select(scales.value.value);
      final correction = target.coordinateSecondsDifference(evaluated);
      candidate = candidate.addSeconds(correction);
      if (correction.abs() <= _inverseScaleToleranceSeconds) {
        converged = true;
        break;
      }
    }
    if (!converged) {
      throw const UtcLeapSecondRepresentationError();
    }
    return operationResult(candidate, flags);
  }

  OperationResult<JulianDate<Ut1Scale>> _invertScaleToUt1<S extends TimeScale>(
    JulianDate<S> target,
    JulianDate<S> Function(PreciseTimeScales scales) select,
  ) {
    final initial = _initialUtcCandidate(target, const [0.0, -69.184, -42.184]);
    var candidate = initial.candidate;
    var flags = ResultFlags.none;
    for (var iteration = 0; iteration < _inverseScaleIterations; iteration++) {
      final scales = iteration == 0
          ? initial.scales
          : _scalesFromUtcJulianDate(candidate);
      flags = flags | scales.flags;
      final evaluated = select(scales.value.value);
      final correction = target.coordinateSecondsDifference(evaluated);
      if (correction.abs() <= _inverseScaleToleranceSeconds) {
        return operationResult(
          scales.value.value.ut1.addSeconds(correction),
          flags,
        );
      }
      candidate = candidate.addSeconds(correction);
    }
    final leapSecond = _insertedLeapSecondToUt1(
      target,
      select,
      candidate,
      flags,
    );
    if (leapSecond != null) return leapSecond;
    throw const TimeScaleConvergenceError(
      'automatic conversion to UT1 did not converge',
    );
  }

  ({
    JulianDate<UtcScale> candidate,
    OperationResult<TimeScaleResult<PreciseTimeScales>> scales,
  })
  _initialUtcCandidate<S extends TimeScale>(
    JulianDate<S> target,
    List<double> offsets,
  ) {
    Object? firstError;
    StackTrace? firstStackTrace;
    for (final offset in offsets) {
      final candidate = JulianDate<UtcScale>.fromParts(
        target.dayNumber,
        target.dayFraction,
      ).addSeconds(offset);
      try {
        return (
          candidate: candidate,
          scales: _scalesFromUtcJulianDate(candidate),
        );
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    Error.throwWithStackTrace(firstError!, firstStackTrace!);
  }

  OperationResult<JulianDate<Ut1Scale>>?
  _insertedLeapSecondToUt1<S extends TimeScale>(
    JulianDate<S> target,
    JulianDate<S> Function(PreciseTimeScales scales) select,
    JulianDate<UtcScale> candidate,
    ResultFlags accumulatedFlags,
  ) {
    final visitedDates = <String>{};
    for (final seconds in const [-1.0, 0.0, 1.0]) {
      final nearby = AstroDateTime.fromJulianDate(
        candidate.addSeconds(seconds),
      );
      final dateKey = '${nearby.year}-${nearby.month}-${nearby.day}';
      if (!visitedDates.add(dateKey)) continue;

      final leapClock = AstroDateTime(
        nearby.year,
        nearby.month,
        nearby.day,
        23,
        59,
        60,
      );
      final offsetBefore = taiMinusUtc(leapClock);
      final normalizedNextDay = AstroDateTime.fromJulianDate(
        leapClock.toUtcJulianDate(),
      );
      final offsetAfter = taiMinusUtc(normalizedNextDay);
      if ((offsetAfter.value - offsetBefore.value - 1.0).abs() >
          _inverseScaleToleranceSeconds) {
        continue;
      }

      final leapScales = scalesFromUtc(leapClock);
      final correction = target.coordinateSecondsDifference(
        select(leapScales.value.value),
      );
      if (correction < -_inverseScaleToleranceSeconds ||
          correction >= 1.0 - _inverseScaleToleranceSeconds) {
        continue;
      }
      return operationResult(
        leapScales.value.value.ut1.addSeconds(correction),
        accumulatedFlags |
            offsetBefore.flags |
            offsetAfter.flags |
            leapScales.flags,
      );
    }
    return null;
  }
}

const int _inverseScaleIterations = 6;
const double _inverseScaleToleranceSeconds = 0.5e-9;
