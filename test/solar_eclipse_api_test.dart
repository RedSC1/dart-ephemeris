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

    tearDown(() => context.close());

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
        expect(
          solvedUt.value.contacts[TaiyinSolarEclipseContact.centralBegin],
          isNotNull,
        );
        expect(
          solvedUt.value.contacts[TaiyinSolarEclipseContact.centralEnd],
          isNotNull,
        );
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
        expect(rangeUt.value[2].kinds, contains(TaiyinEclipseKind.partial));
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
        expect(
          localUt.value.contacts[TaiyinLocalSolarEclipseContact.centralBegin],
          isNotNull,
        );
        expect(
          localUt.value.contacts[TaiyinLocalSolarEclipseContact.centralEnd],
          isNotNull,
        );
        expect(
          localUt.value.contacts[TaiyinLocalSolarEclipseContact.greatest],
          isNotNull,
        );
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
  });
}
