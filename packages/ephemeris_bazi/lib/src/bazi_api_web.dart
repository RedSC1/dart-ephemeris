import 'package:ephemeris/ephemeris.dart'
    hide EphemerisContext, ChineseCalendarContext, TaiyinExtensionHost;
import 'package:ephemeris/backend_web.dart';
import 'package:ephemeris/backend.dart';
import 'bazi_models.dart';
import 'bazi_shared.dart';
import 'bazi_backend.dart';
import 'bazi_records_web.dart';
export 'shen_sha_models.dart';
export 'shen_sha_shared.dart';

final Expando<BaziContext> _cache = Expando<BaziContext>('web_bazi');

extension BaziExtension on EphemerisContext {
  BaziContext get bazi {
    final cached = _cache[this];
    if (cached != null &&
        !cached.isClosed &&
        !cached.chineseCalendar.isClosed) {
      return cached;
    }
    return _cache[this] = createBazi();
  }

  BaziContext createBazi({
    BaziContextConfig config = const BaziContextConfig(),
    ChineseCalendarContext? calendar,
    String? libraryPath,
  }) {
    if (libraryPath != null) {
      throw UnsupportedError('Web has no native module path.');
    }
    extensionHost.ensureOpen();
    final cal = calendar ?? chineseCalendar;
    if (!identical(cal.owner, this)) {
      throw ArgumentError.value(
        calendar,
        'calendar',
        'must belong to this EphemerisContext',
      );
    }
    cal.extensionHost.ensureOpen();
    return BaziContext._(_WebBaziBackend(cal.extensionHost, config), cal);
  }
}

final class BaziContext extends BaziFacade {
  BaziContext._(_WebBaziBackend backend, this.chineseCalendar)
    : super.internal(
        backend,
        chineseCalendar,
        chineseCalendar.owner.time,
        chineseCalendar.owner.solarTime,
      );
  @override
  final ChineseCalendarContext chineseCalendar;
}

