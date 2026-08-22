# dart-ephemeris ("Taiyin")

Dart bindings for [Taiyin Ephemeris](https://github.com/RedSC1/taiyin-ephemeris),
the C++ astronomy, ephemeris, traditional-calendar, and astrology core.

This repository is a monorepo containing three separately published packages:

- [`ephemeris`](packages/ephemeris/) — astronomy, time, positions, events,
  eclipses, astrology, the Chinese calendar, and Ganzhi;
- [`ephemeris_bazi`](packages/ephemeris_bazi/) — optional BaZi (八字)
  extension;
- [`ephemeris_ziwei`](packages/ephemeris_ziwei/) — optional Ziwei Doushu
  (紫微斗数) extension and its default TOML rule profile.

- GitHub repository: `dart-ephemeris`
- pub.dev packages: `ephemeris`, `ephemeris_bazi`, `ephemeris_ziwei`
- Dart imports: `package:ephemeris/ephemeris.dart` and the matching extension
  libraries

```sh
dart pub add ephemeris
dart pub add ephemeris_bazi   # optional
dart pub add ephemeris_ziwei  # optional
```

This is a prerelease. Public APIs and native packaging may still change before
the stable `1.0.0` line.

The packages load their bundled Taiyin native modules automatically on macOS
arm64, Linux x64, and Windows x64. Ordinary users do not locate DLLs or shared
libraries manually. Other Dart Native targets can supply compatible Taiyin
modules explicitly. Dart Web and Flutter Web are not currently supported.

## Quick start

### Planetary positions

```dart
import 'package:ephemeris/ephemeris.dart' as eph;

final runtime = eph.Ephemeris.open();
final context = runtime.createContext();
final instantUt1 =
    eph.JulianDate<eph.Ut1Scale>.fromDouble(2460409.25);

final mars = context.position.atUt1(eph.Body.mars, instantUt1);
final state = context.position.stateAtUt1(eph.Body.mars, instantUt1);

print('Mars longitude/latitude/distance: ${mars.value.coordinates}');
print('Mars Cartesian position (AU): ${state.value.positionAu}');
print('Execution flags: ${mars.flags.values}');
```

The position service also accepts TT, TDB, UTC, explicit Delta-T, batch, and
Cartesian-state requests. Successful native calls return Dart records with a
`value` and `flags`; fatal statuses throw typed `EphemerisError` subclasses.
Close contexts explicitly (normally with `try`/`finally`) in production code;
the short examples below keep one context alive for readability.

### Solar and lunar eclipses

```dart
final searchStart =
    eph.JulianDate<eph.Ut1Scale>.fromDouble(2460310.5);

final solar = context.eclipses.nextSolarAtUt1(searchStart);
final lunar = context.eclipses.nextLunarAtUt1(searchStart);

print('Next solar eclipse: ${solar.value.kinds}');
print('Next lunar eclipse: ${lunar.value.kinds}');
print('Execution flags: ${(solar.flags | lunar.flags).values}');
```

The eclipse service also supports contact times, local circumstances, global
routes and map products, and observer-specific visibility.

### Chinese calendar and Ganzhi

```dart
final localTime = eph.AstroDateTime(2003, 3, 13, 14, 15); // UTC+08:00
final instantUtc = localTime
    .toJulianDate<eph.UtcScale>()
    .addSeconds(-8 * 3600);

final lunarDate = context.chineseCalendar.fromSolar(
  const eph.SolarDate(year: 2003, month: 3, day: 13),
);
final pillars = context.chineseCalendar.fourPillars(
  instantUtc: instantUtc,
  virtualTime: localTime,
);

print('Lunar date: ${lunarDate.value}');
print('Four pillars: ${pillars.value}');
print('Day NaYin: ${context.ganzhi.nayinElement(pillars.value.day)}');
```

The Chinese calendar and Ganzhi APIs are part of the core `ephemeris` package;
they do not require an extension package.

## Astrology

Sidereal positions, ayanamsha models, house systems, precession, nutation, and
lunar points are included in the core package:

```dart
context.configuration.setObserverLocation(
  const eph.ObserverLocation(
    longitudeDegrees: 118.582,
    latitudeDegrees: 37.449,
  ),
);

final sun = context.astrology.siderealPositionAtUt1(
  eph.Body.sun,
  instantUt1,
  ayanamsha: eph.Ayanamsha.lahiri,
);
final houses = context.astrology.housesAtUt1(
  instantUt1,
  system: eph.HouseSystem.porphyry,
);

print('Sidereal Sun: ${sun.value.siderealLongitudeRadians} rad');
print('Ascendant: ${houses.value.ascendantRadians} rad');
print('House cusps: ${houses.value.cuspLongitudesRadians}');
```

## BaZi extension

Install and import the optional package:

```sh
dart pub add ephemeris_bazi
```

```dart
import 'package:ephemeris_bazi/ephemeris_bazi.dart';

final bazi = context.bazi;
final result = bazi.calculateLocal(
  eph.AstroDateTime(2003, 3, 13, 14, 15),
  gender: BaziGender.male,
);

print('Four pillars: ${result.value.pillars}');
print('Qi-Yun start: ${result.value.qiyun.startCivilTime}');
print('Visible Ten Gods: ${result.value.chart.visibleTenGods}');
```

The cached BaZi context uses the calculation context's default Chinese-calendar
policy. `createBazi(calendar: ...)` can bind another calendar created by the
same `EphemerisContext`.

## Ziwei Doushu extension

```sh
dart pub add ephemeris_ziwei
```

```dart
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';

final ziwei = context.ziwei;
final chartResult = ziwei.calculateLocal(
  eph.AstroDateTime(2003, 3, 13, 14, 15),
  gender: ZiweiGender.male,
);
final chart = chartResult.value;
try {
  final life = chart.palace(ZiweiPalace.life);
  print('Bureau: ${chart.anchors.bureau}');
  print('Life-palace stars: ${life.stars.map((star) => star.key)}');
} finally {
  chart.close();
}
```

The extension includes natal charts, independent TOML rule selections,
brightness and transformation overlays, decade-through-hour flow layers,
early/late Rat-hour navigation, and finite birth-time reverse lookup.

## Accuracy and ephemeris data

Taiyin supports its OPM2 compressed ephemeris format, NASA/JPL BSP/SPK kernels,
TKC1/Kepler fallback files, and a built-in semi-analytical route. Applications
can register files or directories with `Ephemeris.addSourcePath()`; the AUTO
router selects a compatible route from the loaded catalog.

For a typical major-body OPM2 product, the compression/reconstruction
difference from its source DE441 or DE442 ephemeris is on the order of
**0.001 arcsec**. This is a state-compression metric, not a blanket guarantee
for final apparent, topocentric, eclipse-contact, or historical-calendar
results. Those also depend on the selected source, coverage, time scales,
observer model, and requested corrections.

The current Dart packages bundle the native runtime, not a full planetary
OPM2/SPK archive. Without external data, the runtime can use its built-in
semi-analytical fallback over its declared interval. For precision work, load
an appropriate OPM2 product or an original NASA/JPL BSP/SPK kernel.

**Coming soon:** a separately downloadable full DE440-derived compressed OPM2
data product. It is not included in the current prerelease.

See the core package's [accuracy and data notes](packages/ephemeris/doc/accuracy-and-data.md)
for scope, limitations, and route-selection guidance.

## Native loading and concurrency

Call `Ephemeris.open()` once in the main isolate to initialize the process-wide
runtime. Worker isolates use `Ephemeris.attach()` and create their own
`EphemerisContext`. Do not send native-backed Dart objects between isolates.

The base package owns `libtaiyin`; BaZi and Ziwei ship their own matching
`libtaiyin_bazi` and `libtaiyin_ziwei` modules. Environment-variable and
explicit-path overrides remain available for development and unsupported
platforms.

## Documentation

- [Core Dart guide and API overview](packages/ephemeris/README.md)
- [Accuracy and ephemeris data](packages/ephemeris/doc/accuracy-and-data.md)
- [Custom callback lifecycle](packages/ephemeris/doc/custom-target-lifecycle.md)
- [BaZi package](packages/ephemeris_bazi/README.md)
- [Ziwei Doushu package](packages/ephemeris_ziwei/README.md)

The public `///` comments generate the package API reference on pub.dev.

## Development

```sh
dart pub get
dart analyze packages
dart test packages/ephemeris/test
dart test packages/ephemeris_bazi/test
dart test packages/ephemeris_ziwei/test
```

Pull requests run formatting, analysis, and dartdoc generation. The complete
macOS/Linux/Windows native integration matrix runs only through a manual
`workflow_dispatch` or a `v*` release tag.

Optional stress matrices stay out of the ordinary test run:

```sh
TAIYIN_BAZI_STRESS_CASES=10000 \
  dart test packages/ephemeris_bazi/test/bazi_stress_test.dart
TAIYIN_ZIWEI_STRESS_CASES=10000 \
  dart test packages/ephemeris_ziwei/test/ziwei_oracle_test.dart
```

Dart Web and Flutter Web are not currently supported because these bindings
use `dart:ffi` and native shared libraries.
