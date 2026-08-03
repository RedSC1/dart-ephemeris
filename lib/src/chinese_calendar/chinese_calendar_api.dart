part of '../taiyin.dart';

/// Owns one native Chinese-calendar context.
///
/// Create one through [TaiyinContext.createChineseCalendar], or use
/// [TaiyinContext.chineseCalendar] for the cached default configuration.
/// Call [close] before discarding the handle; closing the owning
/// [TaiyinContext] closes its cached calendar context first.
final class TaiyinChineseCalendarContext implements Finalizable {
  TaiyinChineseCalendarContext._(
    this._bindings,
    this._context,
    this._finalizer,
  ) {
    _finalizer.attach(this, _context.cast(), detach: this);
  }

  factory TaiyinChineseCalendarContext._create(
    _TaiyinNativeLibraryState nativeState,
    TaiyinBindings bindings,
    Pointer<taiyin_context> astronomyContext,
    TaiyinChineseCalendarConfig config,
  ) {
    final context = using((arena) {
      final nativeConfig = _writeChineseCalendarConfig(bindings, arena, config);
      final output = arena<Pointer<taiyin_chinese_calendar_context>>();
      _checkStatus(
        bindings,
        bindings.taiyin_chinese_calendar_context_create(
          astronomyContext,
          nativeConfig,
          output,
        ),
      );
      return output.value;
    });
    return TaiyinChineseCalendarContext._(
      bindings,
      context,
      nativeState.chineseCalendarFinalizer,
    );
  }

