# Taiyin C ABI → Dart coverage checklist

Baseline: `taiyin-ephemeris/include/taiyin/c/*.h` on 2026-07-20.

- Total callable C symbols: **317**
- Included by the current Dart binding configuration: **247**
- Remaining: **70**

`[x]` means the symbol is included in `ffigen.yaml` and its current Dart API
block has landed. `[ ]` means it still needs a Dart binding/API decision. The
list includes result initializers and process-lifetime callback registration
functions so ABI completeness can be tracked exactly.

## Suggested implementation order

- [x] Astrology core: ayanamsha, sidereal positions, houses, house positions,
  and built-in-model queries
- [x] Lunar points: true/mean nodes and mean/osculating/fitted apogees
- [x] Visibility: Sun, Moon, planet, and star rise/set/transit searches
- [x] Events: longitude, station, aspect, elongation, separation, transit, and
  lunar-phase searches
- [x] Heliacal visibility
- [ ] Lunar occultations
- [ ] Lunar eclipses
- [ ] Solar eclipse search and local circumstances
- [ ] Solar Besselian elements, routes, curves, and map products
- [ ] Remaining process-lifetime ayanamsha and house-system callbacks
- [ ] Diagnostic formatting helper

## Cross-cutting technical debt: split-JD calculation ABI

The Dart `JulianDate` type preserves a split day number and day fraction, and
time-scale conversions already use the native split-JD C ABI. Most calculation
entry points still accept a single `double` Julian day, however. This includes
the existing position, star, observed, phenomena, and orbital APIs as well as
the remaining astrology, visibility, event, heliacal, occultation, and eclipse
APIs. Their Dart wrappers therefore call `JulianDate.toDouble()` at the FFI
boundary and cannot preserve the full split representation end to end.

Do not add input-only `_split` calculation wrappers as an incremental shortcut.
The former position/state experiment was reverted because it immediately merged
the split input to `double`: it had no numerical effect and would have implied a
precision guarantee the native core could not make. The Dart package therefore
uses an explicit scalar boundary for physical calculations today.

An eventual migration is a native-core project, not an ABI façade project. It
must define an internal split epoch, propagate it through evaluation and search
algorithms, introduce split representations for time-bearing result fields, and
only then add matching C ABI and Dart APIs. Existing ABI-1 `double` symbols
must remain available during that transition.

- [ ] Inventory every calculation entry point that accepts one or more Julian
  dates as `double`.
- [ ] Define the native-core split epoch and split result-field policy.
- [ ] Migrate one complete calculation-and-search family end to end, with
  numerical regression coverage.
- [ ] Add C ABI and Dart APIs only for end-to-end-migrated families.
- [ ] Apply the same policy to newly wrapped calculation families.

## `astrology.h` — 27/30

- [x] `taiyin_sidereal_position_init`
- [x] `taiyin_sidereal_coordinates_init`
- [x] `taiyin_house_result_init`
- [x] `taiyin_house_position_result_init`
- [x] `taiyin_lunar_node_position_init`
- [x] `taiyin_lunar_apsis_position_init`
- [x] `taiyin_calc_ayanamsha_tt`
- [x] `taiyin_calc_sidereal_position_tt`
- [x] `taiyin_calc_sidereal_position_ut`
- [x] `taiyin_calc_sidereal_coordinates_tt`
- [x] `taiyin_calc_sidereal_coordinates_ut`
- [x] `taiyin_calc_houses_from_armc`
- [x] `taiyin_calc_houses_ut`
- [x] `taiyin_calc_houses_tt`
- [x] `taiyin_calc_house_position_from_longitude`
- [x] `taiyin_has_house_system_model`
- [x] `taiyin_has_ayanamsha_model`
- [ ] `taiyin_register_ayanamsha_model`
- [ ] `taiyin_register_house_system_model`
- [x] `taiyin_calc_lunar_true_node_tt`
- [x] `taiyin_calc_lunar_true_node_ut`
- [x] `taiyin_calc_lunar_mean_node_tt`
- [x] `taiyin_calc_lunar_mean_node_ut`
- [x] `taiyin_calc_lunar_mean_apogee_tt`
- [x] `taiyin_calc_lunar_mean_apogee_ut`
- [x] `taiyin_calc_lunar_osculating_apogee_tt`
- [x] `taiyin_calc_lunar_osculating_apogee_ut`
- [x] `taiyin_calc_lunar_fitted_apogee_tt`
- [x] `taiyin_calc_lunar_fitted_apogee_ut`
- [ ] `taiyin_register_builtin_astrology_targets`

