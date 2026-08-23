# Ephemeris data and route selection

Taiyin can combine OPM2 compressed ephemerides, NASA/JPL BSP/SPK kernels,
TKC1/Kepler files, stellar catalogs, and built-in semi-analytical models.

## Configure data at startup

```dart
final runtime = Ephemeris.open(
  options: const RuntimeOptions(
    dataRoot: '/opt/taiyin-data',
    sourcePaths: [
      '/opt/taiyin-data/de442',
      '/opt/taiyin-data/satellites/jup365.bsp',
    ],
    strictDiscovery: true,
  ),
);
```

`sourcePaths` accepts files or directories. Additional sources can be loaded
during setup:

```dart
runtime.addSourcePath('/data/custom/object.bsp');

for (final source in runtime.registeredDataSources) {
  print('${source.format}: ${source.source}');
}
```

Finish data, EOP, lunar-limb, source-priority, and callback registration before
starting concurrent calculations.

## Select a provider route

Each calculation context has an independent route rule:

```dart
context.configuration.setRouteRule(RouteRule.automatic);
context.configuration.setRouteRule(RouteRule.opm2);
context.configuration.setRouteRule(RouteRule.spk);
context.configuration.setRouteRule(RouteRule.semiAnalytic);
```

`automatic` evaluates the runtime's ordered provider policies and chooses a
compatible route for the requested target, center, epoch, and flags. A
provider-only rule is a hard filter: selecting `RouteRule.spk` will not jump to
an OPM2 file merely because that file has a larger source priority.

## Override priority inside a provider

Source priorities resolve competing files within their provider:

```dart
runtime.setEphemerisSourcePriority('de442.bsp', 200);
runtime.setEphemerisSourcePriority('my_custom_jupiter.bsp', -10);
runtime.clearEphemerisSourcePriority('my_custom_jupiter.bsp');
```

The key may be a registered path or basename. A positive value raises a
source; a negative value places it below defaults. It does not change the
context's provider filter.

## Catalog indexes

When a writable data directory is discovered, Taiyin may maintain an OPC
catalog index next to the data it describes. Treat the index as generated
metadata: distribute a prebuilt index with read-only packaged data, or allow
the runtime to regenerate it in an application-owned writable directory.

## Choosing precision data

The Dart package bundles the native runtime but not a full planetary OPM2 or
SPK archive. Without external data, the semi-analytical route remains useful
over its declared interval. Precision-sensitive work should load an OPM2
product or the corresponding JPL kernels and inspect `registeredDataSources`
at startup. See [Accuracy and data](accuracy-and-data.md) for the meaning of the
published reconstruction figures.
