import '../result_flags.dart';
import '../position/position_models.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import '../eclipse/lunar_eclipse_models.dart';
import '../eclipse/solar_eclipse_models.dart';
import '../backend/eclipse_backend.dart';
import '../backend/backend_call.dart';
import 'diagnostic_web.dart';
import 'wasm_module.dart';
import 'eclipse_records.dart';

const _solarEclipseIncludeContactsBit = 8589934592;
const _solarRouteDefaultSampleCount = 400;
const _solarRouteMinimumSampleCount = 32;
const _solarRouteMaximumSampleCount = 4096;

final class WebEclipseBackend implements EclipseBackend {
  WebEclipseBackend(this._backend, this._handle, this._complete);
  final WasmBackend _backend;
  final int _handle;
  final BackendCallCompletion _complete;
  OperationResult<T> _call<T>(
    int operation,
    List<num> input,
    T Function(List<double>, int) read,
  ) {
    final reply = _backend.eclipse(_handle, operation, input);
    final flags = ResultFlags(reply.values[0].toInt());
    _complete(
      BackendCall<Object?>(
        status: reply.status,
        flags: flags,
        value: null,
        diagnostic: readWebDiagnostic(reply.values),
      ),
    );
    return operationResult(read(reply.values, reply.values[2].toInt()), flags);
  }

  List<num> _jd(JulianDate<TimeScale> jd) {
    if (jd.dayNumber.abs() > 9007199254740991) {
      throw RangeError('JD outside exact JS range');
    }
    return [jd.dayNumber, jd.dayFraction];
  }

