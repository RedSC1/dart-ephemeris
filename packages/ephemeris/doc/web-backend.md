# Cross-platform initialization and byte-loaded data (experimental)

Version 1.1.0 adds a **partial experimental Web backend**, not Web support for
the entire native API. Existing native `Ephemeris.open()`, path-based loading,
FFI handles, callbacks, and optional-extension call signatures remain unchanged.
Build and deploy the matching C++ JS/Wasm assets explicitly; they are not
included in the Dart package or downloaded automatically.

## One initialization call on both platforms

```dart
import 'dart:typed_data';
import 'package:ephemeris/ephemeris.dart' as eph;

Future<void> calculate(Map<String, Uint8List> opm2Files) async {
  final runtime = await eph.Ephemeris.initialize(
    wasmModuleUri: Uri.parse('assets/taiyin_web.js'),
  );
  for (final file in opm2Files.entries) {
    runtime.addSourceBytes(file.key, file.value);
  }
  final context = runtime.createContext();
  try {
    final result = context.position.atUt1(
      eph.Body.moon,
      eph.Ut1JulianDate.fromDouble(2460409.25),
      flags: {eph.PositionFlag.speed},
    );
    print(result.value.coordinates);
    print(result.flags.values);
  } finally {
    context.close();
  }
}
```

The caller obtains bytes from its own HTTP client, Flutter asset bundle, file
picker, or another source. No HTTP dependency is imposed by this package.
An empty map uses the built-in semi-analytic routes. Precise geocentric
calculations need their component sources (for example Sun, EMB, and Moon),
not just one arbitrary planetary OPM2 file. Load all required sources first.

Conditional exports select the backend at compilation, including when Dart
itself compiles to Wasm. It is not a per-calculation platform test:

- **Native:** `initialize` delegates to the existing synchronous `open`.
  `libraryPath` still selects a native library; `wasmModuleUri` is ignored.
- **Web:** `initialize` downloads the Emscripten JS loader and instantiates its
  adjacent C++ Wasm binary. `wasmModuleUri` is required. Synchronous `open`
  throws `UnsupportedError`; use the new async entry point.

After initialization, byte registration and the supported calculations are
synchronous. This first backend runs on the calling browser thread, not a
Worker. It does not automatically make long calculations non-blocking.

Initialize once before creating contexts, like native process-wide setup.
Calling initialization again resets global source state; do not do that while
calculations are running. Web `attach()` only attaches within the current
application/realm; native isolate/FFI attachment semantics are unchanged.

## Bytes, ownership, and routing

The same byte-loading APIs work on native and Web:

| Data | Entry point |
| --- | --- |
| OPM2, BSP/SPK, TKC1, TKE1 | `runtime.addSourceBytes(name, bytes)` |
| finals2000A Earth-orientation table | `runtime.loadEopTableBytes(bytes)` |
| TLL1 lunar-limb model | `runtime.loadLunarLimbModelBytes(bytes)` |
| Compiled TSC1 / editable TSF1 star catalogs | `runtime.starCatalog.addTsc1Bytes(bytes)` / `addTsf1Bytes(bytes)` |

The adapters use the existing C++ parsers and routing rules. TKC1/TKE1 retain
their approximate Kepler model; loading them as bytes does not improve their
physical accuracy. Use lowercase `.tkc1` and `.tke1` suffixes to match the core's
discoverers. Native applications retain all existing path-based APIs.

```dart
runtime.addSourceBytes('minor-bodies.tkc1', smallBodyCatalogBytes);
runtime.loadEopTableBytes(finals2000ABytes);
runtime.loadLunarLimbModelBytes(lunarLimbBytes);
runtime.starCatalog.addTsc1Bytes(liteStarCatalogBytes);
```

BSP/SPK is optional, not bundled or downloaded automatically. A byte loader
does not provide streaming: the whole input and additional copies must fit in
the browser/Wasm memory budget (the experimental module has a 1 GiB maximum).
Multi-gigabyte planetary kernels are not a suitable Web deployment. Tests use
a 4 KiB synthetic SPK, not a large downloaded kernel.

