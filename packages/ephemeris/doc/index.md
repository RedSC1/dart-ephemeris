# Ephemeris documentation

The `ephemeris` package is the Dart interface to Taiyin's astronomy runtime.
It includes time-scale conversion, planetary and stellar positions, observed
coordinates, events, eclipses, orbits, Western astrology, the Chinese
calendar, and Ganzhi. BaZi and Ziwei Doushu are separately installed extension
packages.

## Start here

- [Getting started](getting-started.md): open the runtime, create a context,
  calculate a position, and handle results.
- [Astronomy workflows](astronomy-workflows.md): positions, observed
  coordinates, events, eclipses, stars, orbits, and astrology.
- [Time and calendar](time-and-calendar.md): UTC, UT1, TT/TDB, EOP data,
  `DateTime`, wall clocks, Chinese-calendar modes, and true solar time.

## Configure the runtime

- [Data and routing](data-and-routing.md): packaged fallback data, OPM2,
  BSP/SPK, source discovery, priority overrides, and route rules.
- [Customization](customization.md): custom targets, house systems,
  ayanamsha models, observer models, apparent corrections, and deflectors.
- [Contexts and isolates](contexts-and-isolates.md): process-wide setup,
  per-worker contexts, cached extension facades, explicit ownership, and
  cleanup.

## Accuracy and advanced use

- [Accuracy and data notes](accuracy-and-data.md)
- [Custom callback lifecycle](custom-target-lifecycle.md)
- [Complete package API overview](../README.md)
- Generated API reference on pub.dev from the public `///` comments

## Optional packages

- [`ephemeris_bazi` guide](../../ephemeris_bazi/doc/guide.md)
- [`ephemeris_ziwei` guide](../../ephemeris_ziwei/doc/guide.md)

All three packages are prereleases. Public API and native packaging details
may still change before stable `1.0.0`.
