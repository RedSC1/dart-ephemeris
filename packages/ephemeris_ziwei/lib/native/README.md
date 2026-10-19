# Pinned Ziwei native modules

This directory contains the macOS arm64, Linux x64, and Windows x64 modular
published Ziwei targets from Taiyin `v1.1.0`, C ABI 11. They
depend on the matching modular core shipped by `package:ephemeris`.

Source-checkout copies may be older. Stage the successful release CI artifacts
before publishing.

Stage replacements from artifacts produced by the native integration workflow:

```sh
dart run tool/stage_native_artifacts.dart /path/to/downloaded-artifacts
```
