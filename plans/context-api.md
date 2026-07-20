# Context API implementation checklist

## Goal

Expose the complete stable `taiyin/c/context.h` surface as an idiomatic,
user-owned `TaiyinContext` and its `configuration` service.

The API must preserve native validation and status reporting, initialize every
versioned C structure before use, reject invalid Dart values before crossing
FFI where practical, and keep context mutation explicitly separate from
concurrent calculation.

## Public Dart design

- [x] Add `TaiyinContextConfiguration` and expose it as
  `TaiyinContext.configuration`.
- [x] Keep time policy/model methods on the owning `TaiyinContext`.
- [x] Add immutable Dart value types:
  - [x] `TaiyinObserverLocation`
  - [x] `TaiyinAtmosphere`
  - [x] `TaiyinAstroModelConfig`
  - [x] `TaiyinApparentConfig`
  - [x] `TaiyinApparentDeflector`
- [x] Add typed enums and flags for:
  - [x] atmosphere policy
  - [x] precession, nutation, TDB, and frame-route models
  - [x] ephemeris route rules
  - [x] refraction and heliacal-visibility models
  - [x] apparent corrections and output frames
  - [x] aberration, deflection, and eclipse models
- [x] Reuse the existing time-model enums where they describe the same native
      identifiers.
- [x] Document that context configuration must finish before the context is
      used concurrently.

## FFI coverage

- [x] Include every `context.h` structure and enum required by the public
      models in `ffigen.yaml`.
- [x] Generate bindings for the 30 context functions not yet covered by the
      high-level wrapper.
- [x] Regenerate `lib/src/bindings/taiyin_bindings.g.dart`; never hand-edit it.

### Structure initialization and reset

- [x] `taiyin_observer_location_init`
- [x] `taiyin_atmosphere_init`
- [x] `taiyin_astro_model_config_init`
- [x] `taiyin_apparent_config_init`
- [x] `taiyin_apparent_deflector_init`
- [x] `taiyin_context_reset`

### Observer and atmosphere

- [x] `taiyin_context_set_observer_location`
- [x] `taiyin_context_clear_observer_location`
- [x] `taiyin_context_set_atmosphere`
- [x] `taiyin_context_set_atmosphere_pressure_temperature`
- [x] `taiyin_context_set_standard_atmosphere`
- [x] `taiyin_context_set_atmosphere_policy`
- [x] `taiyin_context_set_meteorological_range_km`
- [x] `taiyin_context_set_geocentric_observer`
- [x] `taiyin_context_set_topocentric_observer_offset`
- [x] `taiyin_context_set_simple_topocentric_observer`
- [x] `taiyin_context_set_precise_topocentric_observer`

### Calculation models and routes

- [x] `taiyin_context_set_route_rule`
- [x] `taiyin_context_set_astro_models`
- [x] `taiyin_context_set_apparent_config`
- [x] `taiyin_context_set_celestial_pole_offset`
- [x] `taiyin_context_set_refraction_model`
- [x] `taiyin_context_set_heliacal_visibility_model`
- [x] `taiyin_context_set_eclipse_models`

The already wrapped `taiyin_context_set_time_scale_policy`,
`taiyin_context_set_delta_t_model`, and `taiyin_context_set_tdb_model` remain
owned by `TaiyinContext.time`.

### Deflection, light time, and Shapiro delay

- [x] `taiyin_context_use_solar_deflector`
- [x] `taiyin_context_clear_deflectors`
- [x] `taiyin_context_set_deflectors`
- [x] `taiyin_context_set_light_time_iteration`
- [x] `taiyin_context_enable_shapiro_delay`
- [x] `taiyin_context_disable_shapiro_delay`

## Validation and failure behavior

- [x] Validate finite numeric inputs in Dart.
- [x] Validate geographic latitude, longitude, humidity, pressure, wavelength,
      iteration count, tolerance, and deflector-index invariants.
- [x] Call the open-state guard exactly once from every public operation.
- [x] Translate every non-success native status into `TaiyinException`.
- [x] Ensure temporary native allocations cannot escape their arena.
- [x] Preserve clone independence and reset semantics.

## Tests to port

- [x] Port context defaults, mutation, clone, and reset coverage from
      `tests/test_c_api.c`.
- [x] Port public apparent-configuration behavior from
      `tests/test_native_apparent_runtime.cpp`.
- [x] Reuse applicable observer and failure cases from
      `tests/test_apparent_position.cpp`.
- [x] Test every model/flag mapping.
- [x] Test invalid Dart inputs without entering native code where observable.
- [x] Test use-after-close behavior for every public method family.
- [x] Run `dart format --output=none --set-exit-if-changed lib test`.
- [x] Run `dart analyze`.
- [x] Run the complete `dart test` suite.

## Documentation

- [x] Export the context API and models from `lib/taiyin.dart`.
- [x] Add observer, atmosphere, and apparent-configuration examples to
      `README.md`.
- [x] Update `test/ported/README.md` with the newly covered native suites.
- [x] Update this checklist as items land.

## Out of scope

- Runtime-global EOP, catalog, lunar-limb, and cache mutation belong to a
  separate runtime API PR.
- Star, astrology, visibility, event, eclipse, and occultation calculations
  remain separate module PRs.
- Process-lifetime custom ayanamsha and house-system callbacks remain deferred
  to the astrology API. Custom position evaluators are covered by the
  process-wide custom-target API.
