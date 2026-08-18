import 'package:taiyin/taiyin.dart';
import 'package:taiyin_ziwei/taiyin_ziwei.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

/// Ziwei gating on an extension-free baseline library: the package must refuse
/// before any `taiyin_ziwei_*` symbol lookup.
void main() {
  test(
    'Ziwei entry points throw UnsupportedError on a baseline library',
    () {
      final runtime = Ephemeris.open(libraryPath: baselineLibraryPath);
      final context = runtime.createContext();
      expect(() => context.ziwei, throwsUnsupportedError);
      expect(() => context.createZiwei(), throwsUnsupportedError);
      expect(
        () => ZiweiDataCatalog(libraryPath: baselineLibraryPath),
        throwsUnsupportedError,
      );
      context.close();
    },
    skip: baselineLibraryAvailable
        ? false
        : 'Set TAIYIN_BASELINE_LIBRARY to a baseline ABI-8 library.',
  );
}