final class _WebBaziBackend implements BaziBackend {
  _WebBaziBackend(this._host, BaziContextConfig config) {
    _handle = _host
        .callBazi(0, 0, [
          config.earthPalaceMode.id,
          config.qiyunDirectionMode.id,
          config.qiyunTimeModel.id,
          config.dayunBoundaryModel.id,
        ])
        .values[32]
        .toInt();
  }
  final TaiyinExtensionHost _host;
  late final int _handle;
  bool _closed = false;
  @override
  bool get isClosed => _closed;
  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _host.destroyBazi(_handle);
  }

  void _ensureOpen() {
    if (_closed) throw StateError('This BaziContext has been closed.');
  }

  OperationResult<T> _flagged<T>(
    int operation,
    List<num> input,
    T Function(List<double>) read,
  ) {
    _ensureOpen();
    final reply = _host.callBazi(_handle, operation, input);
    return operationResult(
      read(reply.values),
      ResultFlags(reply.values[0].toInt()),
    );
  }

  T _call<T>(int operation, List<num> input, T Function(List<double>) read) =>
      _flagged(operation, input, read).value;
  List<num> _jd(JulianDate<TimeScale> value) {
    if (value.dayNumber.abs() > 9007199254740991) {
      throw RangeError('JD outside exact JS range');
    }
    return [value.dayNumber, value.dayFraction];
  }

  List<num> _calendarInput(AstroDateTime value) {
    validateNativeInt32(value.year, 'year');
    return [
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.fractionalSecond,
    ];
  }

  List<num> _chartInput(BaziChart v) => baziChartValues(v);
  List<num> _qiyunInput(BaziQiyunResult v) => [
    v.direction,
    v.timeModel.id,
    v.referenceJieIndex,
    v.jieIntervalDays,
    v.startAgeYears,
    v.offsetYears,
    v.offsetMonths,
    v.offsetDays,
    v.offsetHours,
    v.offsetMinutes,
    v.offsetSeconds,
    ..._jd(v.referenceJieJdUt),
    ..._jd(v.startJdUt),
    ..._calendarInput(v.startCivilTime),
  ];
  @override
  ({EarthlyBranch a, EarthlyBranch b}) getKongWang(Ganzhi value) {
    _ensureOpen();
    return _call(
      1,
      [value.raw],
      (v) => (
        a: EarthlyBranch.fromId(v[32].toInt()),
        b: EarthlyBranch.fromId(v[33].toInt()),
      ),
    );
  }

  @override
  BaziTenGod getTenGod({required int dayStemId, required int targetStemId}) {
    _ensureOpen();
    _requireStemId(dayStemId, 'dayStemId');
    _requireStemId(targetStemId, 'targetStemId');
    return _call(2, [
      dayStemId,
      targetStemId,
    ], (v) => BaziTenGod.fromId(v[32].toInt()));
  }

  @override
  ({List<int> stems, int count}) getHiddenStems(int branchId) {
    _ensureOpen();
    _requireBranchId(branchId, 'branchId');
    return _call(
      3,
      [branchId],
      (v) => (
        count: v[32].toInt(),
        stems: List<int>.unmodifiable(v.sublist(33, 36).map((n) => n.toInt())),
      ),
    );
  }

  @override
  BaziStemRelationResult calcStemRelation(int stemA, int stemB) {
    _ensureOpen();
    _requireStemId(stemA, 'stemA');
    _requireStemId(stemB, 'stemB');
    return _call(4, [
      stemA,
      stemB,
    ], (v) => _readStemRelation(v[32].toInt(), v[33].toInt()));
  }

  @override
  BaziBranchRelationResult calcBranchRelation(int branchA, int branchB) {
    _ensureOpen();
    _requireBranchId(branchA, 'branchA');
    _requireBranchId(branchB, 'branchB');
    return _call(5, [
      branchA,
      branchB,
    ], (v) => _readBranchRelation(v[32].toInt(), v[33].toInt()));
  }

  @override
  BaziBranchTripleRelationResult calcBranchTripleRelation(
    int branchA,
    int branchB,
    int branchC,
  ) {
    _ensureOpen();
    _requireBranchId(branchA, 'branchA');
    _requireBranchId(branchB, 'branchB');
    _requireBranchId(branchC, 'branchC');
    return _call(6, [
      branchA,
      branchB,
      branchC,
    ], (v) => _readBranchTripleRelation(v[32].toInt(), v[33].toInt()));
  }

  @override
  int getLifeStage({
    required int stemId,
    required int branchId,
    BaziEarthPalaceMode mode = BaziEarthPalaceMode.fireEarth,
  }) {
    _ensureOpen();
    _requireStemId(stemId, 'stemId');
    _requireBranchId(branchId, 'branchId');
    return _call(7, [stemId, branchId, mode.id], (v) => v[32].toInt());
  }

  @override
  BaziChart calcChart(GanzhiFourPillars pillars) {
    _ensureOpen();
    return _call(8, [
      pillars.year.raw,
      pillars.month.raw,
      pillars.day.raw,
      pillars.hour.raw,
    ], (v) => _readBaziChart(Web_taiyin_bazi_chart(v, 32)));
  }

  @override
  Ganzhi calcLiunian(int effectiveYear) {
    _ensureOpen();
    _requireSignedInt32(effectiveYear, 'effectiveYear');
    return _call(9, [effectiveYear], (v) => Ganzhi.fromNative(v[32].toInt()));
  }

  @override
  Ganzhi calcLiuyue(Ganzhi yearPillar, int monthBranch) {
    _ensureOpen();
    _requireBranchId(monthBranch, 'monthBranch');
    return _call(10, [
      yearPillar.raw,
      monthBranch,
    ], (v) => Ganzhi.fromNative(v[32].toInt()));
  }

  @override
  Ganzhi calcLiuri(AstroDateTime civilDate) {
    _ensureOpen();
    return _call(
      11,
      _calendarInput(civilDate),
      (v) => Ganzhi.fromNative(v[32].toInt()),
    );
  }

  @override
  Ganzhi calcLiushi(Ganzhi dayPillar, int hourIndex) {
    _ensureOpen();
    _requireBranchId(hourIndex, 'hourIndex');
    return _call(12, [
      dayPillar.raw,
      hourIndex,
    ], (v) => Ganzhi.fromNative(v[32].toInt()));
  }

  @override
  Ganzhi calcXiaoyun(BaziChart chart, int direction, int age) {
    _ensureOpen();
    _requireDirection(direction);
    _requirePositiveInt32(age, 'age');
    return _call(13, [
      ..._chartInput(chart),
      direction,
      age,
    ], (v) => Ganzhi.fromNative(v[32].toInt()));
  }

  @override
  List<BaziXiaoyun> fillXiaoyun({
    required BaziChart chart,
    required int direction,
    required int startAge,
    required int requestedCount,
  }) {
    _ensureOpen();
    _requireDirection(direction);
    _requirePositiveInt32(startAge, 'startAge');
    _requireNonnegativeInt32(requestedCount, 'requestedCount');
    if (requestedCount != 0 && startAge > 0x7fffffff - requestedCount + 1) {
      throw RangeError(
        'startAge + requestedCount - 1 must fit a signed 32-bit value',
      );
    }
    return _call(
      14,
      [..._chartInput(chart), direction, startAge, requestedCount],
      (v) => List<BaziXiaoyun>.unmodifiable([
        for (var i = 0; i < v[2]; i++)
          _readXiaoyun(
            Web_taiyin_bazi_xiaoyun(v, 32 + i * Web_taiyin_bazi_xiaoyun.width),
          ),
      ]),
    );
  }

  @override
  OperationResult<BaziQiyunResult> calcQiyun({
    required JulianDate<Ut1Scale> birthJdUt,
    required AstroDateTime birthCivilTime,
    required BaziChart chart,
    required BaziGender gender,
  }) {
    _ensureOpen();
    _host.ensureOpen();
    return _flagged(15, [
      ..._jd(birthJdUt),
      ..._calendarInput(birthCivilTime),
      ..._chartInput(chart),
      gender.id,
    ], (v) => _readQiyunResult(Web_taiyin_bazi_qiyun_result(v, 32)));
  }

  @override
  List<BaziDayun> fillDayun({
    required AstroDateTime birthCivilTime,
    required BaziChart chart,
    required BaziQiyunResult qiyun,
    required int requestedCount,
  }) {
    _ensureOpen();
    _requireUnsigned32(requestedCount, 'requestedCount');
    _validateQiyunResult(qiyun);
    return _call(
      16,
      [
        ..._calendarInput(birthCivilTime),
        ..._chartInput(chart),
        ..._qiyunInput(qiyun),
        requestedCount,
      ],
      (v) => List<BaziDayun>.unmodifiable([
        for (var i = 0; i < v[2]; i++)
          _readDayun(
            Web_taiyin_bazi_dayun(v, 32 + i * Web_taiyin_bazi_dayun.width),
          ),
      ]),
    );
  }

  @override
  OperationResult<BaziRenyuanSilingResult> calcRenyuanSiling({
    required JulianDate<Ut1Scale> instantJdUt,
    required BaziChart chart,
    required BaziRenyuanSilingTableModel tableModel,
    required BaziRenyuanSilingTimeModel timeModel,
  }) {
    _ensureOpen();
    _host.ensureOpen();
    return _flagged(
      17,
      [..._jd(instantJdUt), ..._chartInput(chart), tableModel.id, timeModel.id],
      (v) => _readRenyuanSilingResult(
        Web_taiyin_bazi_renyuan_siling_result(v, 32),
      ),
    );
  }

  @override
  List<BaziRenyuanSilingSegment> getRenyuanSilingSegments(
    int monthBranchId,
    BaziRenyuanSilingTableModel tableModel,
  ) {
    _ensureOpen();
    _requireBranchId(monthBranchId, 'monthBranchId');
    return _call(
      18,
      [monthBranchId, tableModel.id],
      (v) => List<BaziRenyuanSilingSegment>.unmodifiable([
        for (var i = 0; i < v[2]; i++)
          _readRenyuanSilingSegment(
            Web_taiyin_bazi_renyuan_siling_segment(
              v,
              32 + i * Web_taiyin_bazi_renyuan_siling_segment.width,
            ),
          ),
      ]),
    );
  }

  @override
  List<BaziRelation> collectChartRelations({
    required BaziChart chart,
    int pillarMask = 0xff,
    int relationMask = 0xffff,
  }) {
    _ensureOpen();
    _requireUnsigned32(pillarMask, 'pillarMask');
    _requireUnsigned32(relationMask, 'relationMask');
    return _call(
      19,
      [..._chartInput(chart), pillarMask, relationMask],
      (v) => List<BaziRelation>.unmodifiable([
        for (var i = 0; i < v[2]; i++)
          _readRelation(
            Web_taiyin_bazi_relation(
              v,
              32 + i * Web_taiyin_bazi_relation.width,
            ),
          ),
      ]),
    );
  }

  @override
  Set<BaziShenShaId> collectTargetShenSha({
    required BaziChart chart,
    required Ganzhi target,
    required BaziShenShaTargetKind targetKind,
    BaziGender? gender,
  }) {
    _ensureOpen();
    return _call(
      20,
      [..._chartInput(chart), target.raw, targetKind.id, gender?.id ?? -1],
      (v) => <BaziShenShaId>{
        for (var i = 0; i < v[2]; i++)
          if (v[32 + i] < 66) BaziShenShaId.fromId(v[32 + i].toInt()),
      },
    );
  }

  void _requireStemId(int value, String name) {
    if (value < 0 || value >= 10) {
      throw ArgumentError.value(value, name, 'must be in the range 0..9');
    }
  }

  void _requireBranchId(int value, String name) {
    if (value < 0 || value >= 12) {
      throw ArgumentError.value(value, name, 'must be in the range 0..11');
    }
  }

  void _requireDirection(int value) {
    if (value != -1 && value != 1) {
      throw ArgumentError.value(value, 'direction', 'must be -1 or 1');
    }
  }

  void _requireSignedInt32(int value, String name) {
    validateNativeInt32(value, name);
  }

  void _requirePositiveInt32(int value, String name) {
    if (value < 1 || value > 0x7fffffff) {
      throw RangeError.range(value, 1, 0x7fffffff, name);
    }
  }

  void _requireNonnegativeInt32(int value, String name) {
    if (value < 0 || value > 0x7fffffff) {
      throw RangeError.range(value, 0, 0x7fffffff, name);
    }
  }

  void _requireUnsigned32(int value, String name) {
    validateNativeUint32(value, name);
  }

  void _validateQiyunResult(BaziQiyunResult value) {
    _requireDirection(value.direction);
    validateNativeUint8(value.referenceJieIndex, 'referenceJieIndex');
    for (final field in [
      (value: value.offsetYears, name: 'offsetYears'),
      (value: value.offsetMonths, name: 'offsetMonths'),
      (value: value.offsetDays, name: 'offsetDays'),
      (value: value.offsetHours, name: 'offsetHours'),
      (value: value.offsetMinutes, name: 'offsetMinutes'),
    ]) {
      _requireSignedInt32(field.value, field.name);
    }
    for (final field in [
      (value: value.jieIntervalDays, name: 'jieIntervalDays'),
      (value: value.startAgeYears, name: 'startAgeYears'),
      (value: value.offsetSeconds, name: 'offsetSeconds'),
    ]) {
      validateNativeFinite(field.value, field.name);
    }
    _jd(value.referenceJieJdUt);
    _jd(value.startJdUt);
    _calendarInput(value.startCivilTime);
  }
}

