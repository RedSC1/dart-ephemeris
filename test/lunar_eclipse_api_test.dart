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

        expect(solvedUt.value.kinds, contains(EclipseKind.total));
        expect(solvedTt.value.kinds, contains(EclipseKind.total));
        expect(solvedUt.value.deltaTSeconds, greaterThan(60));
        expect(
          solvedUt.value.maximum!.toDouble(),
          closeTo(2460926.258194, 2 / 1440),
        );
        expect(
          solvedUt.value.contacts[LunarEclipseContact.totalBegin],
          isNotNull,
        );
        expect(
          solvedUt.value.contacts[LunarEclipseContact.totalEnd],
          isNotNull,
        );
        expect(
          nextUt.value.maximum!.toDouble(),
          closeTo(solvedUt.value.maximum!.toDouble(), 2 / 1440),
        );
        expect(nextTt.value.kinds, contains(EclipseKind.total));
        expect(
          nextTt.value.maximum!.toDouble(),
          closeTo(solvedTt.value.maximum!.toDouble(), 2 / 1440),
        );
        expect(
          previousUt.value.maximum!.toDouble(),
          closeTo(solvedUt.value.maximum!.toDouble(), 2 / 1440),
        );
        expect(rangeUt.value, hasLength(1));
        expect(rangeUt.value.single.kinds, contains(EclipseKind.total));
        expect(rangeTt.value, hasLength(5));
        expect(rangeTt.value.first.kinds, contains(EclipseKind.total));
        expect(rangeTt.value.last.kinds, contains(EclipseKind.penumbral));
        expect(noPenumbral.value, hasLength(4));
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
        final local = context.eclipses.localLunarVisibilityAtUt1(global.value);
        final refracted = context.eclipses.localLunarVisibilityAtUt1(
          global.value,
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
        final localTt = context.eclipses.localLunarVisibilityAtTt(
          globalTt.value,
        );

        final greatest = LunarEclipseContact.greatest;
        expect(local.value.kinds, contains(EclipseKind.total));
        expect(
          local.value.visibility,
          contains(LocalLunarEclipseVisibilityFlag.maximumVisible),
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
          contains(LocalLunarEclipseVisibilityFlag.maximumVisible),
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
