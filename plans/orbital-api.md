# Orbital API implementation checklist

Scope: all eight calculations and searches in `taiyin/c/orbital.h`, their four
result initializers, public Dart models, upstream black-box tests, and
documentation.

## Bindings and compatibility

- [x] Include `orbital.h` in the ffigen wrapper.
- [x] Generate all five result structs, four initializers, and eight operations.
- [x] Probe all twelve callable symbols during ABI-1 compatibility validation.

## Dart API

- [x] Expose `TaiyinContext.orbits`.
- [x] Calculate osculating elements at typed TT and UT1 coordinates.
- [x] Construct osculating nodes, apsides, and the second focus at TT and UT1.
- [x] Search apsides in both directions at TT and UT1.
- [x] Search reference-plane nodes in both directions at TT and UT1.
- [x] Preserve native diagnostics, reference frames, physical centers,
  iteration counts, and evaluation counts.
- [x] Expose barycenter approximation as the only calculation flag accepted by
  the native orbital contract.
- [x] Reject unsupported bodies and the unknown reference-frame sentinel before
  entering FFI.

## Tests and documentation

- [x] Port the Moon osculating-orbit and reference-point geometry checks.
- [x] Port UT1/TT parity for calculations and searches.
- [x] Port the lunar perigee, previous apogee, and ascending-node Swiss oracles
  with the upstream `1e-4` day tolerances.
- [x] Cover every supported orbital reference frame, planet barycenters,
  reverse search, compatibility probing, and use after close.
- [x] Export the models and document the context service.
- [x] Update the upstream black-box coverage map.
