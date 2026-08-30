## 1.0.0-beta.4

- Rebuild the bundled Ziwei module against the Taiyin 1.0.0-beta.5 native
  baseline.

## 1.0.0-beta.3

- Keep `calculateLocal` and `calculateInstant` on the configured fixed civil
  clock when the attached calendar uses a separate mean-solar day boundary.

## 1.0.0-beta.2

- Update the bundled Ziwei module to Taiyin 1.0.0-beta.4 and C ABI 10.
- Preserve written month, effective month, physical month sequence,
  month-building branch, and flow-palace month index independently.
- Add a selectable physical-sequence/effective-month flow-palace strategy for
  leap months and retain corrected reform-year and Rat-hour flow behavior.

## 1.0.0-beta.1

- Promote the extension to beta in lockstep with `ephemeris`.
- Update the bundled Ziwei native module to Taiyin 1.0.0-beta.3.

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
