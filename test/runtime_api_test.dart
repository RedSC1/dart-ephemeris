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
    'Taiyin global runtime native integration',
    () {
      late Taiyin runtime;
      late TaiyinContext context;

      setUp(() {
        runtime = Taiyin.open(libraryPath: libraryPath);
        context = runtime.createContext();
      });

      tearDown(() {
        if (!runtime.hasEopTable) {
          runtime.loadBuiltinEopTable();
        }
        runtime
          ..clearLunarLimbModel()
          ..clearEphemerisCache();
        context.close();
      });

      test('reports Singularity release metadata', () {
        expect(runtime.abiVersion, 1);
        expect(runtime.libraryVersion, '1.0.0');
        expect(runtime.libraryCodename, 'Singularity');
      });

      test('exposes catalog size and discovers a source path', () {
        final initialSize = runtime.catalogSize;

        expect(initialSize, greaterThan(0));
        expect(runtime.catalogSize, initialSize);
        runtime.addSourcePath(nativeDataPath);
        expect(runtime.catalogSize, greaterThanOrEqualTo(initialSize));
      });

      test('manages the built-in EOP table lifecycle', () {
        expect(runtime.hasEopTable, isTrue);

        runtime.clearEopTable();
        expect(runtime.hasEopTable, isFalse);

        runtime.loadBuiltinEopTable();
        expect(runtime.hasEopTable, isTrue);
      });

      test('loads and clears a lunar-limb model', () {
        runtime.clearLunarLimbModel();
        expect(runtime.hasLunarLimbModel, isFalse);

        runtime.loadLunarLimbModel(lunarLimbPath);
        expect(runtime.hasLunarLimbModel, isTrue);

        runtime.clearLunarLimbModel();
        expect(runtime.hasLunarLimbModel, isFalse);
      });

      test('counts and clears ephemeris cache entries', () {
        runtime.clearEphemerisCache();
        expect(runtime.cacheEntryCount, 0);

        runtime.addSourcePath(nativeDataPath);
        context.configuration.setRouteRule(TaiyinRouteRule.opm2);
        context.position.atTt(
          TaiyinBody.mercury,
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.truePosition},
        );
        expect(runtime.cacheEntryCount, greaterThan(0));

        runtime.clearEphemerisCache();
        expect(runtime.cacheEntryCount, 0);
      });

      test('preserves native file errors', () {
        const missingPath = '/taiyin/this/file/does/not/exist';

        expect(
          () => runtime.loadEopTable(missingPath),
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
          () => runtime.loadLunarLimbModel(missingPath),
          throwsA(
            isA<TaiyinException>().having(
              (error) => error.status,
              'status',
              -2001,
            ),
          ),
        );
        expect(
          () => runtime.addSourcePath(missingPath),
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
        expect(() => runtime.addSourcePath(''), throwsArgumentError);
        expect(() => runtime.loadEopTable(''), throwsArgumentError);
        expect(() => runtime.loadLunarLimbModel(''), throwsArgumentError);
        expect(
          () => runtime.addSourcePath('data\u0000ignored'),
          throwsArgumentError,
        );
        expect(
          () => runtime.loadEopTable('eop\u0000ignored'),
          throwsArgumentError,
        );
        expect(
          () => runtime.loadLunarLimbModel('limb\u0000ignored'),
          throwsArgumentError,
        );
      });

      test('runtime lifetime is independent from user contexts', () {
        final closed = runtime.createContext();
        closed.close();

        expect(runtime.catalogSize, greaterThan(0));
        expect(runtime.hasEopTable, isTrue);

        final surviving = runtime.createContext();
        try {
          expect(
            surviving.position
                .atTt(
                  TaiyinBody.moon,
                  JulianDate<TtScale>.fromDouble(2460409.0),
                  flags: {TaiyinPositionFlag.xyz},
                )
                .value
                .values,
            everyElement(isA<double>()),
          );
        } finally {
          surviving.close();
        }
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
