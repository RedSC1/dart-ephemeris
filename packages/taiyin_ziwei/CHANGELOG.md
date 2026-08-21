## 0.5.0

- Require the ABI-9 `taiyin` package.
- Return call-scoped result flags from chart creation, flow resolution, and
  reverse lookup.
- Aggregate time-conversion flags in `calculateInstant`.
- Ship and lazily load a separate `libtaiyin_ziwei` native module.
- Add a four-worker isolate concurrency test.
