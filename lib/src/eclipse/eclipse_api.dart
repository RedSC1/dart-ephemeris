part of '../taiyin.dart';

typedef _EclipseStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);
typedef _LunarTtCalculation =
    int Function(
      Pointer<taiyin_lunar_eclipse_result_tt> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LunarUtCalculation =
    int Function(
      Pointer<taiyin_lunar_eclipse_result_ut> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LunarTtArrayCalculation =
    int Function(
      Pointer<taiyin_lunar_eclipse_result_tt> output,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LunarUtArrayCalculation =
    int Function(
      Pointer<taiyin_lunar_eclipse_result_ut> output,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LocalLunarTtCalculation =
    int Function(
      Pointer<taiyin_local_lunar_eclipse_result_tt> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LocalLunarUtCalculation =
    int Function(
      Pointer<taiyin_local_lunar_eclipse_result_ut> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );

/// Calculates and searches lunar eclipses.
///
/// A local method samples the observer location already configured on the
/// owning [TaiyinContext]. Native calculation coordinates and contact times
/// cross ABI-1 as scalar Julian dates.
final class TaiyinEclipseApi {
  TaiyinEclipseApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _EclipseStatusChecker _checkStatus;

  /// Solves the lunar-eclipse lunation nearest [estimate].
  TaiyinEphemerisResult<TaiyinLunarEclipseResult<TtScale>> solveLunarAtTt(
    JulianDate<TtScale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinLunarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solveMask(positionFlags, options);
    return _lunarTt((output, diagnostic) {
      return _bindings.taiyin_solve_lunar_eclipse_at_tt(
        _context,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Solves the lunar-eclipse lunation nearest [estimate].
  TaiyinEphemerisResult<TaiyinLunarEclipseResult<Ut1Scale>> solveLunarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinLunarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solveMask(positionFlags, options);
    return _lunarUt((output, diagnostic) {
      return _bindings.taiyin_solve_lunar_eclipse_at_ut(
        _context,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next matching lunar eclipse from [start].
  TaiyinEphemerisResult<TaiyinLunarEclipseResult<TtScale>> nextLunarAtTt(
    JulianDate<TtScale> start, {
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinLunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: true);
    return _lunarTt((output, diagnostic) {
      return _bindings.taiyin_search_next_lunar_eclipse_tt(
        _context,
        start.toDouble(),
        kindMask,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next matching lunar eclipse from [start].
  ///
  /// Pass [TaiyinLunarEclipseSearchOption.backward] to search backwards.
  TaiyinEphemerisResult<TaiyinLunarEclipseResult<Ut1Scale>> nextLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinLunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: true);
    return _lunarUt((output, diagnostic) {
      return _bindings.taiyin_search_next_lunar_eclipse_ut(
        _context,
        start.toDouble(),
        kindMask,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds all matching lunar eclipses in the inclusive [start], [end] range.
  ///
  /// Native code reports insufficient [maxResults] capacity as an error rather
  /// than silently dropping later eclipses.
  TaiyinEphemerisResult<List<TaiyinLunarEclipseResult<TtScale>>>
  lunarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinLunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: false);
    return _lunarTtArray(maxResults, (output, capacity, count, diagnostic) {
      return _bindings.taiyin_search_lunar_eclipses_tt(
        _context,
        start.toDouble(),
        end.toDouble(),
        kindMask,
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Finds all matching lunar eclipses in the inclusive [start], [end] range.
  TaiyinEphemerisResult<List<TaiyinLunarEclipseResult<Ut1Scale>>>
  lunarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinLunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: false);
    return _lunarUtArray(maxResults, (output, capacity, count, diagnostic) {
      return _bindings.taiyin_search_lunar_eclipses_ut(
        _context,
        start.toDouble(),
        end.toDouble(),
        kindMask,
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Derives local visibility for a TT global [eclipse].
  ///
  /// The context must have a geographic observer. A non-empty eclipse must
  /// include contact data, so search with `includeContacts` before calling.
  TaiyinEphemerisResult<TaiyinLocalLunarEclipseResult<TtScale>>
  localLunarVisibilityAtTt(
    TaiyinLunarEclipseResult<TtScale> eclipse, {
    Set<TaiyinLocalLunarEclipseVisibilityOption> options = const {},
  }) {
    _ensureOpen();
    _requireLocalContacts(eclipse);
    final mask = _localVisibilityMask(options);
    return _localLunarTt((output, diagnostic) {
      return using((arena) {
        final nativeEclipse = _writeLunarTt(arena, eclipse);
        return _bindings.taiyin_compute_local_lunar_eclipse_visibility_tt(
          _context,
          nativeEclipse,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Derives local visibility for a UT1 global [eclipse].
  TaiyinEphemerisResult<TaiyinLocalLunarEclipseResult<Ut1Scale>>
  localLunarVisibilityAtUt1(
    TaiyinLunarEclipseResult<Ut1Scale> eclipse, {
    Set<TaiyinLocalLunarEclipseVisibilityOption> options = const {},
  }) {
    _ensureOpen();
    _requireLocalContacts(eclipse);
    final mask = _localVisibilityMask(options);
    return _localLunarUt((output, diagnostic) {
      return using((arena) {
        final nativeEclipse = _writeLunarUt(arena, eclipse);
        return _bindings.taiyin_compute_local_lunar_eclipse_visibility_ut(
          _context,
          nativeEclipse,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next matching lunar eclipse and its visibility at the context
  /// observer.
  TaiyinEphemerisResult<TaiyinLocalLunarEclipseResult<TtScale>>
  nextLocalLunarAtTt(
    JulianDate<TtScale> start, {
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinLunarEclipseSearchOption> options = const {},
    Set<TaiyinLocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    final kindMask = _lunarKindMask(kinds);
    final mask = _mergeDisjointMasks(
      _searchMask(positionFlags, options, allowBackward: true),
      _localVisibilityMask(visibilityOptions),
    );
    return _localLunarTt((output, diagnostic) {
      return _bindings.taiyin_search_next_local_lunar_eclipse_tt(
        _context,
        start.toDouble(),
        kindMask,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next matching lunar eclipse and its visibility at the context
  /// observer.
  TaiyinEphemerisResult<TaiyinLocalLunarEclipseResult<Ut1Scale>>
  nextLocalLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinLunarEclipseSearchOption> options = const {},
    Set<TaiyinLocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    final kindMask = _lunarKindMask(kinds);
    final mask = _mergeDisjointMasks(
      _searchMask(positionFlags, options, allowBackward: true),
      _localVisibilityMask(visibilityOptions),
    );
    return _localLunarUt((output, diagnostic) {
      return _bindings.taiyin_search_next_local_lunar_eclipse_ut(
        _context,
        start.toDouble(),
        kindMask,
        mask,
        output,
        diagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLunarEclipseResult<TtScale>> _lunarTt(
    _LunarTtCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_eclipse_result_tt>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_eclipse_result_tt_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readLunarTt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLunarEclipseResult<Ut1Scale>> _lunarUt(
    _LunarUtCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_eclipse_result_ut>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_eclipse_result_ut_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readLunarUt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<List<TaiyinLunarEclipseResult<TtScale>>> _lunarTtArray(
    int capacity,
    _LunarTtArrayCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_eclipse_result_tt>(capacity);
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      for (var index = 0; index < capacity; index++) {
        _bindings.taiyin_lunar_eclipse_result_tt_init(output + index);
      }
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, capacity, count, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final resultCount = _validatedResultCount(count.value, capacity);
      return TaiyinEphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readLunarTt((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<List<TaiyinLunarEclipseResult<Ut1Scale>>> _lunarUtArray(
    int capacity,
    _LunarUtArrayCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_eclipse_result_ut>(capacity);
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      for (var index = 0; index < capacity; index++) {
        _bindings.taiyin_lunar_eclipse_result_ut_init(output + index);
      }
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, capacity, count, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final resultCount = _validatedResultCount(count.value, capacity);
      return TaiyinEphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readLunarUt((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLocalLunarEclipseResult<TtScale>> _localLunarTt(
    _LocalLunarTtCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_local_lunar_eclipse_result_tt>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_local_lunar_eclipse_result_tt_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readLocalLunarTt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLocalLunarEclipseResult<Ut1Scale>> _localLunarUt(
    _LocalLunarUtCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_local_lunar_eclipse_result_ut>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_local_lunar_eclipse_result_ut_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readLocalLunarUt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinLunarEclipseResult<TtScale> _readLunarTt(
    taiyin_lunar_eclipse_result_tt value,
  ) {
    return TaiyinLunarEclipseResult(
      kinds: TaiyinEclipseKind.fromMask(value.kind),
      maximum: _ttOrNull(value.maximum_jd_tt),
      deltaTSeconds: null,
      umbralMagnitude: _finiteOrNull(value.umbral_magnitude),
      penumbralMagnitude: _finiteOrNull(value.penumbral_magnitude),
      axisDistanceRadians: _finiteOrNull(value.axis_distance_rad),
      umbraRadiusRadians: _finiteOrNull(value.umbra_radius_rad),
      penumbraRadiusRadians: _finiteOrNull(value.penumbra_radius_rad),
      moonRadiusRadians: _finiteOrNull(value.moon_radius_rad),
      contacts: {
        for (final contact in TaiyinLunarEclipseContact.values)
          contact: _ttOrNull(value.contact_jd_tt[contact.nativeIndex]),
      },
    );
  }

  TaiyinLunarEclipseResult<Ut1Scale> _readLunarUt(
    taiyin_lunar_eclipse_result_ut value,
  ) {
    return TaiyinLunarEclipseResult(
      kinds: TaiyinEclipseKind.fromMask(value.kind),
      maximum: _ut1OrNull(value.maximum_jd_ut),
      deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
      umbralMagnitude: _finiteOrNull(value.umbral_magnitude),
      penumbralMagnitude: _finiteOrNull(value.penumbral_magnitude),
      axisDistanceRadians: _finiteOrNull(value.axis_distance_rad),
      umbraRadiusRadians: _finiteOrNull(value.umbra_radius_rad),
      penumbraRadiusRadians: _finiteOrNull(value.penumbra_radius_rad),
      moonRadiusRadians: _finiteOrNull(value.moon_radius_rad),
      contacts: {
        for (final contact in TaiyinLunarEclipseContact.values)
          contact: _ut1OrNull(value.contact_jd_ut[contact.nativeIndex]),
      },
    );
  }

  TaiyinLocalLunarEclipseResult<TtScale> _readLocalLunarTt(
    taiyin_local_lunar_eclipse_result_tt value,
  ) {
    return TaiyinLocalLunarEclipseResult(
      kinds: TaiyinEclipseKind.fromMask(value.eclipse_kind),
      visibility: TaiyinLocalLunarEclipseVisibilityFlag.fromMask(
        value.visibility_flags,
      ),
      maximum: _ttOrNull(value.maximum_jd_tt),
      deltaTSeconds: null,
      umbralMagnitude: _finiteOrNull(value.umbral_magnitude),
      penumbralMagnitude: _finiteOrNull(value.penumbral_magnitude),
      contacts: {
        for (final contact in TaiyinLunarEclipseContact.values)
          contact: _readLocalContact<TtScale>(
            _ttOrNull(value.contact_jd_tt[contact.nativeIndex]),
            value.contact_moon_altitude_deg[contact.nativeIndex],
            value.contact_moon_azimuth_deg[contact.nativeIndex],
          ),
      },
      moonrise: _ttOrNull(value.moonrise_jd_tt),
      moonset: _ttOrNull(value.moonset_jd_tt),
    );
  }

  TaiyinLocalLunarEclipseResult<Ut1Scale> _readLocalLunarUt(
    taiyin_local_lunar_eclipse_result_ut value,
  ) {
    return TaiyinLocalLunarEclipseResult(
      kinds: TaiyinEclipseKind.fromMask(value.eclipse_kind),
      visibility: TaiyinLocalLunarEclipseVisibilityFlag.fromMask(
        value.visibility_flags,
      ),
      maximum: _ut1OrNull(value.maximum_jd_ut),
      deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
      umbralMagnitude: _finiteOrNull(value.umbral_magnitude),
      penumbralMagnitude: _finiteOrNull(value.penumbral_magnitude),
      contacts: {
        for (final contact in TaiyinLunarEclipseContact.values)
          contact: _readLocalContact<Ut1Scale>(
            _ut1OrNull(value.contact_jd_ut[contact.nativeIndex]),
            value.contact_moon_altitude_deg[contact.nativeIndex],
            value.contact_moon_azimuth_deg[contact.nativeIndex],
          ),
      },
      moonrise: _ut1OrNull(value.moonrise_jd_ut),
      moonset: _ut1OrNull(value.moonset_jd_ut),
    );
  }

  TaiyinLocalLunarEclipseContact<S>? _readLocalContact<S extends TimeScale>(
    JulianDate<S>? coordinate,
    double altitudeDegrees,
    double azimuthDegrees,
  ) {
    if (coordinate == null) return null;
    return TaiyinLocalLunarEclipseContact(
      coordinate: coordinate,
      moonAltitudeDegrees: _finiteOrNull(altitudeDegrees),
      moonAzimuthDegrees: _finiteOrNull(azimuthDegrees),
    );
  }

  Pointer<taiyin_lunar_eclipse_result_tt> _writeLunarTt(
    Arena arena,
    TaiyinLunarEclipseResult<TtScale> value,
  ) {
    final output = arena<taiyin_lunar_eclipse_result_tt>();
    _bindings.taiyin_lunar_eclipse_result_tt_init(output);
    output.ref
      ..kind = _kindMask(value.kinds)
      ..maximum_jd_tt = value.maximum?.toDouble() ?? double.nan
      ..umbral_magnitude = value.umbralMagnitude ?? double.nan
      ..penumbral_magnitude = value.penumbralMagnitude ?? double.nan
      ..axis_distance_rad = value.axisDistanceRadians ?? double.nan
      ..umbra_radius_rad = value.umbraRadiusRadians ?? double.nan
      ..penumbra_radius_rad = value.penumbraRadiusRadians ?? double.nan
      ..moon_radius_rad = value.moonRadiusRadians ?? double.nan;
    for (final contact in TaiyinLunarEclipseContact.values) {
      output.ref.contact_jd_tt[contact.nativeIndex] =
          value.contacts[contact]?.toDouble() ?? double.nan;
    }
    return output;
  }

  Pointer<taiyin_lunar_eclipse_result_ut> _writeLunarUt(
    Arena arena,
    TaiyinLunarEclipseResult<Ut1Scale> value,
  ) {
    final output = arena<taiyin_lunar_eclipse_result_ut>();
    _bindings.taiyin_lunar_eclipse_result_ut_init(output);
    output.ref
      ..kind = _kindMask(value.kinds)
      ..maximum_jd_ut = value.maximum?.toDouble() ?? double.nan
      ..delta_t_seconds = value.deltaTSeconds ?? double.nan
      ..umbral_magnitude = value.umbralMagnitude ?? double.nan
      ..penumbral_magnitude = value.penumbralMagnitude ?? double.nan
      ..axis_distance_rad = value.axisDistanceRadians ?? double.nan
      ..umbra_radius_rad = value.umbraRadiusRadians ?? double.nan
      ..penumbra_radius_rad = value.penumbraRadiusRadians ?? double.nan
      ..moon_radius_rad = value.moonRadiusRadians ?? double.nan;
    for (final contact in TaiyinLunarEclipseContact.values) {
      output.ref.contact_jd_ut[contact.nativeIndex] =
          value.contacts[contact]?.toDouble() ?? double.nan;
    }
    return output;
  }

  int _solveMask(
    Set<TaiyinPositionFlag> positionFlags,
    Set<TaiyinLunarEclipseSolveOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(0, (mask, option) => mask | option.mask),
    );
  }

  int _searchMask(
    Set<TaiyinPositionFlag> positionFlags,
    Set<TaiyinLunarEclipseSearchOption> options, {
    required bool allowBackward,
  }) {
    _requireSupportedPositionFlags(positionFlags);
    if (!allowBackward &&
        options.contains(TaiyinLunarEclipseSearchOption.backward)) {
      throw ArgumentError.value(
        options,
        'options',
        'backward is only valid for next-eclipse searches',
      );
    }
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(0, (mask, option) => mask | option.mask),
    );
  }

  int _localVisibilityMask(
    Set<TaiyinLocalLunarEclipseVisibilityOption> options,
  ) {
    return options.fold(0, (mask, option) => mask | option.mask);
  }

  int _positionMask(Set<TaiyinPositionFlag> positionFlags) {
    return positionFlags.fold(0, (mask, flag) => mask | flag.mask);
  }

  int _mergeDisjointMasks(int positionMask, int optionMask) {
    assert(
      (positionMask & optionMask) == 0,
      'Position flags and eclipse options bit ranges overlap',
    );
    return positionMask | optionMask;
  }

  int _lunarKindMask(Set<TaiyinEclipseKind> kinds) {
    const supported = {
      TaiyinEclipseKind.penumbral,
      TaiyinEclipseKind.partial,
      TaiyinEclipseKind.total,
    };
    final unsupported = kinds.difference(supported);
    if (unsupported.isNotEmpty) {
      throw ArgumentError.value(
        kinds,
        'kinds',
        'lunar eclipses support only penumbral, partial, and total filters',
      );
    }
    return _kindMask(kinds);
  }

  int _kindMask(Set<TaiyinEclipseKind> kinds) {
    return kinds.fold(0, (mask, kind) => mask | kind.mask);
  }

  void _requireSupportedPositionFlags(Set<TaiyinPositionFlag> flags) {
    const supported = {TaiyinPositionFlag.truePosition};
    final unsupported = flags.difference(supported);
    if (unsupported.isNotEmpty) {
      throw ArgumentError.value(
        flags,
        'positionFlags',
        'lunar eclipses support only truePosition',
      );
    }
  }

  void _requireLocalContacts<S extends TimeScale>(
    TaiyinLunarEclipseResult<S> eclipse,
  ) {
    if (!eclipse.hasEclipse) return;
    final greatest = eclipse.contacts[TaiyinLunarEclipseContact.greatest];
    final contactCount = eclipse.contacts.values
        .whereType<JulianDate<S>>()
        .length;
    if (greatest == null || contactCount < 2) {
      throw ArgumentError.value(
        eclipse,
        'eclipse',
        'must include a greatest and at least one other contact; search with '
            'TaiyinLunarEclipseSearchOption.includeContacts',
      );
    }
  }

  void _requireInterval<S extends TimeScale>(
    JulianDate<S> start,
    JulianDate<S> end,
  ) {
    if (end.compareTo(start) <= 0) {
      throw ArgumentError.value(end, 'end', 'must be later than start');
    }
  }

  void _requireCapacity(int capacity) {
    if (capacity <= 0) {
      throw RangeError.range(capacity, 1, null, 'maxResults');
    }
  }

  int _validatedResultCount(int count, int capacity) {
    if (count < 0 || count > capacity) {
      throw StateError(
        'Native lunar-eclipse search returned count=$count outside 0..$capacity',
      );
    }
    return count;
  }

  JulianDate<TtScale>? _ttOrNull(double value) {
    return value.isFinite ? JulianDate<TtScale>.fromDouble(value) : null;
  }

  JulianDate<Ut1Scale>? _ut1OrNull(double value) {
    return value.isFinite ? JulianDate<Ut1Scale>.fromDouble(value) : null;
  }

  double? _finiteOrNull(double value) => value.isFinite ? value : null;
}
