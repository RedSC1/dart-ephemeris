import 'dart:ffi';

import 'package:taiyin/src/bindings/taiyin_bindings.g.dart';
import 'package:taiyin/src/native_compatibility.dart';
import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

/// Guards the optional-module contract: BaZi is an optional extension whose
/// symbols do not exist in a library built without `TAIYIN_BUILD_BAZI_EXTENSION`.
/// The package must never look up a `taiyin_bazi_*` symbol unless the loaded
/// library advertises the BaZi capability. This file runs against the ABI-5
/// baseline library (Chinese calendar only) to verify that discipline.
void main() {
  group('optional-module symbol lookup discipline', () {
    test(
      'constructing bindings and reading load-time metadata does not touch '
      'BaZi symbols',
      () {
        final library = DynamicLibrary.open(baselineLibraryPath);
        final lookedUp = <String>[];
        Pointer<T> recordLookup<T extends NativeType>(String symbol) {
          lookedUp.add(symbol);
          return library.lookup<T>(symbol);
        }

        final bindings = TaiyinBindings.fromLookup(recordLookup);
        // Mirrors the package load path: version and capabilities first, then
        // the required-symbol validation against library.providesSymbol.
        final abiVersion = bindings.taiyin_get_c_abi_version();
        final capabilities = bindings.taiyin_get_capabilities();
        expect(abiVersion, taiyinSupportedAbiVersion);
        expect(
          capabilities & taiyinChineseCalendarCapability,
          isNonZero,
          reason: 'baseline library must report the Chinese-calendar module',
        );
        expect(
          capabilities & taiyinBaziCapability,
          isZero,
          reason: 'baseline library must not report the BaZi module',
        );
        expect(
          lookedUp.any((symbol) => symbol.startsWith('taiyin_bazi_')),
          isFalse,
          reason: 'BaZi symbols must not be looked up before capability gating',
        );
      },
      skip: baselineLibraryAvailable
          ? false
          : 'Set TAIYIN_BASELINE_LIBRARY to a baseline ABI-5 library.',
    );

    test(
      'the package loads and creates a context on a baseline library',
      () {
        final runtime = Ephemeris.open(libraryPath: baselineLibraryPath);
        final context = runtime.createContext();
        expect(context, isNotNull);
        // The Chinese calendar is always built and works.
        final year = context.chineseCalendar
            .calcYearUt(JulianDate<Ut1Scale>.fromDouble(2460348.0))
            .value;
        expect(year.solarTermCount, 25);
        // fourPillars needs the Ganzhi extension (its entry point is always
        // exported but returns UNSUPPORTED without it); the API must refuse
        // with UnsupportedError.
        expect(
          () => context.chineseCalendar.fourPillars(
            instantUtc: JulianDate<UtcScale>.fromDouble(2460351.0),
            virtualTime: AstroDateTime(2024, 2, 10, 12),
          ),
          throwsUnsupportedError,
        );
        // Ganzhi and BaZi are optional: the API must refuse before any symbol
        // lookup on an extension-free library.
        expect(
          () => context.ganzhi.make(stemId: 0, branchId: 0),
          throwsUnsupportedError,
        );
        expect(() => context.bazi.calcLiunian(2024), throwsUnsupportedError);
        expect(() => context.createBazi(), throwsUnsupportedError);
        context.close();
      },
      skip: baselineLibraryAvailable
          ? false
          : 'Set TAIYIN_BASELINE_LIBRARY to a baseline ABI-5 library.',
    );
  });
}
