import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:ephemeris/ffi.dart';
import 'package:ephemeris/ephemeris.dart';

import 'ziwei_models.dart';

part 'ziwei_placement.dart';

/// The native invalid-star-id sentinel (`TAIYIN_ZIWEI_INVALID_STAR_ID`).
const int _taiyinZiweiInvalidStarId = 0xffff;

/// The native invalid-position sentinel (`TAIYIN_ZIWEI_INVALID_POSITION`).
const int _taiyinZiweiInvalidPosition = 0xff;

/// The core invalid-argument status used by `find_star` for a missing key.
const int _taiyinErrorInvalidArgument = -1;

/// Package hosting the bundled default Ziwei rule profile.
const String _ziweiRulePackage = 'ephemeris_ziwei';

TaiyinExtensionModule _openZiweiModule([String? libraryPath]) =>
    TaiyinExtensionModule.open(
      packageName: _ziweiRulePackage,
      environmentVariable: 'TAIYIN_ZIWEI_LIBRARY_PATH',
      libraryBaseName: 'taiyin_ziwei',
      identitySymbol: 'taiyin_ziwei_context_destroy',
      requiredSymbols: taiyinZiweiSymbols,
      libraryPath: libraryPath,
    );

ResultFlags _checkStatus(
  TaiyinExtensionHost host,
  int rawResult, {
  EphemerisDiagnostic? diagnostic,
}) => host.checkStatus(rawResult, diagnostic: diagnostic);

final Expando<ZiweiContext> _ziweiCache = Expando<ZiweiContext>('taiyin_ziwei');

/// Ziwei entry points attached to an [EphemerisContext].
extension ZiweiExtension on EphemerisContext {
  /// A Ziwei context using the cached default Chinese-calendar context, the
  /// bundled default rule catalog, and the profile-default option selection.
  ///
  /// The first access creates and caches the native context; a cached entry
  /// closed by the caller is replaced on the next access.
  ZiweiContext get ziwei {
    final cached = _ziweiCache[this];
    if (cached != null &&
        !cached.isClosed &&
        !cached.chineseCalendar.isClosed) {
      return cached;
    }
    final created = createZiwei();
    _ziweiCache[this] = created;
    return created;
  }

  /// Creates an independent Ziwei context owned by the caller.
  ///
  /// [calendar] defaults to the cached default Chinese-calendar context and
  /// is borrowed, not owned; it must have been created by this same
  /// [EphemerisContext]. [catalog] defaults to the bundled default rule
  /// profile; a catalog created implicitly is released by
  /// [ZiweiContext.close], while a caller-supplied catalog stays owned by the
  /// caller. [libraryPath] overrides the bundled Ziwei native module when no
  /// caller-supplied [catalog] selects one already.
  ZiweiContext createZiwei({
    ChineseCalendarContext? calendar,
    ZiweiDataCatalog? catalog,
    ZiweiOptionSelection selection = const ZiweiOptionSelection(),
    ZiweiRuleset ruleset = const ZiweiRuleset(),
    String? libraryPath,
  }) {
    if (catalog != null && libraryPath != null) {
      throw ArgumentError(
        'libraryPath cannot be combined with a caller-supplied catalog; '
        'the catalog already selects its Ziwei native module.',
      );
    }
    extensionHost.ensureOpen();
    final effectiveCalendar = calendar ?? chineseCalendar;
    if (!identical(effectiveCalendar.owner, this)) {
      throw ArgumentError.value(
        calendar,
        'calendar',
        'must belong to this EphemerisContext',
      );
    }
    effectiveCalendar.extensionHost.ensureOpen();
    return ZiweiContext._create(
      effectiveCalendar.extensionHost,
      catalog?._module ?? _openZiweiModule(libraryPath),
      effectiveCalendar,
      catalog: catalog,
      selection: selection,
      ruleset: ruleset,
    );
  }
}

/// Owns one reloadable native Ziwei rule catalog.
///
/// Create one through the default constructor, optionally sharing it across
/// several [ZiweiContext] instances. Call [close] before discarding the
/// handle; a catalog passed to a context stays owned by the caller.
final class ZiweiDataCatalog implements Finalizable {
  ZiweiDataCatalog._(
    this._host,
    this._module,
    this._catalog,
    this._finalizer,
    this.profilePath,
  ) {
    _finalizer.attach(this, _catalog.cast(), detach: this);
  }

  /// Loads the TOML rule profile at [profilePath], or the bundled default
  /// profile when omitted.
  ///
  /// [libraryPath] selects the Ziwei module. [coreLibraryPath] optionally
  /// selects the core module used for status metadata; catalog loading itself
  /// does not initialize the process-wide astronomy runtime.
  factory ZiweiDataCatalog({
    String? profilePath,
    String? libraryPath,
    String? coreLibraryPath,
  }) {
    return ZiweiDataCatalog._create(
      TaiyinExtensionHost.open(libraryPath: coreLibraryPath),
      _openZiweiModule(libraryPath),
      profilePath,
    );
  }

  factory ZiweiDataCatalog._create(
    TaiyinExtensionHost host,
    TaiyinExtensionModule module,
    String? profilePath,
  ) {
    final finalizer = module.finalizerFor('taiyin_ziwei_data_catalog_destroy');
    final bindings = module.bindings;
    final resolvedPath = profilePath ?? _defaultZiweiProfilePath();
    _requireZiweiPath(resolvedPath);
    final catalog = using((arena) {
      final output = arena<Pointer<taiyin_ziwei_data_catalog>>();
      _checkStatus(
        host,
        bindings.taiyin_ziwei_data_catalog_create(
          resolvedPath.toNativeUtf8(allocator: arena).cast(),
          output,
        ),
      );
      return output.value;
    });
    return ZiweiDataCatalog._(host, module, catalog, finalizer, resolvedPath);
  }

