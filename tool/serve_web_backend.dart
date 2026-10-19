import 'dart:io';

/// Loopback-only smoke-test server. It never exposes the repository tree.
Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw ArgumentError(
      'Usage: serve_web_backend.dart CORE_BUILD OPM2_DIRECTORY',
    );
  }
  final generated = Directory('build/web_backend').absolute;
  final core = Directory(args[0]).absolute;
  final data = Directory(args[1]).absolute;
  final files = <String, File>{
    '/fixtures/lite.tsc1': File(
      '${data.path}/../../../../stars/catalogs/lite/stars-bright-v5.tsc1',
    ),
    '/fixtures/tier0.tkc1': File(
      '${data.path}/../../../../kepler/sbdb/sbdb-tier0-core.tkc1',
    ),
    for (final name in [
      'main.dart.js',
      'smoke.mjs',
      'smoke.wasm',
      'smoke.support.js',
      'native-reference.json',
    ])
      '/$name': File('${generated.path}/$name'),
    for (final name in ['taiyin_web.js', 'taiyin_web.wasm'])
      '/$name': File('${core.path}/$name'),
    for (final name in [
      'sun',
      'moon',
      'emb',
      'mercury',
      'venus',
      'mars',
      'jupiter',
      'saturn',
      'uranus',
      'neptune',
      'pluto',
    ])
      '/opm2/$name.opm2': File('${data.path}/$name.opm2'),
  };
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8766);
  print('http://127.0.0.1:8766/index.html (dart2js)');
  print('http://127.0.0.1:8766/dart-wasm.html (dart2wasm)');
  await for (final request in server) {
    final response = request.response;
    response.headers.set('Cache-Control', 'no-store');
    final path = request.uri.path;
    try {
      if (request.method != 'GET') {
        response.statusCode = 405;
      } else if (path == '/index.html' || path == '/dart-wasm.html') {
        response.headers.contentType = ContentType.html;
        final script = path == '/index.html'
            ? '<script defer src="main.dart.js"></script>'
            : '''
<script type="module">
import {compileStreaming} from './smoke.mjs';
try { const app = await compileStreaming(fetch('./smoke.wasm'));
  const instance = await app.instantiate({}); instance.invokeMain();
} catch (e) { document.querySelector('#results').textContent = 'FAIL: ' + e.stack; }
</script>''';
        response.write(
          '<!doctype html><meta charset="utf-8"><title>Dart Web backend smoke test</title>'
          '<h1>Dart + Taiyin Wasm backend</h1><pre id="results">Loading…</pre>$script',
        );
      } else if (files.containsKey(path)) {
        response.headers.contentType = path.endsWith('.wasm')
            ? ContentType('application', 'wasm')
            : path.endsWith('.js') || path.endsWith('.mjs')
            ? ContentType('text', 'javascript')
            : path.endsWith('.json')
            ? ContentType.json
            : ContentType.binary;
        await response.addStream(files[path]!.openRead());
      } else {
        response.statusCode = 404;
      }
    } catch (error) {
      response.statusCode = 500;
      response.write('$error');
    }
    await response.close();
  }
}
