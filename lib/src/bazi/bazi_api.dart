part of '../taiyin.dart';

/// The native "invalid five-element" sentinel (`TAIYIN_BAZI_INVALID_WUXING`).
const int _taiyinBaziInvalidWuxing = 0xff;

/// Owns one native BaZi context.
///
/// Create one through [TaiyinContext.createBazi], or use
/// [TaiyinContext.bazi] for the cached default configuration. Call [close]
/// before discarding the handle; closing the owning [TaiyinContext] closes its
/// cached BaZi context first.
final class TaiyinBaziContext implements Finalizable {
  TaiyinBaziContext._(
    this._bindings,
    this._context,
    this._finalizer,
    this._capabilities,
  ) {
    _finalizer.attach(this, _context.cast(), detach: this);
  }

  factory TaiyinBaziContext._create(
    _TaiyinNativeLibraryState nativeState,
    TaiyinBindings bindings,
    TaiyinBaziContextConfig config,
  ) {
    final finalizer = nativeState.baziFinalizer;
    if (finalizer == null) {
      throw UnsupportedError(
        'The loaded Taiyin library does not include the BaZi extension '
        '(build with TAIYIN_BUILD_BAZI_EXTENSION=ON).',
      );
    }
    final context = using((arena) {
      final nativeConfig = _writeBaziConfig(bindings, arena, config);
      final output = arena<Pointer<taiyin_bazi_context>>();
      _checkStatus(
        bindings,
        bindings.taiyin_bazi_context_create(nativeConfig, output),
      );
      return output.value;
    });
    return TaiyinBaziContext._(
      bindings,
      context,
      finalizer,
      nativeState.capabilities,
    );
  }

