import 'dart:io';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  const nativeDataRoot = '../taiyin-ephemeris/data';
  const majorBodiesPath = '$nativeDataRoot/ephemerides/opm2/major-bodies/600y';
  const lunarLimbPath = '$nativeDataRoot/lunar-limb/kaguya_lalt_16ppd.tll1';
  final lunarLimbAvailable = File(lunarLimbPath).existsSync();
  const mazatlan = ObserverLocation(
    longitudeDegrees: -106.4,
    latitudeDegrees: 23.2,
    heightMeters: 0,
  );

  group('EclipseApi solar native integration', () {
    late Ephemeris runtime;
    late EphemerisContext context;

    setUp(() {
      runtime = Ephemeris.open(
        libraryPath: libraryPath,
        options: const RuntimeOptions(
          sourcePaths: [majorBodiesPath],
          loadPackagedData: false,
          loadBuiltinEop: false,
        ),
      );
      context = runtime.createContext();
      context.configuration
        ..setGeocentricObserver(
          observerId: Body.earth.id,
          centerId: Body.earth.id,
        )
        ..setObserverLocation(mazatlan)
        ..setStandardAtmosphere()
        ..setRouteRule(RouteRule.opm2);
    });

    tearDown(() {
      runtime.clearLunarLimbModel();
      context.close();
    });

    test('solves and searches TT and UT1 global solar eclipses', () {
      final solvedUt = context.eclipses
          .solveSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.25),
            options: {SolarEclipseSolveOption.includeContacts},
          )
          .value;
      final solvedTt = context.eclipses
          .solveSolarAtTt(
            JulianDate<TtScale>.fromDouble(2460409.263),
            options: {SolarEclipseSolveOption.includeContacts},
          )
          .value;
      final nextUt = context.eclipses
          .nextSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460400.0),
            kinds: {EclipseKind.total},
            options: {SolarEclipseSearchOption.includeContacts},
          )
          .value;
      final previousUt = context.eclipses
          .nextSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460410.0),
            kinds: {EclipseKind.total},
            options: {
              SolarEclipseSearchOption.includeContacts,
              SolarEclipseSearchOption.backward,
            },
          )
          .value;
      final nextTt = context.eclipses
          .nextSolarAtTt(
            JulianDate<TtScale>.fromDouble(2460409.263),
            kinds: {EclipseKind.total},
            options: {SolarEclipseSearchOption.includeContacts},
          )
          .value;
      final rangeUt = context.eclipses
          .solarEclipsesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460300.0),
            JulianDate<Ut1Scale>.fromDouble(2460800.0),
            maxResults: 6,
            options: {SolarEclipseSearchOption.includeContacts},
          )
          .value;
      final rangeTt = context.eclipses
          .solarEclipsesAtTt(
            JulianDate<TtScale>.fromDouble(2460300.0),
            JulianDate<TtScale>.fromDouble(2460800.0),
            maxResults: 6,
            options: {SolarEclipseSearchOption.includeContacts},
          )
          .value;
      final truePosition = context.eclipses
          .solveSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.25),
            positionFlags: {PositionFlag.truePosition},
          )
          .value;

      expect(solvedUt.kinds, contains(EclipseKind.total));
      expect(solvedUt.kinds, contains(EclipseKind.central));
      expect(solvedTt.kinds, contains(EclipseKind.total));
      expect(solvedUt.deltaTSeconds, greaterThan(50));
      expect(
        solvedUt.maximum!.toDouble(),
        closeTo(2460409.262039739, 2 / 86400),
      );
      expect(solvedUt.coreRadiusKilometers, greaterThan(0));
      expect(solvedUt.penumbralMarginKilometers, lessThan(0));
      for (final contact in SolarEclipseContact.values) {
        expect(solvedUt.contacts[contact], isNotNull);
      }
      expect(
        nextUt.maximum!.toDouble(),
        closeTo(solvedUt.maximum!.toDouble(), 2 / 86400),
      );
      expect(
        previousUt.maximum!.toDouble(),
        closeTo(solvedUt.maximum!.toDouble(), 2 / 86400),
      );
      expect(nextTt.kinds, contains(EclipseKind.total));
      expect(rangeUt, hasLength(3));
      expect(rangeUt[1].kinds, contains(EclipseKind.annular));
      expect(rangeUt[1].kinds, contains(EclipseKind.central));
      expect(rangeUt[2].kinds, contains(EclipseKind.partial));
      expect(rangeUt[2].kinds, contains(EclipseKind.noncentral));
      expect(rangeTt, hasLength(3));
      expect(rangeTt[0].kinds, contains(EclipseKind.total));
      expect(truePosition.kinds, contains(EclipseKind.total));
      expect(
        () => context.eclipses
            .solarEclipsesAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460300.0),
              JulianDate<Ut1Scale>.fromDouble(2460800.0),
              maxResults: 1,
            )
            .value,
        throwsA(isA<EphemerisError>()),
      );
    }, skip: !nativeLibraryAvailable);

    test(
      'derives local solar eclipses and instantaneous geometry in TT and UT1',
      () {
        final localUt = context.eclipses
            .solveLocalSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
            )
            .value;
        final localTt = context.eclipses
            .solveLocalSolarAtTt(JulianDate<TtScale>.fromDouble(2460409.263))
            .value;
        final nextLocalUt = context.eclipses
            .nextLocalSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460400.0),
              kinds: {EclipseKind.total},
            )
            .value;
        final nextLocalTt = context.eclipses
            .nextLocalSolarAtTt(
              JulianDate<TtScale>.fromDouble(2460400.0),
              kinds: {EclipseKind.total},
            )
            .value;
        final circumstancesUt = context.eclipses
            .localSolarCircumstancesAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.256654905),
            )
            .value;
        final circumstancesTt = context.eclipses
            .localSolarCircumstancesAtTt(
              JulianDate<TtScale>.fromDouble(2460409.2575),
            )
            .value;

        expect(localUt.kinds, contains(EclipseKind.total));
        expect(
          localUt.visibility,
          contains(LocalSolarEclipseVisibilityFlag.visibleAtObserver),
        );
        expect(localUt.magnitude, closeTo(1.057846292, 1e-4));
        expect(localUt.obscuration, closeTo(1, 1e-6));
        expect(localUt.durationSeconds, greaterThan(200));
        expect(localUt.sunAltitudeDegrees, greaterThan(0));
        expect(localUt.sunAzimuthDegrees, isNotNull);
        expect(localUt.positionAngleC1Degrees, isNotNull);
        expect(localUt.positionAngleC4Degrees, isNotNull);
        expect(localUt.vertexAngleC1Degrees, isNotNull);
        expect(localUt.vertexAngleC4Degrees, isNotNull);
        expect(localUt.moonSunRadiusRatio, greaterThan(1));
        for (final contact in LocalSolarEclipseContact.values) {
          expect(localUt.contacts[contact], isNotNull);
        }
        expect(localTt.kinds, contains(EclipseKind.total));
        expect(nextLocalUt.kinds, contains(EclipseKind.total));
        expect(
          nextLocalUt.contacts[LocalSolarEclipseContact.greatest],
          isNotNull,
        );
        expect(nextLocalTt.kinds, contains(EclipseKind.total));
        expect(circumstancesUt.deltaTSeconds, greaterThan(50));
        expect(circumstancesUt.magnitude, greaterThan(1));
        expect(circumstancesUt.obscuration, closeTo(1, 1e-6));
        expect(circumstancesUt.sunAltitudeDegrees, greaterThan(0));
        expect(circumstancesTt.magnitude, greaterThan(1));

        final previousLocalUt = context.eclipses
            .nextLocalSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460410.0),
              kinds: {EclipseKind.total},
              options: {SolarEclipseSearchOption.backward},
            )
            .value;
        expect(
          previousLocalUt.maximum!.toDouble(),
          closeTo(localUt.maximum!.toDouble(), 2 / 86400),
        );

        context.configuration.setObserverLocation(
          const ObserverLocation(
            longitudeDegrees: -74.0,
            latitudeDegrees: 40.7,
            heightMeters: 10,
          ),
        );
        final newYork = context.eclipses
            .solveLocalSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
            )
            .value;
        expect(newYork.kinds, contains(EclipseKind.partial));
        expect(
          newYork.contacts[LocalSolarEclipseContact.partialBegin],
          isNotNull,
        );
        expect(newYork.contacts[LocalSolarEclipseContact.centralBegin], isNull);
        expect(newYork.contacts[LocalSolarEclipseContact.centralEnd], isNull);
        expect(
          newYork.contacts[LocalSolarEclipseContact.partialEnd],
          isNotNull,
        );

        context.configuration.setObserverLocation(
          const ObserverLocation(
            longitudeDegrees: 2.3522,
            latitudeDegrees: 48.8566,
            heightMeters: 35,
          ),
        );
        final paris = context.eclipses
            .solveLocalSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
            )
            .value;
        expect(paris.hasEclipse, isTrue);
        expect(paris.visibility, isEmpty);
        for (final contact in LocalSolarEclipseContact.values) {
          expect(paris.contacts[contact], isNull);
        }
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'supports refracted and strict-meteorology local solar visibility',
      () {
        // The context has a fully specified standard atmosphere, so both the
        // refracted and the strict refracted rise/set window resolve without
        // fallback.
        final refracted = context.eclipses
            .solveLocalSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
              visibilityOptions: {LocalSolarEclipseVisibilityOption.refraction},
            )
            .value;
        expect(refracted.kinds, contains(EclipseKind.total));
        expect(
          refracted.visibility,
          contains(LocalSolarEclipseVisibilityFlag.visibleAtObserver),
        );

        final strict = context.eclipses
            .solveLocalSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
              visibilityOptions: {
                LocalSolarEclipseVisibilityOption.refraction,
                LocalSolarEclipseVisibilityOption.strictMeteorology,
              },
            )
            .value;
        expect(strict.kinds, contains(EclipseKind.total));

        // strictMeteorology requires refraction.
        expect(
          () => context.eclipses
              .solveLocalSolarAtUt1(
                JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
                visibilityOptions: {
                  LocalSolarEclipseVisibilityOption.strictMeteorology,
                },
              )
              .value,
          throwsA(isA<ArgumentError>()),
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test('uses a loaded lunar-limb model for solar contact calculations', () {
      runtime.loadLunarLimbModel(lunarLimbPath);

      final global = context.eclipses
          .solveSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.25),
            options: {SolarEclipseSolveOption.lunarLimbCorrection},
          )
          .value;
      final local = context.eclipses
          .solveLocalSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
            options: {SolarEclipseSolveOption.lunarLimbCorrection},
          )
          .value;
      final nextLocal = context.eclipses
          .nextLocalSolarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460400.0),
            kinds: {EclipseKind.total},
            options: {SolarEclipseSearchOption.lunarLimbCorrection},
          )
          .value;
      final route = context.eclipses
          .solarEclipseRouteRowAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460409.262039739),
            options: {SolarEclipseRouteOption.lunarLimbCorrection},
          )
          .value;

      expect(runtime.hasLunarLimbModel, isTrue);
      expect(global.kinds, contains(EclipseKind.total));
      expect(local.kinds, contains(EclipseKind.total));
      expect(local.contacts[LocalSolarEclipseContact.centralBegin], isNotNull);
      expect(nextLocal.kinds, contains(EclipseKind.total));
      expect(route.hasRoute, isTrue);
    }, skip: !nativeLibraryAvailable || !lunarLimbAvailable);

    test('computes and evaluates solar Besselian elements and polynomials', () {
      final center = JulianDate<TtScale>.fromDouble(
        2460409.262231433 + 69 / 86400,
      );
      final elements = context.eclipses
          .solarBesselianElementsAtTt(center)
          .value;
      final polynomial = context.eclipses
          .solarBesselianPolynomialAtTt(
            center,
            spanHours: 6,
            sampleStepHours: 1,
            degree: 4,
          )
          .value;
      final evaluated = context.eclipses
          .evaluateSolarBesselianPolynomial(polynomial, 0)
          .value;
      final directAtTwoHours = context.eclipses
          .solarBesselianElementsAtTt(
            JulianDate<TtScale>.fromDouble(center.toDouble() + 2 / 24),
            timeOffsetHours: 2,
          )
          .value;
      final evaluatedAtTwoHours = context.eclipses
          .evaluateSolarBesselianPolynomial(polynomial, 2)
          .value;
      const zeroElements = SolarBesselianElements(
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
      final normalizedPolynomial = SolarBesselianPolynomial(
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

      expect(elements.tHours, 0);
      // Updated after the native precession/nutation fix (2026-08).
      expect(elements.x, closeTo(0.15822277776121665, 1e-9));
      expect(elements.y, closeTo(0.3044938492945148, 1e-9));
      expect(elements.zeta, closeTo(56.410877306293, 1e-8));
      expect(elements.dDegrees, closeTo(-7.590825680172, 1e-9));
      expect(elements.muDegrees, closeTo(273.994309591411, 1e-8));
      expect(elements.l1, closeTo(0.535736741366, 1e-9));
      expect(elements.l2, closeTo(0.010590415175, 1e-9));
      expect(
        polynomial.referenceEpoch.toDouble(),
        closeTo(center.toDouble(), 1e-12),
      );
      expect(polynomial.degree, 4);
      expect(
        polynomial.xCoefficients,
        hasLength(SolarBesselianPolynomial.coefficientCount),
      );
      expect(evaluated.x, closeTo(elements.x, 1e-8));
      expect(evaluated.y, closeTo(elements.y, 1e-8));
      expect(evaluated.l1, closeTo(elements.l1, 1e-8));
      expect(evaluated.l2, closeTo(elements.l2, 1e-8));
      expect(evaluatedAtTwoHours.tHours, 2);
      expect(evaluatedAtTwoHours.x, closeTo(directAtTwoHours.x, 1e-7));
      expect(evaluatedAtTwoHours.y, closeTo(directAtTwoHours.y, 1e-7));
      expect(polynomial.maxResidual.x, lessThan(1e-7));
      expect(polynomial.maxResidual.y, lessThan(1e-7));
      expect(normalizedPolynomial.xCoefficients, [0, 1, 0, 0, 0, 0, 0, 0]);
      expect(
        () => context.eclipses
            .solarBesselianElementsAtTt(center, timeOffsetHours: double.nan)
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.eclipses
            .solarBesselianPolynomialAtTt(
              center,
              spanHours: 0,
              sampleStepHours: 1,
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.eclipses
            .solarBesselianPolynomialAtTt(
              center,
              spanHours: 6,
              sampleStepHours: 1,
              degree: 8,
            )
            .value,
        throwsRangeError,
      );
      expect(
        () => context.eclipses
            .evaluateSolarBesselianPolynomial(polynomial, double.infinity)
            .value,
        throwsArgumentError,
      );
    }, skip: !nativeLibraryAvailable);

    test('computes lightweight instantaneous global geometry with where', () {
      final centerUt = JulianDate<Ut1Scale>.fromDouble(2460409.262039739);
      final centerTt = JulianDate<TtScale>.fromDouble(
        2460409.262039739 + 69 / 86400,
      );
      final whereUt = context.eclipses.solarEclipseWhereAtUt1(centerUt).value;
      final whereTt = context.eclipses.solarEclipseWhereAtTt(centerTt).value;

      expect(whereUt.magnitude, greaterThan(1));
      expect(whereUt.centerLine.intersectsEarth, isTrue);
      expect(whereUt.centerSeparationDegrees, isNonNegative);
      expect(whereUt.sunAngularRadiusDegrees, greaterThan(0));
      expect(whereUt.moonAngularRadiusDegrees, greaterThan(0));
      expect(whereTt.magnitude, closeTo(whereUt.magnitude, 1e-6));
    });

    test(
      'computes global solar-eclipse route rows and inclusive route samples',
      () {
        final centerUt = JulianDate<Ut1Scale>.fromDouble(2460409.262039739);
        final centerTt = JulianDate<TtScale>.fromDouble(
          2460409.262039739 + 69 / 86400,
        );
        final rowUt = context.eclipses
            .solarEclipseRouteRowAtUt1(centerUt)
            .value;
        final truePositionRow = context.eclipses
            .solarEclipseRouteRowAtUt1(
              centerUt,
              positionFlags: {PositionFlag.truePosition},
            )
            .value;
        final rowTt = context.eclipses.solarEclipseRouteRowAtTt(centerTt).value;
        final routeUt = context.eclipses
            .solarEclipseRouteAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.25),
              JulianDate<Ut1Scale>.fromDouble(2460409.27),
              stepMinutes: 10,
              maxRows: 8,
            )
            .value;
        final routeTt = context.eclipses
            .solarEclipseRouteAtTt(
              JulianDate<TtScale>.fromDouble(2460409.25 + 69 / 86400),
              JulianDate<TtScale>.fromDouble(2460409.27 + 69 / 86400),
              stepMinutes: 10,
              maxRows: 8,
            )
            .value;
        final singleCoordinateRoute = context.eclipses
            .solarEclipseRouteAtUt1(
              centerUt,
              centerUt,
              stepMinutes: 1,
              maxRows: 2,
            )
            .value;

        expect(rowUt.hasRoute, isTrue);
        expect(rowUt.centerLine.intersectsEarth, isTrue);
        expect(rowUt.centerLine.latitudeDegrees, closeTo(25.289608540, 1e-4));
        expect(
          rowUt.centerLine.longitudeDegrees,
          closeTo(-104.147998749, 1e-4),
        );
        expect(rowUt.pathWidthKilometers, closeTo(197.862736, 5));
        expect(rowUt.durationSeconds, closeTo(268.106442, 8));
        expect(rowUt.northLimit.intersectsEarth, isTrue);
        expect(rowUt.southLimit.intersectsEarth, isTrue);
        final annularEndpoint = context.eclipses
            .solarEclipseRouteRowAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2461443.2438330743),
            )
            .value;
        expect(annularEndpoint.northLimit.intersectsEarth, isTrue);
        expect(annularEndpoint.southLimit.intersectsEarth, isFalse);
        expect(annularEndpoint.southLimit.latitudeDegrees, isNull);
        expect(truePositionRow.hasRoute, isTrue);
        expect(rowTt.hasRoute, isTrue);
        expect(rowTt.centerLine.latitudeDegrees, isNotNull);
        expect(routeUt, isNotEmpty);
        for (final routeRow in routeUt) {
          expect(routeRow.hasRoute, isTrue);
        }
        expect(routeTt, isNotEmpty);
        expect(singleCoordinateRoute, hasLength(1));
        expect(
          routeTt.first.coordinateTt.toDouble(),
          closeTo(2460409.25 + 69 / 86400, 1e-12),
        );
        expect(
          () => context.eclipses
              .solarEclipseRouteAtUt1(
                JulianDate<Ut1Scale>.fromDouble(2460409.25),
                JulianDate<Ut1Scale>.fromDouble(2460409.27),
                stepMinutes: 10,
                maxRows: 1,
              )
              .value,
          throwsA(isA<EphemerisError>()),
        );
        expect(
          () => context.eclipses
              .solarEclipseRouteAtUt1(
                JulianDate<Ut1Scale>.fromDouble(2460409.25),
                JulianDate<Ut1Scale>.fromDouble(2460409.27),
                stepMinutes: 10,
                maxRows: 0,
              )
              .value,
          throwsA(
            isA<RangeError>().having((error) => error.name, 'name', 'maxRows'),
          ),
        );
        expect(
          () => context.eclipses
              .solarEclipseRouteAtUt1(
                JulianDate<Ut1Scale>.fromDouble(2460409.27),
                JulianDate<Ut1Scale>.fromDouble(2460409.25),
                stepMinutes: 10,
              )
              .value,
          throwsArgumentError,
        );
        expect(
          () => context.eclipses
              .solarEclipseRouteAtUt1(
                JulianDate<Ut1Scale>.fromDouble(2460409.25),
                JulianDate<Ut1Scale>.fromDouble(2460409.27),
                stepMinutes: 0,
              )
              .value,
          throwsArgumentError,
        );
        expect(
          () => context.eclipses
              .solarEclipseRouteRowAtUt1(
                centerUt,
                positionFlags: {PositionFlag.xyz},
              )
              .value,
          throwsArgumentError,
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test('maps no eclipse and rejects invalid solar inputs', () {
      final none = context.eclipses
          .solveSolarAtTt(JulianDate<TtScale>.fromDouble(2451550.0))
          .value;
      expect(none.hasEclipse, isFalse);
      expect(none.maximum, isNull);
      final emptyCoreProduct = context.eclipses
          .solarEclipseRouteProductAtTt(
            JulianDate<TtScale>.fromDouble(2451550.0),
            routeSampleCount: 32,
          )
          .value;
      final emptyMapProduct = context.eclipses
          .solarEclipseRouteMapProductAtTt(
            JulianDate<TtScale>.fromDouble(2451550.0),
            routeSampleCount: 32,
          )
          .value;
      for (final product in [emptyCoreProduct, emptyMapProduct]) {
        expect(product.points, isEmpty);
        expect(product.summary.flags, isEmpty);
        for (final count in [
          product.summary.curvePointCount,
          product.summary.centerLineCount,
          product.summary.coreNorthCount,
          product.summary.coreSouthCount,
          product.summary.coreBeginHorizonCount,
          product.summary.coreEndHorizonCount,
          product.summary.penumbralNorthCount,
          product.summary.penumbralSouthCount,
          product.summary.halfMagnitudeNorthCount,
          product.summary.halfMagnitudeSouthCount,
          product.summary.corePolygonPointCount,
          product.summary.penumbralPolygonPointCount,
          product.summary.halfMagnitudePolygonPointCount,
          product.summary.polygonPointCount,
        ]) {
          expect(count, 0);
        }
      }
      expect(
        () => context.eclipses
            .nextSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460400.0),
              kinds: {EclipseKind.penumbral},
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.eclipses
            .nextSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460400.0),
              kinds: {EclipseKind.central},
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.eclipses
            .solarEclipsesAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460800.0),
              JulianDate<Ut1Scale>.fromDouble(2460300.0),
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.eclipses
            .solarEclipsesAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460300.0),
              JulianDate<Ut1Scale>.fromDouble(2460800.0),
              maxResults: 0,
            )
            .value,
        throwsRangeError,
      );
      expect(
        () => context.eclipses
            .solarEclipsesAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460300.0),
              JulianDate<Ut1Scale>.fromDouble(2460800.0),
              options: {SolarEclipseSearchOption.backward},
            )
            .value,
        throwsArgumentError,
      );
      expect(
        () => context.eclipses
            .nextSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460400.0),
              positionFlags: {PositionFlag.xyz},
            )
            .value,
        throwsArgumentError,
      );
      context.configuration.clearObserverLocation();
      expect(
        () => context.eclipses
            .solveLocalSolarAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.262231433),
            )
            .value,
        throwsA(isA<EphemerisError>()),
      );
      expect(
        () => context.eclipses
            .localSolarCircumstancesAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2460409.256654905),
            )
            .value,
        throwsA(isA<EphemerisError>()),
      );
      context.close();
      expect(
        () => context.eclipses
            .solveSolarAtUt1(JulianDate<Ut1Scale>.fromDouble(2460409.25))
            .value,
        throwsStateError,
      );
    }, skip: !nativeLibraryAvailable);

    test(
      'computes solar route curves, polygon products, and local boundaries',
      () {
        final centerUt = JulianDate<Ut1Scale>.fromDouble(2460409.262039739);
        final centerTt = JulianDate<TtScale>.fromDouble(
          centerUt.toDouble() + 69 / 86400,
        );
        final curvesUt = context.eclipses
            .solarEclipseRouteCurvesAtUt1(centerUt, routeSampleCount: 32)
            .value;
        final curvesTt = context.eclipses
            .solarEclipseRouteCurvesAtTt(centerTt, routeSampleCount: 32)
            .value;
        final coreProduct = context.eclipses
            .solarEclipseRouteProductAtUt1(centerUt, routeSampleCount: 32)
            .value;
        final coreProductTt = context.eclipses
            .solarEclipseRouteProductAtTt(centerTt, routeSampleCount: 32)
            .value;
        final mapProduct = context.eclipses
            .solarEclipseRouteMapProductAtTt(centerTt, routeSampleCount: 32)
            .value;
        final mapProductUt = context.eclipses
            .solarEclipseRouteMapProductAtUt1(centerUt, routeSampleCount: 32)
            .value;
        final antimeridianMapProduct = context.eclipses
            .solarEclipseRouteMapProductAtUt1(
              JulianDate<Ut1Scale>.fromDouble(2451580.0342944735),
              routeSampleCount: 32,
            )
            .value;
        final boundaryUt = context.eclipses
            .localSolarEclipseBoundaryAtUt1(
              centerUt,
              longitudeDegrees: mazatlan.longitudeDegrees,
              latitudeDegrees: mazatlan.latitudeDegrees,
            )
            .value;
        final boundaryTt = context.eclipses
            .localSolarEclipseBoundaryAtTt(
              centerTt,
              longitudeDegrees: mazatlan.longitudeDegrees,
              latitudeDegrees: mazatlan.latitudeDegrees,
            )
            .value;

        expect(curvesUt, isNotEmpty);
        expect(curvesTt, isNotEmpty);
        expect(
          curvesUt.map((point) => point.kind),
          contains(SolarEclipseRouteCurveKind.centerLine),
        );
        expect(
          curvesUt.map((point) => point.kind),
          contains(SolarEclipseRouteCurveKind.penumbralNorth),
        );
        expect(
          curvesUt.map((point) => point.kind),
          contains(SolarEclipseRouteCurveKind.coreNorth),
        );
        expect(
          curvesUt.map((point) => point.kind),
          contains(SolarEclipseRouteCurveKind.halfMagnitudeNorth),
        );
        for (final point in curvesUt) {
          expect(point.latitudeDegrees.isFinite, isTrue);
          expect(point.longitudeDegrees.isFinite, isTrue);
        }

        expect(coreProduct.points, isNotEmpty);
        expect(coreProductTt.points, isNotEmpty);
        expect(
          coreProduct.summary.flags,
          contains(SolarEclipseRouteProductFlag.hasCorePolygon),
        );
        expect(
          coreProduct.summary.corePolygonPointCount,
          coreProduct.points.length,
        );
        expect(
          coreProduct.points.first.kind,
          SolarEclipseRouteProductPointKind.coreNorth,
        );
        expect(
          coreProduct.points.last.kind,
          SolarEclipseRouteProductPointKind.polygonClose,
        );
        expect(
          coreProduct.points.last.latitudeDegrees,
          closeTo(coreProduct.points.first.latitudeDegrees, 1e-12),
        );
        expect(coreProduct.summary.minimumLatitudeDegrees, isNotNull);
        expect(coreProduct.summary.maximumLatitudeDegrees, isNotNull);
        expect(
          coreProduct.summary.minimumLatitudeDegrees!,
          lessThan(coreProduct.summary.maximumLatitudeDegrees!),
        );

        expect(
          mapProduct.summary.flags,
          contains(SolarEclipseRouteProductFlag.hasCorePolygon),
        );
        expect(
          mapProduct.summary.flags,
          contains(SolarEclipseRouteProductFlag.hasPenumbralPolygon),
        );
        expect(
          mapProduct.summary.flags,
          contains(SolarEclipseRouteProductFlag.hasHalfMagnitudePolygon),
        );
        expect(mapProduct.summary.polygonPointCount, mapProduct.points.length);
        expect(
          mapProduct.summary.polygonPointCount,
          greaterThan(coreProduct.points.length),
        );
        expect(mapProductUt.points, isNotEmpty);
        expect(
          mapProductUt.summary.polygonPointCount,
          mapProductUt.points.length,
        );
        expect(
          mapProductUt.points[mapProductUt.summary.corePolygonPointCount].kind,
          SolarEclipseRouteProductPointKind.penumbralNorth,
        );
        expect(
          mapProductUt
              .points[mapProductUt.summary.corePolygonPointCount +
                  mapProductUt.summary.penumbralPolygonPointCount]
              .kind,
          SolarEclipseRouteProductPointKind.halfMagnitudeNorth,
        );
        expect(
          antimeridianMapProduct.summary.flags,
          contains(SolarEclipseRouteProductFlag.crossesAntimeridian),
        );
        expect(
          mapProduct.points[mapProduct.summary.corePolygonPointCount].kind,
          SolarEclipseRouteProductPointKind.penumbralNorth,
        );
        expect(
          mapProduct
              .points[mapProduct.summary.corePolygonPointCount +
                  mapProduct.summary.penumbralPolygonPointCount]
              .kind,
          SolarEclipseRouteProductPointKind.halfMagnitudeNorth,
        );

        expect(boundaryUt.centerKinds, contains(EclipseKind.total));
        expect(boundaryUt.centerLongitudeDegrees, isNotNull);
        expect(boundaryUt.centerLatitudeDegrees, isNotNull);
        expect(boundaryUt.umbraNorthLongitudeDegrees, isNotNull);
        expect(boundaryUt.umbraSouthLongitudeDegrees, isNotNull);
        expect(boundaryUt.penumbraNorthLongitudeDegrees, isNotNull);
        expect(boundaryUt.penumbraSouthLongitudeDegrees, isNotNull);
        expect(boundaryUt.umbraWidthKilometers, greaterThan(0));
        expect(boundaryTt.centerKinds, contains(EclipseKind.total));
        expect(
          boundaryTt.centerLongitudeDegrees,
          closeTo(boundaryUt.centerLongitudeDegrees!, 0.002),
        );

        expect(
          () => context.eclipses
              .solarEclipseRouteCurvesAtUt1(centerUt, routeSampleCount: 31)
              .value,
          throwsRangeError,
        );
        expect(
          () => context.eclipses
              .solarEclipseRouteProductAtUt1(centerUt, routeSampleCount: 4097)
              .value,
          throwsRangeError,
        );
        expect(
          () => context.eclipses
              .localSolarEclipseBoundaryAtUt1(
                centerUt,
                longitudeDegrees: double.nan,
                latitudeDegrees: mazatlan.latitudeDegrees,
              )
              .value,
          throwsArgumentError,
        );
        expect(
          () => context.eclipses
              .localSolarEclipseBoundaryAtTt(
                centerTt,
                longitudeDegrees: 0.0,
                latitudeDegrees: 90.1,
              )
              .value,
          throwsRangeError,
        );
        expect(
          () => context.eclipses
              .localSolarEclipseBoundaryAtUt1(
                centerUt,
                longitudeDegrees: 0.0,
                latitudeDegrees: -90.1,
              )
              .value,
          throwsRangeError,
        );
        expect(
          () => context.eclipses
              .solarEclipseRouteMapProductAtUt1(
                centerUt,
                positionFlags: {PositionFlag.xyz},
              )
              .value,
          throwsArgumentError,
        );
      },
      skip: !nativeLibraryAvailable,
    );
  });
}
