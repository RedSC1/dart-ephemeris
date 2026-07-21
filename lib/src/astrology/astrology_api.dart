part of '../taiyin.dart';

typedef _AstrologyStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);
typedef _SiderealCalculation =
    int Function(
      int flags,
      Pointer<taiyin_sidereal_position> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _HouseCalculation = int Function(Pointer<taiyin_house_result> output);

/// Sidereal coordinates and astrological house calculations.
///
/// These physical calculations use the native scalar-JD epoch route. A split
/// [JulianDate] is intentionally quantized at the native calculation boundary;
/// this API does not claim sub-double ephemeris sensitivity.
final class TaiyinAstrologyApi {
  TaiyinAstrologyApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _AstrologyStatusChecker _checkStatus;

  /// Evaluates an ayanamsha at a TT coordinate.
  double ayanamshaAtTt(
    JulianDate<TtScale> tt, {
    TaiyinAyanamsha ayanamsha = TaiyinAyanamsha.faganBradley,
    TaiyinSiderealPrecessionPolicy precessionPolicy =
        TaiyinSiderealPrecessionPolicy.compensateToReference,
  }) {
    _ensureOpen();
    return using((arena) {
      final output = arena<Double>();
      _checkStatus(
        _bindings.taiyin_calc_ayanamsha_tt(
          _context,
          ayanamsha.id,
          precessionPolicy.id,
          tt.toDouble(),
          output,
        ),
        null,
      );
      return output.value;
    });
  }

  /// Calculates sidereal ecliptic coordinates at TT.
  TaiyinEphemerisResult<TaiyinSiderealPosition> siderealPositionAtTt(
    TaiyinTarget target,
    JulianDate<TtScale> tt, {
    TaiyinAyanamsha ayanamsha = TaiyinAyanamsha.faganBradley,
    TaiyinSiderealPrecessionPolicy precessionPolicy =
        TaiyinSiderealPrecessionPolicy.compensateToReference,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _siderealFlags(flags);
    return _siderealPosition(
      target,
      ayanamsha,
      precessionPolicy,
      resolvedFlags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_sidereal_position_tt(
        _context,
        ayanamsha.id,
        precessionPolicy.id,
        target.id,
        tt.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates sidereal ecliptic coordinates at UT1 using the context policy.
  TaiyinEphemerisResult<TaiyinSiderealPosition> siderealPositionAtUt1(
    TaiyinTarget target,
    JulianDate<Ut1Scale> ut1, {
    TaiyinAyanamsha ayanamsha = TaiyinAyanamsha.faganBradley,
    TaiyinSiderealPrecessionPolicy precessionPolicy =
        TaiyinSiderealPrecessionPolicy.compensateToReference,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _siderealFlags(flags);
    return _siderealPosition(
      target,
      ayanamsha,
      precessionPolicy,
      resolvedFlags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_sidereal_position_ut(
        _context,
        ayanamsha.id,
        precessionPolicy.id,
        target.id,
        ut1.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates houses directly from ARMC, latitude, and true obliquity.
  TaiyinHouses housesFromArmc({
    required double armcRadians,
    required double observerLatitudeRadians,
    required double trueObliquityRadians,
    TaiyinHouseSystem system = TaiyinHouseSystem.porphyry,
  }) {
    _ensureOpen();
    _requireFinite(armcRadians, 'armcRadians');
    _requireFinite(observerLatitudeRadians, 'observerLatitudeRadians');
    _requireFinite(trueObliquityRadians, 'trueObliquityRadians');
    return _houses(
      (output) => _bindings.taiyin_calc_houses_from_armc(
        armcRadians,
        observerLatitudeRadians,
        trueObliquityRadians,
        system.id,
        output,
      ),
    );
  }

  /// Calculates houses at a UT1 coordinate using the context observer.
  TaiyinHouses housesAtUt1(
    JulianDate<Ut1Scale> ut1, {
    TaiyinHouseSystem system = TaiyinHouseSystem.porphyry,
  }) {
    _ensureOpen();
    return _houses(
      (output) => _bindings.taiyin_calc_houses_ut(
        _context,
        ut1.toDouble(),
        system.id,
        output,
      ),
    );
  }

  /// Calculates houses at a TT coordinate using the context observer.
  TaiyinHouses housesAtTt(
    JulianDate<TtScale> tt, {
    TaiyinHouseSystem system = TaiyinHouseSystem.porphyry,
  }) {
    _ensureOpen();
    return _houses(
      (output) => _bindings.taiyin_calc_houses_tt(
        _context,
        tt.toDouble(),
        system.id,
        output,
      ),
    );
  }

  /// Locates an ecliptic longitude within [houses].
  TaiyinHousePosition housePositionOf(
    TaiyinHouses houses,
    double eclipticLongitudeRadians,
  ) {
    _ensureOpen();
    _requireFinite(eclipticLongitudeRadians, 'eclipticLongitudeRadians');
    return using((arena) {
      final nativeHouses = _writeHouses(arena, houses);
      final output = arena<taiyin_house_position_result>();
      _bindings.taiyin_house_position_result_init(output);
      _checkStatus(
        _bindings.taiyin_calc_house_position_from_longitude(
          nativeHouses,
          eclipticLongitudeRadians,
          output,
        ),
        null,
      );
      return TaiyinHousePosition(
        houseNumber: output.ref.house_number,
        fraction: output.ref.fraction,
        continuousHousePosition: output.ref.continuous_house_position,
      );
    });
  }

  /// Whether the native runtime provides this built-in ayanamsha model.
  bool hasAyanamshaModel(TaiyinAyanamsha ayanamsha) {
    _ensureOpen();
    return _bindings.taiyin_has_ayanamsha_model(ayanamsha.id) != 0;
  }

  /// Whether the native runtime provides this built-in house-system model.
  bool hasHouseSystemModel(TaiyinHouseSystem system) {
    _ensureOpen();
    return _bindings.taiyin_has_house_system_model(system.id) != 0;
  }

  TaiyinEphemerisResult<TaiyinSiderealPosition> _siderealPosition(
    TaiyinTarget target,
    TaiyinAyanamsha ayanamsha,
    TaiyinSiderealPrecessionPolicy precessionPolicy,
    Set<TaiyinPositionFlag> flags,
    _SiderealCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_sidereal_position>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_sidereal_position_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final mask = flags.fold(0, (value, flag) => value | flag.mask);
      final status = calculate(mask, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinSiderealPosition(
          target: target,
          ayanamsha: ayanamsha,
          precessionPolicy: precessionPolicy,
          tropicalLongitudeRadians: value.tropical_longitude_rad,
          siderealLongitudeRadians: value.sidereal_longitude_rad,
          latitudeRadians: value.latitude_rad,
          distanceAu: value.distance_au,
          tropicalLongitudeRateRadiansPerDay:
              value.tropical_longitude_rate_rad_per_day,
          siderealLongitudeRateRadiansPerDay:
              value.sidereal_longitude_rate_rad_per_day,
          flags: flags,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinHouses _houses(_HouseCalculation calculate) {
    return using((arena) {
      final output = arena<taiyin_house_result>();
      _bindings.taiyin_house_result_init(output);
      _checkStatus(calculate(output), null);
      return _readHouses(output.ref);
    });
  }

  TaiyinHouses _readHouses(taiyin_house_result value) {
    final flags = {
      for (final flag in TaiyinHouseResultFlag.values)
        if ((value.flags & flag.mask) != 0) flag,
    };
    return TaiyinHouses(
      requestedSystemId: value.requested_system_id,
      resolvedSystemId: value.resolved_system_id,
      rawFlags: value.flags,
      flags: flags,
      armcRadians: value.armc_rad,
      ascendantRadians: value.ascendant_rad,
      midheavenRadians: value.midheaven_rad,
      vertexRadians: value.vertex_rad,
      eastPointRadians: value.east_point_rad,
      armcRateRadiansPerDay: value.armc_rate_rad_per_day,
      ascendantRateRadiansPerDay: value.ascendant_rate_rad_per_day,
      midheavenRateRadiansPerDay: value.midheaven_rate_rad_per_day,
      vertexRateRadiansPerDay: value.vertex_rate_rad_per_day,
      eastPointRateRadiansPerDay: value.east_point_rate_rad_per_day,
      cuspLongitudesRadians: [
        for (var index = 0; index < 12; index++)
          value.cusp_longitude_rad[index],
      ],
      cuspLongitudeRatesRadiansPerDay: [
        for (var index = 0; index < 12; index++)
          value.cusp_longitude_rate_rad_per_day[index],
      ],
    );
  }

  Pointer<taiyin_house_result> _writeHouses(Arena arena, TaiyinHouses houses) {
    final output = arena<taiyin_house_result>();
    _bindings.taiyin_house_result_init(output);
    output.ref
      ..requested_system_id = houses.requestedSystemId
      ..resolved_system_id = houses.resolvedSystemId
      ..flags = houses.rawFlags
      ..armc_rad = houses.armcRadians
      ..ascendant_rad = houses.ascendantRadians
      ..midheaven_rad = houses.midheavenRadians
      ..vertex_rad = houses.vertexRadians
      ..east_point_rad = houses.eastPointRadians
      ..armc_rate_rad_per_day = houses.armcRateRadiansPerDay
      ..ascendant_rate_rad_per_day = houses.ascendantRateRadiansPerDay
      ..midheaven_rate_rad_per_day = houses.midheavenRateRadiansPerDay
      ..vertex_rate_rad_per_day = houses.vertexRateRadiansPerDay
      ..east_point_rate_rad_per_day = houses.eastPointRateRadiansPerDay;
    for (var index = 0; index < 12; index++) {
      output.ref.cusp_longitude_rad[index] =
          houses.cuspLongitudesRadians[index];
      output.ref.cusp_longitude_rate_rad_per_day[index] =
          houses.cuspLongitudeRatesRadiansPerDay[index];
    }
    return output;
  }

  Set<TaiyinPositionFlag> _siderealFlags(Set<TaiyinPositionFlag> flags) {
    if (flags.contains(TaiyinPositionFlag.xyz) ||
        flags.contains(TaiyinPositionFlag.equatorial)) {
      throw ArgumentError.value(
        flags,
        'flags',
        'sidereal positions are ecliptic longitudes and do not support XYZ or equatorial output',
      );
    }
    return Set.unmodifiable({...flags, TaiyinPositionFlag.radians});
  }

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }
}
