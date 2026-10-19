import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris/backend.dart';
import 'ziwei_models.dart';
import 'ziwei_placement_models.dart';
import 'ziwei_catalog_factory_native.dart'
    if (dart.library.js_interop) 'ziwei_catalog_factory_web.dart'
    as platform;
import 'ziwei_lifetime.dart' if (dart.library.ffi) 'dart:ffi' show Finalizable;

/// A reloadable, platform-independent rule catalog. Existing contexts retain
/// their compiled snapshot when the catalog is reloaded or closed.
abstract class ZiweiDataCatalog implements Finalizable {
  ZiweiDataCatalog.internal();
  factory ZiweiDataCatalog({
    String? profilePath,
    String? libraryPath,
    String? coreLibraryPath,
  }) => platform.createZiweiCatalog(
    profilePath: profilePath,
    libraryPath: libraryPath,
    coreLibraryPath: coreLibraryPath,
  );
  String get profilePath;
  bool get isClosed;
  int get generation;
  void reload();
  void close();
}

/// Common public contract and date/clock orchestration. Implementations below
/// this boundary call the same C++ core through FFI or the Wasm bridge.
abstract base class ZiweiContextFacade {
  ZiweiContextFacade.internal();
  CalendarContextBase get chineseCalendar;
  CalendarContextBase get _calendar => chineseCalendar;
  Time get timeService;
  void _ensureOpen() {
    if (isClosed || chineseCalendar.isClosed) {
      throw StateError('This ZiweiContext or its calendar has been closed.');
    }
  }

  /// Releases the native Ziwei context. Calling this more than once is safe.
  void close();

  /// Finds a star by catalog key, or returns null when the key is unknown.
  ZiweiStar? findStar(String key);

  /// Reads the metadata of the star with native [starId].
  ZiweiStar star(int starId);

  /// Creates a natal chart for a UTC birth instant and its local wall clock.
  ///
  /// [virtualTime] must describe the same event as [instantUtc] in the
  /// calendar context's civil time zone.
  OperationResult<ZiweiChart> createChart({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    required ZiweiGender gender,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  });

  /// Arrange a finite-input chart without inventing a birth date.
  ZiweiCastingChart createCastingChart(
    ZiweiPlacementInput input, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
    ZiweiBureau? fixedBureau,
  });

  /// Reproduce an index-v1 chart (0 <= index < 259200).
  ZiweiCastingChart castingFromIndex(
    int index, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  });

  /// Reproducible number-v1 mapping of ASCII decimal text; collisions are allowed.
  ZiweiCastingChart castingFromNumber(
    String number, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  });

  /// Draw uniformly using the operating system random source.
  ZiweiCastingChart randomCastingChart({
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  });

  /// Moves to an adjacent logical flow hour, preserving minutes and seconds.
  ///
  /// In split-Rat modes this walks Early Zi → Chou → … → Late Zi → Early Zi
  /// as thirteen slots. [direction] must be 1 (next) or -1 (previous). The
  /// returned UTC instant and local clock describe the same event.
  ZiweiFlowHourTarget stepFlowHourTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    int direction = 1,
  });

  /// Moves one local civil flow day, retaining exact wall-clock fields.
  ZiweiFlowDayTarget stepFlowDayTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    int direction = 1,
  });

  /// Finds logical birth-time slots whose selected Tier-1 stars match.
  ///
  /// The search uses this context's Chinese-calendar policy and data routes.
  /// [startVirtualTime] must describe the same event as [startInstantUtc]; it
  /// is then advanced as canonical logical hours.
  OperationResult<List<ZiweiReverseLookupCandidate>> reverseLookupTier1({
    required JulianDate<UtcScale> startInstantUtc,
    required JulianDate<UtcScale> endInstantUtc,
    required AstroDateTime startVirtualTime,
    required ZiweiGender gender,
    required ZiweiTier1ReverseQuery query,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  });
  bool get isClosed;

  /// The catalog generation this context was created from.
  int get generation;

  /// The number of stars registered in the rule catalog.
  int get starCount;

  /// Maps UT1 to the selected chart clock (without changing calendar policy).
  OperationResult<AstroDateTime> chartTimeFromUt1(
    JulianDate<Ut1Scale> instantUt1, {
    ZiweiClock clock = const ZiweiClock(),
  });

  /// Nonlinear inverse for apparent solar time; failures throw, not fall back.
  OperationResult<JulianDate<Ut1Scale>> chartTimeToUt1(
    AstroDateTime virtualTime, {
    ZiweiClock clock = const ZiweiClock(),
  });

  /// Creates a chart from one physical instant and an explicit clock policy.
  OperationResult<ZiweiChart> createChartAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    required ZiweiGender gender,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  });

  /// Preserves chart-clock minutes/seconds; split Zi advances one hour near
  /// midnight. The destination is inverted through the same solar clock.
  OperationResult<ZiweiClockTarget> stepFlowHourAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    ZiweiClock clock = const ZiweiClock(),
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    int direction = 1,
  });

  /// Moves one chart-clock day, not necessarily 86400 physical seconds.
  OperationResult<ZiweiClockTarget> stepFlowDayAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    ZiweiClock clock = const ZiweiClock(),
    int direction = 1,
  });

  /// Searches actual slot/Jie boundaries using the selected clock throughout.
  OperationResult<List<ZiweiReverseLookupUt1Candidate>>
  reverseLookupTier1AtUt1({
    required JulianDate<Ut1Scale> startInstantUt1,
    required JulianDate<Ut1Scale> endInstantUt1,
    required ZiweiGender gender,
    required ZiweiTier1ReverseQuery query,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  });

  /// Creates a natal chart from a local wall-clock birth time.
  ///
  /// The UTC instant is derived from the calendar context's fixed clock offset.
  OperationResult<ZiweiChart> calculateLocal(
    AstroDateTime localTime, {
    required ZiweiGender gender,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
    ZiweiClock clock = const ZiweiClock(),
  }) {
    _ensureOpen();
    final instant = _calendar.instantFromLocal(localTime);
    if (clock.mode != ZiweiClockMode.fixedOffset) {
      final ut1 = timeService.utcToUt1(instant.value);
      final chart = createChartAtUt1(
        instantUt1: ut1.value,
        gender: gender,
        options: options,
        clock: clock,
      );
      return operationResult(
        chart.value,
        instant.flags | ut1.flags | chart.flags,
      );
    }
    final chart = createChart(
      instantUtc: instant.value,
      virtualTime: localTime,
      gender: gender,
      options: options,
    );
    return operationResult(chart.value, instant.flags | chart.flags);
  }

  /// Creates a natal chart from a UTC birth instant.
  ///
  /// The local wall clock is derived from the calendar context's fixed clock
  /// offset.
  OperationResult<ZiweiChart> calculateInstant(
    JulianDate<UtcScale> instantUtc, {
    required ZiweiGender gender,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
    ZiweiClock clock = const ZiweiClock(),
  }) {
    _ensureOpen();
    if (clock.mode != ZiweiClockMode.fixedOffset) {
      final ut1 = timeService.utcToUt1(instantUtc);
      final chart = createChartAtUt1(
        instantUt1: ut1.value,
        gender: gender,
        options: options,
        clock: clock,
      );
      return operationResult(chart.value, ut1.flags | chart.flags);
    }
    final localTimeResult = _calendar.localTimeFromInstant(instantUtc);
    final chartResult = createChart(
      instantUtc: instantUtc,
      virtualTime: localTimeResult.value,
      gender: gender,
      options: options,
    );
    return operationResult(
      chartResult.value,
      chartResult.flags | localTimeResult.flags,
    );
  }

  /// Creates a chart from a Gregorian day and explicit local clock fields.
  OperationResult<ZiweiChart> calculateSolarDay(
    SolarDate solarDay, {
    required int hour,
    int minute = 0,
    int second = 0,
    int nanosecond = 0,
    required ZiweiGender gender,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
    ZiweiClock clock = const ZiweiClock(),
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
      options: options,
      clock: clock,
    );
  }

  /// Converts a lunar day with the bound calendar, then creates its chart.
  OperationResult<ZiweiChart> calculateLunarDay(
    LunarDate lunarDay, {
    required int hour,
    int minute = 0,
    int second = 0,
    int nanosecond = 0,
    required ZiweiGender gender,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
    ZiweiClock clock = const ZiweiClock(),
  }) {
    final solarDay = _calendar.fromLunar(lunarDay);
    final result = calculateSolarDay(
      solarDay.value,
      hour: hour,
      minute: minute,
      second: second,
      nanosecond: nanosecond,
      gender: gender,
      options: options,
      clock: clock,
    );
    return operationResult(result.value, solarDay.flags | result.flags);
  }

  /// The next logical flow hour, preserving minutes and seconds.
  ZiweiFlowHourTarget nextFlowHourTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) {
    return stepFlowHourTarget(
      instantUtc: instantUtc,
      virtualTime: virtualTime,
      ratHourMode: ratHourMode,
    );
  }

  /// The previous logical flow hour, preserving minutes and seconds.
  ZiweiFlowHourTarget previousFlowHourTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  }) {
    return stepFlowHourTarget(
      instantUtc: instantUtc,
      virtualTime: virtualTime,
      ratHourMode: ratHourMode,
      direction: -1,
    );
  }

  /// The same wall clock one local civil flow day later.
  ZiweiFlowDayTarget nextFlowDayTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
  }) {
    return stepFlowDayTarget(instantUtc: instantUtc, virtualTime: virtualTime);
  }

  /// The same wall clock one local civil flow day earlier.
  ZiweiFlowDayTarget previousFlowDayTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
  }) {
    return stepFlowDayTarget(
      instantUtc: instantUtc,
      virtualTime: virtualTime,
      direction: -1,
    );
  }
}