OPC is a path-dependent directory cache, not an accepted byte source. A cache
generated on another machine is not a substitute for the underlying data.

Use a basename such as `moon.opm2`, not a directory or URL. Names and OPM2
headers retain their existing routing/provenance meaning. The loader copies
the data; modifying the original `Uint8List` afterwards cannot change it.
Duplicate `addSourceBytes` basenames throw `StateError`; they are never overwritten.
This check is case-insensitive on both platforms, so `sun.opm2` and `SUN.OPM2`
cannot alias and overwrite a file on a case-insensitive native filesystem.
Malformed names or magic bytes fail before registration; the original C++
parser validates the rest of the file.

EOP and lunar-limb `load*Bytes` calls deliberately **replace** their respective
global table/model, just like their existing native path APIs. Failed parsing
retains the previous resource. Existing contexts see the replacement, including
updated EOP-dependent conversions. Star-catalog calls append catalogs; use
`starCatalog.clear()` to explicitly remove them. TSC1 uses the core's existing
copying memory loader; TSF1 and other file readers use backend-owned files.

- Native keeps owned temporary files because the existing parser takes paths.
  They outlive individual contexts. A subsequent runtime initialization cleans
  up unreferenced files; files explicitly reused by the new catalog are retained.
  An interrupted process can leave temporary files for OS cleanup.
- Web keeps owned files in Emscripten's virtual filesystem until runtime reset
  or the page/realm is discarded. Closing a context does not unload sources.

Registration remains setup-time, in the main isolate/application, before
concurrent calculations. The byte loader is not a hot-reload API. Large data
may require more memory than its compressed file size: caller buffers, virtual
files, Wasm allocations, and temporary decoding storage can coexist.

Use `context.configuration.setRouteRule(eph.RouteRule.opm2)` to require OPM2,
or leave AUTO enabled. OPM2-only outside coverage reports the same typed route
error; the Web adapter does not silently substitute a different JS algorithm.

## Build and deploy the Web assets

This is an opt-in source-checkout experiment. It does **not** obtain Wasm from
an undeclared local path, CDN, or a not-yet-published C++ tag at runtime.
Activate the official Emscripten SDK, then from this Dart repository run:

```sh
dart run tool/build_web_backend.dart /path/to/taiyin-ephemeris
```

The C++ checkout must include `experiments/wasm/web_bridge.cpp`. The tool builds
the `taiyin_web` target and writes `taiyin_web.js` and `taiyin_web.wasm` under
the ignored `build/web_backend/` directory. Deploy the pair together, e.g.
under your application's `assets/` URL. Provide that trusted JS loader URL to
`initialize`. Serve Wasm as `application/wasm`; use an HTTP(S) origin and allow
the loader/binary in the application's CSP and CORS policy. Do not weaken
security policy automatically. Load/module/ABI failures are surfaced as errors.

The bridge is version 1, wasm32, and C ABI 11. Result flags and error status are
split inside the C++ adapter; a packed 64-bit result is never converted to a JS
Number. Julian dates retain their split day/fraction representation.

## Implemented Web surface