BaziChart _readBaziChart(Web_taiyin_bazi_chart value) {
  return BaziChart(
    yearPillar: Ganzhi.fromNative(value.year_pillar),
    monthPillar: Ganzhi.fromNative(value.month_pillar),
    dayPillar: Ganzhi.fromNative(value.day_pillar),
    hourPillar: Ganzhi.fromNative(value.hour_pillar),
    mingGong: Ganzhi.fromNative(value.ming_gong),
    shenGong: Ganzhi.fromNative(value.shen_gong),
    taiYuan: Ganzhi.fromNative(value.tai_yuan),
    taiXi: Ganzhi.fromNative(value.tai_xi),
    hiddenStemCount: List<int>.unmodifiable([
      for (var pillar = 0; pillar < 4; pillar++)
        value.hidden_stem_count[pillar],
    ]),
    hiddenStems: List<List<int>>.unmodifiable([
      for (var pillar = 0; pillar < 4; pillar++)
        List<int>.unmodifiable([
          for (var slot = 0; slot < 3; slot++) value.hidden_stems[pillar][slot],
        ]),
    ]),
    visibleTenGods: List<int>.unmodifiable([
      for (var pillar = 0; pillar < 4; pillar++) value.visible_ten_gods[pillar],
    ]),
    hiddenTenGods: List<List<int>>.unmodifiable([
      for (var pillar = 0; pillar < 4; pillar++)
        List<int>.unmodifiable([
          for (var slot = 0; slot < 3; slot++)
            value.hidden_ten_gods[pillar][slot],
        ]),
    ]),
    lifeStages: List<int>.unmodifiable([
      for (var pillar = 0; pillar < 4; pillar++) value.life_stages[pillar],
    ]),
    nayinIds: List<int>.unmodifiable([
      for (var pillar = 0; pillar < 4; pillar++) value.nayin_ids[pillar],
    ]),
  );
}