  final TaiyinExtensionHost _host;
  final TaiyinExtensionModule _module;
  final Pointer<taiyin_ziwei_data_catalog> _catalog;
  final NativeFinalizer _finalizer;

  TaiyinBindings get _bindings => _module.bindings;

  /// The TOML profile this catalog was loaded from.
  final String profilePath;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Releases the native catalog. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    _finalizer.detach(this);
    _bindings.taiyin_ziwei_data_catalog_destroy(_catalog);
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This ZiweiDataCatalog has been closed.');
    }
  }

  /// Reloads the TOML profile from disk, advancing [generation].
  void reload() {
    _ensureOpen();
    _checkStatus(_host, _bindings.taiyin_ziwei_data_catalog_reload(_catalog));
  }

  /// The catalog snapshot generation, incremented by [reload].
  int get generation {
    _ensureOpen();
    return _bindings.taiyin_ziwei_data_catalog_generation(_catalog);
  }
}

/// Ziwei calculations that share one Taiyin Chinese-calendar context.
///
/// The context borrows [chineseCalendar]; closing the calendar (or its owning
/// [EphemerisContext]) invalidates this context. A catalog created implicitly
/// is owned by the context and released by [close]; a catalog passed to
/// [ZiweiExtension.createZiwei] stays owned by the caller.
final class ZiweiContext implements Finalizable {
  ZiweiContext._(
    this._host,
    this._module,
    this._context,
    this._finalizer,
    this._calendar,
    this._ownedCatalog,
  ) {
    _finalizer.attach(this, _context.cast(), detach: this);
  }

  factory ZiweiContext._create(
    TaiyinExtensionHost host,
    TaiyinExtensionModule module,
    ChineseCalendarContext calendar, {
    ZiweiDataCatalog? catalog,
    ZiweiOptionSelection selection = const ZiweiOptionSelection(),
    ZiweiRuleset ruleset = const ZiweiRuleset(),
  }) {
    host.ensureOpen();
    _validateZiweiOptionSelection(selection);
    _validateZiweiRuleset(ruleset);
    final finalizer = module.finalizerFor('taiyin_ziwei_context_destroy');
    final bindings = module.bindings;
    final ownedCatalog = catalog == null
        ? ZiweiDataCatalog._create(host, module, null)
        : null;
    final effectiveCatalog = catalog ?? ownedCatalog!;
    try {
      effectiveCatalog._ensureOpen();
      final context = using((arena) {
        final overrides = _writeZiweiOptionOverrides(
          bindings,
          arena,
          selection,
        );
        final output = arena<Pointer<taiyin_ziwei_context>>();
        Pointer<taiyin_ziwei_ruleset> nativeRuleset = nullptr;
        try {
          if (ruleset.modules.isNotEmpty) {
            final rulesetOutput = arena<Pointer<taiyin_ziwei_ruleset>>();
            _checkStatus(
              host,
              bindings.taiyin_ziwei_ruleset_create(rulesetOutput),
            );
            nativeRuleset = rulesetOutput.value;
            for (final module in ruleset.modules) {
              _checkStatus(
                host,
                bindings.taiyin_ziwei_ruleset_add_json_module(
                  nativeRuleset,
                  _writeZiweiJsonRuleModule(bindings, arena, module),
                ),
              );
            }
          }
          final status = nativeRuleset == nullptr
              ? bindings.taiyin_ziwei_context_create(
                  effectiveCatalog._catalog,
                  overrides.pointer,
                  overrides.count,
                  output,
                )
              : bindings.taiyin_ziwei_context_create_with_ruleset(
                  effectiveCatalog._catalog,
                  overrides.pointer,
                  overrides.count,
                  nativeRuleset,
                  output,
                );
          _checkStatus(host, status);
        } finally {
          if (nativeRuleset != nullptr) {
            bindings.taiyin_ziwei_ruleset_destroy(nativeRuleset);
          }
        }
        return output.value;
      });
      return ZiweiContext._(
        host,
        module,
        context,
        finalizer,
        calendar,
        ownedCatalog,
      );
    } catch (_) {
      ownedCatalog?.close();
      rethrow;
    }
  }

  final TaiyinExtensionHost _host;
  final TaiyinExtensionModule _module;
  final Pointer<taiyin_ziwei_context> _context;
  final NativeFinalizer _finalizer;
  final ChineseCalendarContext _calendar;
  final ZiweiDataCatalog? _ownedCatalog;
  bool _closed = false;

  TaiyinBindings get _bindings => _module.bindings;
  TaiyinBindings get _coreBindings => _host.bindings;

  /// The calendar context this Ziwei context resolves birth facts through.
  ChineseCalendarContext get chineseCalendar => _calendar;

  bool get isClosed => _closed;

