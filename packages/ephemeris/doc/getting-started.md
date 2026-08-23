# Getting started

Install the core package:

```sh
dart pub add ephemeris
```

Bundled native modules are loaded automatically on supported macOS arm64,
Linux x64, and Windows x64 systems. Dart Web and Flutter Web are not currently
supported.

## Open once, calculate through a context

```dart
import 'package:ephemeris/ephemeris.dart' as eph;

void main() {
  final runtime = eph.Ephemeris.open();
  final context = runtime.createContext();
  try {
    final ut1 = eph.Ut1JulianDate.fromDouble(2460409.25);
    final result = context.position.atUt1(eph.Body.mars, ut1);

    print(result.value.coordinates);
    print(result.flags.values);
  } finally {
    context.close();
  }
}
```

`Ephemeris` owns process-wide services such as data discovery, caches, EOP
tables, and custom callback registrations. `EphemerisContext` owns one user's
mutable calculation configuration and diagnostic storage.

## Values, flags, and errors

Native operations normally return an `OperationResult<T>` record:

```dart
final (:value, :flags) = context.position.atUt1(eph.Body.moon, ut1);
```

- `value` is the requested result.
- `flags` reports non-fatal execution facts such as a fallback.
- Fatal native statuses throw typed `EphemerisError` subclasses.
- `context.lastDiagnostic` provides richer details for the most recent native
  call on that context; it is supplementary, not a replacement for the
  returned flags or exception.

Use a separate context for concurrent work. Do not share one mutable context
between isolates and do not send native-backed objects across isolate
boundaries.

## Choose the next guide

- Need a normal astronomy calculation? Read [Astronomy workflows](astronomy-workflows.md).
- Starting from Dart `DateTime` or a local civil time? Read [Time and calendar](time-and-calendar.md).
- Supplying OPM2 or JPL kernels? Read [Data and routing](data-and-routing.md).
- Registering your own target or astrology model? Read [Customization](customization.md).
