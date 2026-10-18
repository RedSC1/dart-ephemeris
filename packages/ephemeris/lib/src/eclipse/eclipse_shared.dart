import '../result_flags.dart';
import '../position/position_models.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import '../eclipse/lunar_eclipse_models.dart';
import '../eclipse/solar_eclipse_models.dart';
import '../backend/eclipse_backend.dart';

const _solarRouteDefaultSampleCount = 400;

/// Global/local eclipse calculations through one native/Web facade.
final class EclipseApi {
  EclipseApi.internal(this._backend, this._ensureOpen);
  final EclipseBackend _backend;
  final void Function() _ensureOpen;

  /// Solves the lunar-eclipse lunation nearest [estimate].
  OperationResult<LunarEclipseResult<TtScale>> solveLunarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solveLunarAtTt(
      estimate,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Solves the lunar-eclipse lunation nearest [estimate].
  OperationResult<LunarEclipseResult<Ut1Scale>> solveLunarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solveLunarAtUt1(
      estimate,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Finds the next matching lunar eclipse from [start].
  OperationResult<LunarEclipseResult<TtScale>> nextLunarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.nextLunarAtTt(
      start,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Finds the next matching lunar eclipse from [start].
  ///
  /// Pass [LunarEclipseSearchOption.backward] to search backwards.
  OperationResult<LunarEclipseResult<Ut1Scale>> nextLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.nextLunarAtUt1(
      start,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Finds all matching lunar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  ///
  /// Native code reports insufficient [maxResults] capacity as an error rather
  /// than silently dropping later eclipses.
  OperationResult<List<LunarEclipseResult<TtScale>>> lunarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.lunarEclipsesAtTt(
      start,
      end,
      maxResults: maxResults,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Finds all matching lunar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  OperationResult<List<LunarEclipseResult<Ut1Scale>>> lunarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.lunarEclipsesAtUt1(
      start,
      end,
      maxResults: maxResults,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Derives local visibility for a TT global [eclipse].
  ///
  /// The context must have a geographic observer. A non-empty eclipse must
  /// include contact data, so search with `includeContacts` before calling.
  OperationResult<LocalLunarEclipseResult<TtScale>> localLunarVisibilityAtTt(
    LunarEclipseResult<TtScale> eclipse, {
    Set<LocalLunarEclipseVisibilityOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.localLunarVisibilityAtTt(eclipse, options: options);
  }

  /// Derives local visibility for a UT1 global [eclipse].
  OperationResult<LocalLunarEclipseResult<Ut1Scale>> localLunarVisibilityAtUt1(
    LunarEclipseResult<Ut1Scale> eclipse, {
    Set<LocalLunarEclipseVisibilityOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.localLunarVisibilityAtUt1(eclipse, options: options);
  }

  /// Finds the next matching lunar eclipse and its visibility at the context
  /// observer.
  OperationResult<LocalLunarEclipseResult<TtScale>> nextLocalLunarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
    Set<LocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    return _backend.nextLocalLunarAtTt(
      start,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
      visibilityOptions: visibilityOptions,
    );
  }

  /// Finds the next matching lunar eclipse and its visibility at the context
  /// observer.
  OperationResult<LocalLunarEclipseResult<Ut1Scale>> nextLocalLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
    Set<LocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    return _backend.nextLocalLunarAtUt1(
      start,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
      visibilityOptions: visibilityOptions,
    );
  }

  /// Solves the solar-eclipse lunation nearest [estimate].
  OperationResult<SolarEclipseResult<TtScale>> solveSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solveSolarAtTt(
      estimate,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Solves the solar-eclipse lunation nearest [estimate].
  OperationResult<SolarEclipseResult<Ut1Scale>> solveSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solveSolarAtUt1(
      estimate,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Finds the next matching global solar eclipse from [start].
  OperationResult<SolarEclipseResult<TtScale>> nextSolarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.nextSolarAtTt(
      start,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Finds the next matching global solar eclipse from [start].
  ///
  /// Pass [SolarEclipseSearchOption.backward] to search backwards.
  OperationResult<SolarEclipseResult<Ut1Scale>> nextSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.nextSolarAtUt1(
      start,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Finds all matching solar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  OperationResult<List<SolarEclipseResult<TtScale>>> solarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipsesAtTt(
      start,
      end,
      maxResults: maxResults,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Finds all matching solar eclipses in the positive-length,
  /// endpoint-inclusive [start], [end] range.
  OperationResult<List<SolarEclipseResult<Ut1Scale>>> solarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipsesAtUt1(
      start,
      end,
      maxResults: maxResults,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Solves local solar-eclipse circumstances at the context observer.
  ///
  /// A geographic observer location must be configured on the context.
  ///
  /// Contacts are always requested for this local result.
  OperationResult<LocalSolarEclipseResult<TtScale>> solveLocalSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    return _backend.solveLocalSolarAtTt(
      estimate,
      positionFlags: positionFlags,
      options: options,
      visibilityOptions: visibilityOptions,
    );
  }

  /// Solves local solar-eclipse circumstances at the context observer.
  ///
  /// A geographic observer location must be configured on the context.
  ///
  /// Contacts are always requested for this local result.
  OperationResult<LocalSolarEclipseResult<Ut1Scale>> solveLocalSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    return _backend.solveLocalSolarAtUt1(
      estimate,
      positionFlags: positionFlags,
      options: options,
      visibilityOptions: visibilityOptions,
    );
  }

  /// Finds the next solar eclipse visible at the context observer.
  ///
  /// A geographic observer location must be configured on the context.
  ///
  /// Contacts are always requested. Pass
  /// [SolarEclipseSearchOption.backward] to search backwards.
  OperationResult<LocalSolarEclipseResult<TtScale>> nextLocalSolarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    return _backend.nextLocalSolarAtTt(
      start,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
      visibilityOptions: visibilityOptions,
    );
  }

  /// Finds the next solar eclipse visible at the context observer.
  ///
  /// A geographic observer location must be configured on the context.
  ///
  /// Contacts are always requested. Pass
  /// [SolarEclipseSearchOption.backward] to search backwards.
  OperationResult<LocalSolarEclipseResult<Ut1Scale>> nextLocalSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    return _backend.nextLocalSolarAtUt1(
      start,
      kinds: kinds,
      positionFlags: positionFlags,
      options: options,
      visibilityOptions: visibilityOptions,
    );
  }

  /// Calculates instantaneous local solar-eclipse geometry at [coordinate].
  ///
  /// A geographic observer location must be configured on the context.
  OperationResult<LocalSolarEclipseCircumstances<TtScale>>
  localSolarCircumstancesAtTt(JulianDate<TtScale> coordinate) {
    _ensureOpen();
    return _backend.localSolarCircumstancesAtTt(coordinate);
  }

  /// Calculates instantaneous local solar-eclipse geometry at [coordinate].
  ///
  /// A geographic observer location must be configured on the context.
  OperationResult<LocalSolarEclipseCircumstances<Ut1Scale>>
  localSolarCircumstancesAtUt1(JulianDate<Ut1Scale> coordinate) {
    _ensureOpen();
    return _backend.localSolarCircumstancesAtUt1(coordinate);
  }

  /// Computes Besselian elements at a TT [coordinate].
  ///
  /// [timeOffsetHours] is retained as the conventional Besselian time offset
  /// in the returned value. The physical calculation crosses the current
  /// scalar-Julian-date C ABI boundary.
  OperationResult<SolarBesselianElements> solarBesselianElementsAtTt(
    JulianDate<TtScale> coordinate, {
    double timeOffsetHours = 0,
  }) {
    _ensureOpen();
    return _backend.solarBesselianElementsAtTt(
      coordinate,
      timeOffsetHours: timeOffsetHours,
    );
  }

  /// Fits a Besselian polynomial centred on a TT [coordinate].
  ///
  /// [spanHours] and [sampleStepHours] must be positive. The native model
  /// permits polynomial [degree] values from 1 through 7.
  OperationResult<SolarBesselianPolynomial> solarBesselianPolynomialAtTt(
    JulianDate<TtScale> coordinate, {
    required double spanHours,
    required double sampleStepHours,
    int degree = 4,
  }) {
    _ensureOpen();
    return _backend.solarBesselianPolynomialAtTt(
      coordinate,
      spanHours: spanHours,
      sampleStepHours: sampleStepHours,
      degree: degree,
    );
  }

  /// Evaluates a fitted solar Besselian [polynomial] at [timeOffsetHours].
  ///
  /// [timeOffsetHours] is relative to [SolarBesselianPolynomial.referenceEpoch].
  OperationResult<SolarBesselianElements> evaluateSolarBesselianPolynomial(
    SolarBesselianPolynomial polynomial,
    double timeOffsetHours,
  ) {
    _ensureOpen();
    return _backend.evaluateSolarBesselianPolynomial(
      polynomial,
      timeOffsetHours,
    );
  }

  /// Calculates the global solar-eclipse route geometry at TT [coordinate].
  ///
  /// Only [PositionFlag.truePosition] and
  /// [SolarEclipseRouteOption.lunarLimbCorrection] are supported.
  OperationResult<SolarEclipseRouteRow> solarEclipseRouteRowAtTt(
    JulianDate<TtScale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteRowAtTt(
      coordinate,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Calculates the global solar-eclipse route geometry at UT1 [coordinate].
  ///
  /// Only [PositionFlag.truePosition] and
  /// [SolarEclipseRouteOption.lunarLimbCorrection] are supported.
  OperationResult<SolarEclipseRouteRow> solarEclipseRouteRowAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteRowAtUt1(
      coordinate,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Calculates lightweight instantaneous global solar-eclipse geometry at TT
  /// [coordinate].
  ///
  /// Only [PositionFlag.truePosition] and
  /// [SolarEclipseRouteOption.lunarLimbCorrection] are supported.
  OperationResult<SolarEclipseWhere> solarEclipseWhereAtTt(
    JulianDate<TtScale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseWhereAtTt(
      coordinate,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Calculates lightweight instantaneous global solar-eclipse geometry at
  /// UT1 [coordinate].
  ///
  /// Only [PositionFlag.truePosition] and
  /// [SolarEclipseRouteOption.lunarLimbCorrection] are supported.
  OperationResult<SolarEclipseWhere> solarEclipseWhereAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseWhereAtUt1(
      coordinate,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Samples global solar-eclipse route geometry from TT [start] through [end].
  ///
  /// Both endpoints are included when they land on [stepMinutes]. The range
  /// may contain one coordinate. Rows with no Earth-intersecting route branch
  /// are omitted by native code.
  OperationResult<List<SolarEclipseRouteRow>> solarEclipseRouteAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double stepMinutes,
    int maxRows = 256,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteAtTt(
      start,
      end,
      stepMinutes: stepMinutes,
      maxRows: maxRows,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Samples global solar-eclipse route geometry from UT1 [start] through [end].
  ///
  /// Both endpoints are included when they land on [stepMinutes]. The range
  /// may contain one coordinate. Rows with no Earth-intersecting route branch
  /// are omitted by native code.
  OperationResult<List<SolarEclipseRouteRow>> solarEclipseRouteAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double stepMinutes,
    int maxRows = 256,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteAtUt1(
      start,
      end,
      stepMinutes: stepMinutes,
      maxRows: maxRows,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Computes the complete time-tagged solar-eclipse map curves near TT
  /// [coordinate].
  ///
  /// [routeSampleCount] controls the sampling density for every curve and
  /// must be between 32 and 4096. Points are grouped by curve kind.
  OperationResult<List<SolarEclipseRouteCurvePoint>>
  solarEclipseRouteCurvesAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteCurvesAtTt(
      coordinate,
      routeSampleCount: routeSampleCount,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Computes the complete time-tagged solar-eclipse map curves near UT1
  /// [coordinate].
  OperationResult<List<SolarEclipseRouteCurvePoint>>
  solarEclipseRouteCurvesAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteCurvesAtUt1(
      coordinate,
      routeSampleCount: routeSampleCount,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Builds the core-path polygon of the solar eclipse near TT [coordinate].
  ///
  /// Use [solarEclipseRouteMapProductAtTt] when penumbral and half-magnitude
  /// polygons are also required.
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteProductAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteProductAtTt(
      coordinate,
      routeSampleCount: routeSampleCount,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Builds the core-path polygon of the solar eclipse near UT1 [coordinate].
  ///
  /// Use [solarEclipseRouteMapProductAtUt1] when penumbral and half-magnitude
  /// polygons are also required.
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteProductAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteProductAtUt1(
      coordinate,
      routeSampleCount: routeSampleCount,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Builds all available solar-eclipse map polygons near TT [coordinate].
  ///
  /// The returned point sequence contains the core, penumbral, and
  /// half-magnitude polygons in that order when those layers exist.
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteMapProductAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteMapProductAtTt(
      coordinate,
      routeSampleCount: routeSampleCount,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Builds all available solar-eclipse map polygons near UT1 [coordinate].
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteMapProductAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _ensureOpen();
    return _backend.solarEclipseRouteMapProductAtUt1(
      coordinate,
      routeSampleCount: routeSampleCount,
      positionFlags: positionFlags,
      options: options,
    );
  }

  /// Computes the local Earth intersections of the solar shadow at TT
  /// [coordinate].
  ///
  /// [longitudeDegrees] and [latitudeDegrees] select the reference location
  /// used to resolve the central-path kind; they do not need to match the
  /// context observer.
  OperationResult<LocalSolarEclipseBoundary> localSolarEclipseBoundaryAtTt(
    JulianDate<TtScale> coordinate, {
    required double longitudeDegrees,
    required double latitudeDegrees,
  }) {
    _ensureOpen();
    return _backend.localSolarEclipseBoundaryAtTt(
      coordinate,
      longitudeDegrees: longitudeDegrees,
      latitudeDegrees: latitudeDegrees,
    );
  }

  /// Computes the local Earth intersections of the solar shadow at UT1
  /// [coordinate].
  OperationResult<LocalSolarEclipseBoundary> localSolarEclipseBoundaryAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    required double longitudeDegrees,
    required double latitudeDegrees,
  }) {
    _ensureOpen();
    return _backend.localSolarEclipseBoundaryAtUt1(
      coordinate,
      longitudeDegrees: longitudeDegrees,
      latitudeDegrees: latitudeDegrees,
    );
  }
}
