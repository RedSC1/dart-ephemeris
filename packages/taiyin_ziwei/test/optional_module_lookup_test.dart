import 'package:taiyin/taiyin.dart';
import 'package:taiyin_ziwei/taiyin_ziwei.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

/// A missing separately packaged extension produces a clear error without
/// affecting the already loaded core runtime.
void main() {
  test(
    'Ziwei reports a missing extension module',
    () {
      final runtime = Ephemeris.open(libraryPath: libraryPath);
      final context = runtime.createContext();
      expect(
        () =>
            context.createZiwei(libraryPath: '/no/such/libtaiyin_ziwei.dylib'),
        throwsUnsupportedError,
      );
      expect(
        () => ZiweiDataCatalog(libraryPath: '/no/such/libtaiyin_ziwei.dylib'),
        throwsUnsupportedError,
      );
      expect(context.position, isNotNull);
      context.close();
    },
    skip: nativeLibraryAvailable ? false : libraryUnavailableSkip,
  );
}
