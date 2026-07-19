# Runtime API implementation checklist

Scope: the process-wide management functions in `taiyin/c/runtime.h`, plus the
release codename metadata added to `taiyin/c/base.h`. Runtime initialization
options already exposed by `Taiyin.open` remain unchanged.

## Bindings and metadata

- [x] Generate `taiyin_get_library_codename`.
- [x] Expose `Taiyin.libraryCodename`.
- [x] Generate the remaining public runtime management functions.

## Dart API

- [x] Keep native runtime initialization internal to `Taiyin.open()`.
- [x] Represent the process-wide engine with `Taiyin`.
- [x] Represent user calculation state with a separate `TaiyinContext`.
- [x] Create independent contexts through `taiyin.createContext()`.
- [x] Allow worker isolates to create context-only attachments without
  reinitializing the runtime.
- [x] Add source-path discovery.
- [x] Add file and built-in EOP lifecycle management.
- [x] Add lunar-limb model lifecycle management.
- [x] Add ephemeris cache clear and count operations.
- [x] Keep global metadata and catalog/cache queries on `Taiyin`.
- [x] Reject empty paths.
- [x] Document process-wide ownership and setup-time mutation.

## Tests and documentation

- [x] Cover codename metadata.
- [x] Cover source discovery and catalog count.
- [x] Cover EOP and lunar-limb load/clear/has lifecycles.
- [x] Cover cache population, count, and clear.
- [x] Cover native error propagation and invalid paths.
- [x] Cover independent context lifetimes and multi-Isolate calculations.
- [x] Update README and upstream C API coverage notes.
