# Pinned BaZi native modules

This directory contains the macOS arm64, Linux x64, and Windows x64 modular
BaZi targets from Taiyin 1.0.0-beta.5, native commit `f2efc8c3`, C ABI 10. They
depend on the matching modular core shipped by `package:ephemeris`.

Stage replacements from artifacts produced by the native integration workflow:

```sh
dart run tool/stage_native_artifacts.dart /path/to/downloaded-artifacts
```
