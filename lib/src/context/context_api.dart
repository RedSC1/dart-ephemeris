part of '../taiyin.dart';

/// Mutable configuration owned by one Taiyin calculation context.
///
/// Finish configuration before using the owning context concurrently. Cloned
/// [TaiyinContext] instances receive an independent copy of this state.
final class TaiyinContextConfiguration {
  TaiyinContextConfiguration._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final void Function(int status) _checkStatus;

  /// Restores the native calculation context to its defaults.
  void reset() {
    _ensureOpen();
    _checkStatus(_bindings.taiyin_context_reset(_context));
  }

  /// Sets the geographic observer location.
  void setObserverLocation(TaiyinObserverLocation location) {
    _ensureOpen();
    _validateLocation(location);
    using((arena) {
      final native = _writeLocation(arena, location);
      _checkStatus(
        _bindings.taiyin_context_set_observer_location(_context, native),
      );
    });
  }

  /// Removes any geographic observer location from the context.
  void clearObserverLocation() {
    _ensureOpen();
    _checkStatus(_bindings.taiyin_context_clear_observer_location(_context));
  }

  /// Sets complete atmospheric conditions.
  void setAtmosphere(TaiyinAtmosphere atmosphere) {
    _ensureOpen();
    _validateAtmosphere(atmosphere);
    using((arena) {
      final native = arena<taiyin_atmosphere>();
      _bindings.taiyin_atmosphere_init(native);
      native.ref
        ..pressure_mbar = atmosphere.pressureMillibars
        ..temperature_celsius = atmosphere.temperatureCelsius
        ..relative_humidity_percent = atmosphere.relativeHumidityPercent
        ..wavelength_micrometer = atmosphere.wavelengthMicrometers;
      _checkStatus(_bindings.taiyin_context_set_atmosphere(_context, native));
    });
  }

  /// Sets only pressure and temperature, clearing humidity and wavelength.
  void setAtmospherePressureTemperature({
    required double pressureMillibars,
    required double temperatureCelsius,
  }) {
    _ensureOpen();
    _requireFinite(pressureMillibars, 'pressureMillibars');
    _requireFinite(temperatureCelsius, 'temperatureCelsius');
    _checkStatus(
      _bindings.taiyin_context_set_atmosphere_pressure_temperature(
        _context,
        pressureMillibars,
        temperatureCelsius,
      ),
    );
  }

  /// Replaces atmospheric conditions with Taiyin's standard atmosphere.
  void setStandardAtmosphere() {
    _ensureOpen();
    _checkStatus(_bindings.taiyin_context_set_standard_atmosphere(_context));
  }

  /// Replaces fallback behavior for missing atmospheric values.
  ///
  /// Passing an empty set clears all atmosphere-policy flags.
  void setAtmospherePolicy(Set<TaiyinAtmospherePolicyFlag> flags) {
    _ensureOpen();
    final mask = flags.fold(0, (value, flag) => value | flag.mask);
    _checkStatus(
      _bindings.taiyin_context_set_atmosphere_policy(_context, mask),
    );
  }

  /// Sets meteorological visibility range in kilometres.
  ///
  /// [rangeKm] must be at least 1 km.
  void setMeteorologicalRangeKm(double rangeKm) {
    _ensureOpen();
    _requireFinite(rangeKm, 'rangeKm');
    if (rangeKm < 1) {
      throw RangeError.range(rangeKm, 1, null, 'rangeKm');
    }
    _checkStatus(
      _bindings.taiyin_context_set_meteorological_range_km(_context, rangeKm),
    );
  }

  /// Configures a geocentric observer and its ephemeris center.
  ///
  /// The arguments are native body IDs rather than [TaiyinBody] values so
  /// custom registered targets remain usable.
  void setGeocentricObserver({required int observerId, required int centerId}) {
    _ensureOpen();
    _requireInt32(observerId, 'observerId');
    _requireInt32(centerId, 'centerId');
    _checkStatus(
      _bindings.taiyin_context_set_geocentric_observer(
        _context,
        observerId,
        centerId,
      ),
    );
  }

