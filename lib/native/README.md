# Pinned native baseline

`libtaiyin.dylib` is a **pinned copy** of the Taiyin native library that this
package is tested against. Committing it makes the Dart test suite and example
programs self-contained and reproducible: they do not depend on the sibling
`taiyin-ephemeris` checkout being built.

## Current baseline

| | |
|---|---|
| Native commit | `00ac4f21` — "fix(portability): avoid nonstandard M_PI macro" (2026-08-18) |
| Version | 1.0.0-preview.5 |
| C ABI | 8 |
| Build | `taiyin-ephemeris/build-dart-abi8` — full modules (Chinese calendar + Ganzhi + BaZi + Ziwei), monolithic |
| Platform | macOS arm64 |

This is the full-module monolithic build (`taiyin_c` with
`TAIYIN_BUILD_CHINESE_METAPHYSICS_EXTENSIONS=ON`,
`TAIYIN_BUILD_BAZI_EXTENSION=ON`, `TAIYIN_BUILD_ZIWEI_EXTENSION=ON`). It only
links system libraries and carries no external data dependency.

## Replacing the baseline

When the native library updates, rebuild and replace this file in place:

```sh
cp ../taiyin-ephemeris/build-dart-abi8/libtaiyin.8.0.0.dylib lib/native/libtaiyin.dylib
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
