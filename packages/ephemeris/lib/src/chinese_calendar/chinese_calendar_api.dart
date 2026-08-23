part of '../taiyin.dart';

/// Owns one native Chinese-calendar context.
///
/// Create one through [EphemerisContext.createChineseCalendar], or use
/// [EphemerisContext.chineseCalendar] for the cached default configuration.
/// Call [close] before discarding the handle; closing the owning
/// [EphemerisContext] closes its cached calendar context first.
final class ChineseCalendarContext implements Finalizable {
  ChineseCalendarContext._(
    this._bindings,
    this._context,
    this._finalizer,
    this._capabilities,
    this._owner,
    this.config,
  ) {
    _finalizer.attach(this, _context.cast(), detach: this);
  }

  factory ChineseCalendarContext._create(
    _NativeLibraryState nativeState,
    TaiyinBindings bindings,
    Pointer<taiyin_context> astronomyContext,
    ChineseCalendarConfig config,
    EphemerisContext owner,
  ) {
    final context = using((arena) {
      final nativeConfig = _writeChineseCalendarConfig(bindings, arena, config);
      final output = arena<Pointer<taiyin_chinese_calendar_context>>();
      owner._completeOperation(
        bindings.taiyin_chinese_calendar_context_create(
          astronomyContext,
          nativeConfig,
          output,
        ),
      );
      return output.value;
    });
    return ChineseCalendarContext._(
      bindings,
      context,
      nativeState.chineseCalendarFinalizer,
      nativeState.capabilities,
      owner,
      config,
    );
  }

  final TaiyinBindings _bindings;
  final Pointer<taiyin_chinese_calendar_context> _context;
  final NativeFinalizer _finalizer;
  final int _capabilities;
  final EphemerisContext _owner;

  /// The configuration this calendar context was created with.
  final ChineseCalendarConfig config;
  bool _closed = false;

  bool get isClosed => _closed;

  /// The ephemeris context this calendar borrows its native astronomy state
  /// from.
  EphemerisContext get owner => _owner;

  /// FFI handle for the official extension packages (for example
  /// `package:ephemeris_ziwei`).
  TaiyinExtensionHost get extensionHost => TaiyinExtensionHost._(
    _owner._nativeState,
    _context.cast(),
    _ensureOpen,
    _owner._recordDiagnostic,
    _owner._completeOperation,
  );

