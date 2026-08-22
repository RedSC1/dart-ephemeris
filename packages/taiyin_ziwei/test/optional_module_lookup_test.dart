import 'dart:io';

import 'package:taiyin/ffi.dart';
import 'package:taiyin/taiyin.dart';
import 'package:taiyin_ziwei/taiyin_ziwei.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

Set<String> _referencedZiweiSymbols() {
  final current = Directory.current;
  final packageRoot =
      File('${current.path}/lib/src/ziwei_api.dart').existsSync()
      ? current
      : Directory('${current.path}/packages/taiyin_ziwei');
  final source = File(
    '${packageRoot.path}/lib/src/ziwei_api.dart',
  ).readAsStringSync();
  return RegExp(
    r'\b(taiyin_ziwei_[a-z0-9_]+)\s*\(',
  ).allMatches(source).map((match) => match.group(1)!).toSet();
}

/// A missing separately packaged extension produces a clear error without
/// affecting the already loaded core runtime.
void main() {
  test('Ziwei symbol contract covers every native call in the facade', () {
    final missing = _referencedZiweiSymbols().difference(taiyinZiweiSymbols);
    expect(missing, isEmpty);
  });

  test('Ziwei reports a missing extension module', () {
    final runtime = Ephemeris.open(libraryPath: libraryPath);
    final context = runtime.createContext();
    expect(
      () => context.createZiwei(
        libraryPath: '/no/such/definitely_missing_taiyin_ziwei.dylib',
      ),
      throwsUnsupportedError,
    );
    expect(
      () => ZiweiDataCatalog(libraryPath: '/no/such/libtaiyin_ziwei.dylib'),
      throwsUnsupportedError,
    );
    expect(context.position, isNotNull);
    context.close();
  }, skip: nativeLibraryAvailable ? false : libraryUnavailableSkip);
}
