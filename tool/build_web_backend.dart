import 'dart:io';

/// Builds the opt-in C++ Web adapter; generated assets stay under build/.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError(
      'Usage: dart run tool/build_web_backend.dart /path/to/taiyin-ephemeris',
    );
  }
  final source = Directory('${args[0]}/experiments/wasm').absolute;
  if (!File('${source.path}/web_bridge.cpp').existsSync()) {
    throw ArgumentError(
      'The core checkout must include experiments/wasm/web_bridge.cpp',
    );
  }
  final output = Directory('build/web_backend').absolute
    ..createSync(recursive: true);
  final build = Directory('${output.path}/cmake');
  Future<void> run(String command, List<String> arguments) async {
    final result = await Process.start(
      command,
      arguments,
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    final code = await result.exitCode;
    if (code != 0) {
      throw ProcessException(
        command,
        arguments,
        'Web backend build failed',
        code,
      );
    }
  }

  // Activate the official Emscripten SDK before running this script.
  await run('emcmake', [
    'cmake',
    '-S',
    source.path,
    '-B',
    build.path,
    '-DCMAKE_BUILD_TYPE=Release',
  ]);
  await run('cmake', [
    '--build',
    build.path,
    '--target',
    'taiyin_web',
    '-j',
    '10',
  ]);
  for (final name in ['taiyin_web.js', 'taiyin_web.wasm']) {
    await File('${build.path}/$name').copy('${output.path}/$name');
  }
  print('Deploy ${output.path}/taiyin_web.js and taiyin_web.wasm together.');
}
