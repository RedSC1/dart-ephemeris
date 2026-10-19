import 'dart:convert';
import 'package:ephemeris/ephemeris.dart'
    hide EphemerisContext, ChineseCalendarContext, TaiyinExtensionHost;
import 'package:ephemeris/backend_web.dart';
import 'package:ephemeris/backend.dart';
import 'ziwei_models.dart';
import 'ziwei_placement_models.dart';
import 'ziwei_shared.dart';
import 'ziwei_records_web.dart';
export 'ziwei_shared.dart';
export 'ziwei_placement_models.dart';

List<num> _text(String value, {bool empty = true}) {
  if (value.contains('\u0000') || (!empty && value.isEmpty)) {
    throw ArgumentError.value(value, 'text', 'must be nonempty and NUL-free');
  }
  final bytes = utf8.encode(value);
  return [bytes.length, ...bytes];
}

String _readText(List<double> values, int offset) {
  final length = values[offset].toInt();
  return utf8.decode(
    values.skip(offset + 1).take(length).map((v) => v.toInt()).toList(),
  );
}

List<num> _jd(JulianDate<TimeScale> v) {
  if (v.dayNumber.abs() > 9007199254740991) {
    throw RangeError('JD exceeds exact Web integer range');
  }
  validateNativeFinite(v.dayFraction, 'dayFraction');
  return [v.dayNumber, v.dayFraction];
}

List<num> _date(AstroDateTime v) {
  validateNativeInt32(v.year, 'year');
  return [v.year, v.month, v.day, v.hour, v.minute, v.fractionalSecond];
}

AstroDateTime _readDate(List<double> v, [int offset = 0]) => AstroDateTime(
  v[offset].toInt(),
  v[offset + 1].toInt(),
  v[offset + 2].toInt(),
  v[offset + 3].toInt(),
  v[offset + 4].toInt(),
).addNanoseconds((v[offset + 5] * 1e9).round());
JulianDate<S> _readJd<S extends TimeScale>(List<double> v, [int offset = 0]) =>
    JulianDate<S>.fromParts(v[offset].toInt(), v[offset + 1]);
List<num> _clock(ZiweiClock v) {
  if (v.mode != ZiweiClockMode.fixedOffset &&
      (!v.longitudeRadians.isFinite ||
          v.longitudeRadians.abs() > 3.141592653589793)) {
    throw ArgumentError.value(v.longitudeRadians, 'longitudeRadians');
  }
  return [v.mode.index, v.longitudeRadians];
}

List<num> _birth(ZiweiBirthOptions v) => [
  v.ratHourMode.id,
  v.leapMonthStrategy.id,
  v.chartMode.id,
  v.wuHuDunYearBoundary.id,
  v.sihuaYearBoundary.id,
  v.bodyMasterYearBoundary.id,
];
List<num> _flow(ZiweiFlowOptions v) => [
  v.boundary.id,
  v.ratHourMode.id,
  v.childhoodStrategy.id,
  v.flowMonthPalaceStrategy.id,
];
List<num> _query(ZiweiTier1ReverseQuery v) {
  v.validate();
  return [
    v.lucunBranch ?? -1,
    v.hongluanBranch ?? -1,
    v.zuofuBranch ?? -1,
    v.youbiBranch ?? -1,
    v.wenchangBranch ?? -1,
    v.wenquBranch ?? -1,
    v.santaiBranch ?? -1,
    v.bazuoBranch ?? -1,
    v.ziweiBranch ?? -1,
  ];
}

void _range(int v, int low, int high, String name) {
  if (v < low || v > high) throw RangeError.range(v, low, high, name);
}

void _direction(int v) {
  if (v != -1 && v != 1) {
    throw ArgumentError.value(v, 'direction', 'must be -1 or 1');
  }
}

List<num> _input(ZiweiPlacementInput v) {
  _range(v.yearStem, 0, 9, 'yearStem');
  _range(v.yearBranch, 0, 11, 'yearBranch');
  _range(v.month, 1, 12, 'month');
  _range(v.day, 1, 30, 'day');
  _range(v.hourBranch, 0, 11, 'hourBranch');
  return [v.yearStem, v.yearBranch, v.month, v.day, v.hourBranch];
}