  /// Sets an explicit ICRF topocentric observer offset.
  void setTopocentricObserverOffset(TaiyinCartesianState offset) {
    _ensureOpen();
    _validateState(offset);
    using((arena) {
      final native = arena<taiyin_cartesian_state>();
      _bindings.taiyin_cartesian_state_init(native);
      _writeVector(native.ref.position_au, offset.positionAu);
      _writeVector(native.ref.velocity_au_per_day, offset.velocityAuPerDay);
      _writeVector(
        native.ref.acceleration_au_per_day2,
        offset.accelerationAuPerDay2,
      );
      _checkStatus(
        _bindings.taiyin_context_set_topocentric_observer_offset(
          _context,
          native,
        ),
      );
    });
  }

  /// Computes a simple topocentric offset from UT1 and TT coordinates.
  void setSimpleTopocentricObserver(
    TaiyinObserverLocation location, {
    required JulianDate<Ut1Scale> ut1,
    required JulianDate<TtScale> tt,
  }) {
    _ensureOpen();
    _validateLocation(location);
    using((arena) {
      final native = _writeLocation(arena, location);
      _checkStatus(
        _bindings.taiyin_context_set_simple_topocentric_observer(
          _context,
          native,
          writeJulianDate(arena, ut1),
          writeJulianDate(arena, tt),
        ),
      );
    });
  }

  /// Computes an EOP-backed topocentric offset from UTC and TT coordinates.
  void setPreciseTopocentricObserver(
    TaiyinObserverLocation location, {
    required JulianDate<UtcScale> utc,
    required JulianDate<TtScale> tt,
  }) {
    _ensureOpen();
    _validateLocation(location);
    using((arena) {
      final native = _writeLocation(arena, location);
      _checkStatus(
        _bindings.taiyin_context_set_precise_topocentric_observer(
          _context,
          native,
          writeJulianDate(arena, utc),
          writeJulianDate(arena, tt),
        ),
      );
    });
  }

  /// Selects a native ephemeris route-rule table.
  void setRouteRule(TaiyinRouteRule routeRule) {
    _ensureOpen();
    _checkStatus(
      _bindings.taiyin_context_set_route_rule(_context, routeRule.id),
    );
  }

  /// Sets astronomy model selection as one coherent configuration.
  void setAstroModels(TaiyinAstroModelConfig config) {
    _ensureOpen();
    using((arena) {
      final native = arena<taiyin_astro_model_config>();
      _bindings.taiyin_astro_model_config_init(native);
      native.ref
        ..tdb_model_id = config.tdbModel.id
        ..precession_model_id = config.precessionModel?.id ?? -1
        ..nutation_model_id = config.nutationModel?.id ?? -1
        ..obliquity_model_id = config.obliquityModel.id
        ..frame_route_id = config.frameRoute.id;
      _checkStatus(_bindings.taiyin_context_set_astro_models(_context, native));
    });
  }

  /// Sets apparent-position correction and output options.
  void setApparentConfig(TaiyinApparentConfig config) {
    _ensureOpen();
    _validateApparentConfig(config);
    using((arena) {
      final native = arena<taiyin_apparent_config>();
      _bindings.taiyin_apparent_config_init(native);
      native.ref
        ..flags = config.flags.fold(0, (value, flag) => value | flag.mask)
        ..output_frame_id = config.outputFrame.id
        ..light_time_method_id = config.lightTimeMethod.id
        ..shapiro_delay_model_id = config.shapiroDelayModel.id
        ..aberration_model_id = config.aberrationModel.id
        ..deflection_model_id = config.deflectionModel.id
        ..max_light_time_iterations = config.maxLightTimeIterations
        ..light_time_tolerance_days = config.lightTimeToleranceDays
        ..matrix_derivative_step_days = config.matrixDerivativeStepDays;
      _checkStatus(
        _bindings.taiyin_context_set_apparent_config(_context, native),
      );
    });
  }

