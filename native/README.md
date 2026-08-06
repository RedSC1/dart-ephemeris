# Pinned native baseline

`libtaiyin.dylib` is a **pinned copy** of the Taiyin native library that this
package is tested against. Committing it makes the Dart test suite and example
programs self-contained and reproducible: they do not depend on the sibling
`taiyin-ephemeris` checkout being built.

## Current baseline

| | |
|---|---|
| Native commit | `b9d4ca5` — "Fix init regression: TKC1 per-file source keys + route-overlap index (#56)" (2026-08-06) |
| Version | 1.0.0 |
| C ABI | 5 |
| Build | `taiyin-ephemeris/build-bazi` — full modules (Chinese calendar + Ganzhi + BaZi) |
| Platform | macOS arm64 |

This is the full-module build, matching the default
`TAIYIN_TEST_LIBRARY` baseline. It only links system libraries and carries no
external data dependency.

## Replacing the baseline

When the native library updates, rebuild and replace this file in place:

```sh
cp ../taiyin-ephemeris/build-bazi/libtaiyin.5.0.0.dylib native/libtaiyin.dylib
```

Update the "Current baseline" table above with the new native commit, version,
ABI, and build, then update the tests to match any new behavior. Because a
binary diff is opaque, the table is the record of what this file is — do not
swap the file without updating it.

## Testing against the baseline

- `dart test` defaults to this pinned copy.
- Set `TAIYIN_TEST_LIBRARY` to test against a freshly built library instead.
- Set `TAIYIN_BASELINE_LIBRARY` for the bazi-off baseline library (not pinned;
  it must be provided or the optional-module tests skip).