| Surface | Initial Web backend |
| --- | --- |
| Async initialization; byte registration | OPM2/SPK/BSP/TKC1/TKE1, EOP, TLL1, TSC1/TSF1 |
| Global star catalog | Load bytes, count, clear, magnitude lookup by ID/name/alias; not yet the star-position/observed API |
| Context create, clone, explicit close | Implemented; no native-style finalizer safety net |
| Single-body position and Cartesian state | TT, TDB+TT, UT1, explicit Delta-T, UTC |
| Batch positions | Same five time entry points, target order and per-target diagnostics preserved; up to 100,000 targets per Web call |
| Result records, execution flags, typed errors, last diagnostic | Implemented |
| Configuration | Built-in route IDs, geocentric observer, location metadata, model/frame/apparent options, solar deflector, light-time limits |
| Time service | Calendar/JD, UTC/TAI/TT/UT1/TDB conversions and inverse routes, explicit/automatic time-scale bundles, Delta-T helpers and model/policy selection |
| Chinese calendar | Three calendar modes, fixed-offset/mean-solar day boundaries, solar/lunar conversion, winter-solstice year tables, solar-term searches, month lengths and four pillars |
| Solar time | Equation of time, mean/apparent conversion and nonlinear inverse |
| Eclipses | All 39 public operations: global/local lunar/solar search and circumstances, contacts, Besselian elements/polynomial, route rows/curves/map products and where |
| BaZi | All calculation kernels and local/instant/solar/lunar factories, three chart clocks, Qi-Yun, flows, Si-Ling, relations, built-in/custom Shen Sha |
| Ziwei | Default catalog/reload/snapshots, independent options/JSON modules, natal charts, edits, five flow levels, reverse lookup, physical chart clocks/navigation, manual/index/number/random casting |
| Custom Shen Sha callbacks | Synchronous Dart predicates; snapshot ownership, original exception propagation and reentry/close guards |
| Native paths, FFI handles, other custom native callbacks | Native-only |
| Observed coordinates, star positions, other event/orbital APIs, standalone Ganzhi APIs, Western astrology | Not yet exposed through this Dart Web adapter |
| Worker/isolate orchestration | Not implemented for Web |

This matrix describes the actual Dart wrappers, tested in a browser, not just
the lower-level C++ probe. Unsupported APIs are not advertised as working.
Public pure-data models remain importable; native functionality is not removed
or replaced.

## Internal backend boundary

The position module now uses **one shared public `PositionApi`**, not two
platform-specific copies of the public API:

```text
PositionApi (validation, immutable results, batch error selection)
    └─ PositionBackend (typed Dart inputs and BackendCall<T> outputs)
        ├─ NativePositionBackend → FFI → original C ABI
        └─ WebPositionBackend → Wasm transport → original C ABI
```

The public facade imports neither `dart:ffi` nor JS interop. Backend results
contain owned Dart values, status, flags, and diagnostics; no pointer, arena,
Wasm address, or memory view crosses this boundary. Native allocation/free and
Wasm memory-growth handling stay in their respective adapters. Batch calls
still use the C++ batch entry points, rather than looping over single calls.

Existing public position method names, parameters, result records, and typed
failure behavior are retained. Contexts still own their calculation state;
there is no new process-global calculation context or algorithm dispatch DSL.
This separation is implemented for positions, star-catalog management, time,
Chinese calendar, solar time, eclipses and the two optional extensions. A shared calendar base owns all calculation
and convenience methods; thin native/Web subclasses retain the platform-specific
owner and extension-host types. BaZi shares its public calculation orchestration;
Ziwei shares public chart/catalog contracts and date/clock orchestration.
The native/Web adapters perform resource handling and call the original C ABI;
neither contains another implementation of placement or astronomical algorithms.

## Calendar and time example

After the asynchronous initialization above, native and Web accept the same calls:

```dart
final context = runtime.createContext();
final calendar = context.createChineseCalendar(
  config: const eph.ChineseCalendarConfig.localAstronomicalUtcOffset(420),
);
try {
  final local = eph.AstroDateTime(2003, 3, 13, 14, 15);
  final lunar = calendar.fromLocal(local);
  final pillars = calendar.fourPillarsLocal(local);
  final utc = calendar.instantFromLocal(local);
  final utcClock = context.time.reverseJulianDay(utc.value).value;
  print(lunar.value);
  print(pillars.value);
  print(context.time.scalesFromUtc(utcClock).value);
  print(calendar.localTimeFromInstant(utc.value).value);
} finally {
  calendar.close();
  context.close();
}
```

`instantFromLocal` uses the calendar's configured civil-clock offset. A
mean-solar calendar meridian affects assignment of new moons and solar terms
to dates, not the legal-clock-to-UTC conversion. It is not apparent solar time.
Merely labeling local fields as UTC performs no time-zone conversion.
Automatic time conversion remains strict without EOP; estimation still requires
the explicit opt-in below. Leap-second representation and inverse-convergence
exceptions are shared with native.