  final TaiyinBindings _bindings;
  final Pointer<taiyin_chinese_calendar_context> _context;
  final NativeFinalizer _finalizer;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Releases the native calendar context. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    _finalizer.detach(this);
    _bindings.taiyin_chinese_calendar_context_destroy(_context);
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This TaiyinChineseCalendarContext has been closed.');
    }
  }

  /// Computes the full winter-solstice-based Chinese calendar year containing
  /// [jdUt].
  TaiyinEphemerisResult<TaiyinChineseCalendarYear> calcYearUt(
    JulianDate<Ut1Scale> jdUt,
  ) {
    _ensureOpen();
    return using((arena) {
      final output = arena<taiyin_chinese_calendar_year>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_chinese_calendar_year_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_chinese_calendar_calc_year_ut(
        _context,
        writeJulianDate(arena, jdUt),
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readCalendarYear(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Returns one solar term by its spring-equinox-based index (sxwnl
  /// convention): 0 = spring equinox, 18 = the winter solstice of [civilYear],
  /// 19–23 = 小寒…惊蛰 earlier in the same civil year.
  TaiyinEphemerisResult<TaiyinChineseSolarTermEvent> getSpecificJieQiUt({
    required int civilYear,
    required int termIndexFromVernalEquinox,
  }) {
    _ensureOpen();
    return using((arena) {
      final output = arena<taiyin_chinese_solar_term_event>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_chinese_solar_term_event_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_chinese_calendar_get_specific_jie_qi_ut(
        _context,
        civilYear,
        termIndexFromVernalEquinox,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readSolarTermEvent(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Returns the previous solar term at or before [jdUt].
  TaiyinEphemerisResult<TaiyinChineseSolarTermEvent> getPrevJieQiUt(
    JulianDate<Ut1Scale> jdUt,
  ) {
    return _solarTermSearch(
      (jd, output, diagnostic) =>
          _bindings.taiyin_chinese_calendar_get_prev_jie_qi_ut(
            _context,
            jd,
            output,
            diagnostic,
          ),
      jdUt,
    );
  }

  /// Returns the next solar term strictly after [jdUt].
  TaiyinEphemerisResult<TaiyinChineseSolarTermEvent> getNextJieQiUt(
    JulianDate<Ut1Scale> jdUt,
  ) {
    return _solarTermSearch(
      (jd, output, diagnostic) =>
          _bindings.taiyin_chinese_calendar_get_next_jie_qi_ut(
            _context,
            jd,
            output,
            diagnostic,
          ),
      jdUt,
    );
  }

  /// Returns the previous 节 (the twelve major terms) at or before [jdUt].
  TaiyinEphemerisResult<TaiyinChineseSolarTermEvent> getPrevJieUt(
    JulianDate<Ut1Scale> jdUt,
  ) {
    return _solarTermSearch(
      (jd, output, diagnostic) =>
          _bindings.taiyin_chinese_calendar_get_prev_jie_ut(
            _context,
            jd,
            output,
            diagnostic,
          ),
      jdUt,
    );
  }

  /// Returns the next 节 (the twelve major terms) strictly after [jdUt].
  TaiyinEphemerisResult<TaiyinChineseSolarTermEvent> getNextJieUt(
    JulianDate<Ut1Scale> jdUt,
  ) {
    return _solarTermSearch(
      (jd, output, diagnostic) =>
          _bindings.taiyin_chinese_calendar_get_next_jie_ut(
            _context,
            jd,
            output,
            diagnostic,
          ),
      jdUt,
    );
  }

  /// Returns the previous 气 (the twelve minor terms) at or before [jdUt].
  TaiyinEphemerisResult<TaiyinChineseSolarTermEvent> getPrevQiUt(
    JulianDate<Ut1Scale> jdUt,
  ) {
    return _solarTermSearch(
      (jd, output, diagnostic) =>
          _bindings.taiyin_chinese_calendar_get_prev_qi_ut(
            _context,
            jd,
            output,
            diagnostic,
          ),
      jdUt,
    );
  }

  /// Returns the next 气 (the twelve minor terms) strictly after [jdUt].
  TaiyinEphemerisResult<TaiyinChineseSolarTermEvent> getNextQiUt(
    JulianDate<Ut1Scale> jdUt,
  ) {
    return _solarTermSearch(
      (jd, output, diagnostic) =>
          _bindings.taiyin_chinese_calendar_get_next_qi_ut(
            _context,
            jd,
            output,
            diagnostic,
          ),
      jdUt,
    );
  }

  /// Converts a solar (Gregorian) date to a Chinese lunar date.
  TaiyinEphemerisResult<TaiyinLunarDate> fromSolar(TaiyinSolarDate solar) {
    _ensureOpen();
    return using((arena) {
      final nativeSolar = _writeSolarDate(_bindings, arena, solar);
      final output = arena<taiyin_lunar_date>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_lunar_date_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_chinese_calendar_from_solar(
        _context,
        nativeSolar,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readLunarDate(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Converts a Chinese lunar date to a solar (Gregorian) date.
  TaiyinEphemerisResult<TaiyinSolarDate> fromLunar(TaiyinLunarDate lunar) {
    _ensureOpen();
    return using((arena) {
      final nativeLunar = _writeLunarDate(_bindings, arena, lunar);
      final output = arena<taiyin_solar_date>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_solar_date_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_chinese_calendar_from_lunar(
        _context,
        nativeLunar,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readSolarDate(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Returns the number of days in a lunar month.
  TaiyinEphemerisResult<int> getMonthDays({
    required int lunarYear,
    required int month,
    required bool isLeap,
  }) {
    _ensureOpen();
    return using((arena) {
      final output = arena<Uint8>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_chinese_calendar_get_month_days(
        _context,
        lunarYear,
        month,
        isLeap ? 1 : 0,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: output.value,
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Computes the four pillars (四柱) for a birth instant.
  ///
  /// [instantUtc] is the real birth instant and is only compared against the
  /// absolute astronomical boundaries (立春 and the twelve 节).
  /// [virtualTime] is the caller-resolved civil clock used for the nominal
  /// year, day, and hour pillars.
  TaiyinEphemerisResult<TaiyinGanzhiFourPillars> fourPillars({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    TaiyinGanzhiRatHourMode ratHourMode = TaiyinGanzhiRatHourMode.noSplit,
  }) {
    _ensureOpen();
    return using((arena) {
      final nativeVirtualTime = writeNativeCalendar(
        _bindings,
        arena,
        virtualTime,
      );
      final output = arena<taiyin_ganzhi_four_pillars>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ganzhi_four_pillars_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_chinese_calendar_calc_four_pillars_ut(
        _context,
        writeJulianDate(arena, instantUtc),
        nativeVirtualTime,
        ratHourMode.id,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: TaiyinGanzhiFourPillars(
          year: TaiyinGanzhi.fromNative(output.ref.year),
          month: TaiyinGanzhi.fromNative(output.ref.month),
          day: TaiyinGanzhi.fromNative(output.ref.day),
          hour: TaiyinGanzhi.fromNative(output.ref.hour),
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinChineseSolarTermEvent> _solarTermSearch(
    int Function(
      Pointer<taiyin_split_julian_date>,
      Pointer<taiyin_chinese_solar_term_event>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    calculate,
    JulianDate<Ut1Scale> jdUt,
  ) {
    _ensureOpen();
    return using((arena) {
      final output = arena<taiyin_chinese_solar_term_event>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_chinese_solar_term_event_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(
        writeJulianDate(arena, jdUt),
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(_bindings, status, diagnostic: mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readSolarTermEvent(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }
}

Pointer<taiyin_chinese_calendar_config> _writeChineseCalendarConfig(
  TaiyinBindings bindings,
  Arena arena,
  TaiyinChineseCalendarConfig config,
) {
  final native = arena<taiyin_chinese_calendar_config>();
  bindings.taiyin_chinese_calendar_config_init(native);
  native.ref
    ..rule_mode = config.ruleMode.id
    ..day_boundary_mode = config.dayBoundaryMode.id
    ..utc_offset_minutes = config.utcOffsetMinutes
    ..calendar_meridian_deg = config.calendarMeridianDegrees;
  return native;
}

Pointer<taiyin_solar_date> _writeSolarDate(
  TaiyinBindings bindings,
  Arena arena,
  TaiyinSolarDate value,
) {
  final native = arena<taiyin_solar_date>();
  bindings.taiyin_solar_date_init(native);
  native.ref
    ..year = value.year
    ..month = value.month
    ..day = value.day;
  return native;
}

Pointer<taiyin_lunar_date> _writeLunarDate(
  TaiyinBindings bindings,
  Arena arena,
  TaiyinLunarDate value,
) {
  final native = arena<taiyin_lunar_date>();
  bindings.taiyin_lunar_date_init(native);
  native.ref
    ..year = value.year
    ..month = value.month
    ..day = value.day
    ..is_leap = value.isLeap ? 1 : 0
    ..month_days = value.monthDays
    ..month_name = value.monthName.id;
  return native;
}

TaiyinSolarDate _readSolarDate(taiyin_solar_date value) {
  return TaiyinSolarDate(year: value.year, month: value.month, day: value.day);
}

TaiyinLunarDate _readLunarDate(taiyin_lunar_date value) {
  return TaiyinLunarDate(
    year: value.year,
    month: value.month,
    day: value.day,
    isLeap: value.is_leap != 0,
    monthDays: value.month_days,
    monthName: TaiyinChineseCalendarMonthName.fromId(value.month_name),
  );
}

TaiyinChineseSolarTermEvent _readSolarTermEvent(
  taiyin_chinese_solar_term_event value,
) {
  return TaiyinChineseSolarTermEvent(
    indexFromWinterSolstice: value.index_from_winter_solstice,
    targetLongitudeRadians: value.target_longitude_rad,
    jdUt: readJulianDate<Ut1Scale>(value.jd_ut),
    civilDayNumber: value.civil_day_number,
  );
}

TaiyinChineseNewMoonEvent _readNewMoonEvent(
  taiyin_chinese_new_moon_event value,
) {
  return TaiyinChineseNewMoonEvent(
    jdUt: readJulianDate<Ut1Scale>(value.jd_ut),
    civilDayNumber: value.civil_day_number,
  );
}

TaiyinChineseCalendarMonth _readCalendarMonth(
  taiyin_chinese_calendar_month value,
) {
  return TaiyinChineseCalendarMonth(
    lunarYear: value.lunar_year,
    month: value.month,
    isLeap: value.is_leap != 0,
    dayCount: value.day_count,
    monthName: TaiyinChineseCalendarMonthName.fromId(value.month_name),
    firstCivilDayNumber: value.first_civil_day_number,
    astronomicalNewMoonJdUt: readJulianDate<Ut1Scale>(
      value.astronomical_new_moon_jd_ut,
    ),
  );
}

TaiyinChineseCalendarYear _readCalendarYear(
  taiyin_chinese_calendar_year value,
) {
  return TaiyinChineseCalendarYear(
    solarTerms: [
      for (var index = 0; index < value.solar_term_count; index++)
        _readSolarTermEvent(value.solar_terms[index]),
    ],
    newMoons: [
      for (var index = 0; index < value.new_moon_count; index++)
        _readNewMoonEvent(value.new_moons[index]),
    ],
    months: [
      for (var index = 0; index < value.month_count; index++)
        _readCalendarMonth(value.months[index]),
    ],
    solarTermCount: value.solar_term_count,
    newMoonCount: value.new_moon_count,
    monthCount: value.month_count,
    leapMonthIndex: value.leap_month_index,
    firstWinterSolsticeDayNumber: value.first_winter_solstice_day_number,
    secondWinterSolsticeDayNumber: value.second_winter_solstice_day_number,
  );
}
