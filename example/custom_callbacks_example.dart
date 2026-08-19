import 'dart:math' as math;

import 'package:taiyin/taiyin.dart';

/// Three ways to make the C core call back into Dart.
///
/// Ephemeris can ask Dart to supply values for three kinds of pluggable model.
/// Each one is registered process-wide on [Ephemeris], then used like a built-in.
///
/// 1. **Custom target** (`targetId < 0`): a synthetic body whose position /
///    state is computed by a Dart evaluator. It can participate in any
///    position or state calculation alongside the built-in planets.
///
/// 2. **Custom house system** (`modelId >= 10000`): 12 cusp longitudes for a
///    house system of your own devising. Passed as the `system:` argument to
///    the houses calculations.
///
/// 3. **Custom ayanamsha** (`modelId >= 10000`): a sidereal offset computed by
///    Dart. Passed as the `ayanamsha:` argument to the sidereal calculations.
///
/// Run with a path to a built ABI-6 Taiyin shared library:
///
/// ```sh
/// dart run example/custom_callbacks_example.dart ../taiyin-ephemeris/build-bazi/libtaiyin.dylib
/// ```
void main(List<String> arguments) {
  final ephemeris = Ephemeris.open(libraryPath: arguments.firstOrNull);
  final context = ephemeris.createContext();

  // The three registrations. Each is process-wide, so this main isolate owns
  // them; worker isolates see them through the negative / >=10000 IDs alone.
  final comet = ephemeris.registerCustomTarget(
    -42,
    positionEvaluator: _cometPosition,
  );
  final mcEqualHouses = ephemeris.registerCustomHouseSystemModel(
    10001,
    evaluator: _mcEqualHouses,
  );
  final fixedAyanamsha = ephemeris.registerCustomAyanamshaModel(
    10000,
    evaluator: _fixed24DegreeAyanamsha,
  );

  try {
    final jd = JulianDate<TtScale>.fromDouble(2460409.0);

    // 1. Custom target: a synthetic comet in a circular inclined orbit.
    final cometState = context.position.atTt(
      CustomTarget(-42),
      jd,
      flags: const {PositionFlag.xyz, PositionFlag.speed},
    );
    print(
      'comet at AU:      '
      '[${_formatAu(cometState.coordinates)}]  '
      '(${cometState.coordinates.length} values)',
    );

    // The custom target also works in a batch with built-in bodies.
    final bodies = <Target>[Body.sun, CustomTarget(-42)];
    final batch = context.position.batchAtTt(
      bodies,
      jd,
      flags: const {PositionFlag.xyz},
    );
    for (var index = 0; index < bodies.length; index++) {
      print(
        'batch ${bodies[index]}: '
        '[${_formatAu(batch[index].coordinates)}]',
      );
    }

    // 2. Custom house system: equal houses anchored at the midheaven instead
    //    of the ascendant. housesAtTt uses the context observer, so point it
    //    at a location first.
    context.configuration.setObserverLocation(
      const ObserverLocation(
        longitudeDegrees: 116.4074, // Beijing
        latitudeDegrees: 39.9042,
      ),
    );
    final houses = context.astrology.housesAtTt(
      jd,
      system: CustomHouseSystemModel(10001),
    );
    print(
      'custom houses:     '
      '${_formatRadians(houses.cuspLongitudesRadians)} '
      '(system ${houses.resolvedSystemId})',
    );

    // 3. Custom ayanamsha: a fixed 24-degree offset.
    final sidereal = context.astrology.siderealPositionAtTt(
      Body.sun,
      jd,
      ayanamsha: CustomAyanamshaModel(10000),
    );
    print(
      'sun sidereal lon:   ${sidereal.siderealLongitudeRadians.toStringAsFixed(6)} rad '
      '(${_radiansToDms(sidereal.siderealLongitudeRadians)})',
    );
  } finally {
    // Closing releases the Dart callbacks after unregistering the native
    // pointers. Any isolate that still uses these IDs afterward will fail.
    comet.close();
    mcEqualHouses.close();
    fixedAyanamsha.close();
    context.close();
  }
}

/// A comet on a circular orbit, radius 3.5 AU, period 2 years, slight tilt.
///
/// The evaluator runs synchronously inside the native calculation, possibly in
/// a worker isolate, so it and everything it captures must be transitively
/// immutable. The returned list must contain exactly six finite values:
/// components 0–2 are coordinates and 3–5 are their daily rates. The frame and
/// units follow `request.flags` — with `xyz` + `speed`, Cartesian AU and
/// AU/day, matching [PositionFlag] semantics.
List<double> _cometPosition(CustomTargetRequest request) {
  const radiusAu = 3.5;
  const periodDays = 730.5;
  final meanAnomaly =
      2 * math.pi * (request.julianDateTdb.toDouble() - 2451545.0) / periodDays;
  final angularSpeed = 2 * math.pi / periodDays;
  return <double>[
    radiusAu * math.cos(meanAnomaly),
    radiusAu * math.sin(meanAnomaly),
    0.2 * radiusAu * math.sin(meanAnomaly),
    -radiusAu * angularSpeed * math.sin(meanAnomaly),
    radiusAu * angularSpeed * math.cos(meanAnomaly),
    0.2 * radiusAu * angularSpeed * math.cos(meanAnomaly),
  ];
}

/// Equal houses anchored at the midheaven.
///
/// The evaluator receives the rotation already solved by Ephemeris and must
/// return exactly twelve finite cusp longitudes in radians (zero-indexed:
/// index `i` is the cusp of house `i + 1`). Ephemeris applies its normal cusp
/// validation and fallback policy afterward.
List<double> _mcEqualHouses(CustomHouseSystemRequest request) {
  final mc = request.midheavenRadians;
  return <double>[
    for (var house = 0; house < 12; house++)
      (mc + house * math.pi / 6) % (2 * math.pi),
  ];
}

/// A fixed 24-degree ayanamsha, returned in radians.
///
/// The returned value must be finite; Ephemeris normalizes it into `[0, 2π)`
/// before publishing it to the requesting calculation.
double _fixed24DegreeAyanamsha(CustomAyanamshaRequest request) {
  return 24 * math.pi / 180;
}

String _formatAu(List<double> values) =>
    values.map((value) => value.toStringAsFixed(4)).join(', ');

String _formatRadians(List<double> radians) =>
    '[${radians.map(_radiansToDms).join(', ')}]';

String _radiansToDms(double radians) {
  final degrees = (radians * 180 / math.pi) % 360;
  final whole = degrees.floor();
  final minutes = ((degrees - whole) * 60).floor();
  final seconds = ((degrees - whole) * 3600 - minutes * 60).floor();
  return '$whole°$minutes′$seconds″';
}
