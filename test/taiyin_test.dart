import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:taiyin/src/bindings/taiyin_bindings.g.dart';
import 'package:taiyin/src/native_compatibility.dart';
import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

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
  EphemerisContext? context;
  try {
    context = EphemerisContext.attach(libraryPath: libraryPath);
    context.configuration.setRouteRule(
      workerIndex.isEven ? RouteRule.semiAnalytic : RouteRule.opm2,
    );
    final result = context.position.atTt(
      Body.mercury,
      JulianDate<TtScale>.fromDouble(2460409.0),
      flags: {PositionFlag.xyz, PositionFlag.speed, PositionFlag.truePosition},
    );
    sendPort.send(['result', ...result.values]);
  } catch (error, stackTrace) {
    sendPort.send(['error', '$error', '$stackTrace']);
  } finally {
    context?.close();
  }
}

void _customTargetWorkerMain((SendPort, String, int) message) {
  final (sendPort, libraryPath, targetId) = message;
  EphemerisContext? context;
  try {
    context = EphemerisContext.attach(libraryPath: libraryPath);
    final result = context.position.atTt(
      CustomTarget(targetId),
      JulianDate<TtScale>.fromDouble(2460409.0),
      flags: {PositionFlag.xyz, PositionFlag.speed},
    );
    sendPort.send(['result', ...result.values]);
  } catch (error, stackTrace) {
    sendPort.send(['error', '$error', '$stackTrace']);
  } finally {
    context?.close();
  }
}

List<double> _customPositionEvaluator(CustomTargetRequest request) => [
  request.target.id.toDouble(),
  request.julianDateTdb.toDouble(),
  request.julianDateTt.toDouble(),
  request.hasFlag(PositionFlag.xyz) ? 1.0 : 0.0,
  request.flags.contains(PositionFlag.speed) ? 1.0 : 0.0,
  0.0,
];

CartesianState _customStateEvaluator(CustomTargetRequest request) {
  return CartesianState(
    positionAu: Vector3(request.target.id.toDouble(), 2.0, 3.0),
    velocityAuPerDay: const Vector3(4.0, 5.0, 6.0),
    accelerationAuPerDay2: const Vector3(7.0, 8.0, 9.0),
  );
}

List<double> _invalidCustomPositionEvaluator(CustomTargetRequest request) =>
    const [1.0];

List<double> _failingCustomPositionEvaluator(CustomTargetRequest request) {
  throw const CustomEvaluatorFailure(-1004);
}

List<double> _customSunProxyEvaluator(CustomTargetRequest request) {
  return request.positionOf(
    Body.sun,
    flags: const {
      PositionFlag.xyz,
      PositionFlag.speed,
      PositionFlag.truePosition,
    },
  );
}

List<double> _selfRecursiveCustomEvaluator(CustomTargetRequest request) =>
    request.positionOf(request.target);

List<double> _missingDependencyCustomEvaluator(CustomTargetRequest request) =>
    request.positionOf(CustomTarget(-299999));

CustomTargetRequest? _callbackSavedRequest;

List<double> _saveCustomRequestEvaluator(CustomTargetRequest request) {
  _callbackSavedRequest = request;
  return _customPositionEvaluator(request);
}