/// Immutable natal data with explicitly mutable flow layers. Native and Web
/// implementations own their handles below this public contract.
abstract class ZiweiChart implements Finalizable {
  ZiweiChart.internal();

  /// Return an edited natal chart, preserving original birth facts; flows clear.
  ZiweiChart modify(ZiweiPlacementPatch patch);

  /// Shift palace roles without moving physical stars. Source remains unchanged.
  ZiweiChart shiftLifePalace(int steps);

  /// Restore the original chart into a new handle, with an empty flow stack.
  ZiweiChart reset();

  /// Releases the native chart. Calling this more than once is safe.
  void close();

  /// Returns one named natal palace with its physical branch and stars.
  ZiweiPalaceState palace(ZiweiPalace palace);

  /// The physical branch (0 = Zi … 11 = Hai) a natal star occupies, or null
  /// when the star is absent from the natal chart.
  int? starPosition(int starId);

  /// The twelve-palace role a natal star resolves to, or null for flow-only
  /// or absent stars.
  int? starPalace(int starId);

  /// The brightness of a star at its natal position.
  ZiweiBrightness brightness(int starId);

  /// The stars residing in the palace at physical [branchId].
  List<ZiweiStar> palaceStars(int branchId);

  /// The raw transformation mask of a natal star; bits follow
  /// [ZiweiTransformMark.mask].
  int transformMask(int starId);