  /// Releases the native Ziwei context. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    _finalizer.detach(this);
    _bindings.taiyin_ziwei_context_destroy(_context);
    _ownedCatalog?.close();
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This ZiweiContext has been closed.');
    }
    // The host is the calendar's extension host, so this also verifies the
    // borrowed calendar (and its owner) is still open.
    _host.ensureOpen();
  }

  Pointer<taiyin_chinese_calendar_context> get _calendarHandle =>
      _host.nativeHandle<taiyin_chinese_calendar_context>();

  /// The catalog generation this context was created from.
  int get generation {
    _ensureOpen();
    return _bindings.taiyin_ziwei_context_generation(_context);
  }

  /// The number of stars registered in the rule catalog.
  int get starCount {
    _ensureOpen();
    return _bindings.taiyin_ziwei_star_count(_context);
  }

  /// Finds a star by catalog key, or returns null when the key is unknown.
  ZiweiStar? findStar(String key) {
    _ensureOpen();
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', 'must not be empty');
    }
    if (key.contains('\u0000')) {
      throw ArgumentError.value(key, 'key', 'must not contain a NUL character');
    }
    return using((arena) {
      final output = arena<Uint16>();
      final status = _bindings.taiyin_ziwei_find_star(
        _context,
        key.toNativeUtf8(allocator: arena).cast(),
        output,
      );
      final decoded = decodeNativeCallResult(status);
      if (decoded.status == _taiyinErrorInvalidArgument &&
          output.value == _taiyinZiweiInvalidStarId) {
        return null;
      }
      _checkStatus(_host, status);
      if (output.value == _taiyinZiweiInvalidStarId) return null;
      return star(output.value);
    });
  }

  /// Reads the metadata of the star with native [starId].
  ZiweiStar star(int starId) {
    _ensureOpen();
    _requireStarId(starId);
    return using((arena) {
      final category = arena<Int32>();
      final requiredSize = arena<Size>();
      _checkStatus(
        _host,
        _bindings.taiyin_ziwei_get_star_metadata(
          _context,
          starId,
          category,
          nullptr,
          0,
          requiredSize,
        ),
      );
      final buffer = arena<Char>(requiredSize.value);
      _checkStatus(
        _host,
        _bindings.taiyin_ziwei_get_star_metadata(
          _context,
          starId,
          category,
          buffer,
          requiredSize.value,
          requiredSize,
        ),
      );
      final isNatal = arena<Uint8>();
      _checkStatus(
        _host,
        _bindings.taiyin_ziwei_star_is_natal(_context, starId, isNatal),
      );
      return ZiweiStar(
        id: starId,
        key: buffer.cast<Utf8>().toDartString(),
        category: ZiweiStarCategory.fromId(category.value),
        isNatal: isNatal.value != 0,
      );
    });
  }

  void _requireStarId(int starId) {
    validateNativeUint16(starId, 'starId');
    final count = _bindings.taiyin_ziwei_star_count(_context);
    if (starId < 0 || starId >= count) {
      throw ArgumentError.value(
        starId,
        'starId',
        'must identify a registered star in the range 0 through ${count - 1}',
      );
    }
  }

  /// Creates a natal chart for a UTC birth instant and its local wall clock.
  ///
  /// [virtualTime] must describe the same event as [instantUtc] in the
  /// calendar context's civil time zone.
  OperationResult<ZiweiChart> createChart({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    required ZiweiGender gender,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) {
    _ensureOpen();
    return using((arena) {
      final nativeOptions = _writeZiweiBirthOptions(_bindings, arena, options);
      final output = arena<Pointer<taiyin_ziwei_chart>>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_ziwei_chart_create(
        _context,
        _calendarHandle,
        writeJulianDate(arena, instantUtc),
        writeNativeCalendar(_coreBindings, arena, virtualTime),
        gender.id,
        nativeOptions,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _host.readDiagnostic(diagnostic.ref);
      _host.recordDiagnostic(mappedDiagnostic);
      final flags = _checkStatus(_host, status, diagnostic: mappedDiagnostic);
      return operationResult(
        ZiweiChart._(this, output.value, _chartFinalizer),
        flags,
      );
    });
  }

  NativeFinalizer get _chartFinalizer {
    return _module.finalizerFor('taiyin_ziwei_chart_destroy');
  }

  /// Arrange a finite-input chart without inventing a birth date.
  ZiweiCastingChart createCastingChart(
    ZiweiPlacementInput input, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
    ZiweiBureau? fixedBureau,
  }) => _createCasting(this, 0, input, gender, chartMode, fixedBureau);

  /// Reproduce an index-v1 chart (0 <= index < 259200).
  ZiweiCastingChart castingFromIndex(
    int index, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  }) => _createCasting(this, 1, index, gender, chartMode, null);

  /// Reproducible number-v1 mapping of ASCII decimal text; collisions are allowed.
  ZiweiCastingChart castingFromNumber(
    String number, {
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  }) => _createCasting(this, 2, number, gender, chartMode, null);

  /// Draw uniformly using the operating system random source.
  ZiweiCastingChart randomCastingChart({
    required ZiweiGender gender,
    ZiweiChartMode chartMode = ZiweiChartMode.tianPan,
  }) => _createCasting(this, 3, null, gender, chartMode, null);

  /// Creates a natal chart from a local wall-clock birth time.
  ///
  /// The UTC instant is derived from the calendar context's fixed clock offset.
  OperationResult<ZiweiChart> calculateLocal(
    AstroDateTime localTime, {
    required ZiweiGender gender,
    ZiweiBirthOptions options = const ZiweiBirthOptions(),
  }) {
    _ensureOpen();
    final instant = _calendar.instantFromLocal(localTime);
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
  }) {
    _ensureOpen();
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

  /// Moves to the canonical center of an adjacent logical flow hour.
  ///
  /// In split-Rat modes this walks Early Zi → Chou → … → Late Zi → Early Zi
  /// as thirteen slots. [direction] must be 1 (next) or -1 (previous). The
  /// returned UTC instant and local clock describe the same event.
  ZiweiFlowHourTarget stepFlowHourTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
    int direction = 1,
  }) {
    _ensureOpen();
    _requireStepDirection(direction);
    return using((arena) {
      final outInstant = arena<taiyin_split_julian_date>();
      final outVirtual = arena<taiyin_calendar_datetime>();
      final outSegment = arena<Uint8>();
      outVirtual.ref.struct_size = sizeOf<taiyin_calendar_datetime>();
      _checkStatus(
        _host,
        _bindings.taiyin_ziwei_step_flow_hour_target(
          writeJulianDate(arena, instantUtc),
          writeNativeCalendar(_coreBindings, arena, virtualTime),
          ratHourMode.id,
          direction,
          outInstant,
          outVirtual,
          outSegment,
        ),
      );
      return ZiweiFlowHourTarget(
        instantUtc: readJulianDate<UtcScale>(outInstant.ref),
        virtualTime: readCalendarDateTime(outVirtual.ref),
        ratHourSegment: ZiweiRatHourSegment.fromId(outSegment.value),
      );
    });
  }

  /// The canonical center of the next logical flow hour.
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

  /// The canonical center of the previous logical flow hour.
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

  /// Moves one local civil flow day, retaining exact wall-clock fields.
  ZiweiFlowDayTarget stepFlowDayTarget({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    int direction = 1,
  }) {
    _ensureOpen();
    _requireStepDirection(direction);
    return using((arena) {
      final outInstant = arena<taiyin_split_julian_date>();
      final outVirtual = arena<taiyin_calendar_datetime>();
      outVirtual.ref.struct_size = sizeOf<taiyin_calendar_datetime>();
      _checkStatus(
        _host,
        _bindings.taiyin_ziwei_step_flow_day_target(
          writeJulianDate(arena, instantUtc),
          writeNativeCalendar(_coreBindings, arena, virtualTime),
          direction,
          outInstant,
          outVirtual,
        ),
      );
      return ZiweiFlowDayTarget(
        instantUtc: readJulianDate<UtcScale>(outInstant.ref),
        virtualTime: readCalendarDateTime(outVirtual.ref),
      );
    });
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
  }) {
    _ensureOpen();
    query.validate();
    if (endInstantUtc.compareTo(startInstantUtc) <= 0) {
      throw ArgumentError.value(
        endInstantUtc,
        'endInstantUtc',
        'must be after startInstantUtc',
      );
    }
    return using((arena) {
      final request = _writeZiweiReverseRequest(
        _bindings,
        arena,
        startInstantUtc: startInstantUtc,
        endInstantUtc: endInstantUtc,
        startVirtualTime: startVirtualTime,
        gender: gender,
        options: options,
        query: query,
      );
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final countStatus = _bindings.taiyin_ziwei_reverse_lookup_tier1(
        _context,
        _calendarHandle,
        request,
        nullptr,
        0,
        count,
        diagnostic,
      );
      final countDiagnostic = _host.readDiagnostic(diagnostic.ref);
      _host.recordDiagnostic(countDiagnostic);
      final countFlags = _checkStatus(
        _host,
        countStatus,
        diagnostic: countDiagnostic,
      );
      final requiredCount = validatedNativeArrayCount(
        count.value,
        'Ziwei reverse',
      );
      if (requiredCount == 0) {
        return operationResult(
          const <ZiweiReverseLookupCandidate>[],
          countFlags,
        );
      }

      final output = arena<taiyin_ziwei_reverse_candidate>(requiredCount);
      for (var index = 0; index < requiredCount; index++) {
        _bindings.taiyin_ziwei_reverse_candidate_init(output + index);
      }
      _coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final fillStatus = _bindings.taiyin_ziwei_reverse_lookup_tier1(
        _context,
        _calendarHandle,
        request,
        output,
        requiredCount,
        count,
        diagnostic,
      );
      final mappedDiagnostic = _host.readDiagnostic(diagnostic.ref);
      _host.recordDiagnostic(mappedDiagnostic);
      final fillFlags = _checkStatus(
        _host,
        fillStatus,
        diagnostic: mappedDiagnostic,
      );
      final resultCount = validatedNativeResultCount(
        count.value,
        requiredCount,
      );
      return operationResult(
        List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readZiweiReverseCandidate((output + index).ref),
        ]),
        countFlags | fillFlags,
      );
    });
  }
}

