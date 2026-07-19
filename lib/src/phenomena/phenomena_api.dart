part of '../taiyin.dart';

typedef _PhenomenaStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);

/// Physical and apparent phenomena for major solar-system bodies.
final class TaiyinPhenomenaApi {
  TaiyinPhenomenaApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _PhenomenaStatusChecker _checkStatus;

  /// Calculates body phenomena at a TT coordinate.
  TaiyinEphemerisResult<TaiyinBodyPhenomena> atTt(
    TaiyinBody body,
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _calculate(
      body,
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_body_phenomena_tt(
        _context,
        body.id,
        tt.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates body phenomena at a UT1 coordinate.
  TaiyinEphemerisResult<TaiyinBodyPhenomena> atUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> ut1, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _calculate(
      body,
      flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_body_phenomena_ut(
        _context,
        body.id,
        ut1.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  TaiyinEphemerisResult<TaiyinBodyPhenomena> _calculate(
    TaiyinBody body,
    Set<TaiyinPositionFlag> flags,
    int Function(
      int,
      Pointer<taiyin_body_phenomena>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    calculate,
  ) {
    _requireSupportedBody(body);
    final frozenFlags = Set<TaiyinPositionFlag>.unmodifiable(flags);
    final mask = frozenFlags.fold(0, (value, flag) => value | flag.mask);
    return using((arena) {
      final output = arena<taiyin_body_phenomena>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_body_phenomena_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(mask, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinBodyPhenomena(
          body: body,
          phaseAngleRadians: value.phase_angle_rad,
          illuminatedFraction: value.illuminated_fraction,
          solarElongationRadians: value.solar_elongation_rad,
          apparentDiameterRadians: value.apparent_diameter_rad,
          apparentMagnitude: value.apparent_magnitude,
          horizontalParallaxRadians: value.horizontal_parallax_rad.isFinite
              ? value.horizontal_parallax_rad
              : null,
          flags: frozenFlags,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  void _requireSupportedBody(TaiyinBody body) {
    const supported = {
      TaiyinBody.sun,
      TaiyinBody.moon,
      TaiyinBody.mercury,
      TaiyinBody.venus,
      TaiyinBody.mars,
      TaiyinBody.jupiter,
      TaiyinBody.saturn,
      TaiyinBody.uranus,
      TaiyinBody.neptune,
      TaiyinBody.pluto,
    };
    if (!supported.contains(body)) {
      throw ArgumentError.value(
        body,
        'body',
        'phenomena support the Sun, Moon, and physical planets only',
      );
    }
  }
}
