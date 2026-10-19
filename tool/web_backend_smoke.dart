import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris/backend_web.dart' as web;
import '../packages/ephemeris/test/support/backend_scenario.dart';
import '../packages/ephemeris/test/support/byte_sources_scenario.dart';
import '../packages/ephemeris/test/support/calendar_time_scenario.dart';
import '../packages/ephemeris/test/support/eclipse_scenario.dart';
import '../packages/ephemeris_bazi/test/support/web_backend_scenario.dart';
import '../packages/ephemeris_ziwei/test/support/web_backend_scenario.dart';

@JS('fetch')
external JSPromise<_Response> _fetch(String path);
extension type _Response(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSPromise<JSArrayBuffer> arrayBuffer();
  external JSPromise<JSString> text();
}
@JS('document')
external _Document get _document;
extension type _Document(JSObject _) implements JSObject {
  external _Output getElementById(String id);
}
extension type _Output(JSObject _) implements JSObject {
  external set textContent(String value);
}

Future<void> main() async {
  final out = _document.getElementById('results');
  try {
    // Validate a failed script load and its retry path before real initialization.
    try {
      await Ephemeris.initialize(wasmModuleUri: Uri.parse('does-not-exist.js'));
      throw StateError('Missing Wasm loader did not fail');
    } on StateError catch (error) {
      require(
        error.message.toString().contains('Could not load'),
        'Wrong loader failure',
      );
    }
    final runtime = await Ephemeris.initialize(
      wasmModuleUri: Uri.parse('taiyin_web.js'),
      options: const RuntimeOptions(
        loadBuiltinEop: false,
        segmentCacheMaxEntries: 512,
      ),
    );
    final sources = <String, Uint8List>{};
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
    ]) {
      final response = await _fetch('opm2/$name.opm2').toDart;
      require(response.ok, 'Data download failed: ${response.status}');
      sources['$name.opm2'] = JSUint8Array(
        await response.arrayBuffer().toDart,
      ).toDart;
    }
    final result = exerciseBackend(runtime, sources);
    (result['results'] as List).addAll(exerciseCalendarTime(runtime));
    (result['results'] as List).addAll(exerciseEclipses(runtime));
    (result['results'] as List).addAll(exerciseBaziWeb(runtime));
    (result['results'] as List).addAll(exerciseZiweiWeb(runtime));
    final tkcResponse = await _fetch('fixtures/tier0.tkc1').toDart;
    require(tkcResponse.ok, 'TKC1 test data unavailable');
    final tkc = JSUint8Array(await tkcResponse.arrayBuffer().toDart).toDart;
    final starsResponse = await _fetch('fixtures/lite.tsc1').toDart;
    require(starsResponse.ok, 'TSC1 test data unavailable');
    final stars = JSUint8Array(await starsResponse.arrayBuffer().toDart).toDart;
    (result['results'] as List).addAll(
      exerciseByteSources(runtime, tkc, stars),
    );
    final reference = await _fetch('native-reference.json').toDart;
    require(reference.ok, 'Missing native reference');
    final expected =
        jsonDecode((await reference.text().toDart).toDart)
            as Map<String, dynamic>;
    final rows = result['results'] as List;
    final nativeRows = expected['results'] as List;
    require(rows.length == nativeRows.length, 'Position case count mismatch');
    var maximum = 0.0;
    var maximumAt = '';
    for (var i = 0; i < rows.length; ++i) {
      final row = rows[i] as Map;
      final native = nativeRows[i] as Map;
      require(
        row['label'] == native['label'] && row['flags'] == native['flags'],
        'Flags/case mismatch',
      );
      final values = row['values'] as List;
      final baseline = native['values'] as List;
      require(
        values.length == baseline.length,
        'Result shape mismatch at ${row['label']}',
      );
      for (var k = 0; k < values.length; ++k) {
        final difference = ((values[k] as num) - (baseline[k] as num))
            .abs()
            .toDouble();
        if (difference > maximum) {
          maximum = difference;
          maximumAt = '${row['label']}/$k';
        }
        require(difference < 1e-8, 'Native/Web mismatch at $i/$k: $difference');
      }
    }
    // Verify the public default options too, including the compiled EOP table
    // and cleanup of sources registered before runtime reinitialization.
    final defaults = await Ephemeris.initialize(
      wasmModuleUri: Uri.parse('taiyin_web.js'),
    );
    final defaultContext = defaults.createContext();
    try {
      // Exercise transport exceptions, not just errors returned by C ABI.
      // These deliberately truncated internal payloads must not abort Wasm.
      final host = web.TaiyinExtensionHost.open();
      for (final badCall in <void Function()>[
        () => host.callBazi(0, 0, []),
        () => host.callZiwei(0, 0, 0, []),
      ]) {
        var rejected = false;
        try {
          badCall();
        } on InvalidArgumentError catch (error) {
          rejected = error.status == -1;
        }
        require(
          rejected,
          'Truncated bridge input did not produce a typed error',
        );
      }
      defaultContext.configuration.setRouteRule(RouteRule.opm2);
      try {
        defaultContext.position.atTt(
          Body.sun,
          TtJulianDate.fromDouble(2460409.25),
        );
        throw StateError('Runtime reset rediscovered old byte-source files');
      } on EphemerisRouteError {
        /* old sources must really be gone */
      }
      defaultContext.configuration.setRouteRule(RouteRule.automatic);
      final value = defaultContext.position.atUtc(
        Body.sun,
        AstroDateTime(2024, 4, 8, 18),
      );
      require(
        !value.flags.contains(ResultFlag.timeScaleFallback),
        'Default built-in EOP was not used',
      );
    } finally {
      defaultContext.close();
    }
    out.textContent = const JsonEncoder.withIndent('  ').convert({
      'status': 'PASS',
      'cases': rows.length,
      'maxComponentDifference': maximum,
      'maxComponentAt': maximumAt,
      'abiVersion': runtime.abiVersion,
      'libraryVersion': runtime.libraryVersion,
      'defaultOptionsAndEop': 'PASS',
      'bridgeErrorRecovery': 'PASS',
      'notes':
          'Same Dart API + C++ core; OPM2 bytes, UTC errors/flags, cloning and close tested',
    });
  } catch (error, stack) {
    out.textContent = 'FAIL: $error\n$stack';
  }
}
