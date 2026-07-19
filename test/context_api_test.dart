import 'dart:io';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();

  group(
    'TaiyinContextApi native integration',
    () {
      late Taiyin taiyin;
      const beijing = TaiyinObserverLocation(
        longitudeDegrees: 116.391,
        latitudeDegrees: 39.907,
        heightMeters: 50,
      );
      final tt = JulianDate<TtScale>.fromDouble(2460409.0008);
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final utc = JulianDate<UtcScale>.fromDouble(2458850.25);

      setUp(() {
        taiyin = Taiyin.open(libraryPath: libraryPath);
      });

      tearDown(() {
        taiyin.close();
      });

      test('configures observer and atmosphere values', () {
        taiyin.context
          ..setObserverLocation(beijing)
          ..setAtmosphere(
            const TaiyinAtmosphere(
              pressureMillibars: 1008,
              temperatureCelsius: 23,
              relativeHumidityPercent: 45,
              wavelengthMicrometers: 0.55,
            ),
          )
          ..setAtmospherePressureTemperature(
            pressureMillibars: 1005,
            temperatureCelsius: 20,
          )
          ..setStandardAtmosphere()
          ..setAtmospherePolicy({
            TaiyinAtmospherePolicyFlag.allowStandardFallback,
          })
          ..setMeteorologicalRangeKm(25)
          ..clearObserverLocation();
      });

      test('configures astronomy and apparent models', () {
        taiyin.context
          ..setAstroModels(
            const TaiyinAstroModelConfig(
              precessionModel: TaiyinPrecessionModel.iau2006,
              nutationModel: TaiyinNutationModel.iau2000A,
              frameRoute: TaiyinFrameRoute.equinox,
            ),
          )
          ..setApparentConfig(
            TaiyinApparentConfig(
              flags: const {
                TaiyinApparentFlag.lightTime,
                TaiyinApparentFlag.spherical,
              },
              outputFrame: TaiyinApparentFrame.trueEquatorOfDate,
            ),
          )
          ..setCelestialPoleOffset(dxRadians: 1e-10, dyRadians: -2e-10)
          ..setRefractionModel(TaiyinRefractionModel.sofa)
          ..setHeliacalVisibilityModel(
            TaiyinHeliacalVisibilityModel.schaefer1993,
          )
          ..setEclipseModels(
            shadow: TaiyinEclipseShadowModel.nasaDanjon,
            moonRadius: TaiyinEclipseMoonRadiusModel.almanac,
          );
      });

      test('configures observer modes and route selection', () {
        const zero = TaiyinVector3(0, 0, 0);
        const offset = TaiyinCartesianState(
          positionAu: zero,
          velocityAuPerDay: zero,
          accelerationAuPerDay2: zero,
        );

        taiyin.context
          ..setRouteRule(0)
          ..setGeocentricObserver(
            observerId: TaiyinBody.earth.id,
            centerId: TaiyinBody.earth.id,
          )
          ..setTopocentricObserverOffset(offset)
          ..setSimpleTopocentricObserver(beijing, ut1: ut1, tt: tt)
          ..setPreciseTopocentricObserver(beijing, utc: utc, tt: tt);
      });

      test('configures deflection, light time, and Shapiro delay', () {
        taiyin.context
          ..useSolarDeflector()
          ..clearDeflectors()
          ..setDeflectors(const [
            TaiyinApparentDeflector(bodyId: 10, schwarzschildRadiusAu: 1e-8),
          ], solarDeflectorIndex: 0)
          ..setLightTimeIteration(maxIterations: 6, toleranceDays: 1e-12)
          ..enableShapiroDelay()
          ..disableShapiroDelay()
          ..setDeflectors(const []);
      });

      test('clone keeps configured owned state after original reset', () {
        taiyin.context
          ..setObserverLocation(beijing)
          ..setDeflectors(const [
            TaiyinApparentDeflector(bodyId: 10, schwarzschildRadiusAu: 1e-8),
          ], solarDeflectorIndex: 0);

        final clone = taiyin.clone();
        try {
          taiyin.context.reset();
          final result = clone.position.atTt(
            TaiyinBody.sun,
            tt,
            flags: {TaiyinPositionFlag.xyz},
          );
          expect(
            result.value.coordinates.every((value) => value.isFinite),
            isTrue,
          );
        } finally {
          clone.close();
        }
      });

      test('rejects invalid Dart values before native calls', () {
        expect(
          () => taiyin.context.setObserverLocation(
            const TaiyinObserverLocation(
              longitudeDegrees: 0,
              latitudeDegrees: 91,
            ),
          ),
          throwsRangeError,
        );
        expect(
          () => taiyin.context.setAtmosphere(
            const TaiyinAtmosphere(pressureMillibars: double.nan),
          ),
          throwsArgumentError,
        );
        expect(
          () => taiyin.context.setMeteorologicalRangeKm(0.5),
          throwsRangeError,
        );
        expect(() => taiyin.context.setRouteRule(-1), throwsRangeError);
        expect(
          () => taiyin.context.setGeocentricObserver(
            observerId: 0x80000000,
            centerId: 0,
          ),
          throwsRangeError,
        );
        expect(
          () => taiyin.context.setTopocentricObserverOffset(
            const TaiyinCartesianState(
              positionAu: TaiyinVector3(double.nan, 0, 0),
              velocityAuPerDay: TaiyinVector3(0, 0, 0),
              accelerationAuPerDay2: TaiyinVector3(0, 0, 0),
            ),
          ),
          throwsArgumentError,
        );
        expect(
          () => taiyin.context.setDeflectors(const [
            TaiyinApparentDeflector(bodyId: 10, schwarzschildRadiusAu: -1),
          ]),
          throwsRangeError,
        );
        expect(
          () => taiyin.context.setDeflectors(const [], solarDeflectorIndex: 0),
          throwsRangeError,
        );
        expect(
          () => taiyin.context.setLightTimeIteration(
            maxIterations: -1,
            toleranceDays: 1e-12,
          ),
          throwsRangeError,
        );
        expect(
          () => taiyin.context.setApparentConfig(
            TaiyinApparentConfig(
              flags: const {TaiyinApparentFlag.shapiroDelay},
            ),
          ),
          throwsArgumentError,
        );
      });

      test('exposes stable native model identifiers', () {
        expect(TaiyinAtmospherePolicyFlag.values.map((value) => value.mask), [
          1,
        ]);
        expect(TaiyinPrecessionModel.values.map((value) => value.id), [
          0,
          1,
          2,
          3,
        ]);
        expect(TaiyinNutationModel.values.map((value) => value.id), [0, 1]);
        expect(TaiyinObliquityModel.values.map((value) => value.id), [0]);
        expect(TaiyinFrameRoute.values.map((value) => value.id), [0, 1]);
        expect(TaiyinRefractionModel.values.map((value) => value.id), [
          0,
          1,
          2,
          3,
          4,
        ]);
        expect(TaiyinHeliacalVisibilityModel.values.map((value) => value.id), [
          0,
          1,
        ]);
        expect(TaiyinAberrationModel.values.map((value) => value.id), [0]);
        expect(TaiyinDeflectionModel.values.map((value) => value.id), [0, 1]);
        expect(TaiyinLightTimeMethod.values.map((value) => value.id), [0]);
        expect(TaiyinShapiroDelayModel.values.map((value) => value.id), [0]);
        expect(TaiyinEclipseShadowModel.values.map((value) => value.id), [
          0,
          1,
          2,
          3,
        ]);
        expect(TaiyinEclipseMoonRadiusModel.values.map((value) => value.id), [
          0,
          1,
        ]);
        expect(TaiyinApparentFlag.values.map((value) => value.mask), [
          1,
          4,
          8,
          16,
          32,
          64,
          128,
        ]);
      });

      test('rejects context configuration after close', () {
        taiyin.close();
        final calls = <void Function()>[
          () => taiyin.context.reset(),
          () => taiyin.context.setObserverLocation(beijing),
          () => taiyin.context.setAstroModels(const TaiyinAstroModelConfig()),
          () => taiyin.context.useSolarDeflector(),
        ];

        for (final call in calls) {
          expect(call, throwsStateError);
        }
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
