import '../result_flags.dart';
import '../position/position_models.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import '../eclipse/lunar_eclipse_models.dart';
import '../eclipse/solar_eclipse_models.dart';

const _solarRouteDefaultSampleCount = 400;

/// Typed eclipse operations. Platform memory stays below this boundary.
abstract interface class EclipseBackend {
  OperationResult<LunarEclipseResult<TtScale>> solveLunarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSolveOption> options = const {},
  });
  OperationResult<LunarEclipseResult<Ut1Scale>> solveLunarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSolveOption> options = const {},
  });
  OperationResult<LunarEclipseResult<TtScale>> nextLunarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  });
  OperationResult<LunarEclipseResult<Ut1Scale>> nextLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  });
  OperationResult<List<LunarEclipseResult<TtScale>>> lunarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  });
  OperationResult<List<LunarEclipseResult<Ut1Scale>>> lunarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  });
  OperationResult<LocalLunarEclipseResult<TtScale>> localLunarVisibilityAtTt(
    LunarEclipseResult<TtScale> eclipse, {
    Set<LocalLunarEclipseVisibilityOption> options = const {},
  });
  OperationResult<LocalLunarEclipseResult<Ut1Scale>> localLunarVisibilityAtUt1(
    LunarEclipseResult<Ut1Scale> eclipse, {
    Set<LocalLunarEclipseVisibilityOption> options = const {},
  });
  OperationResult<LocalLunarEclipseResult<TtScale>> nextLocalLunarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
    Set<LocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  });
  OperationResult<LocalLunarEclipseResult<Ut1Scale>> nextLocalLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
    Set<LocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  });
  OperationResult<SolarEclipseResult<TtScale>> solveSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
  });
  OperationResult<SolarEclipseResult<Ut1Scale>> solveSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
  });
  OperationResult<SolarEclipseResult<TtScale>> nextSolarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  });
  OperationResult<SolarEclipseResult<Ut1Scale>> nextSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  });
  OperationResult<List<SolarEclipseResult<TtScale>>> solarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  });
  OperationResult<List<SolarEclipseResult<Ut1Scale>>> solarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  });
  OperationResult<LocalSolarEclipseResult<TtScale>> solveLocalSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  });
  OperationResult<LocalSolarEclipseResult<Ut1Scale>> solveLocalSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  });
  OperationResult<LocalSolarEclipseResult<TtScale>> nextLocalSolarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  });
  OperationResult<LocalSolarEclipseResult<Ut1Scale>> nextLocalSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  });
  OperationResult<LocalSolarEclipseCircumstances<TtScale>>
  localSolarCircumstancesAtTt(JulianDate<TtScale> coordinate);
  OperationResult<LocalSolarEclipseCircumstances<Ut1Scale>>
  localSolarCircumstancesAtUt1(JulianDate<Ut1Scale> coordinate);
  OperationResult<SolarBesselianElements> solarBesselianElementsAtTt(
    JulianDate<TtScale> coordinate, {
    double timeOffsetHours = 0,
  });
  OperationResult<SolarBesselianPolynomial> solarBesselianPolynomialAtTt(
    JulianDate<TtScale> coordinate, {
    required double spanHours,
    required double sampleStepHours,
    int degree = 4,
  });
  OperationResult<SolarBesselianElements> evaluateSolarBesselianPolynomial(
    SolarBesselianPolynomial polynomial,
    double timeOffsetHours,
  );
  OperationResult<SolarEclipseRouteRow> solarEclipseRouteRowAtTt(
    JulianDate<TtScale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<SolarEclipseRouteRow> solarEclipseRouteRowAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<SolarEclipseWhere> solarEclipseWhereAtTt(
    JulianDate<TtScale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<SolarEclipseWhere> solarEclipseWhereAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<List<SolarEclipseRouteRow>> solarEclipseRouteAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double stepMinutes,
    int maxRows = 256,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<List<SolarEclipseRouteRow>> solarEclipseRouteAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double stepMinutes,
    int maxRows = 256,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<List<SolarEclipseRouteCurvePoint>>
  solarEclipseRouteCurvesAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<List<SolarEclipseRouteCurvePoint>>
  solarEclipseRouteCurvesAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteProductAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteProductAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteMapProductAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteMapProductAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  });
  OperationResult<LocalSolarEclipseBoundary> localSolarEclipseBoundaryAtTt(
    JulianDate<TtScale> coordinate, {
    required double longitudeDegrees,
    required double latitudeDegrees,
  });
  OperationResult<LocalSolarEclipseBoundary> localSolarEclipseBoundaryAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    required double longitudeDegrees,
    required double latitudeDegrees,
  });
}
