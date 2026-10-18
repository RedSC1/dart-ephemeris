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
- [Experimental Web backend](web-backend.md): unified async initialization,
  OPM2 `Uint8List` sources, deployment, tests, and the initial support matrix.

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

## Compatibility policy

All three packages are stable at 1.0.0. Compatible 1.x releases preserve
public call signatures, documented result records and exception types, and
context/isolate ownership rules. Native computations retain the documented
`OperationResult<T>` record with `value` and `flags`; fatal statuses throw
typed exceptions. `lastDiagnostic` remains a debugging snapshot.

Numerical fixes and model/data updates can change calculated values. Pin
packages, data, route policy, and model IDs for reproducible work. Internal
FFI bindings and implementation files are not public APIs. External native
modules must be built together against the matching core; this release uses
Taiyin `v1.0.0`, C ABI 11.

The supported bundled platforms remain macOS arm64, Linux x64, and Windows
x64. The published 1.0.0 package is native-only; this development branch adds a
partial experimental Web backend described above. See the data, time, and accuracy
guides for the declared calendar, observer, and model limits.
