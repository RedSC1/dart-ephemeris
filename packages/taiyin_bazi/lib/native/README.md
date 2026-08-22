# Pinned BaZi native module

`libtaiyin_bazi.dylib` is the macOS arm64 modular BaZi target from Taiyin
1.0.0-beta.1, native commit `130063b3`, C ABI 9. It depends on the modular
core `libtaiyin` shipped by `package:taiyin`.

Replace it from a modular CMake build with:

```sh
cp -L ../taiyin-ephemeris/build-dart-modular/bazi_astrology/libtaiyin_bazi.dylib \
  packages/taiyin_bazi/lib/native/libtaiyin_bazi.dylib
```