/// A natal Ziwei chart with branch-indexed palaces and an optional flow stack.
///
/// Created through [ZiweiContext.createChart]. Call [close] before discarding
/// the handle.
final class ZiweiChart implements Finalizable {
  ZiweiChart._(this._context, this._chart, this._finalizer) {
    _finalizer.attach(this, _chart.cast(), detach: this);
  }

  final ZiweiContext _context;
  final Pointer<taiyin_ziwei_chart> _chart;
  final NativeFinalizer _finalizer;
  bool _closed = false;

  TaiyinBindings get _bindings => _context._bindings;
  TaiyinBindings get _coreBindings => _context._coreBindings;

  bool get isClosed => _closed;

  /// Return an edited natal chart, preserving original birth facts; flows clear.
  ZiweiChart modify(ZiweiPlacementPatch patch) {
    _ensureOpen();
    _requirePlacement(_context);
    return using((arena) {
      final out = arena<Pointer<taiyin_ziwei_chart>>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_modify(
          _context._context,
          _chart,
          _writePlacementPatch(_bindings, arena, patch),
          out,
        ),
      );
      return ZiweiChart._(_context, out.value, _finalizer);
    });
  }

  /// Shift palace roles without moving physical stars. Source remains unchanged.
  ZiweiChart shiftLifePalace(int steps) {
    _ensureOpen();
    _requirePlacement(_context);
    _placementInt(steps, -2147483648, 2147483647, 'steps');
    return using((arena) {
      final out = arena<Pointer<taiyin_ziwei_chart>>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_shift_life_palace(_chart, steps, out),
      );
      return ZiweiChart._(_context, out.value, _finalizer);
    });
  }

  /// Restore the original chart into a new handle, with an empty flow stack.
  ZiweiChart reset() {
    _ensureOpen();
    _requirePlacement(_context);
    return using((arena) {
      final out = arena<Pointer<taiyin_ziwei_chart>>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_reset(_chart, out),
      );
      return ZiweiChart._(_context, out.value, _finalizer);
    });
  }

  /// Current finite inputs and cumulative edits; this is not a new birth date.
  ZiweiPlacementState get placement {
    _ensureOpen();
    _requirePlacement(_context);
    return using((arena) {
      final input = arena<taiyin_ziwei_placement_input>();
      final patch = arena<taiyin_ziwei_placement_patch>();
      final shift = arena<Uint8>();
      _bindings.taiyin_ziwei_placement_input_init(input);
      _bindings.taiyin_ziwei_placement_patch_init(patch);
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_placement(_chart, input, patch, shift),
      );
      return ZiweiPlacementState(
        _readPlacementInput(input.ref),
        _readPlacementPatch(patch.ref),
        shift.value,
      );
    });
  }

  /// Missing-input records for stars not placed by the current rule set.
  List<ZiweiOmittedPlacement> get omittedPlacements {
    _ensureOpen();
    _requirePlacement(_context);
    return _readOmitted(
      _context,
      (out, capacity, count) =>
          _bindings.taiyin_ziwei_chart_get_omitted_placements(
            _chart,
            out,
            capacity,
            count,
          ),
    );
  }

  /// Releases the native chart. Calling this more than once is safe.
  void close() {
    if (_closed) return;
    _closed = true;
    _finalizer.detach(this);
    _bindings.taiyin_ziwei_chart_destroy(_chart);
  }

  void _ensureOpen() {
    if (_closed) {
      throw StateError('This ZiweiChart has been closed.');
    }
    _context._ensureOpen();
  }

  /// The 31 stable natal anchors, addressable by [ZiweiAnchorSlot].
  ZiweiAnchors get anchors {
    _ensureOpen();
    return using((arena) {
      final output = arena<Uint8>(ZiweiAnchorSlot.count);
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_anchors(_chart, output),
      );
      return ZiweiAnchors([
        for (var index = 0; index < ZiweiAnchorSlot.count; index++)
          output[index],
      ]);
    });
  }

  /// The natal summary: gender, bureau, masters, and transforms.
  ZiweiChartSummary get summary {
    _ensureOpen();
    return using((arena) {
      final gender = arena<Uint8>();
      final bureau = arena<Uint8>();
      final bodyPalace = arena<Uint8>();
      final lifeMaster = arena<Uint16>();
      final bodyMaster = arena<Uint16>();
      final transforms = arena<taiyin_ziwei_transform_set>();
      _bindings.taiyin_ziwei_transform_set_init(transforms);
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_summary(
          _chart,
          gender,
          bureau,
          bodyPalace,
          lifeMaster,
          bodyMaster,
          transforms,
        ),
      );
      return ZiweiChartSummary(
        gender: ZiweiGender.fromId(gender.value),
        bureau: ZiweiBureau.fromId(bureau.value),
        bodyPalaceBranch: bodyPalace.value,
        lifeMaster: lifeMaster.value,
        bodyMaster: bodyMaster.value,
        transforms: _readZiweiTransformSet(transforms.ref),
        palaceStems: List.unmodifiable([
          for (var branch = 0; branch < 12; branch++)
            _palaceStem(arena, branch),
        ]),
      );
    });
  }

  int _palaceStem(Arena arena, int branch) {
    final output = arena<Uint8>();
    _checkStatus(
      _context._host,
      _bindings.taiyin_ziwei_chart_get_palace_stem(_chart, branch, output),
    );
    return output.value;
  }

  /// The twelve natal palaces in semantic (Life through Parents) order.
  List<ZiweiPalaceState> get palaces {
    _ensureOpen();
    final chartAnchors = anchors;
    final stems = summary.palaceStems;
    return List.unmodifiable([
      for (final palace in ZiweiPalace.values)
        ZiweiPalaceState(
          palace: palace,
          branchId: chartAnchors.palacePosition(palace),
          stemId: stems[chartAnchors.palacePosition(palace)],
          stars: palaceStars(chartAnchors.palacePosition(palace)),
        ),
    ]);
  }

  /// Returns one named natal palace with its physical branch and stars.
  ZiweiPalaceState palace(ZiweiPalace palace) => palaces[palace.id];

  /// The physical branch (0 = Zi … 11 = Hai) a natal star occupies, or null
  /// when the star is absent from the natal chart.
  int? starPosition(int starId) {
    _ensureOpen();
    _context._requireStarId(starId);
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_star_position(_chart, starId, output),
      );
      return output.value == _taiyinZiweiInvalidPosition ? null : output.value;
    });
  }

  /// The twelve-palace role a natal star resolves to, or null for flow-only
  /// or absent stars.
  int? starPalace(int starId) {
    _ensureOpen();
    _context._requireStarId(starId);
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_star_palace(_chart, starId, output),
      );
      return output.value == _taiyinZiweiInvalidPosition ? null : output.value;
    });
  }

  /// The brightness of a star at its natal position.
  ZiweiBrightness brightness(int starId) {
    _ensureOpen();
    _context._requireStarId(starId);
    return using((arena) {
      final output = arena<Int32>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_brightness(
          _context._context,
          _chart,
          starId,
          output,
        ),
      );
      return ZiweiBrightness.fromId(output.value);
    });
  }

  /// The stars residing in the palace at physical [branchId].
  List<ZiweiStar> palaceStars(int branchId) {
    _ensureOpen();
    _requireZiweiBranch(branchId, 'branchId');
    return using((arena) {
      final ids = _readZiweiStarIds(
        _context._host,
        _bindings,
        arena,
        (buffer, capacity, count) =>
            _bindings.taiyin_ziwei_chart_get_palace_stars(
              _chart,
              branchId,
              buffer,
              capacity,
              count,
            ),
      );
      return List.unmodifiable([for (final id in ids) _context.star(id)]);
    });
  }

  /// The raw transformation mask of a natal star; bits follow
  /// [ZiweiTransformMark.mask].
  int transformMask(int starId) {
    _ensureOpen();
    _context._requireStarId(starId);
    return using((arena) {
      final output = arena<Uint16>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_star_transformation_mask(
          _chart,
          starId,
          output,
        ),
      );
      return output.value;
    });
  }

  /// Whether a natal star carries the transformation overlay [mark].
  bool hasTransform(int starId, ZiweiTransformMark mark) {
    _ensureOpen();
    _context._requireStarId(starId);
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_has_star_transform_mark(
          _chart,
          mark.id,
          starId,
          output,
        ),
      );
      return output.value != 0;
    });
  }

  /// The number of layers currently on the flow stack.
  int get flowLayerCount {
    _ensureOpen();
    return _bindings.taiyin_ziwei_chart_flow_layer_count(_chart);
  }

  /// Replaces the chart's contiguous flow stack through [deepestLevel].
  OperationResult<ZiweiFlowResolution> setFlow({
    required JulianDate<UtcScale> targetInstantUtc,
    required AstroDateTime targetVirtualTime,
    ZiweiFlowOptions options = const ZiweiFlowOptions(),
    ZiweiFlowLevel deepestLevel = ZiweiFlowLevel.hour,
  }) {
    _ensureOpen();
    return using((arena) {
      final nativeOptions = _writeZiweiFlowOptions(_bindings, arena, options);
      final summary = arena<taiyin_ziwei_flow_summary>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ziwei_flow_summary_init(summary);
      _coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_ziwei_chart_set_flow(
        _context._context,
        _context._calendarHandle,
        writeJulianDate(arena, targetInstantUtc),
        writeNativeCalendar(_coreBindings, arena, targetVirtualTime),
        nativeOptions,
        deepestLevel.id,
        _chart,
        summary,
        diagnostic,
      );
      final mappedDiagnostic = _context._host.readDiagnostic(diagnostic.ref);
      _context._host.recordDiagnostic(mappedDiagnostic);
      final flags = _checkStatus(
        _context._host,
        status,
        diagnostic: mappedDiagnostic,
      );
      return operationResult(_readZiweiFlowResolution(summary.ref), flags);
    });
  }

  /// Drops the flow layers from [firstRemovedLevel] onward.
  void truncateFlow(ZiweiFlowLevel firstRemovedLevel) {
    _ensureOpen();
    _checkStatus(
      _context._host,
      _bindings.taiyin_ziwei_chart_truncate_flow(_chart, firstRemovedLevel.id),
    );
  }

  /// The summary of one flow layer.
  ZiweiFlowLayerSummary flowLayerSummary(ZiweiFlowLevel level) {
    _ensureOpen();
    return using((arena) {
      final lifePalace = arena<Uint8>();
      final coordinateStem = arena<Uint8>();
      final coordinateBranch = arena<Uint8>();
      final transforms = arena<taiyin_ziwei_transform_set>();
      _bindings.taiyin_ziwei_transform_set_init(transforms);
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_flow_layer_summary(
          _chart,
          level.id,
          lifePalace,
          coordinateStem,
          coordinateBranch,
        ),
      );
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_flow_transforms(
          _chart,
          level.id,
          transforms,
        ),
      );
      return ZiweiFlowLayerSummary(
        lifePalace: lifePalace.value,
        coordinateStem: coordinateStem.value,
        coordinateBranch: coordinateBranch.value,
        transforms: _readZiweiTransformSet(transforms.ref),
      );
    });
  }

  /// The physical branch a star occupies in flow [level], or null when the
  /// star is absent from that layer.
  int? flowStarPosition(ZiweiFlowLevel level, int starId) {
    _ensureOpen();
    _context._requireStarId(starId);
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_chart_get_flow_star_position(
          _chart,
          level.id,
          starId,
          output,
        ),
      );
      return output.value == _taiyinZiweiInvalidPosition ? null : output.value;
    });
  }

  /// The stars residing in the palace at physical [branchId] of flow [level].
  List<ZiweiStar> flowPalaceStars(ZiweiFlowLevel level, int branchId) {
    _ensureOpen();
    _requireZiweiBranch(branchId, 'branchId');
    return using((arena) {
      final ids = _readZiweiStarIds(
        _context._host,
        _bindings,
        arena,
        (buffer, capacity, count) =>
            _bindings.taiyin_ziwei_chart_get_flow_palace_stars(
              _chart,
              level.id,
              branchId,
              buffer,
              capacity,
              count,
            ),
      );
      return List.unmodifiable([for (final id in ids) _context.star(id)]);
    });
  }
}

