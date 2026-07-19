# Upstream test migration

Baseline: `taiyin-ephemeris/build-c-api-release`, 74 tests reported by
`ctest -N` on 2026-07-19. The C/C++ sources contain roughly 3,230 expectation
and assertion sites.

The unit of migration is public behavior, not a C++ executable. A Dart test may
combine oracle data from several upstream suites, and tests of private cache,
file-mapping, lock, or parser implementation details do not have a one-to-one
Dart equivalent.

## Ported or in progress

- `c_api_cpp`: ABI version, exact library version, typed capabilities, and
  initialized calendar behavior are covered by `test/taiyin_test.dart`.
- `c_api` and `c_api_static`: metadata, runtime/context lifetime, calendar,
  time-scale, context configuration, and position portions are covered.
  `context_api_test.dart` exercises observer, atmosphere, astronomy/apparent
  models, topocentric modes, deflectors, clone/reset ownership, and invalid
  inputs. `position_api_test.dart` exercises single, batch, and
  Cartesian-state entry points across TDB, TT, UT1, explicit Delta-T, and UTC
  routes. `observed_api_test.dart` exercises single and batch UT1/UTC observed
  positions, nested apparent states and diagnostics, topocentric horizontal
  rates, atmospheric refraction policy, and invalid inputs. The remaining
  public modules move over as their wrappers are added.
  Static-vs-shared linkage is a native build concern and shares the same Dart
  behavior tests.
- `native_apparent_runtime` and `apparent_position`: public context
  configuration, model selection, observer-offset validation, and owned
  deflector behavior are covered. The observed-position wrapper covers UTC and
  UT1 scale routing, apparent self-deflector skipping, topocentric horizontal
  output, and strict-meteorology behavior. DE441-dependent flat apparent
  numerical oracles remain conditional on the corresponding native data.
- `time_angle_interpolation`: all time behavior reachable through the C ABI is
  covered by `time_angle_interpolation_test.dart`, including the original
  Delta-T oracle table. Angle and interpolation helpers are C++ APIs and are
  therefore outside the stable C ABI wrapper.

## Pending public black-box coverage

These suites map to current or planned C ABI modules:

- `custom_ephemeris_method`, `global_ephemeris_runtime`,
  `discovery_descriptors`, `spk_opm2_jplephem_oracles`
- `sidereal_astrology`, `houses_astrology`, `lunar_points_astrology`,
  `pure_functions_full`
- `star_file`, `tsc1_catalog_discovery`, `celestial_body_registry`,
  `body_registry`, `dispatch_models`
- `apparent_position_oracles`, `apparent_self_skip`
- `event_search`, `orbital_events`, `solar_time`, `phenomena`
- `visibility_search`, `solar_visibility_public`, `moon_visibility_public`,
  `star_visibility_public`, `heliacal_visibility`, `occultation_search`,
  `planet_visibility_spk_oracles`, `planet_visibility_public`
- `eclipse_search_smoke`, `eclipse_search_spk_oracles`,
  `sxwnl_solar_oracles`, `sxwnl_route_oracle`, `eclipse_forecast_json`,
  `event_search_swiss`, `orbital_events_swiss`, `lunar_limb_eclipse`,
  `sxwnl_lunar_oracles`

## Native implementation suites

These exercise C++ internals. They are not copied as Dart tests verbatim;
their numerical fixtures and failure cases should be reused through public
operations where applicable:

- `math_primitives`, `field_set`, `ephemeris_catalog`,
  `ephemeris_segment_cache`, `ephemeris_route_rule`
- `spk`, `kepler`, `kepler_file`, `kepler_catalog_tkc1`, `moshier`
- `corrections`, `corrections_oracles`, `geometry`, `coordinates`,
  `low_level_oracles`, `eop`
- `mapped_file`, `math_solvers`, `calc_spec`, `opm2_staged_data`,
  `opm2_spk_cob_oracles`, `opc_catalog_persistent`
- `visibility_math`, `visibility_sampling`, `solar_visibility`,
  `moon_visibility`, `planet_visibility`
- `writer_preferred_rwlock`, `route_inflight_map`, `lunar_limb_tll1`,
  `lunar_orientation`, `event_frame`
