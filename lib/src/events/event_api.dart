part of '../taiyin.dart';

typedef _EventsStatusChecker =
    void Function(int status, TaiyinEphemerisDiagnostic? diagnostic);
typedef _EventScalarCalculation =
    int Function(
      Pointer<Double> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _EventDateArrayCalculation =
    int Function(
      Pointer<Double> output,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _EventPairArrayCalculation =
    int Function(
      Pointer<Double> primary,
      Pointer<Double> secondary,
      int capacity,
      Pointer<Size> count,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );

/// Longitude, aspect, phase, elongation, separation, and solar-transit
/// searches.
///
/// All native event coordinates are scalar Julian dates. [JulianDate] remains
/// split in Dart, but every input and returned event crosses that scalar-JD FFI
/// boundary.
final class TaiyinEventsApi {
  TaiyinEventsApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _EventsStatusChecker _checkStatus;

  /// Native-recommended maximum step for a bounded longitude search.
  double recommendedLongitudeSearchStepDays(TaiyinTarget body) {
    _ensureOpen();
    _requireNonZeroTarget(body, 'body');
    return _bindings.taiyin_recommended_longitude_search_step_days(body.id);
  }

  /// Native-recommended maximum step for a bounded aspect search.
  ///
  /// The recommendation is independent of target order: native code uses the
  /// smaller of the two targets' longitude-search recommendations.
  double recommendedAspectSearchStepDays(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
  ) {
    _ensureOpen();
    _requireDistinctTargets(bodyA, bodyB);
    return _bindings.taiyin_recommended_aspect_search_step_days(
      bodyA.id,
      bodyB.id,
    );
  }

  /// Finds a solar ecliptic-longitude crossing near a UT1 estimate.
  TaiyinEphemerisResult<JulianDate<Ut1Scale>> solarLongitudeAtUt1(
    double targetLongitudeRadians,
    JulianDate<Ut1Scale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinEventSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireFinite(targetLongitudeRadians, 'targetLongitudeRadians');
    final mask = _eventMask(
      positionFlags,
      options,
      allowedOptions: const {TaiyinEventSearchOption.reverse},
    );
    return _scalar<Ut1Scale>((output, diagnostic) {
      return _bindings.taiyin_search_solar_longitude_ut(
        _context,
        targetLongitudeRadians,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds a solar ecliptic-longitude crossing near a TT estimate.
  TaiyinEphemerisResult<JulianDate<TtScale>> solarLongitudeAtTt(
    double targetLongitudeRadians,
    JulianDate<TtScale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinEventSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireFinite(targetLongitudeRadians, 'targetLongitudeRadians');
    final mask = _eventMask(
      positionFlags,
      options,
      allowedOptions: const {TaiyinEventSearchOption.reverse},
    );
    return _scalar<TtScale>((output, diagnostic) {
      return _bindings.taiyin_search_solar_longitude_tt(
        _context,
        targetLongitudeRadians,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds a lunar ecliptic-longitude crossing near a UT1 estimate.
  TaiyinEphemerisResult<JulianDate<Ut1Scale>> moonLongitudeAtUt1(
    double targetLongitudeRadians,
    JulianDate<Ut1Scale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinEventSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireFinite(targetLongitudeRadians, 'targetLongitudeRadians');
    final mask = _eventMask(
      positionFlags,
      options,
      allowedOptions: const {TaiyinEventSearchOption.reverse},
    );
    return _scalar<Ut1Scale>((output, diagnostic) {
      return _bindings.taiyin_search_moon_longitude_ut(
        _context,
        targetLongitudeRadians,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds a lunar ecliptic-longitude crossing near a TT estimate.
  TaiyinEphemerisResult<JulianDate<TtScale>> moonLongitudeAtTt(
    double targetLongitudeRadians,
    JulianDate<TtScale> estimate, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinEventSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireFinite(targetLongitudeRadians, 'targetLongitudeRadians');
    final mask = _eventMask(
      positionFlags,
      options,
      allowedOptions: const {TaiyinEventSearchOption.reverse},
    );
    return _scalar<TtScale>((output, diagnostic) {
      return _bindings.taiyin_search_moon_longitude_tt(
        _context,
        targetLongitudeRadians,
        estimate.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds all [body] longitude crossings in a UT1 interval.
  TaiyinEphemerisResult<List<JulianDate<Ut1Scale>>> longitudeCrossingsAtUt1(
    TaiyinTarget body,
    double targetLongitudeRadians,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireNonZeroTarget(body, 'body');
    _requireFinite(targetLongitudeRadians, 'targetLongitudeRadians');
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return _dateArray<Ut1Scale>(maxResults, (
      output,
      capacity,
      count,
      diagnostic,
    ) {
      return _bindings.taiyin_search_body_longitude_crossings_ut(
        _context,
        body.id,
        targetLongitudeRadians,
        start.toDouble(),
        end.toDouble(),
        maxStepDays,
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Finds all [body] longitude crossings in a TT interval.
  TaiyinEphemerisResult<List<JulianDate<TtScale>>> longitudeCrossingsAtTt(
    TaiyinTarget body,
    double targetLongitudeRadians,
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireNonZeroTarget(body, 'body');
    _requireFinite(targetLongitudeRadians, 'targetLongitudeRadians');
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return _dateArray<TtScale>(maxResults, (
      output,
      capacity,
      count,
      diagnostic,
    ) {
      return _bindings.taiyin_search_body_longitude_crossings_tt(
        _context,
        body.id,
        targetLongitudeRadians,
        start.toDouble(),
        end.toDouble(),
        maxStepDays,
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Finds stationary longitudes of [body] in a UT1 interval.
  TaiyinEphemerisResult<List<TaiyinLongitudeStation<Ut1Scale>>>
  longitudeStationsAtUt1(
    TaiyinTarget body,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireNonZeroTarget(body, 'body');
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return _pairArray<Ut1Scale, TaiyinLongitudeStation<Ut1Scale>>(
      maxResults,
      (primary, secondary, capacity, count, diagnostic) {
        return _bindings.taiyin_search_body_longitude_stations_ut(
          _context,
          body.id,
          start.toDouble(),
          end.toDouble(),
          maxStepDays,
          mask,
          primary,
          secondary,
          capacity,
          count,
          diagnostic,
        );
      },
      (coordinate, longitude) => TaiyinLongitudeStation(
        coordinate: JulianDate<Ut1Scale>.fromDouble(coordinate),
        longitudeRadians: longitude,
      ),
    );
  }

  /// Finds stationary longitudes of [body] in a TT interval.
  TaiyinEphemerisResult<List<TaiyinLongitudeStation<TtScale>>>
  longitudeStationsAtTt(
    TaiyinTarget body,
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireNonZeroTarget(body, 'body');
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return _pairArray<TtScale, TaiyinLongitudeStation<TtScale>>(
      maxResults,
      (primary, secondary, capacity, count, diagnostic) {
        return _bindings.taiyin_search_body_longitude_stations_tt(
          _context,
          body.id,
          start.toDouble(),
          end.toDouble(),
          maxStepDays,
          mask,
          primary,
          secondary,
          capacity,
          count,
          diagnostic,
        );
      },
      (coordinate, longitude) => TaiyinLongitudeStation(
        coordinate: JulianDate<TtScale>.fromDouble(coordinate),
        longitudeRadians: longitude,
      ),
    );
  }

  /// Finds [aspectRadians] crossings between two targets in a UT1 interval.
  TaiyinEphemerisResult<List<JulianDate<Ut1Scale>>> aspectCrossingsAtUt1(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
    double aspectRadians,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireDistinctTargets(bodyA, bodyB);
    _requireFinite(aspectRadians, 'aspectRadians');
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return _dateArray<Ut1Scale>(maxResults, (
      output,
      capacity,
      count,
      diagnostic,
    ) {
      return _bindings.taiyin_search_body_aspect_crossings_ut(
        _context,
        bodyA.id,
        bodyB.id,
        aspectRadians,
        start.toDouble(),
        end.toDouble(),
        maxStepDays,
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Finds [aspectRadians] crossings between two targets in a TT interval.
  TaiyinEphemerisResult<List<JulianDate<TtScale>>> aspectCrossingsAtTt(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
    double aspectRadians,
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireDistinctTargets(bodyA, bodyB);
    _requireFinite(aspectRadians, 'aspectRadians');
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return _dateArray<TtScale>(maxResults, (
      output,
      capacity,
      count,
      diagnostic,
    ) {
      return _bindings.taiyin_search_body_aspect_crossings_tt(
        _context,
        bodyA.id,
        bodyB.id,
        aspectRadians,
        start.toDouble(),
        end.toDouble(),
        maxStepDays,
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Finds exact matches against any of [aspectSeparationsRadians] in UT1.
  TaiyinEphemerisResult<List<TaiyinExactAspectEvent<Ut1Scale>>>
  exactAspectsAtUt1(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
    List<double> aspectSeparationsRadians,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    return _exactAspects<Ut1Scale>(
      bodyA,
      bodyB,
      aspectSeparationsRadians,
      start,
      end,
      maxStepDays: maxStepDays,
      maxResults: maxResults,
      positionFlags: positionFlags,
      calculate:
          (
            aspects,
            aspectCount,
            output,
            outputAspects,
            capacity,
            count,
            diagnostic,
            mask,
          ) => _bindings.taiyin_search_body_exact_aspects_ut(
            _context,
            bodyA.id,
            bodyB.id,
            aspects,
            aspectCount,
            start.toDouble(),
            end.toDouble(),
            maxStepDays,
            mask,
            output,
            outputAspects,
            capacity,
            count,
            diagnostic,
          ),
    );
  }

  /// Finds exact matches against any of [aspectSeparationsRadians] in TT.
  TaiyinEphemerisResult<List<TaiyinExactAspectEvent<TtScale>>> exactAspectsAtTt(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
    List<double> aspectSeparationsRadians,
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    return _exactAspects<TtScale>(
      bodyA,
      bodyB,
      aspectSeparationsRadians,
      start,
      end,
      maxStepDays: maxStepDays,
      maxResults: maxResults,
      positionFlags: positionFlags,
      calculate:
          (
            aspects,
            aspectCount,
            output,
            outputAspects,
            capacity,
            count,
            diagnostic,
            mask,
          ) => _bindings.taiyin_search_body_exact_aspects_tt(
            _context,
            bodyA.id,
            bodyB.id,
            aspects,
            aspectCount,
            start.toDouble(),
            end.toDouble(),
            maxStepDays,
            mask,
            output,
            outputAspects,
            capacity,
            count,
            diagnostic,
          ),
    );
  }

  /// Finds the greatest elongation of Mercury or Venus in a UT1 interval.
  TaiyinEphemerisResult<TaiyinGreatestElongationEvent> greatestElongationAtUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireInnerPlanet(body);
    _validateInterval(start, end);
    final mask = _eventMask(positionFlags, const {});
    return using((arena) {
      final output = arena<taiyin_greatest_elongation_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_greatest_elongation_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_search_greatest_elongation_ut(
        _context,
        body.id,
        start.toDouble(),
        end.toDouble(),
        mask,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinGreatestElongationEvent(
          bodyId: value.body_id,
          coordinate: JulianDate<Ut1Scale>.fromDouble(value.jd_ut),
          elongationRadians: value.elongation_rad,
          relativeLongitudeRadians: value.relative_longitude_rad,
          kind: TaiyinGreatestElongationKind.fromMask(value.kind),
          iterationCount: value.iteration_count,
          evaluationCount: value.evaluation_count,
          phenomena: TaiyinEventPhenomena(
            phaseAngleRadians: value.phenomena.phase_angle_rad,
            illuminatedFraction: value.phenomena.illuminated_fraction,
            solarElongationRadians: value.phenomena.solar_elongation_rad,
            apparentDiameterRadians: value.phenomena.apparent_diameter_rad,
            apparentMagnitude: value.phenomena.apparent_magnitude,
            horizontalParallaxRadians: _finiteOrNull(
              value.phenomena.horizontal_parallax_rad,
            ),
          ),
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  /// Finds a local minimum of separation between two targets in UT1.
  TaiyinEphemerisResult<TaiyinMinimumAngularSeparationEvent<Ut1Scale>>
  minimumAngularSeparationAtUt1(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double maxStepDays,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    return _minimumSeparation<Ut1Scale>(
      bodyA,
      bodyB,
      start,
      end,
      maxStepDays: maxStepDays,
      positionFlags: positionFlags,
      calculate: (output, diagnostic, mask) =>
          _bindings.taiyin_search_minimum_angular_separation_ut(
            _context,
            bodyA.id,
            bodyB.id,
            start.toDouble(),
            end.toDouble(),
            maxStepDays,
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Finds a local minimum of separation between two targets in TT.
  TaiyinEphemerisResult<TaiyinMinimumAngularSeparationEvent<TtScale>>
  minimumAngularSeparationAtTt(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double maxStepDays,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    return _minimumSeparation<TtScale>(
      bodyA,
      bodyB,
      start,
      end,
      maxStepDays: maxStepDays,
      positionFlags: positionFlags,
      calculate: (output, diagnostic, mask) =>
          _bindings.taiyin_search_minimum_angular_separation_tt(
            _context,
            bodyA.id,
            bodyB.id,
            start.toDouble(),
            end.toDouble(),
            maxStepDays,
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Finds the next global Mercury or Venus solar transit from [start].
  TaiyinEphemerisResult<TaiyinSolarTransitEvent> nextSolarTransitAtUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> start, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinEventSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInnerPlanet(body);
    final mask = _eventMask(
      positionFlags,
      options,
      allowedOptions: const {TaiyinEventSearchOption.reverse},
      disallowTopocentric: true,
    );
    return _solarTransit((output, diagnostic) {
      return _bindings.taiyin_search_next_solar_transit_ut(
        _context,
        body.id,
        start.toDouble(),
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Computes local circumstances for a previously found [globalTransit].
  TaiyinEphemerisResult<TaiyinLocalSolarTransitEvent> localSolarTransitAtUt1(
    TaiyinSolarTransitEvent globalTransit,
    TaiyinObserverLocation observer, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinEventSearchOption> options = const {},
  }) {
    _ensureOpen();
    _validateObserver(observer);
    final mask = _eventMask(
      positionFlags,
      options,
      allowedOptions: const {
        TaiyinEventSearchOption.refraction,
        TaiyinEventSearchOption.noRefraction,
      },
      disallowTopocentric: true,
    );
    return using((arena) {
      final global = arena<taiyin_solar_transit_result>();
      _writeSolarTransit(global.ref, globalTransit);
      return _localSolarTransit((output, diagnostic) {
        return _bindings.taiyin_compute_local_solar_transit_ut(
          _context,
          global,
          observer.longitudeDegrees,
          observer.latitudeDegrees,
          observer.heightMeters,
          mask,
          output,
          diagnostic,
        );
      });
    });
  }

  /// Finds the next local Mercury or Venus solar transit from [start].
  TaiyinEphemerisResult<TaiyinLocalSolarTransitEvent>
  nextLocalSolarTransitAtUt1(
    TaiyinBody body,
    JulianDate<Ut1Scale> start,
    TaiyinObserverLocation observer, {
    Set<TaiyinPositionFlag> positionFlags = const {},
    Set<TaiyinEventSearchOption> options = const {},
  }) {
    _ensureOpen();
    _requireInnerPlanet(body);
    _validateObserver(observer);
    final mask = _eventMask(
      positionFlags,
      options,
      allowedOptions: const {
        TaiyinEventSearchOption.reverse,
        TaiyinEventSearchOption.refraction,
        TaiyinEventSearchOption.noRefraction,
      },
      disallowTopocentric: true,
    );
    return _localSolarTransit((output, diagnostic) {
      return _bindings.taiyin_search_next_local_solar_transit_ut(
        _context,
        body.id,
        start.toDouble(),
        observer.longitudeDegrees,
        observer.latitudeDegrees,
        observer.heightMeters,
        mask,
        output,
        diagnostic,
      );
    });
  }

  /// Finds lunar phase crossings in a UT1 interval.
  TaiyinEphemerisResult<List<JulianDate<Ut1Scale>>> lunarPhaseCrossingsAtUt1(
    double phaseRadians,
    JulianDate<Ut1Scale> start,
    JulianDate<Ut1Scale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireFinite(phaseRadians, 'phaseRadians');
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return _dateArray<Ut1Scale>(maxResults, (
      output,
      capacity,
      count,
      diagnostic,
    ) {
      return _bindings.taiyin_search_lunar_phase_crossings_ut(
        _context,
        phaseRadians,
        start.toDouble(),
        end.toDouble(),
        maxStepDays,
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  /// Finds lunar phase crossings in a TT interval.
  TaiyinEphemerisResult<List<JulianDate<TtScale>>> lunarPhaseCrossingsAtTt(
    double phaseRadians,
    JulianDate<TtScale> start,
    JulianDate<TtScale> end, {
    required double maxStepDays,
    int maxResults = 16,
    Set<TaiyinPositionFlag> positionFlags = const {},
  }) {
    _ensureOpen();
    _requireFinite(phaseRadians, 'phaseRadians');
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return _dateArray<TtScale>(maxResults, (
      output,
      capacity,
      count,
      diagnostic,
    ) {
      return _bindings.taiyin_search_lunar_phase_crossings_tt(
        _context,
        phaseRadians,
        start.toDouble(),
        end.toDouble(),
        maxStepDays,
        mask,
        output,
        capacity,
        count,
        diagnostic,
      );
    });
  }

  TaiyinEphemerisResult<JulianDate<S>> _scalar<S extends TimeScale>(
    _EventScalarCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<Double>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: JulianDate<S>.fromDouble(output.value),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<List<JulianDate<S>>> _dateArray<S extends TimeScale>(
    int maxResults,
    _EventDateArrayCalculation calculate,
  ) {
    return using((arena) {
      final output = arena<Double>(maxResults);
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, maxResults, count, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final resultCount = _validatedResultCount(count.value, maxResults);
      final values = List<JulianDate<S>>.unmodifiable(
        List.generate(
          resultCount,
          (index) => JulianDate<S>.fromDouble((output + index).value),
        ),
      );
      return TaiyinEphemerisResult(value: values, diagnostic: mappedDiagnostic);
    });
  }

  TaiyinEphemerisResult<List<T>> _pairArray<S extends TimeScale, T>(
    int maxResults,
    _EventPairArrayCalculation calculate,
    T Function(double coordinate, double secondary) read,
  ) {
    return using((arena) {
      final primary = arena<Double>(maxResults);
      final secondary = arena<Double>(maxResults);
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(
        primary,
        secondary,
        maxResults,
        count,
        diagnostic,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final resultCount = _validatedResultCount(count.value, maxResults);
      final values = List<T>.unmodifiable(
        List.generate(
          resultCount,
          (index) => read((primary + index).value, (secondary + index).value),
        ),
      );
      return TaiyinEphemerisResult(value: values, diagnostic: mappedDiagnostic);
    });
  }

  TaiyinEphemerisResult<List<TaiyinExactAspectEvent<S>>>
  _exactAspects<S extends TimeScale>(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
    List<double> aspectSeparationsRadians,
    JulianDate<S> start,
    JulianDate<S> end, {
    required double maxStepDays,
    required int maxResults,
    required Set<TaiyinPositionFlag> positionFlags,
    required int Function(
      Pointer<Double>,
      int,
      Pointer<Double>,
      Pointer<Double>,
      int,
      Pointer<Size>,
      Pointer<taiyin_ephemeris_diagnostic>,
      int,
    )
    calculate,
  }) {
    _requireDistinctTargets(bodyA, bodyB);
    if (aspectSeparationsRadians.isEmpty) {
      throw ArgumentError.value(
        aspectSeparationsRadians,
        'aspectSeparationsRadians',
        'must not be empty',
      );
    }
    for (final value in aspectSeparationsRadians) {
      _requireFinite(value, 'aspectSeparationsRadians');
    }
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    _requireCapacity(maxResults);
    final mask = _eventMask(positionFlags, const {});
    return using((arena) {
      final aspects = arena<Double>(aspectSeparationsRadians.length);
      for (var index = 0; index < aspectSeparationsRadians.length; index++) {
        (aspects + index).value = aspectSeparationsRadians[index];
      }
      final output = arena<Double>(maxResults);
      final outputAspects = arena<Double>(maxResults);
      final count = arena<Size>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(
        aspects,
        aspectSeparationsRadians.length,
        output,
        outputAspects,
        maxResults,
        count,
        diagnostic,
        mask,
      );
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final resultCount = _validatedResultCount(count.value, maxResults);
      final values = List<TaiyinExactAspectEvent<S>>.unmodifiable(
        List.generate(
          resultCount,
          (index) => TaiyinExactAspectEvent(
            coordinate: JulianDate<S>.fromDouble((output + index).value),
            aspectRadians: (outputAspects + index).value,
          ),
        ),
      );
      return TaiyinEphemerisResult(value: values, diagnostic: mappedDiagnostic);
    });
  }

  TaiyinEphemerisResult<TaiyinMinimumAngularSeparationEvent<S>>
  _minimumSeparation<S extends TimeScale>(
    TaiyinTarget bodyA,
    TaiyinTarget bodyB,
    JulianDate<S> start,
    JulianDate<S> end, {
    required double maxStepDays,
    required Set<TaiyinPositionFlag> positionFlags,
    required int Function(
      Pointer<taiyin_angular_separation_result>,
      Pointer<taiyin_ephemeris_diagnostic>,
      int,
    )
    calculate,
  }) {
    _requireDistinctTargets(bodyA, bodyB);
    _validateInterval(start, end);
    _requirePositiveFinite(maxStepDays, 'maxStepDays');
    final mask = _eventMask(positionFlags, const {});
    return using((arena) {
      final output = arena<taiyin_angular_separation_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_angular_separation_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic, mask);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinMinimumAngularSeparationEvent<S>(
          bodyAId: value.body_a_id,
          bodyBId: value.body_b_id,
          coordinate: JulianDate<S>.fromDouble(value.jd),
          separationRadians: value.separation_rad,
          separationRateRadiansPerDay: value.separation_rate_rad_per_day,
          iterationCount: value.iteration_count,
          evaluationCount: value.evaluation_count,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinSolarTransitEvent> _solarTransit(
    int Function(
      Pointer<taiyin_solar_transit_result>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_solar_transit_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_solar_transit_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      return TaiyinEphemerisResult(
        value: _readSolarTransit(output.ref),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinEphemerisResult<TaiyinLocalSolarTransitEvent> _localSolarTransit(
    int Function(
      Pointer<taiyin_local_solar_transit_result>,
      Pointer<taiyin_ephemeris_diagnostic>,
    )
    calculate,
  ) {
    return using((arena) {
      final output = arena<taiyin_local_solar_transit_result>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_local_solar_transit_result_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(output, diagnostic);
      final mappedDiagnostic = _readEphemerisDiagnostic(diagnostic.ref);
      _checkStatus(status, mappedDiagnostic);
      final value = output.ref;
      return TaiyinEphemerisResult(
        value: TaiyinLocalSolarTransitEvent(
          global: _readSolarTransit(value.global),
          topocentric: _readSolarTransit(value.topocentric),
          visibilityFlags: TaiyinSolarTransitVisibilityFlag.fromMask(
            value.visibility_flags,
          ),
          contactSunAltitudeDegrees: List.generate(
            TaiyinLocalSolarTransitEvent.contactSlotCount,
            (index) => value.contact_sun_altitude_deg[index],
          ),
          contactSunAzimuthDegrees: List.generate(
            TaiyinLocalSolarTransitEvent.contactSlotCount,
            (index) => value.contact_sun_azimuth_deg[index],
          ),
          sunrise: _ut1OrNull(value.sunrise_jd_ut),
          sunset: _ut1OrNull(value.sunset_jd_ut),
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  TaiyinSolarTransitEvent _readSolarTransit(taiyin_solar_transit_result value) {
    return TaiyinSolarTransitEvent(
      bodyId: value.body_id,
      kinds: TaiyinSolarTransitKind.values
          .where((kind) => (value.kind & kind.mask) != 0)
          .toSet(),
      greatest: JulianDate<Ut1Scale>.fromDouble(value.greatest_jd_ut),
      minimumSeparationRadians: value.minimum_separation_rad,
      sunRadiusRadians: value.sun_radius_rad,
      bodyRadiusRadians: value.body_radius_rad,
      t1: _ut1OrNull(value.t1_jd_ut),
      t2: _ut1OrNull(value.t2_jd_ut),
      t3: _ut1OrNull(value.t3_jd_ut),
      t4: _ut1OrNull(value.t4_jd_ut),
      iterationCount: value.iteration_count,
      evaluationCount: value.evaluation_count,
    );
  }

  void _writeSolarTransit(
    taiyin_solar_transit_result output,
    TaiyinSolarTransitEvent value,
  ) {
    output
      ..struct_size = sizeOf<taiyin_solar_transit_result>()
      ..body_id = value.bodyId
      ..kind = value.kinds.fold(0, (mask, kind) => mask | kind.mask)
      ..greatest_jd_ut = value.greatest.toDouble()
      ..minimum_separation_rad = value.minimumSeparationRadians
      ..sun_radius_rad = value.sunRadiusRadians
      ..body_radius_rad = value.bodyRadiusRadians
      ..t1_jd_ut = value.t1?.toDouble() ?? double.nan
      ..t2_jd_ut = value.t2?.toDouble() ?? double.nan
      ..t3_jd_ut = value.t3?.toDouble() ?? double.nan
      ..t4_jd_ut = value.t4?.toDouble() ?? double.nan
      ..iteration_count = value.iterationCount
      ..evaluation_count = value.evaluationCount;
  }

  int _eventMask(
    Set<TaiyinPositionFlag> positionFlags,
    Set<TaiyinEventSearchOption> options, {
    Set<TaiyinEventSearchOption> allowedOptions = const {},
    bool disallowTopocentric = false,
  }) {
    const unsupportedCoordinates = {
      TaiyinPositionFlag.xyz,
      TaiyinPositionFlag.equatorial,
    };
    final unsupportedPositions = positionFlags.intersection(
      unsupportedCoordinates,
    );
    if (unsupportedPositions.isNotEmpty ||
        (disallowTopocentric &&
            positionFlags.contains(TaiyinPositionFlag.topocentric))) {
      throw ArgumentError.value(
        positionFlags,
        'positionFlags',
        'event searches require ecliptic spherical coordinates'
            '${disallowTopocentric ? ' and a geocentric context' : ''}',
      );
    }
    final unsupportedOptions = options.difference(allowedOptions);
    if (unsupportedOptions.isNotEmpty) {
      throw ArgumentError.value(
        options,
        'options',
        'contains options unsupported by this event search',
      );
    }
    if (options.contains(TaiyinEventSearchOption.refraction) &&
        options.contains(TaiyinEventSearchOption.noRefraction)) {
      throw ArgumentError.value(
        options,
        'options',
        'refraction and noRefraction cannot be requested together',
      );
    }
    return positionFlags.fold(0, (mask, flag) => mask | flag.mask) |
        options.fold(0, (mask, option) => mask | option.mask);
  }

  void _validateInterval<S extends TimeScale>(
    JulianDate<S> start,
    JulianDate<S> end,
  ) {
    if (end.compareTo(start) <= 0) {
      throw ArgumentError.value(end, 'end', 'must be later than start');
    }
  }

  void _requireDistinctTargets(TaiyinTarget bodyA, TaiyinTarget bodyB) {
    _requireNonZeroTarget(bodyA, 'bodyA');
    _requireNonZeroTarget(bodyB, 'bodyB');
    if (bodyA.id == bodyB.id) {
      throw ArgumentError.value(bodyB, 'bodyB', 'must differ from bodyA');
    }
  }

  void _requireNonZeroTarget(TaiyinTarget body, String name) {
    if (body.id == 0) {
      throw ArgumentError.value(
        body,
        name,
        'must not be the solar-system barycenter',
      );
    }
  }

  void _requireInnerPlanet(TaiyinBody body) {
    if (body != TaiyinBody.mercury && body != TaiyinBody.venus) {
      throw ArgumentError.value(body, 'body', 'must be Mercury or Venus');
    }
  }

  void _validateObserver(TaiyinObserverLocation observer) {
    _requireFinite(observer.longitudeDegrees, 'observer.longitudeDegrees');
    _requireFinite(observer.latitudeDegrees, 'observer.latitudeDegrees');
    _requireFinite(observer.heightMeters, 'observer.heightMeters');
    if (observer.latitudeDegrees < -90 || observer.latitudeDegrees > 90) {
      throw RangeError.range(
        observer.latitudeDegrees,
        -90,
        90,
        'observer.latitudeDegrees',
      );
    }
  }

  void _requirePositiveFinite(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        'must be finite and greater than zero',
      );
    }
  }

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }

  void _requireCapacity(int maxResults) {
    if (maxResults <= 0) {
      throw RangeError.range(maxResults, 1, null, 'maxResults');
    }
  }

  int _validatedResultCount(int nativeCount, int capacity) {
    if (nativeCount > capacity) {
      throw StateError(
        'Native event search returned $nativeCount results for capacity '
        '$capacity',
      );
    }
    return nativeCount;
  }

  JulianDate<Ut1Scale>? _ut1OrNull(double value) {
    return value.isFinite && value > 0
        ? JulianDate<Ut1Scale>.fromDouble(value)
        : null;
  }

  double? _finiteOrNull(double value) => value.isFinite ? value : null;
}
