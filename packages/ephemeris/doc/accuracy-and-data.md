# Accuracy and ephemeris data

This document separates ephemeris-data reconstruction accuracy from the
accuracy of complete public calculations. Unless stated otherwise, values here
describe the native Taiyin core used by the Dart binding.

## OPM2 reconstruction

Taiyin can evaluate major-body ephemerides stored in the OPM2 compressed
format. For a typical product generated from NASA/JPL DE441 or DE442, the
position reconstruction difference from the source ephemeris is on the order
of **0.001 arcsec**.

That figure measures compression and reconstruction of source states. It is
not a claim that every final result is accurate to 0.001 arcsec. Apparent and
topocentric positions additionally depend on light time, aberration,
gravitational deflection, precession/nutation, Earth-orientation data, observer
configuration, and the selected reference frame. Event times and eclipse
contacts add root-solving, body-radius, shadow, lunar-limb, and refraction
conventions.

## Data available to Dart applications

The current `ephemeris` package bundles the Taiyin native runtime for supported
desktop platforms. It does **not** bundle a full DE planetary archive. With no
external precision source, the AUTO router can use Taiyin's built-in
semi-analytical fallback over its declared interval.

Applications can add individual files or recursively discovered directories:

```dart
import 'package:ephemeris/ephemeris.dart';

final runtime = Ephemeris.open();
runtime
  ..addSourcePath('/data/ephemerides')
  ..addSourcePath('/data/de440.bsp');

print(runtime.catalogSize);
for (final source in runtime.registeredDataSources) {
  print(source);
}
```

Supported source families include:

| Source | Intended role |
|---|---|
| OPM2 | Compact precision ephemeris generated from a declared source product |
| NASA/JPL BSP/SPK | Original planetary, satellite, or small-body kernel |
| TKC1/Kepler | Compact approximate small-body fallback |
| Built-in semi-analytical route | Data-free fallback when no higher-priority source covers the request |

The runtime catalog and AUTO router preserve provider, source, target, center,
frame, and coverage metadata. Loading multiple kernels is supported. When
reproducibility matters, inspect the registered sources and the operation's
diagnostic instead of assuming which file won route selection.

## Full DE440 compressed data

**Coming soon:** a separately downloadable, full DE440-derived OPM2 compressed
data product. It is not included in the current Dart prerelease. Until it is
published, applications that need DE440 should load an original NASA/JPL
DE440 BSP/SPK kernel or supply their own compatible OPM2 data.

## Practical interpretation

- Use OPM2 or a matching BSP/SPK kernel for precision positions, close
  approaches, occultations, and eclipse work.
- Treat the built-in semi-analytical route as a broad-coverage fallback rather
  than a substitute for an in-range precision product.
- Do not extrapolate a file-backed product outside its declared coverage.
- Compact satellite and Kepler fallbacks are useful for availability, not
  precision satellite astrometry.
- `ResultFlag.fallbackOccurred` reports that a lower-priority route completed a
  call; `EphemerisContext.lastDiagnostic` can explain the selected method and
  source for debugging. In concurrent code, trust the result record or thrown
  exception rather than mutable last-call state.

The C++ repository contains the detailed validation reports for individual
subsystems, including event and eclipse comparisons. External published tables
often use different time scales, refraction models, limb conventions, or
rounding, so disagreement with one table is not automatically an ephemeris
compression error.