Closing the astronomy context closes all its calendars. Closing a calendar is
idempotent, and the next `context.chineseCalendar` access creates a fresh cached
default if the previous one was closed.

UTC calculations continue to use the C++ time policy. Missing EOP is an
`EarthOrientationDataError` unless the caller explicitly enables:

```dart
context.time.setAllowUtcOutOfRangeEstimate(true);
```

Estimated calls report `ResultFlag.timeScaleFallback`. UT1 inputs do not need
that UTC estimate switch. Do not relabel UTC as UT1 merely to avoid an error.

## Eclipses, BaZi and Ziwei

After the same initialization, eclipse calls retain their existing signatures:

```dart
final next = context.eclipses.nextLunarAtUt1(
  eph.Ut1JulianDate.fromDouble(2460925.5),
  options: {eph.LunarEclipseSearchOption.includeContacts},
);
print(next.value.maximum);
print(next.flags.values);
```

Local circumstances need the observer location in `context.configuration`, just
as native. TT/UT1 inputs retain their actual scales. Route/map arrays and all
other results are copied; later calls or Wasm memory growth cannot change an
already returned snapshot. Web variable-length eclipse/reverse-search results
are bounded to one million entries per call to avoid unbounded allocations.

Import each optional extension normally:

```dart
import 'package:ephemeris_bazi/ephemeris_bazi.dart';
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';

final local = eph.AstroDateTime(2003, 3, 13, 14, 15);
final bazi = context.bazi;
final ziwei = context.ziwei;
final natal = ziwei.calculateLocal(local, gender: ZiweiGender.male).value;
try {
  print(bazi.calculateLocal(local, gender: BaziGender.male).value.pillars);
  print(natal.palace(ZiweiPalace.life).stars.map((star) => star.key));
  final now = context.chineseCalendar.instantFromLocal(local).value;
  print(natal.setFlow(targetInstantUtc: now, targetVirtualTime: local).value);
} finally {
  natal.close();
  ziwei.close();
  bazi.close();
}
```

`createBazi(calendar: ...)` and `createZiwei(calendar: ...)` borrow a calendar
from the same astronomy context. Closing the calendar or owner invalidates
astronomy-dependent calls; closing an extension does not close a caller-owned
calendar/catalog. Pure BaZi calculations still work after the astronomy owner
closes, matching native. Ziwei charts remain bound to their Ziwei context.
Web has no native finalizer safety net: explicitly close charts, contexts and
catalogs when finished. Closing them is idempotent and remains safe after the
borrowed owner closes.

The opt-in Web build links the C++ BaZi and Ziwei modules into the **same Wasm
instance** as the core. It does not load native DLLs, nor run a second set of
rules in Dart. The six default Ziwei TOML files are embedded at
`/taiyin/ziwei/rules/`; `ZiweiDataCatalog()` loads that profile once and contexts
retain compiled snapshots. Reload advances the catalog generation without
mutating existing contexts. Host OS `profilePath`/library paths cannot be used
in a browser. For portable customizations use `ZiweiRuleset` JSON modules and
`ZiweiOptionSelection`; label conflicts and attempts to replace bundled options
retain the core's errors. No extra TOML upload or bulk URL loader is introduced.

Fixed-offset, mean-solar and apparent-solar **chart clocks** are distinct from
the calendar's new-moon/solar-term day boundary. Apparent-clock inversion,
slot navigation and reverse lookup continue to use the C++ nonlinear solver;
there is no fixed equation-of-time approximation or implicit UTC fallback.
Random casting uses the C++ random interface backed by browser cryptographic
randomness, not `Math.random`.

Custom `BaziShenShaCatalog` predicates execute synchronously on the calling
browser thread. Derived catalog/context snapshots retain their predicates;
closing a source catalog does not invalidate them. Throwing a predicate error
rethrows the original Dart exception. Reentry into a context sharing active
callbacks and closing a context during its evaluation are rejected. Other
native callback categories remain outside this Web surface.

## Reproduce the end-to-end test

