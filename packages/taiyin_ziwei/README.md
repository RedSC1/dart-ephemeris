# taiyin_ziwei

Ziwei Doushu (紫微斗数) extension bindings for the Taiyin ephemeris, part of
the [`taiyin-dart`](../..) monorepo. Mirrors `packages/taiyin-ziwei` in the
Python binding.

Depends on the core `taiyin` package. Importing this package attaches
`context.ziwei` and `context.createZiwei()` to `EphemerisContext`:

```dart
import 'package:taiyin/taiyin.dart';
import 'package:taiyin_ziwei/taiyin_ziwei.dart';

void main() {
  final ephemeris = Ephemeris.open();
  final context = ephemeris.createContext();
  try {
    final chart = context.ziwei.calculateLocal(
      AstroDateTime(2003, 3, 13, 14, 15),
      gender: ZiweiGender.male,
    );
    print(chart.value.summary.bureauId);
  } finally {
    context.close();
  }
}
```

The default TOML rule profile ships bundled under `lib/data/ziwei/rules/` and
loads automatically. `ZiweiDataCatalog(profilePath: ...)` loads a custom
profile; a catalog can be shared across Ziwei contexts.

Requires a native library built with `TAIYIN_BUILD_ZIWEI_EXTENSION=ON` (the
core package's bundled `lib/native/` copy includes it). On a library without
the Ziwei capability every entry point throws `UnsupportedError` before any
`taiyin_ziwei_*` symbol is touched.

```sh
dart test
```
