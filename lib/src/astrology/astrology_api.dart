part of '../taiyin.dart';

typedef _AstrologyStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);
typedef _SiderealCalculation =
    int Function(
      int flags,
      Pointer<taiyin_sidereal_position> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SiderealCoordinatesCalculation =
    int Function(
      int flags,
      Pointer<taiyin_sidereal_coordinates> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LunarNodeCalculation =
    int Function(
      int flags,
      Pointer<taiyin_lunar_node_position> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LunarApsisCalculation =
    int Function(
      int flags,
      Pointer<taiyin_lunar_apsis_position> output,
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
    TaiyinAyanamshaModel ayanamsha = TaiyinAyanamsha.faganBradley,
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
          tt.toDouble(),
          precessionPolicy.nativeFlagMask,
          output,
        ),
        null,
      );
      return output.value;
    });
  }

  /// Calculates sidereal ecliptic coordinates at TT.
  ///
  /// [flags] retain their normal physical-correction semantics. This
  /// specialized result always has ecliptic spherical coordinates, so
  /// [TaiyinPositionFlag.xyz] and [TaiyinPositionFlag.equatorial] are
  /// rejected. [TaiyinPositionFlag.radians] is added automatically.
  TaiyinEphemerisResult<TaiyinSiderealPosition> siderealPositionAtTt(
    TaiyinTarget target,
    JulianDate<TtScale> tt, {
    TaiyinAyanamshaModel ayanamsha = TaiyinAyanamsha.faganBradley,
    TaiyinSiderealPrecessionPolicy precessionPolicy =
        TaiyinSiderealPrecessionPolicy.compensateToReference,
    TaiyinSiderealReferencePlane referencePlane =
        TaiyinSiderealReferencePlane.meanEclipticOfDate,
    TaiyinSiderealReferenceEpoch? referenceEpoch,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _siderealFlags(flags);
    final resolvedCall = _resolveSiderealCall(
      resolvedFlags,
      precessionPolicy,
      referencePlane,
      referenceEpoch,
    );
    return _siderealPosition(
      target,
      ayanamsha,
      precessionPolicy,
      referencePlane,
      referenceEpoch,
      resolvedFlags,
      resolvedCall.flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_sidereal_position_tt(
        _context,
        ayanamsha.id,
        target.id,
        tt.toDouble(),
        mask,
        resolvedCall.referenceEpochJulianDate,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates sidereal ecliptic coordinates at UT1 using the context policy.
  ///
  /// [flags] follow the same restrictions as [siderealPositionAtTt].
  TaiyinEphemerisResult<TaiyinSiderealPosition> siderealPositionAtUt1(
    TaiyinTarget target,
    JulianDate<Ut1Scale> ut1, {
    TaiyinAyanamshaModel ayanamsha = TaiyinAyanamsha.faganBradley,
    TaiyinSiderealPrecessionPolicy precessionPolicy =
        TaiyinSiderealPrecessionPolicy.compensateToReference,
    TaiyinSiderealReferencePlane referencePlane =
        TaiyinSiderealReferencePlane.meanEclipticOfDate,
    TaiyinSiderealReferenceEpoch? referenceEpoch,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _siderealFlags(flags);
    final resolvedCall = _resolveSiderealCall(
      resolvedFlags,
      precessionPolicy,
      referencePlane,
      referenceEpoch,
    );
    return _siderealPosition(
      target,
      ayanamsha,
      precessionPolicy,
      referencePlane,
      referenceEpoch,
      resolvedFlags,
      resolvedCall.flags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_sidereal_position_ut(
        _context,
        ayanamsha.id,
        target.id,
        ut1.toDouble(),
        mask,
        resolvedCall.referenceEpochJulianDate,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates generic sidereal coordinates at TT.
  ///
  /// This is the coordinate-mode counterpart to [siderealPositionAtTt]. It
  /// accepts [TaiyinPositionFlag.equatorial], [TaiyinPositionFlag.xyz], and
  /// their combination. Without `equatorial`, the result is on the sidereal
  /// selected sidereal reference plane and [TaiyinPositionFlag.noNutation] has
  /// no further effect. With `equatorial`, this follows conventional Swiss
  /// Ephemeris-compatible behavior: the result is tropical mean equator of
  /// date with `noNutation`, or tropical true equator of date without it, and
  /// is independent of [ayanamsha], [precessionPolicy], and [referencePlane].
  /// [TaiyinPositionFlag.radians] is added automatically. Other position flags
  /// retain their ordinary native physical-correction semantics.
  TaiyinEphemerisResult<TaiyinSiderealCoordinates> siderealCoordinatesAtTt(
    TaiyinTarget target,
    JulianDate<TtScale> tt, {
    TaiyinAyanamshaModel ayanamsha = TaiyinAyanamsha.faganBradley,
    TaiyinSiderealPrecessionPolicy precessionPolicy =
        TaiyinSiderealPrecessionPolicy.compensateToReference,
    TaiyinSiderealReferencePlane referencePlane =
        TaiyinSiderealReferencePlane.meanEclipticOfDate,
    TaiyinSiderealReferenceEpoch? referenceEpoch,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _genericSiderealFlags(flags);
    final resolvedCall = _resolveSiderealCall(
      resolvedFlags,
      precessionPolicy,
      referencePlane,
      referenceEpoch,
    );
    return _siderealCoordinates(
      target,
      ayanamsha,
      precessionPolicy,
      referencePlane,
      referenceEpoch,
      resolvedFlags,
      resolvedCall.flags,
      (mask, output, diagnostic) =>
          _bindings.taiyin_calc_sidereal_coordinates_tt(
            _context,
            ayanamsha.id,
            target.id,
            tt.toDouble(),
            mask,
            resolvedCall.referenceEpochJulianDate,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates generic sidereal coordinates at UT1 using the context policy.
  ///
  /// See [siderealCoordinatesAtTt] for coordinate-mode and frame semantics.
  TaiyinEphemerisResult<TaiyinSiderealCoordinates> siderealCoordinatesAtUt1(
    TaiyinTarget target,
    JulianDate<Ut1Scale> ut1, {
    TaiyinAyanamshaModel ayanamsha = TaiyinAyanamsha.faganBradley,
    TaiyinSiderealPrecessionPolicy precessionPolicy =
        TaiyinSiderealPrecessionPolicy.compensateToReference,
    TaiyinSiderealReferencePlane referencePlane =
        TaiyinSiderealReferencePlane.meanEclipticOfDate,
    TaiyinSiderealReferenceEpoch? referenceEpoch,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _genericSiderealFlags(flags);
    final resolvedCall = _resolveSiderealCall(
      resolvedFlags,
      precessionPolicy,
      referencePlane,
      referenceEpoch,
    );
    return _siderealCoordinates(
      target,
      ayanamsha,
      precessionPolicy,
      referencePlane,
      referenceEpoch,
      resolvedFlags,
      resolvedCall.flags,
      (mask, output, diagnostic) =>
          _bindings.taiyin_calc_sidereal_coordinates_ut(
            _context,
            ayanamsha.id,
            target.id,
            ut1.toDouble(),
            mask,
            resolvedCall.referenceEpochJulianDate,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the geocentric osculating ("true") lunar node at TT.
  ///
  /// The result is an angular direction, not a Cartesian body position. It
  /// accepts apparent-correction flags such as `truePosition` and frame
  /// selection through `equatorial` / `noNutation`; it always returns radians
  /// and radians per day, so `radians` and `speed` are not accepted.
  TaiyinEphemerisResult<TaiyinLunarNodePosition> lunarTrueNodeAtTt(
    JulianDate<TtScale> tt, {
    TaiyinLunarNodeKind kind = TaiyinLunarNodeKind.ascending,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _lunarPhysicalFlags(flags, 'lunar true node');
    return _lunarNode(
      kind,
      resolvedFlags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_lunar_true_node_tt(
        _context,
        tt.toDouble(),
        kind.id,
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates the geocentric osculating ("true") lunar node at UT1.
  ///
  /// See [lunarTrueNodeAtTt] for the result and flag contract.
  TaiyinEphemerisResult<TaiyinLunarNodePosition> lunarTrueNodeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    TaiyinLunarNodeKind kind = TaiyinLunarNodeKind.ascending,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _lunarPhysicalFlags(flags, 'lunar true node');
    return _lunarNode(
      kind,
      resolvedFlags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_lunar_true_node_ut(
        _context,
        ut1.toDouble(),
        kind.id,
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates the IERS 2003 conventional mean lunar node at TT.
  ///
  /// This is a mean-model direction, so only `equatorial` and `noNutation`
  /// select its output frame; physical apparent-correction flags do not apply.
  TaiyinEphemerisResult<TaiyinLunarNodePosition> lunarMeanNodeAtTt(
    JulianDate<TtScale> tt, {
    TaiyinLunarNodeKind kind = TaiyinLunarNodeKind.ascending,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _lunarMeanFlags(flags, 'lunar mean node');
    return _lunarNode(
      kind,
      resolvedFlags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_lunar_mean_node_tt(
        _context,
        tt.toDouble(),
        kind.id,
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates the IERS 2003 conventional mean lunar node at UT1.
  ///
  /// See [lunarMeanNodeAtTt] for the result and flag contract.
  TaiyinEphemerisResult<TaiyinLunarNodePosition> lunarMeanNodeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    TaiyinLunarNodeKind kind = TaiyinLunarNodeKind.ascending,
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _lunarMeanFlags(flags, 'lunar mean node');
    return _lunarNode(
      kind,
      resolvedFlags,
      (mask, output, diagnostic) => _bindings.taiyin_calc_lunar_mean_node_ut(
        _context,
        ut1.toDouble(),
        kind.id,
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates the Delaunay mean lunar apogee (mean Lilith) at TT.
  ///
  /// This conventional direction has no physical distance, so its
  /// [TaiyinLunarApsisPosition.distanceAu] fields are null.
  TaiyinEphemerisResult<TaiyinLunarApsisPosition> lunarMeanApogeeAtTt(
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarMeanFlags(flags, 'lunar mean apogee'),
      (mask, output, diagnostic) => _bindings.taiyin_calc_lunar_mean_apogee_tt(
        _context,
        tt.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates the Delaunay mean lunar apogee (mean Lilith) at UT1.
  ///
  /// See [lunarMeanApogeeAtTt] for the result and flag contract.
  TaiyinEphemerisResult<TaiyinLunarApsisPosition> lunarMeanApogeeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarMeanFlags(flags, 'lunar mean apogee'),
      (mask, output, diagnostic) => _bindings.taiyin_calc_lunar_mean_apogee_ut(
        _context,
        ut1.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates the geocentric osculating lunar apogee at TT.
  ///
  /// This instantaneous two-body apoapsis is commonly called true Lilith.
  TaiyinEphemerisResult<TaiyinLunarApsisPosition> lunarOsculatingApogeeAtTt(
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarPhysicalFlags(flags, 'lunar osculating apogee'),
      (mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_osculating_apogee_tt(
            _context,
            tt.toDouble(),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the geocentric osculating lunar apogee at UT1.
  ///
  /// See [lunarOsculatingApogeeAtTt] for the result and flag contract.
  TaiyinEphemerisResult<TaiyinLunarApsisPosition> lunarOsculatingApogeeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarPhysicalFlags(flags, 'lunar osculating apogee'),
      (mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_osculating_apogee_ut(
            _context,
            ut1.toDouble(),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the DE441 fitted-natural lunar apogee at TT.
  ///
  /// The result reports [TaiyinLunarApsisPosition.extrapolated] when the
  /// requested date lies outside the fitted DE441 interval. Unlike the
  /// conventional mean apogee, it includes a physical distance and rate from
  /// the fitted model.
  TaiyinEphemerisResult<TaiyinLunarApsisPosition> lunarFittedApogeeAtTt(
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarMeanFlags(flags, 'lunar fitted apogee'),
      (mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_fitted_apogee_tt(
            _context,
            tt.toDouble(),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the DE441 fitted-natural lunar apogee at UT1.
  ///
  /// See [lunarFittedApogeeAtTt] for the result and flag contract.
  TaiyinEphemerisResult<TaiyinLunarApsisPosition> lunarFittedApogeeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarMeanFlags(flags, 'lunar fitted apogee'),
      (mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_fitted_apogee_ut(
            _context,
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
    TaiyinHouseSystemModel system = TaiyinHouseSystem.porphyry,
  }) {
    _ensureOpen();
    _requireFinite(armcRadians, 'armcRadians');
    _requireFinite(observerLatitudeRadians, 'observerLatitudeRadians');
    _requireFinite(trueObliquityRadians, 'trueObliquityRadians');
    _requireOpenLatitude(observerLatitudeRadians, 'observerLatitudeRadians');
    _requireOpenObliquity(trueObliquityRadians, 'trueObliquityRadians');
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
    TaiyinHouseSystemModel system = TaiyinHouseSystem.porphyry,
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
    TaiyinHouseSystemModel system = TaiyinHouseSystem.porphyry,
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

  /// Whether the native runtime provides [ayanamsha].
  bool hasAyanamshaModel(TaiyinAyanamshaModel ayanamsha) {
    _ensureOpen();
    return _bindings.taiyin_has_ayanamsha_model(ayanamsha.id) != 0;
  }

  /// Whether the native runtime provides [system].
  bool hasHouseSystemModel(TaiyinHouseSystemModel system) {
    _ensureOpen();
    return _bindings.taiyin_has_house_system_model(system.id) != 0;
  }

  TaiyinEphemerisResult<TaiyinSiderealPosition> _siderealPosition(
    TaiyinTarget target,
    TaiyinAyanamshaModel ayanamsha,
    TaiyinSiderealPrecessionPolicy precessionPolicy,
    TaiyinSiderealReferencePlane referencePlane,
    TaiyinSiderealReferenceEpoch? referenceEpoch,
    Set<TaiyinPositionFlag> flags,
    int nativeFlags,
    _SiderealCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_sidereal_position>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_sidereal_position_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(nativeFlags, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinSiderealPosition(
          target: target,
          ayanamsha: ayanamsha,
          precessionPolicy: precessionPolicy,
          referencePlane: referencePlane,
          referenceEpoch: referenceEpoch,
          coordinateFrame: TaiyinSiderealCoordinateFrame.fromId(
            value.coordinate_frame_id,
          ),
          rawCoordinateFrameId: value.coordinate_frame_id,
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

  TaiyinEphemerisResult<TaiyinSiderealCoordinates> _siderealCoordinates(
    TaiyinTarget target,
    TaiyinAyanamshaModel ayanamsha,
    TaiyinSiderealPrecessionPolicy precessionPolicy,
    TaiyinSiderealReferencePlane referencePlane,
    TaiyinSiderealReferenceEpoch? referenceEpoch,
    Set<TaiyinPositionFlag> flags,
    int nativeFlags,
    _SiderealCoordinatesCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_sidereal_coordinates>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_sidereal_coordinates_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(nativeFlags, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      final outputFlags = Set<TaiyinPositionFlag>.unmodifiable({
        for (final flag in TaiyinPositionFlag.values)
          if ((value.position_flags & flag.mask) != 0) flag,
      });
      return TaiyinEphemerisResult(
        value: TaiyinSiderealCoordinates(
          target: target,
          ayanamsha: ayanamsha,
          precessionPolicy: precessionPolicy,
          referencePlane: referencePlane,
          referenceEpoch: referenceEpoch,
          coordinateFrame: TaiyinSiderealCoordinateFrame.fromId(
            value.coordinate_frame_id,
          ),
          rawCoordinateFrameId: value.coordinate_frame_id,
          values: [for (var index = 0; index < 6; index++) value.values[index]],
          flags: outputFlags,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLunarNodePosition> _lunarNode(
    TaiyinLunarNodeKind kind,
    Set<TaiyinPositionFlag> flags,
    _LunarNodeCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_node_position>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_node_position_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(_flagMask(flags), output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinLunarNodePosition(
          kind: kind,
          referenceFrame: TaiyinApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          longitudeRadians: value.longitude_rad,
          longitudeRateRadiansPerDay: value.longitude_rate_rad_per_day,
          flags: flags,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLunarApsisPosition> _lunarApsis(
    Set<TaiyinPositionFlag> flags,
    _LunarApsisCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_apsis_position>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_apsis_position_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(_flagMask(flags), output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinLunarApsisPosition(
          referenceFrame: TaiyinApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          definition: TaiyinLunarApsisDefinition.fromId(value.definition),
          rawDefinitionId: value.definition,
          longitudeRadians: value.longitude_rad,
          latitudeRadians: value.latitude_rad,
          longitudeRateRadiansPerDay: value.longitude_rate_rad_per_day,
          latitudeRateRadiansPerDay: value.latitude_rate_rad_per_day,
          distanceAu: _finiteOrNull(value.distance_au),
          distanceRateAuPerDay: _finiteOrNull(value.distance_rate_au_per_day),
          extrapolated: value.extrapolated != 0,
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

  Set<TaiyinPositionFlag> _genericSiderealFlags(
    Set<TaiyinPositionFlag> flags,
  ) => Set.unmodifiable({...flags, TaiyinPositionFlag.radians});

  ({int flags, double referenceEpochJulianDate}) _resolveSiderealCall(
    Set<TaiyinPositionFlag> positionFlags,
    TaiyinSiderealPrecessionPolicy precessionPolicy,
    TaiyinSiderealReferencePlane referencePlane,
    TaiyinSiderealReferenceEpoch? referenceEpoch,
  ) {
    if (referencePlane.requiresReferenceEpoch != (referenceEpoch != null)) {
      final requirement = referencePlane.requiresReferenceEpoch
          ? 'requires a referenceEpoch'
          : 'does not accept a referenceEpoch';
      throw ArgumentError.value(referenceEpoch, 'referenceEpoch', requirement);
    }
    final nativeFlags =
        _flagMask(positionFlags) |
        precessionPolicy.nativeFlagMask |
        referencePlane.nativeFlagMask |
        (referenceEpoch?.isUt1 == true ? 1 << 35 : 0);
    return (
      flags: nativeFlags,
      referenceEpochJulianDate: referenceEpoch?.nativeJulianDate ?? double.nan,
    );
  }

  Set<TaiyinPositionFlag> _lunarPhysicalFlags(
    Set<TaiyinPositionFlag> flags,
    String calculation,
  ) => _lunarFlags(flags, calculation, _lunarPhysicalAllowedFlags);

  Set<TaiyinPositionFlag> _lunarMeanFlags(
    Set<TaiyinPositionFlag> flags,
    String calculation,
  ) => _lunarFlags(flags, calculation, _lunarMeanAllowedFlags);

  Set<TaiyinPositionFlag> _lunarFlags(
    Set<TaiyinPositionFlag> flags,
    String calculation,
    Set<TaiyinPositionFlag> allowed,
  ) {
    final unsupported = flags.difference(allowed);
    if (unsupported.isNotEmpty) {
      final unsupportedNames = [
        for (final flag in TaiyinPositionFlag.values)
          if (unsupported.contains(flag)) flag.name,
      ];
      final allowedNames = [
        for (final flag in TaiyinPositionFlag.values)
          if (allowed.contains(flag)) flag.name,
      ];
      throw ArgumentError.value(
        flags,
        'flags',
        '$calculation does not support ${unsupportedNames.join(', ')}; '
            'allowed: ${allowedNames.join(', ')}',
      );
    }
    return Set.unmodifiable(flags);
  }

  int _flagMask(Set<TaiyinPositionFlag> flags) =>
      flags.fold(0, (value, flag) => value | flag.mask);

  double? _finiteOrNull(double value) => value.isFinite ? value : null;

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }

  void _requireOpenLatitude(double value, String name) {
    final limit = math.pi / 2;
    if (value <= -limit || value >= limit) {
      throw RangeError.value(
        value,
        name,
        'must be strictly between -pi/2 and pi/2',
      );
    }
  }

  void _requireOpenObliquity(double value, String name) {
    final limit = math.pi / 2;
    if (value <= 0 || value >= limit) {
      throw RangeError.value(
        value,
        name,
        'must be strictly between 0 and pi/2',
      );
    }
  }

  static const Set<TaiyinPositionFlag> _lunarPhysicalAllowedFlags = {
    TaiyinPositionFlag.truePosition,
    TaiyinPositionFlag.equatorial,
    TaiyinPositionFlag.noAberration,
    TaiyinPositionFlag.noGravitationalDeflection,
    TaiyinPositionFlag.astrometric,
    TaiyinPositionFlag.noNutation,
  };

  static const Set<TaiyinPositionFlag> _lunarMeanAllowedFlags = {
    TaiyinPositionFlag.equatorial,
    TaiyinPositionFlag.noNutation,
  };
}
