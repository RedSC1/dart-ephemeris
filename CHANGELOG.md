## 0.5.0

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
- Update the pinned full-module native library to Taiyin 1.0.0-preview.6.
