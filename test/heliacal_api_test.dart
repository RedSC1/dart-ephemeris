import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  const nativeDataRoot = '../taiyin-ephemeris/data';
  const majorBodiesPath = '$nativeDataRoot/ephemerides/opm2/major-bodies/600y';
  const fixedCatalogPath =
      '$nativeDataRoot/stars/catalogs/stars-fixed-traditional.tsc1';

  group('HeliacalApi native integration', () {
    late Ephemeris runtime;
    late EphemerisContext context;
    const observer = ObserverLocation(longitudeDegrees: 0, latitudeDegrees: 0);
    final aprilEclipse = JulianDate<Ut1Scale>.fromDouble(2460408.5);

    setUp(() {
      runtime = Ephemeris.open(
        libraryPath: libraryPath,
        options: const RuntimeOptions(
          sourcePaths: [majorBodiesPath],
          loadPackagedData: false,
          loadBuiltinEop: false,
        ),
      );
      runtime.starCatalog
        ..clear()
        ..addTsc1(fixedCatalogPath);
      context = runtime.createContext();
      context.configuration
        ..setGeocentricObserver(
          observerId: Body.earth.id,
          centerId: Body.earth.id,
        )
        ..setObserverLocation(observer)
        ..setAtmospherePolicy({AtmospherePolicyFlag.allowStandardFallback})
        ..useSolarDeflector()
        ..setApparentConfig(
          ApparentConfig(
            flags: const {
              ApparentFlag.spherical,
              ApparentFlag.lightTime,
              ApparentFlag.aberration,
              ApparentFlag.deflection,
            },
            outputFrame: ApparentFrame.trueEclipticOfDate,
          ),
        )
        ..setHeliacalVisibilityModel(HeliacalVisibilityModel.schaefer1993);
    });

    tearDown(() {
      context.close();
      runtime.starCatalog.clear();
    });

    test('evaluates body and catalogue-star heliacal visibility', () {
      const conditions = HeliacalVisibilityConditions(
        extinctionMagnitudePerAirmass: 0.5,
        skyBrightnessNanolambert: 1234,
      );
      final venus = context.heliacal
          .bodyAtUt1(
            Body.venus,
            aprilEclipse,
            positionFlags: {PositionFlag.truePosition},
            flags: {HeliacalFlag.includeMoonlight},
            conditions: conditions,
          )
          .value;
      final spica = context.heliacal.starAtUt1('spica', aprilEclipse).value;

      expect(venus.modelId, HeliacalVisibilityModel.schaefer1993.id);
      expect(venus.extinctionMagnitudePerAirmass, 0.5);
      expect(venus.skyBrightnessNanolambert, 1234);
      expect(venus.moonlightBrightnessNanolambert, 0);
      expect(context.lastDiagnostic?.status, 0);
      expect(spica.targetMagnitude.isFinite, isTrue);
      expect(spica.limitingMagnitude.isFinite, isTrue);
      expect(spica.modelId, HeliacalVisibilityModel.schaefer1993.id);
      expect(spica.skyBrightnessNanolambert, greaterThan(0));
    });

    test('honors strict meteorology and explicit atmosphere data', () {
      expect(
        () => context.heliacal
            .bodyAtUt1(
              Body.venus,
              aprilEclipse,
              flags: {HeliacalFlag.strictMeteorology},
            )
            .value,
        throwsA(
          isA<EphemerisError>().having(
            (error) => error.status,
            'status',
            isNot(0),
          ),
        ),
      );

      context.configuration
        ..setAtmosphere(const Atmosphere(relativeHumidityPercent: 40))
        ..setMeteorologicalRangeKm(40);
      final result = context.heliacal
          .bodyAtUt1(
            Body.venus,
            aprilEclipse,
            flags: {HeliacalFlag.strictMeteorology},
          )
          .value;

      expect(context.lastDiagnostic?.status, 0);
      expect(result.extinctionMagnitudePerAirmass, greaterThan(0));
    });

    test('matches native Venus heliacal-search oracles', () {
      const conditions = HeliacalVisibilityConditions(
        extinctionMagnitudePerAirmass: 0.25,
      );
      const cases = [
        (HeliacalEventKind.morningFirst, 2460760.739317970350),
        (HeliacalEventKind.morningLast, 2460430.731063851155),
        (HeliacalEventKind.eveningFirst, 2460497.270654550754),
        (HeliacalEventKind.eveningLast, 2460749.272280503064),
      ];

      for (final (event, coordinate) in cases) {
        final result = context.heliacal
            .nextBodyEventAtUt1(
              Body.venus,
              JulianDate<Ut1Scale>.fromDouble(coordinate - 2),
              event: event,
              maxSearchDays: 5,
              conditions: conditions,
            )
            .value;

        expect(context.lastDiagnostic?.status, 0);
        expect(result.event, event);
        expect(result.visibility.visible, isTrue);
        expect(result.coordinate.toDouble(), closeTo(coordinate, 10 / 1440));
        expect(result.windowEnd.isAfter(result.windowStart), isTrue);
        expect(result.coordinate.isAfter(result.windowStart), isTrue);
        expect(result.coordinate.isBefore(result.windowEnd), isTrue);
        expect(result.sampledWindowCount, greaterThan(0));
        expect(result.visibilityEvaluationCount, greaterThan(0));
      }
    });

    test('searches a catalogued-star heliacal event', () {
      final start = JulianDate<Ut1Scale>.fromDouble(2460310.5);
      final result = context.heliacal
          .nextStarEventAtUt1(
            'spica',
            start,
            event: HeliacalEventKind.morningFirst,
            maxSearchDays: 366,
          )
          .value;

      expect(context.lastDiagnostic?.status, 0);
      expect(result.event, HeliacalEventKind.morningFirst);
      expect(result.coordinate.isAfter(start), isTrue);
      expect(
        result.coordinate.isBefore(start.add(const Duration(days: 366))),
        isTrue,
      );
      expect(result.windowEnd.isAfter(result.windowStart), isTrue);
      expect(result.coordinate.isAfter(result.windowStart), isTrue);
      expect(result.coordinate.isBefore(result.windowEnd), isTrue);
      expect(result.sampledWindowCount, greaterThan(0));
      expect(result.visibilityEvaluationCount, greaterThan(0));
      expect(result.visibility.visible, isTrue);
    });

    test('rejects unsupported inputs and use after close', () {
      expect(
        () => context.heliacal.bodyAtUt1(Body.sun, aprilEclipse).value,
        throwsArgumentError,
      );
      expect(
        () => context.heliacal.bodyAtUt1(Body.moon, aprilEclipse).value,
        throwsArgumentError,
      );
      expect(
        () =>
            context.heliacal.starAtUt1('spica\u0000suffix', aprilEclipse).value,
        throwsArgumentError,
      );
      expect(
        () => context.heliacal
            .bodyAtUt1(
              Body.venus,
              aprilEclipse,
              positionFlags: {PositionFlag.speed},
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.heliacal
            .bodyAtUt1(
              Body.venus,
              aprilEclipse,
              positionFlags: {PositionFlag.xyz},
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.heliacal
            .nextBodyEventAtUt1(
              Body.venus,
              aprilEclipse,
              event: HeliacalEventKind.morningFirst,
              maxSearchDays: 0,
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.heliacal
            .bodyAtUt1(
              Body.venus,
              aprilEclipse,
              conditions: const HeliacalVisibilityConditions(
                extinctionMagnitudePerAirmass: 0,
              ),
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.heliacal
            .bodyAtUt1(
              Body.venus,
              aprilEclipse,
              conditions: const HeliacalVisibilityConditions(
                skyBrightnessNanolambert: 0,
              ),
            )
            .value,
        throwsArgumentError,
      );
      context.close();
      expect(
        () => context.heliacal.bodyAtUt1(Body.venus, aprilEclipse).value,
        throwsStateError,
      );
    });
  }, skip: !nativeLibraryAvailable);
}