  /// Whether a natal star carries the transformation overlay [mark].
  bool hasTransform(int starId, ZiweiTransformMark mark);

  /// Replaces the chart's contiguous flow stack through [deepestLevel].
  OperationResult<ZiweiFlowResolution> setFlow({
    required JulianDate<UtcScale> targetInstantUtc,
    required AstroDateTime targetVirtualTime,
    ZiweiFlowOptions options = const ZiweiFlowOptions(),
    ZiweiFlowLevel deepestLevel = ZiweiFlowLevel.hour,
  });

  /// Drops the flow layers from [firstRemovedLevel] onward.
  void truncateFlow(ZiweiFlowLevel firstRemovedLevel);

  /// The summary of one flow layer.
  ZiweiFlowLayerSummary flowLayerSummary(ZiweiFlowLevel level);

  /// The physical branch a star occupies in flow [level], or null when the
  /// star is absent from that layer.
  int? flowStarPosition(ZiweiFlowLevel level, int starId);

  /// The stars residing in the palace at physical [branchId] of flow [level].
  List<ZiweiStar> flowPalaceStars(ZiweiFlowLevel level, int branchId);
  bool get isClosed;

  /// Current finite inputs and cumulative edits; this is not a new birth date.
  ZiweiPlacementState get placement;

  /// Missing-input records for stars not placed by the current rule set.
  List<ZiweiOmittedPlacement> get omittedPlacements;

  /// The 31 stable natal anchors, addressable by [ZiweiAnchorSlot].
  ZiweiAnchors get anchors;

  /// The natal summary: gender, bureau, masters, and transforms.
  ZiweiChartSummary get summary;

  /// The twelve natal palaces in semantic (Life through Parents) order.
  List<ZiweiPalaceState> get palaces;

  /// The number of layers currently on the flow stack.
  int get flowLayerCount;

