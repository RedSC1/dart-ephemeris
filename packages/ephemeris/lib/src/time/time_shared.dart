import '../backend/backend_call.dart';
import '../backend/time_backend.dart';
import '../result_flags.dart';
import 'astro_date_time.dart';
import 'julian_date.dart';
import 'time_models.dart';
import 'time_scale.dart';
import 'time_errors.dart';
export 'time_errors.dart';

/// Time-scale conversion and Delta-T operations backed by Ephemeris.
final class Time {
  /// Internal constructor used by an owning [EphemerisContext].
  Time.internal(
    this._backend,
    this._ensureOpen,
    this._complete,
    this._isLeapSecondUnavailable,
    this._configuredTdbModel,
    this._synchronizeTdbModel,
  );
  final TimeBackend _backend;
  final void Function() _ensureOpen;
  final BackendCallCompletion _complete;
  final bool Function(Object error) _isLeapSecondUnavailable;
  final TdbModel Function() _configuredTdbModel;
  final void Function(TdbModel model) _synchronizeTdbModel;
  OperationResult<T> _value<T>(BackendCall<T> call) {
    _complete(call);
    return operationResult(call.value, call.flags);
  }

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
    return _value(_backend.julianDay<S>(value));
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
    return _value(_backend.reverseJulianDay(value));
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
    _complete(_backend.configure(1, [allow ? 1 : 0]));
  }

  /// Selects the TT/TDB conversion model on this context.
  void setTdbModel(TdbModel model) {
    _ensureOpen();
    _complete(_backend.configure(12, [model.id]));
    _synchronizeTdbModel(model);
  }

  /// Selects the estimated Delta-T model and ephemeris family.
  void setDeltaTModel(
    DeltaTModel model, {
    EphemerisFamily family = EphemerisFamily.unknown,
  }) {
    _ensureOpen();
    _complete(_backend.configure(11, [model.id, family.id]));
  }

  double decimalYear<S extends TimeScale>(JulianDate<S> value) {
    _ensureOpen();
    return _finite(
      _backend.scalar(TimeScalar.decimalYear, value.toDouble()),
      'decimal year',
    );
  }

  double julianCenturiesSinceJ2000<S extends TimeScale>(JulianDate<S> value) {
    _ensureOpen();
    return _finite(
      _backend.scalar(TimeScalar.centuries, value.toDouble()),
      'Julian centuries',
    );
  }

  double julianMillenniaSinceJ2000<S extends TimeScale>(JulianDate<S> value) {
    _ensureOpen();
    return _finite(
      _backend.scalar(TimeScalar.millennia, value.toDouble()),
      'Julian millennia',
    );
  }

  double estimatedDeltaTForDecimalYear(double decimalYear) {
    _ensureOpen();
    if (!decimalYear.isFinite) {
      throw ArgumentError.value(decimalYear, 'decimalYear', 'must be finite');
    }
    return _finite(
      _backend.scalar(TimeScalar.deltaTYear, decimalYear),
      'estimated Delta-T',
    );
  }

  double estimatedDeltaTFromUt1(JulianDate<Ut1Scale> ut1) {
    _ensureOpen();
    return _finite(
      _backend.scalar(TimeScalar.deltaTUt1, ut1.toDouble()),
      'estimated Delta-T',
    );
  }

  double estimatedDeltaTFromTt(JulianDate<TtScale> tt) {
    _ensureOpen();
    return _finite(
      _backend.scalar(TimeScalar.deltaTTt, tt.toDouble()),
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
      TimeConversion.ttToTdb,
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
      TimeConversion.tdbToTt,
    );
  }

  /// Looks up TAI−UTC using Taiyin's built-in leap-second table.
  OperationResult<double> taiMinusUtc(AstroDateTime utc) {
    _ensureOpen();
    return _value(_backend.taiMinusUtc(utc));
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
      TimeConversion.utcToTai,
    );
  }

  OperationResult<JulianDate<TtScale>> taiToTt(JulianDate<TaiScale> tai) {
    _ensureOpen();
    return _convert<TtScale, TaiScale>(tai, TimeConversion.taiToTt);
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
      TimeConversion.utcToTt,
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
      TimeConversion.utcToUt1,
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
      _backend.scalar(
        TimeScalar.deltaTOffsets,
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
      TimeConversion.ttToUt1,
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
      TimeConversion.ut1ToTt,
    );
  }

  /// Builds every time scale from UTC using explicit offsets.
  OperationResult<PreciseTimeScales> preciseScalesFromUtc(
    AstroDateTime utc, {
    required double taiMinusUtcSeconds,
    required double dut1Seconds,
    TdbModel? tdbModel,
  }) {
    _ensureOpen();
    _requireFinite(taiMinusUtcSeconds, 'taiMinusUtcSeconds');
    _requireFinite(dut1Seconds, 'dut1Seconds');
    return _value(
      _backend.preciseScales(
        utc,
        taiMinusUtcSeconds,
        dut1Seconds,
        tdbModel ?? configuredTdbModel,
      ),
    );
  }

  /// Builds every time scale according to this context's policy and runtime
  /// EOP/leap-second data, returning the selected route as a diagnostic.
  OperationResult<TimeScaleResult<PreciseTimeScales>> scalesFromUtc(
    AstroDateTime utc,
  ) {
    _ensureOpen();
    return _value(_backend.scalesFromUtc(utc));
  }

  /// Converts a TAI instant to UTC according to this context's time policy.
  ///
  /// A strict context throws [LeapSecondDataError] when coverage is missing.
  /// A context allowing out-of-range estimates converts through UT1 and the
  /// configured Delta-T model and reports [ResultFlag.timeScaleFallback]. UTC
  /// is discontinuous at an inserted leap second, and [UtcJulianDate] cannot
  /// preserve its `second: 60` label; such an instant throws
  /// [UtcLeapSecondRepresentationError] instead of silently returning an
  /// adjacent coordinate.
  OperationResult<JulianDate<UtcScale>> taiToUtc(JulianDate<TaiScale> tai) {
    _ensureOpen();
    try {
      return _invertAtomicToUtc(tai);
    } on UtcLeapSecondRepresentationError {
      rethrow;
    } on Exception catch (directError, directStackTrace) {
      if (!_isLeapSecondUnavailable(directError)) rethrow;
      try {
        final tt = taiToTt(tai);
        final ut1 = ttToUt1(tt.value);
        final utc = ut1ToUtc(ut1.value);
        return operationResult(utc.value, tt.flags | ut1.flags | utc.flags);
      } on Exception {
        Error.throwWithStackTrace(directError, directStackTrace);
      }
    }
  }

  /// Converts a TT instant to UTC according to this context's time policy.
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
    TdbModel? tdbModel,
  }) {
    _ensureOpen();
    if (deltaTSeconds != null) _requireFinite(deltaTSeconds, 'deltaTSeconds');
    return _value(
      _backend.estimatedScales(
        ut1,
        deltaTSeconds,
        tdbModel ?? configuredTdbModel,
      ),
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

  OperationResult<JulianDate<Output>>
  _convert<Output extends TimeScale, Input extends TimeScale>(
    JulianDate<Input> value,
    TimeConversion conversion,
  ) => _value(_backend.convert<Output>(conversion, value));
  OperationResult<JulianDate<Output>> _convertWithOffset<
    Output extends TimeScale,
    Input extends TimeScale
  >(JulianDate<Input> value, double offsetSeconds, TimeConversion conversion) =>
      _value(
        _backend.convert<Output>(conversion, value, offset: offsetSeconds),
      );
  OperationResult<JulianDate<Output>>
  _convertModeled<Output extends TimeScale, Input extends TimeScale>(
    JulianDate<Input> value,
    TdbModel model,
    TimeConversion conversion,
  ) => _value(_backend.convert<Output>(conversion, value, model: model));

  OperationResult<TimeScaleResult<PreciseTimeScales>> _scalesFromUtcJulianDate(
    JulianDate<UtcScale> utc,
  ) {
    return scalesFromUtc(AstroDateTime.fromJulianDate(utc));
  }

  OperationResult<JulianDate<UtcScale>> _invertAtomicToUtc(
    JulianDate<TaiScale> tai,
  ) {
    var candidate = JulianDate<UtcScale>.fromParts(
      tai.dayNumber,
      tai.dayFraction,
    );
    var flags = ResultFlags.none;
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
        return operationResult(candidate, flags);
      }
    }
    throw const UtcLeapSecondRepresentationError();
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
      throw const TimeScaleConvergenceError(
        'automatic conversion to UTC did not converge',
      );
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
      OperationResult<TimeScaleResult<PreciseTimeScales>> leapScales;
      try {
        leapScales = scalesFromUtc(leapClock);
      } on Exception {
        // This is an optional representation probe. If its end-of-day UTC
        // sample lies outside the configured data coverage, the already
        // converged inverse remains the authoritative result.
        continue;
      }
      if (leapScales.value.diagnostic.route != TimeScaleRoute.preciseUtcEop) {
        continue;
      }
      final offsetBefore = taiMinusUtc(leapClock);
      final normalizedNextDay = AstroDateTime.fromJulianDate(
        leapClock.toUtcJulianDate(),
      );
      final offsetAfter = taiMinusUtc(normalizedNextDay);
      if ((offsetAfter.value - offsetBefore.value - 1.0).abs() >
          _inverseScaleToleranceSeconds) {
        continue;
      }

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
