part of 'ziwei_api.dart';

Pointer<taiyin_ziwei_chart_clock> _writeClock(Arena arena, ZiweiClock clock) {
  if (clock.mode != ZiweiClockMode.fixedOffset &&
      (!clock.longitudeRadians.isFinite ||
          clock.longitudeRadians.abs() > 3.141592653589793)) {
    throw ArgumentError.value(
      clock.longitudeRadians,
      'longitudeRadians',
      'must be finite and within [-pi, pi]',
    );
  }
  final out = arena<taiyin_ziwei_chart_clock>();
  out.ref
    ..struct_size = sizeOf<taiyin_ziwei_chart_clock>()
    ..mode = clock.mode.index
    ..longitude_rad = clock.longitudeRadians;
  return out;
}

OperationResult<T> _clockOperation<T>(
  ZiweiContext context,
  T Function(Arena, Pointer<taiyin_ephemeris_diagnostic>, void Function(int))
  action,
) {
  context._ensureOpen();
  return using((arena) {
    final diagnostic = arena<taiyin_ephemeris_diagnostic>();
    context._coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
    var flags = ResultFlags.none;
    void check(int status) {
      final mapped = context._host.readDiagnostic(diagnostic.ref);
      context._host.recordDiagnostic(mapped);
      flags |= _checkStatus(context._host, status, diagnostic: mapped);
      context._coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
    }

    final value = action(arena, diagnostic, check);
    return operationResult(value, flags);
  });
}

/// Explicit UT1 clock operations. Convert UTC with the context's time API
/// first; these methods never silently treat UTC as UT1.
extension ZiweiClockApi on ZiweiContext {
  /// Maps UT1 to the selected chart clock (without changing calendar policy).
  OperationResult<AstroDateTime> chartTimeFromUt1(
    JulianDate<Ut1Scale> instantUt1, {
    ZiweiClock clock = const ZiweiClock(),
  }) => _clockOperation(this, (arena, diagnostic, check) {
    final out = arena<taiyin_calendar_datetime>();
    out.ref.struct_size = sizeOf<taiyin_calendar_datetime>();
    check(
      _bindings.taiyin_ziwei_chart_time_from_ut1(
        _calendarHandle,
        _writeClock(arena, clock),
        writeJulianDate(arena, instantUt1),
        out,
        diagnostic,
      ),
    );
    return readCalendarDateTime(out.ref);
  });

  /// Nonlinear inverse for apparent solar time; failures throw, not fall back.
  OperationResult<JulianDate<Ut1Scale>> chartTimeToUt1(
    AstroDateTime virtualTime, {
    ZiweiClock clock = const ZiweiClock(),
  }) => _clockOperation(this, (arena, diagnostic, check) {
    final out = arena<taiyin_split_julian_date>();
    check(
      _bindings.taiyin_ziwei_chart_time_to_ut1(
        _calendarHandle,
        _writeClock(arena, clock),
        writeNativeCalendar(_coreBindings, arena, virtualTime),
        out,
        diagnostic,
      ),
    );
    return readJulianDate<Ut1Scale>(out.ref);
  });

