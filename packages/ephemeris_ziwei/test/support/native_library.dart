import 'dart:io';
import 'dart:isolate';

String _packageFile(String packageName, String path) {
  final uri = Isolate.resolvePackageUriSync(
    Uri.parse('package:$packageName/$path'),
  );
  if (uri == null || uri.scheme != 'file') return path;
  return uri.toFilePath();
}

/// The ABI-10 Taiyin shared library used by default in native-integration tests.
///
/// Defaults to the modular core copy bundled in the root package. Override
/// with `TAIYIN_TEST_LIBRARY` to test a freshly built core library; the Ziwei
/// module itself is selected by `TAIYIN_ZIWEI_LIBRARY_PATH` or its package
/// bundle.
String get libraryPath =>
    Platform.environment['TAIYIN_TEST_LIBRARY'] ??
    _packageFile('ephemeris', 'native/libtaiyin.dylib');

/// Whether [libraryPath] exists on disk.
bool get nativeLibraryAvailable =>
    File(libraryPath).existsSync() &&
    File(
      _packageFile('ephemeris_ziwei', 'native/libtaiyin_ziwei.dylib'),
    ).existsSync();

/// Skip message for native-integration groups whose library is unavailable.
const String libraryUnavailableSkip =
    'Build or provide the modular Taiyin core and Ziwei libraries.';