  /// Sets celestial-pole offsets and their daily rates, in radians.
  void setCelestialPoleOffset({
    required double dxRadians,
    required double dyRadians,
    double dxRateRadiansPerDay = 0,
    double dyRateRadiansPerDay = 0,
  }) {
    _ensureOpen();
    _requireFinite(dxRadians, 'dxRadians');
    _requireFinite(dyRadians, 'dyRadians');
    _requireFinite(dxRateRadiansPerDay, 'dxRateRadiansPerDay');
    _requireFinite(dyRateRadiansPerDay, 'dyRateRadiansPerDay');
    _checkStatus(
      _bindings.taiyin_context_set_celestial_pole_offset(
        _context,
        dxRadians,
        dyRadians,
        dxRateRadiansPerDay,
        dyRateRadiansPerDay,
      ),
    );
  }

  void setRefractionModel(TaiyinRefractionModel model) {
    _ensureOpen();
    _checkStatus(
      _bindings.taiyin_context_set_refraction_model(_context, model.id),
    );
  }

  void setHeliacalVisibilityModel(TaiyinHeliacalVisibilityModel model) {
    _ensureOpen();
    _checkStatus(
      _bindings.taiyin_context_set_heliacal_visibility_model(
        _context,
        model.id,
      ),
    );
  }

  /// Replaces all custom deflectors with Taiyin's standard solar deflector.
  void useSolarDeflector() {
    _ensureOpen();
    _checkStatus(_bindings.taiyin_context_use_solar_deflector(_context));
  }

  /// Removes all gravitational deflectors.
  void clearDeflectors() {
    _ensureOpen();
    _checkStatus(_bindings.taiyin_context_clear_deflectors(_context));
  }

  /// Replaces the context's gravitational deflector list.
  void setDeflectors(
    List<TaiyinApparentDeflector> deflectors, {
    int solarDeflectorIndex = -1,
  }) {
    _ensureOpen();
    if (solarDeflectorIndex < -1 || solarDeflectorIndex >= deflectors.length) {
      throw RangeError.range(
        solarDeflectorIndex,
        -1,
        deflectors.length - 1,
        'solarDeflectorIndex',
      );
    }
    for (final deflector in deflectors) {
      _validateDeflector(deflector);
    }
    using((arena) {
      Pointer<taiyin_apparent_deflector> native = nullptr;
      if (deflectors.isNotEmpty) {
        native = arena<taiyin_apparent_deflector>(deflectors.length);
      }
      for (var index = 0; index < deflectors.length; index++) {
        final pointer = native + index;
        final deflector = deflectors[index];
        _bindings.taiyin_apparent_deflector_init(pointer);
        pointer.ref
          ..body_id = deflector.bodyId
          ..schwarzschild_radius_au = deflector.schwarzschildRadiusAu
          ..limit = deflector.limit;
      }
      _checkStatus(
        _bindings.taiyin_context_set_deflectors(
          _context,
          native,
          deflectors.length,
          solarDeflectorIndex,
        ),
      );
    });
  }

  /// Sets the iterative light-time solver limits.
  void setLightTimeIteration({
    required int maxIterations,
    required double toleranceDays,
  }) {
    _ensureOpen();
    if (maxIterations < 0 || maxIterations > 0x7fffffff) {
      throw RangeError.range(maxIterations, 0, 0x7fffffff, 'maxIterations');
    }
    _requireFinite(toleranceDays, 'toleranceDays');
    if (toleranceDays < 0) {
      throw RangeError.range(toleranceDays, 0, null, 'toleranceDays');
    }
    _checkStatus(
      _bindings.taiyin_context_set_light_time_iteration(
        _context,
        maxIterations,
        toleranceDays,
      ),
    );
  }

  /// Enables Shapiro delay and its required light-time correction.
  void enableShapiroDelay({
    TaiyinShapiroDelayModel model = TaiyinShapiroDelayModel.standard,
  }) {
    _ensureOpen();
    _checkStatus(
      _bindings.taiyin_context_enable_shapiro_delay(_context, model.id),
    );
  }

  void disableShapiroDelay() {
    _ensureOpen();
    _checkStatus(_bindings.taiyin_context_disable_shapiro_delay(_context));
  }

  /// Selects the Earth-shadow and lunar-radius eclipse models.
  void setEclipseModels({
    required TaiyinEclipseShadowModel shadow,
    required TaiyinEclipseMoonRadiusModel moonRadius,
  }) {
    _ensureOpen();
    _checkStatus(
      _bindings.taiyin_context_set_eclipse_models(
        _context,
        shadow.id,
        moonRadius.id,
      ),
    );
  }

