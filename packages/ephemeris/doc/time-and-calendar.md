# Time scales and Chinese-calendar policies

Taiyin keeps physical instants and local civil clocks separate. This matters
for EOP-dependent UTC/UT1 conversion and for calendar or divination systems
whose day boundary is configurable.

## Dart `DateTime` and typed Julian dates

`DateTime.toUtcJulianDate()` uses the `DateTime` timezone to identify one
physical UTC instant:

```dart
final utc = DateTime.parse('2003-03-13T14:15:00+08:00').toUtcJulianDate();
final ut1 = context.time.utcToUt1(utc);
final mars = context.position.atUt1(Body.mars, ut1.value);
```

Do not subtract the UTC offset again. For raw numeric values use the explicit
scale aliases such as `UtcJulianDate`, `Ut1JulianDate`, `TtJulianDate`, and
`TdbJulianDate`.

UTC and UT1 are not interchangeable. Automatic UTC/UT1 conversion requires
leap-second and EOP coverage. Strict mode throws `EarthOrientationDataError`
when that information is unavailable. Historical applications can explicitly
allow an estimate:

```dart
context.time.setAllowUtcOutOfRangeEstimate(true);
final utc = context.time.ut1ToUtc(ut1.value);
if (utc.flags.contains(ResultFlag.timeScaleFallback)) {
  print('UTC was estimated outside precise EOP coverage');
}
```

Pure UT1 searches do not require EOP data. Formatting UT1 without converting
its scale is also always available:

```dart
final calendarUt1 = context.time.calendarFromUt1(ut1.value);
```

## Local civil time

`AstroDateTime` is a wall-clock value. It deliberately has no IANA timezone or
DST database attached. A `ChineseCalendarContext` supplies the policy that
maps the wall clock to an instant:

```dart
final local = AstroDateTime(2003, 3, 13, 14, 15);
final instant = context.chineseCalendar.instantFromLocal(local);
final roundTrip = context.chineseCalendar.localTimeFromInstant(instant.value);
```

For zones with DST transitions, resolve ambiguous or nonexistent civil times
in the application before passing a wall clock to Taiyin. A fixed offset does
not model historical timezone rule changes.

## Chinese-calendar modes

The default is China-standard historical calendar rules at UTC+08:00:

```dart
final calendar = context.chineseCalendar;
final lunar = calendar.fromLocal(AstroDateTime(2003, 3, 13, 14, 15));
final pillars = calendar.fourPillarsLocal(
  AstroDateTime(2003, 3, 13, 14, 15),
);
```

Create an independent calendar when another policy is required:

```dart
final localAstronomical = context.createChineseCalendar(
  config: const ChineseCalendarConfig.localAstronomicalUtcOffset(330),
);
final meridianCalendar = context.createChineseCalendar(
  config: const ChineseCalendarConfig.localAstronomicalMeridian(118.582),
);
```

The three structure modes are:

- `chinaStandardHistorical`: historical China-standard rules and exceptional
  month names; this is the default.
- `chinaStandardAstronomical`: China-reference astronomical month structure,
  localized to the configured civil-day offset.
- `localAstronomical`: recompute new-moon/solar-term day assignment under the
  selected local day boundary.

The day boundary is either a fixed UTC offset or a mean-solar meridian. These
are calendar policies, not automatic timezone detection.

## Mean and apparent solar time

For applications that use traditional “true solar time”, calculate local mean
solar time for the longitude and then convert it through Taiyin's solar-time
service:

```dart
final longitudeRadians = 118.582 * 3.141592653589793 / 180;
final mean = LocalMeanSolarTime.fromUt1(
  ut1.value,
  longitudeRadians: longitudeRadians,
);
final apparent = context.solarTime.meanToApparent(mean);
print(apparent.value.coordinate);
```

The apparent correction is calculated from the solar ephemeris rather than a
short seasonal approximation. BaZi or Ziwei receives the resulting local wall
clock explicitly; the original physical instant remains available for solar
terms and other astronomical boundaries.
