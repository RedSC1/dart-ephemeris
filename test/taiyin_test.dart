import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:taiyin/src/bindings/taiyin_bindings.g.dart';
import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

Future<List<double>> _calculateInWorker(
  String libraryPath,
  int workerIndex,
) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _workerMain,
    (receivePort.sendPort, libraryPath, workerIndex),
    onError: receivePort.sendPort,
    onExit: receivePort.sendPort,
  );
  try {
    final message = await receivePort.first;
    if (message case ['result', ...final List<Object?> values]) {
      return values.cast<double>();
    }
    if (message case ['error', final Object error, final Object stackTrace]) {
      throw StateError('Worker failed: $error\n$stackTrace');
    }
    if (message == null) {
      throw StateError('Worker exited before returning a result.');
    }
    if (message case [final Object error, final Object stackTrace]) {
      throw StateError('Worker isolate error: $error\n$stackTrace');
    }
    throw StateError('Worker returned an unexpected message: $message');
  } finally {
    receivePort.close();
  }
}

Future<List<double>> _calculateCustomTargetInWorker(
  String libraryPath,
  int targetId,
) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _customTargetWorkerMain,
    (receivePort.sendPort, libraryPath, targetId),
    onError: receivePort.sendPort,
    onExit: receivePort.sendPort,
  );
  try {
    final message = await receivePort.first;
    if (message case ['result', ...final List<Object?> values]) {
      return values.cast<double>();
    }
    if (message case ['error', final Object error, final Object stackTrace]) {
      throw StateError('Worker failed: $error\n$stackTrace');
    }
    if (message == null) {
      throw StateError('Worker exited before returning a result.');
    }
    if (message case [final Object error, final Object stackTrace]) {
      throw StateError('Worker isolate error: $error\n$stackTrace');
    }
    throw StateError('Worker returned an unexpected message: $message');
  } finally {
    receivePort.close();
  }
}

void _workerMain((SendPort, String, int) message) {
  final (sendPort, libraryPath, workerIndex) = message;
  TaiyinContext? context;
  try {
    context = TaiyinContext.attach(libraryPath: libraryPath);
    context.configuration.setRouteRule(
      workerIndex.isEven ? TaiyinRouteRule.moshier : TaiyinRouteRule.opm2,
    );
    final result = context.position.atTt(
      TaiyinBody.mercury,
      JulianDate<TtScale>.fromDouble(2460409.0),
      flags: {
        TaiyinPositionFlag.xyz,
        TaiyinPositionFlag.speed,
        TaiyinPositionFlag.truePosition,
      },
    );
    sendPort.send(['result', ...result.value.values]);
  } catch (error, stackTrace) {
    sendPort.send(['error', '$error', '$stackTrace']);
  } finally {
    context?.close();
  }
}

void _customTargetWorkerMain((SendPort, String, int) message) {
  final (sendPort, libraryPath, targetId) = message;
  TaiyinContext? context;
  try {
    context = TaiyinContext.attach(libraryPath: libraryPath);
    final result = context.position.atTt(
      TaiyinCustomTarget(targetId),
      JulianDate<TtScale>.fromDouble(2460409.0),
      flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
    );
    sendPort.send(['result', ...result.value.values]);
  } catch (error, stackTrace) {
    sendPort.send(['error', '$error', '$stackTrace']);
  } finally {
    context?.close();
  }
}

List<double> _customPositionEvaluator(TaiyinCustomTargetRequest request) => [
  request.target.id.toDouble(),
  request.julianDateTdb,
  request.julianDateTt,
  request.hasFlag(TaiyinPositionFlag.xyz) ? 1.0 : 0.0,
  request.flags.contains(TaiyinPositionFlag.speed) ? 1.0 : 0.0,
  0.0,
];

TaiyinCartesianState _customStateEvaluator(TaiyinCustomTargetRequest request) {
  return TaiyinCartesianState(
    positionAu: TaiyinVector3(request.target.id.toDouble(), 2.0, 3.0),
    velocityAuPerDay: const TaiyinVector3(4.0, 5.0, 6.0),
    accelerationAuPerDay2: const TaiyinVector3(7.0, 8.0, 9.0),
  );
}

