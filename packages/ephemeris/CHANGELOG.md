## 1.0.0-beta.3

- Separate the fixed civil-clock UTC offset from a mean-solar meridian used
  to assign new moons and solar terms to calendar days.
- Make local/instant convenience conversions independent of EOP when a local
  astronomical calendar uses a meridian day boundary.

## 1.0.0-beta.2

- Update the bundled native baseline to Taiyin 1.0.0-beta.4 and C ABI 10.
- Add the historical-China, standard-China, and locally reconstructed
  astronomical Chinese-calendar modes.
- Canonicalize exact integer-hour chart clocks only at Chinese-metaphysics
  boundaries while leaving general astronomy time conversions unchanged.

## 1.0.0-beta.1

- Promote the package line to beta after stabilizing the split native-module,
  isolate-concurrency, result-flag, and time-conversion APIs.
- Update the bundled native baseline to Taiyin 1.0.0-beta.3, including the
  smoothed early Delta-T transition.
- Document the separately downloadable full-range DE441 OPM2 data release.

## 1.0.0-alpha.2

- Add `DateTime.toUtcJulianDate()` and
  `utcJulianDateFromUnixMicroseconds()` as central epoch-based adapters.
- Add readable Julian-date aliases and local-calendar time conversion helpers.
- Report missing/out-of-range EOP and unavailable leap-second data with
  `EarthOrientationDataError` and `LeapSecondDataError`.
- Add automatic TAI/TT/UT1/TDB-to-UTC and UTC/TAI/TT/TDB-to-UT1 conversion
  helpers, plus UT1 and UTC calendar-formatting helpers for event results.
- Reject inserted leap seconds reached from TAI, TT, or TDB when they cannot be
  represented by `UtcJulianDate`; resolve the indistinguishable UT1 coordinate
  to the following midnight. Keep historical TT/TDB-to-UT1 fallback
  independent of UTC leap-second coverage.

## 1.0.0-alpha.1

- Require Taiyin C ABI 9 and regenerate the native FFI bindings.
- Return `OperationResult<T>` named records from native calculations, exposing
  call-scoped `ResultFlags` without relying on mutable last-call state.
- Add typed native exception subclasses while preserving result flags and
  diagnostics on failures.
- Add high-level BaZi and Ziwei result records with aggregated calendar,
  time-scale, and extension flags.
- Align worker-isolate ownership with the core architecture through
  `Ephemeris.attach().createContext()`; attaching never reinitializes the
  process-wide runtime.
- Update the pinned modular native libraries to Taiyin 1.0.0-beta.1.
- Split the pinned native distribution into core, BaZi, and Ziwei modules;
  extension packages now load their own module lazily.
- Remove BaZi/Ziwei from the core capability enum; extension availability is
  determined by loading the corresponding package-owned native module.
- Add concurrent multi-isolate BaZi and Ziwei integration tests.
- Cover positions, event search, eclipses, and Chinese-calendar conversion in
  one concurrent worker-isolate regression, and document the ownership matrix.
