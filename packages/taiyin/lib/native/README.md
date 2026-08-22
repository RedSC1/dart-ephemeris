# Pinned native baseline

`libtaiyin.dylib` is a **pinned copy** of the Taiyin native library that this
package is tested against. Committing it makes the Dart test suite and example
programs self-contained and reproducible: they do not depend on the sibling
`taiyin-ephemeris` checkout being built.

## Current baseline

| | |
|---|---|
| Native commit | `130063b3` — "chore(release): prepare 1.0.0-beta.1" (2026-08-22) |
| Version | 1.0.0-beta.1 |
| C ABI | 9 |
| Build | modular core (astronomy + Chinese calendar + Ganzhi) |
| Platform | macOS arm64 |

This is the modular `taiyin` target built with
`TAIYIN_BUILD_MODULAR_C_API=ON`. BaZi and Ziwei are pinned separately in their
own packages. The core only links system libraries and carries no external
data dependency.

## Replacing the baseline

When the native library updates, rebuild and replace this file in place:

```sh
cp -L ../taiyin-ephemeris/build-dart-modular/libtaiyin.dylib lib/native/libtaiyin.dylib
```

Update the "Current baseline" table above with the new native commit, version,
ABI, and build, then update the tests to match any new behavior. Because a
binary diff is opaque, the table is the record of what this file is — do not
swap the file without updating it.

## Testing against the baseline

- `dart test` defaults to this pinned copy.
- Set `TAIYIN_TEST_LIBRARY` to test against a freshly built library instead.
- Extension suites load the pinned module from the corresponding package.
