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
      (output, diagnostic) => _bindings.taiyin_calc_equation_of_time_ut(
        _context,
        ut1.toDouble(),
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
      (output, diagnostic) => _bindings.taiyin_calc_equation_of_time_tt(
        _context,
        tt.toDouble(),
        output,
        diagnostic,
      ),
    );
  }

  /// Converts local mean solar time to local apparent solar time.
  ///
  /// [longitudeRadians] is east-positive in the range `[-π, π]`.
  TaiyinEphemerisResult<JulianDate<LocalApparentSolarTimeScale>> meanToApparent(
    JulianDate<LocalMeanSolarTimeScale> localMean,
    double longitudeRadians,
  ) {
    _ensureOpen();
    _requireLongitude(longitudeRadians);
    return _convert<LocalApparentSolarTimeScale>(
      (output, diagnostic) =>
          _bindings.taiyin_local_mean_to_apparent_solar_time(
            _context,
            localMean.toDouble(),
            longitudeRadians,
            output,
            diagnostic,
          ),
    );
  }

  /// Converts local apparent solar time to local mean solar time.
  ///
  /// [longitudeRadians] is east-positive in the range `[-π, π]`.
  TaiyinEphemerisResult<JulianDate<LocalMeanSolarTimeScale>> apparentToMean(
    JulianDate<LocalApparentSolarTimeScale> localApparent,
    double longitudeRadians,
  ) {
    _ensureOpen();
    _requireLongitude(longitudeRadians);
    return _convert<LocalMeanSolarTimeScale>(
      (output, diagnostic) =>
          _bindings.taiyin_local_apparent_to_mean_solar_time(
            _context,
            localApparent.toDouble(),
            longitudeRadians,
            output,
            diagnostic,
          ),
    );
  }

  TaiyinEphemerisResult<TaiyinEquationOfTime> _equationOfTime(
    int Function(
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
      final status = calculate(output, diagnostic);
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

  TaiyinEphemerisResult<JulianDate<Output>> _convert<Output extends TimeScale>(
    int Function(Pointer<Double>, Pointer<taiyin_ephemeris_diagnostic>) convert,
  ) {
    return using((arena) {
      final output = arena<Double>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = convert(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: JulianDate<Output>.fromDouble(output.value),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  void _requireLongitude(double value) {
    if (!value.isFinite || value < -math.pi || value > math.pi) {
      throw ArgumentError.value(
        value,
        'longitudeRadians',
        'must be finite and in [-pi, pi]',
      );
    }
  }
}