List<num> _patch(ZiweiPlacementPatch v) {
  if (v.yearStem != null) _range(v.yearStem!, 0, 9, 'yearStem');
  if (v.yearBranch != null) _range(v.yearBranch!, 0, 11, 'yearBranch');
  if (v.month != null) _range(v.month!, 1, 12, 'month');
  if (v.day != null) _range(v.day!, 1, 30, 'day');
  if (v.hourBranch != null) _range(v.hourBranch!, 0, 11, 'hourBranch');
  return [
    v.yearStem ?? -1,
    v.yearBranch ?? -1,
    v.month ?? -1,
    v.day ?? -1,
    v.hourBranch ?? -1,
    v.updateBureau == null
        ? -1
        : v.updateBureau!
        ? 1
        : 0,
  ];
}

int _generation(List<double> v) => v[32].toInt() + v[33].toInt() * 4294967296;

ZiweiDataCatalog createWebZiweiCatalog({
  String? profilePath,
  String? libraryPath,
  String? coreLibraryPath,
}) {
  if (libraryPath != null || coreLibraryPath != null) {
    throw UnsupportedError('Web has no native library path.');
  }
  return _WebZiweiCatalog(
    TaiyinExtensionHost.open(),
    profilePath ?? '/taiyin/ziwei/rules/default.toml',
  );
}

final class _WebZiweiCatalog extends ZiweiDataCatalog {
  _WebZiweiCatalog(this.host, this.profilePath) : super.internal() {
    handle = host
        .callZiwei(0, 0, 0, _text(profilePath, empty: false))
        .values[32]
        .toInt();
  }
  final TaiyinExtensionHost host;
  late final int handle;
  @override
  final String profilePath;
  bool _closed = false;
  @override
  bool get isClosed => _closed;
  void ensureOpen() {
    if (_closed) throw StateError('This ZiweiDataCatalog has been closed.');
  }

  @override
  void close() {
    if (_closed) return;
    host.callZiwei(handle, 0, 1, []);
    _closed = true;
  }

  @override
  void reload() {
    ensureOpen();
    host.callZiwei(handle, 0, 2, []);
  }

  @override
  int get generation {
    ensureOpen();
    return _generation(host.callZiwei(handle, 0, 3, []).values);
  }
}

final Expando<ZiweiContext> _cache = Expando<ZiweiContext>('web_ziwei');

extension ZiweiExtension on EphemerisContext {
  ZiweiContext get ziwei {
    final value = _cache[this];
    if (value != null && !value.isClosed && !value.chineseCalendar.isClosed) {
      return value;
    }
    return _cache[this] = createZiwei();
  }

  ZiweiContext createZiwei({
    ChineseCalendarContext? calendar,
    ZiweiDataCatalog? catalog,
    ZiweiOptionSelection selection = const ZiweiOptionSelection(),
    ZiweiRuleset ruleset = const ZiweiRuleset(),
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
    return ZiweiContext._(
      cal,
      catalog as _WebZiweiCatalog?,
      selection,
      ruleset,
    );
  }
}

final class ZiweiContext extends ZiweiContextFacade {
  ZiweiContext._(
    this.chineseCalendar,
    _WebZiweiCatalog? catalog,
    ZiweiOptionSelection selection,
    ZiweiRuleset ruleset,
  ) : super.internal() {
    _owned = catalog == null
        ? createWebZiweiCatalog() as _WebZiweiCatalog
        : null;
    final effective = catalog ?? _owned!;
    try {
      effective.ensureOpen();
      final entries = <(int, String, String)>[
        if (selection.placementDefault.isNotEmpty)
          (0, '', selection.placementDefault),
        for (final e in selection.placement.entries) (0, e.key, e.value),
        if (selection.brightnessDefault.isNotEmpty)
          (1, '', selection.brightnessDefault),
        for (final e in selection.brightness.entries) (1, e.key, e.value),
        if (selection.sihuaDefault.isNotEmpty) (2, '', selection.sihuaDefault),
        for (final e in selection.sihua.entries) (2, e.key, e.value),
        if (selection.masters.isNotEmpty) (3, '', selection.masters),
        if (selection.longevity.isNotEmpty) (4, '', selection.longevity),
      ];
      final labels = <String>{};
      for (final module in ruleset.modules) {
        if (!labels.add(module.label)) {
          throw ArgumentError('Duplicate rule module label');
        }
      }
      final payload = <num>[
        entries.length,
        for (final e in entries) ...[e.$1, ..._text(e.$2), ..._text(e.$3)],
        ruleset.modules.length,
        for (final m in ruleset.modules) ...[
          ..._text(m.label, empty: false),
          ..._text(m.starsJson),
          ..._text(m.brightnessJson),
          ..._text(m.sihuaJson),
          ..._text(m.flowJson),
          ..._text(m.mastersJson),
        ],
      ];
      _handle = _host
          .callZiwei(effective.handle, 0, 4, payload)
          .values[32]
          .toInt();
    } catch (_) {
      _owned?.close();
      rethrow;
    }
  }
  @override
  final ChineseCalendarContext chineseCalendar;
  @override
  Time get timeService => chineseCalendar.owner.time;
  TaiyinExtensionHost get _host => chineseCalendar.extensionHost;
  late final int _handle;
  _WebZiweiCatalog? _owned;
  bool _closed = false;
  @override
  bool get isClosed => _closed;
  void _ensureOpen() {
    if (_closed) throw StateError('This ZiweiContext has been closed.');
    _host.ensureOpen();
  }

