import 'dart:io';
import 'dart:isolate';

String _packageFile(String packageName, String path) {
  final uri = Isolate.resolvePackageUriSync(
    Uri.parse('package:$packageName/$path'),
  );
  if (uri == null || uri.scheme != 'file') return path;
  return uri.toFilePath();
}

/// The ABI-9 Taiyin shared library used by default in native-integration tests.
///
/// Defaults to the modular core copy bundled in `lib/native/`. Override with
/// `TAIYIN_TEST_LIBRARY` to test against a freshly built library.
String get libraryPath =>
    Platform.environment['TAIYIN_TEST_LIBRARY'] ??
    _packageFile('ephemeris', 'native/libtaiyin.dylib');

/// Whether [libraryPath] exists on disk.
bool get nativeLibraryAvailable => File(libraryPath).existsSync();

/// ABI-9 modular core library used to assert that extension symbols are absent.
///
/// Override with the `TAIYIN_BASELINE_LIBRARY` environment variable.
String get baselineLibraryPath =>
    Platform.environment['TAIYIN_BASELINE_LIBRARY'] ?? libraryPath;

/// Whether [baselineLibraryPath] exists on disk.
bool get baselineLibraryAvailable => File(baselineLibraryPath).existsSync();

/// Skip message for native-integration groups whose library is unavailable.
const String libraryUnavailableSkip =
    'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.';