BaziRelation _readRelation(Web_taiyin_bazi_relation value) {
  return BaziRelation(
    kind: BaziRelationKind.fromId(value.kind),
    pillarMask: BaziRelationPillarFlags.fold(value.pillar_mask),
    combinedElementId: value.combined_element_id == _taiyinBaziInvalidWuxing
        ? null
        : BaziWuxing.fromId(value.combined_element_id),
  );
}

BaziStemRelationResult _readStemRelation(int flags, int combinedElementId) {
  return BaziStemRelationResult(
    flags: BaziStemRelationFlags.fold(flags),
    combinedElementId: combinedElementId == _taiyinBaziInvalidWuxing
        ? null
        : BaziWuxing.fromId(combinedElementId),
  );
}

BaziBranchRelationResult _readBranchRelation(int flags, int combinedElementId) {
  return BaziBranchRelationResult(
    flags: BaziBranchRelationFlags.fold(flags),
    combinedElementId: combinedElementId == _taiyinBaziInvalidWuxing
        ? null
        : BaziWuxing.fromId(combinedElementId),
  );
}

BaziBranchTripleRelationResult _readBranchTripleRelation(
  int flags,
  int combinedElementId,
) {
  return BaziBranchTripleRelationResult(
    flags: BaziBranchTripleRelationFlags.fold(flags),
    combinedElementId: combinedElementId == _taiyinBaziInvalidWuxing
        ? null
        : BaziWuxing.fromId(combinedElementId),
  );
}

