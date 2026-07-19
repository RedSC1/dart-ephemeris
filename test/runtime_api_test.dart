import 'dart:io';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();
  final nativeDataPath = '../taiyin-ephemeris/data';
  final lunarLimbPath = '$nativeDataPath/lunar-limb/kaguya_lalt_16ppd.tll1';

  group(
    'TaiyinRuntimeApi native integration',
    () {
      late Taiyin taiyin;

      setUp(() {
        taiyin = Taiyin.open(libraryPath: libraryPath);
      });

      tearDown(() {
        if (!taiyin.runtime.hasEopTable) {
          taiyin.runtime.loadBuiltinEopTable();
        }
        taiyin.runtime
          ..clearLunarLimbModel()
          ..clearEphemerisCache();
        taiyin.close();
      });

      test('reports Singularity release metadata', () {
        expect(taiyin.abiVersion, 1);
        expect(taiyin.libraryVersion, '1.0.0');
        expect(taiyin.libraryCodename, 'Singularity');
      });

      test('exposes catalog size and discovers a source path', () {
        final initialSize = taiyin.runtime.catalogSize;

        expect(initialSize, greaterThan(0));
        expect(taiyin.catalogSize, initialSize);
        taiyin.runtime.addSourcePath(nativeDataPath);
        expect(taiyin.runtime.catalogSize, greaterThanOrEqualTo(initialSize));
      });

      test('manages the built-in EOP table lifecycle', () {
        expect(taiyin.runtime.hasEopTable, isTrue);

        taiyin.runtime.clearEopTable();
        expect(taiyin.runtime.hasEopTable, isFalse);

        taiyin.runtime.loadBuiltinEopTable();
        expect(taiyin.runtime.hasEopTable, isTrue);
      });

      test('loads and clears a lunar-limb model', () {
        taiyin.runtime.clearLunarLimbModel();
        expect(taiyin.runtime.hasLunarLimbModel, isFalse);

        taiyin.runtime.loadLunarLimbModel(lunarLimbPath);
        expect(taiyin.runtime.hasLunarLimbModel, isTrue);

        taiyin.runtime.clearLunarLimbModel();
        expect(taiyin.runtime.hasLunarLimbModel, isFalse);
      });

      test('counts and clears ephemeris cache entries', () {
        taiyin.runtime.clearEphemerisCache();
        expect(taiyin.runtime.cacheEntryCount, 0);

        taiyin.runtime.addSourcePath(nativeDataPath);
        taiyin.context.setRouteRule(TaiyinRouteRule.opm2);
        taiyin.position.atTt(
          TaiyinBody.mercury,
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.truePosition},
        );
        expect(taiyin.runtime.cacheEntryCount, greaterThan(0));

        taiyin.runtime.clearEphemerisCache();
        expect(taiyin.runtime.cacheEntryCount, 0);
      });

      test('preserves native file errors', () {
        const missingPath = '/taiyin/this/file/does/not/exist';

        expect(
          () => taiyin.runtime.loadEopTable(missingPath),
          throwsA(
            isA<TaiyinException>()
                .having((error) => error.status, 'status', -2001)
                .having(
                  (error) => error.name,
                  'name',
                  'TAIYIN_FILE_ERROR_NOT_FOUND',
                ),
          ),
        );
        expect(
          () => taiyin.runtime.loadLunarLimbModel(missingPath),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.status,
              'status',
              -2001,
            ),
          ),
        );
        expect(
          () => taiyin.runtime.addSourcePath(missingPath),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.status,
              'status',
              -2004,
            ),
          ),
        );
      });

      test('rejects empty paths before native calls', () {
        expect(() => taiyin.runtime.addSourcePath(''), throwsArgumentError);
        expect(() => taiyin.runtime.loadEopTable(''), throwsArgumentError);
        expect(
          () => taiyin.runtime.loadLunarLimbModel(''),
          throwsArgumentError,
        );
        expect(
          () => taiyin.runtime.addSourcePath('data\u0000ignored'),
          throwsArgumentError,
        );
        expect(
          () => taiyin.runtime.loadEopTable('eop\u0000ignored'),
          throwsArgumentError,
        );
        expect(
          () => taiyin.runtime.loadLunarLimbModel('limb\u0000ignored'),
          throwsArgumentError,
        );
      });

      test('rejects runtime access after the owning context closes', () {
        final closed = taiyin.clone();
        closed.close();

        final calls = <void Function()>[
          () => closed.runtime.addSourcePath(nativeDataPath),
          () => closed.runtime.loadEopTable(nativeDataPath),
          closed.runtime.loadBuiltinEopTable,
          closed.runtime.clearEopTable,
          () => closed.runtime.hasEopTable,
          () => closed.runtime.loadLunarLimbModel(lunarLimbPath),
          closed.runtime.clearLunarLimbModel,
          () => closed.runtime.hasLunarLimbModel,
          closed.runtime.clearEphemerisCache,
          () => closed.runtime.catalogSize,
          () => closed.runtime.cacheEntryCount,
        ];

        for (final call in calls) {
          expect(call, throwsStateError);
        }
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
