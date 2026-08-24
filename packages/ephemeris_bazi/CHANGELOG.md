## 1.0.0-beta.1

- Promote the extension to beta in lockstep with `ephemeris`.
- Update the bundled BaZi native module to Taiyin 1.0.0-beta.3.

## 1.0.0-alpha.2

- Route `calculateLocal` and `calculateInstant` through the bound Chinese
  calendar context, including mean-solar-meridian conversion and propagated
  time-scale result flags.

## 1.0.0-alpha.1

- Require the ABI-9 `ephemeris` package.
- Add `calculateLocal` and `calculateInstant` complete-chart entry points.
- Return call-scoped result flags from Qi-Yun and Renyuan Siling operations.
- Ship and lazily load a separate `libtaiyin_bazi` native module.
- Add a four-worker isolate concurrency test.
