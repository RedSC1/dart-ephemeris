# Customization

Taiyin supports both ordinary context configuration and process-wide Dart
callbacks. The runnable example
[`custom_callbacks_example.dart`](../example/custom_callbacks_example.dart)
demonstrates all three callback families together.

## Custom targets

Register a negative target ID and provide its position evaluator:

```dart
final registration = runtime.registerCustomTarget(
  -42,
  positionEvaluator: (request) => <double>[
    1, 0, 0, // position
    0, 0, 0, // rate
  ],
);

final result = context.position.atTt(
  const CustomTarget(-42),
  TtJulianDate.fromDouble(2460409.0),
  flags: const {PositionFlag.xyz, PositionFlag.speed},
);
```

Supply `stateEvaluator` as well when an exact Cartesian state is available;
otherwise the native runtime may use its finite-difference fallback.

## Custom house systems and ayanamsha models

Custom astrology model IDs start at 10000:

```dart
final house = runtime.registerCustomHouseSystemModel(
  10001,
  evaluator: myHouseEvaluator,
  fallback: HouseSystem.porphyry,
);
final ayanamsha = runtime.registerCustomAyanamshaModel(
  10000,
  evaluator: myAyanamshaEvaluator,
);
```

Select the registered IDs with `CustomHouseSystemModel(10001)` and
`CustomAyanamshaModel(10000)` in the normal astrology calls. See the runnable
example for complete evaluator signatures and result shapes.

## Callback ownership and isolates

Callbacks are process-wide native registrations. Register them once in the
long-lived main isolate before workers start. The callback and everything it
captures must be transitively immutable because calculations from worker
isolates may invoke it.

Keep every registration handle alive. Close dependent registrations first,
then fallbacks, after all worker calculations have stopped:

```dart
try {
  // Run calculations.
} finally {
  house.close();
  ayanamsha.close();
  registration.close();
}
```

See [Custom callback lifecycle](custom-target-lifecycle.md) for re-entry,
failure, replacement, and shutdown rules.

## Context-level models

No callback is needed for normal model selection. `context.configuration`
supports:

- geocentric and simple/precise topocentric observers;
- observer location and atmosphere;
- precession, nutation, obliquity, frame, and apparent-position models;
- light-time and Shapiro-delay policies;
- built-in solar or caller-supplied gravitational deflectors;
- refraction, heliacal visibility, and eclipse shadow/radius models;
- provider route rules.

Example:

```dart
context.configuration
  ..setObserverLocation(
    const ObserverLocation(
      longitudeDegrees: 118.582,
      latitudeDegrees: 37.449,
    ),
  )
  ..setApparentConfig(const ApparentConfig())
  ..useSolarDeflector();
```

Treat configuration as setup: do not mutate a context while another operation
is using it.
