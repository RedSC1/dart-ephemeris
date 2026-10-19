import '../backend/backend_call.dart';
import '../backend/calendar_backend.dart';
import '../chinese_calendar/chinese_calendar_models.dart';
import '../ganzhi/ganzhi_models.dart';
import '../interop/value_validation.dart';
import '../result_flags.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'ephemeris_web.dart' show TaiyinExtensionHost;
import 'diagnostic_web.dart';
import 'wasm_module.dart';

final class WebChineseCalendarBackend implements ChineseCalendarBackend {
  WebChineseCalendarBackend(
    this._backend,
    this._handle,
    this._ownerEnsureOpen,
    this._complete,
  );
  final WasmBackend _backend;
  final int _handle;
  final void Function() _ownerEnsureOpen;
  final BackendCallCompletion _complete;
  bool _closed = false;
  void _ensureOpen() {
    if (_closed) {
      throw StateError('This ChineseCalendarContext has been closed.');
    }
    _ownerEnsureOpen();
  }

  TaiyinExtensionHost get extensionHost => TaiyinExtensionHost.internal(
    _ensureOpen,
    backend: _backend,
    calendarHandle: _handle,
    complete: _complete,
  );
  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _backend.destroyCalendar(_handle);
  }

  BackendCall<T> _call<T>(
    int operation,
    List<num> input,
    T Function(List<double>) read,
  ) {
    _ensureOpen();
    final reply = _backend.calendar(_handle, operation, input);
    return BackendCall(
      status: reply.status,
      flags: ResultFlags(reply.values[0].toInt()),
      value: reply.status == 0 ? read(reply.values) : null,
      diagnostic: readWebDiagnostic(reply.values.sublist(480)),
    );
  }

  List<num> _jd(JulianDate<TimeScale> jd) {
    if (jd.dayNumber.abs() > 9007199254740991) {
      throw RangeError('Julian day exceeds exact JS integer range.');
    }
    return [jd.dayNumber, jd.dayFraction];
  }

  Ut1JulianDate _date(List<double> v, int at) =>
      Ut1JulianDate.fromParts(v[at].toInt(), v[at + 1]);
  ChineseSolarTermEvent _term(List<double> v, int at) => ChineseSolarTermEvent(
    indexFromWinterSolstice: v[at].toInt(),
    targetLongitudeRadians: v[at + 1],
    jdUt: _date(v, at + 2),
    civilDayNumber: v[at + 4].toInt(),
  );
  LunarDate _lunar(List<double> v) => LunarDate(
    year: v[1].toInt(),
    month: v[2].toInt(),
    day: v[3].toInt(),
    isLeap: v[4] != 0,
    monthDays: v[5].toInt(),
    monthName: ChineseCalendarMonthName.fromId(v[6].toInt()),
  );
  @override
  BackendCall<ChineseCalendarYear> calcYearUt(JulianDate<Ut1Scale> jd) => _call(
    0,
    _jd(jd),
    (v) => ChineseCalendarYear(
      solarTerms: [for (var i = 0; i < v[1]; i++) _term(v, 16 + i * 5)],
      newMoons: [
        for (var i = 0; i < v[2]; i++)
          ChineseNewMoonEvent(
            jdUt: _date(v, 160 + i * 3),
            civilDayNumber: v[162 + i * 3].toInt(),
          ),
      ],
      months: [for (var i = 0; i < v[3]; i++) _month(v, 224 + i * 10)],
      solarTermCount: v[1].toInt(),
      newMoonCount: v[2].toInt(),
      monthCount: v[3].toInt(),
      leapMonthIndex: v[4].toInt(),
      firstWinterSolsticeDayNumber: v[5].toInt(),
      secondWinterSolsticeDayNumber: v[6].toInt(),
    ),
  );
  ChineseCalendarMonth _month(List<double> v, int at) => ChineseCalendarMonth(
    lunarYear: v[at].toInt(),
    month: v[at + 1].toInt(),
    isLeap: v[at + 2] != 0,
    dayCount: v[at + 3].toInt(),
    monthName: ChineseCalendarMonthName.fromId(v[at + 4].toInt()),
    monthBuildingBranch: v[at + 5].toInt(),
    firstCivilDayNumber: v[at + 6].toInt(),
    astronomicalNewMoonJdUt: _date(v, at + 7),
  );
  @override
  BackendCall<ChineseSolarTermEvent> getSpecificJieQiUt({
    required int civilYear,
    required int termIndexFromVernalEquinox,
  }) {
    validateNativeInt32(civilYear, 'civilYear');
    validateNativeUint8(
      termIndexFromVernalEquinox,
      'termIndexFromVernalEquinox',
    );
    return _call(1, [
      civilYear,
      termIndexFromVernalEquinox,
    ], (v) => _term(v, 1));
  }

  BackendCall<ChineseSolarTermEvent> _search(int op, JulianDate<Ut1Scale> jd) =>
      _call(op, _jd(jd), (v) => _term(v, 1));
  @override
  BackendCall<ChineseSolarTermEvent> getPrevJieQiUt(JulianDate<Ut1Scale> jd) =>
      _search(2, jd);
  @override
  BackendCall<ChineseSolarTermEvent> getNextJieQiUt(JulianDate<Ut1Scale> jd) =>
      _search(3, jd);
  @override
  BackendCall<ChineseSolarTermEvent> getPrevJieUt(JulianDate<Ut1Scale> jd) =>
      _search(4, jd);
  @override
  BackendCall<ChineseSolarTermEvent> getNextJieUt(JulianDate<Ut1Scale> jd) =>
      _search(5, jd);
  @override
  BackendCall<ChineseSolarTermEvent> getPrevQiUt(JulianDate<Ut1Scale> jd) =>
      _search(6, jd);
  @override
  BackendCall<ChineseSolarTermEvent> getNextQiUt(JulianDate<Ut1Scale> jd) =>
      _search(7, jd);
  void _validateDate(int year, int month, int day) {
    validateNativeInt32(year, 'year');
    validateNativeUint8(month, 'month');
    validateNativeUint8(day, 'day');
  }

  @override
  BackendCall<LunarDate> fromSolar(SolarDate date) {
    _validateDate(date.year, date.month, date.day);
    return _call(8, [date.year, date.month, date.day], _lunar);
  }

  @override
  BackendCall<LunarDate> fromInstantUt1(JulianDate<Ut1Scale> jd) =>
      _call(9, _jd(jd), _lunar);
  @override
  BackendCall<SolarDate> fromLunar(LunarDate date) {
    _validateDate(date.year, date.month, date.day);
    validateNativeUint8(date.monthDays, 'monthDays');
    return _call(
      10,
      [
        date.year,
        date.month,
        date.day,
        date.isLeap ? 1 : 0,
        date.monthDays,
        date.monthName.id,
      ],
      (v) =>
          SolarDate(year: v[1].toInt(), month: v[2].toInt(), day: v[3].toInt()),
    );
  }

  @override
  BackendCall<int> getMonthDays({
    required int lunarYear,
    required int month,
    required bool isLeap,
  }) {
    validateNativeInt32(lunarYear, 'lunarYear');
    validateNativeUint8(month, 'month');
    return _call(11, [lunarYear, month, isLeap ? 1 : 0], (v) => v[1].toInt());
  }

  @override
  BackendCall<GanzhiFourPillars> fourPillars({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) {
    validateNativeInt32(virtualTime.year, 'year');
    return _call(
      12,
      [
        ..._jd(instantUtc),
        ratHourMode.id,
        virtualTime.year,
        virtualTime.month,
        virtualTime.day,
        virtualTime.hour,
        virtualTime.minute,
        virtualTime.fractionalSecond,
      ],
      (v) => GanzhiFourPillars(
        year: Ganzhi.fromNative(v[1].toInt()),
        month: Ganzhi.fromNative(v[2].toInt()),
        day: Ganzhi.fromNative(v[3].toInt()),
        hour: Ganzhi.fromNative(v[4].toInt()),
      ),
    );
  }
}
