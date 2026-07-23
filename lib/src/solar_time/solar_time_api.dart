part of '../taiyin.dart';

typedef _SolarTimeStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);

/// Equation-of-time calculations and local solar-time conversions.
///
/// These physical calculations use the native scalar-JD epoch route. A split
/// [JulianDate] is intentionally quantized at the native calculation boundary;
/// this API does not claim sub-double solar-time sensitivity.
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
      ut1.toDouble(),
      (input, output, diagnostic) => _bindings.taiyin_calc_equation_of_time_ut(
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
      tt.toDouble(),
      (input, output, diagnostic) => _bindings.taiyin_calc_equation_of_time_tt(
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
    return _convert<LocalApparentSolarTimeScale, LocalApparentSolarTime>(
      localMean.coordinate.toDouble(),
      (input, output, diagnostic) =>
          _bindings.taiyin_local_mean_to_apparent_solar_time(
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
    return _convert<LocalMeanSolarTimeScale, LocalMeanSolarTime>(
      localApparent.coordinate.toDouble(),
      (input, output, diagnostic) =>
          _bindings.taiyin_local_apparent_to_mean_solar_time(
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

  TaiyinEphemerisResult<TaiyinEquationOfTime> _equationOfTime(
    double input,
    int Function(
      double,
      Pointer<taiyin_equation_of_time_result>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_equation_of_time_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_equation_of_time_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(input, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinEquationOfTime(
          ut1: JulianDate<Ut1Scale>.fromDouble(value.jd_ut),
          tt: JulianDate<TtScale>.fromDouble(value.jd_tt),
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

  /// Invokes a scalar native local-solar-time conversion.
  ///
  /// The callback writes one scalar Julian day through its `Pointer<Double>`
  /// output, so the result is deliberately quantized at the native boundary.
  TaiyinEphemerisResult<Output> _convert<OutputScale extends TimeScale, Output>(
    double input,
    int Function(double, Pointer<Double>, Pointer<taiyin_ephemeris_diagnostic>)
    convert,
    Output Function(JulianDate<OutputScale>) buildOutput,
  ) {
    return using((arena) {
      final output = arena<Double>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = convert(input, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: buildOutput(JulianDate<OutputScale>.fromDouble(output.value)),
        diagnostic: mappedDiagnostic,
      );
    });
  }
}
