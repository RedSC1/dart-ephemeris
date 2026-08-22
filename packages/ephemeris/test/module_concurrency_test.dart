import 'dart:isolate';

import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

Future<List<double>> _runModuleWorker(String coreLibraryPath) async {
  final port = ReceivePort();
  await Isolate.spawn(
    _moduleWorkerMain,
    (port.sendPort, coreLibraryPath),
    onError: port.sendPort,
    onExit: port.sendPort,
  );
  try {
    final message = await port.first;
    if (message case ['result', ...final List<Object?> values]) {
      return values.cast<double>();
    }
    if (message case ['error', final Object error, final Object stack]) {
      throw StateError('Module worker failed: $error\n$stack');
    }
    if (message case [final Object error, final Object stack]) {
      throw StateError('Module isolate error: $error\n$stack');
    }
    throw StateError('Module worker exited without a result: $message');
  } finally {
    port.close();
  }
}

void _moduleWorkerMain((SendPort, String) message) {
  final (sendPort, coreLibraryPath) = message;
  EphemerisContext? context;
  try {
    context = Ephemeris.attach(libraryPath: coreLibraryPath).createContext();
    context.configuration.setRouteRule(RouteRule.opm2);

    final position = context.position
        .atTt(
          Body.mercury,
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: const {
            PositionFlag.xyz,
            PositionFlag.speed,
            PositionFlag.truePosition,
          },
        )
        .value;
    final equinox = context.events
        .solarLongitudeAtUt1(0, JulianDate<Ut1Scale>.fromDouble(2460380.5))
        .value;
    final eclipse = context.eclipses
        .solveLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.25),
          options: const {LunarEclipseSolveOption.includeContacts},
        )
        .value;
    final lunar = context.chineseCalendar
        .fromSolar(const SolarDate(year: 2024, month: 2, day: 10))
        .value;

    sendPort.send([
      'result',
      position.values.first,
      equinox.toDouble(),
      eclipse.maximum!.toDouble(),
      lunar.year.toDouble(),
      lunar.month.toDouble(),
      lunar.day.toDouble(),
    ]);
  } catch (error, stack) {
    sendPort.send(['error', '$error', '$stack']);
  } finally {
    context?.close();
  }
}

void main() {
  test(
    'worker isolates run astronomy, events, eclipses, and calendar concurrently',
    () async {
      final runtime = Ephemeris.open(libraryPath: libraryPath);
      runtime.addSourcePath('../taiyin-ephemeris/data');
      final owner = runtime.createContext();
      try {
        final results = await Future.wait([
          for (var worker = 0; worker < 4; worker++)
            _runModuleWorker(libraryPath),
        ]).timeout(const Duration(seconds: 60));

        expect(results, hasLength(4));
        for (final result in results.skip(1)) {
          expect(result, orderedEquals(results.first));
        }
        expect(results.first.every((value) => value.isFinite), isTrue);
        expect(results.first.sublist(3), orderedEquals([2024.0, 1.0, 1.0]));
      } finally {
        owner.close();
      }
    },
    skip: nativeLibraryAvailable ? false : libraryUnavailableSkip,
  );
}