  Pointer<taiyin_observer_location> _writeLocation(
    Arena arena,
    TaiyinObserverLocation location,
  ) {
    final native = arena<taiyin_observer_location>();
    _bindings.taiyin_observer_location_init(native);
    native.ref
      ..longitude_deg = location.longitudeDegrees
      ..latitude_deg = location.latitudeDegrees
      ..height_m = location.heightMeters;
    return native;
  }

  void _validateLocation(TaiyinObserverLocation value) {
    _requireFinite(value.longitudeDegrees, 'longitudeDegrees');
    _requireFinite(value.latitudeDegrees, 'latitudeDegrees');
    _requireFinite(value.heightMeters, 'heightMeters');
    if (value.latitudeDegrees < -90 || value.latitudeDegrees > 90) {
      throw RangeError.range(value.latitudeDegrees, -90, 90, 'latitudeDegrees');
    }
  }

  void _validateAtmosphere(TaiyinAtmosphere value) {
    _requireFinite(value.pressureMillibars, 'pressureMillibars');
    _requireFinite(value.temperatureCelsius, 'temperatureCelsius');
    _requireFinite(value.relativeHumidityPercent, 'relativeHumidityPercent');
    _requireFinite(value.wavelengthMicrometers, 'wavelengthMicrometers');
  }

  void _validateApparentConfig(TaiyinApparentConfig value) {
    if (value.outputFrame == TaiyinApparentFrame.unknown) {
      throw ArgumentError.value(value.outputFrame, 'outputFrame');
    }
    if (value.maxLightTimeIterations < 0 ||
        value.maxLightTimeIterations > 0x7fffffff) {
      throw RangeError.range(
        value.maxLightTimeIterations,
        0,
        0x7fffffff,
        'maxLightTimeIterations',
      );
    }
    _requireFinite(value.lightTimeToleranceDays, 'lightTimeToleranceDays');
    if (value.lightTimeToleranceDays < 0) {
      throw RangeError.range(
        value.lightTimeToleranceDays,
        0,
        null,
        'lightTimeToleranceDays',
      );
    }
    _requireFinite(value.matrixDerivativeStepDays, 'matrixDerivativeStepDays');
    if (value.matrixDerivativeStepDays <= 0) {
      throw RangeError.value(
        value.matrixDerivativeStepDays,
        'matrixDerivativeStepDays',
        'must be positive',
      );
    }
    if (value.flags.contains(TaiyinApparentFlag.shapiroDelay) &&
        !value.flags.contains(TaiyinApparentFlag.lightTime)) {
      throw ArgumentError(
        'Shapiro delay requires the light-time correction flag.',
      );
    }
  }

  void _validateDeflector(TaiyinApparentDeflector value) {
    _requireInt32(value.bodyId, 'bodyId');
    _requireFinite(value.schwarzschildRadiusAu, 'schwarzschildRadiusAu');
    _requireFinite(value.limit, 'limit');
    if (value.schwarzschildRadiusAu < 0) {
      throw RangeError.range(
        value.schwarzschildRadiusAu,
        0,
        null,
        'schwarzschildRadiusAu',
      );
    }
    if (value.limit < 0) {
      throw RangeError.range(value.limit, 0, null, 'limit');
    }
  }

  void _validateState(TaiyinCartesianState value) {
    for (final coordinate in [
      ...value.positionAu.values,
      ...value.velocityAuPerDay.values,
      ...value.accelerationAuPerDay2.values,
    ]) {
      _requireFinite(coordinate, 'offset coordinate');
    }
  }

  void _writeVector(taiyin_vector3 native, TaiyinVector3 value) {
    native
      ..x = value.x
      ..y = value.y
      ..z = value.z;
  }

  void _requireFinite(double value, String name) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }

  void _requireInt32(int value, String name) {
    if (value < -0x80000000 || value > 0x7fffffff) {
      throw RangeError.range(value, -0x80000000, 0x7fffffff, name);
    }
  }
}
