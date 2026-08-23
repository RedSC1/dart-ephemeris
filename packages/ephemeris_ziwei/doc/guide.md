# Ziwei Doushu guide

`ephemeris_ziwei` is an optional native extension. It ships a Ziwei native
module and the bundled default TOML rule profile.

```sh
dart pub add ephemeris
dart pub add ephemeris_ziwei
```

## Natal chart

```dart
import 'package:ephemeris/ephemeris.dart' as eph;
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';

final context = eph.Ephemeris.open().createContext();
final ziwei = context.ziwei;
final chart = ziwei
    .calculateLocal(
      eph.AstroDateTime(2003, 3, 13, 14, 15),
      gender: ZiweiGender.male,
      options: const ZiweiBirthOptions(
        ratHourMode: eph.GanzhiRatHourMode.noSplit,
      ),
    )
    .value;

try {
  print(chart.anchors.bureau);
  print(chart.palace(ZiweiPalace.life).stars.map((star) => star.key));
} finally {
  chart.close();
}
```

`calculateInstant` accepts a physical UTC instant and resolves its local clock
through the bound Chinese-calendar context. `calculateLocal` accepts a wall
clock under that context's calendar policy. The lower-level `createChart`
accepts both a physical instant and a deliberately adjusted virtual wall clock,
which is the appropriate entry point for an application-computed apparent
solar time.

## Birth options

`ZiweiBirthOptions` keeps independent choices for:

- early/late Rat-hour handling;
- leap-month placement;
- Heaven/Earth/Human chart mode;
- lunar-year or solar-term year boundaries for Wu-Hu-Dun, Si-Hua, and
  life/body masters.

The physical instant remains authoritative for solar-term boundaries. A
virtual Rat-hour date changes only the traditional day/hour interpretation.

## Rule-table options

The bundled profile defaults every unspecified dimension to `option1`. Select
placement, brightness, Si-Hua, masters, and longevity independently:

```dart
final custom = context.createZiwei(
  selection: const ZiweiOptionSelection(
    placementDefault: 'option1',
    brightnessDefault: 'option1',
    sihuaDefault: 'option1',
    masters: 'option1',
    longevity: 'option2',
  ),
);
```

These are rule-dimension choices, not one monolithic “school” switch. The
bundled profile currently supplies `option2` for the longevity table; custom
profiles can add named alternatives and select per-star placement, brightness,
or Si-Hua entries through the corresponding maps.

## Custom TOML catalog and reload

```dart
final catalog = ZiweiDataCatalog(profilePath: '/path/to/profile.toml');
final ziwei = context.createZiwei(catalog: catalog);

print(catalog.generation);
catalog.reload();
print(catalog.generation);
```

Reload advances the catalog snapshot generation. Existing charts remain
native snapshots; create new contexts/charts when the application needs the
new table selection. A caller-supplied catalog remains caller-owned.

## Flow layers and navigation

Charts can resolve Da-Xian, Xiao-Xian, year, month, day, and hour flow layers.
The API also supports:

- lunar-month or solar-term flow boundaries;
- removal of lower flow levels with `truncateFlow`;
- layer summaries and per-palace flow-star lookup;
- next/previous day and hour targets that respect the selected Rat-hour rule;
- physical-month sequence and month-building branches across historical
  calendar edge cases.

## Reverse lookup and overlays

The package exposes star-to-palace lookup, palace-to-star lookup, natal and
flow brightness, annual Si-Hua, self/centripetal/centrifugal transformation
overlays, and finite birth-slot reverse lookup through `ZiweiTier1ReverseQuery`.

## Ownership

`context.ziwei` caches the default context. Independent contexts created by
`createZiwei` must be closed. Every `ZiweiChart` is native-backed and must also
be closed. Close charts before their context, and close contexts before a
caller-owned catalog or Chinese-calendar context.