List<double> _useSavedCustomRequestEvaluator(CustomTargetRequest request) {
  final saved = _callbackSavedRequest;
  if (saved == null) return const [2.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  try {
    saved.positionOf(Body.sun);
    return const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  } on StateError {
    return const [1.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  }
}

void main() {
  final nativeDataPath = '../taiyin-ephemeris/data';

  group(
    'Ephemeris native integration',
    () {
      late Ephemeris runtime;
      late EphemerisContext taiyin;

      setUp(() {
        runtime = Ephemeris.open(libraryPath: libraryPath);
        taiyin = runtime.createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('validates metadata and initializes the catalog', () {
        expect(runtime.abiVersion, taiyinSupportedAbiVersion);
        expect(runtime.libraryVersion, '1.0.0-preview.5');
        expect(runtime.catalogSize, greaterThan(0));
        expect(
          runtime.availableCapabilities,
          containsAll({
            Capability.runtime,
            Capability.time,
            Capability.splitTime,
            Capability.position,
            Capability.eclipse,
            Capability.astrology,
          }),
        );
        expect(runtime.hasCapability(Capability.runtime), isTrue);
        expect(runtime.hasCapability(Capability.splitTime), isTrue);
        expect(runtime.hasCapability(Capability.position), isTrue);
      });

      test('maps native status metadata', () {
        const invalidArgument = -1;

        expect(
          runtime.statusName(invalidArgument),
          'TAIYIN_ERROR_INVALID_ARGUMENT',
        );
        expect(runtime.statusMessage(invalidArgument), isNotEmpty);
        expect(runtime.statusCategory(invalidArgument), StatusCategory.generic);
        expect(runtime.statusCategory(-1001), StatusCategory.ephemeris);
        expect(runtime.statusCategory(-3001), StatusCategory.time);
        expect(runtime.statusCategory(-6001), StatusCategory.runtime);
      });

      test('calculates a finite Moon state vector', () {
        final position = taiyin.positionTt(
          Body.moon,
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: {PositionFlag.xyz, PositionFlag.speed},
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
          flags: {PositionFlag.xyz, PositionFlag.speed},
        );

        expect(target, CustomTarget(targetId));
        expect(result.values[0], targetId.toDouble());
        expect(result.values[1], closeTo(2460409.25, 1e-12));
        expect(result.values[2], closeTo(2460409.0, 1e-12));
        expect(result.values[3], 1.0);
        expect(result.values[4], 1.0);
        expect(taiyin.lastDiagnostic?.status, 0);
        expect(taiyin.lastDiagnostic?.targetId, targetId);
        expect(taiyin.lastDiagnostic?.centerId, -1);
        expect(taiyin.lastDiagnostic?.frame, ApparentFrame.unknown);
        expect(taiyin.lastDiagnostic?.rawFrameId, -1);
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

        expect(result.positionAu.x, targetId.toDouble());
        expect(result.positionAu.y, 2.0);
        expect(result.velocityAuPerDay.values, [4.0, 5.0, 6.0]);
        expect(result.accelerationAuPerDay2.values, [7.0, 8.0, 9.0]);
        expect(taiyin.lastDiagnostic?.targetId, targetId);
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
          PositionFlag.xyz,
          PositionFlag.speed,
          PositionFlag.truePosition,
        };

        final custom = taiyin.position.atTdb(target, tdb, tt, flags: flags);
        final sun = taiyin.position.atTdb(Body.sun, tdb, tt, flags: flags);

        for (var index = 0; index < 6; index++) {
          expect(custom.values[index], closeTo(sun.values[index], 0));
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
          Body.sun,
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: const {
            PositionFlag.xyz,
            PositionFlag.speed,
            PositionFlag.truePosition,
          },
        );
        for (var index = 0; index < 6; index++) {
          expect(values[index], closeTo(sun.values[index], 1e-15));
        }
      });

      test('rejects mutable callback captures and duplicate IDs', () {
        expect(() => CustomTarget(0), throwsArgumentError);
        expect(CustomTarget(-0x80000000).id, -0x80000000);
        expect(() => CustomTarget(-0x80000001), throwsArgumentError);
        expect(
          () => runtime.registerCustomTarget(
            -0x80000001,
            positionEvaluator: _customPositionEvaluator,
          ),
          throwsArgumentError,
        );

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
            isA<EphemerisError>()
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
            isA<EphemerisError>().having(
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
                flags: const {PositionFlag.xyz},
              )
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
          throwsA(isA<EphemerisError>()),
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

        final replacementRuntime = Ephemeris.open(libraryPath: libraryPath);

        expect(registration.isClosed, isTrue);
        final replacement = replacementRuntime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
        );
        addTearDown(replacement.close);
        expect(replacement.target.id, targetId);
      });

      test('failed runtime reset also closes existing registrations', () {
        const targetId = -210017;
        final registration = runtime.registerCustomTarget(
          targetId,
          positionEvaluator: _customPositionEvaluator,
        );

        expect(
          () => Ephemeris.open(
            libraryPath: libraryPath,
            options: const RuntimeOptions(
              eopPath: '/__taiyin_missing__/finals2000A.all',
              loadBuiltinEop: false,
            ),
          ),
          throwsA(
            isA<EphemerisError>().having((error) => error.status, 'status', -3),
          ),
        );
        expect(registration.isClosed, isTrue);

        final recoveredRuntime = Ephemeris.open(libraryPath: libraryPath);
        final replacement = recoveredRuntime.registerCustomTarget(
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
        'rejects dependency access after a request escapes its callback',
        () {
          final producer = runtime.registerCustomTarget(
            -210018,
            positionEvaluator: _saveCustomRequestEvaluator,
          );
          final consumer = runtime.registerCustomTarget(
            -210019,
            positionEvaluator: _useSavedCustomRequestEvaluator,
          );
          addTearDown(() {
            _callbackSavedRequest = null;
            consumer.close();
            producer.close();
          });

          taiyin.position.atTt(
            producer.target,
            JulianDate<TtScale>.fromDouble(2460409.0),
          );
          final result = taiyin.position.atTt(
            consumer.target,
            JulianDate<TtScale>.fromDouble(2460409.0),
          );

          expect(result.values[0], 1.0);
        },
      );

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

          expect(result.positionAu.x, targetId.toDouble());
          expect(
            [
              ...result.positionAu.values,
              ...result.velocityAuPerDay.values,
              ...result.accelerationAuPerDay2.values,
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
        const flags = {PositionFlag.xyz};

        taiyin.position.atUt1(target, ut1, flags: flags);
        expect(taiyin.lastDiagnostic?.status, 0);
        taiyin.position.atUt1WithDeltaT(target, ut1, 69.0, flags: flags);
        expect(taiyin.lastDiagnostic?.status, 0);
        taiyin.position.atUtc(
          target,
          AstroDateTime(2024, 4, 8, 18, 0, 0),
          flags: flags,
        );
        expect(taiyin.lastDiagnostic?.status, 0);
        final batch = taiyin.position.batchAtTt(
          [target, Body.sun],
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: const {PositionFlag.xyz, PositionFlag.truePosition},
        );

        expect(taiyin.lastDiagnostic?.status, 0);
        expect(taiyin.lastDiagnostic?.targetId, Body.sun.id);
        expect(batch, hasLength(2));
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
          final original = taiyin.positionTt(Body.sun, epoch);
          final copied = clone.positionTt(Body.sun, epoch);
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
            isA<EphemerisError>().having(
              (error) => error.status,
              'recursive status',
              -3,
            ),
          ),
        );
        expect(
          () => taiyin.position.atTt(missing.target, tt),
          throwsA(
            isA<EphemerisError>().having(
              (error) => error.status,
              'missing dependency status',
              -1001,
            ),
          ),
        );
      });

      test('attaches through a preloaded dynamic library', () {
        final attached = EphemerisContext.attachToDynamicLibrary(
          DynamicLibrary.open(libraryPath),
        );
        try {
          expect(
            attached
                .positionTt(
                  Body.moon,
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
            Body.sun,
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
