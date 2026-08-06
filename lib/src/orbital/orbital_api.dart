part of '../taiyin.dart';

typedef _OrbitalStatusChecker =
    void Function(int status, EphemerisDiagnostic? diagnostic);

const int _taiyinOrbitalReverseMask = 1 << 32;

/// Osculating-orbit calculations and physical orbital-event searches.
final class OrbitalApi {
  OrbitalApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _OrbitalStatusChecker _checkStatus;

  /// Calculates osculating elements at a TT coordinate.
  EphemerisResult<OsculatingOrbit> osculatingAtTt(
    Body body,
    JulianDate<TtScale> tt, {
    ApparentFrame referenceFrame = ApparentFrame.j2000Ecliptic,
    bool allowBarycenterApproximation = false,
  }) {
    _ensureOpen();
    return _osculating(
      body,
      referenceFrame,
      allowBarycenterApproximation,
      (arena, output, diagnostic, flags) =>
          _bindings.taiyin_calc_body_osculating_orbit_tt(
            _context,
            body.id,
            writeJulianDate(arena, tt),
            referenceFrame.id,
            flags,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates osculating elements at a UT1 coordinate.
  EphemerisResult<OsculatingOrbit> osculatingAtUt1(
    Body body,
    JulianDate<Ut1Scale> ut1, {
    ApparentFrame referenceFrame = ApparentFrame.j2000Ecliptic,
    bool allowBarycenterApproximation = false,
  }) {
    _ensureOpen();
    return _osculating(
      body,
      referenceFrame,
      allowBarycenterApproximation,
      (arena, output, diagnostic, flags) =>
          _bindings.taiyin_calc_body_osculating_orbit_ut(
            _context,
            body.id,
            writeJulianDate(arena, ut1),
            referenceFrame.id,
            flags,
            output,
            diagnostic,
          ),
    );
  }

  /// Constructs instantaneous osculating reference points at TT.
  EphemerisResult<OrbitReferencePoints> referencePointsAtTt(
    Body body,
    JulianDate<TtScale> tt, {
    ApparentFrame referenceFrame = ApparentFrame.j2000Ecliptic,
    bool allowBarycenterApproximation = false,
  }) {
    _ensureOpen();
    return _referencePoints(
      body,
      referenceFrame,
      allowBarycenterApproximation,
      (arena, output, diagnostic, flags) =>
          _bindings.taiyin_calc_body_orbit_reference_points_tt(
            _context,
            body.id,
            writeJulianDate(arena, tt),
            referenceFrame.id,
            flags,
            output,
            diagnostic,
          ),
    );
  }

  /// Constructs instantaneous osculating reference points at UT1.
  EphemerisResult<OrbitReferencePoints> referencePointsAtUt1(
    Body body,
    JulianDate<Ut1Scale> ut1, {
    ApparentFrame referenceFrame = ApparentFrame.j2000Ecliptic,
    bool allowBarycenterApproximation = false,
  }) {
    _ensureOpen();
    return _referencePoints(
      body,
      referenceFrame,
      allowBarycenterApproximation,
      (arena, output, diagnostic, flags) =>
          _bindings.taiyin_calc_body_orbit_reference_points_ut(
            _context,
            body.id,
            writeJulianDate(arena, ut1),
            referenceFrame.id,
            flags,
            output,
            diagnostic,
          ),
    );
  }

  /// Searches from a TT coordinate for a pericenter or apocenter.
  EphemerisResult<ApsisEvent<TtScale>> searchApsisFromTt(
    Body body,
    ApsisKind kind,
    JulianDate<TtScale> start, {
    OrbitalSearchDirection direction = OrbitalSearchDirection.forward,
    bool allowBarycenterApproximation = false,
  }) {
    _ensureOpen();
    return _searchApsis<TtScale>(
      body,
      kind,
      direction,
      allowBarycenterApproximation,
      (arena, output, diagnostic, flags) =>
          _bindings.taiyin_search_next_body_apsis_tt(
            _context,
            body.id,
            kind.id,
            writeJulianDate(arena, start),
            flags,
            output,
            diagnostic,
          ),
    );
  }

  /// Searches from a UT1 coordinate for a pericenter or apocenter.
  EphemerisResult<ApsisEvent<Ut1Scale>> searchApsisFromUt1(
    Body body,
    ApsisKind kind,
    JulianDate<Ut1Scale> start, {
    OrbitalSearchDirection direction = OrbitalSearchDirection.forward,
    bool allowBarycenterApproximation = false,
  }) {
    _ensureOpen();
    return _searchApsis<Ut1Scale>(
      body,
      kind,
      direction,
      allowBarycenterApproximation,
      (arena, output, diagnostic, flags) =>
          _bindings.taiyin_search_next_body_apsis_ut(
            _context,
            body.id,
            kind.id,
            writeJulianDate(arena, start),
            flags,
            output,
            diagnostic,
          ),
    );
  }

  /// Searches from a TT coordinate for a reference-plane crossing.
  EphemerisResult<PlaneNodeEvent<TtScale>> searchPlaneNodeFromTt(
    Body body,
    PlaneNodeKind kind,
    JulianDate<TtScale> start, {
    ApparentFrame referenceFrame = ApparentFrame.j2000Ecliptic,
    OrbitalSearchDirection direction = OrbitalSearchDirection.forward,
    bool allowBarycenterApproximation = false,
  }) {
    _ensureOpen();
    return _searchPlaneNode<TtScale>(
      body,
      kind,
      referenceFrame,
      direction,
      allowBarycenterApproximation,
      (arena, output, diagnostic, flags) =>
          _bindings.taiyin_search_next_body_plane_node_tt(
            _context,
            body.id,
            kind.id,
            writeJulianDate(arena, start),
            referenceFrame.id,
            flags,
            output,
            diagnostic,
          ),
    );
  }

  /// Searches from a UT1 coordinate for a reference-plane crossing.
  EphemerisResult<PlaneNodeEvent<Ut1Scale>> searchPlaneNodeFromUt1(
    Body body,
    PlaneNodeKind kind,
    JulianDate<Ut1Scale> start, {
    ApparentFrame referenceFrame = ApparentFrame.j2000Ecliptic,
    OrbitalSearchDirection direction = OrbitalSearchDirection.forward,
    bool allowBarycenterApproximation = false,
  }) {
    _ensureOpen();
    return _searchPlaneNode<Ut1Scale>(
      body,
      kind,
      referenceFrame,
      direction,
      allowBarycenterApproximation,
      (arena, output, diagnostic, flags) =>
          _bindings.taiyin_search_next_body_plane_node_ut(
            _context,
            body.id,
            kind.id,
            writeJulianDate(arena, start),
            referenceFrame.id,
            flags,
            output,
            diagnostic,
          ),
    );
  }

  EphemerisResult<OsculatingOrbit> _osculating(
    Body body,
    ApparentFrame referenceFrame,
    bool allowBarycenterApproximation,
    int Function(
      Arena,
      Pointer<taiyin_body_osculating_orbit>,
      Pointer<taiyin_ephemeris_diagnostic>,
      int,
    )
    calculate,
  ) {
    _requireOrbitalBody(body);
    _requireReferenceFrame(referenceFrame);
    return using((arena) {
      final output = arena<taiyin_body_osculating_orbit>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_body_osculating_orbit_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(
        arena,
        output,
        diagnostic,
        _flags(allowBarycenterApproximation),
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return EphemerisResult(
        value: OsculatingOrbit(
          body: _bodyFromId(value.body_id),
          center: _bodyFromId(value.center_id),
          referenceFrame: ApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          gravitationalParameterAu3PerDay2:
              value.gravitational_parameter_au3_per_day2,
          semiMajorAxisAu: value.semi_major_axis_au,
          eccentricity: value.eccentricity,
          inclinationRadians: value.inclination_rad,
          longitudeOfAscendingNodeRadians:
              value.longitude_of_ascending_node_rad,
          argumentOfPeriapsisRadians: value.argument_of_periapsis_rad,
          trueAnomalyRadians: value.true_anomaly_rad,
          meanAnomalyRadians: value.mean_anomaly_rad,
          periapsisDistanceAu: value.periapsis_distance_au,
          apoapsisDistanceAu: value.apoapsis_distance_au,
          osculatingPeriodDays: value.osculating_period_days,
          currentDistanceAu: value.current_distance_au,
          radialVelocityAuPerDay: value.radial_velocity_au_per_day,
          allowBarycenterApproximation: allowBarycenterApproximation,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<OrbitReferencePoints> _referencePoints(
    Body body,
    ApparentFrame referenceFrame,
    bool allowBarycenterApproximation,
    int Function(
      Arena,
      Pointer<taiyin_body_orbit_reference_points>,
      Pointer<taiyin_ephemeris_diagnostic>,
      int,
    )
    calculate,
  ) {
    _requireOrbitalBody(body);
    _requireReferenceFrame(referenceFrame);
    return using((arena) {
      final output = arena<taiyin_body_orbit_reference_points>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_body_orbit_reference_points_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(
        arena,
        output,
        diagnostic,
        _flags(allowBarycenterApproximation),
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return EphemerisResult(
        value: OrbitReferencePoints(
          body: _bodyFromId(value.body_id),
          center: _bodyFromId(value.center_id),
          referenceFrame: ApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          model: OrbitReferencePointModel.fromId(value.model_id),
          rawModelId: value.model_id,
          ascendingNode: _readReferencePoint(value.ascending_node),
          descendingNode: _readReferencePoint(value.descending_node),
          periapsis: _readReferencePoint(value.periapsis),
          apoapsis: _readReferencePoint(value.apoapsis),
          secondFocus: _readReferencePoint(value.second_focus),
          allowBarycenterApproximation: allowBarycenterApproximation,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<ApsisEvent<Scale>> _searchApsis<Scale extends TimeScale>(
    Body body,
    ApsisKind kind,
    OrbitalSearchDirection direction,
    bool allowBarycenterApproximation,
    int Function(
      Arena,
      Pointer<taiyin_body_apsis_search_result>,
      Pointer<taiyin_ephemeris_diagnostic>,
      int,
    )
    search,
  ) {
    _requireOrbitalBody(body);
    return using((arena) {
      final output = arena<taiyin_body_apsis_search_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_body_apsis_search_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = search(
        arena,
        output,
        diagnostic,
        _flags(allowBarycenterApproximation, direction: direction),
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return EphemerisResult(
        value: ApsisEvent<Scale>(
          body: _bodyFromId(value.body_id),
          center: _bodyFromId(value.center_id),
          kind: ApsisKind.fromId(value.kind),
          coordinate: readJulianDate<Scale>(value.jd),
          distanceAu: value.distance_au,
          radialVelocityAuPerDay: value.radial_velocity_au_per_day,
          iterationCount: value.iteration_count,
          evaluationCount: value.evaluation_count,
          direction: direction,
          allowBarycenterApproximation: allowBarycenterApproximation,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  EphemerisResult<PlaneNodeEvent<Scale>>
  _searchPlaneNode<Scale extends TimeScale>(
    Body body,
    PlaneNodeKind kind,
    ApparentFrame referenceFrame,
    OrbitalSearchDirection direction,
    bool allowBarycenterApproximation,
    int Function(
      Arena,
      Pointer<taiyin_body_node_search_result>,
      Pointer<taiyin_ephemeris_diagnostic>,
      int,
    )
    search,
  ) {
    _requireOrbitalBody(body);
    _requireReferenceFrame(referenceFrame);
    return using((arena) {
      final output = arena<taiyin_body_node_search_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_body_node_search_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = search(
        arena,
        output,
        diagnostic,
        _flags(allowBarycenterApproximation, direction: direction),
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return EphemerisResult(
        value: PlaneNodeEvent<Scale>(
          body: _bodyFromId(value.body_id),
          center: _bodyFromId(value.center_id),
          referenceFrame: ApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          kind: PlaneNodeKind.fromId(value.kind),
          coordinate: readJulianDate<Scale>(value.jd),
          referencePlaneAngleRadians: value.reference_plane_angle_rad,
          distanceAu: value.distance_au,
          iterationCount: value.iteration_count,
          evaluationCount: value.evaluation_count,
          direction: direction,
          allowBarycenterApproximation: allowBarycenterApproximation,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  int _flags(
    bool allowBarycenterApproximation, {
    OrbitalSearchDirection? direction,
  }) {
    var result = allowBarycenterApproximation
        ? PositionFlag.allowBarycenterApproximation.mask
        : 0;
    if (direction == OrbitalSearchDirection.reverse) {
      result |= _taiyinOrbitalReverseMask;
    }
    return result;
  }

  OrbitReferencePoint _readReferencePoint(
    taiyin_body_orbit_reference_point value,
  ) {
    return OrbitReferencePoint(
      positionAu: Vector3(
        value.position_au.x,
        value.position_au.y,
        value.position_au.z,
      ),
      longitudeRadians: value.longitude_rad,
      latitudeRadians: value.latitude_rad,
      distanceAu: value.distance_au,
    );
  }

  Body _bodyFromId(int id) {
    return Body.values.firstWhere(
      (body) => body.id == id,
      orElse: () => throw StateError('Unknown Ephemeris body ID: $id'),
    );
  }

  void _requireReferenceFrame(ApparentFrame frame) {
    if (frame == ApparentFrame.unknown) {
      throw ArgumentError.value(
        frame,
        'referenceFrame',
        'must be a supported concrete reference frame',
      );
    }
  }

  void _requireOrbitalBody(Body body) {
    const supported = {
      Body.mercuryBarycenter,
      Body.venusBarycenter,
      Body.earthMoonBarycenter,
      Body.marsBarycenter,
      Body.jupiterBarycenter,
      Body.saturnBarycenter,
      Body.uranusBarycenter,
      Body.neptuneBarycenter,
      Body.plutoBarycenter,
      Body.mercury,
      Body.venus,
      Body.moon,
      Body.earth,
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
        'must be the Moon, Earth/EMB, or a major planet/planet barycenter',
      );
    }
  }
}
