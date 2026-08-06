part of '../taiyin.dart';

typedef _PhenomenaStatusChecker =
    void Function(int status, EphemerisDiagnostic? diagnostic);

/// Physical and apparent phenomena for major solar-system bodies.
final class PhenomenaApi {
  PhenomenaApi._(
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
  ///
  /// [origin] makes the observer semantics explicit. A topocentric calculation
  /// uses the context's configured observer for observer-dependent values;
  /// lunar [BodyPhenomena.geocentricHorizontalParallaxRadians] remains
  /// geocentric.
  EphemerisResult<BodyPhenomena> atTt(
    Body body,
    JulianDate<TtScale> tt, {
    PhenomenaOrigin origin = PhenomenaOrigin.geocentric,
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _calculate(
      body,
      origin,
      flags,
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_body_phenomena_tt(
            _context,
            body.id,
            writeJulianDate(arena, tt),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates body phenomena at a UT1 coordinate.
  ///
  /// [origin] makes the observer semantics explicit. A topocentric calculation
  /// uses the context's configured observer for observer-dependent values;
  /// lunar [BodyPhenomena.geocentricHorizontalParallaxRadians] remains
  /// geocentric.
  EphemerisResult<BodyPhenomena> atUt1(
    Body body,
    JulianDate<Ut1Scale> ut1, {
    PhenomenaOrigin origin = PhenomenaOrigin.geocentric,
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _calculate(
      body,
      origin,
      flags,
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_body_phenomena_ut(
            _context,
            body.id,
            writeJulianDate(arena, ut1),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  EphemerisResult<BodyPhenomena> _calculate(
    Body body,
    PhenomenaOrigin origin,
    Set<PositionFlag> flags,
    int Function(
      Arena arena,
      int,
      Pointer<taiyin_body_phenomena>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    calculate,
  ) {
    _requireSupportedBody(body);
    if (flags.contains(PositionFlag.topocentric)) {
      throw ArgumentError.value(
        flags,
        'flags',
        'use the origin parameter for topocentric phenomena',
      );
    }
    final frozenFlags = Set<PositionFlag>.unmodifiable(flags);
    var mask = frozenFlags.fold(0, (value, flag) => value | flag.mask);
    if (origin == PhenomenaOrigin.topocentric) {
      mask |= PositionFlag.topocentric.mask;
    }
    return using((arena) {
      final output = arena<taiyin_body_phenomena>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_body_phenomena_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, mask, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return EphemerisResult(
        value: BodyPhenomena(
          body: body,
          phaseAngleRadians: value.phase_angle_rad,
          illuminatedFraction: value.illuminated_fraction,
          solarElongationRadians: value.solar_elongation_rad,
          apparentDiameterRadians: value.apparent_diameter_rad,
          apparentMagnitude: value.apparent_magnitude,
          geocentricHorizontalParallaxRadians:
              value.horizontal_parallax_rad.isFinite
              ? value.horizontal_parallax_rad
              : null,
          origin: origin,
          flags: frozenFlags,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  void _requireSupportedBody(Body body) {
    const supported = {
      Body.sun,
      Body.moon,
      Body.mercury,
      Body.venus,
      Body.mars,
      Body.jupiter,
      Body.saturn,
      Body.uranus,
      Body.neptune,
      Body.pluto,
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
