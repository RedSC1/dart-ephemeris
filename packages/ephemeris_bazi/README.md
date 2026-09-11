# ephemeris_bazi

> **Pre-release:** `1.0.0-beta.10`, kept in lockstep with the Dart `ephemeris`
> core package.

BaZi (八字) extension bindings for the Taiyin ephemeris, part of the
[`dart-ephemeris`](../..) monorepo. Mirrors `packages/ephemeris-bazi` in the Python
binding.

```sh
dart pub add ephemeris
dart pub add ephemeris_bazi
```

Generated API reference: <https://pub.dev/documentation/ephemeris_bazi/latest/>

See the [BaZi guide](doc/guide.md) for local/instant birth inputs, custom
calendar contexts, Qi-Yun, Da-Yun/Xiao-Yun, Ten Gods, relations, Shen Sha, and
ownership.

Depends on the core `ephemeris` package. Importing this package adds
`context.bazi` and `context.createBazi()` to `EphemerisContext`:

```dart
import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_bazi/ephemeris_bazi.dart';

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
root `ephemeris` package does not contain BaZi symbols. Override the bundled module
with `TAIYIN_BAZI_LIBRARY_PATH` or `createBazi(libraryPath: ...)`. A missing
module raises `UnsupportedError` while the core context remains usable.

For isolate parallelism, open the process runtime once, call
`Ephemeris.attach().createContext()` in every worker, and create one BaZi
context per worker. Do not send native-backed Dart objects between isolates.

```sh
dart test
```
## Custom Shen Sha modules (next release)

```dart
final defaults = BaziShenShaCatalog();
final catalog = defaults.addModule(BaziShenShaModule(
  label: 'my-school',
  rules: [BaziShenShaRule(id: 'day-marker', name: 'Day marker',
    test: (input) => input.targetKind == BaziShenShaTargetKind.day)],
));
final rules = catalog.createContext();
try {
  // chart is an existing BaziChart from context.bazi.calcChart(pillars).
  final matches = rules.evaluate(chart: chart, target: chart.dayPillar,
    targetKind: BaziShenShaTargetKind.day);
  print(matches.map((match) => match.id));
} finally {
  rules.close();
  catalog.close();
  defaults.close();
}
```

Add/remove return NEW catalogs. Built-in definitions cannot be replaced or
removed. Duplicate/unknown IDs are errors. `removeModule('my-school')` removes
ALL that module's rules from the new catalog, not from existing snapshots.
`createContext(disabledIds: [...])` disables entries without deleting them.

Callbacks receive immutable four-pillar bytes, target, target kind and optional
gender, and run synchronously in their creating isolate. Exceptions are
rethrown after native unwinding; no partial result is returned. Reentry into
contexts sharing callbacks and closing an active context are rejected. Close
handles explicitly; do not transfer callback-backed handles between isolates.
For parallel work, create independent catalogs/contexts inside each isolate.
Initialize the astronomy runtime once in the main isolate; workers needing
chart calculations use `Ephemeris.attach()`, not repeated `Ephemeris.open()`.
For external libraries use `BaziShenShaCatalog(coreLibraryPath: '/path/to/core',
libraryPath: '/path/to/bazi')`; the two overrides select different libraries.

中文：不能覆盖或删除内置神煞；删除模块会删除新目录中该模块的全部规则，
已有上下文继续使用旧快照。回调异常原样抛出，不挂星历 lastDiagnostic。
上下文会持有回调，请显式 close；不支持跨 isolate 共享回调句柄。
删除模块后的新目录不再持有该模块回调；旧快照仍保持有效。自定义核心库路径
用 `coreLibraryPath`，八字扩展库路径用 `libraryPath`，两者分开设置。
