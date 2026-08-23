# BaZi guide

`ephemeris_bazi` is an optional native extension. It depends on `ephemeris` but
ships its own BaZi native module.

```sh
dart pub add ephemeris
dart pub add ephemeris_bazi
```

## Calculate from a local wall clock

```dart
import 'package:ephemeris/ephemeris.dart' as eph;
import 'package:ephemeris_bazi/ephemeris_bazi.dart';

final context = eph.Ephemeris.open().createContext();
final bazi = context.bazi;
final result = bazi.calculateLocal(
  eph.AstroDateTime(2003, 3, 13, 14, 15),
  gender: BaziGender.male,
);

print(result.value.pillars);
print(result.value.chart.visibleTenGods);
print(result.value.qiyun.startCivilTime);
```

The cached `context.bazi` uses the context's cached default Chinese calendar,
whose default is China-standard historical rules at UTC+08:00.

## Calculate from a physical UTC instant

```dart
final instant =
    DateTime.parse('2003-03-13T14:15:00+08:00').toUtcJulianDate();
final result = bazi.calculateInstant(
  instant,
  gender: BaziGender.male,
);
```

The bound calendar derives the local civil time. Do not also construct and
maintain a second wall-clock representation for the same event.

## Use another calendar policy

```dart
final calendar = context.createChineseCalendar(
  config: const eph.ChineseCalendarConfig.localAstronomicalMeridian(118.582),
);
final customBazi = context.createBazi(
  calendar: calendar,
  config: const BaziContextConfig(
    earthPalaceMode: BaziEarthPalaceMode.waterEarth,
  ),
);
```

The calendar controls local/instant conversion, the lunar structure, civil
day boundary, and solar-term queries used by the BaZi context. For an explicit
apparent (“true”) solar-time wall clock, use the core solar-time API and the
low-level `fourPillars`, `calcChart`, and `calcQiyun` methods so the original
physical instant remains authoritative for solar-term boundaries.

## Luck cycles and chart analysis

```dart
final dayun = bazi.fillDayun(
  birthCivilTime: result.value.localTime,
  chart: result.value.chart,
  qiyun: result.value.qiyun,
  requestedCount: 8,
);
final relations = bazi.collectChartRelations(chart: result.value.chart);
```

The package also exposes:

- visible and hidden Ten Gods;
- hidden stems, NaYin, and twelve life stages;
- stem, branch, and three-branch relation calculators;
- Qi-Yun direction/time models and Da-Yun boundary models;
- Da-Yun and Xiao-Yun generation;
- Shen Sha word sets and chart relation collection;
- Renyuan Siling tables and time models.

See the generated API reference for each model enum and result record.

## Ownership

`context.bazi` is cached. `context.createBazi(...)` creates an independent
native context. Close independent contexts explicitly; close them before a
custom Chinese-calendar context they borrow.