Build modular native core, BaZi and Ziwei C ABI 11 libraries and the Web target
from the same core checkout. Use the public tag `v1.1.0` in
[`RedSC1/taiyin-ephemeris`](https://github.com/RedSC1/taiyin-ephemeris).
Keep the native and Web source versions aligned. Set `TAIYIN_BAZI_LIBRARY_PATH` and
`TAIYIN_ZIWEI_LIBRARY_PATH` to those newly built modules, not stale bundled
binaries. Use `-ffp-contract=off` for this numerical comparison.
Generate the reference, then compile the **same Dart API scenario** for both
browser compilation modes:

```sh
dart run tool/native_backend_reference.dart \
  /path/to/native/library /path/to/de442-opm2 build/web_backend/native-reference.json
dart compile js tool/web_backend_smoke.dart -O2 -o build/web_backend/main.dart.js
dart compile wasm tool/web_backend_smoke.dart -o build/web_backend/smoke.wasm
dart run tool/serve_web_backend.dart build/web_backend /path/to/de442-opm2
```

Open the printed loopback URLs (`index.html`, `dart-wasm.html`). The test server
exposes only generated assets, the reference JSON, eleven named OPM2 files,
and explicitly named TKC1/TSC1 test catalogs. Other small fixtures are generated
by the shared Dart test code.
It does not serve the repository/private tree.

On 2026-10-18, both modes passed: 1,255 native/Web numerical rows,
maximum mixed-component difference `6.49e-9`, plus parser rejection, duplicate
handling, source-buffer ownership, missing-EOP error/estimate flags, failed-loader
retry, default initialization/built-in EOP, clone isolation, batch/single agreement,
atomic batch failure with per-target diagnostics, and use-after-close checks. This is a portability test,
not a new absolute-accuracy bound or a full browser/platform certification.
The byte-loading tests also perform actual TKC1/TKE1/SPK calculations, EOP
replacement/clear using an existing context, TLL1 replacement/clear, and
TSC1/TSF1 ownership and Unicode name/alias queries.
The native core and optional BaZi/Ziwei integration suites passed 339 tests;
two opt-in stress matrices were skipped. Browser reset also verifies that old
owned files are not rediscovered as packaged ephemeris data.
The time/calendar rows cover both TDB models, strict/estimated/reverse
UTC routes, all three calendar modes, terms/moons/months in the computed
year, all six neighboring-term searches, three rat-hour rules, reform-era month
metadata, UTC+7 versus 105°E, cached calendars and owner-driven cleanup. These
are backend-equivalence tests, not an independent historical-calendar oracle.
Rechecked on 2026-10-19 against the reviewed implementation: both browser
compilers passed the same 1,255 rows (maximum mixed-component difference
`6.4823e-9`), and the three-package native suite passed 337 tests with four
conditional tests skipped. The browser reference used the monolithic C ABI
library with all three modules and `-ffp-contract=off`; a modular native build
must use that same floating-point setting for this strict comparison.
The eclipse scenario calls all 39 public operations, including high-bit option
masks, optional contacts, both search directions, routes and map products.
The bridge is compiled with C++ exception catching enabled. Separate truncated
BaZi/Ziwei transport requests must return `InvalidArgumentError`, after which
ordinary calculations must still succeed (rather than aborting the instance).
BaZi exercises all kernels, three chart clocks and custom predicate snapshots,
disabled/removed rules, exceptions and reentry guards. Ziwei covers every Web
operation, all three chart clocks/rat-hour rules, all five flow levels, 2033
leap-eleventh/ordinary-twelfth months, reform-era dates, explicit reverse search,
independent JSON options, edits, casting and close behavior.

The comparison is unit-aware: eclipse seconds/kilometers and chart-clock
fractional seconds are scaled in the test snapshots (see the scenario helpers).
The maximum above mixes many components and is **not** an angular accuracy or
event-time accuracy claim. Integer IDs, options, masks, result shapes and result
flags are compared exactly; random-casting results are range-checked, not
expected to be the same draw on two platforms.
