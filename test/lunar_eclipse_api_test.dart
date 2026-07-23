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
  const beijing = TaiyinObserverLocation(
    longitudeDegrees: 116.4074,
    latitudeDegrees: 39.9042,
    heightMeters: 43,
  );

  group('TaiyinEclipseApi lunar native integration', () {
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
        ..setObserverLocation(beijing)
        ..setStandardAtmosphere()
        ..setRouteRule(TaiyinRouteRule.opm2);
    });

    tearDown(() => context.close());

    test(
      'solves and searches TT and UT1 total-lunar eclipse results',
      () {
        final solvedUt = context.eclipses.solveLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.25),
          options: {TaiyinLunarEclipseSolveOption.includeContacts},
        );
        final solvedTt = context.eclipses.solveLunarAtTt(
          JulianDate<TtScale>.fromDouble(2460926.26),
          options: {TaiyinLunarEclipseSolveOption.includeContacts},
        );
        final nextUt = context.eclipses.nextLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.0),
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinLunarEclipseSearchOption.includeContacts},
        );
        final previousUt = context.eclipses.nextLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460927.0),
          kinds: {TaiyinEclipseKind.total},
          options: {
            TaiyinLunarEclipseSearchOption.includeContacts,
            TaiyinLunarEclipseSearchOption.backward,
          },
        );
        final nextTt = context.eclipses.nextLunarAtTt(
          JulianDate<TtScale>.fromDouble(2460926.25),
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinLunarEclipseSearchOption.includeContacts},
        );
        final rangeUt = context.eclipses.lunarEclipsesAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.0),
          JulianDate<Ut1Scale>.fromDouble(2460927.0),
          maxResults: 4,
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinLunarEclipseSearchOption.includeContacts},
        );
        final rangeTt = context.eclipses.lunarEclipsesAtTt(
          JulianDate<TtScale>.fromDouble(2451545.0),
          JulianDate<TtScale>.fromDouble(2452275.0),
          maxResults: 8,
          options: {TaiyinLunarEclipseSearchOption.includeContacts},
        );
        final noPenumbral = context.eclipses.lunarEclipsesAtTt(
          JulianDate<TtScale>.fromDouble(2451545.0),
          JulianDate<TtScale>.fromDouble(2452275.0),
          maxResults: 8,
          options: {TaiyinLunarEclipseSearchOption.excludePenumbral},
        );

        expect(solvedUt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(solvedTt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(solvedUt.value.deltaTSeconds, greaterThan(60));
        expect(
          solvedUt.value.maximum!.toDouble(),
          closeTo(2460926.258194, 2 / 1440),
        );
        expect(
          solvedUt.value.contacts[TaiyinLunarEclipseContact.totalBegin],
          isNotNull,
        );
        expect(
          solvedUt.value.contacts[TaiyinLunarEclipseContact.totalEnd],
          isNotNull,
        );
        expect(
          nextUt.value.maximum!.toDouble(),
          closeTo(solvedUt.value.maximum!.toDouble(), 2 / 1440),
        );
        expect(nextTt.value.kinds, contains(TaiyinEclipseKind.total));
        expect(
          nextTt.value.maximum!.toDouble(),
          closeTo(solvedTt.value.maximum!.toDouble(), 2 / 1440),
        );
        expect(
          previousUt.value.maximum!.toDouble(),
          closeTo(solvedUt.value.maximum!.toDouble(), 2 / 1440),
        );
        expect(rangeUt.value, hasLength(1));
        expect(rangeUt.value.single.kinds, contains(TaiyinEclipseKind.total));
        expect(rangeTt.value, hasLength(5));
        expect(rangeTt.value.first.kinds, contains(TaiyinEclipseKind.total));
        expect(rangeTt.value.last.kinds, contains(TaiyinEclipseKind.penumbral));
        expect(noPenumbral.value, hasLength(4));
        expect(
          () => context.eclipses.lunarEclipsesAtTt(
            JulianDate<TtScale>.fromDouble(2451545.0),
            JulianDate<TtScale>.fromDouble(2452275.0),
            maxResults: 1,
          ),
          throwsA(isA<TaiyinException>()),
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'derives local visibility and searches a local eclipse in TT and UT1',
      () {
        final global = context.eclipses.nextLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.0),
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinLunarEclipseSearchOption.includeContacts},
        );
        final local = context.eclipses.localLunarVisibilityAtUt1(global.value);
        final refracted = context.eclipses.localLunarVisibilityAtUt1(
          global.value,
          options: {TaiyinLocalLunarEclipseVisibilityOption.refraction},
        );
        final localSearchUt = context.eclipses.nextLocalLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.0),
          kinds: {TaiyinEclipseKind.total},
          visibilityOptions: {
            TaiyinLocalLunarEclipseVisibilityOption.refraction,
          },
        );
        final localSearchTt = context.eclipses.nextLocalLunarAtTt(
          JulianDate<TtScale>.fromDouble(2460926.25),
          kinds: {TaiyinEclipseKind.total},
        );
        final globalTt = context.eclipses.nextLunarAtTt(
          JulianDate<TtScale>.fromDouble(2460926.25),
          kinds: {TaiyinEclipseKind.total},
          options: {TaiyinLunarEclipseSearchOption.includeContacts},
        );
        final localTt = context.eclipses.localLunarVisibilityAtTt(
          globalTt.value,
        );

        final greatest = TaiyinLunarEclipseContact.greatest;
        expect(local.value.kinds, contains(TaiyinEclipseKind.total));
        expect(
          local.value.visibility,
          contains(TaiyinLocalLunarEclipseVisibilityFlag.maximumVisible),
        );
        expect(local.value.contacts[greatest], isNotNull);
        expect(
          local.value.contacts[greatest]!.moonAltitudeDegrees,
          greaterThan(0),
        );
        expect(
          refracted.value.contacts[greatest]!.moonAltitudeDegrees,
          greaterThan(local.value.contacts[greatest]!.moonAltitudeDegrees!),
        );
        expect(
          localSearchUt.value.maximum!.toDouble(),
          closeTo(global.value.maximum!.toDouble(), 1e-12),
        );
        expect(localSearchUt.value.contacts[greatest], isNotNull);
        expect(
          localSearchTt.value.visibility,
          contains(TaiyinLocalLunarEclipseVisibilityFlag.maximumVisible),
        );
        expect(
          localTt.value.contacts[greatest]!.moonAltitudeDegrees,
          greaterThan(0),
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'maps a no-eclipse lunation and rejects invalid Dart inputs',
      () {
        final none = context.eclipses.solveLunarAtTt(
          JulianDate<TtScale>.fromDouble(2451594.0),
        );
        expect(none.value.hasEclipse, isFalse);
        expect(none.value.maximum, isNull);
        expect(
          () => context.eclipses.nextLunarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460926.0),
            kinds: {TaiyinEclipseKind.annular},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.lunarEclipsesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460927.0),
            JulianDate<Ut1Scale>.fromDouble(2460926.0),
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.lunarEclipsesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460926.0),
            JulianDate<Ut1Scale>.fromDouble(2460927.0),
            maxResults: 0,
          ),
          throwsRangeError,
        );
        expect(
          () => context.eclipses.lunarEclipsesAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460926.0),
            JulianDate<Ut1Scale>.fromDouble(2460927.0),
            options: {TaiyinLunarEclipseSearchOption.backward},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.nextLunarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460926.0),
            positionFlags: {TaiyinPositionFlag.xyz},
          ),
          throwsArgumentError,
        );
        final withoutContacts = context.eclipses.solveLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.25),
        );
        expect(
          () =>
              context.eclipses.localLunarVisibilityAtUt1(withoutContacts.value),
          throwsArgumentError,
        );
        context.close();
        expect(
          () => context.eclipses.solveLunarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460926.25),
          ),
          throwsStateError,
        );
      },
      skip: !nativeLibraryAvailable,
    );
  });
}
