import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ephemeris/ephemeris.dart';
import '../packages/ephemeris/test/support/backend_scenario.dart';
import '../packages/ephemeris/test/support/byte_sources_scenario.dart';
import '../packages/ephemeris/test/support/calendar_time_scenario.dart';
import '../packages/ephemeris/test/support/eclipse_scenario.dart';
import '../packages/ephemeris_bazi/test/support/web_backend_scenario.dart';
import '../packages/ephemeris_ziwei/test/support/web_backend_scenario.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    throw ArgumentError(
      'Usage: native_backend_reference.dart LIBRARY DATA_DIRECTORY OUTPUT.json',
    );
  }
  final runtime = await Ephemeris.initialize(
    libraryPath: args[0],
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
    sources['$name.opm2'] = File('${args[1]}/$name.opm2').readAsBytesSync();
  }
  final result = exerciseBackend(runtime, sources);
  (result['results'] as List).addAll(exerciseCalendarTime(runtime));
  (result['results'] as List).addAll(exerciseEclipses(runtime));
  (result['results'] as List).addAll(exerciseBaziWeb(runtime));
  (result['results'] as List).addAll(exerciseZiweiWeb(runtime));
  final tkc = File(
    '${args[1]}/../../../../kepler/sbdb/sbdb-tier0-core.tkc1',
  ).readAsBytesSync();
  final stars = File(
    '${args[1]}/../../../../stars/catalogs/lite/stars-bright-v5.tsc1',
  ).readAsBytesSync();
  (result['results'] as List).addAll(exerciseByteSources(runtime, tkc, stars));
  File(args[2]).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(result)}\n',
  );
  // Release the temporary byte-source files after the completed test.
  await Ephemeris.initialize(libraryPath: args[0]);
  print('Native shared backend scenario: PASS');
}
