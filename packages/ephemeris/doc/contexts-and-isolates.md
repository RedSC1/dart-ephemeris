# Contexts, isolates, and ownership

## Process-wide runtime and per-user contexts

Call `Ephemeris.open()` once in the main isolate. It initializes global native
data discovery, caches, EOP/lunar-limb resources, and custom registrations.

Create an `EphemerisContext` for each independent user or worker. Its observer,
models, route, time policy, diagnostics, and service facades are independent.

```dart
final runtime = Ephemeris.open();
final first = runtime.createContext();
final second = runtime.createContext();
```

Do not use one mutable context concurrently. Separate contexts can calculate
in parallel.

## Worker isolates

The main isolate initializes the runtime; workers attach without resetting it:

```dart
// Main isolate:
final runtime = Ephemeris.open();

// Worker isolate, after the main setup is complete:
final attached = Ephemeris.attach();
final workerContext = attached.createContext();
```

Pass ordinary Dart inputs and decoded values between isolates. Do not pass
`EphemerisContext`, extension contexts, charts, catalogs, native registration
handles, or other native-backed objects.

## Cached and independent child contexts

These getters cache a default child facade:

```dart
context.chineseCalendar;
context.bazi;  // when ephemeris_bazi is imported
context.ziwei; // when ephemeris_ziwei is imported
```

Use the corresponding factory when a different policy or independently owned
instance is required:

```dart
final calendar = context.createChineseCalendar(
  config: const ChineseCalendarConfig.localAstronomicalUtcOffset(330),
);
final bazi = context.createBazi(calendar: calendar);
final ziwei = context.createZiwei(calendar: calendar);
```

An extension calendar must belong to the same `EphemerisContext`; cross-context
mixing throws before entering native code.

## Cleanup order

Close native children before their borrowed parents:

```dart
try {
  // calculations
} finally {
  ziwei.close();
  bazi.close();
  calendar.close();
  context.close();
}
```

Finalizers are a safety net, not deterministic resource management. Ziwei
charts and caller-owned rule catalogs also have explicit `close()` methods.