  final TaiyinBindings _bindings;
  final Pointer<taiyin_bazi_context> _context;
  final NativeFinalizer _finalizer;
  final int _capabilities;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Releases the native BaZi context. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    _finalizer.detach(this);
    _bindings.taiyin_bazi_context_destroy(_context);
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This TaiyinBaziContext has been closed.');
    }
  }

  void _requireBazi() {
    if ((_capabilities & taiyinBaziCapability) == 0) {
      throw UnsupportedError(
        'The loaded Taiyin library does not include the BaZi extension '
        '(build with TAIYIN_BUILD_BAZI_EXTENSION=ON).',
      );
    }
  }

  /// Returns the 空亡 (kong-wang) branches for a Ganzhi value.
  ({TaiyinEarthlyBranch a, TaiyinEarthlyBranch b}) getKongWang(
    TaiyinGanzhi value,
  ) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final output = arena<Uint8>(2);
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_get_kong_wang(value.raw, output),
      );
      return (
        a: TaiyinEarthlyBranch.fromId(output[0]),
        b: TaiyinEarthlyBranch.fromId(output[1]),
      );
    });
  }

  /// Returns the 十神 (ten god) of a stem relative to the day stem.
  TaiyinBaziTenGod getTenGod({
    required int dayStemId,
    required int targetStemId,
  }) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_get_ten_god(dayStemId, targetStemId, output),
      );
      return TaiyinBaziTenGod.fromId(output.value);
    });
  }

  /// Returns the 藏干 (hidden stems) of an earthly branch.
  ({List<int> stems, int count}) getHiddenStems(int branchId) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final output = arena<Uint8>(3);
      final count = arena<Uint8>();
      _checkStatus(
        _bindings,
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
  TaiyinBaziStemRelationResult calcStemRelation(int stemA, int stemB) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final flags = arena<Uint32>();
      final combinedElement = arena<Uint8>();
      _checkStatus(
        _bindings,
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
  TaiyinBaziBranchRelationResult calcBranchRelation(int branchA, int branchB) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final flags = arena<Uint32>();
      final combinedElement = arena<Uint8>();
      _checkStatus(
        _bindings,
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
  TaiyinBaziBranchTripleRelationResult calcBranchTripleRelation(
    int branchA,
    int branchB,
    int branchC,
  ) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final flags = arena<Uint32>();
      final combinedElement = arena<Uint8>();
      _checkStatus(
        _bindings,
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
    TaiyinBaziEarthPalaceMode mode = TaiyinBaziEarthPalaceMode.fireEarth,
  }) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_get_life_stage(stemId, branchId, mode.id, output),
      );
      return output.value;
    });
  }

  /// Calculates the 流年 (liu-nian / flow-year) Ganzhi for an effective year.
  TaiyinGanzhi calcLiunian(int effectiveYear) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_calc_liunian(effectiveYear, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Calculates the 流月 (liu-yue / flow-month) Ganzhi.
  ///
  /// [monthBranch] follows the C ABI: 2 = 寅, …, 0 = 子, 1 = 丑.
  TaiyinGanzhi calcLiuyue(TaiyinGanzhi yearPillar, int monthBranch) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_calc_liuyue(yearPillar.raw, monthBranch, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Calculates the 流日 (liu-ri / flow-day) Ganzhi for a civil date.
  TaiyinGanzhi calcLiuri(AstroDateTime civilDate) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, civilDate);
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_calc_liuri(calendar, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Calculates the 流时 (liu-shi / flow-hour) Ganzhi.
  ///
  /// [hourIndex] follows the C ABI branch sequence: 0 = 子, …, 11 = 亥.
  TaiyinGanzhi calcLiushi(TaiyinGanzhi dayPillar, int hourIndex) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_calc_liushi(dayPillar.raw, hourIndex, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Calculates the 小运 (xiao-yun) Ganzhi for an age within a chart.
  TaiyinGanzhi calcXiaoyun(TaiyinBaziChart chart, int direction, int age) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final nativeChart = _writeBaziChart(_bindings, arena, chart);
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_calc_xiaoyun(nativeChart, direction, age, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Fills a contiguous range of 小运 (xiao-yun) entries starting at
  /// [startAge] (one-based virtual ages).
  List<TaiyinBaziXiaoyun> fillXiaoyun({
    required TaiyinBaziChart chart,
    required int direction,
    required int startAge,
    required int requestedCount,
  }) {
    _ensureOpen();
    _requireBazi();
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
      _checkStatus(_bindings, countStatus);
      final requiredCount = _validatedArrayCount(count.value, 'BaZi xiao-yun');
      if (requiredCount == 0) {
        return const <TaiyinBaziXiaoyun>[];
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
      _checkStatus(_bindings, fillStatus);
      final resultCount = _validatedArrayCount(count.value, 'BaZi xiao-yun');
      return List.unmodifiable([
        for (var index = 0; index < resultCount; index++)
          _readXiaoyun((output + index).ref),
      ]);
    });
  }

  /// Derives the full 八字 chart (命宫/身宫/胎元/胎息/藏干/十神/大运十二宫) from
  /// the four pillars.
  TaiyinBaziChart calcChart(TaiyinGanzhiFourPillars pillars) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final nativePillars = _writeFourPillars(_bindings, arena, pillars);
      final output = arena<taiyin_bazi_chart>();
      _bindings.taiyin_bazi_chart_init(output);
      _checkStatus(
        _bindings,
        _bindings.taiyin_bazi_calc_chart(_context, nativePillars, output),
      );
      return _readBaziChart(output.ref);
    });
  }

  /// Computes the 起运 (qi-yun) start of the first 大运 for a birth instant.
  ///
  /// [calendar] supplies the astronomical solar-term context used by the
  /// native BaZi module.
  TaiyinEphemerisResult<TaiyinBaziQiyunResult> calcQiyun({
    required JulianDate<Ut1Scale> birthJdUt,
    required AstroDateTime birthCivilTime,
    required TaiyinBaziChart chart,
    required TaiyinBaziGender gender,
    required TaiyinChineseCalendarContext calendar,
  }) {
    _ensureOpen();
    _requireBazi();
    calendar._ensureOpen();
    return using((arena) {
      final output = arena<taiyin_bazi_qiyun_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_bazi_qiyun_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_bazi_calc_qiyun(
        _context,
        calendar._context,
        writeJulianDate(arena, birthJdUt),
        writeNativeCalendar(_bindings, arena, birthCivilTime),
        _writeBaziChart(_bindings, arena, chart),
        gender.id,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readQiyunResult(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Fills the 大运 (da-yun) decades following a 起运 result.
  ///
  /// [requestedCount] is the number of one-based da-yun entries to generate.
  List<TaiyinBaziDayun> fillDayun({
    required AstroDateTime birthCivilTime,
    required TaiyinBaziChart chart,
    required TaiyinBaziQiyunResult qiyun,
    required int requestedCount,
  }) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final birthCivil = writeNativeCalendar(_bindings, arena, birthCivilTime);
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
      _checkStatus(_bindings, countStatus);
      final requiredCount = _validatedArrayCount(count.value, 'BaZi da-yun');
      if (requiredCount == 0) {
        return const <TaiyinBaziDayun>[];
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
      _checkStatus(_bindings, fillStatus);
      final resultCount = _validatedResultCount(count.value, requiredCount);
      return List.unmodifiable([
        for (var index = 0; index < resultCount; index++)
          _readDayun((output + index).ref),
      ]);
    });
  }

  /// Determines the 人元司令 (ren-yuan si-ling) in effect at an instant.
  ///
  /// [calendar] supplies the astronomical solar-term context used by the
  /// native BaZi module.
  TaiyinEphemerisResult<TaiyinBaziRenyuanSilingResult> calcRenyuanSiling({
    required JulianDate<Ut1Scale> instantJdUt,
    required TaiyinBaziChart chart,
    required TaiyinBaziRenyuanSilingTableModel tableModel,
    required TaiyinBaziRenyuanSilingTimeModel timeModel,
    required TaiyinChineseCalendarContext calendar,
  }) {
    _ensureOpen();
    _requireBazi();
    calendar._ensureOpen();
    return using((arena) {
      final output = arena<taiyin_bazi_renyuan_siling_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_bazi_renyuan_siling_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_bazi_calc_renyuan_siling(
        calendar._context,
        writeJulianDate(arena, instantJdUt),
        _writeBaziChart(_bindings, arena, chart),
        tableModel.id,
        timeModel.id,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readRenyuanSilingResult(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Returns the 人元司令 (ren-yuan si-ling) command segments of a month branch.
  List<TaiyinBaziRenyuanSilingSegment> getRenyuanSilingSegments(
    int monthBranchId,
    TaiyinBaziRenyuanSilingTableModel tableModel,
  ) {
    _ensureOpen();
    _requireBazi();
    return using((arena) {
      final count = arena<Size>();
      final countStatus = _bindings.taiyin_bazi_get_renyuan_siling_segments(
        monthBranchId,
        tableModel.id,
        nullptr,
        0,
        count,
      );
      _checkStatus(_bindings, countStatus);
      final requiredCount = _validatedArrayCount(
        count.value,
        'BaZi renyuan siling segments',
      );
      if (requiredCount == 0) {
        return const <TaiyinBaziRenyuanSilingSegment>[];
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
      _checkStatus(_bindings, fillStatus);
      final resultCount = _validatedResultCount(count.value, requiredCount);
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
  List<TaiyinBaziRelation> collectChartRelations({
    required TaiyinBaziChart chart,
    int pillarMask = 0xff,
    int relationMask = 0xffff,
  }) {
    _ensureOpen();
    _requireBazi();
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
      _checkStatus(_bindings, countStatus);
      final requiredCount = _validatedArrayCount(
        count.value,
        'BaZi chart relations',
      );
      if (requiredCount == 0) {
        return const <TaiyinBaziRelation>[];
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
      _checkStatus(_bindings, fillStatus);
      final resultCount = _validatedResultCount(count.value, requiredCount);
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
  Set<TaiyinBaziShenShaId> collectTargetShenSha({
    required TaiyinBaziChart chart,
    required TaiyinGanzhi target,
    required TaiyinBaziShenShaTargetKind targetKind,
    TaiyinBaziGender? gender,
  }) {
    _ensureOpen();
    _requireBazi();
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
      _checkStatus(_bindings, status);
      final count = wordCount.value;
      if (count < 1 || count > wordCapacity) {
        throw StateError(
          'Native BaZi shen-sha collection returned word count=$count '
          'outside 1..$wordCapacity',
        );
      }
      final result = <TaiyinBaziShenShaId>{};
      for (var wordIndex = 0; wordIndex < count; wordIndex++) {
        final word = words[wordIndex];
        for (var bit = 0; bit < 64; bit++) {
          if ((word & (1 << bit)) == 0) continue;
          final id = wordIndex * 64 + bit;
          if (id < 66) {
            result.add(TaiyinBaziShenShaId.fromId(id));
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
  TaiyinBaziContextConfig config,
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
  TaiyinGanzhiFourPillars value,
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
  TaiyinBaziChart value,
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
  TaiyinBaziQiyunResult value,
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

TaiyinBaziChart _readBaziChart(taiyin_bazi_chart value) {
  return TaiyinBaziChart(
    yearPillar: TaiyinGanzhi.fromNative(value.year_pillar),
    monthPillar: TaiyinGanzhi.fromNative(value.month_pillar),
    dayPillar: TaiyinGanzhi.fromNative(value.day_pillar),
    hourPillar: TaiyinGanzhi.fromNative(value.hour_pillar),
    mingGong: TaiyinGanzhi.fromNative(value.ming_gong),
    shenGong: TaiyinGanzhi.fromNative(value.shen_gong),
    taiYuan: TaiyinGanzhi.fromNative(value.tai_yuan),
    taiXi: TaiyinGanzhi.fromNative(value.tai_xi),
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

TaiyinBaziRelation _readRelation(taiyin_bazi_relation value) {
  return TaiyinBaziRelation(
    kind: TaiyinBaziRelationKind.fromId(value.kind),
    pillarMask: TaiyinBaziRelationPillarFlags.fold(value.pillar_mask),
    combinedElementId: value.combined_element_id == _taiyinBaziInvalidWuxing
        ? null
        : TaiyinBaziWuxing.fromId(value.combined_element_id),
  );
}

TaiyinBaziStemRelationResult _readStemRelation(
  int flags,
  int combinedElementId,
) {
  return TaiyinBaziStemRelationResult(
    flags: TaiyinBaziStemRelationFlags.fold(flags),
    combinedElementId: combinedElementId == _taiyinBaziInvalidWuxing
        ? null
        : TaiyinBaziWuxing.fromId(combinedElementId),
  );
}

TaiyinBaziBranchRelationResult _readBranchRelation(
  int flags,
  int combinedElementId,
) {
  return TaiyinBaziBranchRelationResult(
    flags: TaiyinBaziBranchRelationFlags.fold(flags),
    combinedElementId: combinedElementId == _taiyinBaziInvalidWuxing
        ? null
        : TaiyinBaziWuxing.fromId(combinedElementId),
  );
}

TaiyinBaziBranchTripleRelationResult _readBranchTripleRelation(
  int flags,
  int combinedElementId,
) {
  return TaiyinBaziBranchTripleRelationResult(
    flags: TaiyinBaziBranchTripleRelationFlags.fold(flags),
    combinedElementId: combinedElementId == _taiyinBaziInvalidWuxing
        ? null
        : TaiyinBaziWuxing.fromId(combinedElementId),
  );
}

TaiyinBaziQiyunResult _readQiyunResult(taiyin_bazi_qiyun_result value) {
  return TaiyinBaziQiyunResult(
    direction: value.direction,
    timeModel: TaiyinBaziQiyunTimeModel.fromId(value.time_model),
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
    startCivilTime: _readCalendarDateTime(value.start_civil_time),
  );
}

TaiyinBaziXiaoyun _readXiaoyun(taiyin_bazi_xiaoyun value) {
  return TaiyinBaziXiaoyun(
    age: value.age,
    ganzhi: TaiyinGanzhi.fromNative(value.ganzhi),
  );
}

TaiyinBaziDayun _readDayun(taiyin_bazi_dayun value) {
  return TaiyinBaziDayun(
    index: value.index,
    ganzhi: TaiyinGanzhi.fromNative(value.ganzhi),
    startVirtualAge: value.start_virtual_age,
    endVirtualAge: value.end_virtual_age,
    startJdUt: readJulianDate<Ut1Scale>(value.start_jd_ut),
    endJdUt: readJulianDate<Ut1Scale>(value.end_jd_ut),
    startCivilTime: _readCalendarDateTime(value.start_civil_time),
    endCivilTime: _readCalendarDateTime(value.end_civil_time),
  );
}

TaiyinBaziRenyuanSilingSegment _readRenyuanSilingSegment(
  taiyin_bazi_renyuan_siling_segment value,
) {
  return TaiyinBaziRenyuanSilingSegment(
    stemId: value.stem_id,
    originKind: TaiyinBaziRenyuanSilingOriginKind.fromId(value.origin_kind),
    segmentIndex: value.segment_index,
    startDay: value.start_day,
    endDay: value.end_day,
  );
}

TaiyinBaziRenyuanSilingResult _readRenyuanSilingResult(
  taiyin_bazi_renyuan_siling_result value,
) {
  return TaiyinBaziRenyuanSilingResult(
    tableModel: TaiyinBaziRenyuanSilingTableModel.fromId(value.table_model),
    timeModel: TaiyinBaziRenyuanSilingTimeModel.fromId(value.time_model),
    monthBranchId: value.month_branch_id,
    stemId: value.stem_id,
    originKind: TaiyinBaziRenyuanSilingOriginKind.fromId(value.origin_kind),
    segmentIndex: value.segment_index,
    previousJieIndex: value.previous_jie_index,
    daysSinceJie: value.days_since_jie,
    segmentStartDay: value.segment_start_day,
    segmentEndDay: value.segment_end_day,
    previousJieJdUt: readJulianDate<Ut1Scale>(value.previous_jie_jd_ut),
  );
}

/// Converts a native calendar struct into an [AstroDateTime] using the same
/// second rounding the time API applies to `reverseJulianDay`.
AstroDateTime _readCalendarDateTime(taiyin_calendar_datetime value) {
  final minute = AstroDateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
  );
  return minute.addNanoseconds(
    (value.second * Duration.microsecondsPerSecond * 1000).round(),
  );
}

int _validatedArrayCount(int count, String noun) {
  if (count < 0) {
    throw StateError('Native $noun returned a negative count');
  }
  return count;
}

int _validatedResultCount(int count, int capacity) {
  if (count < 0 || count > capacity) {
    throw StateError(
      'Native array fill returned count=$count outside 0..$capacity',
    );
  }
  return count;
}
