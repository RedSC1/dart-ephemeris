import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  const nativeDataRoot = '../taiyin-ephemeris/data';
  const majorBodiesPath = '$nativeDataRoot/ephemerides/opm2/major-bodies/600y';
  const beijing = ObserverLocation(
    longitudeDegrees: 116.4074,
    latitudeDegrees: 39.9042,
    heightMeters: 43,
  );

  group('EclipseApi lunar native integration', () {
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
        ..setObserverLocation(beijing)
        ..setStandardAtmosphere()
        ..setRouteRule(RouteRule.opm2);
    });

    tearDown(() => context.close());

    test(
      'solves and searches TT and UT1 total-lunar eclipse results',
      () {
        final solvedUt = context.eclipses.solveLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.25),
          options: {LunarEclipseSolveOption.includeContacts},
        );
        final solvedTt = context.eclipses.solveLunarAtTt(
          JulianDate<TtScale>.fromDouble(2460926.26),
          options: {LunarEclipseSolveOption.includeContacts},
        );
        final nextUt = context.eclipses.nextLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.0),
          kinds: {EclipseKind.total},
          options: {LunarEclipseSearchOption.includeContacts},
        );
        final previousUt = context.eclipses.nextLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460927.0),
          kinds: {EclipseKind.total},
          options: {
            LunarEclipseSearchOption.includeContacts,
            LunarEclipseSearchOption.backward,
          },
        );
        final nextTt = context.eclipses.nextLunarAtTt(
          JulianDate<TtScale>.fromDouble(2460926.25),
          kinds: {EclipseKind.total},
          options: {LunarEclipseSearchOption.includeContacts},
        );
        final rangeUt = context.eclipses.lunarEclipsesAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.0),
          JulianDate<Ut1Scale>.fromDouble(2460927.0),
          maxResults: 4,
          kinds: {EclipseKind.total},
          options: {LunarEclipseSearchOption.includeContacts},
        );
        final rangeTt = context.eclipses.lunarEclipsesAtTt(
          JulianDate<TtScale>.fromDouble(2451545.0),
          JulianDate<TtScale>.fromDouble(2452275.0),
          maxResults: 8,
          options: {LunarEclipseSearchOption.includeContacts},
        );
        final noPenumbral = context.eclipses.lunarEclipsesAtTt(
          JulianDate<TtScale>.fromDouble(2451545.0),
          JulianDate<TtScale>.fromDouble(2452275.0),
          maxResults: 8,
          options: {LunarEclipseSearchOption.excludePenumbral},
        );

        expect(solvedUt.kinds, contains(EclipseKind.total));
        expect(solvedTt.kinds, contains(EclipseKind.total));
        expect(solvedUt.deltaTSeconds, greaterThan(60));
        expect(solvedUt.maximum!.toDouble(), closeTo(2460926.258194, 2 / 1440));
        expect(solvedUt.contacts[LunarEclipseContact.totalBegin], isNotNull);
        expect(solvedUt.contacts[LunarEclipseContact.totalEnd], isNotNull);
        expect(
          nextUt.maximum!.toDouble(),
          closeTo(solvedUt.maximum!.toDouble(), 2 / 1440),
        );
        expect(nextTt.kinds, contains(EclipseKind.total));
        expect(
          nextTt.maximum!.toDouble(),
          closeTo(solvedTt.maximum!.toDouble(), 2 / 1440),
        );
        expect(
          previousUt.maximum!.toDouble(),
          closeTo(solvedUt.maximum!.toDouble(), 2 / 1440),
        );
        expect(rangeUt, hasLength(1));
        expect(rangeUt.single.kinds, contains(EclipseKind.total));
        expect(rangeTt, hasLength(5));
        expect(rangeTt.first.kinds, contains(EclipseKind.total));
        expect(rangeTt.last.kinds, contains(EclipseKind.penumbral));
        expect(noPenumbral, hasLength(4));
        expect(
          () => context.eclipses.lunarEclipsesAtTt(
            JulianDate<TtScale>.fromDouble(2451545.0),
            JulianDate<TtScale>.fromDouble(2452275.0),
            maxResults: 1,
          ),
          throwsA(isA<EphemerisError>()),
        );
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'derives local visibility and searches a local eclipse in TT and UT1',
      () {
        final global = context.eclipses.nextLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.0),
          kinds: {EclipseKind.total},
          options: {LunarEclipseSearchOption.includeContacts},
        );
        final local = context.eclipses.localLunarVisibilityAtUt1(global);
        final refracted = context.eclipses.localLunarVisibilityAtUt1(
          global,
          options: {LocalLunarEclipseVisibilityOption.refraction},
        );
        final localSearchUt = context.eclipses.nextLocalLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.0),
          kinds: {EclipseKind.total},
          visibilityOptions: {LocalLunarEclipseVisibilityOption.refraction},
        );
        final localSearchTt = context.eclipses.nextLocalLunarAtTt(
          JulianDate<TtScale>.fromDouble(2460926.25),
          kinds: {EclipseKind.total},
        );
        final globalTt = context.eclipses.nextLunarAtTt(
          JulianDate<TtScale>.fromDouble(2460926.25),
          kinds: {EclipseKind.total},
          options: {LunarEclipseSearchOption.includeContacts},
        );
        final localTt = context.eclipses.localLunarVisibilityAtTt(globalTt);

        final greatest = LunarEclipseContact.greatest;
        expect(local.kinds, contains(EclipseKind.total));
        expect(
          local.visibility,
          contains(LocalLunarEclipseVisibilityFlag.maximumVisible),
        );
        expect(local.contacts[greatest], isNotNull);
        expect(local.contacts[greatest]!.moonAltitudeDegrees, greaterThan(0));
        expect(
          refracted.contacts[greatest]!.moonAltitudeDegrees,
          greaterThan(local.contacts[greatest]!.moonAltitudeDegrees!),
        );
        expect(
          localSearchUt.maximum!.toDouble(),
          closeTo(global.maximum!.toDouble(), 1e-12),
        );
        expect(localSearchUt.contacts[greatest], isNotNull);
        expect(
          localSearchTt.visibility,
          contains(LocalLunarEclipseVisibilityFlag.maximumVisible),
        );
        expect(localTt.contacts[greatest]!.moonAltitudeDegrees, greaterThan(0));
      },
      skip: !nativeLibraryAvailable,
    );

    test(
      'maps a no-eclipse lunation and rejects invalid Dart inputs',
      () {
        final none = context.eclipses.solveLunarAtTt(
          JulianDate<TtScale>.fromDouble(2451594.0),
        );
        expect(none.hasEclipse, isFalse);
        expect(none.maximum, isNull);
        expect(
          () => context.eclipses.nextLunarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460926.0),
            kinds: {EclipseKind.annular},
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
            options: {LunarEclipseSearchOption.backward},
          ),
          throwsArgumentError,
        );
        expect(
          () => context.eclipses.nextLunarAtUt1(
            JulianDate<Ut1Scale>.fromDouble(2460926.0),
            positionFlags: {PositionFlag.xyz},
          ),
          throwsArgumentError,
        );
        final withoutContacts = context.eclipses.solveLunarAtUt1(
          JulianDate<Ut1Scale>.fromDouble(2460926.25),
        );
        expect(
          () => context.eclipses.localLunarVisibilityAtUt1(withoutContacts),
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
