import 'dart:isolate';
import 'dart:math' as math;

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

double _customAyanamsha(CustomAyanamshaRequest request) => 2 * math.pi + 0.123;

double _throwingCustomAyanamsha(CustomAyanamshaRequest request) =>
    throw StateError('expected callback failure');

List<double> _customHouseCusps(CustomHouseSystemRequest request) {
  const offset = 0.01;
  final step = 2 * math.pi / 12;
  return [
    for (var index = 0; index < 12; index++)
      (request.ascendantRadians + offset + index * step) % (2 * math.pi),
  ];
}

List<double> _invalidCustomHouseCusps(CustomHouseSystemRequest request) =>
    const [0.0];

Future<double> _calculateCustomAyanamshaInWorker(
  String libraryPath,
  int modelId,
) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _customAyanamshaWorkerMain,
    (receivePort.sendPort, libraryPath, modelId),
    onError: receivePort.sendPort,
    onExit: receivePort.sendPort,
  );
  try {
    final message = await receivePort.first;
    if (message is double) return message;
    if (message case ['error', final String error, final String stackTrace]) {
      throw StateError('Worker failed: $error\n$stackTrace');
    }
    if (message == null) {
      throw StateError('Worker exited before returning a result.');
    }
    throw StateError('Worker returned an unexpected message: $message');
  } finally {
    receivePort.close();
  }
}

Future<double> _calculateCustomHouseInWorker(
  String libraryPath,
  int modelId,
) async {
  final receivePort = ReceivePort();
  await Isolate.spawn(
    _customHouseWorkerMain,
    (receivePort.sendPort, libraryPath, modelId),
    onError: receivePort.sendPort,
    onExit: receivePort.sendPort,
  );
  try {
    final message = await receivePort.first;
    if (message is double) return message;
    if (message case ['error', final String error, final String stackTrace]) {
      throw StateError('Worker failed: $error\n$stackTrace');
    }
    if (message == null) {
      throw StateError('Worker exited before returning a result.');
    }
    throw StateError('Worker returned an unexpected message: $message');
  } finally {
    receivePort.close();
  }
}

void _customAyanamshaWorkerMain((SendPort, String, int) message) {
  final (sendPort, libraryPath, modelId) = message;
  EphemerisContext? context;
  try {
    context = EphemerisContext.attach(libraryPath: libraryPath);
    final result = context.astrology.ayanamshaAtTt(
      JulianDate<TtScale>.fromDouble(2460409.0),
      ayanamsha: CustomAyanamshaModel(modelId),
    );
    sendPort.send(result);
  } catch (error, stackTrace) {
    sendPort.send(['error', '$error', '$stackTrace']);
  } finally {
    context?.close();
  }
}

void _customHouseWorkerMain((SendPort, String, int) message) {
  final (sendPort, libraryPath, modelId) = message;
  EphemerisContext? context;
  try {
    context = EphemerisContext.attach(libraryPath: libraryPath);
    final houses = context.astrology.housesFromArmc(
      armcRadians: 1.0,
      observerLatitudeRadians: 0.5,
      trueObliquityRadians: 0.409,
      system: CustomHouseSystemModel(modelId),
    );
    sendPort.send(houses.cuspLongitudesRadians.first);
  } catch (error, stackTrace) {
    sendPort.send(['error', '$error', '$stackTrace']);
  } finally {
    context?.close();
  }
}

