import 'dart:io';

final class _NativeFile {
  const _NativeFile(this.artifact, this.source, this.destination);

  final String artifact;
  final String source;
  final String destination;
}

const _files = <_NativeFile>[
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'lib/libtaiyin.dylib',
    'packages/ephemeris/lib/native/libtaiyin.dylib',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'lib/libtaiyin_bazi.dylib',
    'packages/ephemeris_bazi/lib/native/libtaiyin_bazi.dylib',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'lib/libtaiyin_ziwei.dylib',
    'packages/ephemeris_ziwei/lib/native/libtaiyin_ziwei.dylib',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'share/doc/taiyin/NOTICE',
    'packages/ephemeris/NOTICE',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'share/doc/taiyin/NOTICE',
    'packages/ephemeris_bazi/NOTICE',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'share/doc/taiyin/NOTICE',
    'packages/ephemeris_ziwei/NOTICE',
  ),
  _NativeFile(
    'taiyin-native-Linux-X64',
    'lib/libtaiyin.so',
    'packages/ephemeris/lib/native/libtaiyin.so',
  ),
  _NativeFile(
    'taiyin-native-Linux-X64',
    'lib/libtaiyin_bazi.so',
    'packages/ephemeris_bazi/lib/native/libtaiyin_bazi.so',
  ),
  _NativeFile(
    'taiyin-native-Linux-X64',
    'lib/libtaiyin_ziwei.so',
    'packages/ephemeris_ziwei/lib/native/libtaiyin_ziwei.so',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/taiyin.dll',
    'packages/ephemeris/lib/native/taiyin.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/taiyin_bazi.dll',
    'packages/ephemeris_bazi/lib/native/taiyin_bazi.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/taiyin_ziwei.dll',
    'packages/ephemeris_ziwei/lib/native/taiyin_ziwei.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/libgcc_s_seh-1.dll',
    'packages/ephemeris/lib/native/libgcc_s_seh-1.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/libstdc++-6.dll',
    'packages/ephemeris/lib/native/libstdc++-6.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/libwinpthread-1.dll',
    'packages/ephemeris/lib/native/libwinpthread-1.dll',
  ),
];

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/stage_native_artifacts.dart <artifact-root>',
    );
    exitCode = 64;
    return;
  }

  final repository = Directory.current.absolute;
  if (!File.fromUri(repository.uri.resolve('pubspec.yaml')).existsSync() ||
      !Directory.fromUri(
        repository.uri.resolve('packages/ephemeris/'),
      ).existsSync()) {
    stderr.writeln('Run this command from the dart-ephemeris repository root.');
    exitCode = 64;
    return;
  }

  final artifactRoot = Directory(arguments.single).absolute;
  final missing = <String>[];
  for (final file in _files) {
    final source = _artifactFile(artifactRoot, file);
    if (!source.existsSync()) missing.add(source.path);
  }
  if (missing.isNotEmpty) {
    stderr.writeln('Native artifact set is incomplete:');
    for (final path in missing) {
      stderr.writeln('  $path');
    }
    exitCode = 66;
    return;
  }

  for (final file in _files) {
    final source = _artifactFile(artifactRoot, file);
    final destination = _relativeFile(repository, file.destination);
    destination.parent.createSync(recursive: true);
    source.copySync(destination.path);
    stdout.writeln('${source.path} -> ${destination.path}');
  }

  // The native NOTICE names the C++ source-tree path. In Dart distributions
  // the same manifest lives in the base package and is addressable by package
  // URI, including from the optional extension packages.
  for (final relativePath in const [
    'packages/ephemeris/NOTICE',
    'packages/ephemeris_bazi/NOTICE',
    'packages/ephemeris_ziwei/NOTICE',
  ]) {
    final notice = _relativeFile(repository, relativePath);
    final contents = notice.readAsStringSync();
    notice.writeAsStringSync(
      contents.replaceAll(
        '    data/stars/catalogs/lite/required_stars.json',
        '    package:ephemeris/data/stars/catalogs/lite/required_stars.json',
      ),
    );
  }
}

File _artifactFile(Directory root, _NativeFile file) {
  final relativePath = '${file.artifact}/${file.source}';
  final source = _relativeFile(root, relativePath);
  if (source.existsSync() || !file.source.startsWith('lib/')) return source;

  // CMake uses lib64 on some 64-bit Linux distributions (including the
  // manylinux2014 image) and lib elsewhere. Treat both install layouts as the
  // same artifact instead of encoding the build host's convention here.
  return _relativeFile(
    root,
    '${file.artifact}/lib64/${file.source.substring('lib/'.length)}',
  );
}

File _relativeFile(Directory root, String relativePath) =>
    File.fromUri(root.uri.resolve(relativePath));
