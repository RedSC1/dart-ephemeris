import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris/backend.dart';
import 'bazi_models.dart';
import 'bazi_backend.dart';

/// Shared public behavior; platform-specific subclasses retain calendar types.
abstract base class BaziFacade {
  BaziFacade.internal(
    this._backend,
    this._calendar,
    this._time,
    this._solarTime,
  );
  final BaziBackend _backend;
  final CalendarContextBase _calendar;
  final Time _time;
  final SolarTimeApi _solarTime;
  bool get isClosed => _backend.isClosed;
  CalendarContextBase get chineseCalendar;
  void close() => _backend.close();
  void _ensureOpen() {
    if (isClosed) throw StateError('This BaziContext has been closed.');
  }

  /// Returns the 空亡 (kong-wang) branches for a Ganzhi value.
  ({EarthlyBranch a, EarthlyBranch b}) getKongWang(Ganzhi value) {
    _ensureOpen();
    return _backend.getKongWang(value);
  }

  /// Returns the 十神 (ten god) of a stem relative to the day stem.
  BaziTenGod getTenGod({required int dayStemId, required int targetStemId}) {
    _ensureOpen();
    return _backend.getTenGod(dayStemId: dayStemId, targetStemId: targetStemId);
  }

  /// Returns the 藏干 (hidden stems) of an earthly branch.
  ({List<int> stems, int count}) getHiddenStems(int branchId) {
    _ensureOpen();
    return _backend.getHiddenStems(branchId);
  }

  /// Calculates the relation between two heavenly stems.
  BaziStemRelationResult calcStemRelation(int stemA, int stemB) {
    _ensureOpen();
    return _backend.calcStemRelation(stemA, stemB);
  }

  /// Calculates the relation between two earthly branches.
  BaziBranchRelationResult calcBranchRelation(int branchA, int branchB) {
    _ensureOpen();
    return _backend.calcBranchRelation(branchA, branchB);
  }

  /// Calculates the triple relation among three earthly branches.
  BaziBranchTripleRelationResult calcBranchTripleRelation(
    int branchA,
    int branchB,
    int branchC,
  ) {
    _ensureOpen();
    return _backend.calcBranchTripleRelation(branchA, branchB, branchC);
  }

  /// Returns the 长生十二宫 (life stage) of a stem in an earthly branch.
  int getLifeStage({
    required int stemId,
    required int branchId,
    BaziEarthPalaceMode mode = BaziEarthPalaceMode.fireEarth,
  }) {
    _ensureOpen();
    return _backend.getLifeStage(
      stemId: stemId,
      branchId: branchId,
      mode: mode,
    );
  }

  /// Calculates the 流年 (liu-nian / flow-year) Ganzhi for an effective year.
  Ganzhi calcLiunian(int effectiveYear) {
    _ensureOpen();
    return _backend.calcLiunian(effectiveYear);
  }

  /// Calculates the 流月 (liu-yue / flow-month) Ganzhi.
  ///
  /// [monthBranch] follows the C ABI: 2 = 寅, …, 0 = 子, 1 = 丑.
  Ganzhi calcLiuyue(Ganzhi yearPillar, int monthBranch) {
    _ensureOpen();
    return _backend.calcLiuyue(yearPillar, monthBranch);
  }

  /// Calculates the 流日 (liu-ri / flow-day) Ganzhi for a civil date.
  Ganzhi calcLiuri(AstroDateTime civilDate) {
    _ensureOpen();
    return _backend.calcLiuri(civilDate);
  }

  /// Calculates the 流时 (liu-shi / flow-hour) Ganzhi.
  ///
  /// [hourIndex] follows the C ABI branch sequence: 0 = 子, …, 11 = 亥.
  Ganzhi calcLiushi(Ganzhi dayPillar, int hourIndex) {
    _ensureOpen();
    return _backend.calcLiushi(dayPillar, hourIndex);
  }

  /// Calculates the 小运 (xiao-yun) Ganzhi for an age within a chart.
  Ganzhi calcXiaoyun(BaziChart chart, int direction, int age) {
    _ensureOpen();
    return _backend.calcXiaoyun(chart, direction, age);
  }

  /// Fills a contiguous range of 小运 (xiao-yun) entries starting at
  /// [startAge] (one-based virtual ages).
  List<BaziXiaoyun> fillXiaoyun({
    required BaziChart chart,
    required int direction,
    required int startAge,
    required int requestedCount,
  }) {
    _ensureOpen();
    return _backend.fillXiaoyun(
      chart: chart,
      direction: direction,
      startAge: startAge,
      requestedCount: requestedCount,
    );
  }

  /// Derives the full 八字 chart (命宫/身宫/胎元/胎息/藏干/十神/大运十二宫) from
  /// the four pillars.
  BaziChart calcChart(GanzhiFourPillars pillars) {
    _ensureOpen();
    return _backend.calcChart(pillars);
  }

  /// Computes the 起运 (qi-yun) start of the first 大运 for a birth instant.
  ///
  /// Uses the bound [chineseCalendar] as the astronomical solar-term context.
  OperationResult<BaziQiyunResult> calcQiyun({
    required JulianDate<Ut1Scale> birthJdUt,
    required AstroDateTime birthCivilTime,
    required BaziChart chart,
    required BaziGender gender,
  }) {
    _ensureOpen();
    return _backend.calcQiyun(
      birthJdUt: birthJdUt,
      birthCivilTime: birthCivilTime,
      chart: chart,
      gender: gender,
    );
  }

  /// Fills the 大运 (da-yun) decades following a 起运 result.
  ///
  /// [requestedCount] is the number of one-based da-yun entries to generate.
  List<BaziDayun> fillDayun({
    required AstroDateTime birthCivilTime,
    required BaziChart chart,
    required BaziQiyunResult qiyun,
    required int requestedCount,
  }) {
    _ensureOpen();
    return _backend.fillDayun(
      birthCivilTime: birthCivilTime,
      chart: chart,
      qiyun: qiyun,
      requestedCount: requestedCount,
    );
  }

  /// Determines the 人元司令 (ren-yuan si-ling) in effect at an instant.
  ///
  /// Uses the bound [chineseCalendar] as the astronomical solar-term context.
  OperationResult<BaziRenyuanSilingResult> calcRenyuanSiling({
    required JulianDate<Ut1Scale> instantJdUt,
    required BaziChart chart,
    required BaziRenyuanSilingTableModel tableModel,
    required BaziRenyuanSilingTimeModel timeModel,
  }) {
    _ensureOpen();
    return _backend.calcRenyuanSiling(
      instantJdUt: instantJdUt,
      chart: chart,
      tableModel: tableModel,
      timeModel: timeModel,
    );
  }

  /// Returns the 人元司令 (ren-yuan si-ling) command segments of a month branch.
  List<BaziRenyuanSilingSegment> getRenyuanSilingSegments(
    int monthBranchId,
    BaziRenyuanSilingTableModel tableModel,
  ) {
    _ensureOpen();
    return _backend.getRenyuanSilingSegments(monthBranchId, tableModel);
  }

  /// Collects every relation in a chart within [pillarMask] and [relationMask].
  ///
  /// [relationMask] uses `1 << relationKind.id` bits; the default covers every
  /// relation kind.
  List<BaziRelation> collectChartRelations({
    required BaziChart chart,
    int pillarMask = 0xff,
    int relationMask = 0xffff,
  }) {
    _ensureOpen();
    return _backend.collectChartRelations(
      chart: chart,
      pillarMask: pillarMask,
      relationMask: relationMask,
    );
  }

  /// Collects the 神煞 (shen-sha) set attached to a target Ganzhi.
  ///
  /// When [gender] is provided the gender-dependent legacy shen-sha rules are
  /// applied; otherwise the gender-neutral rules are used.
  Set<BaziShenShaId> collectTargetShenSha({
    required BaziChart chart,
    required Ganzhi target,
    required BaziShenShaTargetKind targetKind,
    BaziGender? gender,
  }) {
    _ensureOpen();
    return _backend.collectTargetShenSha(
      chart: chart,
      target: target,
      targetKind: targetKind,
      gender: gender,
    );
  }

  OperationResult<BaziResult> _calculateResolved({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime chartTime,
    required BaziGender gender,
    required GanzhiRatHourMode ratHourMode,
    AstroDateTime? clockTime,
  }) {
    final utcCalendarResult = _time.reverseJulianDay(instantUtc);
    final timeScalesResult = _time.scalesFromUtc(utcCalendarResult.value);
    final pillarsResult = _calendar.fourPillars(
      instantUtc: instantUtc,
      virtualTime: chartTime,
      ratHourMode: ratHourMode,
    );
    final chart = calcChart(pillarsResult.value);
    final qiyunResult = calcQiyun(
      birthJdUt: timeScalesResult.value.value.ut1,
      birthCivilTime: chartTime,
      chart: chart,
      gender: gender,
    );
    return operationResult(
      BaziResult(
        instantUtc: instantUtc,
        chartTime: chartTime,
        clockTime: clockTime,
        pillars: pillarsResult.value,
        chart: chart,
        qiyun: qiyunResult.value,
      ),
      utcCalendarResult.flags |
          timeScalesResult.flags |
          pillarsResult.flags |
          qiyunResult.flags,
    );
  }

  void _validateClock(BaziClock clock) {
    if (clock.mode != BaziClockMode.fixedOffset &&
        (!clock.longitudeRadians.isFinite ||
            clock.longitudeRadians.abs() > 3.141592653589793)) {
      throw ArgumentError.value(
        clock.longitudeRadians,
        'longitudeRadians',
        'must be finite and within [-pi, pi]',
      );
    }
  }

  OperationResult<AstroDateTime> _chartTimeFromInstant(
    JulianDate<UtcScale> instantUtc,
    BaziClock clock,
  ) {
    _validateClock(clock);
    if (clock.mode == BaziClockMode.fixedOffset) {
      return _calendar.localTimeFromInstant(instantUtc);
    }

    final ut1 = _time.utcToUt1(instantUtc);
    final mean = LocalMeanSolarTime.fromUt1(
      ut1.value,
      longitudeRadians: clock.longitudeRadians,
    );
    if (clock.mode == BaziClockMode.meanSolar) {
      final chartTime = _time.reverseJulianDay(mean.coordinate);
      return operationResult(chartTime.value, ut1.flags | chartTime.flags);
    }

    final apparent = _solarTime.meanToApparent(mean);
    final chartTime = _time.reverseJulianDay(apparent.value.coordinate);
    return operationResult(
      chartTime.value,
      ut1.flags | apparent.flags | chartTime.flags,
    );
  }

  /// Calculates a complete BaZi result from a fixed-offset local civil clock.
  OperationResult<BaziResult> calculateLocal(
    AstroDateTime localTime, {
    required BaziGender gender,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    BaziClock clock = const BaziClock(),
  }) {
    _ensureOpen();
    final instant = _calendar.instantFromLocal(localTime);
    final chartTime = _chartTimeFromInstant(instant.value, clock);
    final result = _calculateResolved(
      instantUtc: instant.value,
      chartTime: chartTime.value,
      clockTime: localTime,
      gender: gender,
      ratHourMode: ratHourMode,
    );
    return operationResult(
      result.value,
      instant.flags | chartTime.flags | result.flags,
    );
  }

  /// Calculates a complete BaZi result from one UTC instant and the configured
  /// fixed civil clock.
  OperationResult<BaziResult> calculateInstant(
    JulianDate<UtcScale> instantUtc, {
    required BaziGender gender,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    BaziClock clock = const BaziClock(),
  }) {
    _ensureOpen();
    final clockTime = _calendar.localTimeFromInstant(instantUtc);
    final chartTime = _chartTimeFromInstant(instantUtc, clock);
    final result = _calculateResolved(
      instantUtc: instantUtc,
      chartTime: chartTime.value,
      clockTime: clockTime.value,
      gender: gender,
      ratHourMode: ratHourMode,
    );
    return operationResult(
      result.value,
      result.flags | clockTime.flags | chartTime.flags,
    );
  }

  /// Calculates from a Gregorian day and explicit local clock fields.
  OperationResult<BaziResult> calculateSolarDay(
    SolarDate solarDay, {
    required int hour,
    int minute = 0,
    int second = 0,
    int nanosecond = 0,
    required BaziGender gender,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    BaziClock clock = const BaziClock(),
  }) {
    final localTime = AstroDateTime(
      solarDay.year,
      solarDay.month,
      solarDay.day,
      hour,
      minute,
      second,
      nanosecond,
    );
    return calculateLocal(
      localTime,
      gender: gender,
      ratHourMode: ratHourMode,
      clock: clock,
    );
  }

  /// Converts a lunar day with the bound calendar, then calculates its chart.
  OperationResult<BaziResult> calculateLunarDay(
    LunarDate lunarDay, {
    required int hour,
    int minute = 0,
    int second = 0,
    int nanosecond = 0,
    required BaziGender gender,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    BaziClock clock = const BaziClock(),
  }) {
    final solarDay = _calendar.fromLunar(lunarDay);
    final result = calculateSolarDay(
      solarDay.value,
      hour: hour,
      minute: minute,
      second: second,
      nanosecond: nanosecond,
      gender: gender,
      ratHourMode: ratHourMode,
      clock: clock,
    );
    return operationResult(result.value, solarDay.flags | result.flags);
  }
}
