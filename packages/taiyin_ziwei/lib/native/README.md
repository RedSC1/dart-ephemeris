# Pinned Ziwei native modules

This directory contains the macOS arm64, Linux x64, and Windows x64 modular
Ziwei targets from Taiyin 1.0.0-beta.1, native commit `130063b3`, C ABI 9. They
depend on the matching modular core shipped by `package:taiyin`.

Stage replacements from artifacts produced by the native integration workflow:

```sh
dart run tool/stage_native_artifacts.dart /path/to/downloaded-artifacts
```
