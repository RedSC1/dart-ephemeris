# ephemeris_ziwei

> **Pre-release:** `1.0.0-beta.3`, kept in lockstep with the Dart `ephemeris`
> core package.

Ziwei Doushu (紫微斗数) extension bindings for the Taiyin ephemeris, part of
the [`dart-ephemeris`](../..) monorepo. Mirrors `packages/ephemeris-ziwei` in the
Python binding.

```sh
dart pub add ephemeris
dart pub add ephemeris_ziwei
```

Generated API reference: <https://pub.dev/documentation/ephemeris_ziwei/latest/>

See the [Ziwei Doushu guide](doc/guide.md) for the bundled rule profile,
independent option dimensions, custom TOML catalogs, natal charts, flow
layers, Rat-hour policies, and reverse lookup.

Depends on the core `ephemeris` package. Importing this package adds
`context.ziwei` and `context.createZiwei()` to `EphemerisContext`:

```dart
import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';

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
root `ephemeris` package does not contain Ziwei symbols. Override the bundled
module with `TAIYIN_ZIWEI_LIBRARY_PATH`, `createZiwei(libraryPath: ...)`, or
`ZiweiDataCatalog(libraryPath: ...)`. A missing module raises
`UnsupportedError` while the core context remains usable.

For isolate parallelism, create one Ziwei context and independent charts per
worker. Catalog snapshots are immutable, but a mutable chart must not be
modified concurrently from more than one isolate.

Flow resolution keeps the physical lunar year, written month, effective
month, physical month sequence, month-building branch, and palace month index
separate. `ZiweiFlowMonthPalaceStrategy.physicalSequence` is the default;
select `effectiveMonth` through `ZiweiFlowOptions` for schools that attach a
leap segment's flow palace to its effective month.

```sh
dart test
```