BaziQiyunResult _readQiyunResult(Web_taiyin_bazi_qiyun_result value) {
  return BaziQiyunResult(
    direction: value.direction,
    timeModel: BaziQiyunTimeModel.fromId(value.time_model),
    referenceJieIndex: value.reference_jie_index,
    jieIntervalDays: value.jie_interval_days,
    startAgeYears: value.start_age_years,
    offsetYears: value.offset_years,
    offsetMonths: value.offset_months,
    offsetDays: value.offset_days,
    offsetHours: value.offset_hours,
    offsetMinutes: value.offset_minutes,
    offsetSeconds: value.offset_seconds,
    referenceJieJdUt: readJulianDate<Ut1Scale>(value.reference_jie_jd_ut),
    startJdUt: readJulianDate<Ut1Scale>(value.start_jd_ut),
    startCivilTime: readCalendarDateTime(value.start_civil_time),
  );
}

BaziXiaoyun _readXiaoyun(Web_taiyin_bazi_xiaoyun value) {
  return BaziXiaoyun(age: value.age, ganzhi: Ganzhi.fromNative(value.ganzhi));
}

BaziDayun _readDayun(Web_taiyin_bazi_dayun value) {
  return BaziDayun(
    index: value.index,
    ganzhi: Ganzhi.fromNative(value.ganzhi),
    startVirtualAge: value.start_virtual_age,
    endVirtualAge: value.end_virtual_age,
    startJdUt: readJulianDate<Ut1Scale>(value.start_jd_ut),
    endJdUt: readJulianDate<Ut1Scale>(value.end_jd_ut),
    startCivilTime: readCalendarDateTime(value.start_civil_time),
    endCivilTime: readCalendarDateTime(value.end_civil_time),
  );
}

