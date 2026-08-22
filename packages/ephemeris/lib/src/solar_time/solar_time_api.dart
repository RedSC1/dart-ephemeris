part of '../taiyin.dart';

typedef _SolarTimeStatusChecker =
    ResultFlags Function(int status, EphemerisDiagnostic? diagnostic);

/// Equation-of-time calculations and local solar-time conversions.
///
/// These physical calculations consume and produce split [JulianDate] values
/// end to end, preserving the full low-order fraction across the FFI boundary.
final class SolarTimeApi {
  SolarTimeApi._(
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
  OperationResult<EquationOfTime> equationOfTimeAtUt1(
    JulianDate<Ut1Scale> ut1,
  ) {
    _ensureOpen();
    return _equationOfTime(
      (arena, output, diagnostic) => _bindings.taiyin_calc_equation_of_time_ut(
        _context,
        writeJulianDate(arena, ut1),
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates the equation of time from a TT coordinate.
  OperationResult<EquationOfTime> equationOfTimeAtTt(JulianDate<TtScale> tt) {
    _ensureOpen();
    return _equationOfTime(
      (arena, output, diagnostic) => _bindings.taiyin_calc_equation_of_time_tt(
        _context,
        writeJulianDate(arena, tt),
        output,
        diagnostic,
      ),
    );
  }

  /// Converts local mean solar time to local apparent solar time.
  OperationResult<LocalApparentSolarTime> meanToApparent(
    LocalMeanSolarTime localMean,
  ) {
    _ensureOpen();
    return _convert<LocalApparentSolarTimeScale, LocalApparentSolarTime>(
      (arena, output, diagnostic) =>
          _bindings.taiyin_local_mean_to_apparent_solar_time(
            _context,
            writeJulianDate(arena, localMean.coordinate),
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
  OperationResult<LocalMeanSolarTime> apparentToMean(
    LocalApparentSolarTime localApparent,
  ) {
    _ensureOpen();
    return _convert<LocalMeanSolarTimeScale, LocalMeanSolarTime>(
      (arena, output, diagnostic) =>
          _bindings.taiyin_local_apparent_to_mean_solar_time(
            _context,
            writeJulianDate(arena, localApparent.coordinate),
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

  OperationResult<EquationOfTime> _equationOfTime(
    int Function(
      Arena,
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
      final status = calculate(arena, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return operationResult(
        EquationOfTime(
          ut1: readJulianDate<Ut1Scale>(value.jd_ut),
          tt: readJulianDate<TtScale>(value.jd_tt),
          equationDays: value.equation_days,
          equationSeconds: value.equation_seconds,
          apparentSunRightAscensionRadians:
              value.apparent_sun_right_ascension_rad,
          greenwichApparentSiderealTimeRadians: value.gast_rad,
        ),
        resultFlags,
      );
    });
  }

  /// Invokes a native local-solar-time conversion.
  ///
  /// The callback writes one split Julian date through its
  /// `Pointer<taiyin_split_julian_date>` output.
  OperationResult<Output> _convert<OutputScale extends TimeScale, Output>(
    int Function(
      Arena,
      Pointer<taiyin_split_julian_date>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    convert,
    Output Function(JulianDate<OutputScale>) buildOutput,
  ) {
    return using((arena) {
      final output = arena<taiyin_split_julian_date>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = convert(arena, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      return operationResult(
        buildOutput(readJulianDate<OutputScale>(output.ref)),
        resultFlags,
      );
    });
  }
}