  /// Replaces flow layers through [deepestLevel] using physical Jie boundaries
  /// and virtual-clock day/hour labels.
  OperationResult<ZiweiFlowResolution> setFlowAtUt1({
    required JulianDate<Ut1Scale> targetInstantUt1,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiFlowOptions options = const ZiweiFlowOptions(),
    ZiweiFlowLevel deepestLevel = ZiweiFlowLevel.hour,
  });
}

/// Finite-input casting chart without a fabricated birth instant.
abstract class ZiweiCastingChart implements Finalizable {
  ZiweiCastingChart.internal();

  /// Release the handle. Idempotent; also safe after the context is closed.
  void close();
  int? starPosition(int starId);
  int? starPalace(int starId);
  int transformMask(int starId);
  bool hasTransform(int starId, ZiweiTransformMark mark);
  List<ZiweiStar> palaceStars(int branch);
  ZiweiBrightness brightness(int starId);
  ZiweiCastingChart modify(ZiweiPlacementPatch patch);
  ZiweiCastingChart shiftLifePalace(int steps);
  ZiweiCastingChart reset();
  bool get isClosed;
  ZiweiCastingSummary get summary;
  List<ZiweiOmittedPlacement> get omittedPlacements;
}

/// Explicit physical UT1 chart-clock operations.
extension ZiweiClockApi on ZiweiContextFacade {
  /// Maps UT1 to the selected chart clock (without changing calendar policy).
  OperationResult<AstroDateTime> chartTimeFromUt1(
    JulianDate<Ut1Scale> instantUt1, {
    ZiweiClock clock = const ZiweiClock(),
  }) => this.chartTimeFromUt1(instantUt1, clock: clock);

  /// Nonlinear inverse for apparent solar time; failures throw, not fall back.
  OperationResult<JulianDate<Ut1Scale>> chartTimeToUt1(
    AstroDateTime virtualTime, {
    ZiweiClock clock = const ZiweiClock(),
  }) => this.chartTimeToUt1(virtualTime, clock: clock);

  /// Creates a chart from one physical instant and an explicit clock policy.
  OperationResult<ZiweiChart> createChartAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    required ZiweiGender gender,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) => this.createChartAtUt1(
    instantUt1: instantUt1,
    gender: gender,
    clock: clock,
    options: options,
  );

  /// Preserves chart-clock minutes/seconds; split Zi advances one hour near
  /// midnight. The destination is inverted through the same solar clock.
  OperationResult<ZiweiClockTarget> stepFlowHourAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    ZiweiClock clock = const ZiweiClock(),
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    int direction = 1,
  }) => this.stepFlowHourAtUt1(
    instantUt1: instantUt1,
    clock: clock,
    ratHourMode: ratHourMode,
    direction: direction,
  );

  /// Moves one chart-clock day, not necessarily 86400 physical seconds.
  OperationResult<ZiweiClockTarget> stepFlowDayAtUt1({
    required JulianDate<Ut1Scale> instantUt1,
    ZiweiClock clock = const ZiweiClock(),
    int direction = 1,
  }) => this.stepFlowDayAtUt1(
    instantUt1: instantUt1,
    clock: clock,
    direction: direction,
  );

  /// Searches actual slot/Jie boundaries using the selected clock throughout.
  OperationResult<List<ZiweiReverseLookupUt1Candidate>>
  reverseLookupTier1AtUt1({
    required JulianDate<Ut1Scale> startInstantUt1,
    required JulianDate<Ut1Scale> endInstantUt1,
    required ZiweiGender gender,
    required ZiweiTier1ReverseQuery query,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) => this.reverseLookupTier1AtUt1(
    startInstantUt1: startInstantUt1,
    endInstantUt1: endInstantUt1,
    gender: gender,
    query: query,
    clock: clock,
    options: options,
  );
}

extension ZiweiChartClockApi on ZiweiChart {
  /// Replaces flow layers through [deepestLevel] using physical Jie boundaries
  /// and virtual-clock day/hour labels.
  OperationResult<ZiweiFlowResolution> setFlowAtUt1({
    required JulianDate<Ut1Scale> targetInstantUt1,
    ZiweiClock clock = const ZiweiClock(),
    ZiweiFlowOptions options = const ZiweiFlowOptions(),
    ZiweiFlowLevel deepestLevel = ZiweiFlowLevel.hour,
  }) => this.setFlowAtUt1(
    targetInstantUt1: targetInstantUt1,
    clock: clock,
    options: options,
    deepestLevel: deepestLevel,
  );
}
