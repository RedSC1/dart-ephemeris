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
    'packages/taiyin/lib/native/libtaiyin.dylib',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'lib/libtaiyin_bazi.dylib',
    'packages/taiyin_bazi/lib/native/libtaiyin_bazi.dylib',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'lib/libtaiyin_ziwei.dylib',
    'packages/taiyin_ziwei/lib/native/libtaiyin_ziwei.dylib',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'share/doc/taiyin/NOTICE',
    'packages/taiyin/NOTICE',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'share/doc/taiyin/NOTICE',
    'packages/taiyin_bazi/NOTICE',
  ),
  _NativeFile(
    'taiyin-native-macOS-ARM64',
    'share/doc/taiyin/NOTICE',
    'packages/taiyin_ziwei/NOTICE',
  ),
  _NativeFile(
    'taiyin-native-Linux-X64',
    'lib/libtaiyin.so',
    'packages/taiyin/lib/native/libtaiyin.so',
  ),
  _NativeFile(
    'taiyin-native-Linux-X64',
    'lib/libtaiyin_bazi.so',
    'packages/taiyin_bazi/lib/native/libtaiyin_bazi.so',
  ),
  _NativeFile(
    'taiyin-native-Linux-X64',
    'lib/libtaiyin_ziwei.so',
    'packages/taiyin_ziwei/lib/native/libtaiyin_ziwei.so',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/taiyin.dll',
    'packages/taiyin/lib/native/taiyin.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/taiyin_bazi.dll',
    'packages/taiyin_bazi/lib/native/taiyin_bazi.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/taiyin_ziwei.dll',
    'packages/taiyin_ziwei/lib/native/taiyin_ziwei.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/libgcc_s_seh-1.dll',
    'packages/taiyin/lib/native/libgcc_s_seh-1.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/libstdc++-6.dll',
    'packages/taiyin/lib/native/libstdc++-6.dll',
  ),
  _NativeFile(
    'taiyin-native-Windows-X64',
    'bin/libwinpthread-1.dll',
    'packages/taiyin/lib/native/libwinpthread-1.dll',
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
        repository.uri.resolve('packages/taiyin/'),
      ).existsSync()) {
    stderr.writeln('Run this command from the taiyin-dart repository root.');
    exitCode = 64;
    return;
  }

  final artifactRoot = Directory(arguments.single).absolute;
  final missing = <String>[];
  for (final file in _files) {
    final source = _relativeFile(
      artifactRoot,
      '${file.artifact}/${file.source}',
    );
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
    final source = _relativeFile(
      artifactRoot,
      '${file.artifact}/${file.source}',
    );
    final destination = _relativeFile(repository, file.destination);
    destination.parent.createSync(recursive: true);
    source.copySync(destination.path);
    stdout.writeln('${source.path} -> ${destination.path}');
  }
}

File _relativeFile(Directory root, String relativePath) =>
    File.fromUri(root.uri.resolve(relativePath));