## `base.h` — 10/11

- [x] `taiyin_cartesian_state_init`
- [x] `taiyin_calendar_datetime_init`
- [x] `taiyin_ephemeris_diagnostic_init`
- [x] `taiyin_get_c_abi_version`
- [x] `taiyin_get_library_version`
- [x] `taiyin_get_library_codename`
- [x] `taiyin_get_capabilities`
- [ ] `taiyin_format_ephemeris_diagnostic`
- [x] `taiyin_status_name`
- [x] `taiyin_status_message`
- [x] `taiyin_status_category`

## `context.h` — 36/36

- [x] `taiyin_observer_location_init`
- [x] `taiyin_atmosphere_init`
- [x] `taiyin_astro_model_config_init`
- [x] `taiyin_apparent_config_init`
- [x] `taiyin_apparent_deflector_init`
- [x] `taiyin_context_create`
- [x] `taiyin_context_clone`
- [x] `taiyin_context_destroy`
- [x] `taiyin_context_reset`
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
- [x] `taiyin_context_set_route_rule`
- [x] `taiyin_context_set_time_scale_policy`
- [x] `taiyin_context_set_delta_t_model`
- [x] `taiyin_context_set_tdb_model`
- [x] `taiyin_context_set_astro_models`
- [x] `taiyin_context_set_apparent_config`
- [x] `taiyin_context_set_celestial_pole_offset`
- [x] `taiyin_context_set_refraction_model`
- [x] `taiyin_context_set_heliacal_visibility_model`
- [x] `taiyin_context_use_solar_deflector`
- [x] `taiyin_context_clear_deflectors`
- [x] `taiyin_context_set_deflectors`
- [x] `taiyin_context_set_light_time_iteration`
- [x] `taiyin_context_enable_shapiro_delay`
- [x] `taiyin_context_disable_shapiro_delay`
- [x] `taiyin_context_set_eclipse_models`

## `eclipse.h` — 0/52

- [ ] `taiyin_lunar_eclipse_result_tt_init`
- [ ] `taiyin_lunar_eclipse_result_ut_init`
- [ ] `taiyin_local_lunar_eclipse_result_tt_init`
- [ ] `taiyin_local_lunar_eclipse_result_ut_init`
- [ ] `taiyin_solar_eclipse_result_tt_init`
- [ ] `taiyin_solar_eclipse_result_ut_init`
- [ ] `taiyin_local_solar_eclipse_result_tt_init`
- [ ] `taiyin_local_solar_eclipse_result_ut_init`
- [ ] `taiyin_local_solar_eclipse_circumstances_tt_init`
- [ ] `taiyin_local_solar_eclipse_circumstances_ut_init`
- [ ] `taiyin_local_solar_eclipse_boundary_init`
- [ ] `taiyin_solar_eclipse_route_row_init`
- [ ] `taiyin_solar_eclipse_route_product_summary_init`
- [ ] `taiyin_solar_besselian_elements_init`
- [ ] `taiyin_solar_besselian_polynomial_init`
- [ ] `taiyin_solve_lunar_eclipse_at_tt`
- [ ] `taiyin_solve_lunar_eclipse_at_ut`
- [ ] `taiyin_search_next_lunar_eclipse_tt`
- [ ] `taiyin_search_next_lunar_eclipse_ut`
- [ ] `taiyin_search_lunar_eclipses_tt`
- [ ] `taiyin_search_lunar_eclipses_ut`
- [ ] `taiyin_compute_local_lunar_eclipse_visibility_tt`
- [ ] `taiyin_compute_local_lunar_eclipse_visibility_ut`
- [ ] `taiyin_search_next_local_lunar_eclipse_tt`
- [ ] `taiyin_search_next_local_lunar_eclipse_ut`
- [ ] `taiyin_solve_solar_eclipse_at_tt`
- [ ] `taiyin_solve_solar_eclipse_at_ut`
- [ ] `taiyin_search_next_solar_eclipse_tt`
- [ ] `taiyin_search_next_solar_eclipse_ut`
- [ ] `taiyin_search_solar_eclipses_tt`
- [ ] `taiyin_search_solar_eclipses_ut`
- [ ] `taiyin_solve_local_solar_eclipse_at_tt`
- [ ] `taiyin_solve_local_solar_eclipse_at_ut`
- [ ] `taiyin_search_next_local_solar_eclipse_tt`
- [ ] `taiyin_search_next_local_solar_eclipse_ut`
- [ ] `taiyin_compute_local_solar_circumstances_tt`
- [ ] `taiyin_compute_local_solar_circumstances_ut`
- [ ] `taiyin_compute_solar_besselian_elements_tt`
- [ ] `taiyin_compute_solar_besselian_polynomial_tt`
- [ ] `taiyin_evaluate_solar_besselian_polynomial`
- [ ] `taiyin_compute_solar_eclipse_route_row_tt`
- [ ] `taiyin_compute_solar_eclipse_route_row_ut`
- [ ] `taiyin_compute_solar_eclipse_route_tt`
- [ ] `taiyin_compute_solar_eclipse_route_ut`
- [ ] `taiyin_compute_solar_eclipse_route_curves_tt`
- [ ] `taiyin_compute_solar_eclipse_route_curves_ut`
- [ ] `taiyin_compute_solar_eclipse_route_product_tt`
- [ ] `taiyin_compute_solar_eclipse_route_product_ut`
- [ ] `taiyin_compute_solar_eclipse_route_map_product_tt`
- [ ] `taiyin_compute_solar_eclipse_route_map_product_ut`
- [ ] `taiyin_compute_local_solar_eclipse_boundary_tt`
- [ ] `taiyin_compute_local_solar_eclipse_boundary_ut`

