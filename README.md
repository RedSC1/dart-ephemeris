# Taiyin Dart workspace

This repository contains three separately published Dart packages:

- [`taiyin`](packages/taiyin) — core astronomy, astrology, Chinese calendar,
  and Ganzhi APIs; ships `libtaiyin`.
- [`taiyin_bazi`](packages/taiyin_bazi) — optional BaZi extension; ships
  `libtaiyin_bazi`.
- [`taiyin_ziwei`](packages/taiyin_ziwei) — optional Ziwei Doushu extension;
  ships `libtaiyin_ziwei` and the default TOML rule profile.

All three are currently `1.0.0-alpha.1`. See each package README and CHANGELOG
for its public API and release notes.

```sh
dart pub get
dart analyze
dart test packages/taiyin/test
dart test packages/taiyin_bazi/test
dart test packages/taiyin_ziwei/test
```

Optional maintainer stress matrices are count-controlled and stay out of the
ordinary test run:

```sh
TAIYIN_BAZI_STRESS_CASES=10000 \
  dart test packages/taiyin_bazi/test/bazi_stress_test.dart
TAIYIN_ZIWEI_STRESS_CASES=10000 \
  dart test packages/taiyin_ziwei/test/ziwei_oracle_test.dart
```

The repository targets Dart Native platforms. Dart Web is not currently
supported because the bindings use `dart:ffi`.
