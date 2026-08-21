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
- Update the pinned modular native libraries to Taiyin 1.0.0-preview.6.
- Split the pinned native distribution into core, BaZi, and Ziwei modules;
  extension packages now load their own module lazily.
- Remove BaZi/Ziwei from the core capability enum; extension availability is
  determined by loading the corresponding package-owned native module.
- Add concurrent multi-isolate BaZi and Ziwei integration tests.
