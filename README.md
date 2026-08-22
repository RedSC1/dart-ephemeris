# Taiyin Dart workspace

This repository contains three separately published Dart packages:

- [`taiyin`](packages/taiyin) — core astronomy, astrology, Chinese calendar,
  and Ganzhi APIs; ships `libtaiyin`.
- [`taiyin_bazi`](packages/taiyin_bazi) — optional BaZi extension; ships
  `libtaiyin_bazi`.
- [`taiyin_ziwei`](packages/taiyin_ziwei) — optional Ziwei Doushu extension;
  ships `libtaiyin_ziwei` and the default TOML rule profile.

The prerelease packages bundle macOS arm64, Linux x64, and Windows x64 native
modules. Other Dart Native targets can use an application-supplied Taiyin
build. Dart Web is not currently supported.

All three are currently `1.0.0-alpha.1`. See each package README and CHANGELOG
for its public API and release notes.

## Install

Install the core package first, then add only the optional traditional
astrology extensions the application uses:

```sh
dart pub add taiyin
dart pub add taiyin_bazi   # optional
dart pub add taiyin_ziwei  # optional
```

The packages load their bundled native modules automatically on supported
platforms. No manual DLL/shared-library path is required for an ordinary
installation.

## Quick start

```dart
import 'package:taiyin/taiyin.dart' as taiyin;

void main() {
  final ephemeris = taiyin.Ephemeris.open();
  final context = ephemeris.createContext();
  try {
    final result = context.position.atTt(
      taiyin.Body.mars,
      taiyin.JulianDate<taiyin.TtScale>.fromDouble(2460409.0),
    );
    print(result.value.coordinates);
    print(result.flags.values);
  } finally {
    context.close();
  }
}
```

Package guides:

- [Core astronomy, calendar, Ganzhi, and astrology](packages/taiyin/README.md)
- [BaZi extension](packages/taiyin_bazi/README.md)
- [Ziwei Doushu extension](packages/taiyin_ziwei/README.md)

The `///` API comments are the source for generated Dart API documentation.
Maintainers can preview all three locally with:

```sh
dart doc packages/taiyin
dart doc packages/taiyin_bazi
dart doc packages/taiyin_ziwei
```

## Workspace development

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