## `events.h` — 26/26

- [x] `taiyin_greatest_elongation_result_init`
- [x] `taiyin_angular_separation_result_init`
- [x] `taiyin_solar_transit_result_init`
- [x] `taiyin_local_solar_transit_result_init`
- [x] `taiyin_recommended_longitude_search_step_days`
- [x] `taiyin_recommended_aspect_search_step_days`
- [x] `taiyin_search_solar_longitude_ut`
- [x] `taiyin_search_solar_longitude_tt`
- [x] `taiyin_search_moon_longitude_ut`
- [x] `taiyin_search_moon_longitude_tt`
- [x] `taiyin_search_body_longitude_crossings_ut`
- [x] `taiyin_search_body_longitude_crossings_tt`
- [x] `taiyin_search_body_longitude_stations_ut`
- [x] `taiyin_search_body_longitude_stations_tt`
- [x] `taiyin_search_body_aspect_crossings_ut`
- [x] `taiyin_search_body_aspect_crossings_tt`
- [x] `taiyin_search_body_exact_aspects_ut`
- [x] `taiyin_search_body_exact_aspects_tt`
- [x] `taiyin_search_greatest_elongation_ut`
- [x] `taiyin_search_minimum_angular_separation_ut`
- [x] `taiyin_search_minimum_angular_separation_tt`
- [x] `taiyin_search_next_solar_transit_ut`
- [x] `taiyin_compute_local_solar_transit_ut`
- [x] `taiyin_search_next_local_solar_transit_ut`
- [x] `taiyin_search_lunar_phase_crossings_ut`
- [x] `taiyin_search_lunar_phase_crossings_tt`

## `heliacal.h` — 7/7

- [x] `taiyin_heliacal_visibility_conditions_init`
- [x] `taiyin_heliacal_visibility_result_init`
- [x] `taiyin_heliacal_visibility_search_result_init`
- [x] `taiyin_calc_body_heliacal_visibility_ut`
- [x] `taiyin_calc_star_heliacal_visibility_ut`
- [x] `taiyin_search_next_body_heliacal_visibility_ut`
- [x] `taiyin_search_next_star_heliacal_visibility_ut`

## `observed.h` — 3/3

- [x] `taiyin_observed_position_init`
- [x] `taiyin_calc_observed_bodies_ut`
- [x] `taiyin_calc_observed_bodies_utc`

## `occultation.h` — 0/14

- [ ] `taiyin_lunar_occultation_result_init`
- [ ] `taiyin_lunar_occultation_local_visibility_init`
- [ ] `taiyin_lunar_occultation_where_result_init`
- [ ] `taiyin_search_next_geocentric_lunar_star_occultation_ut`
- [ ] `taiyin_search_next_local_lunar_star_occultation_ut`
- [ ] `taiyin_search_next_geocentric_lunar_body_occultation_ut`
- [ ] `taiyin_search_next_geocentric_lunar_body_occultation_with_radius_ut`
- [ ] `taiyin_search_next_local_lunar_body_occultation_ut`
- [ ] `taiyin_search_next_local_lunar_body_occultation_with_radius_ut`
- [ ] `taiyin_compute_lunar_star_occultation_local_visibility_ut`
- [ ] `taiyin_compute_lunar_body_occultation_local_visibility_ut`
- [ ] `taiyin_compute_lunar_star_occultation_where_ut`
- [ ] `taiyin_compute_lunar_body_occultation_where_ut`
- [ ] `taiyin_compute_lunar_body_occultation_where_with_radius_ut`