List<double> _invalidCustomPositionEvaluator(
  TaiyinCustomTargetRequest request,
) => const [1.0];

List<double> _failingCustomPositionEvaluator(
  TaiyinCustomTargetRequest request,
) {
  throw const TaiyinCustomEvaluatorFailure(-1004);
}

List<double> _customSunProxyEvaluator(TaiyinCustomTargetRequest request) {
  return request.positionOf(
    TaiyinBody.sun,
    flags: const {
      TaiyinPositionFlag.xyz,
      TaiyinPositionFlag.speed,
      TaiyinPositionFlag.truePosition,
    },
  );
}

List<double> _selfRecursiveCustomEvaluator(TaiyinCustomTargetRequest request) =>
    request.positionOf(request.target);

List<double> _missingDependencyCustomEvaluator(
  TaiyinCustomTargetRequest request,
) => request.positionOf(TaiyinCustomTarget(-299999));

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();
  final nativeDataPath = '../taiyin-ephemeris/data';

  group(
    'Taiyin native integration',
    () {
      late Taiyin runtime;
      late TaiyinContext taiyin;

      setUp(() {
        runtime = Taiyin.open(libraryPath: libraryPath);
        taiyin = runtime.createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('validates metadata and initializes the catalog', () {
        expect(runtime.abiVersion, 1);
        expect(runtime.libraryVersion, '1.0.0');
        expect(runtime.catalogSize, greaterThan(0));
        expect(
          runtime.availableCapabilities,
          containsAll({
            TaiyinCapability.runtime,
            TaiyinCapability.time,
            TaiyinCapability.splitTime,
            TaiyinCapability.position,
            TaiyinCapability.eclipse,
            TaiyinCapability.astrology,
          }),
        );
        expect(runtime.hasCapability(TaiyinCapability.runtime), isTrue);
        expect(runtime.hasCapability(TaiyinCapability.splitTime), isTrue);
        expect(runtime.hasCapability(TaiyinCapability.position), isTrue);
      });

      test('maps native status metadata', () {
        const invalidArgument = -1;

        expect(
          runtime.statusName(invalidArgument),
          'TAIYIN_ERROR_INVALID_ARGUMENT',
        );
        expect(runtime.statusMessage(invalidArgument), isNotEmpty);
        expect(
          runtime.statusCategory(invalidArgument),
          TaiyinStatusCategory.generic,
        );
        expect(runtime.statusCategory(-1001), TaiyinStatusCategory.ephemeris);
        expect(runtime.statusCategory(-3001), TaiyinStatusCategory.time);
        expect(runtime.statusCategory(-6001), TaiyinStatusCategory.runtime);
      });

      test('calculates a finite Moon state vector', () {
        final position = taiyin.positionTt(
          TaiyinBody.moon,
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
        );

        expect(position.values, hasLength(6));
        expect(position.values, everyElement(isA<double>()));
        expect(position.values.every((value) => value.isFinite), isTrue);
        expect(position.isCartesian, isTrue);
      });

      test('registers and calculates a custom target', () {
        const targetId = -210001;
        final registration = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
        );
        addTearDown(registration.close);
        final target = registration.target;
        final result = taiyin.position.atTdb(
          target,
          JulianDate<TdbScale>.fromDouble(2460409.25),
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
        );

        expect(target, TaiyinCustomTarget(targetId));
        expect(result.value.values[0], targetId.toDouble());
        expect(result.value.values[1], closeTo(2460409.25, 1e-12));
        expect(result.value.values[2], closeTo(2460409.0, 1e-12));
        expect(result.value.values[3], 1.0);
        expect(result.value.values[4], 1.0);
        expect(result.diagnostic.status, 0);
        expect(result.diagnostic.targetId, targetId);
        expect(result.diagnostic.centerId, -1);
        expect(result.diagnostic.frame, TaiyinApparentFrame.unknown);
        expect(result.diagnostic.rawFrameId, -1);
      });

      test('uses an exact custom state evaluator', () {
        const targetId = -210002;
        final registration = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
          stateEvaluator: _customStateEvaluator,
        );
        addTearDown(registration.close);
        final target = registration.target;
        final result = taiyin.position.stateAtTt(
          target,
          JulianDate<TtScale>.fromDouble(2460409.0),
        );

        expect(result.value.positionAu.x, targetId.toDouble());
        expect(result.value.positionAu.y, 2.0);
        expect(result.value.velocityAuPerDay.values, [4.0, 5.0, 6.0]);
        expect(result.value.accelerationAuPerDay2.values, [7.0, 8.0, 9.0]);
        expect(result.diagnostic.targetId, targetId);
      });

      test('custom evaluator can calculate a dependency', () {
        const targetId = -210008;
        final registration = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customSunProxyEvaluator,
        );
        addTearDown(registration.close);
        final target = registration.target;
        final tdb = JulianDate<TdbScale>.fromDouble(2460409.25);
        final tt = JulianDate<TtScale>.fromDouble(2460409.0);
        const flags = {
          TaiyinPositionFlag.xyz,
          TaiyinPositionFlag.speed,
          TaiyinPositionFlag.truePosition,
        };

        final custom = taiyin.position.atTdb(target, tdb, tt, flags: flags);
        final sun = taiyin.position.atTdb(
          TaiyinBody.sun,
          tdb,
          tt,
          flags: flags,
        );

        for (var index = 0; index < 6; index++) {
          expect(
            custom.value.values[index],
            closeTo(sun.value.values[index], 0),
          );
        }
      });

      test('custom target callbacks work from a worker isolate', () async {
        const targetId = -210003;
        final registration = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customSunProxyEvaluator,
        );
        addTearDown(registration.close);

        final values = await _calculateCustomTargetInWorker(
          libraryPath,
          targetId,
        );
        final sun = taiyin.position.atTt(
          TaiyinBody.sun,
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: const {
            TaiyinPositionFlag.xyz,
            TaiyinPositionFlag.speed,
            TaiyinPositionFlag.truePosition,
          },
        );
        for (var index = 0; index < 6; index++) {
          expect(values[index], closeTo(sun.value.values[index], 1e-15));
        }
      });

      test('rejects mutable callback captures and duplicate IDs', () {
        expect(() => TaiyinCustomTarget(0), throwsArgumentError);

        final mutableOffset = <double>[0.25];
        expect(
          () => runtime.registerCustomTarget(
            -210004,
            positionEvaluator: (request) => [
              1.0 + mutableOffset.single,
              2.0,
              3.0,
              0.0,
              0.0,
              0.0,
            ],
          ),
          throwsArgumentError,
        );

        final registration = runtime.registerCustomTarget(
          -210005,
          positionEvaluator: _customPositionEvaluator,
        );
        addTearDown(registration.close);
        expect(
          () => runtime.registerCustomTarget(
            -210005,
            positionEvaluator: _customPositionEvaluator,
          ),
          throwsArgumentError,
        );
      });

      test('maps invalid and deliberate custom evaluator failures', () {
        final invalidRegistration = runtime.registerCustomTarget(
          -210006,
          positionEvaluator: _invalidCustomPositionEvaluator,
        );
        addTearDown(invalidRegistration.close);
        final invalidTarget = invalidRegistration.target;
        expect(
          () => taiyin.position.atTt(
            invalidTarget,
            JulianDate<TtScale>.fromDouble(2460409.0),
          ),
          throwsA(
            isA<TaiyinException>()
                .having((error) => error.status, 'status', -1)
                .having(
                  (error) => error.diagnostic?.targetId,
                  'diagnostic target',
                  invalidTarget.id,
                ),
          ),
        );

        final failingRegistration = runtime.registerCustomTarget(
          -210007,
          positionEvaluator: _failingCustomPositionEvaluator,
        );
        addTearDown(failingRegistration.close);
        final failingTarget = failingRegistration.target;
        expect(
          () => taiyin.position.atTt(
            failingTarget,
            JulianDate<TtScale>.fromDouble(2460409.0),
          ),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.status,
              'status',
              -1004,
            ),
          ),
        );
      });

      test('unregisters, closes, and permits re-registration', () {
        const targetId = -210009;
        final registration = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
        );
        final target = registration.target;

        expect(
          taiyin.position
              .atTt(
                target,
                JulianDate<TtScale>.fromDouble(2460409.0),
                flags: const {TaiyinPositionFlag.xyz},
              )
              .value
              .values[0],
          targetId.toDouble(),
        );

        registration.close();
        expect(registration.isClosed, isTrue);
        expect(registration.close, returnsNormally);
        expect(
          () => taiyin.position.atTt(
            target,
            JulianDate<TtScale>.fromDouble(2460409.0),
          ),
          throwsA(isA<TaiyinException>()),
        );

        final replacement = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
        );
        addTearDown(replacement.close);
        expect(replacement.target, target);
        expect(replacement.isClosed, isFalse);
      });

      test('runtime reset closes existing custom registrations', () {
        const targetId = -210010;
        final registration = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
        );

        final replacementRuntime = Taiyin.open(libraryPath: libraryPath);

        expect(registration.isClosed, isTrue);
        final replacement = replacementRuntime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
        );
        addTearDown(replacement.close);
        expect(replacement.target.id, targetId);
      });

      test('clears all custom registrations explicitly', () {
        final first = runtime.registerCustomTarget(
          -210011,
          positionEvaluator: _customPositionEvaluator,
        );
        final second = runtime.registerCustomTarget(
          -210012,
          positionEvaluator: _customPositionEvaluator,
        );

        runtime.clearCustomTargets();

        expect(first.isClosed, isTrue);
        expect(second.isClosed, isTrue);
        final replacement = runtime.registerCustomTarget(
          -210011,
          positionEvaluator: _customPositionEvaluator,
        );
        addTearDown(replacement.close);
        expect(replacement.isClosed, isFalse);
      });

      test(
        'derives custom state with the native finite-difference fallback',
        () {
          const targetId = -210013;
          final registration = runtime.registerCustomTarget(
            targetId,
            positionEvaluator: _customPositionEvaluator,
          );
          addTearDown(registration.close);

          final result = taiyin.position.stateAtTt(
            registration.target,
            JulianDate<TtScale>.fromDouble(2460409.0),
          );

          expect(result.value.positionAu.x, targetId.toDouble());
          expect(
            [
              ...result.value.positionAu.values,
              ...result.value.velocityAuPerDay.values,
              ...result.value.accelerationAuPerDay2.values,
            ],
            everyElement(
              isA<double>().having((value) => value.isFinite, 'finite', isTrue),
            ),
          );
        },
      );

      test('routes custom targets through UT1, UTC, and mixed batches', () {
        const targetId = -210014;
        final registration = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
        );
        addTearDown(registration.close);
        final target = registration.target;
        final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
        const flags = {TaiyinPositionFlag.xyz};

        final automatic = taiyin.position.atUt1(target, ut1, flags: flags);
        final explicit = taiyin.position.atUt1WithDeltaT(
          target,
          ut1,
          69.0,
          flags: flags,
        );
        final utc = taiyin.position.atUtc(
          target,
          AstroDateTime(2024, 4, 8, 18, 0, 0),
          flags: flags,
        );
        final batch = taiyin.position.batchAtTt(
          [target, TaiyinBody.sun],
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: const {
            TaiyinPositionFlag.xyz,
            TaiyinPositionFlag.truePosition,
          },
        );

        expect(automatic.diagnostic.status, 0);
        expect(explicit.diagnostic.status, 0);
        expect(utc.diagnostic.status, 0);
        expect(
          batch.map((result) => result.diagnostic.status),
          everyElement(0),
        );
        expect(batch.map((result) => result.diagnostic.targetId), [
          targetId,
          TaiyinBody.sun.id,
        ]);
      });

      test('matches native fractional calendar conversion', () {
        final bindings = TaiyinBindings(DynamicLibrary.open(libraryPath));
        final value = AstroDateTime(2026, 7, 19, 12, 34, 56, 123456789);

        using((arena) {
          final nativeCalendar = arena<taiyin_calendar_datetime>();
          final nativeJulianDate = arena<Double>();
          bindings.taiyin_calendar_datetime_init(nativeCalendar);
          nativeCalendar.ref
            ..year = value.year
            ..month = value.month
            ..day = value.day
            ..hour = value.hour
            ..minute = value.minute
            ..second = value.fractionalSecond;

          expect(
            bindings.taiyin_julian_day(nativeCalendar, nativeJulianDate),
            0,
          );
          expect(nativeJulianDate.value, value.toJulianDay());

          final reversed = arena<taiyin_calendar_datetime>();
          bindings.taiyin_calendar_datetime_init(reversed);
          expect(
            bindings.taiyin_reverse_julian_day(
              nativeJulianDate.value,
              reversed,
            ),
            0,
          );
          expect(reversed.ref.second, closeTo(value.fractionalSecond, 0.00005));
        });
      });

      test('clones a context without reinitializing the runtime', () {
        final clone = taiyin.clone();
        try {
          final epoch = JulianDate<TtScale>.fromDouble(2460409.0);
          final original = taiyin.positionTt(TaiyinBody.sun, epoch);
          final copied = clone.positionTt(TaiyinBody.sun, epoch);
          expect(copied.values, original.values);
        } finally {
          clone.close();
        }
      });

      test('worker isolates create independent contexts', () async {
        runtime.addSourcePath(nativeDataPath);
        final results = await Future.wait([
          for (var worker = 0; worker < 4; worker++)
            _calculateInWorker(libraryPath, worker),
        ]);

        expect(results, hasLength(4));
        for (final values in results) {
          expect(values, hasLength(6));
          expect(values.every((value) => value.isFinite), isTrue);
        }
        expect(results[0], results[2]);
        expect(results[1], results[3]);
        expect(results[0], isNot(results[1]));
      });

      test('worker isolate setup failures complete with an error', () async {
        await expectLater(
          _calculateInWorker(
            '${Directory.systemTemp.path}/missing-taiyin-library.dylib',
            0,
          ).timeout(const Duration(seconds: 5)),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('Worker failed'),
            ),
          ),
        );
      });

      test('propagates recursive and missing custom dependencies', () {
        final recursive = runtime.registerCustomTarget(
          -210015,
          positionEvaluator: _selfRecursiveCustomEvaluator,
        );
        final missing = runtime.registerCustomTarget(
          -210016,
          positionEvaluator: _missingDependencyCustomEvaluator,
        );
        addTearDown(recursive.close);
        addTearDown(missing.close);
        final tt = JulianDate<TtScale>.fromDouble(2460409.0);

        expect(
          () => taiyin.position.atTt(recursive.target, tt),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.status,
              'recursive status',
              -3,
            ),
          ),
        );
        expect(
          () => taiyin.position.atTt(missing.target, tt),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.status,
              'missing dependency status',
              -1001,
            ),
          ),
        );
      });

      test('attaches through a preloaded dynamic library', () {
        final attached = TaiyinContext.attachToDynamicLibrary(
          DynamicLibrary.open(libraryPath),
        );
        try {
          expect(
            attached
                .positionTt(
                  TaiyinBody.moon,
                  JulianDate<TtScale>.fromDouble(2460409.0),
                )
                .values,
            everyElement(isA<double>()),
          );
        } finally {
          attached.close();
        }
      });

      test('rejects calls after close', () {
        taiyin.close();
        expect(
          () => taiyin.positionTt(
            TaiyinBody.sun,
            JulianDate<TtScale>.fromDouble(2460409.0),
          ),
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
