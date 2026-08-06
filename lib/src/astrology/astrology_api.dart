part of '../taiyin.dart';

typedef _AstrologyStatusChecker =
    void Function(int status, EphemerisDiagnostic? diagnostic);
typedef _SiderealCalculation =
    int Function(
      Arena arena,
      int flags,
      Pointer<taiyin_sidereal_position> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _SiderealCoordinatesCalculation =
    int Function(
      Arena arena,
      int flags,
      Pointer<taiyin_sidereal_coordinates> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LunarNodeCalculation =
    int Function(
      Arena arena,
      int flags,
      Pointer<taiyin_lunar_node_position> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _LunarApsisCalculation =
    int Function(
      Arena arena,
      int flags,
      Pointer<taiyin_lunar_apsis_position> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _HouseCalculation =
    int Function(Arena arena, Pointer<taiyin_house_result> output);

const int _siderealReferenceEpochUt1Flag = 1 << 35;

/// Sidereal coordinates and astrological house calculations.
///
/// Julian dates cross the native boundary as split `taiyin_split_julian_date`
/// structs, preserving the full day-number/fraction precision. Sidereal
/// reference epochs are likewise passed as split structs, or as a null pointer
/// when the selected reference plane does not require one.
final class AstrologyApi {
  AstrologyApi._(
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
    AyanamshaModel ayanamsha = Ayanamsha.faganBradley,
    SiderealPrecessionPolicy precessionPolicy =
        SiderealPrecessionPolicy.compensateToReference,
  }) {
    _ensureOpen();
    return using((arena) {
      final output = arena<Double>();
      _checkStatus(
        _bindings.taiyin_calc_ayanamsha_tt(
          _context,
          ayanamsha.id,
          writeJulianDate(arena, tt),
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
  /// [PositionFlag.xyz] and [PositionFlag.equatorial] are
  /// rejected. [PositionFlag.radians] is added automatically.
  EphemerisResult<SiderealPosition> siderealPositionAtTt(
    Target target,
    JulianDate<TtScale> tt, {
    AyanamshaModel ayanamsha = Ayanamsha.faganBradley,
    SiderealPrecessionPolicy precessionPolicy =
        SiderealPrecessionPolicy.compensateToReference,
    SiderealReferencePlane referencePlane =
        SiderealReferencePlane.meanEclipticOfDate,
    SiderealReferenceEpoch? referenceEpoch,
    Set<PositionFlag> flags = const {},
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
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_sidereal_position_tt(
            _context,
            ayanamsha.id,
            target.id,
            writeJulianDate(arena, tt),
            mask,
            _writeReferenceEpoch(arena, resolvedCall.referenceEpoch),
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates sidereal ecliptic coordinates at UT1 using the context policy.
  ///
  /// [flags] follow the same restrictions as [siderealPositionAtTt].
  EphemerisResult<SiderealPosition> siderealPositionAtUt1(
    Target target,
    JulianDate<Ut1Scale> ut1, {
    AyanamshaModel ayanamsha = Ayanamsha.faganBradley,
    SiderealPrecessionPolicy precessionPolicy =
        SiderealPrecessionPolicy.compensateToReference,
    SiderealReferencePlane referencePlane =
        SiderealReferencePlane.meanEclipticOfDate,
    SiderealReferenceEpoch? referenceEpoch,
    Set<PositionFlag> flags = const {},
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
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_sidereal_position_ut(
            _context,
            ayanamsha.id,
            target.id,
            writeJulianDate(arena, ut1),
            mask,
            _writeReferenceEpoch(arena, resolvedCall.referenceEpoch),
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates generic sidereal coordinates at TT.
  ///
  /// This is the coordinate-mode counterpart to [siderealPositionAtTt]. It
  /// accepts [PositionFlag.equatorial], [PositionFlag.xyz], and
  /// their combination. Without `equatorial`, the result is on the sidereal
  /// selected sidereal reference plane and [PositionFlag.noNutation] has
  /// no further effect. With `equatorial`, this follows conventional Swiss
  /// Ephemeris-compatible behavior: the result is tropical mean equator of
  /// date with `noNutation`, or tropical true equator of date without it, and
  /// is independent of [ayanamsha], [precessionPolicy], and [referencePlane].
  /// [PositionFlag.radians] is added automatically. Other position flags
  /// retain their ordinary native physical-correction semantics.
  EphemerisResult<SiderealCoordinates> siderealCoordinatesAtTt(
    Target target,
    JulianDate<TtScale> tt, {
    AyanamshaModel ayanamsha = Ayanamsha.faganBradley,
    SiderealPrecessionPolicy precessionPolicy =
        SiderealPrecessionPolicy.compensateToReference,
    SiderealReferencePlane referencePlane =
        SiderealReferencePlane.meanEclipticOfDate,
    SiderealReferenceEpoch? referenceEpoch,
    Set<PositionFlag> flags = const {},
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
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_sidereal_coordinates_tt(
            _context,
            ayanamsha.id,
            target.id,
            writeJulianDate(arena, tt),
            mask,
            _writeReferenceEpoch(arena, resolvedCall.referenceEpoch),
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates generic sidereal coordinates at UT1 using the context policy.
  ///
  /// See [siderealCoordinatesAtTt] for coordinate-mode and frame semantics.
  EphemerisResult<SiderealCoordinates> siderealCoordinatesAtUt1(
    Target target,
    JulianDate<Ut1Scale> ut1, {
    AyanamshaModel ayanamsha = Ayanamsha.faganBradley,
    SiderealPrecessionPolicy precessionPolicy =
        SiderealPrecessionPolicy.compensateToReference,
    SiderealReferencePlane referencePlane =
        SiderealReferencePlane.meanEclipticOfDate,
    SiderealReferenceEpoch? referenceEpoch,
    Set<PositionFlag> flags = const {},
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
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_sidereal_coordinates_ut(
            _context,
            ayanamsha.id,
            target.id,
            writeJulianDate(arena, ut1),
            mask,
            _writeReferenceEpoch(arena, resolvedCall.referenceEpoch),
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
  EphemerisResult<LunarNodePosition> lunarTrueNodeAtTt(
    JulianDate<TtScale> tt, {
    LunarNodeKind kind = LunarNodeKind.ascending,
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _lunarPhysicalFlags(flags, 'lunar true node');
    return _lunarNode(
      kind,
      resolvedFlags,
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_true_node_tt(
            _context,
            writeJulianDate(arena, tt),
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
  EphemerisResult<LunarNodePosition> lunarTrueNodeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    LunarNodeKind kind = LunarNodeKind.ascending,
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _lunarPhysicalFlags(flags, 'lunar true node');
    return _lunarNode(
      kind,
      resolvedFlags,
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_true_node_ut(
            _context,
            writeJulianDate(arena, ut1),
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
  EphemerisResult<LunarNodePosition> lunarMeanNodeAtTt(
    JulianDate<TtScale> tt, {
    LunarNodeKind kind = LunarNodeKind.ascending,
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _lunarMeanFlags(flags, 'lunar mean node');
    return _lunarNode(
      kind,
      resolvedFlags,
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_mean_node_tt(
            _context,
            writeJulianDate(arena, tt),
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
  EphemerisResult<LunarNodePosition> lunarMeanNodeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    LunarNodeKind kind = LunarNodeKind.ascending,
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    final resolvedFlags = _lunarMeanFlags(flags, 'lunar mean node');
    return _lunarNode(
      kind,
      resolvedFlags,
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_mean_node_ut(
            _context,
            writeJulianDate(arena, ut1),
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
  /// [LunarApsisPosition.distanceAu] fields are null.
  EphemerisResult<LunarApsisPosition> lunarMeanApogeeAtTt(
    JulianDate<TtScale> tt, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarMeanFlags(flags, 'lunar mean apogee'),
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_mean_apogee_tt(
            _context,
            writeJulianDate(arena, tt),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the Delaunay mean lunar apogee (mean Lilith) at UT1.
  ///
  /// See [lunarMeanApogeeAtTt] for the result and flag contract.
  EphemerisResult<LunarApsisPosition> lunarMeanApogeeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarMeanFlags(flags, 'lunar mean apogee'),
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_mean_apogee_ut(
            _context,
            writeJulianDate(arena, ut1),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the geocentric osculating lunar apogee at TT.
  ///
  /// This instantaneous two-body apoapsis is commonly called true Lilith.
  EphemerisResult<LunarApsisPosition> lunarOsculatingApogeeAtTt(
    JulianDate<TtScale> tt, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarPhysicalFlags(flags, 'lunar osculating apogee'),
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_osculating_apogee_tt(
            _context,
            writeJulianDate(arena, tt),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the geocentric osculating lunar apogee at UT1.
  ///
  /// See [lunarOsculatingApogeeAtTt] for the result and flag contract.
  EphemerisResult<LunarApsisPosition> lunarOsculatingApogeeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarPhysicalFlags(flags, 'lunar osculating apogee'),
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_osculating_apogee_ut(
            _context,
            writeJulianDate(arena, ut1),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the DE441 fitted-natural lunar apogee at TT.
  ///
  /// The result reports [LunarApsisPosition.extrapolated] when the
  /// requested date lies outside the fitted DE441 interval. Unlike the
  /// conventional mean apogee, it includes a physical distance and rate from
  /// the fitted model.
  EphemerisResult<LunarApsisPosition> lunarFittedApogeeAtTt(
    JulianDate<TtScale> tt, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarMeanFlags(flags, 'lunar fitted apogee'),
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_fitted_apogee_tt(
            _context,
            writeJulianDate(arena, tt),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates the DE441 fitted-natural lunar apogee at UT1.
  ///
  /// See [lunarFittedApogeeAtTt] for the result and flag contract.
  EphemerisResult<LunarApsisPosition> lunarFittedApogeeAtUt1(
    JulianDate<Ut1Scale> ut1, {
    Set<PositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _lunarApsis(
      _lunarMeanFlags(flags, 'lunar fitted apogee'),
      (arena, mask, output, diagnostic) =>
          _bindings.taiyin_calc_lunar_fitted_apogee_ut(
            _context,
            writeJulianDate(arena, ut1),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates houses directly from ARMC, latitude, and true obliquity.
  Houses housesFromArmc({
    required double armcRadians,
    required double observerLatitudeRadians,
    required double trueObliquityRadians,
    HouseSystemModel system = HouseSystem.porphyry,
  }) {
    _ensureOpen();
    _requireFinite(armcRadians, 'armcRadians');
    _requireFinite(observerLatitudeRadians, 'observerLatitudeRadians');
    _requireFinite(trueObliquityRadians, 'trueObliquityRadians');
    _requireOpenLatitude(observerLatitudeRadians, 'observerLatitudeRadians');
    _requireOpenObliquity(trueObliquityRadians, 'trueObliquityRadians');
    return _houses(
      (_, output) => _bindings.taiyin_calc_houses_from_armc(
        armcRadians,
        observerLatitudeRadians,
        trueObliquityRadians,
        system.id,
        output,
      ),
    );
  }

  /// Calculates houses at a UT1 coordinate using the context observer.
  Houses housesAtUt1(
    JulianDate<Ut1Scale> ut1, {
    HouseSystemModel system = HouseSystem.porphyry,
  }) {
    _ensureOpen();
    return _houses(
      (arena, output) => _bindings.taiyin_calc_houses_ut(
        _context,
        writeJulianDate(arena, ut1),
        system.id,
        output,
      ),
    );
  }

  /// Calculates houses at a TT coordinate using the context observer.
  Houses housesAtTt(
    JulianDate<TtScale> tt, {
    HouseSystemModel system = HouseSystem.porphyry,
  }) {
    _ensureOpen();
    return _houses(
      (arena, output) => _bindings.taiyin_calc_houses_tt(
        _context,
        writeJulianDate(arena, tt),
        system.id,
        output,
      ),
    );
  }

  /// Locates an ecliptic longitude within [houses].
  HousePosition housePositionOf(
    Houses houses,
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
      return HousePosition(
        houseNumber: output.ref.house_number,
        fraction: output.ref.fraction,
        continuousHousePosition: output.ref.continuous_house_position,
      );
    });
  }

  /// Whether the native runtime provides [ayanamsha].
  bool hasAyanamshaModel(AyanamshaModel ayanamsha) {
    _ensureOpen();
    return _bindings.taiyin_has_ayanamsha_model(ayanamsha.id) != 0;
  }

  /// Whether the native runtime provides [system].
  bool hasHouseSystemModel(HouseSystemModel system) {
    _ensureOpen();
    return _bindings.taiyin_has_house_system_model(system.id) != 0;
  }

  EphemerisResult<SiderealPosition> _siderealPosition(
    Target target,
    AyanamshaModel ayanamsha,
    SiderealPrecessionPolicy precessionPolicy,
    SiderealReferencePlane referencePlane,
    SiderealReferenceEpoch? referenceEpoch,
    Set<PositionFlag> flags,
    int nativeFlags,
    _SiderealCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_sidereal_position>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_sidereal_position_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, nativeFlags, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return EphemerisResult(
        value: SiderealPosition(
          target: target,
          ayanamsha: ayanamsha,
          precessionPolicy: precessionPolicy,
          referencePlane: referencePlane,
          referenceEpoch: referenceEpoch,
          coordinateFrame: SiderealCoordinateFrame.fromId(
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

  EphemerisResult<SiderealCoordinates> _siderealCoordinates(
    Target target,
    AyanamshaModel ayanamsha,
    SiderealPrecessionPolicy precessionPolicy,
    SiderealReferencePlane referencePlane,
    SiderealReferenceEpoch? referenceEpoch,
    Set<PositionFlag> flags,
    int nativeFlags,
    _SiderealCoordinatesCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_sidereal_coordinates>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_sidereal_coordinates_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, nativeFlags, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      final outputFlags = Set<PositionFlag>.unmodifiable({
        for (final flag in PositionFlag.values)
          if ((value.position_flags & flag.mask) != 0) flag,
      });
      return EphemerisResult(
        value: SiderealCoordinates(
          target: target,
          ayanamsha: ayanamsha,
          precessionPolicy: precessionPolicy,
          referencePlane: referencePlane,
          referenceEpoch: referenceEpoch,
          coordinateFrame: SiderealCoordinateFrame.fromId(
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

  EphemerisResult<LunarNodePosition> _lunarNode(
    LunarNodeKind kind,
    Set<PositionFlag> flags,
    _LunarNodeCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_node_position>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_node_position_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, _flagMask(flags), output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return EphemerisResult(
        value: LunarNodePosition(
          kind: kind,
          referenceFrame: ApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          longitudeRadians: value.longitude_rad,
          longitudeRateRadiansPerDay: value.longitude_rate_rad_per_day,
          flags: flags,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<LunarApsisPosition> _lunarApsis(
    Set<PositionFlag> flags,
    _LunarApsisCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_apsis_position>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_apsis_position_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, _flagMask(flags), output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return EphemerisResult(
        value: LunarApsisPosition(
          referenceFrame: ApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          definition: LunarApsisDefinition.fromId(value.definition),
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

  Houses _houses(_HouseCalculation calculate) {
    return using((arena) {
      final output = arena<taiyin_house_result>();
      _bindings.taiyin_house_result_init(output);
      _checkStatus(calculate(arena, output), null);
      return _readHouses(output.ref);
    });
  }

  Houses _readHouses(taiyin_house_result value) {
    final flags = {
      for (final flag in HouseResultFlag.values)
        if ((value.flags & flag.mask) != 0) flag,
    };
    return Houses(
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

  Pointer<taiyin_house_result> _writeHouses(Arena arena, Houses houses) {
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

  Set<PositionFlag> _siderealFlags(Set<PositionFlag> flags) {
    if (flags.contains(PositionFlag.xyz) ||
        flags.contains(PositionFlag.equatorial)) {
      throw ArgumentError.value(
        flags,
        'flags',
        'sidereal positions are ecliptic longitudes and do not support XYZ or equatorial output',
      );
    }
    return Set.unmodifiable({...flags, PositionFlag.radians});
  }

  Set<PositionFlag> _genericSiderealFlags(Set<PositionFlag> flags) =>
      Set.unmodifiable({...flags, PositionFlag.radians});

  ({int flags, SiderealReferenceEpoch? referenceEpoch}) _resolveSiderealCall(
    Set<PositionFlag> positionFlags,
    SiderealPrecessionPolicy precessionPolicy,
    SiderealReferencePlane referencePlane,
    SiderealReferenceEpoch? referenceEpoch,
  ) {
    if (referencePlane.requiresReferenceEpoch != (referenceEpoch != null)) {
      final requirement = referencePlane.requiresReferenceEpoch
          ? '${referencePlane.name} requires a referenceEpoch'
          : '${referencePlane.name} does not accept a referenceEpoch';
      throw ArgumentError.value(referenceEpoch, 'referenceEpoch', requirement);
    }
    final nativeFlags =
        _flagMask(positionFlags) |
        precessionPolicy.nativeFlagMask |
        referencePlane.nativeFlagMask |
        (referenceEpoch?.isUt1 == true ? _siderealReferenceEpochUt1Flag : 0);
    return (flags: nativeFlags, referenceEpoch: referenceEpoch);
  }

  /// Marshals a sidereal reference epoch into an arena-owned split-JD pointer.
  ///
  /// A null epoch (used when [SiderealReferencePlane] does not require
  /// one) is written as a null pointer, which the native ABI interprets as no
  /// reference epoch.
  Pointer<taiyin_split_julian_date> _writeReferenceEpoch(
    Arena arena,
    SiderealReferenceEpoch? referenceEpoch,
  ) {
    if (referenceEpoch == null) {
      return nullptr;
    }
    return switch (referenceEpoch) {
      SiderealReferenceEpochTt() => writeJulianDate<TtScale>(
        arena,
        referenceEpoch.coordinate,
      ),
      SiderealReferenceEpochUt1() => writeJulianDate<Ut1Scale>(
        arena,
        referenceEpoch.coordinate,
      ),
    };
  }

  Set<PositionFlag> _lunarPhysicalFlags(
    Set<PositionFlag> flags,
    String calculation,
  ) => _lunarFlags(flags, calculation, _lunarPhysicalAllowedFlags);

  Set<PositionFlag> _lunarMeanFlags(
    Set<PositionFlag> flags,
    String calculation,
  ) => _lunarFlags(flags, calculation, _lunarMeanAllowedFlags);

  Set<PositionFlag> _lunarFlags(
    Set<PositionFlag> flags,
    String calculation,
    Set<PositionFlag> allowed,
  ) {
    final unsupported = flags.difference(allowed);
    if (unsupported.isNotEmpty) {
      final unsupportedNames = [
        for (final flag in PositionFlag.values)
          if (unsupported.contains(flag)) flag.name,
      ];
      final allowedNames = [
        for (final flag in PositionFlag.values)
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

  int _flagMask(Set<PositionFlag> flags) =>
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

  static const Set<PositionFlag> _lunarPhysicalAllowedFlags = {
    PositionFlag.truePosition,
    PositionFlag.equatorial,
    PositionFlag.noAberration,
    PositionFlag.noGravitationalDeflection,
    PositionFlag.astrometric,
    PositionFlag.noNutation,
  };

  static const Set<PositionFlag> _lunarMeanAllowedFlags = {
    PositionFlag.equatorial,
    PositionFlag.noNutation,
  };
}
