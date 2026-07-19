# Context API implementation checklist

## Goal

Expose the complete stable `taiyin/c/context.h` surface as an idiomatic,
context-owned Dart service available through `taiyin.context`.

The API must preserve native validation and status reporting, initialize every
versioned C structure before use, reject invalid Dart values before crossing
FFI where practical, and keep context mutation explicitly separate from
concurrent calculation.

## Public Dart design

- [ ] Add `TaiyinContextApi` and expose it as `Taiyin.context`.
- [ ] Keep the existing `Taiyin.time` policy/model methods source-compatible.
- [ ] Add immutable Dart value types:
  - [ ] `TaiyinObserverLocation`
  - [ ] `TaiyinAtmosphere`
  - [ ] `TaiyinAstroModelConfig`
  - [ ] `TaiyinApparentConfig`
  - [ ] `TaiyinApparentDeflector`
- [ ] Add typed enums and flags for:
  - [ ] atmosphere policy
  - [ ] precession, nutation, TDB, and frame-route models
  - [ ] refraction and heliacal-visibility models
  - [ ] apparent corrections and output frames
  - [ ] aberration, deflection, and eclipse models
- [ ] Reuse the existing time-model enums where they describe the same native
      identifiers.
- [ ] Document that context configuration must finish before the context is
      used concurrently.

## FFI coverage

- [ ] Include every `context.h` structure and enum required by the public
      models in `ffigen.yaml`.
- [ ] Generate bindings for the 30 context functions not yet covered by the
      high-level wrapper.
- [ ] Regenerate `lib/src/bindings/taiyin_bindings.g.dart`; never hand-edit it.

### Structure initialization and reset

- [ ] `taiyin_observer_location_init`
- [ ] `taiyin_atmosphere_init`
- [ ] `taiyin_astro_model_config_init`
- [ ] `taiyin_apparent_config_init`
- [ ] `taiyin_apparent_deflector_init`
- [ ] `taiyin_context_reset`

### Observer and atmosphere

- [ ] `taiyin_context_set_observer_location`
- [ ] `taiyin_context_clear_observer_location`
- [ ] `taiyin_context_set_atmosphere`
- [ ] `taiyin_context_set_atmosphere_pressure_temperature`
- [ ] `taiyin_context_set_standard_atmosphere`
- [ ] `taiyin_context_set_atmosphere_policy`
- [ ] `taiyin_context_set_meteorological_range_km`
- [ ] `taiyin_context_set_geocentric_observer`
- [ ] `taiyin_context_set_topocentric_observer_offset`
- [ ] `taiyin_context_set_simple_topocentric_observer`
- [ ] `taiyin_context_set_precise_topocentric_observer`

### Calculation models and routes

- [ ] `taiyin_context_set_route_rule`
- [ ] `taiyin_context_set_astro_models`
- [ ] `taiyin_context_set_apparent_config`
- [ ] `taiyin_context_set_celestial_pole_offset`
- [ ] `taiyin_context_set_refraction_model`
- [ ] `taiyin_context_set_heliacal_visibility_model`
- [ ] `taiyin_context_set_eclipse_models`

The already wrapped `taiyin_context_set_time_scale_policy`,
`taiyin_context_set_delta_t_model`, and `taiyin_context_set_tdb_model` remain
owned by `Taiyin.time` for source compatibility.

### Deflection, light time, and Shapiro delay

- [ ] `taiyin_context_use_solar_deflector`
- [ ] `taiyin_context_clear_deflectors`
- [ ] `taiyin_context_set_deflectors`
- [ ] `taiyin_context_set_light_time_iteration`
- [ ] `taiyin_context_enable_shapiro_delay`
- [ ] `taiyin_context_disable_shapiro_delay`

## Validation and failure behavior

- [ ] Validate finite numeric inputs in Dart.
- [ ] Validate geographic latitude, longitude, humidity, pressure, wavelength,
      iteration count, tolerance, and deflector-index invariants.
- [ ] Call the open-state guard exactly once from every public operation.
- [ ] Translate every non-success native status into `TaiyinException`.
- [ ] Ensure temporary native allocations cannot escape their arena.
- [ ] Preserve clone independence and reset semantics.

## Tests to port

- [ ] Port context defaults, mutation, clone, and reset coverage from
      `tests/test_c_api.c`.
- [ ] Port public apparent-configuration behavior from
      `tests/test_native_apparent_runtime.cpp`.
- [ ] Reuse applicable observer and failure cases from
      `tests/test_apparent_position.cpp`.
- [ ] Test every model/flag mapping.
- [ ] Test invalid Dart inputs without entering native code where observable.
- [ ] Test use-after-close behavior for every public method family.
- [ ] Run `dart format --output=none --set-exit-if-changed lib test`.
- [ ] Run `dart analyze`.
- [ ] Run the complete `dart test` suite.

## Documentation

- [ ] Export the context API and models from `lib/taiyin.dart`.
- [ ] Add observer, atmosphere, and apparent-configuration examples to
      `README.md`.
- [ ] Update `test/ported/README.md` with the newly covered native suites.
- [ ] Update this checklist as items land.

## Out of scope

- Runtime-global EOP, catalog, lunar-limb, and cache mutation belong to a
  separate runtime API PR.
- Star, astrology, visibility, event, eclipse, and occultation calculations
  remain separate module PRs.
- Process-lifetime custom Dart-to-C callbacks remain deferred until the
  ordinary value-based APIs are complete.
