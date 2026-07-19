part of '../taiyin.dart';

typedef _SolarTimeStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);

/// Equation-of-time calculations and local solar-time conversions.
final class TaiyinSolarTimeApi {
  TaiyinSolarTimeApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _SolarTimeStatusChecker _checkStatus;

  /// Calculates the equation of time from a UT1 coordinate.
  TaiyinEphemerisResult<TaiyinEquationOfTime> equationOfTimeAtUt1(
    JulianDate<Ut1Scale> ut1,
  ) {
    _ensureOpen();
    return _equationOfTime(
      ut1,
      (input, output, diagnostic) =>
          _bindings.taiyin_calc_equation_of_time_ut_split(
            _context,
            input,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the equation of time from a TT coordinate.
  TaiyinEphemerisResult<TaiyinEquationOfTime> equationOfTimeAtTt(
    JulianDate<TtScale> tt,
  ) {
    _ensureOpen();
    return _equationOfTime(
      tt,
      (input, output, diagnostic) =>
          _bindings.taiyin_calc_equation_of_time_tt_split(
            _context,
            input,
            output,
            diagnostic,
          ),
    );
  }

  /// Converts local mean solar time to local apparent solar time.
  TaiyinEphemerisResult<LocalApparentSolarTime> meanToApparent(
    LocalMeanSolarTime localMean,
  ) {
    _ensureOpen();
    return _convert<
      LocalMeanSolarTimeScale,
      LocalApparentSolarTimeScale,
      LocalApparentSolarTime
    >(
      localMean.coordinate,
      (input, output, diagnostic) =>
          _bindings.taiyin_local_mean_to_apparent_solar_time_split(
            _context,
            input,
            localMean.longitudeRadians,
            output,
            diagnostic,
          ),
      (coordinate) => LocalApparentSolarTime.fromCoordinate(
        coordinate,
        longitudeRadians: localMean.longitudeRadians,
      ),
    );
  }

  /// Converts local apparent solar time to local mean solar time.
  TaiyinEphemerisResult<LocalMeanSolarTime> apparentToMean(
    LocalApparentSolarTime localApparent,
  ) {
    _ensureOpen();
    return _convert<
      LocalApparentSolarTimeScale,
      LocalMeanSolarTimeScale,
      LocalMeanSolarTime
    >(
      localApparent.coordinate,
      (input, output, diagnostic) =>
          _bindings.taiyin_local_apparent_to_mean_solar_time_split(
            _context,
            input,
            localApparent.longitudeRadians,
            output,
            diagnostic,
          ),
      (coordinate) => LocalMeanSolarTime.fromCoordinate(
        coordinate,
        longitudeRadians: localApparent.longitudeRadians,
      ),
    );
  }

  TaiyinEphemerisResult<TaiyinEquationOfTime>
  _equationOfTime<InputScale extends TimeScale>(
    JulianDate<InputScale> input,
    int Function(
      Pointer<taiyin_split_julian_date>,
      Pointer<taiyin_split_equation_of_time_result>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    calculate,
  ) {
    return using((arena) {
      final nativeInput = _writeJulianDate(arena, input);
      final output = arena<taiyin_split_equation_of_time_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_split_equation_of_time_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(nativeInput, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinEquationOfTime(
          ut1: _readJulianDate<Ut1Scale>(value.jd_ut),
          tt: _readJulianDate<TtScale>(value.jd_tt),
          equationDays: value.equation_days,
          equationSeconds: value.equation_seconds,
          apparentSunRightAscensionRadians:
              value.apparent_sun_right_ascension_rad,
          greenwichApparentSiderealTimeRadians: value.gast_rad,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<Output>
  _convert<InputScale extends TimeScale, OutputScale extends TimeScale, Output>(
    JulianDate<InputScale> input,
    int Function(
      Pointer<taiyin_split_julian_date>,
      Pointer<taiyin_split_julian_date>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    convert,
    Output Function(JulianDate<OutputScale>) buildOutput,
  ) {
    return using((arena) {
      final nativeInput = _writeJulianDate(arena, input);
      final output = arena<taiyin_split_julian_date>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = convert(nativeInput, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: buildOutput(_readJulianDate<OutputScale>(output.ref)),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  Pointer<taiyin_split_julian_date> _writeJulianDate<Scale extends TimeScale>(
    Allocator allocator,
    JulianDate<Scale> value,
  ) {
    final native = allocator<taiyin_split_julian_date>();
    native.ref
      ..day_number = value.dayNumber
      ..day_fraction = value.dayFraction;
    return native;
  }

  JulianDate<Scale> _readJulianDate<Scale extends TimeScale>(
    taiyin_split_julian_date value,
  ) {
    return JulianDate<Scale>.fromParts(value.day_number, value.day_fraction);
  }
}
