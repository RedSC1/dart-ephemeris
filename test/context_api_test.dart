import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  group(
    'ContextConfiguration native integration',
    () {
      late EphemerisContext taiyin;
      const beijing = ObserverLocation(
        longitudeDegrees: 116.391,
        latitudeDegrees: 39.907,
        heightMeters: 50,
      );
      final tt = JulianDate<TtScale>.fromDouble(2460409.0008);
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final utc = JulianDate<UtcScale>.fromDouble(2458850.25);
      const zero = Vector3(0, 0, 0);
      const offset = CartesianState(
        positionAu: zero,
        velocityAuPerDay: zero,
        accelerationAuPerDay2: zero,
      );

      setUp(() {
        taiyin = Ephemeris.open(libraryPath: libraryPath).createContext();
      });

      tearDown(() {
        taiyin.close();
      });

      test('configures observer and atmosphere values', () {
        taiyin.configuration
          ..setObserverLocation(beijing)
          ..setAtmosphere(
            const Atmosphere(
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
          ..setAtmospherePolicy({AtmospherePolicyFlag.allowStandardFallback})
          ..setMeteorologicalRangeKm(25)
          ..clearObserverLocation();
      });

      test('configures astronomy and apparent models', () {
        taiyin.configuration
          ..setAstroModels(const AstroModelConfig())
          ..setAstroModels(
            const AstroModelConfig(
              precessionModel: PrecessionModel.iau2006,
              nutationModel: NutationModel.iau2000A,
              frameRoute: FrameRoute.equinox,
            ),
          )
          ..setApparentConfig(
            ApparentConfig(
              flags: const {ApparentFlag.lightTime, ApparentFlag.spherical},
              outputFrame: ApparentFrame.trueEquatorOfDate,
            ),
          )
          ..setCelestialPoleOffset(dxRadians: 1e-10, dyRadians: -2e-10)
          ..setRefractionModel(RefractionModel.sofa)
          ..setHeliacalVisibilityModel(HeliacalVisibilityModel.schaefer1993)
          ..setEclipseModels(
            shadow: EclipseShadowModel.nasaDanjon,
            moonRadius: EclipseMoonRadiusModel.almanac,
          );
      });

      test('configures observer modes and route selection', () {
        taiyin.configuration
          ..setRouteRule(RouteRule.automatic)
          ..setGeocentricObserver(
            observerId: Body.earth.id,
            centerId: Body.earth.id,
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
            ApparentDeflector(bodyId: 10, schwarzschildRadiusAu: 1e-8),
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
            ApparentDeflector(bodyId: 10, schwarzschildRadiusAu: 1e-8),
          ], solarDeflectorIndex: 0)
          ..setApparentConfig(
            ApparentConfig(
              flags: const {
                ApparentFlag.lightTime,
                ApparentFlag.spherical,
                ApparentFlag.deflection,
              },
            ),
          );

        final clone = taiyin.clone();
        try {
          taiyin.configuration.reset();
          expect(
            () => taiyin.position.atTt(
              Body.moon,
              tt,
              flags: {PositionFlag.xyz, PositionFlag.topocentric},
            ),
            throwsA(isA<EphemerisError>()),
          );
          final result = clone.position.atTt(
            Body.moon,
            tt,
            flags: {PositionFlag.xyz, PositionFlag.topocentric},
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
                .atTt(Body.sun, tt)
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
              .atTt(Body.sun, tt)
              .value
              .values
              .every((value) => value.isFinite),
          isTrue,
        );
      });

      test('rejects invalid Dart values before native calls', () {
        expect(
          () => taiyin.configuration.setObserverLocation(
            const ObserverLocation(longitudeDegrees: 0, latitudeDegrees: 91),
          ),
          throwsRangeError,
        );
        expect(
          () => taiyin.configuration.setAtmosphere(
            const Atmosphere(pressureMillibars: double.nan),
          ),
          throwsArgumentError,
        );
        expect(
          () => taiyin.configuration.setMeteorologicalRangeKm(0.5),
          throwsRangeError,
        );
        expect(
          () => taiyin.configuration.setRouteRule(const RouteRule.raw(-1)),
          throwsA(isA<EphemerisError>()),
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
            const CartesianState(
              positionAu: Vector3(double.nan, 0, 0),
              velocityAuPerDay: Vector3(0, 0, 0),
              accelerationAuPerDay2: Vector3(0, 0, 0),
            ),
          ),
          throwsArgumentError,
        );
        expect(
          () => taiyin.configuration.setDeflectors(const [
            ApparentDeflector(bodyId: 10, schwarzschildRadiusAu: -1),
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
            ApparentConfig(flags: const {ApparentFlag.shapiroDelay}),
          ),
          throwsArgumentError,
        );
      });

      test('exposes stable native model identifiers', () {
        expect(AtmospherePolicyFlag.values.map((value) => value.mask), [1]);
        expect(PrecessionModel.values.map((value) => value.id), [0, 1, 2, 3]);
        expect(NutationModel.values.map((value) => value.id), [0, 1]);
        expect(ObliquityModel.values.map((value) => value.id), [0]);
        expect(FrameRoute.values.map((value) => value.id), [0, 1]);
        expect(
          [
            RouteRule.automatic.id,
            RouteRule.opm2.id,
            RouteRule.spk.id,
            RouteRule.semiAnalytic.id,
          ],
          [0, 1, 2, 3],
        );
        expect(RefractionModel.values.map((value) => value.id), [
          0,
          1,
          2,
          3,
          4,
        ]);
        expect(HeliacalVisibilityModel.values.map((value) => value.id), [0, 1]);
        expect(AberrationModel.values.map((value) => value.id), [0]);
        expect(DeflectionModel.values.map((value) => value.id), [0, 1]);
        expect(LightTimeMethod.values.map((value) => value.id), [0]);
        expect(ShapiroDelayModel.values.map((value) => value.id), [0]);
        expect(EclipseShadowModel.values.map((value) => value.id), [
          0,
          1,
          2,
          3,
        ]);
        expect(EclipseMoonRadiusModel.values.map((value) => value.id), [0, 1]);
        expect(ApparentFlag.values.map((value) => value.mask), [
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
          () => taiyin.configuration.setAtmosphere(const Atmosphere()),
          () => taiyin.configuration.setAtmospherePressureTemperature(
            pressureMillibars: 1013.25,
            temperatureCelsius: 15,
          ),
          () => taiyin.configuration.setStandardAtmosphere(),
          () => taiyin.configuration.setAtmospherePolicy(const {}),
          () => taiyin.configuration.setMeteorologicalRangeKm(25),
          () => taiyin.configuration.setGeocentricObserver(
            observerId: Body.earth.id,
            centerId: Body.sun.id,
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
          () => taiyin.configuration.setRouteRule(RouteRule.automatic),
          () => taiyin.configuration.setAstroModels(const AstroModelConfig()),
          () => taiyin.configuration.setApparentConfig(ApparentConfig()),
          () => taiyin.configuration.setCelestialPoleOffset(
            dxRadians: 0,
            dyRadians: 0,
          ),
          () => taiyin.configuration.setRefractionModel(RefractionModel.sofa),
          () => taiyin.configuration.setHeliacalVisibilityModel(
            HeliacalVisibilityModel.schaefer1993,
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
            shadow: EclipseShadowModel.nasaDanjon,
            moonRadius: EclipseMoonRadiusModel.almanac,
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