BaziRenyuanSilingSegment _readRenyuanSilingSegment(
  Web_taiyin_bazi_renyuan_siling_segment value,
) {
  return BaziRenyuanSilingSegment(
    stemId: value.stem_id,
    originKind: BaziRenyuanSilingOriginKind.fromId(value.origin_kind),
    segmentIndex: value.segment_index,
    startDay: value.start_day,
    endDay: value.end_day,
  );
}

BaziRenyuanSilingResult _readRenyuanSilingResult(
  Web_taiyin_bazi_renyuan_siling_result value,
) {
  return BaziRenyuanSilingResult(
    tableModel: BaziRenyuanSilingTableModel.fromId(value.table_model),
    timeModel: BaziRenyuanSilingTimeModel.fromId(value.time_model),
    monthBranchId: value.month_branch_id,
    stemId: value.stem_id,
    originKind: BaziRenyuanSilingOriginKind.fromId(value.origin_kind),
    segmentIndex: value.segment_index,
    previousJieIndex: value.previous_jie_index,
    daysSinceJie: value.days_since_jie,
    segmentStartDay: value.segment_start_day,
    segmentEndDay: value.segment_end_day,
    previousJieJdUt: readJulianDate<Ut1Scale>(value.previous_jie_jd_ut),
  );
}

void _validateBaziChart(BaziChart value) {
  void requireFour(List<int> values, String name) {
    if (values.length != 4) {
      throw ArgumentError.value(values, name, 'must contain four values');
    }
    for (var index = 0; index < values.length; index++) {
      validateNativeUint8(values[index], '$name[$index]');
    }
  }

  requireFour(value.hiddenStemCount, 'hiddenStemCount');
  requireFour(value.visibleTenGods, 'visibleTenGods');
  requireFour(value.lifeStages, 'lifeStages');
  requireFour(value.nayinIds, 'nayinIds');

  void requireFourByThree(List<List<int>> values, String name) {
    if (values.length != 4) {
      throw ArgumentError.value(values, name, 'must contain four rows');
    }
    for (var pillar = 0; pillar < values.length; pillar++) {
      final row = values[pillar];
      if (row.length != 3) {
        throw ArgumentError.value(
          row,
          '$name[$pillar]',
          'must contain three values',
        );
      }
      for (var slot = 0; slot < row.length; slot++) {
        validateNativeUint8(row[slot], '$name[$pillar][$slot]');
      }
    }
  }

  requireFourByThree(value.hiddenStems, 'hiddenStems');
  requireFourByThree(value.hiddenTenGods, 'hiddenTenGods');
}

const _taiyinBaziInvalidWuxing = 255;
JulianDate<S> readJulianDate<S extends TimeScale>(
  Web_taiyin_split_julian_date v,
) => JulianDate<S>.fromParts(v.day_number, v.day_fraction);
AstroDateTime readCalendarDateTime(Web_taiyin_calendar_datetime v) =>
    AstroDateTime(
      v.year,
      v.month,
      v.day,
      v.hour,
      v.minute,
    ).addNanoseconds((v.second * 1e9).round());

/// Internal copied wire value for the official Web Shen Sha adapter.
List<num> baziChartValues(BaziChart v) {
  _validateBaziChart(v);
  return [
    v.yearPillar.raw,
    v.monthPillar.raw,
    v.dayPillar.raw,
    v.hourPillar.raw,
    v.mingGong.raw,
    v.shenGong.raw,
    v.taiYuan.raw,
    v.taiXi.raw,
    ...v.hiddenStemCount,
    for (final r in v.hiddenStems) ...r,
    ...v.visibleTenGods,
    for (final r in v.hiddenTenGods) ...r,
    ...v.lifeStages,
    ...v.nayinIds,
  ];
}