void _validateZiweiOptionSelection(ZiweiOptionSelection selection) {
  _requireZiweiOptionText(selection.placementDefault, 'placementDefault');
  _requireZiweiOptionText(selection.brightnessDefault, 'brightnessDefault');
  _requireZiweiOptionText(selection.sihuaDefault, 'sihuaDefault');
  _requireZiweiOptionText(selection.masters, 'masters');
  _requireZiweiOptionText(selection.longevity, 'longevity');
  for (final entry in selection.placement.entries) {
    _requireZiweiOptionText(entry.key, 'placement key');
    _requireZiweiOptionText(entry.value, 'placement option');
  }
  for (final entry in selection.brightness.entries) {
    _requireZiweiOptionText(entry.key, 'brightness key');
    _requireZiweiOptionText(entry.value, 'brightness option');
  }
  for (final entry in selection.sihua.entries) {
    _requireZiweiOptionText(entry.key, 'sihua key');
    _requireZiweiOptionText(entry.value, 'sihua option');
  }
}

void _validateZiweiRuleset(ZiweiRuleset ruleset) {
  final labels = <String>{};
  for (final module in ruleset.modules) {
    if (module.label.isEmpty) {
      throw ArgumentError.value(module.label, 'label', 'must not be empty');
    }
    if (!labels.add(module.label)) {
      throw ArgumentError.value(
        module.label,
        'label',
        'must be unique within a ruleset',
      );
    }
    _requireZiweiOptionText(module.label, 'label');
    _requireZiweiOptionText(module.starsJson, 'starsJson');
    _requireZiweiOptionText(module.brightnessJson, 'brightnessJson');
    _requireZiweiOptionText(module.sihuaJson, 'sihuaJson');
    _requireZiweiOptionText(module.flowJson, 'flowJson');
    _requireZiweiOptionText(module.mastersJson, 'mastersJson');
  }
}

