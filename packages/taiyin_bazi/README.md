# taiyin_bazi

BaZi (八字) extension bindings for the Taiyin ephemeris, part of the
[`taiyin-dart`](../..) monorepo. Mirrors `packages/taiyin-bazi` in the Python
binding.

Depends on the core `taiyin` package. Importing this package attaches
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

Requires a native library built with `TAIYIN_BUILD_BAZI_EXTENSION=ON` (the core
package's bundled `lib/native/` copy includes it). On a library without the
BaZi capability every entry point throws `UnsupportedError` before any
`taiyin_bazi_*` symbol is touched.

```sh
dart test
```