## `orbital.h` — 12/12

- [x] `taiyin_body_osculating_orbit_init`
- [x] `taiyin_body_orbit_reference_points_init`
- [x] `taiyin_body_apsis_search_result_init`
- [x] `taiyin_body_node_search_result_init`
- [x] `taiyin_calc_body_osculating_orbit_tt`
- [x] `taiyin_calc_body_osculating_orbit_ut`
- [x] `taiyin_calc_body_orbit_reference_points_tt`
- [x] `taiyin_calc_body_orbit_reference_points_ut`
- [x] `taiyin_search_next_body_apsis_tt`
- [x] `taiyin_search_next_body_apsis_ut`
- [x] `taiyin_search_next_body_plane_node_tt`
- [x] `taiyin_search_next_body_plane_node_ut`

## `phenomena.h` — 3/3

- [x] `taiyin_body_phenomena_init`
- [x] `taiyin_calc_body_phenomena_tt`
- [x] `taiyin_calc_body_phenomena_ut`

## `position.h` — 18/18

- [x] `taiyin_register_native_position_evaluator`
- [x] `taiyin_unregister_native_position_evaluator`
- [x] `taiyin_clear_native_position_evaluators`
- [x] `taiyin_calc_position_tdb`
- [x] `taiyin_calc_position_tt`
- [x] `taiyin_calc_position_ut`
- [x] `taiyin_calc_position_ut_delta_t`
- [x] `taiyin_calc_position_utc`
- [x] `taiyin_calc_positions_ut`
- [x] `taiyin_calc_positions_tdb`
- [x] `taiyin_calc_positions_tt`
- [x] `taiyin_calc_positions_ut_delta_t`
- [x] `taiyin_calc_positions_utc`
- [x] `taiyin_calc_state_tdb`
- [x] `taiyin_calc_state_tt`
- [x] `taiyin_calc_state_ut`
- [x] `taiyin_calc_state_ut_delta_t`
- [x] `taiyin_calc_state_utc`

## `runtime.h` — 13/13

- [x] `taiyin_runtime_config_init`
- [x] `taiyin_runtime_initialize`
- [x] `taiyin_runtime_add_source_path`
- [x] `taiyin_runtime_load_eop_table`
- [x] `taiyin_runtime_load_builtin_eop_table`
- [x] `taiyin_runtime_clear_eop_table`
- [x] `taiyin_runtime_has_eop_table`
- [x] `taiyin_runtime_load_lunar_limb_model`
- [x] `taiyin_runtime_clear_lunar_limb_model`
- [x] `taiyin_runtime_has_lunar_limb_model`
- [x] `taiyin_runtime_clear_ephemeris_cache`
- [x] `taiyin_runtime_catalog_size`
- [x] `taiyin_runtime_cache_entry_count`

## `solar_time.h` — 10/10

- [x] `taiyin_equation_of_time_result_init`
- [x] `taiyin_split_equation_of_time_result_init`
- [x] `taiyin_calc_equation_of_time_ut`
- [x] `taiyin_calc_equation_of_time_tt`
- [x] `taiyin_calc_equation_of_time_ut_split`
- [x] `taiyin_calc_equation_of_time_tt_split`
- [x] `taiyin_local_mean_to_apparent_solar_time`
- [x] `taiyin_local_apparent_to_mean_solar_time`
- [x] `taiyin_local_mean_to_apparent_solar_time_split`
- [x] `taiyin_local_apparent_to_mean_solar_time_split`

## `star.h` — 16/16

- [x] `taiyin_star_catalog_add_tsc1`
- [x] `taiyin_star_catalog_add_tsc1_memory`
- [x] `taiyin_star_catalog_add_tsf1`
- [x] `taiyin_star_catalog_clear`
- [x] `taiyin_star_catalog_count`
- [x] `taiyin_star_find_magnitude`
- [x] `taiyin_calc_star_position_tdb`
- [x] `taiyin_calc_star_position_tt`
- [x] `taiyin_calc_star_position_ut`
- [x] `taiyin_calc_star_position_ut_delta_t`
- [x] `taiyin_calc_star_positions_tdb`
- [x] `taiyin_calc_star_positions_tt`
- [x] `taiyin_calc_star_positions_ut`
- [x] `taiyin_calc_star_positions_ut_delta_t`
- [x] `taiyin_calc_observed_star_ut`
- [x] `taiyin_calc_observed_stars_ut`

