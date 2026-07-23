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
  const fixedCatalogPath =
      '$nativeDataRoot/stars/catalogs/stars-fixed-traditional.tsc1';
  const antaresLocation = TaiyinObserverLocation(
    longitudeDegrees: -78.709289952229,
    latitudeDegrees: 24.897937227562,
  );
  const mercuryLocation = TaiyinObserverLocation(
    longitudeDegrees: -144.104686755054,
    latitudeDegrees: -10.079501905368,
  );

  group(
    'TaiyinOccultationApi native integration',
    () {
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
        runtime.starCatalog
          ..clear()
          ..addTsc1(fixedCatalogPath);
        context = runtime.createContext();
        context.configuration
          ..setGeocentricObserver(
            observerId: TaiyinBody.earth.id,
            centerId: TaiyinBody.earth.id,
          )
          ..setObserverLocation(antaresLocation)
          ..setStandardAtmosphere()
          ..useSolarDeflector()
          ..setApparentConfig(
            TaiyinApparentConfig(
              flags: {
                TaiyinApparentFlag.spherical,
                TaiyinApparentFlag.lightTime,
                TaiyinApparentFlag.aberration,
                TaiyinApparentFlag.deflection,
              },
              outputFrame: TaiyinApparentFrame.trueEclipticOfDate,
            ),
          )
          ..setRouteRule(TaiyinRouteRule.opm2);
      });

      tearDown(() {
        context.close();
        runtime.starCatalog.clear();
      });

      test(
        'searches star occultations and derives visibility and where data',
        () {
          final start = JulianDate<Ut1Scale>.fromDouble(2460310.5);
          final geocentric = context.occultation.nextGeocentricStarAtUt1(
            'antares',
            start,
            positionFlags: {TaiyinPositionFlag.truePosition},
          );
          final local = context.occultation.nextLocalStarAtUt1(
            'antares',
            start,
            options: {TaiyinOccultationSearchOption.oneCandidate},
          );
          final visibility = context.occultation.localStarVisibilityAtUt1(
            'antares',
            local.value,
            options: {TaiyinOccultationVisibilityOption.refraction},
          );
          final where = context.occultation.starWhereAtUt1(
            'antares',
            geocentric.value,
            visibilityOptions: {TaiyinOccultationVisibilityOption.refraction},
          );

          expect(geocentric.value.kind, TaiyinLunarOccultationKind.lunarStar);
          expect(geocentric.value.begin, isNotNull);
          expect(geocentric.value.end, isNotNull);
          expect(
            geocentric.value.begin!.isBefore(geocentric.value.coordinate),
            isTrue,
          );
          expect(
            geocentric.value.end!.isAfter(geocentric.value.coordinate),
            isTrue,
          );
          expect(
            local.value.coordinate.toDouble(),
            // Native's SwissEph oracle allows three seconds for this local
            // maximum; retain the same end-to-end tolerance here.
            closeTo(2460318.136560418177, 3 / 86400),
          );
          expect(visibility.value.firstContact, isNotNull);
          expect(visibility.value.maximum, isNotNull);
          expect(visibility.value.fourthContact, isNotNull);
          expect(visibility.value.secondContact, isNull);
          expect(visibility.value.thirdContact, isNull);
          expect(visibility.value.visibleIntervals, hasLength(1));
          expect(
            visibility.value.visibleIntervals.single.begin.isBefore(
              local.value.coordinate,
            ),
            isTrue,
          );
          expect(where.value.centerLineHitsEarth, isTrue);
          expect(where.value.types, contains(TaiyinOccultationType.central));
          expect(where.value.maximumLocation, isNotNull);
          expect(
            where.value.maximumLocation!.longitudeDegrees,
            inInclusiveRange(-180.0, 180.0),
          );
          expect(
            where.value.maximumLocation!.latitudeDegrees,
            inInclusiveRange(-90.0, 90.0),
          );
          expect(where.value.centerLinePath, isNotEmpty);
          expect(where.value.visibleRegionPolygon, isNotEmpty);
        },
      );

      test('searches body occultations with standard and custom radii', () {
        final start = JulianDate<Ut1Scale>.fromDouble(2460900.5);
        final geocentric = context.occultation.nextGeocentricBodyAtUt1(
          TaiyinBody.mercury,
          start,
        );
        final enlarged = context.occultation.nextGeocentricBodyAtUt1(
          TaiyinBody.mercury,
          start,
          targetRadiusKilometers: 2 * 2439.7,
          options: {TaiyinOccultationSearchOption.filterTotal},
        );

        context.configuration.setObserverLocation(mercuryLocation);
        final local = context.occultation.nextLocalBodyAtUt1(
          TaiyinBody.mercury,
          start,
        );
        final localWithRadius = context.occultation.nextLocalBodyAtUt1(
          TaiyinBody.mercury,
          start,
          targetRadiusKilometers: 2 * 2439.7,
        );
        final visibility = context.occultation.localBodyVisibilityAtUt1(
          TaiyinBody.mercury,
          local.value,
        );
        final where = context.occultation.bodyWhereAtUt1(
          TaiyinBody.mercury,
          geocentric.value,
        );
        final whereWithRadius = context.occultation.bodyWhereAtUt1(
          TaiyinBody.mercury,
          enlarged.value,
          targetRadiusKilometers: 2 * 2439.7,
        );

        expect(geocentric.value.kind, TaiyinLunarOccultationKind.lunarBody);
        expect(
          geocentric.value.coordinate.toDouble(),
          closeTo(2461090.465108, 10 / 86400),
        );
        expect(
          enlarged.value.targetRadiusRadians,
          greaterThan(geocentric.value.targetRadiusRadians),
        );
        expect(
          enlarged.value.firstContact!.isBefore(geocentric.value.firstContact!),
          isTrue,
        );
        expect(
          enlarged.value.fourthContact!.isAfter(
            geocentric.value.fourthContact!,
          ),
          isTrue,
        );
        expect(local.value.secondContact, isNotNull);
        expect(local.value.thirdContact, isNotNull);
        expect(
          localWithRadius.value.targetRadiusRadians,
          greaterThan(local.value.targetRadiusRadians),
        );
        expect(visibility.value.firstContact, isNotNull);
        expect(visibility.value.secondContact, isNotNull);
        expect(visibility.value.thirdContact, isNotNull);
        expect(visibility.value.fourthContact, isNotNull);
        expect(visibility.value.visibleIntervals, isNotEmpty);
        expect(where.value.maximumLocation, isNotNull);
        expect(where.value.types, contains(TaiyinOccultationType.central));
        expect(
          whereWithRadius.value.targetRadiusRadians,
          greaterThan(where.value.targetRadiusRadians!),
        );
      });

      test('rejects invalid Dart inputs and use after close', () {
        final start = JulianDate<Ut1Scale>.fromDouble(2460900.5);
        expect(
          () => context.occultation.nextGeocentricBodyAtUt1(
            TaiyinBody.moon,
            start,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.occultation.nextGeocentricBodyAtUt1(
            TaiyinBody.solarSystemBarycenter,
            start,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.occultation.nextGeocentricBodyAtUt1(
            TaiyinBody.mercury,
            start,
            targetRadiusKilometers: -1,
          ),
          throwsArgumentError,
        );
        expect(
          () => context.occultation.nextGeocentricStarAtUt1('', start),
          throwsArgumentError,
        );
        expect(
          () => context.occultation.nextGeocentricStarAtUt1(
            'antares',
            start,
            positionFlags: {TaiyinPositionFlag.xyz},
          ),
          throwsArgumentError,
        );
        final star = context.occultation.nextGeocentricStarAtUt1(
          'antares',
          JulianDate<Ut1Scale>.fromDouble(2460310.5),
        );
        expect(
          () => context.occultation.localBodyVisibilityAtUt1(
            TaiyinBody.mercury,
            star.value,
          ),
          throwsArgumentError,
        );
        context.close();
        expect(
          () => context.occultation.nextGeocentricStarAtUt1('antares', start),
          throwsStateError,
        );
      });
    },
    skip: !nativeLibraryAvailable
        ? 'native test library is unavailable'
        : false,
  );
}
