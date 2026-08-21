part of '../taiyin.dart';

typedef _OccultationStatusChecker =
    ResultFlags Function(int status, EphemerisDiagnostic? diagnostic);
typedef _OccultationSearchCalculation =
    int Function(
      Arena arena,
      Pointer<taiyin_lunar_occultation_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _OccultationVisibilityCalculation =
    int Function(
      Arena arena,
      Pointer<taiyin_lunar_occultation_result> occultation,
      Pointer<taiyin_lunar_occultation_local_visibility> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _OccultationWhereCalculation =
    int Function(
      Arena arena,
      Pointer<taiyin_lunar_occultation_result> occultation,
      Pointer<taiyin_lunar_occultation_where_result> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );

/// Searches lunar occultations and derives local visibility or global paths.
///
/// Local searches and local-visibility calculations use the observer already
/// configured on the owning [EphemerisContext]. Native inputs and all returned
/// dates cross the ABI as split UT1 Julian dates.
final class OccultationApi {
  OccultationApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _OccultationStatusChecker _checkStatus;

  // Native lunar-occultation searches do not define these as target bodies.
  static final Set<int> _unsupportedBodyTargetIds = Set.unmodifiable({
    Body.solarSystemBarycenter.id,
    Body.earthMoonBarycenter.id,
    Body.sun.id,
    Body.moon.id,
    Body.earth.id,
  });

  /// Finds the next geocentric lunar occultation of a catalogued star.
  OperationResult<LunarOccultationResult> nextGeocentricStarAtUt1(
    String starKey,
    JulianDate<Ut1Scale> start, {
    Set<PositionFlag> positionFlags = const {},
    Set<OccultationSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    final mask = _searchMask(positionFlags, options);
    return _search((arena, output, diagnostic) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _bindings.taiyin_search_next_geocentric_lunar_star_occultation_ut(
        _context,
        nativeStarKey,
        writeJulianDate(arena, start),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next local lunar occultation of a catalogued star.
  ///
  /// The context must have a configured geographic observer.
  OperationResult<LunarOccultationResult> nextLocalStarAtUt1(
    String starKey,
    JulianDate<Ut1Scale> start, {
    Set<PositionFlag> positionFlags = const {},
    Set<OccultationSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    final mask = _searchMask(positionFlags, options);
    return _search((arena, output, diagnostic) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _bindings.taiyin_search_next_local_lunar_star_occultation_ut(
        _context,
        nativeStarKey,
        writeJulianDate(arena, start),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next geocentric lunar occultation of a solar-system or custom
  /// [target].
  ///
  /// Omit [targetRadiusKilometers] to use native physical-disc data. Supplying
  /// zero models a point source; a positive value uses that explicit radius.
  OperationResult<LunarOccultationResult> nextGeocentricBodyAtUt1(
    Target target,
    JulianDate<Ut1Scale> start, {
    double? targetRadiusKilometers,
    Set<PositionFlag> positionFlags = const {},
    Set<OccultationSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireBodyTarget(target);
    _requireNonnegativeOptional(
      targetRadiusKilometers,
      'targetRadiusKilometers',
    );
    final mask = _searchMask(positionFlags, options);
    return _search((arena, output, diagnostic) {
      if (targetRadiusKilometers case final radius?) {
        return _bindings
            .taiyin_search_next_geocentric_lunar_body_occultation_with_radius_ut(
              _context,
              target.id,
              radius,
              writeJulianDate(arena, start),
              mask,
              output,
              diagnostic,
            );
      }
      return _bindings.taiyin_search_next_geocentric_lunar_body_occultation_ut(
        _context,
        target.id,
        writeJulianDate(arena, start),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds the next local lunar occultation of a solar-system or custom
  /// [target].
  ///
  /// The context must have a configured geographic observer. See
  /// [nextGeocentricBodyAtUt1] for [targetRadiusKilometers] semantics.
  OperationResult<LunarOccultationResult> nextLocalBodyAtUt1(
    Target target,
    JulianDate<Ut1Scale> start, {
    double? targetRadiusKilometers,
    Set<PositionFlag> positionFlags = const {},
    Set<OccultationSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireBodyTarget(target);
    _requireNonnegativeOptional(
      targetRadiusKilometers,
      'targetRadiusKilometers',
    );
    final mask = _searchMask(positionFlags, options);
    return _search((arena, output, diagnostic) {
      if (targetRadiusKilometers case final radius?) {
        return _bindings
            .taiyin_search_next_local_lunar_body_occultation_with_radius_ut(
              _context,
              target.id,
              radius,
              writeJulianDate(arena, start),
              mask,
              output,
              diagnostic,
            );
      }
      return _bindings.taiyin_search_next_local_lunar_body_occultation_ut(
        _context,
        target.id,
        writeJulianDate(arena, start),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Calculates local visibility samples for a star [occultation].
  ///
  /// The occultation must have come from a lunar-star search and the context
  /// must retain its local observer configuration.
  OperationResult<LunarOccultationLocalVisibility> localStarVisibilityAtUt1(
    String starKey,
    LunarOccultationResult occultation, {
    Set<OccultationVisibilityOption> options = const {},
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    _requireKind(occultation, LunarOccultationKind.lunarStar);
    final mask = _visibilityMask(options);
    return _visibility(occultation, (
      arena,
      nativeOccultation,
      output,
      diagnostic,
    ) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _bindings
          .taiyin_compute_lunar_star_occultation_local_visibility_ut(
            _context,
            nativeStarKey,
            nativeOccultation,
            mask,
            output,
            diagnostic,
          );
    });
  }

  /// Calculates local visibility samples for a body [occultation].
  OperationResult<LunarOccultationLocalVisibility> localBodyVisibilityAtUt1(
    Target target,
    LunarOccultationResult occultation, {
    Set<OccultationVisibilityOption> options = const {},
  }) {
    _ensureOpen();
    _requireBodyTarget(target);
    _requireKind(occultation, LunarOccultationKind.lunarBody);
    final mask = _visibilityMask(options);
    return _visibility(occultation, (_, nativeOccultation, output, diagnostic) {
      return _bindings
          .taiyin_compute_lunar_body_occultation_local_visibility_ut(
            _context,
            target.id,
            nativeOccultation,
            mask,
            output,
            diagnostic,
          );
    });
  }

  /// Calculates the global location and derived paths for a star occultation.
  OperationResult<LunarOccultationWhereResult> starWhereAtUt1(
    String starKey,
    LunarOccultationResult occultation, {
    Set<PositionFlag> positionFlags = const {},
    Set<OccultationVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    _requireKind(occultation, LunarOccultationKind.lunarStar);
    final mask = _whereMask(positionFlags, visibilityOptions);
    return _where(occultation, (arena, nativeOccultation, output, diagnostic) {
      final nativeStarKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      return _bindings.taiyin_compute_lunar_star_occultation_where_ut(
        _context,
        nativeStarKey,
        nativeOccultation,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Calculates the global location and derived paths for a body occultation.
  ///
  /// Supply the same [targetRadiusKilometers] used for the search when the
  /// event was found with a custom target radius.
  OperationResult<LunarOccultationWhereResult> bodyWhereAtUt1(
    Target target,
    LunarOccultationResult occultation, {
    double? targetRadiusKilometers,
    Set<PositionFlag> positionFlags = const {},
    Set<OccultationVisibilityOption> visibilityOptions = const {},
  }) {
    _ensureOpen();
    _requireBodyTarget(target);
    _requireKind(occultation, LunarOccultationKind.lunarBody);
    _requireNonnegativeOptional(
      targetRadiusKilometers,
      'targetRadiusKilometers',
    );
    final mask = _whereMask(positionFlags, visibilityOptions);
    return _where(occultation, (_, nativeOccultation, output, diagnostic) {
      if (targetRadiusKilometers case final radius?) {
        return _bindings
            .taiyin_compute_lunar_body_occultation_where_with_radius_ut(
              _context,
              target.id,
              radius,
              nativeOccultation,
              mask,
              output,
              diagnostic,
            );
      }
      return _bindings.taiyin_compute_lunar_body_occultation_where_ut(
        _context,
        target.id,
        nativeOccultation,
        mask,
        output,
        diagnostic,
      );
    });
  }

  OperationResult<LunarOccultationResult> _search(
    _OccultationSearchCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_lunar_occultation_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_occultation_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      return operationResult(_readOccultation(output.ref), resultFlags);
    });
  }

  OperationResult<LunarOccultationLocalVisibility> _visibility(
    LunarOccultationResult occultation,
    _OccultationVisibilityCalculation calculate,
  ) {
    return using((arena) {
      final nativeOccultation = _writeOccultation(arena, occultation);
      final output = arena<taiyin_lunar_occultation_local_visibility>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_occultation_local_visibility_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, nativeOccultation, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      return operationResult(_readLocalVisibility(output.ref), resultFlags);
    });
  }

  OperationResult<LunarOccultationWhereResult> _where(
    LunarOccultationResult occultation,
    _OccultationWhereCalculation calculate,
  ) {
    return using((arena) {
      final nativeOccultation = _writeOccultation(arena, occultation);
      final output = arena<taiyin_lunar_occultation_where_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_lunar_occultation_where_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(arena, nativeOccultation, output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      final resultFlags = _checkStatus(status, mappedDiagnostic);
      return operationResult(_readWhere(output.ref), resultFlags);
    });
  }

  LunarOccultationResult _readOccultation(
    taiyin_lunar_occultation_result value,
  ) {
    return LunarOccultationResult(
      kind: LunarOccultationKind.fromId(value.kind),
      types: OccultationType.fromMask(value.type_flags),
      coordinate: _requiredUt1(value.jd_ut, 'occultation maximum'),
      begin: _ut1OrNull(value.begin_jd_ut),
      end: _ut1OrNull(value.end_jd_ut),
      firstContact: _ut1OrNull(value.first_contact_jd_ut),
      secondContact: _ut1OrNull(value.second_contact_jd_ut),
      thirdContact: _ut1OrNull(value.third_contact_jd_ut),
      fourthContact: _ut1OrNull(value.fourth_contact_jd_ut),
      separationRadians: value.separation_rad,
      moonRadiusRadians: value.moon_radius_rad,
      targetRadiusRadians: value.target_radius_rad,
      marginRadians: value.margin_rad,
      phenomena: _readPhenomena(value.phenomena),
      candidate: _ut1OrNull(value.candidate_jd_ut),
      nextSearch: _ut1OrNull(value.next_search_jd_ut),
      candidateCount: value.candidate_count,
      iterationCount: value.iteration_count,
      evaluationCount: value.evaluation_count,
    );
  }

  LunarOccultationPhenomena _readPhenomena(
    taiyin_lunar_occultation_phenomena value,
  ) {
    return LunarOccultationPhenomena(
      angularDistanceRadians: _finiteOrNull(value.angular_distance_rad),
      diameterRatio: _finiteOrNull(value.diameter_ratio),
      magnitude: _finiteOrNull(value.magnitude),
      obscuration: _finiteOrNull(value.obscuration),
      occultedFraction: _finiteOrNull(value.occulted_fraction),
    );
  }

  LunarOccultationLocalVisibility _readLocalVisibility(
    taiyin_lunar_occultation_local_visibility value,
  ) {
    return LunarOccultationLocalVisibility(
      firstContact: _readVisibilitySample(value.first_contact),
      secondContact: _readVisibilitySample(value.second_contact),
      maximum: _readVisibilitySample(value.maximum),
      thirdContact: _readVisibilitySample(value.third_contact),
      fourthContact: _readVisibilitySample(value.fourth_contact),
      targetRise: _ut1OrNull(value.target_rise_jd_ut),
      targetSet: _ut1OrNull(value.target_set_jd_ut),
      visibleBegin: _ut1OrNull(value.visible_begin_jd_ut),
      visibleEnd: _ut1OrNull(value.visible_end_jd_ut),
      darkVisibleBegin: _ut1OrNull(value.dark_visible_begin_jd_ut),
      darkVisibleEnd: _ut1OrNull(value.dark_visible_end_jd_ut),
      visibleIntervals: _readIntervals(
        value.visible_intervals,
        value.visible_interval_count,
        'visibleIntervalCount',
      ),
      darkVisibleIntervals: _readIntervals(
        value.dark_visible_intervals,
        value.dark_visible_interval_count,
        'darkVisibleIntervalCount',
      ),
      flags: OccultationVisibilityFlag.fromMask(value.visibility_flags),
    );
  }

  LunarOccultationVisibilitySample? _readVisibilitySample(
    taiyin_lunar_occultation_visibility_sample value,
  ) {
    if (value.valid == 0) return null;
    return LunarOccultationVisibilitySample(
      coordinate: _requiredUt1(value.jd_ut, 'visibility sample'),
      moonAltitudeRadians: value.moon_altitude_rad,
      moonAzimuthRadians: value.moon_azimuth_rad,
      targetAltitudeRadians: value.target_altitude_rad,
      targetAzimuthRadians: value.target_azimuth_rad,
      sunAltitudeRadians: value.sun_altitude_rad,
      sunAzimuthRadians: value.sun_azimuth_rad,
      flags: OccultationSampleFlag.fromMask(value.visibility_flags),
    );
  }

  List<LunarOccultationVisibilityInterval> _readIntervals(
    Array<taiyin_lunar_occultation_visibility_interval> values,
    int count,
    String name,
  ) {
    final safeCount = _validatedCount(
      count,
      LunarOccultationLocalVisibility.maxIntervals,
      name,
    );
    return List.unmodifiable([
      for (var index = 0; index < safeCount; index++)
        _readInterval(values[index], name, index),
    ]);
  }

  LunarOccultationVisibilityInterval _readInterval(
    taiyin_lunar_occultation_visibility_interval value,
    String name,
    int index,
  ) {
    _requireValidEntry(value.valid, '$name[$index]');
    return LunarOccultationVisibilityInterval(
      begin: _requiredUt1(value.begin_jd_ut, '$name[$index].begin'),
      end: _requiredUt1(value.end_jd_ut, '$name[$index].end'),
    );
  }

  LunarOccultationWhereResult _readWhere(
    taiyin_lunar_occultation_where_result value,
  ) {
    final coordinate = _ut1OrNull(value.jd_ut);
    return LunarOccultationWhereResult(
      centerLineHitsEarth: value.center_line_hits_earth != 0,
      types: OccultationType.fromMask(value.type_flags),
      coordinate: coordinate,
      centerLineBegin: _ut1OrNull(value.center_line_begin_jd_ut),
      centerLineEnd: _ut1OrNull(value.center_line_end_jd_ut),
      centerLinePath: _readPath(
        value.center_line_path,
        value.center_line_path_count,
        LunarOccultationWhereResult.maxPathPoints,
        'centerLinePathCount',
      ),
      centerLineMinLongitudeDegrees: _finiteOrNull(
        value.center_line_min_longitude_deg,
      ),
      centerLineMaxLongitudeDegrees: _finiteOrNull(
        value.center_line_max_longitude_deg,
      ),
      centerLineMinLatitudeDegrees: _finiteOrNull(
        value.center_line_min_latitude_deg,
      ),
      centerLineMaxLatitudeDegrees: _finiteOrNull(
        value.center_line_max_latitude_deg,
      ),
      centerLinePathDistanceKilometers: _finiteOrNull(
        value.center_line_path_distance_km,
      ),
      outerNorthPath: _readPath(
        value.outer_north_path,
        value.outer_limit_path_count,
        LunarOccultationWhereResult.maxPathPoints,
        'outerLimitPathCount',
      ),
      outerSouthPath: _readPath(
        value.outer_south_path,
        value.outer_limit_path_count,
        LunarOccultationWhereResult.maxPathPoints,
        'outerLimitPathCount',
      ),
      outerLimitMeanWidthKilometers: _finiteOrNull(
        value.outer_limit_mean_width_km,
      ),
      outerLimitMaxWidthKilometers: _finiteOrNull(
        value.outer_limit_max_width_km,
      ),
      visibleRegionPolygon: _readPath(
        value.visible_region_polygon,
        value.visible_region_polygon_count,
        LunarOccultationWhereResult.maxPolygonPoints,
        'visibleRegionPolygonCount',
      ),
      visibleRegionMinLongitudeDegrees: _finiteOrNull(
        value.visible_region_min_longitude_deg,
      ),
      visibleRegionMaxLongitudeDegrees: _finiteOrNull(
        value.visible_region_max_longitude_deg,
      ),
      visibleRegionMinLatitudeDegrees: _finiteOrNull(
        value.visible_region_min_latitude_deg,
      ),
      visibleRegionMaxLatitudeDegrees: _finiteOrNull(
        value.visible_region_max_latitude_deg,
      ),
      maximumLocation: _readMaximumLocation(value, coordinate),
      separationRadians: _finiteOrNull(value.separation_rad),
      moonRadiusRadians: _finiteOrNull(value.moon_radius_rad),
      targetRadiusRadians: _finiteOrNull(value.target_radius_rad),
      marginRadians: _finiteOrNull(value.margin_rad),
      phenomena: _readPhenomena(value.phenomena),
      localSample: _readVisibilitySample(value.local_sample),
      visibilityFlags: OccultationVisibilityFlag.fromMask(
        value.visibility_flags,
      ),
    );
  }

  LunarOccultationPathPoint? _readMaximumLocation(
    taiyin_lunar_occultation_where_result value,
    JulianDate<Ut1Scale>? coordinate,
  ) {
    final longitude = _finiteOrNull(value.longitude_deg);
    final latitude = _finiteOrNull(value.latitude_deg);
    final height = _finiteOrNull(value.height_m);
    if (coordinate == null ||
        longitude == null ||
        latitude == null ||
        height == null) {
      return null;
    }
    return LunarOccultationPathPoint(
      valid: true,
      coordinate: coordinate,
      longitudeDegrees: longitude,
      latitudeDegrees: latitude,
      heightMeters: height,
    );
  }

  List<LunarOccultationPathPoint> _readPath(
    Array<taiyin_lunar_occultation_path_point> values,
    int count,
    int capacity,
    String name,
  ) {
    final safeCount = _validatedCount(count, capacity, name);
    return List.unmodifiable([
      for (var index = 0; index < safeCount; index++)
        _readPathPoint(values[index], name, index),
    ]);
  }

  LunarOccultationPathPoint _readPathPoint(
    taiyin_lunar_occultation_path_point value,
    String name,
    int index,
  ) {
    _requireValidEntry(value.valid, '$name[$index]');
    return LunarOccultationPathPoint(
      valid: true,
      coordinate: _ut1OrNull(value.jd_ut),
      longitudeDegrees: _finiteOrNull(value.longitude_deg),
      latitudeDegrees: _finiteOrNull(value.latitude_deg),
      heightMeters: _finiteOrNull(value.height_m),
    );
  }

  Pointer<taiyin_lunar_occultation_result> _writeOccultation(
    Arena arena,
    LunarOccultationResult value,
  ) {
    final output = arena<taiyin_lunar_occultation_result>();
    _bindings.taiyin_lunar_occultation_result_init(output);
    output.ref
      ..kind = value.kind.id
      ..type_flags = value.types.fold(0, (mask, type) => mask | type.mask)
      ..separation_rad = value.separationRadians
      ..moon_radius_rad = value.moonRadiusRadians
      ..target_radius_rad = value.targetRadiusRadians
      ..margin_rad = value.marginRadians
      ..candidate_count = value.candidateCount
      ..iteration_count = value.iterationCount
      ..evaluation_count = value.evaluationCount;
    _writeUt1(output.ref.jd_ut, value.coordinate);
    _writeUt1(output.ref.begin_jd_ut, value.begin);
    _writeUt1(output.ref.end_jd_ut, value.end);
    _writeUt1(output.ref.first_contact_jd_ut, value.firstContact);
    _writeUt1(output.ref.second_contact_jd_ut, value.secondContact);
    _writeUt1(output.ref.third_contact_jd_ut, value.thirdContact);
    _writeUt1(output.ref.fourth_contact_jd_ut, value.fourthContact);
    _writeUt1(output.ref.candidate_jd_ut, value.candidate);
    _writeUt1(output.ref.next_search_jd_ut, value.nextSearch);
    output.ref.phenomena
      ..angular_distance_rad =
          value.phenomena.angularDistanceRadians ?? double.nan
      ..diameter_ratio = value.phenomena.diameterRatio ?? double.nan
      ..magnitude = value.phenomena.magnitude ?? double.nan
      ..obscuration = value.phenomena.obscuration ?? double.nan
      ..occulted_fraction = value.phenomena.occultedFraction ?? double.nan;
    return output;
  }

  int _searchMask(
    Set<PositionFlag> positionFlags,
    Set<OccultationSearchOption> options,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      options.fold(0, (mask, option) => mask | option.mask),
    );
  }

  int _whereMask(
    Set<PositionFlag> positionFlags,
    Set<OccultationVisibilityOption> visibilityOptions,
  ) {
    _requireSupportedPositionFlags(positionFlags);
    return _mergeDisjointMasks(
      _positionMask(positionFlags),
      _visibilityMask(visibilityOptions),
    );
  }

  int _positionMask(Set<PositionFlag> flags) {
    return flags.fold(0, (mask, flag) => mask | flag.mask);
  }

  int _mergeDisjointMasks(int positionMask, int optionMask) {
    assert(
      (positionMask & optionMask) == 0,
      'Position flags and occultation options bit ranges overlap',
    );
    return positionMask | optionMask;
  }

  int _visibilityMask(Set<OccultationVisibilityOption> options) {
    return options.fold(0, (mask, option) => mask | option.mask);
  }

  void _requireSupportedPositionFlags(Set<PositionFlag> flags) {
    const supported = {
      PositionFlag.truePosition,
      PositionFlag.astrometric,
      PositionFlag.noAberration,
      PositionFlag.noGravitationalDeflection,
    };
    final unsupported = flags.difference(supported);
    if (unsupported.isNotEmpty) {
      throw ArgumentError.value(
        flags,
        'positionFlags',
        'lunar occultations support only truePosition, astrometric, '
            'noAberration, and noGravitationalDeflection',
      );
    }
  }

  void _requireStarKey(String starKey) {
    if (starKey.isEmpty || starKey.contains('\u0000')) {
      throw ArgumentError.value(
        starKey,
        'starKey',
        'must be non-empty and contain no NUL character',
      );
    }
  }

  void _requireBodyTarget(Target target) {
    if (_unsupportedBodyTargetIds.contains(target.id)) {
      throw ArgumentError.value(
        target,
        'target',
        'must not be the Moon, Earth, Earth-Moon barycenter, Sun, or '
            'solar-system barycenter',
      );
    }
  }

  void _requireKind(
    LunarOccultationResult occultation,
    LunarOccultationKind expected,
  ) {
    if (occultation.kind != expected) {
      throw ArgumentError.value(
        occultation,
        'occultation',
        'must be a $expected result',
      );
    }
  }

  void _requireNonnegativeOptional(double? value, String name) {
    if (value == null) return;
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        name,
        'must be finite and greater than or equal to zero',
      );
    }
  }

  int _validatedCount(int count, int capacity, String name) {
    if (count < 0 || count > capacity) {
      throw StateError(
        'Native occultation result reported $name=$count outside 0..$capacity',
      );
    }
    return count;
  }

  void _requireValidEntry(int valid, String name) {
    if (valid == 0) {
      throw StateError(
        'Native occultation result reported an invalid $name inside its count',
      );
    }
  }

  JulianDate<Ut1Scale> _requiredUt1(
    taiyin_split_julian_date value,
    String name,
  ) {
    return _ut1OrNull(value) ??
        (throw StateError('Native occultation result has no $name'));
  }

  JulianDate<Ut1Scale>? _ut1OrNull(taiyin_split_julian_date value) {
    return value.day_fraction.isFinite ? readJulianDate<Ut1Scale>(value) : null;
  }

  void _writeUt1(taiyin_split_julian_date target, JulianDate<Ut1Scale>? value) {
    target
      ..day_number = value?.dayNumber ?? 0
      ..day_fraction = value?.dayFraction ?? double.nan;
  }

  double? _finiteOrNull(double value) => value.isFinite ? value : null;
}