void _requireZiweiOptionText(String value, String name) {
  if (value.contains('\u0000')) {
    throw ArgumentError.value(value, name, 'must not contain a NUL character');
  }
}

void _requireZiweiBranch(int branchId, String name) {
  if (branchId < 0 || branchId >= 12) {
    throw ArgumentError.value(branchId, name, 'must be in the range 0..11');
  }
}

List<int> _readZiweiStarIds(
  TaiyinExtensionHost host,
  TaiyinBindings bindings,
  Arena arena,
  int Function(Pointer<Uint16> buffer, int capacity, Pointer<Size> count) fill,
) {
  final count = arena<Size>();
  _checkStatus(host, fill(nullptr, 0, count));
  final requiredCount = validatedNativeArrayCount(
    count.value,
    'Ziwei star list',
  );
  if (requiredCount == 0) return const <int>[];
  final buffer = arena<Uint16>(requiredCount);
  _checkStatus(host, fill(buffer, requiredCount, count));
  final resultCount = validatedNativeResultCount(count.value, requiredCount);
  return [for (var index = 0; index < resultCount; index++) buffer[index]];
}

({Pointer<taiyin_ziwei_option_override> pointer, int count})
_writeZiweiOptionOverrides(
  TaiyinBindings bindings,
  Arena arena,
  ZiweiOptionSelection selection,
) {
  final entries = <(int, String?, String)>[
    if (selection.placementDefault.isNotEmpty)
      (
        taiyin_ziwei_option_component.TAIYIN_ZIWEI_OPTION_PLACEMENT,
        null,
        selection.placementDefault,
      ),
    for (final entry in selection.placement.entries)
      (
        taiyin_ziwei_option_component.TAIYIN_ZIWEI_OPTION_PLACEMENT,
        entry.key,
        entry.value,
      ),
    if (selection.brightnessDefault.isNotEmpty)
      (
        taiyin_ziwei_option_component.TAIYIN_ZIWEI_OPTION_BRIGHTNESS,
        null,
        selection.brightnessDefault,
      ),
    for (final entry in selection.brightness.entries)
      (
        taiyin_ziwei_option_component.TAIYIN_ZIWEI_OPTION_BRIGHTNESS,
        entry.key,
        entry.value,
      ),
    if (selection.sihuaDefault.isNotEmpty)
      (
        taiyin_ziwei_option_component.TAIYIN_ZIWEI_OPTION_SIHUA,
        null,
        selection.sihuaDefault,
      ),
    for (final entry in selection.sihua.entries)
      (
        taiyin_ziwei_option_component.TAIYIN_ZIWEI_OPTION_SIHUA,
        entry.key,
        entry.value,
      ),
    if (selection.masters.isNotEmpty)
      (
        taiyin_ziwei_option_component.TAIYIN_ZIWEI_OPTION_MASTERS,
        null,
        selection.masters,
      ),
    if (selection.longevity.isNotEmpty)
      (
        taiyin_ziwei_option_component.TAIYIN_ZIWEI_OPTION_LONGEVITY,
        null,
        selection.longevity,
      ),
  ];
  if (entries.isEmpty) {
    return (pointer: nullptr, count: 0);
  }
  final output = arena<taiyin_ziwei_option_override>(entries.length);
  for (var index = 0; index < entries.length; index++) {
    final (component, key, option) = entries[index];
    final slot = output + index;
    bindings.taiyin_ziwei_option_override_init(slot);
    slot.ref
      ..component = component
      ..key = key == null ? nullptr : key.toNativeUtf8(allocator: arena).cast()
      ..option = option.toNativeUtf8(allocator: arena).cast();
  }
  return (pointer: output, count: entries.length);
}