void main() {
  group(
    'AstrologyApi native integration',
    () {
      late Ephemeris runtime;
      late EphemerisContext context;
      final tt = JulianDate<TtScale>.fromDouble(2460409.0);
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460311.0);

      setUp(() {
        runtime = Ephemeris.open(libraryPath: libraryPath);
        context = runtime.createContext();
      });

      tearDown(() {
        context.close();
      });

      test('evaluates built-in ayanamshas and exposes their availability', () {
        final fagan = context.astrology.ayanamshaAtTt(
          JulianDate<TtScale>.fromDouble(2433282.42346),
          precessionPolicy: SiderealPrecessionPolicy.useReferencePrecession,
        );
        final lahiri = context.astrology.ayanamshaAtTt(
          JulianDate<TtScale>.fromDouble(2435553.5),
          ayanamsha: Ayanamsha.lahiri,
          precessionPolicy: SiderealPrecessionPolicy.useReferencePrecession,
        );

        // Oracles reflect the native precession fix (2026-08); under
        // useReferencePrecession the reference-epoch value no longer equals
        // the published reference offset exactly.
        expect(fagan * 180 / math.pi, closeTo(24.04112467418854, 1e-9));
        expect(lahiri * 180 / math.pi, closeTo(23.250184940616585, 1e-9));
        for (final ayanamsha in Ayanamsha.values) {
          expect(context.astrology.hasAyanamshaModel(ayanamsha), isTrue);
        }
        for (final system in HouseSystem.values) {
          expect(context.astrology.hasHouseSystemModel(system), isTrue);
        }
      });

      test('registers and closes custom astrology model callbacks', () async {
        final ayanamsha = runtime.registerCustomAyanamshaModel(
          100101,
          evaluator: _customAyanamsha,
          referencePrecessionModel: PrecessionModel.iau2006,
        );
        final houseSystem = runtime.registerCustomHouseSystemModel(
          100101,
          evaluator: _customHouseCusps,
        );
        try {
          expect(context.astrology.hasAyanamshaModel(ayanamsha.model), isTrue);
          expect(
            context.astrology.hasHouseSystemModel(houseSystem.model),
            isTrue,
          );

          // The native precession fix (2026-08) changed the
          // compensateToReference correction applied to custom models, so the
          // published value is no longer exactly the callback's constant.
          expect(
            context.astrology.ayanamshaAtTt(tt, ayanamsha: ayanamsha.model),
            closeTo(0.12297428980664273, 1e-9),
          );
          expect(
            await _calculateCustomAyanamshaInWorker(
              libraryPath,
              ayanamsha.model.id,
            ),
            closeTo(0.12297428980664273, 1e-9),
          );
          final sidereal = context.astrology.siderealPositionAtTt(
            Body.sun,
            tt,
            ayanamsha: ayanamsha.model,
          );
          expect(sidereal.value.ayanamsha, ayanamsha.model);

          final houses = context.astrology.housesFromArmc(
            armcRadians: 1.0,
            observerLatitudeRadians: 0.5,
            trueObliquityRadians: 0.409,
            system: houseSystem.model,
          );
          expect(houses.requestedSystemId, houseSystem.model.id);
          expect(houses.resolvedSystemId, houseSystem.model.id);
          expect(
            houses.cuspLongitudesRadians[0],
            closeTo((houses.ascendantRadians + 0.01) % (2 * math.pi), 1e-15),
          );
          expect(
            await _calculateCustomHouseInWorker(
              libraryPath,
              houseSystem.model.id,
            ),
            closeTo((houses.ascendantRadians + 0.01) % (2 * math.pi), 1e-15),
          );
        } finally {
          houseSystem.close();
          ayanamsha.close();
        }

        expect(houseSystem.isClosed, isTrue);
        expect(ayanamsha.isClosed, isTrue);
        expect(context.astrology.hasAyanamshaModel(ayanamsha.model), isFalse);
        expect(
          context.astrology.hasHouseSystemModel(houseSystem.model),
          isFalse,
        );
      });

      test('rejects mutable custom callback captures', () {
        final mutable = <double>[0.123];
        expect(
          () => runtime.registerCustomAyanamshaModel(
            100104,
            evaluator: (request) => mutable.single,
          ),
          throwsArgumentError,
        );
        expect(
          () => runtime.registerCustomHouseSystemModel(
            100104,
            evaluator: (request) => List<double>.filled(12, mutable.single),
          ),
          throwsArgumentError,
        );
      });

      test('keeps a custom fallback callback alive until dependents close', () {
        final fallback = runtime.registerCustomHouseSystemModel(
          100105,
          evaluator: _customHouseCusps,
        );
        final dependent = runtime.registerCustomHouseSystemModel(
          100106,
          evaluator: _invalidCustomHouseCusps,
          fallback: fallback.model,
        );
        try {
          expect(() => fallback.close(), throwsA(isA<EphemerisError>()));
          expect(fallback.isClosed, isFalse);
          dependent.close();
          fallback.close();
          fallback.close();
          expect(dependent.isClosed, isTrue);
          expect(fallback.isClosed, isTrue);
        } finally {
          dependent.close();
          fallback.close();
        }
      });

      test('returns a native failure when a custom evaluator throws', () {
        final registration = runtime.registerCustomAyanamshaModel(
          100107,
          evaluator: _throwingCustomAyanamsha,
        );
        try {
          expect(
            () => context.astrology.ayanamshaAtTt(
              tt,
              ayanamsha: registration.model,
            ),
            throwsA(isA<EphemerisError>()),
          );
        } finally {
          registration.close();
        }
      });

      test('rejects invalid custom model identifiers', () {
        expect(() => CustomAyanamshaModel(9999), throwsArgumentError);
        expect(() => CustomHouseSystemModel(9999), throwsArgumentError);
      });

      test('clears custom models and applies a custom house fallback', () {
        final fallback = runtime.registerCustomHouseSystemModel(
          100102,
          evaluator: _invalidCustomHouseCusps,
          fallback: HouseSystem.porphyry,
        );
        final ayanamsha = runtime.registerCustomAyanamshaModel(
          100102,
          evaluator: _customAyanamsha,
        );
        try {
          final houses = context.astrology.housesFromArmc(
            armcRadians: 1.0,
            observerLatitudeRadians: 0.5,
            trueObliquityRadians: 0.409,
            system: fallback.model,
          );
          expect(houses.requestedSystemId, fallback.model.id);
          expect(houses.resolvedSystem, HouseSystem.porphyry);
          expect(houses.flags, contains(HouseResultFlag.usedFallback));

          runtime
            ..clearCustomAyanamshaModels()
            ..clearCustomHouseSystemModels();
          expect(ayanamsha.isClosed, isTrue);
          expect(fallback.isClosed, isTrue);
        } finally {
          fallback.close();
          ayanamsha.close();
        }
      });

      test('runtime reset releases custom callback handles', () {
        final ayanamsha = runtime.registerCustomAyanamshaModel(
          100103,
          evaluator: _customAyanamsha,
        );
        final houseSystem = runtime.registerCustomHouseSystemModel(
          100103,
          evaluator: _customHouseCusps,
        );

        Ephemeris.open(libraryPath: libraryPath);

        expect(ayanamsha.isClosed, isTrue);
        expect(houseSystem.isClosed, isTrue);
      });

      test('calculates sidereal ecliptic positions with a diagnostic', () {
        final fromTt = context.astrology.siderealPositionAtTt(
          Body.sun,
          tt,
          ayanamsha: Ayanamsha.lahiri,
          flags: {PositionFlag.speed},
        );
        final fromUt1 = context.astrology.siderealPositionAtUt1(Body.sun, ut1);
        final position = fromTt.value;
        final offset = _normalizeSignedRadians(
          position.tropicalLongitudeRadians - position.siderealLongitudeRadians,
        );

        expect(
          position.flags,
          containsAll({PositionFlag.radians, PositionFlag.speed}),
        );
        expect(
          [
            position.tropicalLongitudeRadians,
            position.siderealLongitudeRadians,
            position.latitudeRadians,
            position.distanceAu,
            position.tropicalLongitudeRateRadiansPerDay,
            position.siderealLongitudeRateRadiansPerDay,
            fromUt1.value.tropicalLongitudeRadians,
          ].every((value) => value.isFinite),
          isTrue,
        );
        expect(
          _normalizeSignedRadians(
            offset -
                context.astrology.ayanamshaAtTt(
                  tt,
                  ayanamsha: Ayanamsha.lahiri,
                ),
          ),
          closeTo(0, 1e-12),
        );
        expect(fromTt.diagnostic.status, 0);
        expect(fromTt.diagnostic.targetId, Body.sun.id);
        expect(fromUt1.diagnostic.status, 0);
        expect(fromUt1.value.tropicalLongitudeRateRadiansPerDay.isNaN, isTrue);
        expect(fromUt1.value.siderealLongitudeRateRadiansPerDay.isNaN, isTrue);
      });

      test('supports generic sidereal ecliptic, equatorial, and XYZ modes', () {
        final structured = context.astrology.siderealPositionAtTt(
          Body.sun,
          tt,
          ayanamsha: Ayanamsha.lahiri,
          flags: {PositionFlag.speed},
        );
        final ecliptic = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          ayanamsha: Ayanamsha.lahiri,
          flags: {PositionFlag.speed},
        );
        final equatorial = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          ayanamsha: Ayanamsha.lahiri,
          flags: {PositionFlag.speed, PositionFlag.equatorial},
        );
        final equatorialXyz = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          ayanamsha: Ayanamsha.lahiri,
          flags: {
            PositionFlag.speed,
            PositionFlag.equatorial,
            PositionFlag.xyz,
          },
        );
        final meanEquatorial = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          ayanamsha: Ayanamsha.lahiri,
          flags: {
            PositionFlag.speed,
            PositionFlag.equatorial,
            PositionFlag.noNutation,
          },
        );
        final faganEquatorial = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          flags: {
            PositionFlag.speed,
            PositionFlag.equatorial,
            PositionFlag.radians,
          },
        );
        final explicitMean = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          ayanamsha: Ayanamsha.lahiri,
          flags: {PositionFlag.noNutation},
        );
        final genericUt1 = context.astrology.siderealCoordinatesAtUt1(
          Body.sun,
          ut1,
          flags: {PositionFlag.xyz},
        );

        expect(
          ecliptic.value.coordinateFrame,
          SiderealCoordinateFrame.meanEclipticOfDate,
        );
        expect(
          equatorial.value.coordinateFrame,
          SiderealCoordinateFrame.trueEquatorOfDate,
        );
        expect(
          equatorialXyz.value.coordinateFrame,
          SiderealCoordinateFrame.trueEquatorOfDate,
        );
        expect(
          meanEquatorial.value.coordinateFrame,
          SiderealCoordinateFrame.meanEquatorOfDate,
        );
        expect(ecliptic.value.isCartesian, isFalse);
        expect(ecliptic.value.isEquatorial, isFalse);
        expect(equatorial.value.isCartesian, isFalse);
        expect(equatorial.value.isEquatorial, isTrue);
        expect(equatorialXyz.value.isCartesian, isTrue);
        expect(equatorialXyz.value.isEquatorial, isTrue);
        expect(
          equatorialXyz.value.flags,
          containsAll({
            PositionFlag.speed,
            PositionFlag.equatorial,
            PositionFlag.xyz,
            PositionFlag.radians,
          }),
        );
        expect(ecliptic.value.values, hasLength(6));
        expect(ecliptic.value.values.every((value) => value.isFinite), isTrue);
        expect(
          ecliptic.value.values[0],
          closeTo(structured.value.siderealLongitudeRadians, 1e-12),
        );
        expect(
          ecliptic.value.values[1],
          closeTo(structured.value.latitudeRadians, 1e-12),
        );
        expect(
          ecliptic.value.values[2],
          closeTo(structured.value.distanceAu, 1e-12),
        );
        expect(
          ecliptic.value.values[3],
          closeTo(structured.value.siderealLongitudeRateRadiansPerDay, 1e-12),
        );

        final nativeTrueEquatorial = context.positionTt(
          Body.sun,
          tt,
          flags: {
            PositionFlag.speed,
            PositionFlag.equatorial,
            PositionFlag.radians,
          },
        );
        final nativeMeanEquatorial = context.positionTt(
          Body.sun,
          tt,
          flags: {
            PositionFlag.speed,
            PositionFlag.equatorial,
            PositionFlag.noNutation,
            PositionFlag.radians,
          },
        );
        for (var index = 0; index < 6; index++) {
          expect(
            equatorial.value.values[index],
            closeTo(nativeTrueEquatorial.values[index], 1e-12),
          );
          expect(
            meanEquatorial.value.values[index],
            closeTo(nativeMeanEquatorial.values[index], 1e-12),
          );
          expect(
            faganEquatorial.value.values[index],
            closeTo(equatorial.value.values[index], 1e-12),
          );
        }

        final xyz = equatorialXyz.value.coordinates;
        final xy = math.sqrt(xyz[0] * xyz[0] + xyz[1] * xyz[1]);
        expect(
          _normalizeRadians(math.atan2(xyz[1], xyz[0])),
          closeTo(equatorial.value.values[0], 1e-12),
        );
        expect(
          math.atan2(xyz[2], xy),
          closeTo(equatorial.value.values[1], 1e-12),
        );
        expect(
          math.sqrt(xy * xy + xyz[2] * xyz[2]),
          closeTo(equatorial.value.values[2], 1e-12),
        );
        expect(
          explicitMean.value.values[0],
          closeTo(
            context.astrology
                .siderealCoordinatesAtTt(
                  Body.sun,
                  tt,
                  ayanamsha: Ayanamsha.lahiri,
                )
                .value
                .values[0],
            1e-12,
          ),
        );
        expect(genericUt1.value.isCartesian, isTrue);
        expect(
          genericUt1.value.values.every((value) => value.isFinite),
          isTrue,
        );
        expect(genericUt1.diagnostic.status, 0);
      });

      test('supports typed sidereal reference planes and epochs', () {
        final j2000Epoch = SiderealReferenceEpoch.tt(
          JulianDate<TtScale>.fromDouble(2451545.0),
        );
        final ut1Epoch = SiderealReferenceEpoch.ut1(ut1);
        final j2000Position = context.astrology.siderealPositionAtTt(
          Body.sun,
          tt,
          referencePlane: SiderealReferencePlane.meanEclipticJ2000,
          flags: {PositionFlag.speed},
        );
        final fixedPosition = context.astrology.siderealPositionAtTt(
          Body.sun,
          tt,
          referencePlane: SiderealReferencePlane.meanEclipticAtEpoch,
          referenceEpoch: j2000Epoch,
          flags: {PositionFlag.speed},
        );
        final invariablePosition = context.astrology.siderealPositionAtTt(
          Body.sun,
          tt,
          referencePlane: SiderealReferencePlane.solarSystemInvariable,
          referenceEpoch: j2000Epoch,
          flags: {PositionFlag.speed},
        );
        final j2000Coordinates = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          referencePlane: SiderealReferencePlane.meanEclipticJ2000,
          flags: {PositionFlag.speed},
        );
        final fixedJ2000 = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          referencePlane: SiderealReferencePlane.meanEclipticAtEpoch,
          referenceEpoch: j2000Epoch,
          flags: {PositionFlag.speed},
        );
        final invariable = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          referencePlane: SiderealReferencePlane.solarSystemInvariable,
          referenceEpoch: j2000Epoch,
        );
        final ut1Fixed = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          referencePlane: SiderealReferencePlane.meanEclipticAtEpoch,
          referenceEpoch: ut1Epoch,
        );
        final ut1FixedPosition = context.astrology.siderealPositionAtUt1(
          Body.sun,
          ut1,
          referencePlane: SiderealReferencePlane.meanEclipticAtEpoch,
          referenceEpoch: j2000Epoch,
          flags: {PositionFlag.speed},
        );
        final ut1FixedCoordinates = context.astrology.siderealCoordinatesAtUt1(
          Body.sun,
          ut1,
          referencePlane: SiderealReferencePlane.meanEclipticAtEpoch,
          referenceEpoch: ut1Epoch,
          flags: {PositionFlag.speed},
        );
        final rawFixed = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          precessionPolicy: SiderealPrecessionPolicy.rawReferenceOffset,
          referencePlane: SiderealReferencePlane.meanEclipticAtEpoch,
          referenceEpoch: j2000Epoch,
        );
        final equatorial = context.astrology.siderealCoordinatesAtTt(
          Body.sun,
          tt,
          referencePlane: SiderealReferencePlane.meanEclipticJ2000,
          flags: {PositionFlag.equatorial, PositionFlag.speed},
        );
        final equatorialWithIgnoredSiderealOptions = context.astrology
            .siderealCoordinatesAtTt(
              Body.sun,
              tt,
              ayanamsha: Ayanamsha.lahiri,
              precessionPolicy: SiderealPrecessionPolicy.useReferencePrecession,
              referencePlane: SiderealReferencePlane.solarSystemInvariable,
              referenceEpoch: j2000Epoch,
              flags: {PositionFlag.equatorial, PositionFlag.speed},
            );

        expect(
          j2000Position.value.coordinateFrame,
          SiderealCoordinateFrame.j2000Ecliptic,
        );
        expect(
          j2000Coordinates.value.coordinateFrame,
          SiderealCoordinateFrame.j2000Ecliptic,
        );
        expect(
          fixedPosition.value.coordinateFrame,
          SiderealCoordinateFrame.fixedMeanEclipticAtEpoch,
        );
        expect(
          invariablePosition.value.coordinateFrame,
          SiderealCoordinateFrame.solarSystemInvariable,
        );
        expect(
          fixedJ2000.value.coordinateFrame,
          SiderealCoordinateFrame.fixedMeanEclipticAtEpoch,
        );
        expect(
          invariable.value.coordinateFrame,
          SiderealCoordinateFrame.solarSystemInvariable,
        );
        expect(
          ut1Fixed.value.coordinateFrame,
          SiderealCoordinateFrame.fixedMeanEclipticAtEpoch,
        );
        expect(
          ut1FixedPosition.value.coordinateFrame,
          SiderealCoordinateFrame.fixedMeanEclipticAtEpoch,
        );
        expect(
          ut1FixedCoordinates.value.coordinateFrame,
          SiderealCoordinateFrame.fixedMeanEclipticAtEpoch,
        );
        expect(
          equatorial.value.coordinateFrame,
          SiderealCoordinateFrame.trueEquatorOfDate,
        );
        expect(
          j2000Position.value.siderealLongitudeRadians,
          closeTo(j2000Coordinates.value.values[0], 1e-12),
        );
        expect(
          fixedJ2000.value.values,
          orderedEquals(
            j2000Coordinates.value.values.map((value) => closeTo(value, 1e-12)),
          ),
        );
        expect(
          invariable.value.values.every((value) => value.isFinite),
          isTrue,
        );
        expect(
          fixedPosition.value.tropicalLongitudeRateRadiansPerDay.isFinite,
          isTrue,
        );
        expect(
          invariablePosition.value.unshiftedLongitudeRateRadiansPerDay.isFinite,
          isTrue,
        );
        expect(
          rawFixed.value.precessionPolicy,
          SiderealPrecessionPolicy.rawReferenceOffset,
        );
        expect(
          rawFixed.value.coordinateFrame,
          SiderealCoordinateFrame.fixedMeanEclipticAtEpoch,
        );
        expect(j2000Position.value.referenceEpoch, isNull);
        expect(fixedPosition.value.referenceEpoch, equals(j2000Epoch));
        expect(invariablePosition.value.referenceEpoch, equals(j2000Epoch));
        expect(fixedJ2000.value.referenceEpoch, equals(j2000Epoch));
        expect(ut1Fixed.value.referenceEpoch, equals(ut1Epoch));
        expect(ut1FixedPosition.value.referenceEpoch, equals(j2000Epoch));
        expect(ut1FixedCoordinates.value.referenceEpoch, equals(ut1Epoch));
        expect(
          j2000Epoch,
          equals(
            SiderealReferenceEpoch.tt(
              JulianDate<TtScale>.fromDouble(2451545.0),
            ),
          ),
        );
        expect(j2000Epoch.toString(), contains('JulianDate'));
        expect(
          equatorialWithIgnoredSiderealOptions.value.values,
          orderedEquals(
            equatorial.value.values.map((value) => closeTo(value, 1e-12)),
          ),
        );

        expect(
          () => context.astrology.siderealCoordinatesAtTt(
            Body.sun,
            tt,
            referencePlane: SiderealReferencePlane.meanEclipticAtEpoch,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.astrology.siderealCoordinatesAtTt(
            Body.sun,
            tt,
            referencePlane: SiderealReferencePlane.meanEclipticJ2000,
            referenceEpoch: j2000Epoch,
          ),
          throwsArgumentError,
        );
      });

      test('calculates lunar nodes and explicit apogee conventions', () {
        final meanFlags = {PositionFlag.noNutation};
        final physicalFlags = {
          PositionFlag.truePosition,
          PositionFlag.noNutation,
        };
        final trueAscending = context.astrology.lunarTrueNodeAtTt(
          tt,
          flags: physicalFlags,
        );
        final trueDescending = context.astrology.lunarTrueNodeAtTt(
          tt,
          kind: LunarNodeKind.descending,
          flags: physicalFlags,
        );
        final trueUt1 = context.astrology.lunarTrueNodeAtUt1(
          ut1,
          flags: physicalFlags,
        );
        final apparentTrueUt1 = context.astrology.lunarTrueNodeAtUt1(
          ut1,
          flags: meanFlags,
        );
        final trueDescendingUt1 = context.astrology.lunarTrueNodeAtUt1(
          ut1,
          kind: LunarNodeKind.descending,
          flags: physicalFlags,
        );
        final meanAscending = context.astrology.lunarMeanNodeAtTt(
          tt,
          flags: meanFlags,
        );
        final meanDescending = context.astrology.lunarMeanNodeAtTt(
          tt,
          kind: LunarNodeKind.descending,
          flags: meanFlags,
        );
        final meanUt1 = context.astrology.lunarMeanNodeAtUt1(
          ut1,
          flags: meanFlags,
        );
        final meanDescendingUt1 = context.astrology.lunarMeanNodeAtUt1(
          ut1,
          kind: LunarNodeKind.descending,
          flags: meanFlags,
        );
        final meanEquatorial = context.astrology.lunarMeanNodeAtTt(
          tt,
          flags: {PositionFlag.equatorial},
        );
        final meanApogee = context.astrology.lunarMeanApogeeAtTt(
          tt,
          flags: meanFlags,
        );
        final meanApogeeUt1 = context.astrology.lunarMeanApogeeAtUt1(
          ut1,
          flags: meanFlags,
        );
        final osculatingApogee = context.astrology.lunarOsculatingApogeeAtTt(
          tt,
          flags: physicalFlags,
        );
        final osculatingApogeeUt1 = context.astrology
            .lunarOsculatingApogeeAtUt1(ut1, flags: physicalFlags);
        final apparentOsculatingApogeeUt1 = context.astrology
            .lunarOsculatingApogeeAtUt1(ut1, flags: meanFlags);
        final fittedApogee = context.astrology.lunarFittedApogeeAtTt(
          JulianDate<TtScale>.fromDouble(2460420.5913274437),
          flags: meanFlags,
        );
        final fittedApogeeUt1 = context.astrology.lunarFittedApogeeAtUt1(
          ut1,
          flags: meanFlags,
        );

        expect(
          trueAscending.value.referenceFrame,
          ApparentFrame.meanEclipticOfDate,
        );
        expect(trueAscending.value.kind, LunarNodeKind.ascending);
        expect(
          _normalizeSignedRadians(
            trueDescending.value.longitudeRadians -
                trueAscending.value.longitudeRadians,
          ).abs(),
          closeTo(math.pi, 1e-13),
        );
        expect(
          trueDescending.value.longitudeRateRadiansPerDay,
          closeTo(trueAscending.value.longitudeRateRadiansPerDay, 1e-14),
        );
        expect(
          trueAscending.value.longitudeRadians * 180 / math.pi,
          closeTo(15.627613595150201, 0.01),
        );
        expect(trueAscending.diagnostic.status, 0);
        expect(trueUt1.value.longitudeRadians.isFinite, isTrue);
        expect(
          _normalizeSignedRadians(
            trueUt1.value.longitudeRadians -
                apparentTrueUt1.value.longitudeRadians,
          ).abs(),
          greaterThan(1e-11),
        );
        expect(
          _normalizeSignedRadians(
            trueDescendingUt1.value.longitudeRadians -
                trueUt1.value.longitudeRadians,
          ).abs(),
          closeTo(math.pi, 1e-13),
        );
        expect(
          trueDescendingUt1.value.longitudeRateRadiansPerDay,
          closeTo(trueUt1.value.longitudeRateRadiansPerDay, 1e-14),
        );

        expect(
          meanAscending.value.referenceFrame,
          ApparentFrame.meanEclipticOfDate,
        );
        expect(
          meanAscending.value.longitudeRadians * 180 / math.pi,
          closeTo(15.662505452962762, 1e-11),
        );
        expect(
          _normalizeSignedRadians(
            meanDescending.value.longitudeRadians -
                meanAscending.value.longitudeRadians,
          ).abs(),
          closeTo(math.pi, 1e-13),
        );
        expect(meanUt1.value.longitudeRadians.isFinite, isTrue);
        expect(
          _normalizeSignedRadians(
            meanDescendingUt1.value.longitudeRadians -
                meanUt1.value.longitudeRadians,
          ).abs(),
          closeTo(math.pi, 1e-13),
        );
        expect(
          meanEquatorial.value.referenceFrame,
          ApparentFrame.trueEquatorOfDate,
        );

        expect(meanApogee.value.definition, LunarApsisDefinition.delaunayMean);
        expect(meanApogee.value.distanceAu, isNull);
        expect(meanApogee.value.distanceRateAuPerDay, isNull);
        expect(
          meanApogee.value.longitudeRadians * 180 / math.pi,
          closeTo(170.92150432407695, 1e-11),
        );
        expect(
          meanApogee.value.latitudeRadians * 180 / math.pi,
          closeTo(2.1582226032549934, 1e-11),
        );
        expect(meanApogeeUt1.value.distanceAu, isNull);

        expect(
          osculatingApogee.value.definition,
          LunarApsisDefinition.osculatingTwoBody,
        );
        expect(osculatingApogee.value.distanceAu, greaterThan(0));
        expect(osculatingApogee.value.distanceRateAuPerDay!.isFinite, isTrue);
        expect(
          osculatingApogee.value.longitudeRadians * 180 / math.pi,
          closeTo(182.7274859203948, 1 / 60),
        );
        expect(osculatingApogeeUt1.value.distanceAu, greaterThan(0));
        expect(
          _normalizeSignedRadians(
            osculatingApogeeUt1.value.longitudeRadians -
                apparentOsculatingApogeeUt1.value.longitudeRadians,
          ).abs(),
          greaterThan(1e-11),
        );

        expect(
          fittedApogee.value.definition,
          LunarApsisDefinition.de441FittedNatural,
        );
        expect(fittedApogee.value.extrapolated, isFalse);
        expect(fittedApogee.value.distanceAu, greaterThan(0));
        expect(
          fittedApogee.value.longitudeRadians,
          closeTo(2.927240809794924, math.pi / 180 / 60),
        );
        expect(fittedApogeeUt1.value.distanceRateAuPerDay!.isFinite, isTrue);
        for (final status in [
          trueUt1.diagnostic.status,
          trueDescendingUt1.diagnostic.status,
          meanUt1.diagnostic.status,
          meanDescendingUt1.diagnostic.status,
          meanApogeeUt1.diagnostic.status,
          osculatingApogeeUt1.diagnostic.status,
          fittedApogeeUt1.diagnostic.status,
        ]) {
          expect(status, 0);
        }

        final extrapolated = context.astrology.lunarFittedApogeeAtTt(
          JulianDate<TtScale>.fromDouble(-3100016.5),
        );
        expect(extrapolated.value.extrapolated, isTrue);
        expect(extrapolated.value.distanceAu, greaterThan(0));
      });

      test('validates lunar-point flag contracts before native calls', () {
        expect(
          () => context.astrology.lunarTrueNodeAtTt(
            tt,
            flags: {PositionFlag.radians},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.astrology.lunarTrueNodeAtTt(
            tt,
            flags: {PositionFlag.topocentric},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.astrology.lunarMeanNodeAtTt(
            tt,
            flags: {PositionFlag.truePosition},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.astrology.lunarFittedApogeeAtTt(
            tt,
            flags: {PositionFlag.noAberration},
          ),
          throwsArgumentError,
        );
      });

      test('calculates and locates houses from a configured observer', () {
        context.configuration.setObserverLocation(
          const ObserverLocation(
            longitudeDegrees: 116.3833,
            latitudeDegrees: 39.9167,
          ),
        );
        final houses = context.astrology.housesAtUt1(ut1);
        final ttFromUt1 = context.time.ut1ToTt(
          ut1,
          deltaTSeconds: context.time.estimatedDeltaTFromUt1(ut1),
        );
        final fromTt = context.astrology.housesAtTt(ttFromUt1);
        final exactCusp = context.astrology.housePositionOf(
          houses,
          houses.cuspLongitudesRadians[4],
        );
        final firstSpan = _normalizeRadians(
          houses.cuspLongitudesRadians[1] - houses.cuspLongitudesRadians[0],
        );
        final midpoint = context.astrology.housePositionOf(
          houses,
          houses.cuspLongitudesRadians[0] + firstSpan / 2,
        );

        expect(houses.requestedSystem, HouseSystem.porphyry);
        expect(houses.resolvedSystem, HouseSystem.porphyry);
        expect(houses.flags, isEmpty);
        expect(
          houses.ascendantRadians * 180 / math.pi,
          closeTo(137.955986373727, 3e-6),
        );
        expect(
          houses.midheavenRadians * 180 / math.pi,
          closeTo(39.424973002554, 3e-6),
        );
        expect(
          houses.cuspLongitudesRadians
              .followedBy(houses.cuspLongitudeRatesRadiansPerDay)
              .every((value) => value.isFinite),
          isTrue,
        );
        expect(
          _normalizeSignedRadians(
            fromTt.ascendantRadians - houses.ascendantRadians,
          ),
          closeTo(0, 1e-9),
        );
        expect(exactCusp.houseNumber, 5);
        expect(exactCusp.fraction, 0);
        expect(exactCusp.continuousHousePosition, 5);
        expect(midpoint.houseNumber, 1);
        expect(midpoint.fraction, closeTo(0.5, 1e-12));
        expect(midpoint.continuousHousePosition, closeTo(1.5, 1e-12));

        final finalSpan = _normalizeRadians(
          houses.cuspLongitudesRadians[0] - houses.cuspLongitudesRadians[11],
        );
        final wrapped = context.astrology.housePositionOf(
          houses,
          houses.cuspLongitudesRadians[11] + finalSpan / 2,
        );
        expect(wrapped.houseNumber, 12);
        expect(wrapped.fraction, closeTo(0.5, 1e-12));
        expect(wrapped.continuousHousePosition, closeTo(12.5, 1e-12));
      });

      test(
        'maps house fallbacks and suppresses discontinuous whole-sign rates',
        () {
          context.configuration.setObserverLocation(
            const ObserverLocation(longitudeDegrees: 0, latitudeDegrees: 70),
          );
          final fallback = context.astrology.housesAtUt1(
            ut1,
            system: HouseSystem.placidus,
          );
          final porphyry = context.astrology.housesAtUt1(
            ut1,
            system: HouseSystem.porphyry,
          );

          expect(fallback.requestedSystem, HouseSystem.placidus);
          expect(fallback.resolvedSystem, HouseSystem.porphyry);
          expect(
            fallback.flags,
            containsAll({
              HouseResultFlag.usedFallback,
              HouseResultFlag.fallbackPorphyry,
            }),
          );
          for (var index = 0; index < 12; index++) {
            expect(
              _normalizeSignedRadians(
                fallback.cuspLongitudesRadians[index] -
                    porphyry.cuspLongitudesRadians[index],
              ),
              closeTo(0, 1e-12),
            );
          }

          final ingress = _findWholeSignIngress(context, ut1);
          expect(ingress.flags, contains(HouseResultFlag.speedUnavailable));
          expect(ingress.armcRateRadiansPerDay.isNaN, isTrue);
          expect(ingress.cuspLongitudeRatesRadiansPerDay[0].isNaN, isTrue);
        },
      );

      test('calculates houses directly from ARMC', () {
        final houses = context.astrology.housesFromArmc(
          armcRadians: 123.456 * math.pi / 180,
          observerLatitudeRadians: 39.9167 * math.pi / 180,
          trueObliquityRadians: 23.436 * math.pi / 180,
          system: HouseSystem.placidus,
        );

        expect(houses.resolvedSystem, HouseSystem.placidus);
        expect(
          houses.cuspLongitudesRadians[0] * 180 / math.pi,
          closeTo(206.656040425304212, 1e-9),
        );
        expect(houses.flags, isEmpty);
        expect(houses.armcRateRadiansPerDay.isNaN, isTrue);
      });

      test(
        'rejects unsupported sidereal coordinate modes and use after close',
        () {
          expect(
            () => context.astrology.housesAtUt1(ut1),
            throwsA(isA<EphemerisError>()),
          );
          expect(
            () => context.astrology.siderealPositionAtTt(
              Body.sun,
              tt,
              flags: {PositionFlag.xyz},
            ),
            throwsArgumentError,
          );
          expect(
            () => context.astrology.housesFromArmc(
              armcRadians: double.nan,
              observerLatitudeRadians: 0,
              trueObliquityRadians: 0,
            ),
            throwsArgumentError,
          );
          expect(
            () => context.astrology.housesFromArmc(
              armcRadians: 0,
              observerLatitudeRadians: math.pi / 2,
              trueObliquityRadians: math.pi / 6,
            ),
            throwsRangeError,
          );
          expect(
            () => context.astrology.housesFromArmc(
              armcRadians: 0,
              observerLatitudeRadians: 0,
              trueObliquityRadians: 0,
            ),
            throwsRangeError,
          );
          expect(
            () => HousePosition(
              houseNumber: 0,
              fraction: 0,
              continuousHousePosition: 0,
            ),
            throwsRangeError,
          );

          context.close();
          expect(() => context.astrology.ayanamshaAtTt(tt), throwsStateError);
          expect(() => context.astrology.housesAtUt1(ut1), throwsStateError);
          expect(
            () => context.astrology.lunarFittedApogeeAtTt(tt),
            throwsStateError,
          );
        },
      );
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}

double _normalizeRadians(double value) {
  final normalized = value % (2 * math.pi);
  return normalized < 0 ? normalized + 2 * math.pi : normalized;
}

double _normalizeSignedRadians(double value) {
  final normalized = _normalizeRadians(value);
  return normalized > math.pi ? normalized - 2 * math.pi : normalized;
}

Houses _findWholeSignIngress(
  EphemerisContext context,
  JulianDate<Ut1Scale> start,
) {
  var lowerJulianDate = start.toDouble();
  var lower = context.astrology.housesAtUt1(
    JulianDate<Ut1Scale>.fromDouble(lowerJulianDate),
    system: HouseSystem.wholeSign,
  );
  var upperJulianDate = double.nan;

  for (var sample = 1; sample <= 288; sample++) {
    final sampleJulianDate = start.toDouble() + sample * 5 / 1440;
    final candidate = context.astrology.housesAtUt1(
      JulianDate<Ut1Scale>.fromDouble(sampleJulianDate),
      system: HouseSystem.wholeSign,
    );
    if (_angularDistance(
          candidate.cuspLongitudesRadians[0],
          lower.cuspLongitudesRadians[0],
        ) >
        math.pi / 180) {
      upperJulianDate = sampleJulianDate;
      break;
    }
    lowerJulianDate = sampleJulianDate;
    lower = candidate;
  }
  if (!upperJulianDate.isFinite) {
    throw StateError('Could not find a Whole Sign cusp ingress.');
  }

  for (var iteration = 0; iteration < 48; iteration++) {
    final middleJulianDate = (lowerJulianDate + upperJulianDate) / 2;
    final middle = context.astrology.housesAtUt1(
      JulianDate<Ut1Scale>.fromDouble(middleJulianDate),
      system: HouseSystem.wholeSign,
    );
    if (_angularDistance(
          middle.cuspLongitudesRadians[0],
          lower.cuspLongitudesRadians[0],
        ) <
        1e-12) {
      lowerJulianDate = middleJulianDate;
      lower = middle;
    } else {
      upperJulianDate = middleJulianDate;
    }
  }
  return context.astrology.housesAtUt1(
    JulianDate<Ut1Scale>.fromDouble((lowerJulianDate + upperJulianDate) / 2),
    system: HouseSystem.wholeSign,
  );
}

double _angularDistance(double left, double right) =>
    _normalizeSignedRadians(left - right).abs();
