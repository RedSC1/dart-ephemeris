# taiyin_ziwei

> **Pre-release:** `1.0.0-alpha.1`, kept in lockstep with the Dart `taiyin`
> core package.

Ziwei Doushu (紫微斗数) extension bindings for the Taiyin ephemeris, part of
the [`taiyin-dart`](../..) monorepo. Mirrors `packages/taiyin-ziwei` in the
Python binding.

```sh
dart pub add taiyin
dart pub add taiyin_ziwei
```

Generated API reference: <https://pub.dev/documentation/taiyin_ziwei/latest/>

Depends on the core `taiyin` package. Importing this package adds
`context.ziwei` and `context.createZiwei()` to `EphemerisContext`:

```dart
import 'package:taiyin/taiyin.dart';
import 'package:taiyin_ziwei/taiyin_ziwei.dart';

void main() {
  final ephemeris = Ephemeris.open();
  final context = ephemeris.createContext();
  try {
    final result = context.ziwei.calculateLocal(
      AstroDateTime(2003, 3, 13, 14, 15),
      gender: ZiweiGender.male,
    );
    print(result.value.summary.bureauId);
    print(result.flags.values);
  } finally {
    context.close();
  }
}
```

The default TOML rule profile ships bundled under `lib/data/ziwei/rules/` and
loads automatically. `ZiweiDataCatalog(profilePath: ...)` loads a custom
profile; a catalog can be shared across Ziwei contexts.

This package ships and lazily loads its own `libtaiyin_ziwei` native module; the
root `taiyin` package does not contain Ziwei symbols. Override the bundled
module with `TAIYIN_ZIWEI_LIBRARY_PATH`, `createZiwei(libraryPath: ...)`, or
`ZiweiDataCatalog(libraryPath: ...)`. A missing module raises
`UnsupportedError` while the core context remains usable.

For isolate parallelism, create one Ziwei context and independent charts per
worker. Catalog snapshots are immutable, but a mutable chart must not be
modified concurrently from more than one isolate.

```sh
dart test
```
