# Astronomy workflows

This page maps common tasks to the service exposed by `EphemerisContext`.
Detailed signatures and model types are documented in the generated pub.dev
API reference and the [complete package overview](../README.md).

## Positions and states

```dart
final ut1 = Ut1JulianDate.fromDouble(2460409.25);
final position = context.position.atUt1(Body.mars, ut1);
final state = context.position.stateAtUt1(Body.mars, ut1);
```

The position service supports UTC, UT1, TT, and TDB entry points; explicit
Delta-T; Cartesian/ecliptic flags; rates; physical centers and barycenters;
custom targets; and batch calls. Use typed Julian dates so the scale remains
visible at the call site.

## Observed coordinates and visibility

Configure a terrestrial observer first:

```dart
context.configuration.setObserverLocation(
  const ObserverLocation(
    longitudeDegrees: 118.582,
    latitudeDegrees: 37.449,
  ),
);

final observed = context.observed.atUt1(
  Body.jupiter,
  ut1,
  flags: const {ObservedFlag.topocentric},
);
```

Observed results expose altitude/azimuth-style quantities, so coordinate-only
position flags such as `PositionFlag.xyz` do not apply. Configure atmosphere,
refraction, and topocentric precision through `context.configuration`.

## Events, phenomena, and heliacal visibility

Use `context.events` for longitude crossings, stations, aspects, elongations,
solar transits, and lunar phases. `context.phenomena`, `context.visibility`,
and `context.heliacal` cover angular phenomena, rise/set/transit/twilight, and
heliacal events respectively.

Searches return the same `value`/`flags` shape as direct calculations. Convert
a resulting UT1 instant to UTC only when you actually need UTC output:

```dart
final utc = context.time.utcCalendarFromUt1(eventInstantUt1);
```

## Solar and lunar eclipses

```dart
final solar = context.eclipses.nextSolarAtUt1(ut1);
final lunar = context.eclipses.nextLunarAtUt1(ut1);
```

The eclipse service also exposes fixed-event circumstances, local contacts,
global solar-eclipse routes and map products, lunar contacts, and visibility.
Observer-dependent calls require observer configuration.

## Occultations, stars, and orbits

- `context.occultation`: body/body and body/star occultation searches.
- `runtime.starCatalog` and `context.stars`: catalog loading, lookup, and
  apparent/observed stellar positions.
- `context.orbits`: osculating elements, apsides, nodes, and orbit searches.
- `context.solarTime`: mean/apparent solar-time conversion.

## Western astrology

Sidereal longitude, precession/ayanamsha, house systems, and lunar points are
part of the core package:

```dart
final sidereal = context.astrology.siderealPositionAtUt1(
  Body.sun,
  ut1,
  ayanamsha: Ayanamsha.lahiri,
);
final houses = context.astrology.housesAtUt1(
  ut1,
  system: HouseSystem.porphyry,
);
```

Custom house and ayanamsha callbacks are documented in
[Customization](customization.md).
