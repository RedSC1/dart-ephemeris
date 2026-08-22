import 'dart:io';

import 'package:taiyin/ffi.dart';
import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

Set<String> _referencedBaziSymbols() {
  final current = Directory.current;
  final packageRoot = File('${current.path}/lib/src/bazi_api.dart').existsSync()
      ? current
      : Directory('${current.path}/packages/taiyin_bazi');
  final source = File(
    '${packageRoot.path}/lib/src/bazi_api.dart',
  ).readAsStringSync();
  return RegExp(
    r'\b(taiyin_bazi_[a-z0-9_]+)\s*\(',
  ).allMatches(source).map((match) => match.group(1)!).toSet();
}

/// A missing separately packaged extension produces a clear error without
/// affecting the already loaded core runtime.
void main() {
  test('BaZi symbol contract covers every native call in the facade', () {
    final missing = _referencedBaziSymbols().difference(taiyinBaziSymbols);
    expect(missing, isEmpty);
  });

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