## `time.h` — 48/48

- [x] `taiyin_precise_time_scales_init`
- [x] `taiyin_split_precise_time_scales_init`
- [x] `taiyin_time_scale_diagnostic_init`
- [x] `taiyin_estimated_time_scales_init`
- [x] `taiyin_split_estimated_time_scales_init`
- [x] `taiyin_split_julian_date_from_parts`
- [x] `taiyin_split_julian_date_from_double`
- [x] `taiyin_split_julian_date_to_double`
- [x] `taiyin_julian_day`
- [x] `taiyin_julian_day_split`
- [x] `taiyin_reverse_julian_day`
- [x] `taiyin_reverse_julian_day_split`
- [x] `taiyin_decimal_year_from_jd`
- [x] `taiyin_julian_centuries_from_j2000`
- [x] `taiyin_julian_millennia_from_j2000`
- [x] `taiyin_add_seconds_to_jd`
- [x] `taiyin_seconds_between_jd`
- [x] `taiyin_add_seconds_to_split_jd`
- [x] `taiyin_seconds_between_split_jd`
- [x] `taiyin_estimated_delta_t_seconds_for_decimal_year`
- [x] `taiyin_estimated_delta_t_seconds_from_ut1`
- [x] `taiyin_estimated_delta_t_seconds_from_tt`
- [x] `taiyin_tt_to_tdb`
- [x] `taiyin_tdb_to_tt`
- [x] `taiyin_tai_minus_utc_seconds`
- [x] `taiyin_utc_to_tai`
- [x] `taiyin_tai_to_tt`
- [x] `taiyin_utc_to_tt`
- [x] `taiyin_utc_to_ut1`
- [x] `taiyin_delta_t_from_tai_minus_utc_and_dut1`
- [x] `taiyin_tt_to_ut1`
- [x] `taiyin_ut1_to_tt`
- [x] `taiyin_utc_to_tai_split`
- [x] `taiyin_tai_to_tt_split`
- [x] `taiyin_utc_to_tt_split`
- [x] `taiyin_utc_to_ut1_split`
- [x] `taiyin_tt_to_ut1_split`
- [x] `taiyin_ut1_to_tt_split`
- [x] `taiyin_tt_to_tdb_split`
- [x] `taiyin_tdb_to_tt_split`
- [x] `taiyin_make_precise_time_scales_from_utc`
- [x] `taiyin_make_split_precise_time_scales_from_utc`
- [x] `taiyin_make_time_scales_from_utc`
- [x] `taiyin_make_split_time_scales_from_utc`
- [x] `taiyin_make_time_scales_from_ut_delta_t`
- [x] `taiyin_make_split_time_scales_from_ut_delta_t`
- [x] `taiyin_make_estimated_time_scales_from_ut`
- [x] `taiyin_make_split_estimated_time_scales_from_ut`

## `visibility.h` — 18/18

- [x] `taiyin_visibility_event_result_init`
- [x] `taiyin_solar_rise_set_fast_result_init`
- [x] `taiyin_solar_transit_fast_result_init`
- [x] `taiyin_search_moon_rise_set_ut`
- [x] `taiyin_search_moon_rise_set_at_horizon_ut`
- [x] `taiyin_search_moon_transit_ut`
- [x] `taiyin_search_planet_rise_set_ut`
- [x] `taiyin_search_planet_rise_set_at_horizon_ut`
- [x] `taiyin_search_planet_transit_ut`
- [x] `taiyin_search_solar_rise_set_ut`
- [x] `taiyin_search_solar_rise_set_at_horizon_ut`
- [x] `taiyin_search_solar_twilight_ut`
- [x] `taiyin_search_solar_transit_ut`
- [x] `taiyin_compute_solar_rise_set_fast_tt`
- [x] `taiyin_compute_solar_transit_fast_tt`
- [x] `taiyin_search_star_rise_set_ut`
- [x] `taiyin_search_star_rise_set_at_horizon_ut`
- [x] `taiyin_search_star_transit_ut`
