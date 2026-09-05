## 1.0.0-beta.7

- Add immutable natal edits, life-palace shifts and reset.
- Add independent manual, numbered and OS-random casting charts, full star and
  transformation queries, and missing-input records.
- Build against Taiyin `v1.0.0-beta.9`; release packages require the matching
  CI-built native modules. Keep all three Dart packages in lockstep.

## 1.0.0-beta.6

- Keep the extension release in lockstep with `ephemeris` 1.0.0-beta.6 and
  Taiyin 1.0.0-beta.8.
- Add immutable JSON option modules for stars, brightness, Si-Hua, flow stars,
  and master tables without replacing bundled TOML options; modules can be
  removed as one complete contribution set by label.
- Expose whether each Ziwei registry entry is a natal or flow-only star.

## 1.0.0-beta.5

- Keep the extension release in lockstep with `ephemeris` 1.0.0-beta.5 and
  Taiyin 1.0.0-beta.6.

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
