import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:taiyin/ffi.dart';
import 'package:taiyin/taiyin.dart';

import 'bazi_models.dart';

/// The native "invalid five-element" sentinel (`TAIYIN_BAZI_INVALID_WUXING`).
const int _taiyinBaziInvalidWuxing = 0xff;

TaiyinExtensionModule _openBaziModule([String? libraryPath]) =>
    TaiyinExtensionModule.open(
      packageName: 'taiyin_bazi',
      environmentVariable: 'TAIYIN_BAZI_LIBRARY_PATH',
      libraryBaseName: 'taiyin_bazi',
      identitySymbol: 'taiyin_bazi_context_destroy',
      requiredSymbols: taiyinBaziSymbols,
      libraryPath: libraryPath,
    );

ResultFlags _checkStatus(
  TaiyinExtensionHost host,
  int rawResult, {
  EphemerisDiagnostic? diagnostic,
}) => host.checkStatus(rawResult, diagnostic: diagnostic);

final Expando<BaziContext> _baziCache = Expando<BaziContext>('taiyin_bazi');

/// BaZi entry points attached to an [EphemerisContext].
extension BaziExtension on EphemerisContext {
  /// A BaZi context using the default configuration, bound to the cached
  /// default Chinese-calendar context.
  ///
  /// The first access creates and caches the native context; a cached entry
  /// closed by the caller (or whose bound calendar was closed) is replaced on
  /// the next access. The BaZi context does not borrow this context's native
  /// state, so closing the owning context does not invalidate it.
  BaziContext get bazi {
    final cached = _baziCache[this];
    if (cached != null &&
        !cached.isClosed &&
        !cached.chineseCalendar.isClosed) {
      return cached;
    }
    final created = createBazi();
    _baziCache[this] = created;
    return created;
  }

  /// Creates an independent BaZi context owned by the caller.
  ///
  /// [calendar] defaults to the cached default Chinese-calendar context and
  /// must have been created by this same [EphemerisContext]. Call
  /// [BaziContext.close] when it is no longer needed. [libraryPath] overrides
  /// the bundled BaZi native module for this call.
  BaziContext createBazi({
    BaziContextConfig config = const BaziContextConfig(),
    ChineseCalendarContext? calendar,
    String? libraryPath,
  }) {
    final host = extensionHost;
    host.ensureOpen();
    final effectiveCalendar = calendar ?? chineseCalendar;
    if (!identical(effectiveCalendar.owner, this)) {
      throw ArgumentError.value(
        calendar,
        'calendar',
        'must belong to this EphemerisContext',
      );
    }
    effectiveCalendar.extensionHost.ensureOpen();
    return BaziContext._create(
      host,
      _openBaziModule(libraryPath),
      config,
      effectiveCalendar,
    );
  }
}

/// Owns one native BaZi context.
///
/// Create one through [BaziExtension.createBazi], or use
/// [BaziExtension.bazi] for the cached default configuration. Call [close]
/// before discarding the handle; a native finalizer is attached as a safety
/// net for contexts that are not closed explicitly.
final class BaziContext implements Finalizable {
  BaziContext._(
    this._host,
    this._module,
    this._context,
    this._finalizer,
    this._calendar,
  ) {
    _finalizer.attach(this, _context.cast(), detach: this);
  }

  factory BaziContext._create(
    TaiyinExtensionHost host,
    TaiyinExtensionModule module,
    BaziContextConfig config,
    ChineseCalendarContext calendar,
  ) {
    final finalizer = module.finalizerFor('taiyin_bazi_context_destroy');
    final bindings = module.bindings;
    final context = using((arena) {
      final nativeConfig = _writeBaziConfig(bindings, arena, config);
      final output = arena<Pointer<taiyin_bazi_context>>();
      _checkStatus(
        host,
        bindings.taiyin_bazi_context_create(nativeConfig, output),
      );
      return output.value;
    });
    return BaziContext._(host, module, context, finalizer, calendar);
  }

  final TaiyinExtensionHost _host;
  final TaiyinExtensionModule _module;
  final Pointer<taiyin_bazi_context> _context;
  final NativeFinalizer _finalizer;
  final ChineseCalendarContext _calendar;

  TaiyinBindings get _bindings => _module.bindings;
  TaiyinBindings get _coreBindings => _host.bindings;
  bool _closed = false;

