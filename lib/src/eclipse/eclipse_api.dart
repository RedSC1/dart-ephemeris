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
typedef _SolarTtCalculation =
    int Function(
      Pointer<taiyin_solar_eclipse_result_tt> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarUtCalculation =
    int Function(
      Pointer<taiyin_solar_eclipse_result_ut> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarTtArrayCalculation =
    int Function(
      Pointer<taiyin_solar_eclipse_result_tt> output,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarUtArrayCalculation =
    int Function(
      Pointer<taiyin_solar_eclipse_result_ut> output,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LocalSolarTtCalculation =
    int Function(
      Pointer<taiyin_local_solar_eclipse_result_tt> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LocalSolarUtCalculation =
    int Function(
      Pointer<taiyin_local_solar_eclipse_result_ut> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarCircumstancesTtCalculation =
    int Function(
      Pointer<taiyin_local_solar_eclipse_circumstances_tt> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarCircumstancesUtCalculation =
    int Function(
      Pointer<taiyin_local_solar_eclipse_circumstances_ut> output,
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

  /// Finds all matching lunar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
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

  /// Finds all matching lunar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
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

  int _mergeDisjointMasks(int maskA, int maskB) {
    assert((maskA & maskB) == 0, 'Eclipse mask fields overlap');
    return maskA | maskB;
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
        'eclipse APIs support only truePosition',
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
        'Native eclipse search returned count=$count outside 0..$capacity',
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

  /// Solves the solar-eclipse lunation nearest [estimate].
  TaiyinEphemerisResult<TaiyinSolarEclipseResult<TtScale>> solveSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarSolveMask(positionFlags, options);
    return _solarTt((output, diagnostic) {
      return _bindings.taiyin_solve_solar_eclipse_at_tt(
        _context,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Solves the solar-eclipse lunation nearest [estimate].
  TaiyinEphemerisResult<TaiyinSolarEclipseResult<Ut1Scale>> solveSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarSolveMask(positionFlags, options);
    return _solarUt((output, diagnostic) {
      return _bindings.taiyin_solve_solar_eclipse_at_ut(
        _context,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next matching global solar eclipse from [start].
  TaiyinEphemerisResult<TaiyinSolarEclipseResult<TtScale>> nextSolarAtTt(
    JulianDate<TtScale> start, {
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarSearchMask(positionFlags, options, allowBackward: true);
    return _solarTt((output, diagnostic) {
      return _bindings.taiyin_search_next_solar_eclipse_tt(
        _context,
        start.toDouble(),
        _solarKindMask(kinds),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next matching global solar eclipse from [start].
  ///
  /// Pass [TaiyinSolarEclipseSearchOption.backward] to search backwards.
  TaiyinEphemerisResult<TaiyinSolarEclipseResult<Ut1Scale>> nextSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarSearchMask(positionFlags, options, allowBackward: true);
    return _solarUt((output, diagnostic) {
      return _bindings.taiyin_search_next_solar_eclipse_ut(
        _context,
        start.toDouble(),
        _solarKindMask(kinds),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds all matching solar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  TaiyinEphemerisResult<List<TaiyinSolarEclipseResult<TtScale>>>
  solarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final mask = _solarSearchMask(positionFlags, options, allowBackward: false);
    return _solarTtArray(maxResults, (output, capacity, count, diagnostic) {
      return _bindings.taiyin_search_solar_eclipses_tt(
        _context,
        start.toDouble(),
        end.toDouble(),
        _solarKindMask(kinds),
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Finds all matching solar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  TaiyinEphemerisResult<List<TaiyinSolarEclipseResult<Ut1Scale>>>
  solarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final mask = _solarSearchMask(positionFlags, options, allowBackward: false);
    return _solarUtArray(maxResults, (output, capacity, count, diagnostic) {
      return _bindings.taiyin_search_solar_eclipses_ut(
        _context,
        start.toDouble(),
        end.toDouble(),
        _solarKindMask(kinds),
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Solves local solar-eclipse circumstances at the context observer.
  ///
  /// Contacts are always requested for this local result.
  TaiyinEphemerisResult<TaiyinLocalSolarEclipseResult<TtScale>>
  solveLocalSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _withSolarContacts(_solarSolveMask(positionFlags, options));
    return _localSolarTt((output, diagnostic) {
      return _bindings.taiyin_solve_local_solar_eclipse_at_tt(
        _context,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Solves local solar-eclipse circumstances at the context observer.
  ///
  /// Contacts are always requested for this local result.
  TaiyinEphemerisResult<TaiyinLocalSolarEclipseResult<Ut1Scale>>
  solveLocalSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _withSolarContacts(_solarSolveMask(positionFlags, options));
    return _localSolarUt((output, diagnostic) {
      return _bindings.taiyin_solve_local_solar_eclipse_at_ut(
        _context,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next solar eclipse visible at the context observer.
  ///
  /// Contacts are always requested. Pass
  /// [TaiyinSolarEclipseSearchOption.backward] to search backwards.
  TaiyinEphemerisResult<TaiyinLocalSolarEclipseResult<TtScale>>
  nextLocalSolarAtTt(
    JulianDate<TtScale> start, {
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _withSolarContacts(
      _solarSearchMask(positionFlags, options, allowBackward: true),
    );
    return _localSolarTt((output, diagnostic) {
      return _bindings.taiyin_search_next_local_solar_eclipse_tt(
        _context,
        start.toDouble(),
        _solarKindMask(kinds),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next solar eclipse visible at the context observer.
  ///
  /// Contacts are always requested. Pass
  /// [TaiyinSolarEclipseSearchOption.backward] to search backwards.
  TaiyinEphemerisResult<TaiyinLocalSolarEclipseResult<Ut1Scale>>
  nextLocalSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<TaiyinEclipseKind> kinds = const {},
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinSolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _withSolarContacts(
      _solarSearchMask(positionFlags, options, allowBackward: true),
    );
    return _localSolarUt((output, diagnostic) {
      return _bindings.taiyin_search_next_local_solar_eclipse_ut(
        _context,
        start.toDouble(),
        _solarKindMask(kinds),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Calculates instantaneous local solar-eclipse geometry at [coordinate].
  TaiyinEphemerisResult<TaiyinLocalSolarEclipseCircumstances<TtScale>>
  localSolarCircumstancesAtTt(JulianDate<TtScale> coordinate) {
    _ensureOpen();
    return _solarCircumstancesTt((output, diagnostic) {
      return _bindings.taiyin_compute_local_solar_circumstances_tt(
        _context,
        coordinate.toDouble(),
        output,
        diagnostic,
      );
    });
  }

  /// Calculates instantaneous local solar-eclipse geometry at [coordinate].
  TaiyinEphemerisResult<TaiyinLocalSolarEclipseCircumstances<Ut1Scale>>
  localSolarCircumstancesAtUt1(JulianDate<Ut1Scale> coordinate) {
    _ensureOpen();
    return _solarCircumstancesUt((output, diagnostic) {
      return _bindings.taiyin_compute_local_solar_circumstances_ut(
        _context,
        coordinate.toDouble(),
        output,
        diagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinSolarEclipseResult<TtScale>> _solarTt(
    _SolarTtCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_eclipse_result_tt>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_eclipse_result_tt_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readSolarTt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinSolarEclipseResult<Ut1Scale>> _solarUt(
    _SolarUtCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_eclipse_result_ut>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_eclipse_result_ut_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readSolarUt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<List<TaiyinSolarEclipseResult<TtScale>>> _solarTtArray(
    int capacity,
    _SolarTtArrayCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_eclipse_result_tt>(capacity);
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      for (var index = 0; index < capacity; index++) {
        _bindings.taiyin_solar_eclipse_result_tt_init(output + index);
      }
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, capacity, count, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final resultCount = _validatedResultCount(count.value, capacity);
      return TaiyinEphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readSolarTt((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<List<TaiyinSolarEclipseResult<Ut1Scale>>> _solarUtArray(
    int capacity,
    _SolarUtArrayCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_eclipse_result_ut>(capacity);
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      for (var index = 0; index < capacity; index++) {
        _bindings.taiyin_solar_eclipse_result_ut_init(output + index);
      }
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, capacity, count, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final resultCount = _validatedResultCount(count.value, capacity);
      return TaiyinEphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readSolarUt((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLocalSolarEclipseResult<TtScale>> _localSolarTt(
    _LocalSolarTtCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_local_solar_eclipse_result_tt>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_local_solar_eclipse_result_tt_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readLocalSolarTt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLocalSolarEclipseResult<Ut1Scale>> _localSolarUt(
    _LocalSolarUtCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_local_solar_eclipse_result_ut>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_local_solar_eclipse_result_ut_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readLocalSolarUt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLocalSolarEclipseCircumstances<TtScale>>
  _solarCircumstancesTt(_SolarCircumstancesTtCalculation calculate) {
    return using((arena) {
      final output = arena<taiyin_local_solar_eclipse_circumstances_tt>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_local_solar_eclipse_circumstances_tt_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinLocalSolarEclipseCircumstances(
          coordinate: JulianDate<TtScale>.fromDouble(value.jd_tt),
          deltaTSeconds: null,
          magnitude: value.magnitude,
          obscuration: value.obscuration,
          centerSeparationDegrees: value.center_separation_deg,
          sunAngularRadiusDegrees: value.sun_angular_radius_deg,
          moonAngularRadiusDegrees: value.moon_angular_radius_deg,
          sunAltitudeDegrees: value.sun_altitude_deg,
          sunAzimuthDegrees: value.sun_azimuth_deg,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLocalSolarEclipseCircumstances<Ut1Scale>>
  _solarCircumstancesUt(_SolarCircumstancesUtCalculation calculate) {
    return using((arena) {
      final output = arena<taiyin_local_solar_eclipse_circumstances_ut>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_local_solar_eclipse_circumstances_ut_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinLocalSolarEclipseCircumstances(
          coordinate: JulianDate<Ut1Scale>.fromDouble(value.jd_ut),
          deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
          magnitude: value.magnitude,
          obscuration: value.obscuration,
          centerSeparationDegrees: value.center_separation_deg,
          sunAngularRadiusDegrees: value.sun_angular_radius_deg,
          moonAngularRadiusDegrees: value.moon_angular_radius_deg,
          sunAltitudeDegrees: value.sun_altitude_deg,
          sunAzimuthDegrees: value.sun_azimuth_deg,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinSolarEclipseResult<TtScale> _readSolarTt(
    taiyin_solar_eclipse_result_tt value,
  ) {
    return TaiyinSolarEclipseResult(
      kinds: TaiyinEclipseKind.fromMask(value.kind),
      maximum: _ttOrNull(value.maximum_jd_tt),
      deltaTSeconds: null,
      axisDistanceKilometers: _finiteOrNull(value.axis_distance_km),
      penumbraRadiusKilometers: _finiteOrNull(value.penumbra_radius_km),
      coreRadiusKilometers: _finiteOrNull(value.core_radius_km),
      penumbralMarginKilometers: _finiteOrNull(value.penumbral_margin_km),
      centralMarginKilometers: _finiteOrNull(value.central_margin_km),
      maximumLatitudeDegrees: _finiteOrNull(value.maximum_latitude_deg),
      maximumLongitudeDegrees: _finiteOrNull(value.maximum_longitude_deg),
      contacts: {
        for (final contact in TaiyinSolarEclipseContact.values)
          contact: _ttOrNull(value.contact_jd_tt[contact.nativeIndex]),
      },
    );
  }

  TaiyinSolarEclipseResult<Ut1Scale> _readSolarUt(
    taiyin_solar_eclipse_result_ut value,
  ) {
    return TaiyinSolarEclipseResult(
      kinds: TaiyinEclipseKind.fromMask(value.kind),
      maximum: _ut1OrNull(value.maximum_jd_ut),
      deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
      axisDistanceKilometers: _finiteOrNull(value.axis_distance_km),
      penumbraRadiusKilometers: _finiteOrNull(value.penumbra_radius_km),
      coreRadiusKilometers: _finiteOrNull(value.core_radius_km),
      penumbralMarginKilometers: _finiteOrNull(value.penumbral_margin_km),
      centralMarginKilometers: _finiteOrNull(value.central_margin_km),
      maximumLatitudeDegrees: _finiteOrNull(value.maximum_latitude_deg),
      maximumLongitudeDegrees: _finiteOrNull(value.maximum_longitude_deg),
      contacts: {
        for (final contact in TaiyinSolarEclipseContact.values)
          contact: _ut1OrNull(value.contact_jd_ut[contact.nativeIndex]),
      },
    );
  }

  TaiyinLocalSolarEclipseResult<TtScale> _readLocalSolarTt(
    taiyin_local_solar_eclipse_result_tt value,
  ) {
    return TaiyinLocalSolarEclipseResult(
      kinds: TaiyinEclipseKind.fromMask(value.kind),
      visibility: TaiyinLocalSolarEclipseVisibilityFlag.fromMask(value.kind),
      maximum: _ttOrNull(value.maximum_jd_tt),
      deltaTSeconds: null,
      magnitude: _finiteOrNull(value.magnitude),
      obscuration: _finiteOrNull(value.obscuration),
      sunAltitudeDegrees: _finiteOrNull(value.sun_altitude_deg),
      sunAzimuthDegrees: _finiteOrNull(value.sun_azimuth_deg),
      contacts: {
        for (final contact in TaiyinLocalSolarEclipseContact.values)
          contact: _ttOrNull(value.contact_jd_tt[contact.nativeIndex]),
      },
      positionAngleC1Degrees: _finiteOrNull(value.position_angle_c1_deg),
      positionAngleC4Degrees: _finiteOrNull(value.position_angle_c4_deg),
      vertexAngleC1Degrees: _finiteOrNull(value.vertex_angle_c1_deg),
      vertexAngleC4Degrees: _finiteOrNull(value.vertex_angle_c4_deg),
      sunriseMagnitude: _finiteOrNull(value.sunrise_magnitude),
      sunsetMagnitude: _finiteOrNull(value.sunset_magnitude),
      durationSeconds: _finiteOrNull(value.duration_seconds),
      moonSunRadiusRatio: _finiteOrNull(value.moon_sun_radius_ratio),
    );
  }

  TaiyinLocalSolarEclipseResult<Ut1Scale> _readLocalSolarUt(
    taiyin_local_solar_eclipse_result_ut value,
  ) {
    return TaiyinLocalSolarEclipseResult(
      kinds: TaiyinEclipseKind.fromMask(value.kind),
      visibility: TaiyinLocalSolarEclipseVisibilityFlag.fromMask(value.kind),
      maximum: _ut1OrNull(value.maximum_jd_ut),
      deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
      magnitude: _finiteOrNull(value.magnitude),
      obscuration: _finiteOrNull(value.obscuration),
      sunAltitudeDegrees: _finiteOrNull(value.sun_altitude_deg),
      sunAzimuthDegrees: _finiteOrNull(value.sun_azimuth_deg),
      contacts: {
        for (final contact in TaiyinLocalSolarEclipseContact.values)
          contact: _ut1OrNull(value.contact_jd_ut[contact.nativeIndex]),
      },
      positionAngleC1Degrees: _finiteOrNull(value.position_angle_c1_deg),
      positionAngleC4Degrees: _finiteOrNull(value.position_angle_c4_deg),
      vertexAngleC1Degrees: _finiteOrNull(value.vertex_angle_c1_deg),
      vertexAngleC4Degrees: _finiteOrNull(value.vertex_angle_c4_deg),
      sunriseMagnitude: _finiteOrNull(value.sunrise_magnitude),
      sunsetMagnitude: _finiteOrNull(value.sunset_magnitude),
      durationSeconds: _finiteOrNull(value.duration_seconds),
      moonSunRadiusRatio: _finiteOrNull(value.moon_sun_radius_ratio),
    );
  }

  int _solarSolveMask(
    Set<TaiyinPositionFlag> positionFlags,
    Set<TaiyinSolarEclipseSolveOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(0, (mask, option) => mask | option.mask),
    );
  }

  int _solarSearchMask(
    Set<TaiyinPositionFlag> positionFlags,
    Set<TaiyinSolarEclipseSearchOption> options, {
    required bool allowBackward,
  }) {
    _requireSupportedPositionFlags(positionFlags);
    if (!allowBackward &&
        options.contains(TaiyinSolarEclipseSearchOption.backward)) {
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

  int _withSolarContacts(int mask) =>
      mask | TaiyinSolarEclipseSolveOption.includeContacts.mask;

  int _solarKindMask(Set<TaiyinEclipseKind> kinds) {
    const supported = {
      TaiyinEclipseKind.partial,
      TaiyinEclipseKind.total,
      TaiyinEclipseKind.annular,
      TaiyinEclipseKind.hybrid,
    };
    final unsupported = kinds.difference(supported);
    if (unsupported.isNotEmpty) {
      throw ArgumentError.value(
        kinds,
        'kinds',
        'solar eclipses support only partial, total, annular, and hybrid '
            'filters',
      );
    }
    return _kindMask(kinds);
  }
}
