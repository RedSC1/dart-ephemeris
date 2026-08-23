## 1.0.0-alpha.2

- Route `calculateLocal` and `calculateInstant` through the bound Chinese
  calendar context, including mean-solar-meridian conversion and propagated
  time-scale result flags.

## 1.0.0-alpha.1

- Require the ABI-9 `ephemeris` package.
- Return call-scoped result flags from chart creation, flow resolution, and
  reverse lookup.
- Aggregate time-conversion flags in `calculateInstant`.
- Ship and lazily load a separate `libtaiyin_ziwei` native module.
- Add a four-worker isolate concurrency test.
