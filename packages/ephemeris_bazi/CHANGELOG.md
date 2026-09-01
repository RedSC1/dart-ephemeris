## 1.0.0-beta.6

- Keep the extension release in lockstep with `ephemeris` 1.0.0-beta.6 and
  Taiyin 1.0.0-beta.8.

## 1.0.0-beta.5

- Keep the extension release in lockstep with `ephemeris` 1.0.0-beta.5 and
  Taiyin 1.0.0-beta.6.

## 1.0.0-beta.4

- Rebuild the bundled BaZi module against Taiyin 1.0.0-beta.5 and avoid
  unsupported internal-visibility attributes in MinGW builds.

## 1.0.0-beta.3

- Keep `calculateLocal` and `calculateInstant` on the configured fixed civil
  clock when the attached calendar uses a separate mean-solar day boundary.

## 1.0.0-beta.2

- Update the bundled BaZi module to Taiyin 1.0.0-beta.4 and C ABI 10.
- Use the core's canonicalized virtual chart clock at exact integer-hour
  boundaries without changing the physical UTC instant.

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
