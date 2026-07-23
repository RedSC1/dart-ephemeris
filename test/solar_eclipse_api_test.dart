import 'dart:io';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();
  const nativeDataRoot = '../taiyin-ephemeris/data';
  const majorBodiesPath = '$nativeDataRoot/ephemerides/opm2/major-bodies/600y';
  const lunarLimbPath = '$nativeDataRoot/lunar-limb/kaguya_lalt_16ppd.tll1';
  final lunarLimbAvailable = File(lunarLimbPath).existsSync();
  const mazatlan = TaiyinObserverLocation(
    longitudeDegrees: -106.4,
    latitudeDegrees: 23.2,
    heightMeters: 0,
  );

  group('TaiyinEclipseApi solar native integration', () {
    late Taiyin runtime;
    late TaiyinContext context;

    setUp(() {
      runtime = Taiyin.open(
        libraryPath: libraryPath,
        options: const TaiyinRuntimeOptions(
          sourcePaths: [majorBodiesPath],
          loadPackagedData: false,
          loadBuiltinEop: false,
        ),
      );
      context = runtime.createContext();
      context.configuration
        ..setGeocentricObserver(
          observerId: TaiyinBody.earth.id,
          centerId: TaiyinBody.earth.id,
        )
        ..setObserverLocation(mazatlan)
        ..setStandardAtmosphere()
        ..setRouteRule(TaiyinRouteRule.opm2);
    });

    tearDown(() {
      runtime.clearLunarLimbModel();
      context.close();
    });

    test(
      'solves and searches TT and UT1 global solar eclipses',
      () {
        final solvedUt = context.eclipses.solveSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.25),
          options: {TaiyinSolarEclipseSolveOption.includeContacts},
        );
        final solvedTt = context.eclipses.solveSolarAtTt(
          JulianDate<TtScale>.fromDouble(2460409.263),
          options: {TaiyinSolarEclipseSolveOption.includeContacts},
        );
        final nextUt = context.eclipses.nextSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460400.0),
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinSolarEclipseSearchOption.includeContacts},
        );
        final previousUt = context.eclipses.nextSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460410.0),
          kinds: {TaiyinEclipseKind.total},
          options: {
            TaiyinSolarEclipseSearchOption.includeContacts,
            TaiyinSolarEclipseSearchOption.backward,
          },
        );
        final nextTt = context.eclipses.nextSolarAtTt(
          JulianDate<TtScale>.fromDouble(2460409.263),
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinSolarEclipseSearchOption.includeContacts},
        );
        final rangeUt = context.eclipses.solarEclipsesAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460300.0),
          JulianDate<Ut1Scale>.fromDouble(2460800.0),
          maxResults: 6,
          options: {TaiyinSolarEclipseSearchOption.includeContacts},
        );
        final rangeTt = context.eclipses.solarEclipsesAtTt(
          JulianDate<TtScale>.fromDouble(2460300.0),
          JulianDate<TtScale>.fromDouble(2460800.0),
          maxResults: 6,
          options: {TaiyinSolarEclipseSearchOption.includeContacts},
        );
        final truePosition = context.eclipses.solveSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.25),
          positionFlags: {TaiyinPositionFlag.truePosition},
        );

        expect(solvedUt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(solvedUt.value.kinds, contains(TaiyinEclipseKind.central));
        expect(solvedTt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(solvedUt.value.deltaTSeconds, greaterThan(50));
        expect(
          solvedUt.value.maximum!.toDouble(),
          closeTo(2460409.262039739, 2 / 86400),
        );
        expect(solvedUt.value.coreRadiusKilometers, greaterThan(0));
        expect(solvedUt.value.penumbralMarginKilometers, lessThan(0));
        for (final contact in TaiyinSolarEclipseContact.values) {
          expect(solvedUt.value.contacts[contact], isNotNull);
        }
        expect(
          nextUt.value.maximum!.toDouble(),
          closeTo(solvedUt.value.maximum!.toDouble(), 2 / 86400),
        );
        expect(
          previousUt.value.maximum!.toDouble(),
          closeTo(solvedUt.value.maximum!.toDouble(), 2 / 86400),
        );
        expect(nextTt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(rangeUt.value, hasLength(3));
        expect(rangeUt.value[1].kinds, contains(TaiyinEclipseKind.annular));
        expect(rangeUt.value[1].kinds, contains(TaiyinEclipseKind.central));
        expect(rangeUt.value[2].kinds, contains(TaiyinEclipseKind.partial));
        expect(rangeUt.value[2].kinds, contains(TaiyinEclipseKind.noncentral));
        expect(rangeTt.value, hasLength(3));
        expect(rangeTt.value[0].kinds, contains(TaiyinEclipseKind.total));
        expect(truePosition.value.kinds, contains(TaiyinEclipseKind.total));
        expect(
          () => context.eclipses.solarEclipsesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460300.0),
            JulianDate<Ut1Scale>.fromDouble(2460800.0),
            maxResults: 1,
          ),
          throwsA(isA<TaiyinException>()),
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'derives local solar eclipses and instantaneous geometry in TT and UT1',
      () {
        final localUt = context.eclipses.solveLocalSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
        );
        final localTt = context.eclipses.solveLocalSolarAtTt(
          JulianDate<TtScale>.fromDouble(2460409.263),
        );
        final nextLocalUt = context.eclipses.nextLocalSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460400.0),
          kinds: {TaiyinEclipseKind.total},
        );
        final nextLocalTt = context.eclipses.nextLocalSolarAtTt(
          JulianDate<TtScale>.fromDouble(2460400.0),
          kinds: {TaiyinEclipseKind.total},
        );
        final circumstancesUt = context.eclipses.localSolarCircumstancesAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.256654905),
        );
        final circumstancesTt = context.eclipses.localSolarCircumstancesAtTt(
          JulianDate<TtScale>.fromDouble(2460409.2575),
        );

        expect(localUt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(
          localUt.value.visibility,
          contains(TaiyinLocalSolarEclipseVisibilityFlag.visibleAtObserver),
        );
        expect(localUt.value.magnitude, closeTo(1.057846292, 1e-4));
        expect(localUt.value.obscuration, closeTo(1, 1e-6));
        expect(localUt.value.durationSeconds, greaterThan(200));
        expect(localUt.value.sunAltitudeDegrees, greaterThan(0));
        expect(localUt.value.sunAzimuthDegrees, isNotNull);
        expect(localUt.value.positionAngleC1Degrees, isNotNull);
        expect(localUt.value.positionAngleC4Degrees, isNotNull);
        expect(localUt.value.vertexAngleC1Degrees, isNotNull);
        expect(localUt.value.vertexAngleC4Degrees, isNotNull);
        expect(localUt.value.moonSunRadiusRatio, greaterThan(1));
        for (final contact in TaiyinLocalSolarEclipseContact.values) {
          expect(localUt.value.contacts[contact], isNotNull);
        }
        expect(localTt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(nextLocalUt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(
          nextLocalUt.value.contacts[TaiyinLocalSolarEclipseContact.greatest],
          isNotNull,
        );
        expect(nextLocalTt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(circumstancesUt.value.deltaTSeconds, greaterThan(50));
        expect(circumstancesUt.value.magnitude, greaterThan(1));
        expect(circumstancesUt.value.obscuration, closeTo(1, 1e-6));
        expect(circumstancesUt.value.sunAltitudeDegrees, greaterThan(0));
        expect(circumstancesTt.value.magnitude, greaterThan(1));

        final previousLocalUt = context.eclipses.nextLocalSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460410.0),
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinSolarEclipseSearchOption.backward},
        );
        expect(
          previousLocalUt.value.maximum!.toDouble(),
          closeTo(localUt.value.maximum!.toDouble(), 2 / 86400),
        );

        context.configuration.setObserverLocation(
          const TaiyinObserverLocation(
            longitudeDegrees: -74.0,
            latitudeDegrees: 40.7,
            heightMeters: 10,
          ),
        );
        final newYork = context.eclipses.solveLocalSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
        );
        expect(newYork.value.kinds, contains(TaiyinEclipseKind.partial));
        expect(
          newYork.value.contacts[TaiyinLocalSolarEclipseContact.partialBegin],
          isNotNull,
        );
        expect(
          newYork.value.contacts[TaiyinLocalSolarEclipseContact.centralBegin],
          isNull,
        );
        expect(
          newYork.value.contacts[TaiyinLocalSolarEclipseContact.centralEnd],
          isNull,
        );
        expect(
          newYork.value.contacts[TaiyinLocalSolarEclipseContact.partialEnd],
          isNotNull,
        );

        context.configuration.setObserverLocation(
          const TaiyinObserverLocation(
            longitudeDegrees: 2.3522,
            latitudeDegrees: 48.8566,
            heightMeters: 35,
          ),
        );
        final paris = context.eclipses.solveLocalSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
        );
        expect(paris.value.hasEclipse, isTrue);
        expect(paris.value.visibility, isEmpty);
        for (final contact in TaiyinLocalSolarEclipseContact.values) {
          expect(paris.value.contacts[contact], isNull);
        }
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'uses a loaded lunar-limb model for solar contact calculations',
      () {
        runtime.loadLunarLimbModel(lunarLimbPath);

        final global = context.eclipses.solveSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.25),
          options: {TaiyinSolarEclipseSolveOption.lunarLimbCorrection},
        );
        final local = context.eclipses.solveLocalSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
          options: {TaiyinSolarEclipseSolveOption.lunarLimbCorrection},
        );
        final nextLocal = context.eclipses.nextLocalSolarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460400.0),
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinSolarEclipseSearchOption.lunarLimbCorrection},
        );
        final route = context.eclipses.solarEclipseRouteRowAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.262039739),
          options: {TaiyinSolarEclipseRouteOption.lunarLimbCorrection},
        );

        expect(runtime.hasLunarLimbModel, isTrue);
        expect(global.value.kinds, contains(TaiyinEclipseKind.total));
        expect(local.value.kinds, contains(TaiyinEclipseKind.total));
        expect(
          local.value.contacts[TaiyinLocalSolarEclipseContact.centralBegin],
          isNotNull,
        );
        expect(nextLocal.value.kinds, contains(TaiyinEclipseKind.total));
        expect(route.value.hasRoute, isTrue);
      },
      skip: !nativeLibraryAvailable || !lunarLimbAvailable,
    );

    test(
      'computes and evaluates solar Besselian elements and polynomials',
      () {
        final center = JulianDate<TtScale>.fromDouble(
          2460409.262231433 + 69 / 86400,
        );
        final elements = context.eclipses.solarBesselianElementsAtTt(center);
        final polynomial = context.eclipses.solarBesselianPolynomialAtTt(
          center,
          spanHours: 6,
          sampleStepHours: 1,
          degree: 4,
        );
        final evaluated = context.eclipses.evaluateSolarBesselianPolynomial(
          polynomial.value,
          0,
        );
        final directAtTwoHours = context.eclipses.solarBesselianElementsAtTt(
          JulianDate<TtScale>.fromDouble(center.toDouble() + 2 / 24),
          timeOffsetHours: 2,
        );
        final evaluatedAtTwoHours = context.eclipses
            .evaluateSolarBesselianPolynomial(polynomial.value, 2);
        const zeroElements = TaiyinSolarBesselianElements(
          tHours: 0,
          x: 0,
          y: 0,
          zeta: 0,
          dDegrees: 0,
          muDegrees: 0,
          l1: 0,
          l2: 0,
          f1Degrees: 0,
          f2Degrees: 0,
          tanF1: 0,
          tanF2: 0,
          gamma: 0,
        );
        final normalizedPolynomial = TaiyinSolarBesselianPolynomial(
          referenceEpoch: center,
          spanHours: 1,
          sampleStepHours: 1,
          degree: 1,
          xCoefficients: List.generate(8, (index) => index.toDouble()),
          yCoefficients: List.filled(8, 0),
          zetaCoefficients: List.filled(8, 0),
          dDegreesCoefficients: List.filled(8, 0),
          muDegreesCoefficients: List.filled(8, 0),
          l1Coefficients: List.filled(8, 0),
          l2Coefficients: List.filled(8, 0),
          f1Degrees: 0,
          f2Degrees: 0,
          tanF1: 0,
          tanF2: 0,
          center: zeroElements,
          maxResidual: zeroElements,
        );

        expect(elements.value.tHours, 0);
        expect(elements.value.x, closeTo(0.158222771478, 1e-9));
        expect(elements.value.y, closeTo(0.304493852574, 1e-9));
        expect(elements.value.zeta, closeTo(56.410877306293, 1e-8));
        expect(elements.value.dDegrees, closeTo(-7.590825680172, 1e-9));
        expect(elements.value.muDegrees, closeTo(273.994309607730, 1e-8));
        expect(elements.value.l1, closeTo(0.535736741366, 1e-9));
        expect(elements.value.l2, closeTo(0.010590415175, 1e-9));
        expect(
          polynomial.value.referenceEpoch.toDouble(),
          closeTo(center.toDouble(), 1e-12),
        );
        expect(polynomial.value.degree, 4);
        expect(
          polynomial.value.xCoefficients,
          hasLength(TaiyinSolarBesselianPolynomial.coefficientCount),
        );
        expect(evaluated.x, closeTo(elements.value.x, 1e-8));
        expect(evaluated.y, closeTo(elements.value.y, 1e-8));
        expect(evaluated.l1, closeTo(elements.value.l1, 1e-8));
        expect(evaluated.l2, closeTo(elements.value.l2, 1e-8));
        expect(evaluatedAtTwoHours.tHours, 2);
        expect(evaluatedAtTwoHours.x, closeTo(directAtTwoHours.value.x, 1e-7));
        expect(evaluatedAtTwoHours.y, closeTo(directAtTwoHours.value.y, 1e-7));
        expect(polynomial.value.maxResidual.x, lessThan(1e-7));
        expect(polynomial.value.maxResidual.y, lessThan(1e-7));
        expect(normalizedPolynomial.xCoefficients, [0, 1, 0, 0, 0, 0, 0, 0]);
        expect(
          () => context.eclipses.solarBesselianElementsAtTt(
            center,
            timeOffsetHours: double.nan,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.solarBesselianPolynomialAtTt(
            center,
            spanHours: 0,
            sampleStepHours: 1,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.solarBesselianPolynomialAtTt(
            center,
            spanHours: 6,
            sampleStepHours: 1,
            degree: 8,
          ),
          throwsRangeError,
        );
        expect(
          () => context.eclipses.evaluateSolarBesselianPolynomial(
            polynomial.value,
            double.infinity,
          ),
          throwsArgumentError,
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'computes global solar-eclipse route rows and inclusive route samples',
      () {
        final centerUt = JulianDate<Ut1Scale>.fromDouble(2460409.262039739);
        final centerTt = JulianDate<TtScale>.fromDouble(
          2460409.262039739 + 69 / 86400,
        );
        final rowUt = context.eclipses.solarEclipseRouteRowAtUt1(centerUt);
        final truePositionRow = context.eclipses.solarEclipseRouteRowAtUt1(
          centerUt,
          positionFlags: {TaiyinPositionFlag.truePosition},
        );
        final rowTt = context.eclipses.solarEclipseRouteRowAtTt(centerTt);
        final routeUt = context.eclipses.solarEclipseRouteAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460409.25),
          JulianDate<Ut1Scale>.fromDouble(2460409.27),
          stepMinutes: 10,
          maxRows: 8,
        );
        final routeTt = context.eclipses.solarEclipseRouteAtTt(
          JulianDate<TtScale>.fromDouble(2460409.25 + 69 / 86400),
          JulianDate<TtScale>.fromDouble(2460409.27 + 69 / 86400),
          stepMinutes: 10,
          maxRows: 8,
        );
        final singleCoordinateRoute = context.eclipses.solarEclipseRouteAtUt1(
          centerUt,
          centerUt,
          stepMinutes: 1,
          maxRows: 2,
        );

        expect(rowUt.value.hasRoute, isTrue);
        expect(rowUt.value.centerLine.intersectsEarth, isTrue);
        expect(
          rowUt.value.centerLine.latitudeDegrees,
          closeTo(25.289608540, 1e-4),
        );
        expect(
          rowUt.value.centerLine.longitudeDegrees,
          closeTo(-104.147998749, 1e-4),
        );
        expect(rowUt.value.pathWidthKilometers, closeTo(197.862736, 5));
        expect(rowUt.value.durationSeconds, closeTo(268.106442, 8));
        expect(rowUt.value.northLimit.intersectsEarth, isTrue);
        expect(rowUt.value.southLimit.intersectsEarth, isTrue);
        final annularEndpoint = context.eclipses.solarEclipseRouteRowAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2461443.2438330743),
        );
        expect(annularEndpoint.value.northLimit.intersectsEarth, isTrue);
        expect(annularEndpoint.value.southLimit.intersectsEarth, isFalse);
        expect(annularEndpoint.value.southLimit.latitudeDegrees, isNull);
        expect(truePositionRow.value.hasRoute, isTrue);
        expect(rowTt.value.hasRoute, isTrue);
        expect(rowTt.value.centerLine.latitudeDegrees, isNotNull);
        expect(routeUt.value, isNotEmpty);
        for (final routeRow in routeUt.value) {
          expect(routeRow.hasRoute, isTrue);
        }
        expect(routeTt.value, isNotEmpty);
        expect(singleCoordinateRoute.value, hasLength(1));
        expect(
          routeTt.value.first.coordinateTt.toDouble(),
          closeTo(2460409.25 + 69 / 86400, 1e-12),
        );
        expect(
          () => context.eclipses.solarEclipseRouteAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.25),
            JulianDate<Ut1Scale>.fromDouble(2460409.27),
            stepMinutes: 10,
            maxRows: 1,
          ),
          throwsA(isA<TaiyinException>()),
        );
        expect(
          () => context.eclipses.solarEclipseRouteAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.25),
            JulianDate<Ut1Scale>.fromDouble(2460409.27),
            stepMinutes: 10,
            maxRows: 0,
          ),
          throwsA(
            isA<RangeError>().having((error) => error.name, 'name', 'maxRows'),
          ),
        );
        expect(
          () => context.eclipses.solarEclipseRouteAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.27),
            JulianDate<Ut1Scale>.fromDouble(2460409.25),
            stepMinutes: 10,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.solarEclipseRouteAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.25),
            JulianDate<Ut1Scale>.fromDouble(2460409.27),
            stepMinutes: 0,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.solarEclipseRouteRowAtUt1(
            centerUt,
            positionFlags: {TaiyinPositionFlag.xyz},
          ),
          throwsArgumentError,
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'maps no eclipse and rejects invalid solar inputs',
      () {
        final none = context.eclipses.solveSolarAtTt(
          JulianDate<TtScale>.fromDouble(2451550.0),
        );
        expect(none.value.hasEclipse, isFalse);
        expect(none.value.maximum, isNull);
        expect(
          () => context.eclipses.nextSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460400.0),
            kinds: {TaiyinEclipseKind.penumbral},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.nextSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460400.0),
            kinds: {TaiyinEclipseKind.central},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.solarEclipsesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460800.0),
            JulianDate<Ut1Scale>.fromDouble(2460300.0),
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.solarEclipsesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460300.0),
            JulianDate<Ut1Scale>.fromDouble(2460800.0),
            maxResults: 0,
          ),
          throwsRangeError,
        );
        expect(
          () => context.eclipses.solarEclipsesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460300.0),
            JulianDate<Ut1Scale>.fromDouble(2460800.0),
            options: {TaiyinSolarEclipseSearchOption.backward},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.nextSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460400.0),
            positionFlags: {TaiyinPositionFlag.xyz},
          ),
          throwsArgumentError,
        );
        context.configuration.clearObserverLocation();
        expect(
          () => context.eclipses.solveLocalSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
          ),
          throwsA(isA<TaiyinException>()),
        );
        expect(
          () => context.eclipses.localSolarCircumstancesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.256654905),
          ),
          throwsA(isA<TaiyinException>()),
        );
        context.close();
        expect(
          () => context.eclipses.solveSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.25),
          ),
          throwsStateError,
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'computes solar route curves, polygon products, and local boundaries',
      () {
        final centerUt = JulianDate<Ut1Scale>.fromDouble(2460409.262039739);
        final centerTt = JulianDate<TtScale>.fromDouble(
          centerUt.toDouble() + 69 / 86400,
        );
        final curvesUt = context.eclipses.solarEclipseRouteCurvesAtUt1(
          centerUt,
          routeSampleCount: 32,
        );
        final curvesTt = context.eclipses.solarEclipseRouteCurvesAtTt(
          centerTt,
          routeSampleCount: 32,
        );
        final coreProduct = context.eclipses.solarEclipseRouteProductAtUt1(
          centerUt,
          routeSampleCount: 32,
        );
        final coreProductTt = context.eclipses.solarEclipseRouteProductAtTt(
          centerTt,
          routeSampleCount: 32,
        );
        final mapProduct = context.eclipses.solarEclipseRouteMapProductAtTt(
          centerTt,
          routeSampleCount: 32,
        );
        final mapProductUt = context.eclipses.solarEclipseRouteMapProductAtUt1(
          centerUt,
          routeSampleCount: 32,
        );
        final boundaryUt = context.eclipses.localSolarEclipseBoundaryAtUt1(
          centerUt,
          longitudeDegrees: mazatlan.longitudeDegrees,
          latitudeDegrees: mazatlan.latitudeDegrees,
        );
        final boundaryTt = context.eclipses.localSolarEclipseBoundaryAtTt(
          centerTt,
          longitudeDegrees: mazatlan.longitudeDegrees,
          latitudeDegrees: mazatlan.latitudeDegrees,
        );

        expect(curvesUt.value, isNotEmpty);
        expect(curvesTt.value, isNotEmpty);
        expect(
          curvesUt.value.map((point) => point.kind),
          contains(TaiyinSolarEclipseRouteCurveKind.centerLine),
        );
        expect(
          curvesUt.value.map((point) => point.kind),
          contains(TaiyinSolarEclipseRouteCurveKind.penumbralNorth),
        );
        expect(
          curvesUt.value.map((point) => point.kind),
          contains(TaiyinSolarEclipseRouteCurveKind.coreNorth),
        );
        expect(
          curvesUt.value.map((point) => point.kind),
          contains(TaiyinSolarEclipseRouteCurveKind.halfMagnitudeNorth),
        );
        for (final point in curvesUt.value) {
          expect(point.latitudeDegrees.isFinite, isTrue);
          expect(point.longitudeDegrees.isFinite, isTrue);
        }

        expect(coreProduct.value.points, isNotEmpty);
        expect(coreProductTt.value.points, isNotEmpty);
        expect(
          coreProduct.value.summary.flags,
          contains(TaiyinSolarEclipseRouteProductFlag.hasCorePolygon),
        );
        expect(
          coreProduct.value.summary.corePolygonPointCount,
          coreProduct.value.points.length,
        );
        expect(
          coreProduct.value.points.first.kind,
          TaiyinSolarEclipseRouteProductPointKind.coreNorth,
        );
        expect(
          coreProduct.value.points.last.kind,
          TaiyinSolarEclipseRouteProductPointKind.polygonClose,
        );
        expect(
          coreProduct.value.points.last.latitudeDegrees,
          closeTo(coreProduct.value.points.first.latitudeDegrees, 1e-12),
        );
        expect(
          coreProduct.value.summary.minimumLatitudeDegrees,
          lessThan(coreProduct.value.summary.maximumLatitudeDegrees!),
        );

        expect(
          mapProduct.value.summary.flags,
          contains(TaiyinSolarEclipseRouteProductFlag.hasCorePolygon),
        );
        expect(
          mapProduct.value.summary.flags,
          contains(TaiyinSolarEclipseRouteProductFlag.hasPenumbralPolygon),
        );
        expect(
          mapProduct.value.summary.flags,
          contains(TaiyinSolarEclipseRouteProductFlag.hasHalfMagnitudePolygon),
        );
        expect(
          mapProduct.value.summary.polygonPointCount,
          mapProduct.value.points.length,
        );
        expect(
          mapProduct.value.summary.polygonPointCount,
          greaterThan(coreProduct.value.points.length),
        );
        expect(mapProductUt.value.points, isNotEmpty);
        expect(
          mapProductUt.value.summary.polygonPointCount,
          mapProductUt.value.points.length,
        );
        expect(
          mapProduct
              .value
              .points[mapProduct.value.summary.corePolygonPointCount]
              .kind,
          TaiyinSolarEclipseRouteProductPointKind.penumbralNorth,
        );
        expect(
          mapProduct
              .value
              .points[mapProduct.value.summary.corePolygonPointCount +
                  mapProduct.value.summary.penumbralPolygonPointCount]
              .kind,
          TaiyinSolarEclipseRouteProductPointKind.halfMagnitudeNorth,
        );

        expect(boundaryUt.value.centerKinds, contains(TaiyinEclipseKind.total));
        expect(boundaryUt.value.centerLongitudeDegrees, isNotNull);
        expect(boundaryUt.value.centerLatitudeDegrees, isNotNull);
        expect(boundaryUt.value.umbraNorthLongitudeDegrees, isNotNull);
        expect(boundaryUt.value.umbraSouthLongitudeDegrees, isNotNull);
        expect(boundaryUt.value.penumbraNorthLongitudeDegrees, isNotNull);
        expect(boundaryUt.value.penumbraSouthLongitudeDegrees, isNotNull);
        expect(boundaryUt.value.umbraWidthKilometers, greaterThan(0));
        expect(boundaryTt.value.centerKinds, contains(TaiyinEclipseKind.total));
        expect(
          boundaryTt.value.centerLongitudeDegrees,
          closeTo(boundaryUt.value.centerLongitudeDegrees!, 0.002),
        );

        expect(
          () => context.eclipses.solarEclipseRouteCurvesAtUt1(
            centerUt,
            routeSampleCount: 31,
          ),
          throwsRangeError,
        );
        expect(
          () => context.eclipses.solarEclipseRouteProductAtUt1(
            centerUt,
            routeSampleCount: 4097,
          ),
          throwsRangeError,
        );
        expect(
          () => context.eclipses.localSolarEclipseBoundaryAtUt1(
            centerUt,
            longitudeDegrees: double.nan,
            latitudeDegrees: mazatlan.latitudeDegrees,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.solarEclipseRouteMapProductAtUt1(
            centerUt,
            positionFlags: {TaiyinPositionFlag.xyz},
          ),
          throwsArgumentError,
        );
      },
      skip: !nativeLibraryAvailable,
    );
  });
}
