# Custom target lifecycle and concurrency

Custom targets bridge process-wide native function pointers to Dart
`NativeCallable` objects. Their lifecycle is therefore stricter than an
ordinary `EphemerisContext`.

## Required operating model

1. Call `Ephemeris.open` once from the application's long-lived main isolate.
2. Register custom targets before starting concurrent calculations.
3. Pass `registration.target` to contexts in the same isolate group, including
   contexts attached by worker isolates.
4. Stop and join all calculations before calling `registration.close()`,
   `clearCustomTargets()`, or `Ephemeris.open` again.
5. Close every registration when it is no longer needed.

Calculations may run concurrently from independent `EphemerisContext` objects.
Registration, unregistration, clearing, and process-wide runtime
reinitialization are setup-time lifecycle changes. They are serialized
internally, but must not overlap a calculation because native code may already
be executing a copied callback pointer.

Do not register or close a target from inside its own evaluator.

## Why registrations have no GC finalizer

The isolate's native-library state strongly retains every active
`CustomTargetRegistration`, and the registration retains its
`NativeCallable` objects. The registration therefore cannot be garbage
collected while native code still owns its callbacks.

This is intentional. Native unregistration is a process-wide setup mutation
and must happen at a deliberate synchronization point, not at an unpredictable
GC finalizer time. Forgetting `close()` leaks the registration and keeps its
isolate alive; it does not silently close the callable and leave a dangling
native pointer.

## Isolates

Create registrations in the long-lived main isolate. Worker isolates should
use `EphemerisContext.attach` and may calculate registered targets, but should not
own process-wide registration lifecycle changes.

The `NativeCallable` objects use the default `keepIsolateAlive = true`.
Consequently, an isolate that owns an active registration cannot exit normally
until the registration is closed or a runtime reset invalidates it.

## Runtime reset and Hot Restart

Every `Ephemeris.open` after the first successful native initialization is a
process-wide reset:

- Native C-owned evaluators are cleared before reinitialization can fail.
- Dart closes and invalidates the registrations known to the current isolate
  after the native initialization attempt, before returning or throwing.
- A failed reset therefore still makes old registration handles report
  `isClosed == true`.
- The first successful initialization preserves C evaluators registered during
  native setup before initialization.

The native lifecycle PR must be merged and shipped before the Dart wrapper
change because the wrapper requires the unregister and clear ABI symbols.

## Borrowed evaluator requests

`CustomTargetRequest` borrows a native context that exists only during
the synchronous evaluator invocation. `positionOf()` checks this dynamic
scope. Saving a request and using it from a later microtask, timer, callback, or
future throws `StateError` before crossing FFI.

Evaluator return values themselves may be retained normally; only the request
and its borrowed dependency operation expire.

Keep evaluator execution synchronous. Do not schedule microtasks, timers, or
other asynchronous work from an isolate-group-bound FFI callback; current Dart
VMs do not provide a normal isolate event-loop context for that callback.

## Target IDs

Custom IDs must fit the native signed 32-bit ABI and be negative:

```text
-2147483648 <= targetId < 0
```

Values outside this range are rejected before FFI so distinct Dart integers
cannot truncate to the same native ID.

## Evaluator and diagnostic behavior

- Evaluator closures and captured values must be transitively immutable.
- Throw `CustomEvaluatorFailure(status)` to return a deliberate native
  status.
- Unexpected evaluator exceptions become `TAIYIN_ERROR_INTERNAL`; the wrapper
  does not print to stderr or impose an application logging policy.
- Custom diagnostics use unknown sentinels for frame, center, and method IDs
  instead of pretending the result is ICRF/SSB.
- `positionOf()` propagates a dependency's failure status but does not expose
  its full diagnostic object through the outer custom-target result.
- `using`/`Arena` allocations in this package use `calloc`; the temporary
  dependency diagnostic is zero-initialized before native code fills it.
