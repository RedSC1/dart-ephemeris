import '../backend/backend_call.dart';
import '../backend/calendar_backend.dart';
import '../time/time_api.dart';
import '../result_flags.dart';
import '../ganzhi/ganzhi_models.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'chinese_calendar_models.dart';

/// An owned Chinese-calendar configuration borrowing its astronomy context.
/// Native and Web use the same public facade and the same C++ calendar rules.
abstract base class CalendarContextBase {
  CalendarContextBase.internal(
    this._backend,
    this._ownerTime,
    this.config,
    this._ownerEnsureOpen,
    this._complete,
  );
  final ChineseCalendarBackend _backend;
  final Time _ownerTime;
  final void Function() _ownerEnsureOpen;
  final BackendCallCompletion _complete;
  final ChineseCalendarConfig config;
  bool _closed = false;
  bool get isClosed => _closed;

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This ChineseCalendarContext has been closed.');
    }
    _ownerEnsureOpen();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _backend.close();
  }

  OperationResult<T> _run<T>(BackendCall<T> Function() calculate) {
    _ensureOpen();
    final call = calculate();
    _complete(call);
    return operationResult(call.value, call.flags);
  }

  OperationResult<ChineseCalendarYear> calcYearUt(JulianDate<Ut1Scale> jdUt) =>
      _run(() => _backend.calcYearUt(jdUt));
  OperationResult<ChineseSolarTermEvent> getSpecificJieQiUt({
    required int civilYear,
    required int termIndexFromVernalEquinox,
  }) => _run(
    () => _backend.getSpecificJieQiUt(
      civilYear: civilYear,
      termIndexFromVernalEquinox: termIndexFromVernalEquinox,
    ),
  );
  OperationResult<ChineseSolarTermEvent> getPrevJieQiUt(
    JulianDate<Ut1Scale> jdUt,
  ) => _run(() => _backend.getPrevJieQiUt(jdUt));
  OperationResult<ChineseSolarTermEvent> getNextJieQiUt(
    JulianDate<Ut1Scale> jdUt,
  ) => _run(() => _backend.getNextJieQiUt(jdUt));
  OperationResult<ChineseSolarTermEvent> getPrevJieUt(
    JulianDate<Ut1Scale> jdUt,
  ) => _run(() => _backend.getPrevJieUt(jdUt));
  OperationResult<ChineseSolarTermEvent> getNextJieUt(
    JulianDate<Ut1Scale> jdUt,
  ) => _run(() => _backend.getNextJieUt(jdUt));
  OperationResult<ChineseSolarTermEvent> getPrevQiUt(
    JulianDate<Ut1Scale> jdUt,
  ) => _run(() => _backend.getPrevQiUt(jdUt));
  OperationResult<ChineseSolarTermEvent> getNextQiUt(
    JulianDate<Ut1Scale> jdUt,
  ) => _run(() => _backend.getNextQiUt(jdUt));
  OperationResult<LunarDate> fromSolar(SolarDate date) =>
      _run(() => _backend.fromSolar(date));
  OperationResult<SolarDate> fromLunar(LunarDate date) =>
      _run(() => _backend.fromLunar(date));
  OperationResult<LunarDate> fromInstantUt1(JulianDate<Ut1Scale> instant) =>
      _run(() => _backend.fromInstantUt1(instant));
  OperationResult<int> getMonthDays({
    required int lunarYear,
    required int month,
    required bool isLeap,
  }) => _run(
    () => _backend.getMonthDays(
      lunarYear: lunarYear,
      month: month,
      isLeap: isLeap,
    ),
  );
  OperationResult<GanzhiFourPillars> fourPillars({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) => _run(
    () => _backend.fourPillars(
      instantUtc: instantUtc,
      virtualTime: virtualTime,
      ratHourMode: ratHourMode,
    ),
  );
  double get _clockOffsetSeconds => config.utcOffsetMinutes * 60.0;

  /// Converts a local civil clock to UTC using its configured fixed offset.
  ///
  /// The calendar's mean-solar meridian, when selected, controls only new-moon
  /// and solar-term day assignment. It does not replace the caller's legal
  /// clock. No daylight-saving or IANA timezone rules are applied.
  OperationResult<JulianDate<UtcScale>> instantFromLocal(
    AstroDateTime localTime,
  ) {
    _ensureOpen();
    if (localTime.second == 60) {
      throw const UtcLeapSecondRepresentationError();
    }
    return operationResult(
      localTime.toUtcJulianDate().addSeconds(-_clockOffsetSeconds),
      ResultFlags.none,
    );
  }

  /// Converts a UTC instant to the configured fixed-offset civil clock.
  OperationResult<AstroDateTime> localTimeFromInstant(
    JulianDate<UtcScale> instantUtc,
  ) {
    _ensureOpen();
    return _ownerTime.reverseJulianDay(
      instantUtc.addSeconds(_clockOffsetSeconds),
    );
  }

  /// Converts the Gregorian date portion of a local civil clock to a Chinese
  /// lunar date.
  OperationResult<LunarDate> fromLocal(AstroDateTime localTime) {
    return fromSolar(
      SolarDate(
        year: localTime.year,
        month: localTime.month,
        day: localTime.day,
      ),
    );
  }

  /// Computes four pillars from one local civil clock.
  ///
  /// The corresponding UTC instant is derived from this calendar context, so
  /// callers do not need to repeat or manually subtract its UTC offset.
  OperationResult<GanzhiFourPillars> fourPillarsLocal(
    AstroDateTime localTime, {
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) {
    final instant = instantFromLocal(localTime);
    final pillars = fourPillars(
      instantUtc: instant.value,
      virtualTime: localTime,
      ratHourMode: ratHourMode,
    );
    return operationResult(pillars.value, instant.flags | pillars.flags);
  }

  /// Computes four pillars from one UTC instant.
  ///
  /// The civil clock used for the nominal year, day, and hour pillars is
  /// derived from this calendar context's day-boundary configuration.
  OperationResult<GanzhiFourPillars> fourPillarsInstant(
    JulianDate<UtcScale> instantUtc, {
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) {
    final localTimeResult = localTimeFromInstant(instantUtc);
    final pillarsResult = fourPillars(
      instantUtc: instantUtc,
      virtualTime: localTimeResult.value,
      ratHourMode: ratHourMode,
    );
    return operationResult(
      pillarsResult.value,
      localTimeResult.flags | pillarsResult.flags,
    );
  }
}
