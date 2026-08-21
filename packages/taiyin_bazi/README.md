# taiyin_bazi

> **Pre-release:** `1.0.0-alpha.1`, kept in lockstep with the Dart `taiyin`
> core package.

BaZi (八字) extension bindings for the Taiyin ephemeris, part of the
[`taiyin-dart`](../..) monorepo. Mirrors `packages/taiyin-bazi` in the Python
binding.

Depends on the core `taiyin` package. Importing this package adds
`context.bazi` and `context.createBazi()` to `EphemerisContext`:

```dart
import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';

void main() {
  final ephemeris = Ephemeris.open();
  final context = ephemeris.createContext();
  try {
    final result = context.bazi.calculateLocal(
      AstroDateTime(2003, 3, 13, 14, 15),
      gender: BaziGender.male,
    );
    print(result.value.chart.dayPillar);
    print(result.value.qiyun.startCivilTime);
    print(result.flags.values);
  } finally {
    context.close();
  }
}
```

A BaZi context binds one `ChineseCalendarContext` at creation (the cached
default calendar unless `createBazi(calendar: ...)` says otherwise) and
resolves solar terms through it; the calendar must belong to the same
`EphemerisContext`.

This package ships and lazily loads its own `libtaiyin_bazi` native module; the
root `taiyin` package does not contain BaZi symbols. Override the bundled module
with `TAIYIN_BAZI_LIBRARY_PATH` or `createBazi(libraryPath: ...)`. A missing
module raises `UnsupportedError` while the core context remains usable.

For isolate parallelism, open the process runtime once, call
`Ephemeris.attach().createContext()` in every worker, and create one BaZi
context per worker. Do not send native-backed Dart objects between isolates.

```sh
dart test
```
