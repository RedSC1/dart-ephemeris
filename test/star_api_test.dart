import 'dart:io';
import 'dart:typed_data';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();
  const nativeDataRoot = '../taiyin-ephemeris/data';
  const fixedCatalogPath =
      '$nativeDataRoot/stars/catalogs/stars-fixed-traditional.tsc1';
  const majorBodiesPath = '$nativeDataRoot/ephemerides/opm2/major-bodies/600y';

  group(
    'Taiyin Star API native integration',
    () {
      late Taiyin runtime;
      late TaiyinContext context;
      late Directory temporaryDirectory;
      final tt = JulianDate<TtScale>.fromDouble(2460409.0);
      final ut1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);
      final tdb = JulianDate<TdbScale>.fromDouble(2460409.0);

      setUp(() {
        runtime = Taiyin.open(
          libraryPath: libraryPath,
          options: const TaiyinRuntimeOptions(
            sourcePaths: [majorBodiesPath],
            loadPackagedData: false,
          ),
        );
        runtime.starCatalog
          ..clear()
          ..addTsc1(fixedCatalogPath);
        context = runtime.createContext();
        temporaryDirectory = Directory.systemTemp.createTempSync(
          'taiyin-dart-star-',
        );
      });

      tearDown(() {
        context.close();
        runtime.starCatalog.clear();
        temporaryDirectory.deleteSync(recursive: true);
      });

      test('loads TSC1 catalogs and resolves magnitude aliases', () {
        expect(runtime.starCatalog.count, 1);
        expect(runtime.starCatalog.magnitudeOf('spica').isFinite, isTrue);
        expect(runtime.starCatalog.magnitudeOf('Spica').isFinite, isTrue);

        runtime.starCatalog.clear();
        expect(runtime.starCatalog.count, 0);
      });

      test('copies caller-owned TSC1 bytes before returning', () {
        final bytes = File(fixedCatalogPath).readAsBytesSync();
        runtime.starCatalog
          ..clear()
          ..addTsc1Bytes(bytes);

        bytes.fillRange(0, bytes.length, 0);

        expect(runtime.starCatalog.count, 1);
        expect(runtime.starCatalog.magnitudeOf('spica').isFinite, isTrue);
      });

      test('loads editable TSF1 catalogs', () {
        final path = '${temporaryDirectory.path}/custom-stars.tsf1';
        File(path).writeAsStringSync('''
TSF1
version=1
star_count=1

star.0.id=custom_star
star.0.name=Custom Star
star.0.aliases=custom-star-alias
star.0.ra_deg=180
star.0.dec_deg=45
star.0.pm_ra_mas_yr=1
star.0.pm_dec_mas_yr=-2
star.0.parallax_mas=0
star.0.radial_velocity_km_s=0
star.0.reference_epoch=2000
star.0.magnitude=5.5
''');

        runtime.starCatalog
          ..clear()
          ..addTsf1(path);

        expect(runtime.starCatalog.count, 1);
        expect(runtime.starCatalog.magnitudeOf('Custom Star'), 5.5);
        expect(runtime.starCatalog.magnitudeOf('custom-star-alias'), 5.5);
      });

      test('covers TDB, TT, UT1, and explicit Delta-T positions', () {
        const flags = {
          TaiyinPositionFlag.xyz,
          TaiyinPositionFlag.speed,
          TaiyinPositionFlag.truePosition,
        };
        final results = [
          context.stars.atTdb('spica', tdb, tt, flags: flags),
          context.stars.atTt('spica', tt, flags: flags),
          context.stars.atUt1('spica', ut1, flags: flags),
          context.stars.atUt1WithDeltaT('spica', ut1, 69.184, flags: flags),
        ];

        for (final result in results) {
          expect(result.value.starKey, 'spica');
          expect(result.value.values, hasLength(6));
          expect(result.value.values.every((value) => value.isFinite), isTrue);
          expect(result.value.isCartesian, isTrue);
          expect(result.diagnostic.status, 0);
          expect(result.diagnostic.julianDateTdb.isFinite, isTrue);
        }
      });

      test('batch time routes preserve keys and match single results', () {
        const keys = ['spica', 'antares'];
        const flags = {TaiyinPositionFlag.xyz, TaiyinPositionFlag.truePosition};
        final batches = [
          context.stars.batchAtTdb(keys, tdb, tt, flags: flags),
          context.stars.batchAtTt(keys, tt, flags: flags),
          context.stars.batchAtUt1(keys, ut1, flags: flags),
          context.stars.batchAtUt1WithDeltaT(keys, ut1, 69.184, flags: flags),
        ];

        for (final batch in batches) {
          expect(batch, hasLength(keys.length));
          expect([for (final result in batch) result.value.starKey], keys);
          expect(
            batch.every(
              (result) =>
                  result.diagnostic.status == 0 &&
                  result.value.values.every((value) => value.isFinite),
            ),
            isTrue,
          );
        }

        final batch = context.stars.batchAtTt(keys, tt, flags: flags);
        for (var index = 0; index < keys.length; index++) {
          final single = context.stars.atTt(keys[index], tt, flags: flags);
          for (var valueIndex = 0; valueIndex < 6; valueIndex++) {
            expect(
              batch[index].value.values[valueIndex],
              closeTo(single.value.values[valueIndex], 1e-15),
            );
          }
        }
        expect(context.stars.batchAtTt(const [], tt), isEmpty);
      });

      test(
        'position batches preserve a successful star when another fails',
        () {
          final batch = context.stars.batchAtTt(
            const ['spica', 'missing-star'],
            tt,
            flags: {TaiyinPositionFlag.xyz},
          );

          expect(batch, hasLength(2));
          expect(batch[0].diagnostic.status, 0);
          expect(
            batch[0].value.values.every((value) => value.isFinite),
            isTrue,
          );
          expect(batch[1].diagnostic.status, isNot(0));
        },
      );

      test('calculates single and batch observed star positions', () {
        const flags = {
          TaiyinObservedFlag.speed,
          TaiyinObservedFlag.truePosition,
        };
        final single = context.stars.observedAtUt1('spica', ut1, flags: flags);
        final batch = context.stars.observedBatchAtUt1(
          const ['spica', 'antares'],
          ut1,
          flags: flags,
        );

        expect(single.starKey, 'spica');
        expect(single.status, 0);
        expect(single.diagnostic.status, 0);
        expect(single.apparent.starKey, 'spica');
        expect(single.apparent.longitudeRadians.isFinite, isTrue);
        expect(single.apparent.latitudeRadians.isFinite, isTrue);
        expect(single.apparent.distanceAu, greaterThan(0));
        expect(
          single.apparent.apparentState.velocityAuPerDay.values.every(
            (value) => value.isFinite,
          ),
          isTrue,
        );
        expect(batch, hasLength(2));
        expect(
          [for (final value in batch) value.starKey],
          ['spica', 'antares'],
        );
        expect(
          batch.first.apparent.longitudeRadians,
          closeTo(single.apparent.longitudeRadians, 1e-15),
        );
        expect(context.stars.observedBatchAtUt1(const [], ut1), isEmpty);
      });

      test('maps topocentric horizontal observed star output', () {
        context.configuration.setObserverLocation(
          const TaiyinObserverLocation(
            longitudeDegrees: 116.391,
            latitudeDegrees: 39.907,
            heightMeters: 50,
          ),
        );

        final result = context.stars.observedAtUt1(
          'spica',
          ut1,
          flags: {
            TaiyinObservedFlag.speed,
            TaiyinObservedFlag.topocentric,
            TaiyinObservedFlag.horizontal,
            TaiyinObservedFlag.truePosition,
          },
        );

        expect(result.horizontal, isNotNull);
        expect(result.horizontal!.azimuthRadians.isFinite, isTrue);
        expect(result.horizontal!.altitudeRadians.isFinite, isTrue);
        expect(result.horizontalRates, isNotNull);
        expect(result.horizontalRates!.azimuthRadiansPerDay.isFinite, isTrue);
        expect(result.refractedHorizontal, isNull);
      });

      test('reports failed observed stars and rejects invalid Dart inputs', () {
        expect(
          () => context.stars.observedBatchAtUt1(const [
            'spica',
            'missing-star',
          ], ut1),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.status,
              'status',
              isNot(0),
            ),
          ),
        );
        expect(
          () => context.stars.observedAtUt1(
            'spica',
            ut1,
            flags: {TaiyinObservedFlag.horizontal},
          ),
          throwsArgumentError,
        );
        expect(() => context.stars.atTt('', tt), throwsArgumentError);
        expect(
          () => context.stars.atTt('spica\u0000ignored', tt),
          throwsArgumentError,
        );
        expect(
          () => context.stars.batchAtTt(const ['spica', ''], tt),
          throwsArgumentError,
        );
        expect(
          () => context.stars.atUt1WithDeltaT('spica', ut1, double.nan),
          throwsArgumentError,
        );
        expect(() => runtime.starCatalog.addTsc1(''), throwsArgumentError);
        expect(
          () => runtime.starCatalog.addTsf1('stars\u0000ignored'),
          throwsArgumentError,
        );
        expect(
          () => runtime.starCatalog.addTsc1Bytes(Uint8List(0)),
          throwsArgumentError,
        );
        expect(() => runtime.starCatalog.magnitudeOf(''), throwsArgumentError);
        expect(
          () => runtime.starCatalog.addTsc1(
            '${temporaryDirectory.path}/missing.tsc1',
          ),
          throwsA(isA<TaiyinException>()),
        );

        context.close();
        expect(() => context.stars.atTt('spica', tt), throwsStateError);
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