  @override
  void close() {
    if (_closed) return;
    _host.callZiwei(_handle, 0, 5, []);
    _closed = true;
    _owned?.close();
  }

  OperationResult<List<double>> _call(
    int op,
    List<num> input, {
    int chart = 0,
    bool diagnostic = false,
  }) {
    _ensureOpen();
    final reply = _host.callZiwei(
      _handle,
      chart,
      op,
      input,
      diagnostic: diagnostic,
    );
    return operationResult(reply.values, ResultFlags(reply.values[0].toInt()));
  }

  List<double> _values(int op, List<num> input, {int chart = 0}) =>
      _call(op, input, chart: chart).value;
  @override
  int get generation => _generation(_values(6, []));
  @override
  int get starCount => _values(6, [])[34].toInt();
  ZiweiStar? _star(List<double> v) {
    final id = v[32].toInt();
    if (id == 65535) return null;
    return ZiweiStar(
      id: id,
      key: _readText(v, 35),
      category: ZiweiStarCategory.fromId(v[33].toInt()),
      isNatal: v[34] != 0,
    );
  }

  @override
  ZiweiStar? findStar(String key) =>
      _star(_values(7, _text(key, empty: false)));
  void _starId(int id) {
    validateNativeUint16(id, 'starId');
    if (id >= starCount) {
      throw ArgumentError.value(
        id,
        'starId',
        'must identify a registered star',
      );
    }
  }

  @override
  ZiweiStar star(int starId) {
    _starId(starId);
    return _star(_values(8, [starId]))!;
  }

  @override
  OperationResult<ZiweiChart> createChart({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    required ZiweiGender gender,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) {
    final result = _call(9, [
      ..._jd(instantUtc),
      ..._date(virtualTime),
      gender.id,
      ..._birth(options),
    ], diagnostic: true);
    return operationResult(
      _WebZiweiChart(this, result.value[32].toInt()),
      result.flags,
    );
  }

  @override
  OperationResult<ZiweiChart> createChartAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    required ZiweiGender gender,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) {
    final result = _call(10, [
      ..._jd(instantUt1),
      ..._clock(clock),
      gender.id,
      ..._birth(options),
    ], diagnostic: true);
    return operationResult(
      _WebZiweiChart(this, result.value[32].toInt()),
      result.flags,
    );
  }