  List<num> _mask(BigInt mask) => [
    (mask & BigInt.from(0xffffffff)).toInt(),
    (mask >> 32).toInt(),
  ];
  JulianDate<S> _readJd<S extends TimeScale>(Web_taiyin_split_julian_date v) =>
      JulianDate<S>.fromParts(v.day_number, v.day_fraction);
  @override
  OperationResult<LunarEclipseResult<TtScale>> solveLunarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSolveOption> options = const {},
  }) {
    final mask = _solveMask(positionFlags, options);
    return _call(0, [
      ..._jd(estimate),
      ..._mask(mask),
    ], (v, n) => _readLunarTt(Web_taiyin_lunar_eclipse_result_tt(v, 32)));
  }

  @override
  OperationResult<LunarEclipseResult<Ut1Scale>> solveLunarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSolveOption> options = const {},
  }) {
    final mask = _solveMask(positionFlags, options);
    return _call(1, [
      ..._jd(estimate),
      ..._mask(mask),
    ], (v, n) => _readLunarUt(Web_taiyin_lunar_eclipse_result_ut(v, 32)));
  }

  @override
  OperationResult<LunarEclipseResult<TtScale>> nextLunarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: true);
    return _call(2, [
      ..._jd(start),
      kindMask,
      ..._mask(mask),
    ], (v, n) => _readLunarTt(Web_taiyin_lunar_eclipse_result_tt(v, 32)));
  }

  @override
  OperationResult<LunarEclipseResult<Ut1Scale>> nextLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: true);
    return _call(3, [
      ..._jd(start),
      kindMask,
      ..._mask(mask),
    ], (v, n) => _readLunarUt(Web_taiyin_lunar_eclipse_result_ut(v, 32)));
  }

  @override
  OperationResult<List<LunarEclipseResult<TtScale>>> lunarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: false);
    return _call(
      4,
      [..._jd(start), ..._jd(end), kindMask, ..._mask(mask), maxResults],
      (v, n) => List.unmodifiable([
        for (var i = 0; i < n; i++)
          _readLunarTt(Web_taiyin_lunar_eclipse_result_tt(v, 32 + 0 + i * 23)),
      ]),
    );
  }

  @override
  OperationResult<List<LunarEclipseResult<Ut1Scale>>> lunarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
  }) {
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final kindMask = _lunarKindMask(kinds);
    final mask = _searchMask(positionFlags, options, allowBackward: false);
    return _call(
      5,
      [..._jd(start), ..._jd(end), kindMask, ..._mask(mask), maxResults],
      (v, n) => List.unmodifiable([
        for (var i = 0; i < n; i++)
          _readLunarUt(Web_taiyin_lunar_eclipse_result_ut(v, 32 + 0 + i * 24)),
      ]),
    );
  }

  @override
  OperationResult<LocalLunarEclipseResult<TtScale>> localLunarVisibilityAtTt(
    LunarEclipseResult<TtScale> eclipse, {
    Set<LocalLunarEclipseVisibilityOption> options = const {},
  }) {
    _requireLocalContacts(eclipse);
    final mask = _localVisibilityMask(options);
    return _call(
      6,
      [..._lunarInput(eclipse, false), ..._mask(mask)],
      (v, n) =>
          _readLocalLunarTt(Web_taiyin_local_lunar_eclipse_result_tt(v, 32)),
    );
  }

  @override
  OperationResult<LocalLunarEclipseResult<Ut1Scale>> localLunarVisibilityAtUt1(
    LunarEclipseResult<Ut1Scale> eclipse, {
    Set<LocalLunarEclipseVisibilityOption> options = const {},
  }) {
    _requireLocalContacts(eclipse);
    final mask = _localVisibilityMask(options);
    return _call(
      7,
      [..._lunarInput(eclipse, true), ..._mask(mask)],
      (v, n) =>
          _readLocalLunarUt(Web_taiyin_local_lunar_eclipse_result_ut(v, 32)),
    );
  }

  @override
  OperationResult<LocalLunarEclipseResult<TtScale>> nextLocalLunarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
    Set<LocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    final kindMask = _lunarKindMask(kinds);
    final mask = _mergeDisjointMasks(
      _searchMask(positionFlags, options, allowBackward: true),
      _localVisibilityMask(visibilityOptions),
    );
    return _call(
      8,
      [..._jd(start), kindMask, ..._mask(mask)],
      (v, n) =>
          _readLocalLunarTt(Web_taiyin_local_lunar_eclipse_result_tt(v, 32)),
    );
  }

  @override
  OperationResult<LocalLunarEclipseResult<Ut1Scale>> nextLocalLunarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<LunarEclipseSearchOption> options = const {},
    Set<LocalLunarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    final kindMask = _lunarKindMask(kinds);
    final mask = _mergeDisjointMasks(
      _searchMask(positionFlags, options, allowBackward: true),
      _localVisibilityMask(visibilityOptions),
    );
    return _call(
      9,
      [..._jd(start), kindMask, ..._mask(mask)],
      (v, n) =>
          _readLocalLunarUt(Web_taiyin_local_lunar_eclipse_result_ut(v, 32)),
    );
  }

  @override
  OperationResult<SolarEclipseResult<TtScale>> solveSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
  }) {
    final mask = _solarSolveMask(positionFlags, options);
    return _call(10, [
      ..._jd(estimate),
      ..._mask(mask),
    ], (v, n) => _readSolarTt(Web_taiyin_solar_eclipse_result_tt(v, 32)));
  }

  @override
  OperationResult<SolarEclipseResult<Ut1Scale>> solveSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
  }) {
    final mask = _solarSolveMask(positionFlags, options);
    return _call(11, [
      ..._jd(estimate),
      ..._mask(mask),
    ], (v, n) => _readSolarUt(Web_taiyin_solar_eclipse_result_ut(v, 32)));
  }

  @override
  OperationResult<SolarEclipseResult<TtScale>> nextSolarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    final mask = _solarSearchMask(positionFlags, options, allowBackward: true);
    return _call(12, [
      ..._jd(start),
      _solarKindMask(kinds),
      ..._mask(mask),
    ], (v, n) => _readSolarTt(Web_taiyin_solar_eclipse_result_tt(v, 32)));
  }

  @override
  OperationResult<SolarEclipseResult<Ut1Scale>> nextSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    final mask = _solarSearchMask(positionFlags, options, allowBackward: true);
    return _call(13, [
      ..._jd(start),
      _solarKindMask(kinds),
      ..._mask(mask),
    ], (v, n) => _readSolarUt(Web_taiyin_solar_eclipse_result_ut(v, 32)));
  }

  @override
  OperationResult<List<SolarEclipseResult<TtScale>>> solarEclipsesAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final mask = _solarSearchMask(positionFlags, options, allowBackward: false);
    return _call(
      14,
      [
        ..._jd(start),
        ..._jd(end),
        _solarKindMask(kinds),
        ..._mask(mask),
        maxResults,
      ],
      (v, n) => List.unmodifiable([
        for (var i = 0; i < n; i++)
          _readSolarTt(Web_taiyin_solar_eclipse_result_tt(v, 32 + 0 + i * 20)),
      ]),
    );
  }

  @override
  OperationResult<List<SolarEclipseResult<Ut1Scale>>> solarEclipsesAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    int maxResults = 16,
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
  }) {
    _requireInterval(start, end);
    _requireCapacity(maxResults);
    final mask = _solarSearchMask(positionFlags, options, allowBackward: false);
    return _call(
      15,
      [
        ..._jd(start),
        ..._jd(end),
        _solarKindMask(kinds),
        ..._mask(mask),
        maxResults,
      ],
      (v, n) => List.unmodifiable([
        for (var i = 0; i < n; i++)
          _readSolarUt(Web_taiyin_solar_eclipse_result_ut(v, 32 + 0 + i * 21)),
      ]),
    );
  }

  @override
  OperationResult<LocalSolarEclipseResult<TtScale>> solveLocalSolarAtTt(
    JulianDate<TtScale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    final mask = _withSolarContacts(
      _mergeDisjointMasks(
        _solarSolveMask(positionFlags, options),
        _localSolarVisibilityMask(visibilityOptions),
      ),
    );
    return _call(
      16,
      [..._jd(estimate), ..._mask(mask)],
      (v, n) =>
          _readLocalSolarTt(Web_taiyin_local_solar_eclipse_result_tt(v, 32)),
    );
  }

  @override
  OperationResult<LocalSolarEclipseResult<Ut1Scale>> solveLocalSolarAtUt1(
    JulianDate<Ut1Scale> estimate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSolveOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    final mask = _withSolarContacts(
      _mergeDisjointMasks(
        _solarSolveMask(positionFlags, options),
        _localSolarVisibilityMask(visibilityOptions),
      ),
    );
    return _call(
      17,
      [..._jd(estimate), ..._mask(mask)],
      (v, n) =>
          _readLocalSolarUt(Web_taiyin_local_solar_eclipse_result_ut(v, 32)),
    );
  }

  @override
  OperationResult<LocalSolarEclipseResult<TtScale>> nextLocalSolarAtTt(
    JulianDate<TtScale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    final mask = _withSolarContacts(
      _mergeDisjointMasks(
        _solarSearchMask(positionFlags, options, allowBackward: true),
        _localSolarVisibilityMask(visibilityOptions),
      ),
    );
    return _call(
      18,
      [..._jd(start), _solarKindMask(kinds), ..._mask(mask)],
      (v, n) =>
          _readLocalSolarTt(Web_taiyin_local_solar_eclipse_result_tt(v, 32)),
    );
  }

  @override
  OperationResult<LocalSolarEclipseResult<Ut1Scale>> nextLocalSolarAtUt1(
    JulianDate<Ut1Scale> start, {
    Set<EclipseKind> kinds = const {},
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseSearchOption> options = const {},
    Set<LocalSolarEclipseVisibilityOption> visibilityOptions = const {},
  }) {
    final mask = _withSolarContacts(
      _mergeDisjointMasks(
        _solarSearchMask(positionFlags, options, allowBackward: true),
        _localSolarVisibilityMask(visibilityOptions),
      ),
    );
    return _call(
      19,
      [..._jd(start), _solarKindMask(kinds), ..._mask(mask)],
      (v, n) =>
          _readLocalSolarUt(Web_taiyin_local_solar_eclipse_result_ut(v, 32)),
    );
  }

  @override
  OperationResult<LocalSolarEclipseCircumstances<TtScale>>
  localSolarCircumstancesAtTt(JulianDate<TtScale> coordinate) {
    return _call(20, [..._jd(coordinate)], (v, n) {
      final value = Web_taiyin_local_solar_eclipse_circumstances_tt(v, 32);
      return LocalSolarEclipseCircumstances<TtScale>(
        coordinate: _readJd<TtScale>(value.jd_tt),
        deltaTSeconds: null,
        magnitude: value.magnitude,
        obscuration: value.obscuration,
        centerSeparationDegrees: value.center_separation_deg,
        sunAngularRadiusDegrees: value.sun_angular_radius_deg,
        moonAngularRadiusDegrees: value.moon_angular_radius_deg,
        sunAltitudeDegrees: value.sun_altitude_deg,
        sunAzimuthDegrees: value.sun_azimuth_deg,
      );
    });
  }

  @override
  OperationResult<LocalSolarEclipseCircumstances<Ut1Scale>>
  localSolarCircumstancesAtUt1(JulianDate<Ut1Scale> coordinate) {
    return _call(21, [..._jd(coordinate)], (v, n) {
      final value = Web_taiyin_local_solar_eclipse_circumstances_ut(v, 32);
      return LocalSolarEclipseCircumstances<Ut1Scale>(
        coordinate: _readJd<Ut1Scale>(value.jd_ut),
        deltaTSeconds: _finiteOrNull(value.delta_t_seconds),
        magnitude: value.magnitude,
        obscuration: value.obscuration,
        centerSeparationDegrees: value.center_separation_deg,
        sunAngularRadiusDegrees: value.sun_angular_radius_deg,
        moonAngularRadiusDegrees: value.moon_angular_radius_deg,
        sunAltitudeDegrees: value.sun_altitude_deg,
        sunAzimuthDegrees: value.sun_azimuth_deg,
      );
    });
  }

  @override
  OperationResult<SolarBesselianElements> solarBesselianElementsAtTt(
    JulianDate<TtScale> coordinate, {
    double timeOffsetHours = 0,
  }) {
    _requireFinite(timeOffsetHours, 'timeOffsetHours');
    return _call(
      22,
      [..._jd(coordinate), timeOffsetHours],
      (v, n) => _readSolarBesselianElements(
        Web_taiyin_solar_besselian_elements(v, 32),
      ),
    );
  }

  @override
  OperationResult<SolarBesselianPolynomial> solarBesselianPolynomialAtTt(
    JulianDate<TtScale> coordinate, {
    required double spanHours,
    required double sampleStepHours,
    int degree = 4,
  }) {
    _requirePositiveFinite(spanHours, 'spanHours');
    _requirePositiveFinite(sampleStepHours, 'sampleStepHours');
    _requireBesselianDegree(degree);
    return _call(
      23,
      [..._jd(coordinate), spanHours, sampleStepHours, degree],
      (v, n) => _readSolarBesselianPolynomial(
        Web_taiyin_solar_besselian_polynomial(v, 32),
      ),
    );
  }

  @override
  OperationResult<SolarBesselianElements> evaluateSolarBesselianPolynomial(
    SolarBesselianPolynomial polynomial,
    double timeOffsetHours,
  ) {
    _requireFinite(timeOffsetHours, 'timeOffsetHours');
    return _call(
      24,
      [..._polynomialInput(polynomial), timeOffsetHours],
      (v, n) => _readSolarBesselianElements(
        Web_taiyin_solar_besselian_elements(v, 32),
      ),
    );
  }

  @override
  OperationResult<SolarEclipseRouteRow> solarEclipseRouteRowAtTt(
    JulianDate<TtScale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      25,
      [..._jd(coordinate), ..._mask(mask)],
      (v, n) =>
          _readSolarEclipseRouteRow(Web_taiyin_solar_eclipse_route_row(v, 32)),
    );
  }

  @override
  OperationResult<SolarEclipseRouteRow> solarEclipseRouteRowAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      26,
      [..._jd(coordinate), ..._mask(mask)],
      (v, n) =>
          _readSolarEclipseRouteRow(Web_taiyin_solar_eclipse_route_row(v, 32)),
    );
  }

  @override
  OperationResult<SolarEclipseWhere> solarEclipseWhereAtTt(
    JulianDate<TtScale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    final mask = _solarRouteMask(positionFlags, options);
    return _call(27, [
      ..._jd(coordinate),
      ..._mask(mask),
    ], (v, n) => _readSolarEclipseWhere(Web_taiyin_solar_eclipse_where(v, 32)));
  }

  @override
  OperationResult<SolarEclipseWhere> solarEclipseWhereAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    final mask = _solarRouteMask(positionFlags, options);
    return _call(28, [
      ..._jd(coordinate),
      ..._mask(mask),
    ], (v, n) => _readSolarEclipseWhere(Web_taiyin_solar_eclipse_where(v, 32)));
  }

  @override
  OperationResult<List<SolarEclipseRouteRow>> solarEclipseRouteAtTt(
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double stepMinutes,
    int maxRows = 256,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _requireRouteInterval(start, end);
    _requirePositiveFinite(stepMinutes, 'stepMinutes');
    _requireCapacity(maxRows, name: 'maxRows');
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      29,
      [..._jd(start), ..._jd(end), stepMinutes, ..._mask(mask), maxRows],
      (v, n) => List.unmodifiable([
        for (var i = 0; i < n; i++)
          _readSolarEclipseRouteRow(
            Web_taiyin_solar_eclipse_route_row(v, 32 + 0 + i * 71),
          ),
      ]),
    );
  }

  @override
  OperationResult<List<SolarEclipseRouteRow>> solarEclipseRouteAtUt1(
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double stepMinutes,
    int maxRows = 256,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _requireRouteInterval(start, end);
    _requirePositiveFinite(stepMinutes, 'stepMinutes');
    _requireCapacity(maxRows, name: 'maxRows');
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      30,
      [..._jd(start), ..._jd(end), stepMinutes, ..._mask(mask), maxRows],
      (v, n) => List.unmodifiable([
        for (var i = 0; i < n; i++)
          _readSolarEclipseRouteRow(
            Web_taiyin_solar_eclipse_route_row(v, 32 + 0 + i * 71),
          ),
      ]),
    );
  }

  @override
  OperationResult<List<SolarEclipseRouteCurvePoint>>
  solarEclipseRouteCurvesAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      31,
      [..._jd(coordinate), ..._mask(mask), routeSampleCount, 0],
      (v, n) => List.unmodifiable([
        for (var i = 0; i < n; i++)
          _readSolarEclipseRouteCurvePoint(
            Web_taiyin_solar_eclipse_route_curve_point(v, 32 + 0 + i * 7),
          ),
      ]),
    );
  }

  @override
  OperationResult<List<SolarEclipseRouteCurvePoint>>
  solarEclipseRouteCurvesAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      32,
      [..._jd(coordinate), ..._mask(mask), routeSampleCount, 0],
      (v, n) => List.unmodifiable([
        for (var i = 0; i < n; i++)
          _readSolarEclipseRouteCurvePoint(
            Web_taiyin_solar_eclipse_route_curve_point(v, 32 + 0 + i * 7),
          ),
      ]),
    );
  }

  @override
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteProductAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      33,
      [..._jd(coordinate), ..._mask(mask), routeSampleCount, 0],
      (v, n) => SolarEclipseRouteProduct(
        points: [
          for (var i = 0; i < n; i++)
            _readSolarEclipseRouteProductPoint(
              Web_taiyin_solar_eclipse_route_product_point(v, 32 + 19 + i * 9),
            ),
        ],
        summary: _readSolarEclipseRouteProductSummary(
          Web_taiyin_solar_eclipse_route_product_summary(v, 32),
        ),
      ),
    );
  }

  @override
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteProductAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      34,
      [..._jd(coordinate), ..._mask(mask), routeSampleCount, 0],
      (v, n) => SolarEclipseRouteProduct(
        points: [
          for (var i = 0; i < n; i++)
            _readSolarEclipseRouteProductPoint(
              Web_taiyin_solar_eclipse_route_product_point(v, 32 + 19 + i * 9),
            ),
        ],
        summary: _readSolarEclipseRouteProductSummary(
          Web_taiyin_solar_eclipse_route_product_summary(v, 32),
        ),
      ),
    );
  }

  @override
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteMapProductAtTt(
    JulianDate<TtScale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      35,
      [..._jd(coordinate), ..._mask(mask), routeSampleCount, 0],
      (v, n) => SolarEclipseRouteProduct(
        points: [
          for (var i = 0; i < n; i++)
            _readSolarEclipseRouteProductPoint(
              Web_taiyin_solar_eclipse_route_product_point(v, 32 + 19 + i * 9),
            ),
        ],
        summary: _readSolarEclipseRouteProductSummary(
          Web_taiyin_solar_eclipse_route_product_summary(v, 32),
        ),
      ),
    );
  }

  @override
  OperationResult<SolarEclipseRouteProduct> solarEclipseRouteMapProductAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    int routeSampleCount = _solarRouteDefaultSampleCount,
    Set<PositionFlag> positionFlags = const {},
    Set<SolarEclipseRouteOption> options = const {},
  }) {
    _requireRouteSampleCount(routeSampleCount);
    final mask = _solarRouteMask(positionFlags, options);
    return _call(
      36,
      [..._jd(coordinate), ..._mask(mask), routeSampleCount, 0],
      (v, n) => SolarEclipseRouteProduct(
        points: [
          for (var i = 0; i < n; i++)
            _readSolarEclipseRouteProductPoint(
              Web_taiyin_solar_eclipse_route_product_point(v, 32 + 19 + i * 9),
            ),
        ],
        summary: _readSolarEclipseRouteProductSummary(
          Web_taiyin_solar_eclipse_route_product_summary(v, 32),
        ),
      ),
    );
  }

  @override
  OperationResult<LocalSolarEclipseBoundary> localSolarEclipseBoundaryAtTt(
    JulianDate<TtScale> coordinate, {
    required double longitudeDegrees,
    required double latitudeDegrees,
  }) {
    _requireFinite(longitudeDegrees, 'longitudeDegrees');
    _requireBoundaryLatitude(latitudeDegrees);
    return _call(
      37,
      [..._jd(coordinate), longitudeDegrees, latitudeDegrees],
      (v, n) => _readLocalSolarEclipseBoundary(
        Web_taiyin_local_solar_eclipse_boundary(v, 32),
      ),
    );
  }

  @override
  OperationResult<LocalSolarEclipseBoundary> localSolarEclipseBoundaryAtUt1(
    JulianDate<Ut1Scale> coordinate, {
    required double longitudeDegrees,
    required double latitudeDegrees,
  }) {
    _requireFinite(longitudeDegrees, 'longitudeDegrees');
    _requireBoundaryLatitude(latitudeDegrees);
    return _call(
      38,
      [..._jd(coordinate), longitudeDegrees, latitudeDegrees],
      (v, n) => _readLocalSolarEclipseBoundary(
        Web_taiyin_local_solar_eclipse_boundary(v, 32),
      ),
    );
  }

  List<num> _optionalJd(JulianDate<TimeScale>? v) =>
      v == null ? [0, double.nan] : _jd(v);
  List<num> _lunarInput(LunarEclipseResult<TimeScale> v, bool ut) => [
    _kindMask(v.kinds),
    ..._optionalJd(v.maximum),
    if (ut) v.deltaTSeconds ?? double.nan,
    v.umbralMagnitude ?? double.nan,
    v.penumbralMagnitude ?? double.nan,
    v.axisDistanceRadians ?? double.nan,
    v.umbraRadiusRadians ?? double.nan,
    v.penumbraRadiusRadians ?? double.nan,
    v.moonRadiusRadians ?? double.nan,
    for (final c in LunarEclipseContact.values) ..._optionalJd(v.contacts[c]),
  ];
  List<num> _elementsInput(SolarBesselianElements v) => [
    v.tHours,
    v.x,
    v.y,
    v.zeta,
    v.dDegrees,
    v.muDegrees,
    v.l1,
    v.l2,
    v.f1Degrees,
    v.f2Degrees,
    v.tanF1,
    v.tanF2,
    v.gamma,
  ];
  List<num> _polynomialInput(SolarBesselianPolynomial v) => [
    ..._jd(v.referenceEpoch),
    v.spanHours,
    v.sampleStepHours,
    v.degree,
    ...v.xCoefficients,
    ...v.yCoefficients,
    ...v.zetaCoefficients,
    ...v.dDegreesCoefficients,
    ...v.muDegreesCoefficients,
    ...v.l1Coefficients,
    ...v.l2Coefficients,
    v.f1Degrees,
    v.f2Degrees,
    v.tanF1,
    v.tanF2,
    ..._elementsInput(v.center),
    ..._elementsInput(v.maxResidual),
  ];
  LunarEclipseResult<TtScale> _readLunarTt(
    Web_taiyin_lunar_eclipse_result_tt value,
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
    Web_taiyin_lunar_eclipse_result_ut value,
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
    Web_taiyin_local_lunar_eclipse_result_tt value,
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
    Web_taiyin_local_lunar_eclipse_result_ut value,
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

  JulianDate<TtScale>? _ttOrNull(Web_taiyin_split_julian_date value) {
    return value.day_fraction.isFinite ? _readJd<TtScale>(value) : null;
  }

  JulianDate<Ut1Scale>? _ut1OrNull(Web_taiyin_split_julian_date value) {
    return value.day_fraction.isFinite ? _readJd<Ut1Scale>(value) : null;
  }

  JulianDate<TtScale> _requireTtRouteCoordinate(
    Web_taiyin_split_julian_date value,
    String name,
  ) {
    if (!value.day_fraction.isFinite) {
      throw StateError(
        'Native solar eclipse route calculation returned non-finite $name '
        'after a successful calculation',
      );
    }
    return _readJd<TtScale>(value);
  }

  JulianDate<Ut1Scale> _requireUt1RouteCoordinate(
    Web_taiyin_split_julian_date value,
    String name,
  ) {
    if (!value.day_fraction.isFinite) {
      throw StateError(
        'Native solar eclipse route calculation returned non-finite $name '
        'after a successful calculation',
      );
    }
    return _readJd<Ut1Scale>(value);
  }

  SolarEclipseResult<TtScale> _readSolarTt(
    Web_taiyin_solar_eclipse_result_tt value,
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
    Web_taiyin_solar_eclipse_result_ut value,
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
    Web_taiyin_local_solar_eclipse_result_tt value,
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
    Web_taiyin_local_solar_eclipse_result_ut value,
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
    Web_taiyin_solar_eclipse_route_row value,
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

  SolarEclipseWhere _readSolarEclipseWhere(
    Web_taiyin_solar_eclipse_where value,
  ) {
    return SolarEclipseWhere(
      coordinateTt: _readJd<TtScale>(value.jd_tt),
      coordinateUt1: _readJd<Ut1Scale>(value.jd_ut),
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
    Web_taiyin_solar_eclipse_path_point value,
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
    Web_taiyin_solar_eclipse_route_curve_point value,
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
    Web_taiyin_solar_eclipse_route_product_point value,
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
    Web_taiyin_solar_eclipse_route_product_summary value,
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
    Web_taiyin_local_solar_eclipse_boundary value,
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
    Web_taiyin_solar_besselian_elements value,
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
    Web_taiyin_solar_besselian_polynomial value,
  ) {
    return SolarBesselianPolynomial(
      referenceEpoch: _readJd<TtScale>(value.t0_jd_tt),
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

  List<double> _readBesselianCoefficients(List<double> values) {
    return [
      for (
        var index = 0;
        index < SolarBesselianPolynomial.coefficientCount;
        index++
      )
        values[index],
    ];
  }

  double? _finiteOrNull(double v) => v.isFinite ? v : null;
  BigInt _solveMask(
    Set<PositionFlag> positionFlags,
    Set<LunarEclipseSolveOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(
        BigInt.zero,
        (mask, option) => mask | BigInt.from(option.mask),
      ),
    );
  }

  BigInt _searchMask(
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
      options.fold(
        BigInt.zero,
        (mask, option) => mask | BigInt.from(option.mask),
      ),
    );
  }

  BigInt _localVisibilityMask(Set<LocalLunarEclipseVisibilityOption> options) {
    return options.fold(
      BigInt.zero,
      (mask, option) => mask | BigInt.from(option.mask),
    );
  }

  BigInt _localSolarVisibilityMask(
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
    return options.fold(
      BigInt.zero,
      (mask, option) => mask | BigInt.from(option.mask),
    );
  }

  BigInt _positionMask(Set<PositionFlag> positionFlags) {
    return positionFlags.fold(
      BigInt.zero,
      (mask, flag) => mask | BigInt.from(flag.mask),
    );
  }

  BigInt _mergeDisjointMasks(BigInt maskA, BigInt maskB) {
    assert((maskA & maskB) == BigInt.zero, 'Eclipse mask fields overlap');
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
    if (capacity < 0 || capacity > 0xffffffff) {
      throw RangeError.range(capacity, 0, 0xffffffff, name);
    }
    if (capacity <= 0) {
      throw RangeError.range(capacity, 1, null, name);
    }
  }

  BigInt _solarSolveMask(
    Set<PositionFlag> positionFlags,
    Set<SolarEclipseSolveOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(
        BigInt.zero,
        (mask, option) => mask | BigInt.from(option.mask),
      ),
    );
  }

  BigInt _solarSearchMask(
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
      options.fold(
        BigInt.zero,
        (mask, option) => mask | BigInt.from(option.mask),
      ),
    );
  }

  BigInt _solarRouteMask(
    Set<PositionFlag> positionFlags,
    Set<SolarEclipseRouteOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(
        BigInt.zero,
        (mask, option) => mask | BigInt.from(option.mask),
      ),
    );
  }

  BigInt _withSolarContacts(BigInt mask) =>
      mask | BigInt.from(_solarEclipseIncludeContactsBit);
  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
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

  double _requireFiniteNativeRouteCoordinate(double value, String name) {
    if (!value.isFinite) {
      throw StateError(
        'Native solar eclipse route calculation returned non-finite $name '
        'after a successful calculation',
      );
    }
    return value;
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
