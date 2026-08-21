import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

/// BaZi gating on an extension-free baseline library: the package must refuse
/// before any `taiyin_bazi_*` symbol lookup.
void main() {
  test(
    'BaZi entry points throw UnsupportedError on a baseline library',
    () {
      final runtime = Ephemeris.open(libraryPath: baselineLibraryPath);
      final context = runtime.createContext();
      expect(() => context.bazi.calcLiunian(2024), throwsUnsupportedError);
      expect(() => context.createBazi(), throwsUnsupportedError);
      context.close();
    },
    skip: baselineLibraryAvailable
        ? false
        : 'Set TAIYIN_BASELINE_LIBRARY to a baseline ABI-9 library.',
  );
}
