# Observed API implementation checklist

Scope: `taiyin/c/observed.h`. This branch wraps the two observed-body
calculation entry points and their complete result graph. Runtime/catalog,
stars, visibility searches, and event searches remain separate API blocks.

## Bindings

- [x] Include `taiyin/c/observed.h` in the ffigen wrapper header.
- [x] Generate the observed functions and four result structures.

## Dart API

- [x] Add typed observed flags, including strict meteorology.
- [x] Add immutable horizontal coordinate and rate values.
- [x] Add immutable apparent and observed position values.
- [x] Expose single and batch UT1 calculations.
- [x] Expose single and batch UTC calculations.
- [x] Preserve nested native diagnostics and Cartesian states.
- [x] Represent unrequested horizontal and rate fields as `null`.
- [x] Reject unsupported bodies, oversized batches, and invalid flag
  dependencies before entering native code.

## Tests and documentation

- [x] Cover UT1 and UTC single and batch routes.
- [x] Cover apparent self-deflector skipping.
- [x] Cover topocentric horizontal coordinates and rates.
- [x] Cover refraction fallback and strict meteorology.
- [x] Cover empty batches, invalid inputs, and use after close.
- [x] Document the public API and update the upstream coverage map.
