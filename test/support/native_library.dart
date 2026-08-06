import 'dart:io';

/// The ABI-5 Taiyin shared library used by default in native-integration tests.
///
/// Defaults to the pinned copy in `native/` (full-module build: Chinese
/// calendar + Ganzhi + BaZi). Override with the `TAIYIN_TEST_LIBRARY`
/// environment variable to test against a freshly built library.
String get libraryPath =>
    Platform.environment['TAIYIN_TEST_LIBRARY'] ??
    'native/libtaiyin.dylib';

/// Whether [libraryPath] exists on disk.
bool get nativeLibraryAvailable => File(libraryPath).existsSync();

/// ABI-5 baseline library (Chinese calendar only; no Ganzhi/BaZi extension),
/// used by optional-module tests to assert capability gating.
///
/// Override with the `TAIYIN_BASELINE_LIBRARY` environment variable.
String get baselineLibraryPath =>
    Platform.environment['TAIYIN_BASELINE_LIBRARY'] ??
    '../taiyin-ephemeris/build-review-off/libtaiyin.dylib';

/// Whether [baselineLibraryPath] exists on disk.
bool get baselineLibraryAvailable => File(baselineLibraryPath).existsSync();

/// Skip message for native-integration groups whose library is unavailable.
const String libraryUnavailableSkip =
    'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.';