  /// Releases the native calendar context. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    _owner._calendarChildren.remove(this);
    _finalizer.detach(this);
    _bindings.taiyin_chinese_calendar_context_destroy(_context);
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This ChineseCalendarContext has been closed.');
    }
    // This context borrows the owning context's native astronomy state, so it
    // must not outlive the owner.
    _owner._ensureOpen();
  }

  /// Computes the full winter-solstice-based Chinese calendar year containing
  /// [jdUt].
  OperationResult<ChineseCalendarYear> calcYearUt(JulianDate<Ut1Scale> jdUt) {
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
      final flags = _owner._completeOperation(
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(_readCalendarYear(output.ref), flags);
    });
  }

  /// Returns one solar term by its spring-equinox-based index (sxwnl
  /// convention): 0 = spring equinox, 18 = the winter solstice of [civilYear],
  /// 19–23 = 小寒…惊蛰 earlier in the same civil year.
  OperationResult<ChineseSolarTermEvent> getSpecificJieQiUt({
    required int civilYear,
    required int termIndexFromVernalEquinox,
  }) {
    _ensureOpen();
    validateNativeInt32(civilYear, 'civilYear');
    validateNativeUint8(
      termIndexFromVernalEquinox,
      'termIndexFromVernalEquinox',
    );
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
      final flags = _owner._completeOperation(
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(_readSolarTermEvent(output.ref), flags);
    });
  }

  /// Returns the previous solar term at or before [jdUt].
  OperationResult<ChineseSolarTermEvent> getPrevJieQiUt(
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
  OperationResult<ChineseSolarTermEvent> getNextJieQiUt(
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
  OperationResult<ChineseSolarTermEvent> getPrevJieUt(
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
  OperationResult<ChineseSolarTermEvent> getNextJieUt(
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
  OperationResult<ChineseSolarTermEvent> getPrevQiUt(
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
  OperationResult<ChineseSolarTermEvent> getNextQiUt(
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
  OperationResult<LunarDate> fromSolar(SolarDate solar) {
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
      final flags = _owner._completeOperation(
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(_readLunarDate(output.ref), flags);
    });
  }

  /// Converts a local civil clock to the UTC instant implied by this
  /// calendar context's day-boundary configuration.
  ///
  /// Fixed-offset calendars use [ChineseCalendarConfig.utcOffsetMinutes].
  /// Mean-solar-meridian calendars use
  /// [ChineseCalendarConfig.calendarMeridianDegrees]. No daylight-saving or
  /// IANA timezone rules are applied.
  OperationResult<JulianDate<UtcScale>> instantFromLocal(
    AstroDateTime localTime,
  ) {
    _ensureOpen();
    if (localTime.second == 60) {
      throw const UtcLeapSecondRepresentationError();
    }
    if (config.dayBoundaryMode ==
        ChineseCalendarDayBoundaryMode.meanSolarMeridian) {
      final instantUt1 = localTime.toJulianDate<Ut1Scale>().addSeconds(
        -_civilOffsetSeconds,
      );
      return _owner.time.ut1ToUtc(instantUt1);
    }
    return operationResult(
      localTime.toUtcJulianDate().addSeconds(-_civilOffsetSeconds),
      ResultFlags.none,
    );
  }

  /// Converts a UTC instant to the local civil clock implied by this calendar
  /// context's day-boundary configuration.
  OperationResult<AstroDateTime> localTimeFromInstant(
    JulianDate<UtcScale> instantUtc,
  ) {
    _ensureOpen();
    if (config.dayBoundaryMode ==
        ChineseCalendarDayBoundaryMode.meanSolarMeridian) {
      final instantUt1 = _owner.time.utcToUt1(instantUtc);
      final localClock = _owner.time.reverseJulianDay(
        instantUt1.value.addSeconds(_civilOffsetSeconds),
      );
      return operationResult(
        localClock.value,
        instantUt1.flags | localClock.flags,
      );
    }
    return _owner.time.reverseJulianDay(
      instantUtc.addSeconds(_civilOffsetSeconds),
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

  /// Resolves the Chinese lunar date containing a UT1 instant.
  OperationResult<LunarDate> fromInstantUt1(JulianDate<Ut1Scale> instant) {
    _ensureOpen();
    return using((arena) {
      final nativeInstant = writeJulianDate(arena, instant);
      final output = arena<taiyin_lunar_date>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_lunar_date_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_chinese_calendar_from_instant_ut(
        _context,
        nativeInstant,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final flags = _owner._completeOperation(
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(_readLunarDate(output.ref), flags);
    });
  }

  /// Converts a Chinese lunar date to a solar (Gregorian) date.
  OperationResult<SolarDate> fromLunar(LunarDate lunar) {
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
      final flags = _owner._completeOperation(
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(_readSolarDate(output.ref), flags);
    });
  }

  /// Returns the number of days in a lunar month.
  OperationResult<int> getMonthDays({
    required int lunarYear,
    required int month,
    required bool isLeap,
  }) {
    _ensureOpen();
    validateNativeInt32(lunarYear, 'lunarYear');
    validateNativeUint8(month, 'month');
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
      final flags = _owner._completeOperation(
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(output.value, flags);
    });
  }

  /// Computes the four pillars (四柱) for a birth instant.
  ///
  /// [instantUtc] is the real birth instant and is only compared against the
  /// absolute astronomical boundaries (立春 and the twelve 节).
  /// [virtualTime] is the caller-resolved civil clock used for the nominal
  /// year, day, and hour pillars.
  OperationResult<GanzhiFourPillars> fourPillars({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) {
    _ensureOpen();
    // four-pillars needs the Ganzhi extension; the native entry point is
    // always exported but returns UNSUPPORTED without it. Refuse up front
    // with a clear error instead of a native UNSUPPORTED status.
    if ((_capabilities & taiyinGanzhiCalendarCapability) == 0) {
      throw UnsupportedError(
        'The loaded Taiyin library does not include the Ganzhi calendar '
        'extension (build with TAIYIN_BUILD_GANZHI_CALENDAR_EXTENSION=ON), '
        'which fourPillars requires.',
      );
    }
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
      final flags = _owner._completeOperation(
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(
        GanzhiFourPillars(
          year: Ganzhi.fromNative(output.ref.year),
          month: Ganzhi.fromNative(output.ref.month),
          day: Ganzhi.fromNative(output.ref.day),
          hour: Ganzhi.fromNative(output.ref.hour),
        ),
        flags,
      );
    });
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

  double get _civilOffsetSeconds {
    if (config.dayBoundaryMode ==
        ChineseCalendarDayBoundaryMode.fixedUtcOffset) {
      return config.utcOffsetMinutes * 60.0;
    }
    return config.calendarMeridianDegrees * 240.0;
  }

  OperationResult<ChineseSolarTermEvent> _solarTermSearch(
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
      final flags = _owner._completeOperation(
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(_readSolarTermEvent(output.ref), flags);
    });
  }
}

Pointer<taiyin_chinese_calendar_config> _writeChineseCalendarConfig(
  TaiyinBindings bindings,
  Arena arena,
  ChineseCalendarConfig config,
) {
  validateNativeInt32(config.utcOffsetMinutes, 'utcOffsetMinutes');
  final native = arena<taiyin_chinese_calendar_config>();
  bindings.taiyin_chinese_calendar_config_init(native);
  native.ref
    ..mode = config.mode.id
    ..day_boundary_mode = config.dayBoundaryMode.id
    ..utc_offset_minutes = config.utcOffsetMinutes
    ..calendar_meridian_deg = config.calendarMeridianDegrees;
  return native;
}

Pointer<taiyin_solar_date> _writeSolarDate(
  TaiyinBindings bindings,
  Arena arena,
  SolarDate value,
) {
  validateNativeInt32(value.year, 'year');
  validateNativeUint8(value.month, 'month');
  validateNativeUint8(value.day, 'day');
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
  LunarDate value,
) {
  validateNativeInt32(value.year, 'year');
  validateNativeUint8(value.month, 'month');
  validateNativeUint8(value.day, 'day');
  validateNativeUint8(value.monthDays, 'monthDays');
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

SolarDate _readSolarDate(taiyin_solar_date value) {
  return SolarDate(year: value.year, month: value.month, day: value.day);
}

LunarDate _readLunarDate(taiyin_lunar_date value) {
  return LunarDate(
    year: value.year,
    month: value.month,
    day: value.day,
    isLeap: value.is_leap != 0,
    monthDays: value.month_days,
    monthName: ChineseCalendarMonthName.fromId(value.month_name),
  );
}

ChineseSolarTermEvent _readSolarTermEvent(
  taiyin_chinese_solar_term_event value,
) {
  return ChineseSolarTermEvent(
    indexFromWinterSolstice: value.index_from_winter_solstice,
    targetLongitudeRadians: value.target_longitude_rad,
    jdUt: readJulianDate<Ut1Scale>(value.jd_ut),
    civilDayNumber: value.civil_day_number,
  );
}

ChineseNewMoonEvent _readNewMoonEvent(taiyin_chinese_new_moon_event value) {
  return ChineseNewMoonEvent(
    jdUt: readJulianDate<Ut1Scale>(value.jd_ut),
    civilDayNumber: value.civil_day_number,
  );
}

ChineseCalendarMonth _readCalendarMonth(taiyin_chinese_calendar_month value) {
  return ChineseCalendarMonth(
    lunarYear: value.lunar_year,
    month: value.month,
    isLeap: value.is_leap != 0,
    dayCount: value.day_count,
    monthName: ChineseCalendarMonthName.fromId(value.month_name),
    monthBuildingBranch: value.month_building_branch,
    firstCivilDayNumber: value.first_civil_day_number,
    astronomicalNewMoonJdUt: readJulianDate<Ut1Scale>(
      value.astronomical_new_moon_jd_ut,
    ),
  );
}

ChineseCalendarYear _readCalendarYear(taiyin_chinese_calendar_year value) {
  return ChineseCalendarYear(
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
