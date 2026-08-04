part of '../taiyin.dart';

typedef _OrbitalStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);

const int _taiyinOrbitalReverseMask = 1 << 32;

/// Osculating-orbit calculations and physical orbital-event searches.
final class TaiyinOrbitalApi {
  TaiyinOrbitalApi._(
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
  TaiyinEphemerisResult<TaiyinOsculatingOrbit> osculatingAtTt(
    TaiyinBody body,
    JulianDate<TtScale> tt, {
    TaiyinApparentFrame referenceFrame = TaiyinApparentFrame.j2000Ecliptic,
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
  TaiyinEphemerisResult<TaiyinOsculatingOrbit> osculatingAtUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> ut1, {
    TaiyinApparentFrame referenceFrame = TaiyinApparentFrame.j2000Ecliptic,
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
  TaiyinEphemerisResult<TaiyinOrbitReferencePoints> referencePointsAtTt(
    TaiyinBody body,
    JulianDate<TtScale> tt, {
    TaiyinApparentFrame referenceFrame = TaiyinApparentFrame.j2000Ecliptic,
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
  TaiyinEphemerisResult<TaiyinOrbitReferencePoints> referencePointsAtUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> ut1, {
    TaiyinApparentFrame referenceFrame = TaiyinApparentFrame.j2000Ecliptic,
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
  TaiyinEphemerisResult<TaiyinApsisEvent<TtScale>> searchApsisFromTt(
    TaiyinBody body,
    TaiyinApsisKind kind,
    JulianDate<TtScale> start, {
    TaiyinOrbitalSearchDirection direction =
        TaiyinOrbitalSearchDirection.forward,
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
  TaiyinEphemerisResult<TaiyinApsisEvent<Ut1Scale>> searchApsisFromUt1(
    TaiyinBody body,
    TaiyinApsisKind kind,
    JulianDate<Ut1Scale> start, {
    TaiyinOrbitalSearchDirection direction =
        TaiyinOrbitalSearchDirection.forward,
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
  TaiyinEphemerisResult<TaiyinPlaneNodeEvent<TtScale>> searchPlaneNodeFromTt(
    TaiyinBody body,
    TaiyinPlaneNodeKind kind,
    JulianDate<TtScale> start, {
    TaiyinApparentFrame referenceFrame = TaiyinApparentFrame.j2000Ecliptic,
    TaiyinOrbitalSearchDirection direction =
        TaiyinOrbitalSearchDirection.forward,
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
  TaiyinEphemerisResult<TaiyinPlaneNodeEvent<Ut1Scale>> searchPlaneNodeFromUt1(
    TaiyinBody body,
    TaiyinPlaneNodeKind kind,
    JulianDate<Ut1Scale> start, {
    TaiyinApparentFrame referenceFrame = TaiyinApparentFrame.j2000Ecliptic,
    TaiyinOrbitalSearchDirection direction =
        TaiyinOrbitalSearchDirection.forward,
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

  TaiyinEphemerisResult<TaiyinOsculatingOrbit> _osculating(
    TaiyinBody body,
    TaiyinApparentFrame referenceFrame,
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
      return TaiyinEphemerisResult(
        value: TaiyinOsculatingOrbit(
          body: _bodyFromId(value.body_id),
          center: _bodyFromId(value.center_id),
          referenceFrame: TaiyinApparentFrame.fromId(value.reference_frame_id),
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

  TaiyinEphemerisResult<TaiyinOrbitReferencePoints> _referencePoints(
    TaiyinBody body,
    TaiyinApparentFrame referenceFrame,
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
      return TaiyinEphemerisResult(
        value: TaiyinOrbitReferencePoints(
          body: _bodyFromId(value.body_id),
          center: _bodyFromId(value.center_id),
          referenceFrame: TaiyinApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          model: TaiyinOrbitReferencePointModel.fromId(value.model_id),
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

  TaiyinEphemerisResult<TaiyinApsisEvent<Scale>>
  _searchApsis<Scale extends TimeScale>(
    TaiyinBody body,
    TaiyinApsisKind kind,
    TaiyinOrbitalSearchDirection direction,
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
      return TaiyinEphemerisResult(
        value: TaiyinApsisEvent<Scale>(
          body: _bodyFromId(value.body_id),
          center: _bodyFromId(value.center_id),
          kind: TaiyinApsisKind.fromId(value.kind),
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

  TaiyinEphemerisResult<TaiyinPlaneNodeEvent<Scale>>
  _searchPlaneNode<Scale extends TimeScale>(
    TaiyinBody body,
    TaiyinPlaneNodeKind kind,
    TaiyinApparentFrame referenceFrame,
    TaiyinOrbitalSearchDirection direction,
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
      return TaiyinEphemerisResult(
        value: TaiyinPlaneNodeEvent<Scale>(
          body: _bodyFromId(value.body_id),
          center: _bodyFromId(value.center_id),
          referenceFrame: TaiyinApparentFrame.fromId(value.reference_frame_id),
          rawReferenceFrameId: value.reference_frame_id,
          kind: TaiyinPlaneNodeKind.fromId(value.kind),
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
    TaiyinOrbitalSearchDirection? direction,
  }) {
    var result = allowBarycenterApproximation
        ? TaiyinPositionFlag.allowBarycenterApproximation.mask
        : 0;
    if (direction == TaiyinOrbitalSearchDirection.reverse) {
      result |= _taiyinOrbitalReverseMask;
    }
    return result;
  }

  TaiyinOrbitReferencePoint _readReferencePoint(
    taiyin_body_orbit_reference_point value,
  ) {
    return TaiyinOrbitReferencePoint(
      positionAu: TaiyinVector3(
        value.position_au.x,
        value.position_au.y,
        value.position_au.z,
      ),
      longitudeRadians: value.longitude_rad,
      latitudeRadians: value.latitude_rad,
      distanceAu: value.distance_au,
    );
  }

  TaiyinBody _bodyFromId(int id) {
    return TaiyinBody.values.firstWhere(
      (body) => body.id == id,
      orElse: () => throw StateError('Unknown Taiyin body ID: $id'),
    );
  }

  void _requireReferenceFrame(TaiyinApparentFrame frame) {
    if (frame == TaiyinApparentFrame.unknown) {
      throw ArgumentError.value(
        frame,
        'referenceFrame',
        'must be a supported concrete reference frame',
      );
    }
  }

  void _requireOrbitalBody(TaiyinBody body) {
    const supported = {
      TaiyinBody.mercuryBarycenter,
      TaiyinBody.venusBarycenter,
      TaiyinBody.earthMoonBarycenter,
      TaiyinBody.marsBarycenter,
      TaiyinBody.jupiterBarycenter,
      TaiyinBody.saturnBarycenter,
      TaiyinBody.uranusBarycenter,
      TaiyinBody.neptuneBarycenter,
      TaiyinBody.plutoBarycenter,
      TaiyinBody.mercury,
      TaiyinBody.venus,
      TaiyinBody.moon,
      TaiyinBody.earth,
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
        'must be the Moon, Earth/EMB, or a major planet/planet barycenter',
      );
    }
  }
}
