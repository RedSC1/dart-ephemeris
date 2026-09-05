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

## Manual placement and casting charts

Available from Dart beta.7, using C++ `v1.0.0-beta.9` or later. Older beta.8
native binaries do not contain these symbols; release assembly must use the
validated native-integration artifacts rather than stale checkout binaries. During
local development, select the new module with `TAIYIN_ZIWEI_LIBRARY_PATH` (and
the matching core with `Ephemeris.open(libraryPath: ...)`). Old modules produce
a clear `UnsupportedError` for new operations; existing APIs remain usable.

```dart
final manual = ziwei.createCastingChart(
  const ZiweiPlacementInput(yearStem: 0, yearBranch: 0, month: 3, day: 13, hourBranch: 7),
  gender: ZiweiGender.male,
);
final draw = ziwei.randomCastingChart(gender: ZiweiGender.male);
final replay = ziwei.castingFromIndex(draw.summary.index!, gender: ZiweiGender.male);
final number = ziwei.castingFromNumber('123456', gender: ZiweiGender.male);
print(number.summary.index); // 209225: number-v1, shared with C++/JS/Python

final edited = chart.modify(const ZiweiPlacementPatch(month: 3, updateBureau: true));
final shifted = edited.shiftLifePalace(1);
final original = shifted.reset();

// Each result owns an independent native handle.
original.close(); shifted.close(); edited.close();
number.close(); replay.close(); draw.close(); manual.close();
```

`ZiweiCastingChart` is distinct from a natal `ZiweiChart`: it has no invented
birth date or real-date flow methods. It exposes `summary`, `starPosition`,
`starPalace`, `palaceStars`, `brightness`, `transformMask`, `hasTransform` and
`omittedPlacements`. Missing date-derived inputs omit dependent stars; positions
are null. Omission `missingInputs` is a bit mask of native RuleInputSource IDs.

Both chart types support immutable `modify`, `shiftLifePalace`, and `reset`.
Null patch inputs are unchanged. `updateBureau: null` inherits the choice,
false restores the original bureau, true recomputes it. Natal edits retain the
original birth/calendar facts and clear stale flows; resolve flows again on the
new chart. Shifts change palace roles without moving the physical stars.

Index-v1 contains 259,200 combinations, hour fastest. Random draws use the OS
random source; gender, chart mode and rule selection remain explicit caller
choices and must match when replaying. Number-v1 normalizes ASCII decimal text
and is a library-defined mapping (not a traditional formula or unique ID).
Reset restores the original draw without resampling. Pure-rule operations
return chart objects directly and throw on failure, without an OperationResult
wrapper or diagnostic update.

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

## JSON option modules

Small application- or school-specific named options can be layered over the
selected TOML snapshot. Bundled TOML options remain immutable:

```dart
final ruleset = const ZiweiRuleset()
    .addModule(const ZiweiJsonRuleModule(
      label: 'school-a',
      starsJson:
          '[{"key":"ziwei","rule":{"type":"constant","value":5}}]',
    ));
final ziwei = context.createZiwei(
  ruleset: ruleset,
  selection: const ZiweiOptionSelection(
    placement: {'ziwei': 'school-a'},
  ),
);

final restored = ruleset.removeModule('school-a');
```

Each module may contain `starsJson`, `brightnessJson`, `sihuaJson`,
`flowJson`, and `mastersJson`. Its label becomes an option name across all of
those components. Labels must be unique and cannot replace bundled option
names. `removeModule()` removes every contribution registered by that user
module; it cannot remove a bundled TOML option. Native compilation happens
during context creation, so the Dart ruleset owns no native handle.
`ZiweiStar.isNatal` distinguishes natal registry entries from flow-only stars.

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