  bool get isClosed => _closed;

  /// The calendar context shared by four-pillar and BaZi calculations.
  ChineseCalendarContext get chineseCalendar => _calendar;

  /// Releases the native BaZi context. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    _finalizer.detach(this);
    _bindings.taiyin_bazi_context_destroy(_context);
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This BaziContext has been closed.');
    }
  }

  /// Returns the 空亡 (kong-wang) branches for a Ganzhi value.
  ({EarthlyBranch a, EarthlyBranch b}) getKongWang(Ganzhi value) {
    _ensureOpen();
    return using((arena) {
      final output = arena<Uint8>(2);
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_get_kong_wang(value.raw, output),
      );
      return (
        a: EarthlyBranch.fromId(output[0]),
        b: EarthlyBranch.fromId(output[1]),
      );
    });
  }

  /// Returns the 十神 (ten god) of a stem relative to the day stem.
  BaziTenGod getTenGod({required int dayStemId, required int targetStemId}) {
    _ensureOpen();
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_get_ten_god(dayStemId, targetStemId, output),
      );
      return BaziTenGod.fromId(output.value);
    });
  }

  /// Returns the 藏干 (hidden stems) of an earthly branch.
  ({List<int> stems, int count}) getHiddenStems(int branchId) {
    _ensureOpen();
    return using((arena) {
      final output = arena<Uint8>(3);
      final count = arena<Uint8>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_get_hidden_stems(branchId, output, count),
      );
      final stemCount = count.value;
      return (
        stems: List.unmodifiable([
          for (var index = 0; index < stemCount; index++) output[index],
        ]),
        count: stemCount,
      );
    });
  }

  /// Calculates the relation between two heavenly stems.
  BaziStemRelationResult calcStemRelation(int stemA, int stemB) {
    _ensureOpen();
    return using((arena) {
      final flags = arena<Uint32>();
      final combinedElement = arena<Uint8>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_calc_stem_relation(
          stemA,
          stemB,
          flags,
          combinedElement,
        ),
      );
      return _readStemRelation(flags.value, combinedElement.value);
    });
  }

  /// Calculates the relation between two earthly branches.
  BaziBranchRelationResult calcBranchRelation(int branchA, int branchB) {
    _ensureOpen();
    return using((arena) {
      final flags = arena<Uint32>();
      final combinedElement = arena<Uint8>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_calc_branch_relation(
          branchA,
          branchB,
          flags,
          combinedElement,
        ),
      );
      return _readBranchRelation(flags.value, combinedElement.value);
    });
  }

  /// Calculates the triple relation among three earthly branches.
  BaziBranchTripleRelationResult calcBranchTripleRelation(
    int branchA,
    int branchB,
    int branchC,
  ) {
    _ensureOpen();
    return using((arena) {
      final flags = arena<Uint32>();
      final combinedElement = arena<Uint8>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_calc_branch_triple_relation(
          branchA,
          branchB,
          branchC,
          flags,
          combinedElement,
        ),
      );
      return _readBranchTripleRelation(flags.value, combinedElement.value);
    });
  }

  /// Returns the 长生十二宫 (life stage) of a stem in an earthly branch.
  int getLifeStage({
    required int stemId,
    required int branchId,
    BaziEarthPalaceMode mode = BaziEarthPalaceMode.fireEarth,
  }) {
    _ensureOpen();
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_get_life_stage(stemId, branchId, mode.id, output),
      );
      return output.value;
    });
  }

  /// Calculates the 流年 (liu-nian / flow-year) Ganzhi for an effective year.
  Ganzhi calcLiunian(int effectiveYear) {
    _ensureOpen();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_calc_liunian(effectiveYear, output),
      );
      return Ganzhi.fromNative(output.value);
    });
  }

  /// Calculates the 流月 (liu-yue / flow-month) Ganzhi.
  ///
  /// [monthBranch] follows the C ABI: 2 = 寅, …, 0 = 子, 1 = 丑.
  Ganzhi calcLiuyue(Ganzhi yearPillar, int monthBranch) {
    _ensureOpen();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_calc_liuyue(yearPillar.raw, monthBranch, output),
      );
      return Ganzhi.fromNative(output.value);
    });
  }

  /// Calculates the 流日 (liu-ri / flow-day) Ganzhi for a civil date.
  Ganzhi calcLiuri(AstroDateTime civilDate) {
    _ensureOpen();
    return using((arena) {
      final calendar = writeNativeCalendar(_coreBindings, arena, civilDate);
      final output = arena<taiyin_ganzhi>();
      _checkStatus(_host, _bindings.taiyin_bazi_calc_liuri(calendar, output));
      return Ganzhi.fromNative(output.value);
    });
  }

  /// Calculates the 流时 (liu-shi / flow-hour) Ganzhi.
  ///
  /// [hourIndex] follows the C ABI branch sequence: 0 = 子, …, 11 = 亥.
  Ganzhi calcLiushi(Ganzhi dayPillar, int hourIndex) {
    _ensureOpen();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_calc_liushi(dayPillar.raw, hourIndex, output),
      );
      return Ganzhi.fromNative(output.value);
    });
  }

  /// Calculates the 小运 (xiao-yun) Ganzhi for an age within a chart.
  Ganzhi calcXiaoyun(BaziChart chart, int direction, int age) {
    _ensureOpen();
    return using((arena) {
      final nativeChart = _writeBaziChart(_bindings, arena, chart);
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_calc_xiaoyun(nativeChart, direction, age, output),
      );
      return Ganzhi.fromNative(output.value);
    });
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
    return using((arena) {
      final nativeChart = _writeBaziChart(_bindings, arena, chart);

      final count = arena<Size>();
      final countStatus = _bindings.taiyin_bazi_fill_xiaoyun(
        nativeChart,
        direction,
        startAge,
        requestedCount,
        nullptr,
        0,
        count,
      );
      _checkStatus(_host, countStatus);
      final requiredCount = validatedNativeArrayCount(
        count.value,
        'BaZi xiao-yun',
      );
      if (requiredCount == 0) {
        return const <BaziXiaoyun>[];
      }

      final output = arena<taiyin_bazi_xiaoyun>(requiredCount);
      for (var index = 0; index < requiredCount; index++) {
        _bindings.taiyin_bazi_xiaoyun_init(output + index);
      }
      final fillStatus = _bindings.taiyin_bazi_fill_xiaoyun(
        nativeChart,
        direction,
        startAge,
        requestedCount,
        output,
        requiredCount,
        count,
      );
      _checkStatus(_host, fillStatus);
      final resultCount = validatedNativeResultCount(
        count.value,
        requiredCount,
      );
      return List.unmodifiable([
        for (var index = 0; index < resultCount; index++)
          _readXiaoyun((output + index).ref),
      ]);
    });
  }

  /// Derives the full 八字 chart (命宫/身宫/胎元/胎息/藏干/十神/大运十二宫) from
  /// the four pillars.
  BaziChart calcChart(GanzhiFourPillars pillars) {
    _ensureOpen();
    return using((arena) {
      final nativePillars = _writeFourPillars(_coreBindings, arena, pillars);
      final output = arena<taiyin_bazi_chart>();
      _bindings.taiyin_bazi_chart_init(output);
      _checkStatus(
        _host,
        _bindings.taiyin_bazi_calc_chart(_context, nativePillars, output),
      );
      return _readBaziChart(output.ref);
    });
  }

  OperationResult<BaziResult> _calculateResolved({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime localTime,
    required BaziGender gender,
    required GanzhiRatHourMode ratHourMode,
  }) {
    final utcCalendarResult = _calendar.owner.time.reverseJulianDay(instantUtc);
    final timeScalesResult = _calendar.owner.time.scalesFromUtc(
      utcCalendarResult.value,
    );
    final pillarsResult = _calendar.fourPillars(
      instantUtc: instantUtc,
      virtualTime: localTime,
      ratHourMode: ratHourMode,
    );
    final chart = calcChart(pillarsResult.value);
    final qiyunResult = calcQiyun(
      birthJdUt: timeScalesResult.value.value.ut1,
      birthCivilTime: localTime,
      chart: chart,
      gender: gender,
    );
    return operationResult(
      BaziResult(
        instantUtc: instantUtc,
        localTime: localTime,
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

  /// Calculates a complete BaZi result from a local civil clock.
  OperationResult<BaziResult> calculateLocal(
    AstroDateTime localTime, {
    required BaziGender gender,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) {
    _ensureOpen();
    final instantUtc = localTime.toJulianDate<UtcScale>().addSeconds(
      -_calendarOffsetSeconds,
    );
    return _calculateResolved(
      instantUtc: instantUtc,
      localTime: localTime,
      gender: gender,
      ratHourMode: ratHourMode,
    );
  }

  /// Calculates a complete BaZi result from one UTC instant.
  OperationResult<BaziResult> calculateInstant(
    JulianDate<UtcScale> instantUtc, {
    required BaziGender gender,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) {
    _ensureOpen();
    final localJd = instantUtc.addSeconds(_calendarOffsetSeconds);
    final localTimeResult = _calendar.owner.time.reverseJulianDay(localJd);
    final result = _calculateResolved(
      instantUtc: instantUtc,
      localTime: localTimeResult.value,
      gender: gender,
      ratHourMode: ratHourMode,
    );
    return operationResult(result.value, result.flags | localTimeResult.flags);
  }

  double get _calendarOffsetSeconds {
    final config = _calendar.config;
    if (config.dayBoundaryMode ==
        ChineseCalendarDayBoundaryMode.fixedUtcOffset) {
      return config.utcOffsetMinutes * 60.0;
    }
    return config.calendarMeridianDegrees * 240.0;
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
    _calendar.extensionHost.ensureOpen();
    return using((arena) {
      final output = arena<taiyin_bazi_qiyun_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_bazi_qiyun_result_init(output);
      _coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_bazi_calc_qiyun(
        _context,
        _calendar.extensionHost.nativeHandle<taiyin_chinese_calendar_context>(),
        writeJulianDate(arena, birthJdUt),
        writeNativeCalendar(_coreBindings, arena, birthCivilTime),
        _writeBaziChart(_bindings, arena, chart),
        gender.id,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _host.readDiagnostic(diagnostic.ref);
      _host.recordDiagnostic(mappedDiagnostic);
      final flags = _checkStatus(_host, status, diagnostic: mappedDiagnostic);
      return operationResult(_readQiyunResult(output.ref), flags);
    });
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
    return using((arena) {
      final birthCivil = writeNativeCalendar(
        _coreBindings,
        arena,
        birthCivilTime,
      );
      final nativeChart = _writeBaziChart(_bindings, arena, chart);
      final nativeQiyun = _writeQiyun(_bindings, arena, qiyun);

      final count = arena<Size>();
      final countStatus = _bindings.taiyin_bazi_fill_dayun(
        _context,
        birthCivil,
        nativeChart,
        nativeQiyun,
        requestedCount,
        nullptr,
        0,
        count,
      );
      _checkStatus(_host, countStatus);
      final requiredCount = validatedNativeArrayCount(
        count.value,
        'BaZi da-yun',
      );
      if (requiredCount == 0) {
        return const <BaziDayun>[];
      }

      final output = arena<taiyin_bazi_dayun>(requiredCount);
      for (var index = 0; index < requiredCount; index++) {
        _bindings.taiyin_bazi_dayun_init(output + index);
      }
      final fillStatus = _bindings.taiyin_bazi_fill_dayun(
        _context,
        birthCivil,
        nativeChart,
        nativeQiyun,
        requestedCount,
        output,
        requiredCount,
        count,
      );
      _checkStatus(_host, fillStatus);
      final resultCount = validatedNativeResultCount(
        count.value,
        requiredCount,
      );
      return List.unmodifiable([
        for (var index = 0; index < resultCount; index++)
          _readDayun((output + index).ref),
      ]);
    });
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
    _calendar.extensionHost.ensureOpen();
    return using((arena) {
      final output = arena<taiyin_bazi_renyuan_siling_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_bazi_renyuan_siling_result_init(output);
      _coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_bazi_calc_renyuan_siling(
        _calendar.extensionHost.nativeHandle<taiyin_chinese_calendar_context>(),
        writeJulianDate(arena, instantJdUt),
        _writeBaziChart(_bindings, arena, chart),
        tableModel.id,
        timeModel.id,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _host.readDiagnostic(diagnostic.ref);
      _host.recordDiagnostic(mappedDiagnostic);
      final flags = _checkStatus(_host, status, diagnostic: mappedDiagnostic);
      return operationResult(_readRenyuanSilingResult(output.ref), flags);
    });
  }

  /// Returns the 人元司令 (ren-yuan si-ling) command segments of a month branch.
  List<BaziRenyuanSilingSegment> getRenyuanSilingSegments(
    int monthBranchId,
    BaziRenyuanSilingTableModel tableModel,
  ) {
    _ensureOpen();
    return using((arena) {
      final count = arena<Size>();
      final countStatus = _bindings.taiyin_bazi_get_renyuan_siling_segments(
        monthBranchId,
        tableModel.id,
        nullptr,
        0,
        count,
      );
      _checkStatus(_host, countStatus);
      final requiredCount = validatedNativeArrayCount(
        count.value,
        'BaZi renyuan siling segments',
      );
      if (requiredCount == 0) {
        return const <BaziRenyuanSilingSegment>[];
      }

      final output = arena<taiyin_bazi_renyuan_siling_segment>(requiredCount);
      for (var index = 0; index < requiredCount; index++) {
        _bindings.taiyin_bazi_renyuan_siling_segment_init(output + index);
      }
      final fillStatus = _bindings.taiyin_bazi_get_renyuan_siling_segments(
        monthBranchId,
        tableModel.id,
        output,
        requiredCount,
        count,
      );
      _checkStatus(_host, fillStatus);
      final resultCount = validatedNativeResultCount(
        count.value,
        requiredCount,
      );
      return List.unmodifiable([
        for (var index = 0; index < resultCount; index++)
          _readRenyuanSilingSegment((output + index).ref),
      ]);
    });
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
    return using((arena) {
      final nativeChart = _writeBaziChart(_bindings, arena, chart);
      final count = arena<Size>();
      final countStatus = _bindings.taiyin_bazi_collect_chart_relations(
        nativeChart,
        pillarMask,
        relationMask,
        nullptr,
        0,
        count,
      );
      _checkStatus(_host, countStatus);
      final requiredCount = validatedNativeArrayCount(
        count.value,
        'BaZi chart relations',
      );
      if (requiredCount == 0) {
        return const <BaziRelation>[];
      }

      final output = arena<taiyin_bazi_relation>(requiredCount);
      for (var index = 0; index < requiredCount; index++) {
        _bindings.taiyin_bazi_relation_init(output + index);
      }
      final fillStatus = _bindings.taiyin_bazi_collect_chart_relations(
        nativeChart,
        pillarMask,
        relationMask,
        output,
        requiredCount,
        count,
      );
      _checkStatus(_host, fillStatus);
      final resultCount = validatedNativeResultCount(
        count.value,
        requiredCount,
      );
      return List.unmodifiable([
        for (var index = 0; index < resultCount; index++)
          _readRelation((output + index).ref),
      ]);
    });
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
    return using((arena) {
      final nativeChart = _writeBaziChart(_bindings, arena, chart);
      const wordCapacity = 2;
      final words = arena<Uint64>(wordCapacity);
      final wordCount = arena<Size>();
      final status = gender == null
          ? _bindings.taiyin_bazi_collect_target_shen_sha(
              nativeChart,
              target.raw,
              targetKind.id,
              words,
              wordCapacity,
              wordCount,
            )
          : _bindings.taiyin_bazi_collect_target_shen_sha_with_gender(
              nativeChart,
              target.raw,
              targetKind.id,
              gender.id,
              words,
              wordCapacity,
              wordCount,
            );
      _checkStatus(_host, status);
      final count = wordCount.value;
      if (count < 1 || count > wordCapacity) {
        throw StateError(
          'Native BaZi shen-sha collection returned word count=$count '
          'outside 1..$wordCapacity',
        );
      }
      final result = <BaziShenShaId>{};
      for (var wordIndex = 0; wordIndex < count; wordIndex++) {
        final word = words[wordIndex];
        for (var bit = 0; bit < 64; bit++) {
          if ((word & (1 << bit)) == 0) continue;
          final id = wordIndex * 64 + bit;
          if (id < 66) {
            result.add(BaziShenShaId.fromId(id));
          }
        }
      }
      return result;
    });
  }
}

Pointer<taiyin_bazi_context_config> _writeBaziConfig(
  TaiyinBindings bindings,
  Arena arena,
  BaziContextConfig config,
) {
  final native = arena<taiyin_bazi_context_config>();
  bindings.taiyin_bazi_context_config_init(native);
  native.ref
    ..earth_palace_mode = config.earthPalaceMode.id
    ..qiyun_direction_mode = config.qiyunDirectionMode.id
    ..qiyun_time_model = config.qiyunTimeModel.id
    ..dayun_boundary_model = config.dayunBoundaryModel.id;
  return native;
}

Pointer<taiyin_ganzhi_four_pillars> _writeFourPillars(
  TaiyinBindings bindings,
  Arena arena,
  GanzhiFourPillars value,
) {
  final native = arena<taiyin_ganzhi_four_pillars>();
  bindings.taiyin_ganzhi_four_pillars_init(native);
  native.ref
    ..year = value.year.raw
    ..month = value.month.raw
    ..day = value.day.raw
    ..hour = value.hour.raw;
  return native;
}

Pointer<taiyin_bazi_chart> _writeBaziChart(
  TaiyinBindings bindings,
  Arena arena,
  BaziChart value,
) {
  final native = arena<taiyin_bazi_chart>();
  bindings.taiyin_bazi_chart_init(native);
  native.ref
    ..year_pillar = value.yearPillar.raw
    ..month_pillar = value.monthPillar.raw
    ..day_pillar = value.dayPillar.raw
    ..hour_pillar = value.hourPillar.raw
    ..ming_gong = value.mingGong.raw
    ..shen_gong = value.shenGong.raw
    ..tai_yuan = value.taiYuan.raw
    ..tai_xi = value.taiXi.raw;
  for (var pillar = 0; pillar < 4; pillar++) {
    native.ref.hidden_stem_count[pillar] = value.hiddenStemCount[pillar];
    native.ref.visible_ten_gods[pillar] = value.visibleTenGods[pillar];
    native.ref.life_stages[pillar] = value.lifeStages[pillar];
    native.ref.nayin_ids[pillar] = value.nayinIds[pillar];
    for (var slot = 0; slot < 3; slot++) {
      native.ref.hidden_stems[pillar][slot] = value.hiddenStems[pillar][slot];
      native.ref.hidden_ten_gods[pillar][slot] =
          value.hiddenTenGods[pillar][slot];
    }
  }
  return native;
}

Pointer<taiyin_bazi_qiyun_result> _writeQiyun(
  TaiyinBindings bindings,
  Arena arena,
  BaziQiyunResult value,
) {
  final native = arena<taiyin_bazi_qiyun_result>();
  bindings.taiyin_bazi_qiyun_result_init(native);
  native.ref
    ..direction = value.direction
    ..time_model = value.timeModel.id
    ..reference_jie_index = value.referenceJieIndex
    ..jie_interval_days = value.jieIntervalDays
    ..start_age_years = value.startAgeYears
    ..offset_years = value.offsetYears
    ..offset_months = value.offsetMonths
    ..offset_days = value.offsetDays
    ..offset_hours = value.offsetHours
    ..offset_minutes = value.offsetMinutes
    ..offset_seconds = value.offsetSeconds
    ..reference_jie_jd_ut.day_number = value.referenceJieJdUt.dayNumber
    ..reference_jie_jd_ut.day_fraction = value.referenceJieJdUt.dayFraction
    ..start_jd_ut.day_number = value.startJdUt.dayNumber
    ..start_jd_ut.day_fraction = value.startJdUt.dayFraction
    ..start_civil_time.struct_size = sizeOf<taiyin_calendar_datetime>()
    ..start_civil_time.year = value.startCivilTime.year
    ..start_civil_time.month = value.startCivilTime.month
    ..start_civil_time.day = value.startCivilTime.day
    ..start_civil_time.hour = value.startCivilTime.hour
    ..start_civil_time.minute = value.startCivilTime.minute
    ..start_civil_time.second = value.startCivilTime.fractionalSecond;
  return native;
}

BaziChart _readBaziChart(taiyin_bazi_chart value) {
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

BaziRelation _readRelation(taiyin_bazi_relation value) {
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

BaziQiyunResult _readQiyunResult(taiyin_bazi_qiyun_result value) {
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

BaziXiaoyun _readXiaoyun(taiyin_bazi_xiaoyun value) {
  return BaziXiaoyun(age: value.age, ganzhi: Ganzhi.fromNative(value.ganzhi));
}

BaziDayun _readDayun(taiyin_bazi_dayun value) {
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
  taiyin_bazi_renyuan_siling_segment value,
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
  taiyin_bazi_renyuan_siling_result value,
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
