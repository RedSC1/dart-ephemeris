import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

/// A missing separately packaged extension produces a clear error without
/// affecting the already loaded core runtime.
void main() {
  test(
    'BaZi reports a missing extension module',
    () {
      final runtime = Ephemeris.open(libraryPath: libraryPath);
      final context = runtime.createContext();
      expect(
        () => context.createBazi(libraryPath: '/no/such/libtaiyin_bazi.dylib'),
        throwsUnsupportedError,
      );
      expect(context.position, isNotNull);
      context.close();
    },
    skip: nativeLibraryAvailable ? false : libraryUnavailableSkip,
  );
}
