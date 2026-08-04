import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  group(
    'TaiyinContextConfiguration native integration',
    () {
      late TaiyinContext taiyin;
      const beijing = TaiyinObserverLocation(
        longitudeDegrees: 116.391,
        latitudeDegrees: 39.907,
        heightMeters: 50,
      );
      final tt = JulianDate<TtScale>.fromDouble(2460409.0008);
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final utc = JulianDate<UtcScale>.fromDouble(2458850.25);
      const zero = TaiyinVector3(0, 0, 0);
      const offset = TaiyinCartesianState(
        positionAu: zero,
        velocityAuPerDay: zero,
        accelerationAuPerDay2: zero,
      );

      setUp(() {
        taiyin = Taiyin.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('configures observer and atmosphere values', () {
        taiyin.configuration
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
        taiyin.configuration
          ..setAstroModels(const TaiyinAstroModelConfig())
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
        taiyin.configuration
          ..setRouteRule(TaiyinRouteRule.automatic)
          ..setGeocentricObserver(
            observerId: TaiyinBody.earth.id,
            centerId: TaiyinBody.earth.id,
          )
          ..setTopocentricObserverOffset(offset)
          ..setSimpleTopocentricObserver(beijing, ut1: ut1, tt: tt)
          ..setPreciseTopocentricObserver(beijing, utc: utc, tt: tt);
      });

      test('configures deflection, light time, and Shapiro delay', () {
        taiyin.configuration
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
        taiyin.configuration
          ..setObserverLocation(beijing)
          ..setTopocentricObserverOffset(offset)
          ..setDeflectors(const [
            TaiyinApparentDeflector(bodyId: 10, schwarzschildRadiusAu: 1e-8),
          ], solarDeflectorIndex: 0)
          ..setApparentConfig(
            TaiyinApparentConfig(
              flags: const {
                TaiyinApparentFlag.lightTime,
                TaiyinApparentFlag.spherical,
                TaiyinApparentFlag.deflection,
              },
            ),
          );

        final clone = taiyin.clone();
        try {
          taiyin.configuration.reset();
          expect(
            () => taiyin.position.atTt(
              TaiyinBody.moon,
              tt,
              flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.topocentric},
            ),
            throwsA(isA<TaiyinException>()),
          );
          final result = clone.position.atTt(
            TaiyinBody.moon,
            tt,
            flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.topocentric},
          );
          expect(
            result.value.coordinates.every((value) => value.isFinite),
            isTrue,
          );
        } finally {
          clone.close();
        }
      });

      test('original and clone lifetimes are independent', () {
        final survivingClone = taiyin.clone();
        taiyin.close();
        try {
          survivingClone.configuration.setStandardAtmosphere();
          expect(
            survivingClone.position
                .atTt(TaiyinBody.sun, tt)
                .value
                .values
                .every((value) => value.isFinite),
            isTrue,
          );
        } finally {
          survivingClone.close();
        }
        expect(() => survivingClone.configuration.reset(), throwsStateError);
      });

      test('closing a clone does not affect the original', () {
        final clone = taiyin.clone()..close();

        expect(() => clone.configuration.reset(), throwsStateError);
        taiyin.configuration.setStandardAtmosphere();
        expect(
          taiyin.position
              .atTt(TaiyinBody.sun, tt)
              .value
              .values
              .every((value) => value.isFinite),
          isTrue,
        );
      });

      test('rejects invalid Dart values before native calls', () {
        expect(
          () => taiyin.configuration.setObserverLocation(
            const TaiyinObserverLocation(
              longitudeDegrees: 0,
              latitudeDegrees: 91,
            ),
          ),
          throwsRangeError,
        );
        expect(
          () => taiyin.configuration.setAtmosphere(
            const TaiyinAtmosphere(pressureMillibars: double.nan),
          ),
          throwsArgumentError,
        );
        expect(
          () => taiyin.configuration.setMeteorologicalRangeKm(0.5),
          throwsRangeError,
        );
        expect(
          () =>
              taiyin.configuration.setRouteRule(const TaiyinRouteRule.raw(-1)),
          throwsA(isA<TaiyinException>()),
        );
        expect(
          () => taiyin.configuration.setGeocentricObserver(
            observerId: 0x80000000,
            centerId: 0,
          ),
          throwsRangeError,
        );
        expect(
          () => taiyin.configuration.setTopocentricObserverOffset(
            const TaiyinCartesianState(
              positionAu: TaiyinVector3(double.nan, 0, 0),
              velocityAuPerDay: TaiyinVector3(0, 0, 0),
              accelerationAuPerDay2: TaiyinVector3(0, 0, 0),
            ),
          ),
          throwsArgumentError,
        );
        expect(
          () => taiyin.configuration.setDeflectors(const [
            TaiyinApparentDeflector(bodyId: 10, schwarzschildRadiusAu: -1),
          ]),
          throwsRangeError,
        );
        expect(
          () => taiyin.configuration.setDeflectors(
            const [],
            solarDeflectorIndex: 0,
          ),
          throwsRangeError,
        );
        expect(
          () => taiyin.configuration.setLightTimeIteration(
            maxIterations: -1,
            toleranceDays: 1e-12,
          ),
          throwsRangeError,
        );
        expect(
          () => taiyin.configuration.setApparentConfig(
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
        expect(
          [
            TaiyinRouteRule.automatic.id,
            TaiyinRouteRule.opm2.id,
            TaiyinRouteRule.spk.id,
            TaiyinRouteRule.semiAnalytic.id,
          ],
          [0, 1, 2, 3],
        );
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
          () => taiyin.configuration.reset(),
          () => taiyin.configuration.setObserverLocation(beijing),
          () => taiyin.configuration.clearObserverLocation(),
          () => taiyin.configuration.setAtmosphere(const TaiyinAtmosphere()),
          () => taiyin.configuration.setAtmospherePressureTemperature(
            pressureMillibars: 1013.25,
            temperatureCelsius: 15,
          ),
          () => taiyin.configuration.setStandardAtmosphere(),
          () => taiyin.configuration.setAtmospherePolicy(const {}),
          () => taiyin.configuration.setMeteorologicalRangeKm(25),
          () => taiyin.configuration.setGeocentricObserver(
            observerId: TaiyinBody.earth.id,
            centerId: TaiyinBody.sun.id,
          ),
          () => taiyin.configuration.setTopocentricObserverOffset(offset),
          () => taiyin.configuration.setSimpleTopocentricObserver(
            beijing,
            ut1: ut1,
            tt: tt,
          ),
          () => taiyin.configuration.setPreciseTopocentricObserver(
            beijing,
            utc: utc,
            tt: tt,
          ),
          () => taiyin.configuration.setRouteRule(TaiyinRouteRule.automatic),
          () => taiyin.configuration.setAstroModels(
            const TaiyinAstroModelConfig(),
          ),
          () => taiyin.configuration.setApparentConfig(TaiyinApparentConfig()),
          () => taiyin.configuration.setCelestialPoleOffset(
            dxRadians: 0,
            dyRadians: 0,
          ),
          () => taiyin.configuration.setRefractionModel(
            TaiyinRefractionModel.sofa,
          ),
          () => taiyin.configuration.setHeliacalVisibilityModel(
            TaiyinHeliacalVisibilityModel.schaefer1993,
          ),
          () => taiyin.configuration.useSolarDeflector(),
          () => taiyin.configuration.clearDeflectors(),
          () => taiyin.configuration.setDeflectors(const []),
          () => taiyin.configuration.setLightTimeIteration(
            maxIterations: 6,
            toleranceDays: 1e-12,
          ),
          () => taiyin.configuration.enableShapiroDelay(),
          () => taiyin.configuration.disableShapiroDelay(),
          () => taiyin.configuration.setEclipseModels(
            shadow: TaiyinEclipseShadowModel.nasaDanjon,
            moonRadius: TaiyinEclipseMoonRadiusModel.almanac,
          ),
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
