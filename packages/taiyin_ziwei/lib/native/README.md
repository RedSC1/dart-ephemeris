# Pinned Ziwei native module

`libtaiyin_ziwei.dylib` is the macOS arm64 modular Ziwei target from Taiyin
1.0.0-beta.1, native commit `130063b3`, C ABI 9. It depends on the modular
core `libtaiyin` shipped by `package:taiyin`.

Replace it from a modular CMake build with:

```sh
cp -L ../taiyin-ephemeris/build-dart-modular/ziwei_astrology/libtaiyin_ziwei.dylib \
  packages/taiyin_ziwei/lib/native/libtaiyin_ziwei.dylib
```
