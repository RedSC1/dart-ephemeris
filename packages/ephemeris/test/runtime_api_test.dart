import 'package:ephemeris/src/native_compatibility.dart';
import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  final nativeDataPath = '../taiyin-ephemeris/data';
  final lunarLimbPath = '$nativeDataPath/lunar-limb/kaguya_lalt_16ppd.tll1';

  group(
    'Ephemeris global runtime native integration',
    () {
      late Ephemeris runtime;
      late EphemerisContext context;

      setUp(() {
        runtime = Ephemeris.open(libraryPath: libraryPath);
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
        expect(runtime.abiVersion, taiyinSupportedAbiVersion);
        expect(runtime.libraryVersion, '1.0.0-beta.3');
        expect(runtime.libraryCodename, 'Singularity');
      });

      test('opens the bundled native library without an explicit path', () {
        final bundled = Ephemeris.open();
        expect(bundled.abiVersion, taiyinSupportedAbiVersion);
      });

      test('formats structured native diagnostics for logs', () {
        context.position
            .atTt(
              Body.moon,
              JulianDate<TtScale>.fromDouble(2460409.0),
              flags: {PositionFlag.xyz},
            )
            .value;
        final diagnostic = context.lastDiagnostic!;

        final formatted = runtime.formatEphemerisDiagnostic(diagnostic);

        expect(formatted, contains('status=TAIYIN_STATUS_OK(0)'));
        expect(formatted, contains('target=${Body.moon.id}'));
        expect(formatted, contains('jd_tdb='));

        final aliasedDiagnostic = EphemerisDiagnostic(
          status: diagnostic.status,
          targetId: diagnostic.targetId + 0x100000000,
          centerId: diagnostic.centerId,
          frame: diagnostic.frame,
          rawFrameId: diagnostic.rawFrameId,
          julianDateTdb: diagnostic.julianDateTdb,
          candidateCount: diagnostic.candidateCount,
          attemptedMethodId: diagnostic.attemptedMethodId,
          nearestCoverageStart: diagnostic.nearestCoverageStart,
          nearestCoverageEnd: diagnostic.nearestCoverageEnd,
          componentTargetId: diagnostic.componentTargetId,
          componentCenterId: diagnostic.componentCenterId,
          componentMethodId: diagnostic.componentMethodId,
          timeScaleRoute: diagnostic.timeScaleRoute,
          rawTimeScaleRouteId: diagnostic.rawTimeScaleRouteId,
          timeScaleFallbackReason: diagnostic.timeScaleFallbackReason,
          rawTimeScaleFallbackReasonId: diagnostic.rawTimeScaleFallbackReasonId,
          timeScaleFlags: diagnostic.timeScaleFlags,
          taiMinusUtcSeconds: diagnostic.taiMinusUtcSeconds,
          dut1Seconds: diagnostic.dut1Seconds,
          deltaTSeconds: diagnostic.deltaTSeconds,
        );
        expect(
          () => runtime.formatEphemerisDiagnostic(aliasedDiagnostic),
          throwsRangeError,
        );
      });

      test('rejects status codes before native int32 narrowing', () {
        for (final status in [-0x80000001, 0x80000000]) {
          expect(() => runtime.statusName(status), throwsRangeError);
          expect(() => runtime.statusMessage(status), throwsRangeError);
          expect(() => runtime.statusCategory(status), throwsRangeError);
        }
      });

      test(
        'registers built-in astrology targets for position calculations',
        () {
          runtime
            ..registerBuiltinAstrologyTargets()
            ..registerBuiltinAstrologyTargets();

          final position = context.position
              .atTt(
                AstrologyTarget.trueNode,
                JulianDate<TtScale>.fromDouble(2460409.0),
                flags: {PositionFlag.radians, PositionFlag.speed},
              )
              .value;

          expect(position.values[0].isFinite, isTrue);
          expect(position.values[1], 0.0);
          expect(position.values[2].isNaN, isTrue);
          expect(position.values[3].isFinite, isTrue);
          expect(position.values[4], 0.0);
          expect(position.values[5].isNaN, isTrue);
        },
      );

      test('exposes catalog size and discovers a source path', () {
        final initialSize = runtime.catalogSize;

        expect(initialSize, greaterThan(0));
        expect(runtime.catalogSize, initialSize);
        runtime.addSourcePath(nativeDataPath);
        expect(runtime.catalogSize, greaterThanOrEqualTo(initialSize));
      });

      test('lists registered data sources and manages priorities', () {
        final sources = runtime.registeredDataSources;

        expect(sources, isNotEmpty);
        expect(
          sources.any(
            (source) => source.kind == RuntimeDataSourceKind.earthOrientation,
          ),
          isTrue,
          reason: 'the built-in EOP table is registered by default',
        );

        runtime.setEphemerisSourcePriority('jup365.bsp', 100);
        runtime.clearEphemerisSourcePriority('jup365.bsp');
        runtime.clearAllEphemerisSourcePriorities();

        expect(
          () => runtime.setEphemerisSourcePriority('', 1),
          throwsArgumentError,
        );
        for (final priority in [-0x80000001, 0x80000000]) {
          expect(
            () => runtime.setEphemerisSourcePriority('jup365.bsp', priority),
            throwsRangeError,
          );
        }
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
        context.configuration.setRouteRule(RouteRule.opm2);
        context.position
            .atTt(
              Body.mercury,
              JulianDate<TtScale>.fromDouble(2460409.0),
              flags: {PositionFlag.xyz, PositionFlag.truePosition},
            )
            .value;
        expect(runtime.cacheEntryCount, greaterThan(0));

        runtime.clearEphemerisCache();
        expect(runtime.cacheEntryCount, 0);
      });

      test('preserves native file errors', () {
        const missingPath = '/taiyin/this/file/does/not/exist';

        expect(
          () => runtime.loadEopTable(missingPath),
          throwsA(
            isA<EphemerisError>()
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
            isA<EphemerisError>().having(
              (error) => error.status,
              'status',
              -2001,
            ),
          ),
        );
        expect(
          () => runtime.addSourcePath(missingPath),
          throwsA(
            isA<EphemerisError>().having(
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
        expect(
          () => Ephemeris.open(
            libraryPath: libraryPath,
            options: const RuntimeOptions(dataRoot: 'data\u0000ignored'),
          ),
          throwsArgumentError,
        );
        expect(
          () => Ephemeris.open(
            libraryPath: libraryPath,
            options: const RuntimeOptions(sourcePaths: ['']),
          ),
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
                  Body.moon,
                  JulianDate<TtScale>.fromDouble(2460409.0),
                  flags: {PositionFlag.xyz},
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