Pointer<taiyin_ziwei_json_rule_module> _writeZiweiJsonRuleModule(
  TaiyinBindings bindings,
  Arena arena,
  ZiweiJsonRuleModule module,
) {
  Pointer<Char> optional(String value) =>
      value.isEmpty ? nullptr : value.toNativeUtf8(allocator: arena).cast();

  final output = arena<taiyin_ziwei_json_rule_module>();
  bindings.taiyin_ziwei_json_rule_module_init(output);
  output.ref
    ..label = module.label.toNativeUtf8(allocator: arena).cast()
    ..stars_json = optional(module.starsJson)
    ..brightness_json = optional(module.brightnessJson)
    ..sihua_json = optional(module.sihuaJson)
    ..flow_json = optional(module.flowJson)
    ..masters_json = optional(module.mastersJson);
  return output;
}

Pointer<taiyin_ziwei_birth_options> _writeZiweiBirthOptions(
  TaiyinBindings bindings,
  Arena arena,
  ZiweiBirthOptions options,
) {
  final native = arena<taiyin_ziwei_birth_options>();
  bindings.taiyin_ziwei_birth_options_init(native);
  native.ref
    ..rat_hour_mode = options.ratHourMode.id
    ..leap_month_strategy = options.leapMonthStrategy.id
    ..chart_mode = options.chartMode.id
    ..wu_hu_dun_year_boundary = options.wuHuDunYearBoundary.id
    ..sihua_year_boundary = options.sihuaYearBoundary.id
    ..body_master_year_boundary = options.bodyMasterYearBoundary.id;
  return native;
}