  ZiweiCastingChart _casting(
    int op,
    List<num> input,
    ZiweiGender gender,
    ZiweiChartMode mode, [
    ZiweiBureau? bureau,
  ]) => _WebZiweiCastingChart(
    this,
    _values(op, [gender.id, mode.id, bureau?.id ?? -1, ...input])[32].toInt(),
  );
  @override
  ZiweiCastingChart createCastingChart(
    ZiweiPlacementInput input, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
    ZiweiBureau? fixedBureau,
  }) => _casting(33, _input(input), gender, chartMode, fixedBureau);
  @override
  ZiweiCastingChart castingFromIndex(
    int index, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  }) {
    _range(index, 0, 259199, 'index');
    return _casting(34, [index], gender, chartMode);
  }

  @override
  ZiweiCastingChart castingFromNumber(
    String number, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  }) {
    if (!RegExp(r'^\d+$').hasMatch(number)) {
      throw ArgumentError.value(number, 'number', 'must be ASCII decimal text');
    }
    return _casting(35, _text(number, empty: false), gender, chartMode);
  }

  @override
  ZiweiCastingChart randomCastingChart({
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  }) => _casting(36, [], gender, chartMode);
  @override
  OperationResult<AstroDateTime> chartTimeFromUt1(
    JulianDate<Ut1Scale> instantUt1, {
    ZiweiClock clock = const ZiweiClock(),
  }) {
    final r = _call(25, [
      ..._clock(clock),
      ..._jd(instantUt1),
    ], diagnostic: true);
    return operationResult(_readDate(r.value, 32), r.flags);
  }

  @override
  OperationResult<JulianDate<Ut1Scale>> chartTimeToUt1(
    AstroDateTime virtualTime, {
    ZiweiClock clock = const ZiweiClock(),
  }) {
    final r = _call(26, [
      ..._clock(clock),
      ..._date(virtualTime),
    ], diagnostic: true);
    return operationResult(_readJd<Ut1Scale>(r.value, 32), r.flags);
  }

  OperationResult<ZiweiClockTarget> _step(
    int op,
    JulianDate<Ut1Scale> instant,
    ZiweiClock clock,
    GanzhiRatHourMode mode,
    int direction,
  ) {
    _direction(direction);
    final r = _call(op, [
      ..._clock(clock),
      ..._jd(instant),
      mode.id,
      direction,
    ], diagnostic: true);
    return operationResult(
      ZiweiClockTarget(
        instantUt1: _readJd<Ut1Scale>(r.value, 32),
        virtualTime: _readDate(r.value, 34),
        ratHourSegment: ZiweiRatHourSegment.fromId(r.value[40].toInt()),
      ),
      r.flags,
    );
  }

  @override
  OperationResult<ZiweiClockTarget> stepFlowHourAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    ZiweiClock clock = const ZiweiClock(),
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    int direction = 1,
  }) => _step(27, instantUt1, clock, ratHourMode, direction);
  @override
  OperationResult<ZiweiClockTarget> stepFlowDayAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    ZiweiClock clock = const ZiweiClock(),
    int direction = 1,
  }) => _step(28, instantUt1, clock, GanzhiRatHourMode.noSplit, direction);
  List<double> _legacyStep(
    int op,
    JulianDate<UtcScale> instant,
    AstroDateTime time,
    int mode,
    int direction,
  ) {
    _direction(direction);
    return _values(op, [..._jd(instant), ..._date(time), mode, direction]);
  }

  @override
  ZiweiFlowHourTarget stepFlowHourTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    int direction = 1,
  }) {
    final v = _legacyStep(
      29,
      instantUtc,
      virtualTime,
      ratHourMode.id,
      direction,
    );
    return ZiweiFlowHourTarget(
      instantUtc: _readJd<UtcScale>(v, 32),
      virtualTime: _readDate(v, 34),
      ratHourSegment: ZiweiRatHourSegment.fromId(v[40].toInt()),
    );
  }

  @override
  ZiweiFlowDayTarget stepFlowDayTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    int direction = 1,
  }) {
    final v = _legacyStep(30, instantUtc, virtualTime, 0, direction);
    return ZiweiFlowDayTarget(
      instantUtc: _readJd<UtcScale>(v, 32),
      virtualTime: _readDate(v, 34),
    );
  }

  List<num> _request(
    JulianDate<TimeScale> start,
    JulianDate<TimeScale> end,
    AstroDateTime time,
    ZiweiGender gender,
    ZiweiBirthOptions options,
    ZiweiTier1ReverseQuery query,
  ) {
    if (end.compareTo(start) <= 0) {
      throw ArgumentError('end must be after start');
    }
    return [
      ..._jd(start),
      ..._jd(end),
      ..._date(time),
      gender.id,
      ..._birth(options),
      ..._query(query),
    ];
  }

  @override
  OperationResult<List<ZiweiReverseLookupCandidate>> reverseLookupTier1({
    required JulianDate<UtcScale> startInstantUtc,
    required JulianDate<UtcScale> endInstantUtc,
    required AstroDateTime startVirtualTime,
    required ZiweiGender gender,
    required ZiweiTier1ReverseQuery query,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) {
    final r = _call(
      31,
      _request(
        startInstantUtc,
        endInstantUtc,
        startVirtualTime,
        gender,
        options,
        query,
      ),
      diagnostic: true,
    );
    return operationResult(
      List.unmodifiable(
        List.generate(
          r.value[2].toInt(),
          (i) => _readZiweiReverseCandidate(
            Web_taiyin_ziwei_reverse_candidate(
              r.value,
              32 + i * Web_taiyin_ziwei_reverse_candidate.width,
            ),
          ),
        ),
      ),
      r.flags,
    );
  }

  @override
  OperationResult<List<ZiweiReverseLookupUt1Candidate>>
  reverseLookupTier1AtUt1({
    required JulianDate<Ut1Scale> startInstantUt1,
    required JulianDate<Ut1Scale> endInstantUt1,
    required ZiweiGender gender,
    required ZiweiTier1ReverseQuery query,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) {
    final r = _call(32, [
      ..._request(
        startInstantUt1,
        endInstantUt1,
        AstroDateTime(2000, 1, 1),
        gender,
        options,
        query,
      ),
      ..._clock(clock),
    ], diagnostic: true);
    return operationResult(
      List.unmodifiable(
        List.generate(r.value[2].toInt(), (i) {
          final v = Web_taiyin_ziwei_reverse_candidate(
            r.value,
            32 + i * Web_taiyin_ziwei_reverse_candidate.width,
          );
          return ZiweiReverseLookupUt1Candidate(
            instantUt1: _readJd<Ut1Scale>(v.values, v.offset),
            virtualTime: _readDate(v.values, v.offset + 2),
            lunarYear: v.lunar_year,
            lunarMonth: v.lunar_month,
            lunarDay: v.lunar_day,
            lunarIsLeap: v.lunar_is_leap != 0,
            hourBranch: v.hour_branch,
            ratHourSegment: ZiweiRatHourSegment.fromId(v.rat_hour_segment),
          );
        }),
      ),
      r.flags,
    );
  }
}

final class _WebZiweiChart extends ZiweiChart {
  _WebZiweiChart(this.context, this.handle) : super.internal();
  final ZiweiContext context;
  final int handle;
  bool _closed = false;
  @override
  bool get isClosed => _closed;
  void _ensureOpen() {
    if (_closed) throw StateError('This ZiweiChart has been closed.');
    context._ensureOpen();
  }

  List<double> _values(int op, List<num> input) {
    _ensureOpen();
    return context._values(op, input, chart: handle);
  }

  List<double> get _metadata => _values(12, []);
  @override
  void close() {
    if (_closed) return;
    context._host.callZiwei(context._handle, handle, 11, []);
    _closed = true;
  }

  @override
  ZiweiAnchors get anchors =>
      ZiweiAnchors(_metadata.skip(32).take(31).map((v) => v.toInt()).toList());
  @override
  ZiweiChartSummary get summary {
    final v = _metadata;
    final stems = List<int>.filled(12, 0);
    for (var i = 0; i < 12; ++i) {
      stems[v[72 + i * 2].toInt()] = v[73 + i * 2].toInt();
    }
    return ZiweiChartSummary(
      gender: ZiweiGender.fromId(v[63].toInt()),
      bureau: ZiweiBureau.fromId(v[64].toInt()),
      bodyPalaceBranch: v[65].toInt(),
      lifeMaster: v[66].toInt(),
      bodyMaster: v[67].toInt(),
      transforms: _readZiweiTransformSet(Web_taiyin_ziwei_transform_set(v, 68)),
      palaceStems: List.unmodifiable(stems),
    );
  }

  @override
  ZiweiPlacementState get placement {
    final v = _metadata;
    return ZiweiPlacementState(
      _readPlacementInput(Web_taiyin_ziwei_placement_input(v, 96)),
      _readPlacementPatch(Web_taiyin_ziwei_placement_patch(v, 101)),
      v[107].toInt(),
    );
  }

  @override
  List<ZiweiOmittedPlacement> get omittedPlacements =>
      _omitted(_values(45, []));
  @override
  List<ZiweiPalaceState> get palaces {
    final a = anchors, s = summary.palaceStems;
    return List.unmodifiable([
      for (final p in ZiweiPalace.values)
        ZiweiPalaceState(
          palace: p,
          branchId: a.palacePosition(p),
          stemId: s[a.palacePosition(p)],
          stars: palaceStars(a.palacePosition(p)),
        ),
    ]);
  }

  @override
  ZiweiPalaceState palace(ZiweiPalace palace) => palaces[palace.id];
  List<double> _star(int id) {
    context._starId(id);
    return _values(13, [id]);
  }

  @override
  int? starPosition(int starId) => _position(_star(starId)[32]);
  @override
  int? starPalace(int starId) => _position(_star(starId)[33]);
  @override
  ZiweiBrightness brightness(int starId) =>
      ZiweiBrightness.fromId(_star(starId)[34].toInt());
  @override
  int transformMask(int starId) => _star(starId)[35].toInt();
  @override
  bool hasTransform(int starId, ZiweiTransformMark mark) =>
      (transformMask(starId) & (1 << mark.id)) != 0;
  List<ZiweiStar> _stars(List<double> v) => List.unmodifiable([
    for (final id in v.skip(32).take(v[2].toInt())) context.star(id.toInt()),
  ]);
  @override
  List<ZiweiStar> palaceStars(int branchId) {
    _range(branchId, 0, 11, 'branchId');
    return _stars(_values(14, [branchId]));
  }

  @override
  ZiweiChart modify(ZiweiPlacementPatch patch) =>
      _WebZiweiChart(context, _values(15, _patch(patch))[32].toInt());
  @override
  ZiweiChart shiftLifePalace(int steps) {
    validateNativeInt32(steps, 'steps');
    return _WebZiweiChart(context, _values(16, [steps])[32].toInt());
  }

  @override
  ZiweiChart reset() => _WebZiweiChart(context, _values(17, [])[32].toInt());
  @override
  int get flowLayerCount => _values(21, [])[32].toInt();
  OperationResult<ZiweiFlowResolution> _set(int op, List<num> input) {
    _ensureOpen();
    final r = context._call(op, input, chart: handle, diagnostic: true);
    return operationResult(
      _readZiweiFlowResolution(Web_taiyin_ziwei_flow_summary(r.value, 32)),
      r.flags,
    );
  }

  @override
  OperationResult<ZiweiFlowResolution> setFlow({
    required JulianDate<UtcScale> targetInstantUtc,
    required AstroDateTime targetVirtualTime,
    ZiweiFlowOptions options = const ZiweiFlowOptions(),
    ZiweiFlowLevel deepestLevel = ZiweiFlowLevel.hour,
  }) => _set(18, [
    ..._jd(targetInstantUtc),
    ..._date(targetVirtualTime),
    ..._flow(options),
    deepestLevel.id,
  ]);
  @override
  OperationResult<ZiweiFlowResolution> setFlowAtUt1({
    required JulianDate<Ut1Scale> targetInstantUt1,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiFlowOptions options = const ZiweiFlowOptions(),
    ZiweiFlowLevel deepestLevel = ZiweiFlowLevel.hour,
  }) => _set(19, [
    ..._jd(targetInstantUt1),
    ..._clock(clock),
    ..._flow(options),
    deepestLevel.id,
  ]);
  @override
  void truncateFlow(ZiweiFlowLevel firstRemovedLevel) {
    _values(20, [firstRemovedLevel.id]);
  }

  @override
  ZiweiFlowLayerSummary flowLayerSummary(ZiweiFlowLevel level) {
    final v = _values(22, [level.id]);
    return ZiweiFlowLayerSummary(
      lifePalace: v[32].toInt(),
      coordinateStem: v[33].toInt(),
      coordinateBranch: v[34].toInt(),
      transforms: _readZiweiTransformSet(Web_taiyin_ziwei_transform_set(v, 35)),
    );
  }

  @override
  int? flowStarPosition(ZiweiFlowLevel level, int starId) {
    context._starId(starId);
    return _position(_values(23, [level.id, starId])[32]);
  }

  @override
  List<ZiweiStar> flowPalaceStars(ZiweiFlowLevel level, int branchId) {
    _range(branchId, 0, 11, 'branchId');
    return _stars(_values(24, [level.id, branchId]));
  }
}

int? _position(double value) => value == 255 ? null : value.toInt();
List<ZiweiOmittedPlacement> _omitted(List<double> v) => List.unmodifiable(
  List.generate(
    v[2].toInt(),
    (i) => ZiweiOmittedPlacement(v[32 + i * 2].toInt(), v[33 + i * 2].toInt()),
  ),
);

final class _WebZiweiCastingChart extends ZiweiCastingChart {
  _WebZiweiCastingChart(this.context, this.handle) : super.internal();
  final ZiweiContext context;
  final int handle;
  bool _closed = false;
  @override
  bool get isClosed => _closed;
  List<double> _values(int op, List<num> input) {
    if (_closed) throw StateError('This ZiweiCastingChart has been closed.');
    return context._values(op, input, chart: handle);
  }

  @override
  void close() {
    if (_closed) return;
    context._host.callZiwei(context._handle, handle, 37, []);
    _closed = true;
  }

  @override
  ZiweiCastingSummary get summary {
    final v = _values(38, []);
    return _readCastingSummary(
      Web_taiyin_ziwei_casting_summary(v, 32),
      _readText(v, 32 + Web_taiyin_ziwei_casting_summary.width),
    );
  }

  @override
  List<ZiweiOmittedPlacement> get omittedPlacements =>
      _omitted(_values(41, []));
  List<double> _stars() => _values(39, []);
  @override
  int? starPosition(int starId) {
    _range(starId, 0, 65535, 'starId');
    final v = _stars();
    if (starId >= v[2]) throw RangeError('starId is not registered');
    return _position(v[32 + starId * 2]);
  }

  @override
  int? starPalace(int starId) {
    final p = starPosition(starId);
    return p == null ? null : summary.palaceBranches.indexOf(p);
  }

  @override
  int transformMask(int starId) {
    _range(starId, 0, 65535, 'starId');
    final v = _stars();
    if (starId >= v[2]) throw RangeError('starId is not registered');
    return v[33 + starId * 2].toInt();
  }

  @override
  bool hasTransform(int starId, ZiweiTransformMark mark) =>
      (transformMask(starId) & (1 << mark.id)) != 0;
  @override
  List<ZiweiStar> palaceStars(int branch) {
    _range(branch, 0, 11, 'branch');
    final v = _stars();
    return List.unmodifiable([
      for (var i = 0; i < v[2]; ++i)
        if (v[32 + i * 2] == branch) context.star(i),
    ]);
  }

  @override
  ZiweiBrightness brightness(int starId) {
    _range(starId, 0, 65535, 'starId');
    return ZiweiBrightness.fromId(_values(40, [starId])[32].toInt());
  }

  @override
  ZiweiCastingChart modify(ZiweiPlacementPatch patch) =>
      _WebZiweiCastingChart(context, _values(42, _patch(patch))[32].toInt());
  @override
  ZiweiCastingChart shiftLifePalace(int steps) {
    validateNativeInt32(steps, 'steps');
    return _WebZiweiCastingChart(context, _values(43, [steps])[32].toInt());
  }

  @override
  ZiweiCastingChart reset() =>
      _WebZiweiCastingChart(context, _values(44, [])[32].toInt());
}

ZiweiReverseLookupCandidate _readZiweiReverseCandidate(
  Web_taiyin_ziwei_reverse_candidate value,
) {
  return ZiweiReverseLookupCandidate(
    instantUtc: _fromJd<UtcScale>(value.instant_utc),
    virtualTime: _fromDate(value.virtual_time),
    lunarYear: value.lunar_year,
    lunarMonth: value.lunar_month,
    lunarDay: value.lunar_day,
    lunarIsLeap: value.lunar_is_leap != 0,
    hourBranch: value.hour_branch,
    ratHourSegment: ZiweiRatHourSegment.fromId(value.rat_hour_segment),
  );
}

ZiweiTransformSet _readZiweiTransformSet(Web_taiyin_ziwei_transform_set value) {
  return ZiweiTransformSet(
    lu: value.lu,
    quan: value.quan,
    ke: value.ke,
    ji: value.ji,
  );
}

ZiweiFlowResolution _readZiweiFlowResolution(
  Web_taiyin_ziwei_flow_summary value,
) {
  return ZiweiFlowResolution(
    effectiveBirthYear: value.effective_birth_year,
    effectiveTargetYear: value.effective_target_year,
    targetLunarYear: value.target_lunar_year,
    targetMonth: value.target_month,
    targetEffectiveMonth: value.target_effective_month,
    targetMonthSequence: value.target_month_sequence,
    targetMonthName: value.target_month_name,
    targetPalaceMonthIndex: value.target_palace_month_index,
    targetMonthBuildingBranch: value.target_month_building_branch,
    targetDay: value.target_day,
    targetHourIndex: value.target_hour_index,
    targetRatHourSegment: ZiweiRatHourSegment.fromId(
      value.target_rat_hour_segment,
    ),
    targetMonthIsLeap: value.target_month_is_leap != 0,
    decade: ZiweiDecadeLimit(
      index: value.decade_index,
      startAge: value.decade_start_age,
      endAge: value.decade_end_age,
    ),
    smallLimit: ZiweiSmallLimit(
      virtualAge: value.small_limit_virtual_age,
      stemId: value.small_limit_stem,
      branchId: value.small_limit_branch,
    ),
  );
}

ZiweiPlacementInput _readPlacementInput(Web_taiyin_ziwei_placement_input v) =>
    ZiweiPlacementInput(
      yearStem: v.year_stem,
      yearBranch: v.year_branch,
      month: v.month,
      day: v.day,
      hourBranch: v.hour_branch,
    );

ZiweiPlacementPatch _readPlacementPatch(Web_taiyin_ziwei_placement_patch v) =>
    ZiweiPlacementPatch(
      yearStem: v.year_stem < 0 ? null : v.year_stem,
      yearBranch: v.year_branch < 0 ? null : v.year_branch,
      month: v.month < 0 ? null : v.month,
      day: v.day < 0 ? null : v.day,
      hourBranch: v.hour_branch < 0 ? null : v.hour_branch,
      updateBureau: v.update_bureau < 0 ? null : v.update_bureau != 0,
    );

ZiweiCastingSummary _readCastingSummary(
  Web_taiyin_ziwei_casting_summary s,
  String number,
) => ZiweiCastingSummary.internal(
  number: number,
  input: _readPlacementInput(s.input),
  originalInput: _readPlacementInput(s.original_input),
  overrides: _readPlacementPatch(s.overrides),
  index: s.index == 0xffffffff ? null : s.index,
  method: ZiweiCastingMethod.values[s.method],
  gender: ZiweiGender.fromId(s.gender),
  chartMode: ZiweiChartMode.values[s.chart_mode],
  bureau: ZiweiBureau.fromId(s.bureau),
  originalBureau: ZiweiBureau.fromId(s.original_bureau),
  bodyPalace: s.body_palace,
  lifeMaster: s.life_master,
  bodyMaster: s.body_master,
  yearTransformStem: s.year_transform_stem,
  transformations: List.unmodifiable([
    s.year_lu,
    s.year_quan,
    s.year_ke,
    s.year_ji,
  ]),
  updateBureau: s.update_bureau != 0,
  lifePalaceShift: s.life_palace_shift,
  palaceBranches: List.unmodifiable([
    for (var i = 0; i < 12; i++) s.palace_branches[i],
  ]),
  palaceStems: List.unmodifiable([
    for (var i = 0; i < 12; i++) s.palace_stems[i],
  ]),
);
JulianDate<S> _fromJd<S extends TimeScale>(Web_taiyin_split_julian_date v) =>
    _readJd<S>(v.values, v.offset);
AstroDateTime _fromDate(Web_taiyin_calendar_datetime v) =>
    _readDate(v.values, v.offset);
