import 'dart:ffi';

import 'package:taiyin/src/bindings/taiyin_bindings.g.dart';
import 'package:taiyin/src/native_compatibility.dart';
import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

/// Guards the optional-module contract: BaZi and Ziwei are optional
/// extensions whose symbols do not exist in a library built without
/// `TAIYIN_BUILD_BAZI_EXTENSION` / `TAIYIN_BUILD_ZIWEI_EXTENSION`. The core
/// package must never look up a `taiyin_bazi_*` or `taiyin_ziwei_*` symbol;
/// the extension packages gate their own lookups by capability (covered by
/// their own baseline tests). This file runs against the ABI-8 baseline
/// library (Chinese calendar only) to verify that discipline.
void main() {
  group('optional-module symbol lookup discipline', () {
    test(
      'constructing bindings and reading load-time metadata does not touch '
      'extension symbols',
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
          capabilities & taiyinZiweiCapability,
          isZero,
          reason: 'baseline library must not report the Ziwei module',
        );
        expect(
          lookedUp.any((symbol) => symbol.startsWith('taiyin_bazi_')),
          isFalse,
          reason: 'BaZi symbols must not be looked up before capability gating',
        );
        expect(
          lookedUp.any((symbol) => symbol.startsWith('taiyin_ziwei_')),
          isFalse,
          reason:
              'Ziwei symbols must not be looked up before capability gating',
        );
      },
      skip: baselineLibraryAvailable
          ? false
          : 'Set TAIYIN_BASELINE_LIBRARY to a baseline ABI-8 library.',
    );

    test(
      'the package loads and creates a context on a baseline library',
      () {
        final runtime = Ephemeris.open(libraryPath: baselineLibraryPath);
        final context = runtime.createContext();
        expect(context, isNotNull);
        // The Chinese calendar is always built and works, and since the
        // calendar-ABI restructure Ganzhi (including four pillars) is always
        // built too.
        final year = context.chineseCalendar.calcYearUt(
          JulianDate<Ut1Scale>.fromDouble(2460348.0),
        );
        expect(year.solarTermCount, 25);
        final pillars = context.chineseCalendar.fourPillars(
          instantUtc: JulianDate<UtcScale>.fromDouble(2460351.0),
          virtualTime: AstroDateTime(2024, 2, 10, 12),
        );
        expect(pillars.year.stemId, inInclusiveRange(0, 9));
        expect(context.ganzhi.make(stemId: 0, branchId: 0).stemId, 0);
        context.close();
      },
      skip: baselineLibraryAvailable
          ? false
          : 'Set TAIYIN_BASELINE_LIBRARY to a baseline ABI-8 library.',
    );
  });
}