Pointer<taiyin_ziwei_flow_options> _writeZiweiFlowOptions(
  TaiyinBindings bindings,
  Arena arena,
  ZiweiFlowOptions options,
) {
  final native = arena<taiyin_ziwei_flow_options>();
  bindings.taiyin_ziwei_flow_options_init(native);
  native.ref
    ..boundary = options.boundary.id
    ..rat_hour_mode = options.ratHourMode.id
    ..childhood_strategy = options.childhoodStrategy.id
    ..flow_month_palace_strategy = options.flowMonthPalaceStrategy.id;
  return native;
}

void _writeZiweiReverseQueryFields(
  taiyin_ziwei_reverse_query native,
  ZiweiTier1ReverseQuery query,
) {
  native
    ..lucun_branch = query.lucunBranch ?? -1
    ..hongluan_branch = query.hongluanBranch ?? -1
    ..zuofu_branch = query.zuofuBranch ?? -1
    ..youbi_branch = query.youbiBranch ?? -1
    ..wenchang_branch = query.wenchangBranch ?? -1
    ..wenqu_branch = query.wenquBranch ?? -1
    ..santai_branch = query.santaiBranch ?? -1
    ..bazuo_branch = query.bazuoBranch ?? -1
    ..ziwei_branch = query.ziweiBranch ?? -1;
}

Pointer<taiyin_ziwei_reverse_request> _writeZiweiReverseRequest(
  TaiyinBindings bindings,
  Arena arena, {
  required JulianDate<UtcScale> startInstantUtc,
  required JulianDate<UtcScale> endInstantUtc,
  required AstroDateTime startVirtualTime,
  required ZiweiGender gender,
  required ZiweiBirthOptions options,
  required ZiweiTier1ReverseQuery query,
}) {
  validateNativeJulianDate(startInstantUtc);
  validateNativeJulianDate(endInstantUtc);
  validateNativeCalendar(startVirtualTime);
  final native = arena<taiyin_ziwei_reverse_request>();
  bindings.taiyin_ziwei_reverse_request_init(native);
  native.ref
    ..start_instant_utc.day_number = startInstantUtc.dayNumber
    ..start_instant_utc.day_fraction = startInstantUtc.dayFraction
    ..end_instant_utc.day_number = endInstantUtc.dayNumber
    ..end_instant_utc.day_fraction = endInstantUtc.dayFraction
    ..start_virtual_time.struct_size = sizeOf<taiyin_calendar_datetime>()
    ..start_virtual_time.year = startVirtualTime.year
    ..start_virtual_time.month = startVirtualTime.month
    ..start_virtual_time.day = startVirtualTime.day
    ..start_virtual_time.hour = startVirtualTime.hour
    ..start_virtual_time.minute = startVirtualTime.minute
    ..start_virtual_time.second = startVirtualTime.fractionalSecond
    ..gender = gender.id;
  native.ref.birth_options
    ..struct_size = sizeOf<taiyin_ziwei_birth_options>()
    ..rat_hour_mode = options.ratHourMode.id
    ..leap_month_strategy = options.leapMonthStrategy.id
    ..chart_mode = options.chartMode.id
    ..wu_hu_dun_year_boundary = options.wuHuDunYearBoundary.id
    ..sihua_year_boundary = options.sihuaYearBoundary.id
    ..body_master_year_boundary = options.bodyMasterYearBoundary.id;
  _writeZiweiReverseQueryFields(native.ref.query, query);
  return native;
}

ZiweiReverseLookupCandidate _readZiweiReverseCandidate(
  taiyin_ziwei_reverse_candidate value,
) {
  return ZiweiReverseLookupCandidate(
    instantUtc: readJulianDate<UtcScale>(value.instant_utc),
    virtualTime: readCalendarDateTime(value.virtual_time),
    lunarYear: value.lunar_year,
    lunarMonth: value.lunar_month,
    lunarDay: value.lunar_day,
    lunarIsLeap: value.lunar_is_leap != 0,
    hourBranch: value.hour_branch,
    ratHourSegment: ZiweiRatHourSegment.fromId(value.rat_hour_segment),
  );
}

ZiweiTransformSet _readZiweiTransformSet(taiyin_ziwei_transform_set value) {
  return ZiweiTransformSet(
    lu: value.lu,
    quan: value.quan,
    ke: value.ke,
    ji: value.ji,
  );
}

ZiweiFlowResolution _readZiweiFlowResolution(taiyin_ziwei_flow_summary value) {
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

void _requireStepDirection(int direction) {
  if (direction != -1 && direction != 1) {
    throw ArgumentError.value(direction, 'direction', 'must be -1 or 1');
  }
}

void _requireZiweiPath(String path) {
  if (path.isEmpty) {
    throw ArgumentError.value(path, 'profilePath', 'must not be empty');
  }
  if (path.contains('\u0000')) {
    throw ArgumentError.value(
      path,
      'profilePath',
      'must not contain a NUL character',
    );
  }
}

String _defaultZiweiProfilePath() {
  final resolved = Isolate.resolvePackageUriSync(
    Uri.parse('package:$_ziweiRulePackage/data/ziwei/rules/default.toml'),
  );
  if (resolved == null || resolved.scheme != 'file') {
    throw StateError(
      'Could not resolve the bundled Ziwei rule profile. '
      'Pass profilePath to ZiweiDataCatalog explicitly.',
    );
  }
  return resolved.toFilePath();
}
