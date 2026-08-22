# Pinned native release baselines

This directory contains **pinned copies** of the Taiyin native library for the
platforms distributed by this prerelease. Bundling them makes installed Dart
packages self-contained; users do not need to locate a separate Taiyin shared
library.

## Current baseline

| | |
|---|---|
| Native commit | `130063b3` — "chore(release): prepare 1.0.0-beta.1" (2026-08-22) |
| Version | 1.0.0-beta.1 |
| C ABI | 9 |
| Build | modular core (astronomy + Chinese calendar + Ganzhi) |
| Platforms | macOS arm64, Linux x64, Windows x64 |

This is the modular `taiyin` target built with
`TAIYIN_BUILD_MODULAR_C_API=ON`. BaZi and Ziwei are pinned separately in their
own packages. The core carries no external ephemeris-data dependency. The
Windows build additionally uses the bundled MinGW-w64 compiler runtime DLLs
listed below.

## Replacing the baseline

The bundled files are:

```text
libtaiyin.dylib   macOS arm64
libtaiyin.so      Linux x64
taiyin.dll        Windows x64
```

The Windows distribution also keeps the MinGW-w64 compiler runtime DLLs beside
`taiyin.dll`, so users do not need a GCC installation. Their GPLv3, GCC
Runtime Library Exception, and winpthreads license notices are retained under
`licenses/`. The native Taiyin and third-party attribution notice is shipped
as the package-level `NOTICE` file.

When the native baseline changes, download the three artifacts produced by the
`Native integration` workflow and stage them from the repository root:

```sh
dart run tool/stage_native_artifacts.dart /path/to/downloaded-artifacts
```

Update the "Current baseline" table above with the new native commit, version,
ABI, and build, then update the tests to match any new behavior. Because a
binary diff is opaque, the table is the record of what this file is — do not
swap the file without updating it.

## Testing against the baseline

- `dart test` defaults to the pinned copy matching the current platform and
  architecture.
- Set `TAIYIN_TEST_LIBRARY` to test against a freshly built library instead.
- Extension suites load the pinned module from the corresponding package.