  /// Creates a chart from one physical instant and an explicit clock policy.
  OperationResult<ZiweiChart> createChartAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    required ZiweiGender gender,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) => _clockOperation(this, (arena, diagnostic, check) {
    final out = arena<Pointer<taiyin_ziwei_chart>>();
    check(
      _bindings.taiyin_ziwei_chart_create_at_ut1(
        _context,
        _calendarHandle,
        writeJulianDate(arena, instantUt1),
        _writeClock(arena, clock),
        gender.id,
        _writeZiweiBirthOptions(_bindings, arena, options),
        out,
        diagnostic,
      ),
    );
    return ZiweiChart._(this, out.value, _chartFinalizer);
  });

  /// Preserves chart-clock minutes/seconds; split Zi advances one hour near
  /// midnight. The destination is inverted through the same solar clock.
  OperationResult<ZiweiClockTarget> stepFlowHourAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    ZiweiClock clock = const ZiweiClock(),
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    int direction = 1,
  }) {
    _requireStepDirection(direction);
    return _clockOperation(this, (arena, diagnostic, check) {
      final out = arena<taiyin_split_julian_date>();
      final time = arena<taiyin_calendar_datetime>();
      time.ref.struct_size = sizeOf<taiyin_calendar_datetime>();
      final segment = arena<Uint8>();
      check(
        _bindings.taiyin_ziwei_step_flow_hour_at_ut1(
          _calendarHandle,
          _writeClock(arena, clock),
          writeJulianDate(arena, instantUt1),
          ratHourMode.id,
          direction,
          out,
          time,
          segment,
          diagnostic,
        ),
      );
      return ZiweiClockTarget(
        instantUt1: readJulianDate<Ut1Scale>(out.ref),
        virtualTime: readCalendarDateTime(time.ref),
        ratHourSegment: ZiweiRatHourSegment.fromId(segment.value),
      );
    });
  }

  /// Moves one chart-clock day, not necessarily 86400 physical seconds.
  OperationResult<ZiweiClockTarget> stepFlowDayAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    ZiweiClock clock = const ZiweiClock(),
    int direction = 1,
  }) {
    _requireStepDirection(direction);
    return _clockOperation(this, (arena, diagnostic, check) {
      final out = arena<taiyin_split_julian_date>();
      final time = arena<taiyin_calendar_datetime>();
      time.ref.struct_size = sizeOf<taiyin_calendar_datetime>();
      check(
        _bindings.taiyin_ziwei_step_flow_day_at_ut1(
          _calendarHandle,
          _writeClock(arena, clock),
          writeJulianDate(arena, instantUt1),
          direction,
          out,
          time,
          diagnostic,
        ),
      );
      return ZiweiClockTarget(
        instantUt1: readJulianDate<Ut1Scale>(out.ref),
        virtualTime: readCalendarDateTime(time.ref),
      );
    });
  }

  /// Searches actual slot/Jie boundaries using the selected clock throughout.
  OperationResult<List<ZiweiReverseLookupUt1Candidate>>
  reverseLookupTier1AtUt1({
    required JulianDate<Ut1Scale> startInstantUt1,
    required JulianDate<Ut1Scale> endInstantUt1,
    required ZiweiGender gender,
    required ZiweiTier1ReverseQuery query,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) {
    query.validate();
    validateNativeJulianDate(startInstantUt1);
    validateNativeJulianDate(endInstantUt1);
    if (endInstantUt1.compareTo(startInstantUt1) <= 0) {
      throw ArgumentError('endInstantUt1 must be after startInstantUt1');
    }
    return _clockOperation(this, (arena, diagnostic, check) {
      final request = arena<taiyin_ziwei_reverse_request>();
      _bindings.taiyin_ziwei_reverse_request_init(request);
      request.ref
        ..start_instant_utc = writeJulianDate(arena, startInstantUt1).ref
        ..end_instant_utc = writeJulianDate(arena, endInstantUt1).ref
        ..gender = gender.id
        ..birth_options = _writeZiweiBirthOptions(
          _bindings,
          arena,
          options,
        ).ref;
      _writeZiweiReverseQueryFields(request.ref.query, query);
      final nativeClock = _writeClock(arena, clock);
      final count = arena<Size>();
      check(
        _bindings.taiyin_ziwei_reverse_lookup_tier1_at_ut1(
          _context,
          _calendarHandle,
          request,
          nativeClock,
          nullptr,
          0,
          count,
          diagnostic,
        ),
      );
      final capacity = validatedNativeArrayCount(count.value, 'Ziwei reverse');
      if (capacity == 0) return <ZiweiReverseLookupUt1Candidate>[];
      final out = arena<taiyin_ziwei_reverse_candidate>(capacity);
      for (var i = 0; i < capacity; ++i) {
        _bindings.taiyin_ziwei_reverse_candidate_init(out + i);
      }
      check(
        _bindings.taiyin_ziwei_reverse_lookup_tier1_at_ut1(
          _context,
          _calendarHandle,
          request,
          nativeClock,
          out,
          capacity,
          count,
          diagnostic,
        ),
      );
      final length = validatedNativeResultCount(count.value, capacity);
      return List.generate(length, (i) {
        final value = out[i];
        return ZiweiReverseLookupUt1Candidate(
          instantUt1: readJulianDate<Ut1Scale>(value.instant_utc),
          virtualTime: readCalendarDateTime(value.virtual_time),
          lunarYear: value.lunar_year,
          lunarMonth: value.lunar_month,
          lunarDay: value.lunar_day,
          lunarIsLeap: value.lunar_is_leap != 0,
          hourBranch: value.hour_branch,
          ratHourSegment: ZiweiRatHourSegment.fromId(value.rat_hour_segment),
        );
      }, growable: false);
    });
  }
}

/// Clock-aware flow evaluation, preserving the natal chart's original facts.
extension ZiweiChartClockApi on ZiweiChart {
  /// Replaces flow layers through [deepestLevel] using physical Jie boundaries
  /// and virtual-clock day/hour labels.
  OperationResult<ZiweiFlowResolution> setFlowAtUt1({
    required JulianDate<Ut1Scale> targetInstantUt1,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiFlowOptions options = const ZiweiFlowOptions(),
    ZiweiFlowLevel deepestLevel = ZiweiFlowLevel.hour,
  }) {
    _ensureOpen();
    return _clockOperation(_context, (arena, diagnostic, check) {
      final summary = arena<taiyin_ziwei_flow_summary>();
      _bindings.taiyin_ziwei_flow_summary_init(summary);
      check(
        _bindings.taiyin_ziwei_chart_set_flow_at_ut1(
          _context._context,
          _context._calendarHandle,
          writeJulianDate(arena, targetInstantUt1),
          _writeClock(arena, clock),
          _writeZiweiFlowOptions(_bindings, arena, options),
          deepestLevel.id,
          _chart,
          summary,
          diagnostic,
        ),
      );
      return _readZiweiFlowResolution(summary.ref);
    });
  }
}
