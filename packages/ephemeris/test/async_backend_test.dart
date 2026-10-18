@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';
import 'support/backend_scenario.dart';
import 'support/byte_sources_scenario.dart';
import 'support/calendar_time_scenario.dart';
import 'support/native_library.dart';

void main() {
  test(
    'async native initialization preserves synchronous open',
    () async {
      final runtime = await Ephemeris.initialize(
        libraryPath: libraryPath,
        wasmModuleUri: Uri.parse('assets/taiyin_web.js'),
      );
      final ctx = runtime.createContext();
      try {
        expect(
          ctx.position
              .atTt(Body.sun, TtJulianDate.fromDouble(2460409))
              .value
              .values
              .every((v) => v.isFinite),
          isTrue,
        );
      } finally {
        ctx.close();
      }
      expect(Ephemeris.open(libraryPath: libraryPath).abiVersion, 11);
    },
    skip: !nativeLibraryAvailable ? libraryUnavailableSkip : false,
  );

  final dataRoot = Platform.environment['TAIYIN_OPM2_TEST_DATA'];
  test(
    'multi-format bytes and replacement of EOP/lunar-limb resources',
    () async {
      final runtime = await Ephemeris.initialize(
        libraryPath: libraryPath,
        options: const RuntimeOptions(loadBuiltinEop: false),
      );
      try {
        for (final name in [
          'sun',
          'moon',
          'emb',
          'mercury',
          'venus',
          'mars',
          'jupiter',
          'saturn',
          'uranus',
          'neptune',
          'pluto',
        ]) {
          runtime.addSourceBytes(
            '$name.opm2',
            File('$dataRoot/$name.opm2').readAsBytesSync(),
          );
        }
        final tkc = File(
          '$dataRoot/../../../../kepler/sbdb/sbdb-tier0-core.tkc1',
        ).readAsBytesSync();
        final stars = File(
          '$dataRoot/../../../../stars/catalogs/lite/stars-bright-v5.tsc1',
        ).readAsBytesSync();
        expect(exerciseByteSources(runtime, tkc, stars), hasLength(6));
        expect(exerciseCalendarTime(runtime), hasLength(213));
      } finally {
        await Ephemeris.initialize(libraryPath: libraryPath);
      }
    },
    skip: !nativeLibraryAvailable
        ? libraryUnavailableSkip
        : dataRoot == null
        ? 'Set TAIYIN_OPM2_TEST_DATA.'
        : false,
  );
  test(
    'Uint8List ownership, parsing, routing and context isolation',
    () async {
      final runtime = await Ephemeris.initialize(
        libraryPath: libraryPath,
        options: const RuntimeOptions(
          loadBuiltinEop: false,
          segmentCacheMaxEntries: 512,
        ),
      );
      final sources = <String, Uint8List>{};
      for (final name in [
        'sun',
        'moon',
        'emb',
        'mercury',
        'venus',
        'mars',
        'jupiter',
        'saturn',
        'uranus',
        'neptune',
        'pluto',
      ]) {
        sources['$name.opm2'] = File('$dataRoot/$name.opm2').readAsBytesSync();
      }
      expect(exerciseBackend(runtime, sources)['status'], 'PASS');
      final paths = runtime.registeredDataSources
          .map((s) => s.source)
          .where((p) => p.contains('ephemeris-bytes-'))
          .toList();
      expect(paths, hasLength(11));
      expect(paths.every((p) => File(p).existsSync()), isTrue);
      final retained = await Ephemeris.initialize(
        libraryPath: libraryPath,
        options: RuntimeOptions(sourcePaths: paths),
      );
      expect(paths.every((p) => File(p).existsSync()), isTrue);
      final retainedContext = retained.createContext();
      try {
        retainedContext.configuration.setRouteRule(RouteRule.opm2);
        expect(
          retainedContext.position
              .atTt(Body.sun, TtJulianDate.fromDouble(2460409))
              .value
              .values
              .every((v) => v.isFinite),
          isTrue,
        );
      } finally {
        retainedContext.close();
      }
      await Ephemeris.initialize(libraryPath: libraryPath);
      expect(paths.every((p) => !File(p).existsSync()), isTrue);
    },
    skip: !nativeLibraryAvailable
        ? libraryUnavailableSkip
        : dataRoot == null
        ? 'Set TAIYIN_OPM2_TEST_DATA to the DE442 OPM2 directory.'
        : false,
  );
}
