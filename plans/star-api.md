# Star API implementation checklist

Scope: all 16 functions in `taiyin/c/star.h`, plus two follow-up fixes from the
Codex review on PR #5.

## Bindings

- [x] Include `taiyin/c/star.h` in the ffigen wrapper header.
- [x] Generate all catalog, position, and observed-star functions.
- [x] Eagerly probe late ABI-1 runtime and star symbols during library
  compatibility validation.

## Dart API

- [x] Put process-wide catalog operations on `Taiyin.starCatalog`.
- [x] Add TSC1 path and byte loading with caller-memory copy semantics.
- [x] Add TSF1 path loading, catalog count/clear, and magnitude lookup.
- [x] Put context-owned calculations on `TaiyinContext.stars`.
- [x] Add TDB, TT, UT1, and explicit Delta-T position routes.
- [x] Add matching batch position routes with per-star diagnostics.
- [x] Add single and batch UT1 observed-star routes.
- [x] Reuse existing position/observed flags and shared numerical value types.
- [x] Add immutable star-specific position and observed result types.
- [x] Reject empty or NUL-containing keys and paths before FFI.

## Tests and documentation

- [x] Port the C API catalog-memory retention and batch-star cases.
- [x] Cover all 16 C ABI functions.
- [x] Cover TSF1 loading and aliases.
- [x] Compare batch output against matching single calculations at `1e-15`.
- [x] Cover partial position failures and all-or-nothing observed failures.
- [x] Normalize failed batch positions to NaN and preserve all batch failure
  diagnostics.
- [x] Cover topocentric horizontal observed output and use after close.
- [x] Make worker-isolate setup/calculation failures complete the test future.
- [x] Document catalog ownership, concurrency boundaries, and public examples.
- [x] Update the upstream black-box coverage map.

## Deferred

- UTC observed-star calculations do not exist in the current C ABI.
- Star catalog mutation remains setup-time only; the Dart wrapper does not
  serialize it against calculations in other isolates.
