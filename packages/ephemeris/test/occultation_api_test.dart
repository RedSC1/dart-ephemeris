import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  const nativeDataRoot = '../taiyin-ephemeris/data';
  const majorBodiesPath = '$nativeDataRoot/ephemerides/opm2/major-bodies/600y';
  const fixedCatalogPath =
      '$nativeDataRoot/stars/catalogs/stars-fixed-traditional.tsc1';
  const antaresLocation = ObserverLocation(
    longitudeDegrees: -78.709289952229,
    latitudeDegrees: 24.897937227562,
  );
  const mercuryLocation = ObserverLocation(
    longitudeDegrees: -144.104686755054,
    latitudeDegrees: -10.079501905368,
  );

  group(
    'OccultationApi native integration',
    () {
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
        runtime.starCatalog
          ..clear()
          ..addTsc1(fixedCatalogPath);
        context = runtime.createContext();
        context.configuration
          ..setGeocentricObserver(
            observerId: Body.earth.id,
            centerId: Body.earth.id,
          )
          ..setObserverLocation(antaresLocation)
          ..setStandardAtmosphere()
          ..useSolarDeflector()
          ..setApparentConfig(
            ApparentConfig(
              flags: {
                ApparentFlag.spherical,
                ApparentFlag.lightTime,
                ApparentFlag.aberration,
                ApparentFlag.deflection,
              },
              outputFrame: ApparentFrame.trueEclipticOfDate,
            ),
          )
          ..setRouteRule(RouteRule.opm2);
      });

      tearDown(() {
        context.close();
        runtime.starCatalog.clear();
      });

      test(
        'searches star occultations and derives visibility and where data',
        () {
          final start = JulianDate<Ut1Scale>.fromDouble(2460310.5);
          final geocentric = context.occultation
              .nextGeocentricStarAtUt1(
                'antares',
                start,
                positionFlags: {PositionFlag.truePosition},
              )
              .value;
          final local = context.occultation
              .nextLocalStarAtUt1(
                'antares',
                start,
                options: {OccultationSearchOption.oneCandidate},
              )
              .value;
          final visibility = context.occultation
              .localStarVisibilityAtUt1(
                'antares',
                local,
                options: {OccultationVisibilityOption.refraction},
              )
              .value;
          final where = context.occultation
              .starWhereAtUt1(
                'antares',
                geocentric,
                visibilityOptions: {OccultationVisibilityOption.refraction},
              )
              .value;

          expect(geocentric.kind, LunarOccultationKind.lunarStar);
          expect(geocentric.begin, isNotNull);
          expect(geocentric.end, isNotNull);
          expect(geocentric.begin!.isBefore(geocentric.coordinate), isTrue);
          expect(geocentric.end!.isAfter(geocentric.coordinate), isTrue);
          expect(
            local.coordinate.toDouble(),
            // Native's SwissEph oracle allows three seconds for this local
            // maximum; retain the same end-to-end tolerance here.
            closeTo(2460318.136560418177, 3 / 86400),
          );
          expect(visibility.firstContact, isNotNull);
          expect(visibility.maximum, isNotNull);
          expect(visibility.fourthContact, isNotNull);
          expect(visibility.secondContact, isNull);
          expect(visibility.thirdContact, isNull);
          expect(visibility.visibleIntervals, hasLength(1));
          expect(
            visibility.visibleIntervals.single.begin.isBefore(local.coordinate),
            isTrue,
          );
          expect(where.centerLineHitsEarth, isTrue);
          expect(where.types, contains(OccultationType.central));
          expect(where.maximumLocation, isNotNull);
          expect(
            where.maximumLocation!.longitudeDegrees,
            inInclusiveRange(-180.0, 180.0),
          );
          expect(
            where.maximumLocation!.latitudeDegrees,
            inInclusiveRange(-90.0, 90.0),
          );
          expect(where.centerLinePath, isNotEmpty);
          expect(where.visibleRegionPolygon, isNotEmpty);
        },
      );

      test('searches body occultations with standard and custom radii', () {
        final start = JulianDate<Ut1Scale>.fromDouble(2460900.5);
        final geocentric = context.occultation
            .nextGeocentricBodyAtUt1(Body.mercury, start)
            .value;
        final enlarged = context.occultation
            .nextGeocentricBodyAtUt1(
              Body.mercury,
              start,
              targetRadiusKilometers: 2 * 2439.7,
              options: {OccultationSearchOption.filterTotal},
            )
            .value;

        context.configuration.setObserverLocation(mercuryLocation);
        final local = context.occultation
            .nextLocalBodyAtUt1(Body.mercury, start)
            .value;
        final localWithRadius = context.occultation
            .nextLocalBodyAtUt1(
              Body.mercury,
              start,
              targetRadiusKilometers: 2 * 2439.7,
            )
            .value;
        final visibility = context.occultation
            .localBodyVisibilityAtUt1(Body.mercury, local)
            .value;
        final where = context.occultation
            .bodyWhereAtUt1(Body.mercury, geocentric)
            .value;
        final whereWithRadius = context.occultation
            .bodyWhereAtUt1(
              Body.mercury,
              enlarged,
              targetRadiusKilometers: 2 * 2439.7,
            )
            .value;

        expect(geocentric.kind, LunarOccultationKind.lunarBody);
        expect(
          geocentric.coordinate.toDouble(),
          closeTo(2461090.465108, 10 / 86400),
        );
        expect(
          enlarged.targetRadiusRadians,
          greaterThan(geocentric.targetRadiusRadians),
        );
        expect(
          enlarged.firstContact!.isBefore(geocentric.firstContact!),
          isTrue,
        );
        expect(
          enlarged.fourthContact!.isAfter(geocentric.fourthContact!),
          isTrue,
        );
        expect(local.secondContact, isNotNull);
        expect(local.thirdContact, isNotNull);
        expect(
          localWithRadius.targetRadiusRadians,
          greaterThan(local.targetRadiusRadians),
        );
        expect(visibility.firstContact, isNotNull);
        expect(visibility.secondContact, isNotNull);
        expect(visibility.thirdContact, isNotNull);
        expect(visibility.fourthContact, isNotNull);
        expect(visibility.visibleIntervals, isNotEmpty);
        expect(where.maximumLocation, isNotNull);
        expect(where.types, contains(OccultationType.central));
        expect(
          whereWithRadius.targetRadiusRadians,
          greaterThan(where.targetRadiusRadians!),
        );
      });

      test('rejects invalid Dart inputs and use after close', () {
        final start = JulianDate<Ut1Scale>.fromDouble(2460900.5);
        expect(
          () => context.occultation
              .nextGeocentricBodyAtUt1(Body.moon, start)
              .value,
          throwsArgumentError,
        );
        expect(
          () => context.occultation
              .nextGeocentricBodyAtUt1(Body.solarSystemBarycenter, start)
              .value,
          throwsArgumentError,
        );
        expect(
          () => context.occultation
              .nextGeocentricBodyAtUt1(
                Body.mercury,
                start,
                targetRadiusKilometers: -1,
              )
              .value,
          throwsArgumentError,
        );
        expect(
          () => context.occultation.nextGeocentricStarAtUt1('', start).value,
          throwsArgumentError,
        );
        expect(
          () => context.occultation
              .nextGeocentricStarAtUt1(
                'antares',
                start,
                positionFlags: {PositionFlag.xyz},
              )
              .value,
          throwsArgumentError,
        );
        final star = context.occultation
            .nextGeocentricStarAtUt1(
              'antares',
              JulianDate<Ut1Scale>.fromDouble(2460310.5),
            )
            .value;
        expect(
          () => context.occultation
              .localBodyVisibilityAtUt1(Body.mercury, star)
              .value,
          throwsArgumentError,
        );
        context.close();
        expect(
          () => context.occultation
              .nextGeocentricStarAtUt1('antares', start)
              .value,
          throwsStateError,
        );
      });
    },
    skip: !nativeLibraryAvailable
        ? 'native test library is unavailable'
        : false,
  );
}
