part of '../taiyin.dart';

typedef _EclipseStatusChecker =
    void Function(int status, EphemerisDiagnostic? diagnostic);
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
typedef _SolarRouteRowCalculation =
    int Function(
      Pointer<taiyin_solar_eclipse_route_row> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarRouteRowsCalculation =
    int Function(
      Pointer<taiyin_solar_eclipse_route_row> output,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarRouteCurvesCalculation =
    int Function(
      Pointer<taiyin_solar_eclipse_route_curve_point> output,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SolarRouteProductCalculation =
    int Function(
      Pointer<taiyin_solar_eclipse_route_product_point> output,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_solar_eclipse_route_product_summary> summary,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LocalSolarBoundaryCalculation =
    int Function(
      Pointer<taiyin_local_solar_eclipse_boundary> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );

// Shared by the solve and search C ABI option families. Local solar results
// always include contacts, regardless of the public option set supplied.
const _solarEclipseIncludeContactsBit = 1 << 33;
const _solarRouteDefaultSampleCount = 400;
const _solarRouteMinimumSampleCount = 32;
const _solarRouteMaximumSampleCount = 4096;

/// Calculates and searches lunar eclipses.
///
/// A local method samples the observer location already configured on the
/// owning [EphemerisContext]. Native calculation coordinates and contact times
/// cross the ABI-8 boundary as split Julian dates.
final class EclipseApi {
  EclipseApi._(
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
  EphemerisResult<LunarEclipseResult<TtScale>> solveLunarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solveMask(positionFlags, options);
    return using((arena) {
      final estimateJd = writeJulianDate(arena, estimate);
      return _lunarTt((output, diagnostic) {
        return _bindings.taiyin_solve_lunar_eclipse_at_tt(
          _context,
          estimateJd,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Solves the lunar-eclipse lunation nearest [estimate].
  EphemerisResult<LunarEclipseResult<Ut1Scale>> solveLunarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solveMask(positionFlags, options);
    return using((arena) {
      final estimateJd = writeJulianDate(arena, estimate);
      return _lunarUt((output, diagnostic) {
        return _bindings.taiyin_solve_lunar_eclipse_at_ut(
          _context,
          estimateJd,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next matching lunar eclipse from [start].
  EphemerisResult<LunarEclipseResult<TtScale>> nextLunarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: true);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      return _lunarTt((output, diagnostic) {
        return _bindings.taiyin_search_next_lunar_eclipse_tt(
          _context,
          startJd,
          kindMask,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next matching lunar eclipse from [start].
  ///
  /// Pass [LunarEclipseSearchOption.backward] to search backwards.
  EphemerisResult<LunarEclipseResult<Ut1Scale>> nextLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: true);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      return _lunarUt((output, diagnostic) {
        return _bindings.taiyin_search_next_lunar_eclipse_ut(
          _context,
          startJd,
          kindMask,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds all matching lunar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  ///
  /// Native code reports insufficient [maxResults] capacity as an error rather
  /// than silently dropping later eclipses.
  EphemerisResult<List<LunarEclipseResult<TtScale>>> lunarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: false);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      final endJd = writeJulianDate(arena, end);
      return _lunarTtArray(maxResults, (output, capacity, count, diagnostic) {
        return _bindings.taiyin_search_lunar_eclipses_tt(
          _context,
          startJd,
          endJd,
          kindMask,
          mask,
          output,
          capacity,
          count,
          diagnostic,
        );
      });
    });
  }

  /// Finds all matching lunar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  EphemerisResult<List<LunarEclipseResult<Ut1Scale>>> lunarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: false);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      final endJd = writeJulianDate(arena, end);
      return _lunarUtArray(maxResults, (output, capacity, count, diagnostic) {
        return _bindings.taiyin_search_lunar_eclipses_ut(
          _context,
          startJd,
          endJd,
          kindMask,
          mask,
          output,
          capacity,
          count,
          diagnostic,
        );
      });
    });
  }

  /// Derives local visibility for a TT global [eclipse].
  ///
  /// The context must have a geographic observer. A non-empty eclipse must
  /// include contact data, so search with `includeContacts` before calling.
  EphemerisResult<LocalLunarEclipseResult<TtScale>> localLunarVisibilityAtTt(
    LunarEclipseResult<TtScale> eclipse, {
    Set<LocalLunarEclipseVisibilityOption> options = const {},
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
  EphemerisResult<LocalLunarEclipseResult<Ut1Scale>> localLunarVisibilityAtUt1(
    LunarEclipseResult<Ut1Scale> eclipse, {
    Set<LocalLunarEclipseVisibilityOption> options = const {},
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
  EphemerisResult<LocalLunarEclipseResult<TtScale>> nextLocalLunarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
    Set<LocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    final kindMask = _lunarKindMask(kinds);
    final mask = _mergeDisjointMasks(
      _searchMask(positionFlags, options, allowBackward: true),
      _localVisibilityMask(visibilityOptions),
    );
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      return _localLunarTt((output, diagnostic) {
        return _bindings.taiyin_search_next_local_lunar_eclipse_tt(
          _context,
          startJd,
          kindMask,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next matching lunar eclipse and its visibility at the context
  /// observer.
  EphemerisResult<LocalLunarEclipseResult<Ut1Scale>> nextLocalLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
    Set<LocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    final kindMask = _lunarKindMask(kinds);
    final mask = _mergeDisjointMasks(
      _searchMask(positionFlags, options, allowBackward: true),
      _localVisibilityMask(visibilityOptions),
    );
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      return _localLunarUt((output, diagnostic) {
        return _bindings.taiyin_search_next_local_lunar_eclipse_ut(
          _context,
          startJd,
          kindMask,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  EphemerisResult<LunarEclipseResult<TtScale>> _lunarTt(
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
      return EphemerisResult(
        value: _readLunarTt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<LunarEclipseResult<Ut1Scale>> _lunarUt(
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
      return EphemerisResult(
        value: _readLunarUt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<List<LunarEclipseResult<TtScale>>> _lunarTtArray(
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
      return EphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readLunarTt((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<List<LunarEclipseResult<Ut1Scale>>> _lunarUtArray(
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
      return EphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readLunarUt((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<LocalLunarEclipseResult<TtScale>> _localLunarTt(
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
      return EphemerisResult(
        value: _readLocalLunarTt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<LocalLunarEclipseResult<Ut1Scale>> _localLunarUt(
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
      return EphemerisResult(
        value: _readLocalLunarUt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  LunarEclipseResult<TtScale> _readLunarTt(
    taiyin_lunar_eclipse_result_tt value,
  ) {
    return LunarEclipseResult(
      kinds: EclipseKind.fromMask(value.kind),
      maximum: _ttOrNull(value.maximum_jd_tt),
      deltaTSeconds: null,
      umbralMagnitude: _finiteOrNull(value.umbral_magnitude),
      penumbralMagnitude: _finiteOrNull(value.penumbral_magnitude),
      axisDistanceRadians: _finiteOrNull(value.axis_distance_rad),
      umbraRadiusRadians: _finiteOrNull(value.umbra_radius_rad),
      penumbraRadiusRadians: _finiteOrNull(value.penumbra_radius_rad),
      moonRadiusRadians: _finiteOrNull(value.moon_radius_rad),
      contacts: {
        for (final contact in LunarEclipseContact.values)
          contact: _ttOrNull(value.contact_jd_tt[contact.nativeIndex]),
      },
    );
  }

  LunarEclipseResult<Ut1Scale> _readLunarUt(
    taiyin_lunar_eclipse_result_ut value,
  ) {
    return LunarEclipseResult(
      kinds: EclipseKind.fromMask(value.kind),
      maximum: _ut1OrNull(value.maximum_jd_ut),
      deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
      umbralMagnitude: _finiteOrNull(value.umbral_magnitude),
      penumbralMagnitude: _finiteOrNull(value.penumbral_magnitude),
      axisDistanceRadians: _finiteOrNull(value.axis_distance_rad),
      umbraRadiusRadians: _finiteOrNull(value.umbra_radius_rad),
      penumbraRadiusRadians: _finiteOrNull(value.penumbra_radius_rad),
      moonRadiusRadians: _finiteOrNull(value.moon_radius_rad),
      contacts: {
        for (final contact in LunarEclipseContact.values)
          contact: _ut1OrNull(value.contact_jd_ut[contact.nativeIndex]),
      },
    );
  }

  LocalLunarEclipseResult<TtScale> _readLocalLunarTt(
    taiyin_local_lunar_eclipse_result_tt value,
  ) {
    return LocalLunarEclipseResult(
      kinds: EclipseKind.fromMask(value.eclipse_kind),
      visibility: LocalLunarEclipseVisibilityFlag.fromMask(
        value.visibility_flags,
      ),
      maximum: _ttOrNull(value.maximum_jd_tt),
      deltaTSeconds: null,
      umbralMagnitude: _finiteOrNull(value.umbral_magnitude),
      penumbralMagnitude: _finiteOrNull(value.penumbral_magnitude),
      contacts: {
        for (final contact in LunarEclipseContact.values)
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

  LocalLunarEclipseResult<Ut1Scale> _readLocalLunarUt(
    taiyin_local_lunar_eclipse_result_ut value,
  ) {
    return LocalLunarEclipseResult(
      kinds: EclipseKind.fromMask(value.eclipse_kind),
      visibility: LocalLunarEclipseVisibilityFlag.fromMask(
        value.visibility_flags,
      ),
      maximum: _ut1OrNull(value.maximum_jd_ut),
      deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
      umbralMagnitude: _finiteOrNull(value.umbral_magnitude),
      penumbralMagnitude: _finiteOrNull(value.penumbral_magnitude),
      contacts: {
        for (final contact in LunarEclipseContact.values)
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

  LocalLunarEclipseContact<S>? _readLocalContact<S extends TimeScale>(
    JulianDate<S>? coordinate,
    double altitudeDegrees,
    double azimuthDegrees,
  ) {
    if (coordinate == null) return null;
    return LocalLunarEclipseContact(
      coordinate: coordinate,
      moonAltitudeDegrees: _finiteOrNull(altitudeDegrees),
      moonAzimuthDegrees: _finiteOrNull(azimuthDegrees),
    );
  }

  /// Writes an optional Julian date into a split C ABI struct value, using the
  /// native NaN day-fraction sentinel for the null case.
  taiyin_split_julian_date _writeJdOrInvalid<S extends TimeScale>(
    Arena arena,
    JulianDate<S>? value,
  ) {
    if (value == null) {
      final invalid = arena<taiyin_split_julian_date>();
      invalid.ref
        ..day_number = 0
        ..day_fraction = double.nan;
      return invalid.ref;
    }
    return writeJulianDate(arena, value).ref;
  }

  /// Returns a pointer to the final field of [struct] when that field is an
  /// array of [elementCount] split Julian dates.
  ///
  /// dart:ffi exposes no `[]=` operator on `Array<Struct>`, so array elements
  /// are populated through an indexed pointer derived from the struct layout.
  Pointer<taiyin_split_julian_date> _lastJdArrayPointer<S extends Struct>(
    Pointer<S> struct,
    int structSize,
    int elementCount,
  ) {
    final offset =
        structSize - elementCount * sizeOf<taiyin_split_julian_date>();
    return (struct.cast<Uint8>() + offset).cast<taiyin_split_julian_date>();
  }

  Pointer<taiyin_lunar_eclipse_result_tt> _writeLunarTt(
    Arena arena,
    LunarEclipseResult<TtScale> value,
  ) {
    final output = arena<taiyin_lunar_eclipse_result_tt>();
    _bindings.taiyin_lunar_eclipse_result_tt_init(output);
    output.ref
      ..kind = _kindMask(value.kinds)
      ..maximum_jd_tt = _writeJdOrInvalid(arena, value.maximum)
      ..umbral_magnitude = value.umbralMagnitude ?? double.nan
      ..penumbral_magnitude = value.penumbralMagnitude ?? double.nan
      ..axis_distance_rad = value.axisDistanceRadians ?? double.nan
      ..umbra_radius_rad = value.umbraRadiusRadians ?? double.nan
      ..penumbra_radius_rad = value.penumbraRadiusRadians ?? double.nan
      ..moon_radius_rad = value.moonRadiusRadians ?? double.nan;
    final contactJd = _lastJdArrayPointer(
      output,
      sizeOf<taiyin_lunar_eclipse_result_tt>(),
      LunarEclipseContact.values.length,
    );
    for (final contact in LunarEclipseContact.values) {
      contactJd[contact.nativeIndex] = _writeJdOrInvalid(
        arena,
        value.contacts[contact],
      );
    }
    return output;
  }

  Pointer<taiyin_lunar_eclipse_result_ut> _writeLunarUt(
    Arena arena,
    LunarEclipseResult<Ut1Scale> value,
  ) {
    final output = arena<taiyin_lunar_eclipse_result_ut>();
    _bindings.taiyin_lunar_eclipse_result_ut_init(output);
    output.ref
      ..kind = _kindMask(value.kinds)
      ..maximum_jd_ut = _writeJdOrInvalid(arena, value.maximum)
      ..delta_t_seconds = value.deltaTSeconds ?? double.nan
      ..umbral_magnitude = value.umbralMagnitude ?? double.nan
      ..penumbral_magnitude = value.penumbralMagnitude ?? double.nan
      ..axis_distance_rad = value.axisDistanceRadians ?? double.nan
      ..umbra_radius_rad = value.umbraRadiusRadians ?? double.nan
      ..penumbra_radius_rad = value.penumbraRadiusRadians ?? double.nan
      ..moon_radius_rad = value.moonRadiusRadians ?? double.nan;
    final contactJd = _lastJdArrayPointer(
      output,
      sizeOf<taiyin_lunar_eclipse_result_ut>(),
      LunarEclipseContact.values.length,
    );
    for (final contact in LunarEclipseContact.values) {
      contactJd[contact.nativeIndex] = _writeJdOrInvalid(
        arena,
        value.contacts[contact],
      );
    }
    return output;
  }

  int _solveMask(
    Set<PositionFlag> positionFlags,
    Set<LunarEclipseSolveOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(0, (mask, option) => mask | option.mask),
    );
  }

  int _searchMask(
    Set<PositionFlag> positionFlags,
    Set<LunarEclipseSearchOption> options, {
    required bool allowBackward,
  }) {
    _requireSupportedPositionFlags(positionFlags);
    if (!allowBackward && options.contains(LunarEclipseSearchOption.backward)) {
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

  int _localVisibilityMask(Set<LocalLunarEclipseVisibilityOption> options) {
    return options.fold(0, (mask, option) => mask | option.mask);
  }

  int _localSolarVisibilityMask(
    Set<LocalSolarEclipseVisibilityOption> options,
  ) {
    if (options.contains(LocalSolarEclipseVisibilityOption.strictMeteorology) &&
        !options.contains(LocalSolarEclipseVisibilityOption.refraction)) {
      throw ArgumentError.value(
        options,
        'visibilityOptions',
        'strictMeteorology is valid only together with refraction',
      );
    }
    return options.fold(0, (mask, option) => mask | option.mask);
  }

  int _positionMask(Set<PositionFlag> positionFlags) {
    return positionFlags.fold(0, (mask, flag) => mask | flag.mask);
  }

  int _mergeDisjointMasks(int maskA, int maskB) {
    assert((maskA & maskB) == 0, 'Eclipse mask fields overlap');
    return maskA | maskB;
  }

  int _lunarKindMask(Set<EclipseKind> kinds) {
    const supported = {
      EclipseKind.penumbral,
      EclipseKind.partial,
      EclipseKind.total,
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

  int _kindMask(Set<EclipseKind> kinds) {
    return kinds.fold(0, (mask, kind) => mask | kind.mask);
  }

  void _requireSupportedPositionFlags(Set<PositionFlag> flags) {
    const supported = {PositionFlag.truePosition};
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
    LunarEclipseResult<S> eclipse,
  ) {
    if (!eclipse.hasEclipse) return;
    final greatest = eclipse.contacts[LunarEclipseContact.greatest];
    final contactCount = eclipse.contacts.values
        .whereType<JulianDate<S>>()
        .length;
    if (greatest == null || contactCount < 2) {
      throw ArgumentError.value(
        eclipse,
        'eclipse',
        'must include a greatest and at least one other contact; search with '
            'LunarEclipseSearchOption.includeContacts',
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

  void _requireCapacity(int capacity, {String name = 'maxResults'}) {
    if (capacity <= 0) {
      throw RangeError.range(capacity, 1, null, name);
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

  JulianDate<TtScale>? _ttOrNull(taiyin_split_julian_date value) {
    return value.day_fraction.isFinite ? readJulianDate<TtScale>(value) : null;
  }

  JulianDate<Ut1Scale>? _ut1OrNull(taiyin_split_julian_date value) {
    return value.day_fraction.isFinite ? readJulianDate<Ut1Scale>(value) : null;
  }

  JulianDate<TtScale> _requireTtRouteCoordinate(
    taiyin_split_julian_date value,
    String name,
  ) {
    if (!value.day_fraction.isFinite) {
      throw StateError(
        'Native solar eclipse route calculation returned non-finite $name '
        'after a successful calculation',
      );
    }
    return readJulianDate<TtScale>(value);
  }

  JulianDate<Ut1Scale> _requireUt1RouteCoordinate(
    taiyin_split_julian_date value,
    String name,
  ) {
    if (!value.day_fraction.isFinite) {
      throw StateError(
        'Native solar eclipse route calculation returned non-finite $name '
        'after a successful calculation',
      );
    }
    return readJulianDate<Ut1Scale>(value);
  }

  double? _finiteOrNull(double value) => value.isFinite ? value : null;

  /// Solves the solar-eclipse lunation nearest [estimate].
  EphemerisResult<SolarEclipseResult<TtScale>> solveSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarSolveMask(positionFlags, options);
    return using((arena) {
      final estimateJd = writeJulianDate(arena, estimate);
      return _solarTt((output, diagnostic) {
        return _bindings.taiyin_solve_solar_eclipse_at_tt(
          _context,
          estimateJd,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Solves the solar-eclipse lunation nearest [estimate].
  EphemerisResult<SolarEclipseResult<Ut1Scale>> solveSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarSolveMask(positionFlags, options);
    return using((arena) {
      final estimateJd = writeJulianDate(arena, estimate);
      return _solarUt((output, diagnostic) {
        return _bindings.taiyin_solve_solar_eclipse_at_ut(
          _context,
          estimateJd,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next matching global solar eclipse from [start].
  EphemerisResult<SolarEclipseResult<TtScale>> nextSolarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarSearchMask(positionFlags, options, allowBackward: true);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      return _solarTt((output, diagnostic) {
        return _bindings.taiyin_search_next_solar_eclipse_tt(
          _context,
          startJd,
          _solarKindMask(kinds),
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next matching global solar eclipse from [start].
  ///
  /// Pass [SolarEclipseSearchOption.backward] to search backwards.
  EphemerisResult<SolarEclipseResult<Ut1Scale>> nextSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarSearchMask(positionFlags, options, allowBackward: true);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      return _solarUt((output, diagnostic) {
        return _bindings.taiyin_search_next_solar_eclipse_ut(
          _context,
          startJd,
          _solarKindMask(kinds),
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds all matching solar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  EphemerisResult<List<SolarEclipseResult<TtScale>>> solarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final mask = _solarSearchMask(positionFlags, options, allowBackward: false);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      final endJd = writeJulianDate(arena, end);
      return _solarTtArray(maxResults, (output, capacity, count, diagnostic) {
        return _bindings.taiyin_search_solar_eclipses_tt(
          _context,
          startJd,
          endJd,
          _solarKindMask(kinds),
          mask,
          output,
          capacity,
          count,
          diagnostic,
        );
      });
    });
  }

  /// Finds all matching solar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  EphemerisResult<List<SolarEclipseResult<Ut1Scale>>> solarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final mask = _solarSearchMask(positionFlags, options, allowBackward: false);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      final endJd = writeJulianDate(arena, end);
      return _solarUtArray(maxResults, (output, capacity, count, diagnostic) {
        return _bindings.taiyin_search_solar_eclipses_ut(
          _context,
          startJd,
          endJd,
          _solarKindMask(kinds),
          mask,
          output,
          capacity,
          count,
          diagnostic,
        );
      });
    });
  }

  /// Solves local solar-eclipse circumstances at the context observer.
  ///
  /// A geographic observer location must be configured on the context.
  ///
  /// Contacts are always requested for this local result.
  EphemerisResult<LocalSolarEclipseResult<TtScale>> solveLocalSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    final mask = _withSolarContacts(
      _mergeDisjointMasks(
        _solarSolveMask(positionFlags, options),
        _localSolarVisibilityMask(visibilityOptions),
      ),
    );
    return using((arena) {
      final estimateJd = writeJulianDate(arena, estimate);
      return _localSolarTt((output, diagnostic) {
        return _bindings.taiyin_solve_local_solar_eclipse_at_tt(
          _context,
          estimateJd,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Solves local solar-eclipse circumstances at the context observer.
  ///
  /// A geographic observer location must be configured on the context.
  ///
  /// Contacts are always requested for this local result.
  EphemerisResult<LocalSolarEclipseResult<Ut1Scale>> solveLocalSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    final mask = _withSolarContacts(
      _mergeDisjointMasks(
        _solarSolveMask(positionFlags, options),
        _localSolarVisibilityMask(visibilityOptions),
      ),
    );
    return using((arena) {
      final estimateJd = writeJulianDate(arena, estimate);
      return _localSolarUt((output, diagnostic) {
        return _bindings.taiyin_solve_local_solar_eclipse_at_ut(
          _context,
          estimateJd,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next solar eclipse visible at the context observer.
  ///
  /// A geographic observer location must be configured on the context.
  ///
  /// Contacts are always requested. Pass
  /// [SolarEclipseSearchOption.backward] to search backwards.
  EphemerisResult<LocalSolarEclipseResult<TtScale>> nextLocalSolarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    final mask = _withSolarContacts(
      _mergeDisjointMasks(
        _solarSearchMask(positionFlags, options, allowBackward: true),
        _localSolarVisibilityMask(visibilityOptions),
      ),
    );
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      return _localSolarTt((output, diagnostic) {
        return _bindings.taiyin_search_next_local_solar_eclipse_tt(
          _context,
          startJd,
          _solarKindMask(kinds),
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next solar eclipse visible at the context observer.
  ///
  /// A geographic observer location must be configured on the context.
  ///
  /// Contacts are always requested. Pass
  /// [SolarEclipseSearchOption.backward] to search backwards.
  EphemerisResult<LocalSolarEclipseResult<Ut1Scale>> nextLocalSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    final mask = _withSolarContacts(
      _mergeDisjointMasks(
        _solarSearchMask(positionFlags, options, allowBackward: true),
        _localSolarVisibilityMask(visibilityOptions),
      ),
    );
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      return _localSolarUt((output, diagnostic) {
        return _bindings.taiyin_search_next_local_solar_eclipse_ut(
          _context,
          startJd,
          _solarKindMask(kinds),
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Calculates instantaneous local solar-eclipse geometry at [coordinate].
  ///
  /// A geographic observer location must be configured on the context.
  EphemerisResult<LocalSolarEclipseCircumstances<TtScale>>
  localSolarCircumstancesAtTt(JulianDate<TtScale> coordinate) {
    _ensureOpen();
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarCircumstancesTt((output, diagnostic) {
        return _bindings.taiyin_compute_local_solar_circumstances_tt(
          _context,
          coordinateJd,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Calculates instantaneous local solar-eclipse geometry at [coordinate].
  ///
  /// A geographic observer location must be configured on the context.
  EphemerisResult<LocalSolarEclipseCircumstances<Ut1Scale>>
  localSolarCircumstancesAtUt1(JulianDate<Ut1Scale> coordinate) {
    _ensureOpen();
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarCircumstancesUt((output, diagnostic) {
        return _bindings.taiyin_compute_local_solar_circumstances_ut(
          _context,
          coordinateJd,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Computes Besselian elements at a TT [coordinate].
  ///
  /// [timeOffsetHours] is retained as the conventional Besselian time offset
  /// in the returned value. The physical calculation crosses the current
  /// scalar-Julian-date C ABI boundary.
  EphemerisResult<SolarBesselianElements> solarBesselianElementsAtTt(
    JulianDate<TtScale> coordinate, {
    double timeOffsetHours = 0,
  }) {
    _ensureOpen();
    _requireFinite(timeOffsetHours, 'timeOffsetHours');
    return using((arena) {
      final output = arena<taiyin_solar_besselian_elements>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_besselian_elements_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_compute_solar_besselian_elements_tt(
        _context,
        writeJulianDate(arena, coordinate),
        timeOffsetHours,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return EphemerisResult(
        value: _readSolarBesselianElements(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Fits a Besselian polynomial centred on a TT [coordinate].
  ///
  /// [spanHours] and [sampleStepHours] must be positive. The native model
  /// permits polynomial [degree] values from 1 through 7.
  EphemerisResult<SolarBesselianPolynomial> solarBesselianPolynomialAtTt(
    JulianDate<TtScale> coordinate, {
    required double spanHours,
    required double sampleStepHours,
    int degree = 4,
  }) {
    _ensureOpen();
    _requirePositiveFinite(spanHours, 'spanHours');
    _requirePositiveFinite(sampleStepHours, 'sampleStepHours');
    _requireBesselianDegree(degree);
    return using((arena) {
      final output = arena<taiyin_solar_besselian_polynomial>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_besselian_polynomial_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_compute_solar_besselian_polynomial_tt(
        _context,
        writeJulianDate(arena, coordinate),
        spanHours,
        sampleStepHours,
        degree,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return EphemerisResult(
        value: _readSolarBesselianPolynomial(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Evaluates a fitted solar Besselian [polynomial] at [timeOffsetHours].
  ///
  /// [timeOffsetHours] is relative to [SolarBesselianPolynomial.referenceEpoch].
  SolarBesselianElements evaluateSolarBesselianPolynomial(
    SolarBesselianPolynomial polynomial,
    double timeOffsetHours,
  ) {
    _ensureOpen();
    _requireFinite(timeOffsetHours, 'timeOffsetHours');
    return using((arena) {
      final nativePolynomial = arena<taiyin_solar_besselian_polynomial>();
      final output = arena<taiyin_solar_besselian_elements>();
      _bindings
        ..taiyin_solar_besselian_polynomial_init(nativePolynomial)
        ..taiyin_solar_besselian_elements_init(output);
      _writeSolarBesselianPolynomial(arena, nativePolynomial.ref, polynomial);
      _checkStatus(
        _bindings.taiyin_evaluate_solar_besselian_polynomial(
          nativePolynomial,
          timeOffsetHours,
          output,
        ),
        null,
      );
      return _readSolarBesselianElements(output.ref);
    });
  }

  /// Calculates the global solar-eclipse route geometry at TT [coordinate].
  ///
  /// Only [PositionFlag.truePosition] and
  /// [SolarEclipseRouteOption.lunarLimbCorrection] are supported.
  EphemerisResult<SolarEclipseRouteRow> solarEclipseRouteRowAtTt(
    JulianDate<TtScale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarRouteRow((output, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_row_tt(
          _context,
          coordinateJd,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Calculates the global solar-eclipse route geometry at UT1 [coordinate].
  ///
  /// Only [PositionFlag.truePosition] and
  /// [SolarEclipseRouteOption.lunarLimbCorrection] are supported.
  EphemerisResult<SolarEclipseRouteRow> solarEclipseRouteRowAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarRouteRow((output, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_row_ut(
          _context,
          coordinateJd,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Calculates lightweight instantaneous global solar-eclipse geometry at TT
  /// [coordinate].
  ///
  /// Only [PositionFlag.truePosition] and
  /// [SolarEclipseRouteOption.lunarLimbCorrection] are supported.
  EphemerisResult<SolarEclipseWhere> solarEclipseWhereAtTt(
    JulianDate<TtScale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      final output = arena<taiyin_solar_eclipse_where>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_solar_eclipse_where_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_compute_solar_eclipse_where_tt(
        _context,
        coordinateJd,
        mask,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return EphemerisResult(
        value: _readSolarEclipseWhere(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Calculates lightweight instantaneous global solar-eclipse geometry at
  /// UT1 [coordinate].
  ///
  /// Only [PositionFlag.truePosition] and
  /// [SolarEclipseRouteOption.lunarLimbCorrection] are supported.
  EphemerisResult<SolarEclipseWhere> solarEclipseWhereAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      final output = arena<taiyin_solar_eclipse_where>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_solar_eclipse_where_init(output);
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_compute_solar_eclipse_where_ut(
        _context,
        coordinateJd,
        mask,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return EphemerisResult(
        value: _readSolarEclipseWhere(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Samples global solar-eclipse route geometry from TT [start] through [end].
  ///
  /// Both endpoints are included when they land on [stepMinutes]. The range
  /// may contain one coordinate. Rows with no Earth-intersecting route branch
  /// are omitted by native code.
  EphemerisResult<List<SolarEclipseRouteRow>> solarEclipseRouteAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double stepMinutes,
    int maxRows = 256,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    _requireRouteInterval(start, end);
    _requirePositiveFinite(stepMinutes, 'stepMinutes');
    _requireCapacity(maxRows, name: 'maxRows');
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      final endJd = writeJulianDate(arena, end);
      return _solarRouteRows(maxRows, (output, capacity, count, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_tt(
          _context,
          startJd,
          endJd,
          stepMinutes,
          mask,
          output,
          capacity,
          count,
          diagnostic,
        );
      });
    });
  }

  /// Samples global solar-eclipse route geometry from UT1 [start] through [end].
  ///
  /// Both endpoints are included when they land on [stepMinutes]. The range
  /// may contain one coordinate. Rows with no Earth-intersecting route branch
  /// are omitted by native code.
  EphemerisResult<List<SolarEclipseRouteRow>> solarEclipseRouteAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double stepMinutes,
    int maxRows = 256,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    _requireRouteInterval(start, end);
    _requirePositiveFinite(stepMinutes, 'stepMinutes');
    _requireCapacity(maxRows, name: 'maxRows');
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final startJd = writeJulianDate(arena, start);
      final endJd = writeJulianDate(arena, end);
      return _solarRouteRows(maxRows, (output, capacity, count, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_ut(
          _context,
          startJd,
          endJd,
          stepMinutes,
          mask,
          output,
          capacity,
          count,
          diagnostic,
        );
      });
    });
  }

  /// Computes the complete time-tagged solar-eclipse map curves near TT
  /// [coordinate].
  ///
  /// [routeSampleCount] controls the sampling density for every curve and
  /// must be between 32 and 4096. Points are grouped by curve kind.
  EphemerisResult<List<SolarEclipseRouteCurvePoint>>
  solarEclipseRouteCurvesAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarRouteCurves((output, capacity, count, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_curves_tt(
          _context,
          coordinateJd,
          mask,
          routeSampleCount,
          output,
          capacity,
          count,
          diagnostic,
        );
      });
    });
  }

  /// Computes the complete time-tagged solar-eclipse map curves near UT1
  /// [coordinate].
  EphemerisResult<List<SolarEclipseRouteCurvePoint>>
  solarEclipseRouteCurvesAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarRouteCurves((output, capacity, count, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_curves_ut(
          _context,
          coordinateJd,
          mask,
          routeSampleCount,
          output,
          capacity,
          count,
          diagnostic,
        );
      });
    });
  }

  /// Builds the core-path polygon of the solar eclipse near TT [coordinate].
  ///
  /// Use [solarEclipseRouteMapProductAtTt] when penumbral and half-magnitude
  /// polygons are also required.
  EphemerisResult<SolarEclipseRouteProduct> solarEclipseRouteProductAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarRouteProduct((output, capacity, count, summary, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_product_tt(
          _context,
          coordinateJd,
          mask,
          routeSampleCount,
          output,
          capacity,
          count,
          summary,
          diagnostic,
        );
      });
    });
  }

  /// Builds the core-path polygon of the solar eclipse near UT1 [coordinate].
  ///
  /// Use [solarEclipseRouteMapProductAtUt1] when penumbral and half-magnitude
  /// polygons are also required.
  EphemerisResult<SolarEclipseRouteProduct> solarEclipseRouteProductAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarRouteProduct((output, capacity, count, summary, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_product_ut(
          _context,
          coordinateJd,
          mask,
          routeSampleCount,
          output,
          capacity,
          count,
          summary,
          diagnostic,
        );
      });
    });
  }

  /// Builds all available solar-eclipse map polygons near TT [coordinate].
  ///
  /// The returned point sequence contains the core, penumbral, and
  /// half-magnitude polygons in that order when those layers exist.
  EphemerisResult<SolarEclipseRouteProduct> solarEclipseRouteMapProductAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarRouteProduct((output, capacity, count, summary, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_map_product_tt(
          _context,
          coordinateJd,
          mask,
          routeSampleCount,
          output,
          capacity,
          count,
          summary,
          diagnostic,
        );
      });
    });
  }

  /// Builds all available solar-eclipse map polygons near UT1 [coordinate].
  EphemerisResult<SolarEclipseRouteProduct> solarEclipseRouteMapProductAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _solarRouteProduct((output, capacity, count, summary, diagnostic) {
        return _bindings.taiyin_compute_solar_eclipse_route_map_product_ut(
          _context,
          coordinateJd,
          mask,
          routeSampleCount,
          output,
          capacity,
          count,
          summary,
          diagnostic,
        );
      });
    });
  }

  /// Computes the local Earth intersections of the solar shadow at TT
  /// [coordinate].
  ///
  /// [longitudeDegrees] and [latitudeDegrees] select the reference location
  /// used to resolve the central-path kind; they do not need to match the
  /// context observer.
  EphemerisResult<LocalSolarEclipseBoundary> localSolarEclipseBoundaryAtTt(
    JulianDate<TtScale> coordinate, {
    required double longitudeDegrees,
    required double latitudeDegrees,
  }) {
    _ensureOpen();
    _requireFinite(longitudeDegrees, 'longitudeDegrees');
    _requireBoundaryLatitude(latitudeDegrees);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _localSolarBoundary((output, diagnostic) {
        return _bindings.taiyin_compute_local_solar_eclipse_boundary_tt(
          _context,
          coordinateJd,
          longitudeDegrees,
          latitudeDegrees,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Computes the local Earth intersections of the solar shadow at UT1
  /// [coordinate].
  EphemerisResult<LocalSolarEclipseBoundary> localSolarEclipseBoundaryAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    required double longitudeDegrees,
    required double latitudeDegrees,
  }) {
    _ensureOpen();
    _requireFinite(longitudeDegrees, 'longitudeDegrees');
    _requireBoundaryLatitude(latitudeDegrees);
    return using((arena) {
      final coordinateJd = writeJulianDate(arena, coordinate);
      return _localSolarBoundary((output, diagnostic) {
        return _bindings.taiyin_compute_local_solar_eclipse_boundary_ut(
          _context,
          coordinateJd,
          longitudeDegrees,
          latitudeDegrees,
          output,
          diagnostic,
        );
      });
    });
  }

  EphemerisResult<SolarEclipseResult<TtScale>> _solarTt(
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
      return EphemerisResult(
        value: _readSolarTt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<SolarEclipseResult<Ut1Scale>> _solarUt(
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
      return EphemerisResult(
        value: _readSolarUt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<List<SolarEclipseResult<TtScale>>> _solarTtArray(
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
      return EphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readSolarTt((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<List<SolarEclipseResult<Ut1Scale>>> _solarUtArray(
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
      return EphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readSolarUt((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<SolarEclipseRouteRow> _solarRouteRow(
    _SolarRouteRowCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_eclipse_route_row>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_eclipse_route_row_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return EphemerisResult(
        value: _readSolarEclipseRouteRow(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<List<SolarEclipseRouteRow>> _solarRouteRows(
    int capacity,
    _SolarRouteRowsCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_eclipse_route_row>(capacity);
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      for (var index = 0; index < capacity; index++) {
        _bindings.taiyin_solar_eclipse_route_row_init(output + index);
      }
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, capacity, count, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final resultCount = _validatedResultCount(count.value, capacity);
      return EphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < resultCount; index++)
            _readSolarEclipseRouteRow((output + index).ref),
        ]),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<List<SolarEclipseRouteCurvePoint>> _solarRouteCurves(
    _SolarRouteCurvesCalculation calculate,
  ) {
    return using((arena) {
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final countStatus = calculate(nullptr, 0, count, diagnostic);
      final countDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(countStatus, countDiagnostic);
      final requiredCount = count.value;
      if (requiredCount < 0) {
        throw StateError(
          'Native solar eclipse route returned a negative curve count',
        );
      }
      if (requiredCount == 0) {
        return EphemerisResult(
          value: const <SolarEclipseRouteCurvePoint>[],
          diagnostic: countDiagnostic,
        );
      }

      final output = arena<taiyin_solar_eclipse_route_curve_point>(
        requiredCount,
      );
      for (var index = 0; index < requiredCount; index++) {
        output[index].struct_size = 0;
      }
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final fillStatus = calculate(output, requiredCount, count, diagnostic);
      final fillDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(fillStatus, fillDiagnostic);
      _requireExactNativeCount(
        count.value,
        requiredCount,
        'solar eclipse route curve',
      );
      return EphemerisResult(
        value: List.unmodifiable([
          for (var index = 0; index < requiredCount; index++)
            _readSolarEclipseRouteCurvePoint(output[index]),
        ]),
        diagnostic: fillDiagnostic,
      );
    });
  }

  EphemerisResult<SolarEclipseRouteProduct> _solarRouteProduct(
    _SolarRouteProductCalculation calculate,
  ) {
    return using((arena) {
      final count = arena<Size>();
      final summary = arena<taiyin_solar_eclipse_route_product_summary>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_eclipse_route_product_summary_init(summary)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final countStatus = calculate(nullptr, 0, count, summary, diagnostic);
      final countDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(countStatus, countDiagnostic);
      final requiredCount = count.value;
      if (requiredCount < 0) {
        throw StateError(
          'Native solar eclipse route returned a negative product count',
        );
      }
      if (requiredCount == 0) {
        return EphemerisResult(
          value: SolarEclipseRouteProduct(
            points: const <SolarEclipseRouteProductPoint>[],
            summary: _readSolarEclipseRouteProductSummary(summary.ref),
          ),
          diagnostic: countDiagnostic,
        );
      }

      final output = arena<taiyin_solar_eclipse_route_product_point>(
        requiredCount,
      );
      for (var index = 0; index < requiredCount; index++) {
        output[index].struct_size = 0;
      }
      _bindings
        ..taiyin_solar_eclipse_route_product_summary_init(summary)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final fillStatus = calculate(
        output,
        requiredCount,
        count,
        summary,
        diagnostic,
      );
      final fillDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(fillStatus, fillDiagnostic);
      _requireExactNativeCount(
        count.value,
        requiredCount,
        'solar eclipse route product',
      );
      return EphemerisResult(
        value: SolarEclipseRouteProduct(
          points: [
            for (var index = 0; index < requiredCount; index++)
              _readSolarEclipseRouteProductPoint(output[index]),
          ],
          summary: _readSolarEclipseRouteProductSummary(summary.ref),
        ),
        diagnostic: fillDiagnostic,
      );
    });
  }

  EphemerisResult<LocalSolarEclipseBoundary> _localSolarBoundary(
    _LocalSolarBoundaryCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_local_solar_eclipse_boundary>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_local_solar_eclipse_boundary_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return EphemerisResult(
        value: _readLocalSolarEclipseBoundary(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<LocalSolarEclipseResult<TtScale>> _localSolarTt(
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
      return EphemerisResult(
        value: _readLocalSolarTt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<LocalSolarEclipseResult<Ut1Scale>> _localSolarUt(
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
      return EphemerisResult(
        value: _readLocalSolarUt(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<LocalSolarEclipseCircumstances<TtScale>>
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
      return EphemerisResult(
        value: LocalSolarEclipseCircumstances(
          coordinate: readJulianDate<TtScale>(value.jd_tt),
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

  EphemerisResult<LocalSolarEclipseCircumstances<Ut1Scale>>
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
      return EphemerisResult(
        value: LocalSolarEclipseCircumstances(
          coordinate: readJulianDate<Ut1Scale>(value.jd_ut),
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

  SolarEclipseResult<TtScale> _readSolarTt(
    taiyin_solar_eclipse_result_tt value,
  ) {
    return SolarEclipseResult(
      kinds: EclipseKind.fromMask(value.kind),
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
        for (final contact in SolarEclipseContact.values)
          contact: _ttOrNull(value.contact_jd_tt[contact.nativeIndex]),
      },
    );
  }

  SolarEclipseResult<Ut1Scale> _readSolarUt(
    taiyin_solar_eclipse_result_ut value,
  ) {
    return SolarEclipseResult(
      kinds: EclipseKind.fromMask(value.kind),
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
        for (final contact in SolarEclipseContact.values)
          contact: _ut1OrNull(value.contact_jd_ut[contact.nativeIndex]),
      },
    );
  }

  LocalSolarEclipseResult<TtScale> _readLocalSolarTt(
    taiyin_local_solar_eclipse_result_tt value,
  ) {
    // The C ABI deliberately packs eclipse-kind bits (0--6) and local
    // visibility bits (7--12) into this single field.
    return LocalSolarEclipseResult(
      kinds: EclipseKind.fromMask(value.kind),
      visibility: LocalSolarEclipseVisibilityFlag.fromMask(value.kind),
      maximum: _ttOrNull(value.maximum_jd_tt),
      deltaTSeconds: null,
      magnitude: _finiteOrNull(value.magnitude),
      obscuration: _finiteOrNull(value.obscuration),
      sunAltitudeDegrees: _finiteOrNull(value.sun_altitude_deg),
      sunAzimuthDegrees: _finiteOrNull(value.sun_azimuth_deg),
      contacts: {
        for (final contact in LocalSolarEclipseContact.values)
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

  LocalSolarEclipseResult<Ut1Scale> _readLocalSolarUt(
    taiyin_local_solar_eclipse_result_ut value,
  ) {
    // See [_readLocalSolarTt]: both masks are read from the packed C field.
    return LocalSolarEclipseResult(
      kinds: EclipseKind.fromMask(value.kind),
      visibility: LocalSolarEclipseVisibilityFlag.fromMask(value.kind),
      maximum: _ut1OrNull(value.maximum_jd_ut),
      deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
      magnitude: _finiteOrNull(value.magnitude),
      obscuration: _finiteOrNull(value.obscuration),
      sunAltitudeDegrees: _finiteOrNull(value.sun_altitude_deg),
      sunAzimuthDegrees: _finiteOrNull(value.sun_azimuth_deg),
      contacts: {
        for (final contact in LocalSolarEclipseContact.values)
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

  SolarEclipseRouteRow _readSolarEclipseRouteRow(
    taiyin_solar_eclipse_route_row value,
  ) {
    return SolarEclipseRouteRow(
      coordinateTt: _requireTtRouteCoordinate(value.jd_tt, 'jd_tt'),
      coordinateUt1: _requireUt1RouteCoordinate(value.jd_ut, 'jd_ut'),
      centerLine: _readSolarEclipseRoutePoint(value.center_line),
      penumbralNorthLimit: _readSolarEclipseRoutePoint(
        value.penumbral_north_limit,
      ),
      penumbralSouthLimit: _readSolarEclipseRoutePoint(
        value.penumbral_south_limit,
      ),
      northLimit: _readSolarEclipseRoutePoint(value.north_limit),
      southLimit: _readSolarEclipseRoutePoint(value.south_limit),
      halfMagnitudeNorthLimit: _readSolarEclipseRoutePoint(
        value.half_magnitude_north_limit,
      ),
      halfMagnitudeSouthLimit: _readSolarEclipseRoutePoint(
        value.half_magnitude_south_limit,
      ),
      pathWidthKilometers: _finiteOrNull(value.path_width_km),
      durationSeconds: _finiteOrNull(value.duration_seconds),
      sunAltitudeDegrees: _finiteOrNull(value.sun_altitude_deg),
      sunAzimuthDegrees: _finiteOrNull(value.sun_azimuth_deg),
    );
  }

  SolarEclipseWhere _readSolarEclipseWhere(taiyin_solar_eclipse_where value) {
    return SolarEclipseWhere(
      coordinateTt: readJulianDate<TtScale>(value.jd_tt),
      coordinateUt1: readJulianDate<Ut1Scale>(value.jd_ut),
      centerLine: _readSolarEclipseRoutePoint(value.center_line),
      penumbralNorthLimit: _readSolarEclipseRoutePoint(
        value.penumbral_north_limit,
      ),
      penumbralSouthLimit: _readSolarEclipseRoutePoint(
        value.penumbral_south_limit,
      ),
      northLimit: _readSolarEclipseRoutePoint(value.north_limit),
      southLimit: _readSolarEclipseRoutePoint(value.south_limit),
      magnitude: value.magnitude,
      obscuration: value.obscuration,
      centerSeparationDegrees: value.center_separation_deg,
      sunAngularRadiusDegrees: value.sun_angular_radius_deg,
      moonAngularRadiusDegrees: value.moon_angular_radius_deg,
    );
  }

  SolarEclipseRoutePoint _readSolarEclipseRoutePoint(
    taiyin_solar_eclipse_path_point value,
  ) {
    return SolarEclipseRoutePoint(
      coordinateTt: _ttOrNull(value.jd_tt),
      coordinateUt1: _ut1OrNull(value.jd_ut),
      latitudeDegrees: _finiteOrNull(value.latitude_deg),
      longitudeDegrees: _finiteOrNull(value.longitude_deg),
      elevationMeters: _finiteOrNull(value.elevation_m),
      sunAltitudeDegrees: _finiteOrNull(value.sun_altitude_deg),
      sunAzimuthDegrees: _finiteOrNull(value.sun_azimuth_deg),
    );
  }

  SolarEclipseRouteCurvePoint _readSolarEclipseRouteCurvePoint(
    taiyin_solar_eclipse_route_curve_point value,
  ) {
    return SolarEclipseRouteCurvePoint(
      coordinateTt: _requireTtRouteCoordinate(value.jd_tt, 'curve.jd_tt'),
      coordinateUt1: _requireUt1RouteCoordinate(value.jd_ut, 'curve.jd_ut'),
      kind: SolarEclipseRouteCurveKind.fromNativeIndex(value.curve_kind),
      latitudeDegrees: _requireFiniteNativeRouteCoordinate(
        value.latitude_deg,
        'curve.latitude_deg',
      ),
      longitudeDegrees: _requireFiniteNativeRouteCoordinate(
        value.longitude_deg,
        'curve.longitude_deg',
      ),
    );
  }

  SolarEclipseRouteProductPoint _readSolarEclipseRouteProductPoint(
    taiyin_solar_eclipse_route_product_point value,
  ) {
    return SolarEclipseRouteProductPoint(
      coordinateTt: _requireTtRouteCoordinate(value.jd_tt, 'product.jd_tt'),
      coordinateUt1: _requireUt1RouteCoordinate(value.jd_ut, 'product.jd_ut'),
      kind: SolarEclipseRouteProductPointKind.fromNativeIndex(value.point_kind),
      sourceCurveKind: SolarEclipseRouteCurveKind.fromNativeIndex(
        value.source_curve_kind,
      ),
      latitudeDegrees: _requireFiniteNativeRouteCoordinate(
        value.latitude_deg,
        'product.latitude_deg',
      ),
      longitudeDegrees: _requireFiniteNativeRouteCoordinate(
        value.longitude_deg,
        'product.longitude_deg',
      ),
      unwrappedLongitudeDegrees: _requireFiniteNativeRouteCoordinate(
        value.unwrapped_longitude_deg,
        'product.unwrapped_longitude_deg',
      ),
    );
  }

  SolarEclipseRouteProductSummary _readSolarEclipseRouteProductSummary(
    taiyin_solar_eclipse_route_product_summary value,
  ) {
    return SolarEclipseRouteProductSummary(
      flags: SolarEclipseRouteProductFlag.fromMask(value.flags),
      curvePointCount: value.curve_point_count,
      centerLineCount: value.center_line_count,
      coreNorthCount: value.core_north_count,
      coreSouthCount: value.core_south_count,
      coreBeginHorizonCount: value.core_begin_horizon_count,
      coreEndHorizonCount: value.core_end_horizon_count,
      penumbralNorthCount: value.penumbral_north_count,
      penumbralSouthCount: value.penumbral_south_count,
      halfMagnitudeNorthCount: value.half_magnitude_north_count,
      halfMagnitudeSouthCount: value.half_magnitude_south_count,
      corePolygonPointCount: value.core_polygon_point_count,
      penumbralPolygonPointCount: value.penumbral_polygon_point_count,
      halfMagnitudePolygonPointCount: value.half_magnitude_polygon_point_count,
      polygonPointCount: value.polygon_point_count,
      minimumLatitudeDegrees: _finiteOrNull(value.min_latitude_deg),
      maximumLatitudeDegrees: _finiteOrNull(value.max_latitude_deg),
      minimumUnwrappedLongitudeDegrees: _finiteOrNull(
        value.min_unwrapped_longitude_deg,
      ),
      maximumUnwrappedLongitudeDegrees: _finiteOrNull(
        value.max_unwrapped_longitude_deg,
      ),
    );
  }

  LocalSolarEclipseBoundary _readLocalSolarEclipseBoundary(
    taiyin_local_solar_eclipse_boundary value,
  ) {
    return LocalSolarEclipseBoundary(
      centerKinds: EclipseKind.fromMask(value.center_kind),
      centerLongitudeDegrees: _finiteOrNull(value.center_longitude_deg),
      centerLatitudeDegrees: _finiteOrNull(value.center_latitude_deg),
      umbraNorthLongitudeDegrees: _finiteOrNull(
        value.umbra_north_longitude_deg,
      ),
      umbraNorthLatitudeDegrees: _finiteOrNull(value.umbra_north_latitude_deg),
      umbraSouthLongitudeDegrees: _finiteOrNull(
        value.umbra_south_longitude_deg,
      ),
      umbraSouthLatitudeDegrees: _finiteOrNull(value.umbra_south_latitude_deg),
      penumbraNorthLongitudeDegrees: _finiteOrNull(
        value.penumbra_north_longitude_deg,
      ),
      penumbraNorthLatitudeDegrees: _finiteOrNull(
        value.penumbra_north_latitude_deg,
      ),
      penumbraSouthLongitudeDegrees: _finiteOrNull(
        value.penumbra_south_longitude_deg,
      ),
      penumbraSouthLatitudeDegrees: _finiteOrNull(
        value.penumbra_south_latitude_deg,
      ),
      umbraWidthKilometers: _finiteOrNull(value.umbra_width_km),
    );
  }

  SolarBesselianElements _readSolarBesselianElements(
    taiyin_solar_besselian_elements value,
  ) {
    return SolarBesselianElements(
      tHours: value.t_hours,
      x: value.x,
      y: value.y,
      zeta: value.zeta,
      dDegrees: value.d_deg,
      muDegrees: value.mu_deg,
      l1: value.l1,
      l2: value.l2,
      f1Degrees: value.f1_deg,
      f2Degrees: value.f2_deg,
      tanF1: value.tan_f1,
      tanF2: value.tan_f2,
      gamma: value.gamma,
    );
  }

  SolarBesselianPolynomial _readSolarBesselianPolynomial(
    taiyin_solar_besselian_polynomial value,
  ) {
    return SolarBesselianPolynomial(
      referenceEpoch: readJulianDate<TtScale>(value.t0_jd_tt),
      spanHours: value.span_hours,
      sampleStepHours: value.sample_step_hours,
      degree: value.degree,
      xCoefficients: _readBesselianCoefficients(value.x),
      yCoefficients: _readBesselianCoefficients(value.y),
      zetaCoefficients: _readBesselianCoefficients(value.zeta),
      dDegreesCoefficients: _readBesselianCoefficients(value.d_deg),
      muDegreesCoefficients: _readBesselianCoefficients(value.mu_deg),
      l1Coefficients: _readBesselianCoefficients(value.l1),
      l2Coefficients: _readBesselianCoefficients(value.l2),
      f1Degrees: value.f1_deg,
      f2Degrees: value.f2_deg,
      tanF1: value.tan_f1,
      tanF2: value.tan_f2,
      center: _readSolarBesselianElements(value.center),
      maxResidual: _readSolarBesselianElements(value.max_residual),
    );
  }

  List<double> _readBesselianCoefficients(Array<Double> values) {
    return [
      for (
        var index = 0;
        index < SolarBesselianPolynomial.coefficientCount;
        index++
      )
        values[index],
    ];
  }

  void _writeSolarBesselianPolynomial(
    Arena arena,
    taiyin_solar_besselian_polynomial native,
    SolarBesselianPolynomial value,
  ) {
    native
      ..t0_jd_tt = writeJulianDate(arena, value.referenceEpoch).ref
      ..span_hours = value.spanHours
      ..sample_step_hours = value.sampleStepHours
      ..degree = value.degree
      ..f1_deg = value.f1Degrees
      ..f2_deg = value.f2Degrees
      ..tan_f1 = value.tanF1
      ..tan_f2 = value.tanF2;
    for (
      var index = 0;
      index < SolarBesselianPolynomial.coefficientCount;
      index++
    ) {
      native.x[index] = value.xCoefficients[index];
      native.y[index] = value.yCoefficients[index];
      native.zeta[index] = value.zetaCoefficients[index];
      native.d_deg[index] = value.dDegreesCoefficients[index];
      native.mu_deg[index] = value.muDegreesCoefficients[index];
      native.l1[index] = value.l1Coefficients[index];
      native.l2[index] = value.l2Coefficients[index];
    }
    _writeSolarBesselianElements(native.center, value.center);
    _writeSolarBesselianElements(native.max_residual, value.maxResidual);
  }

  void _writeSolarBesselianElements(
    taiyin_solar_besselian_elements native,
    SolarBesselianElements value,
  ) {
    native
      ..t_hours = value.tHours
      ..x = value.x
      ..y = value.y
      ..zeta = value.zeta
      ..d_deg = value.dDegrees
      ..mu_deg = value.muDegrees
      ..l1 = value.l1
      ..l2 = value.l2
      ..f1_deg = value.f1Degrees
      ..f2_deg = value.f2Degrees
      ..tan_f1 = value.tanF1
      ..tan_f2 = value.tanF2
      ..gamma = value.gamma;
  }

  int _solarSolveMask(
    Set<PositionFlag> positionFlags,
    Set<SolarEclipseSolveOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(0, (mask, option) => mask | option.mask),
    );
  }

  int _solarSearchMask(
    Set<PositionFlag> positionFlags,
    Set<SolarEclipseSearchOption> options, {
    required bool allowBackward,
  }) {
    _requireSupportedPositionFlags(positionFlags);
    if (!allowBackward && options.contains(SolarEclipseSearchOption.backward)) {
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

  int _solarRouteMask(
    Set<PositionFlag> positionFlags,
    Set<SolarEclipseRouteOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(0, (mask, option) => mask | option.mask),
    );
  }

  int _withSolarContacts(int mask) => mask | _solarEclipseIncludeContactsBit;

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }

  double _requireFiniteNativeRouteCoordinate(double value, String name) {
    if (!value.isFinite) {
      throw StateError(
        'Native solar eclipse route calculation returned non-finite $name '
        'after a successful calculation',
      );
    }
    return value;
  }

  void _requireBoundaryLatitude(double value) {
    _requireFinite(value, 'latitudeDegrees');
    if (value < -90 || value > 90) {
      throw RangeError.range(value, -90, 90, 'latitudeDegrees');
    }
  }

  void _requireRouteSampleCount(int value) {
    if (value < _solarRouteMinimumSampleCount ||
        value > _solarRouteMaximumSampleCount) {
      throw RangeError.range(
        value,
        _solarRouteMinimumSampleCount,
        _solarRouteMaximumSampleCount,
        'routeSampleCount',
      );
    }
  }

  void _requireExactNativeCount(int actual, int expected, String noun) {
    if (actual != expected) {
      throw StateError(
        'Native $noun fill returned count=$actual after reporting '
        'count=$expected',
      );
    }
  }

  void _requirePositiveFinite(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        'must be a positive finite number',
      );
    }
  }

  void _requireBesselianDegree(int degree) {
    if (degree < 1 || degree >= SolarBesselianPolynomial.coefficientCount) {
      throw RangeError.range(
        degree,
        1,
        SolarBesselianPolynomial.coefficientCount - 1,
        'degree',
      );
    }
  }

  void _requireRouteInterval<S extends TimeScale>(
    JulianDate<S> start,
    JulianDate<S> end,
  ) {
    if (end.compareTo(start) < 0) {
      throw ArgumentError.value(end, 'end', 'must not be earlier than start');
    }
  }

  int _solarKindMask(Set<EclipseKind> kinds) {
    const supported = {
      EclipseKind.partial,
      EclipseKind.total,
      EclipseKind.annular,
      EclipseKind.hybrid,
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
