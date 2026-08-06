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
      final venus = context.heliacal.bodyAtUt1(
        Body.venus,
        aprilEclipse,
        positionFlags: {PositionFlag.truePosition},
        flags: {HeliacalFlag.includeMoonlight},
        conditions: conditions,
      );
      final spica = context.heliacal.starAtUt1('spica', aprilEclipse);

      expect(venus.diagnostic.status, 0);
      expect(venus.value.modelId, HeliacalVisibilityModel.schaefer1993.id);
      expect(venus.value.extinctionMagnitudePerAirmass, 0.5);
      expect(venus.value.skyBrightnessNanolambert, 1234);
      expect(venus.value.moonlightBrightnessNanolambert, 0);
      expect(spica.diagnostic.status, 0);
      expect(spica.value.targetMagnitude.isFinite, isTrue);
      expect(spica.value.limitingMagnitude.isFinite, isTrue);
      expect(spica.value.modelId, HeliacalVisibilityModel.schaefer1993.id);
      expect(spica.value.skyBrightnessNanolambert, greaterThan(0));
    });

    test('honors strict meteorology and explicit atmosphere data', () {
      expect(
        () => context.heliacal.bodyAtUt1(
          Body.venus,
          aprilEclipse,
          flags: {HeliacalFlag.strictMeteorology},
        ),
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
      final result = context.heliacal.bodyAtUt1(
        Body.venus,
        aprilEclipse,
        flags: {HeliacalFlag.strictMeteorology},
      );

      expect(result.diagnostic.status, 0);
      expect(result.value.extinctionMagnitudePerAirmass, greaterThan(0));
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
        final result = context.heliacal.nextBodyEventAtUt1(
          Body.venus,
          JulianDate<Ut1Scale>.fromDouble(coordinate - 2),
          event: event,
          maxSearchDays: 5,
          conditions: conditions,
        );

        expect(result.diagnostic.status, 0);
        expect(result.value.event, event);
        expect(result.value.visibility.visible, isTrue);
        expect(
          result.value.coordinate.toDouble(),
          closeTo(coordinate, 10 / 1440),
        );
        expect(
          result.value.windowEnd.isAfter(result.value.windowStart),
          isTrue,
        );
        expect(
          result.value.coordinate.isAfter(result.value.windowStart),
          isTrue,
        );
        expect(
          result.value.coordinate.isBefore(result.value.windowEnd),
          isTrue,
        );
        expect(result.value.sampledWindowCount, greaterThan(0));
        expect(result.value.visibilityEvaluationCount, greaterThan(0));
      }
    });

    test('searches a catalogued-star heliacal event', () {
      final start = JulianDate<Ut1Scale>.fromDouble(2460310.5);
      final result = context.heliacal.nextStarEventAtUt1(
        'spica',
        start,
        event: HeliacalEventKind.morningFirst,
        maxSearchDays: 366,
      );

      expect(result.diagnostic.status, 0);
      expect(result.value.event, HeliacalEventKind.morningFirst);
      expect(result.value.coordinate.isAfter(start), isTrue);
      expect(
        result.value.coordinate.isBefore(start.add(const Duration(days: 366))),
        isTrue,
      );
      expect(result.value.windowEnd.isAfter(result.value.windowStart), isTrue);
      expect(result.value.coordinate.isAfter(result.value.windowStart), isTrue);
      expect(result.value.coordinate.isBefore(result.value.windowEnd), isTrue);
      expect(result.value.sampledWindowCount, greaterThan(0));
      expect(result.value.visibilityEvaluationCount, greaterThan(0));
      expect(result.value.visibility.visible, isTrue);
    });

    test('rejects unsupported inputs and use after close', () {
      expect(
        () => context.heliacal.bodyAtUt1(Body.sun, aprilEclipse),
        throwsArgumentError,
      );
      expect(
        () => context.heliacal.bodyAtUt1(Body.moon, aprilEclipse),
        throwsArgumentError,
      );
      expect(
        () => context.heliacal.starAtUt1('spica\u0000suffix', aprilEclipse),
        throwsArgumentError,
      );
      expect(
        () => context.heliacal.bodyAtUt1(
          Body.venus,
          aprilEclipse,
          positionFlags: {PositionFlag.speed},
        ),
        throwsArgumentError,
      );
      expect(
        () => context.heliacal.bodyAtUt1(
          Body.venus,
          aprilEclipse,
          positionFlags: {PositionFlag.xyz},
        ),
        throwsArgumentError,
      );
      expect(
        () => context.heliacal.nextBodyEventAtUt1(
          Body.venus,
          aprilEclipse,
          event: HeliacalEventKind.morningFirst,
          maxSearchDays: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => context.heliacal.bodyAtUt1(
          Body.venus,
          aprilEclipse,
          conditions: const HeliacalVisibilityConditions(
            extinctionMagnitudePerAirmass: 0,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => context.heliacal.bodyAtUt1(
          Body.venus,
          aprilEclipse,
          conditions: const HeliacalVisibilityConditions(
            skyBrightnessNanolambert: 0,
          ),
        ),
        throwsArgumentError,
      );
      context.close();
      expect(
        () => context.heliacal.bodyAtUt1(Body.venus, aprilEclipse),
        throwsStateError,
      );
    });
  }, skip: !nativeLibraryAvailable);
}
