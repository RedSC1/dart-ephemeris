# Solar-time and phenomena API implementation checklist

Scope: all five functions in `taiyin/c/solar_time.h`, all three functions in
`taiyin/c/phenomena.h`, and the actionable diagnostics follow-up from PR #6.
The two small native modules share one PR so each public feature lands with
complete bindings, models, tests, and documentation.

## Bindings and compatibility

- [x] Include `solar_time.h` and `phenomena.h` in the ffigen wrapper.
- [x] Generate both result structs and all eight C ABI functions.
- [x] Probe all eight symbols during native compatibility validation.

## Solar-time API

- [x] Expose `TaiyinContext.solarTime`.
- [x] Calculate the equation of time from typed UT1 and TT coordinates.
- [x] Preserve resolved UT1/TT, equation days/seconds, apparent solar right
  ascension, GAST, and the native diagnostic.
- [x] Add distinct local-mean and local-apparent `JulianDate` scale markers.
- [x] Convert in both directions with east-positive longitude validation.

## Phenomena API

- [x] Expose `TaiyinContext.phenomena`.
- [x] Calculate at typed UT1 and TT coordinates.
- [x] Reuse position-route flags and the common body enumeration.
- [x] Preserve phase, illumination, elongation, apparent diameter, apparent
  magnitude, lunar horizontal parallax, and the native diagnostic.
- [x] Reject barycentres and Earth before entering the physical-disc API.

## Review follow-up, tests, and documentation

- [x] Preserve every observed batch diagnostic in input order while retaining
  the first failure as the primary exception diagnostic.
- [x] Port equation-of-time, UT/TT parity, LMT/LAT round-trip, and invalid
  longitude behavior from `test_solar_time.cpp`.
- [x] Port the first-quarter Moon SwissEph oracle and strict upstream
  tolerances from `test_phenomena.cpp`.
- [x] Cover TT phenomena, nullable non-lunar parallax, invalid bodies, native
  diagnostics, and use after close.
- [x] Export the models and document both context services.
- [x] Update the upstream black-box coverage map.
