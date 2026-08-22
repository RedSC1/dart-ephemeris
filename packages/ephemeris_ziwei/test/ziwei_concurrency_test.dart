import 'dart:isolate';

import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

Future<int> _runZiweiWorker(String coreLibraryPath, int iterations) async {
  final port = ReceivePort();
  await Isolate.spawn(
    _ziweiWorkerMain,
    (port.sendPort, coreLibraryPath, iterations),
    onError: port.sendPort,
    onExit: port.sendPort,
  );
  try {
    final message = await port.first;
    if (message case ['result', final int checksum]) return checksum;
    if (message case ['error', final Object error, final Object stack]) {
      throw StateError('Ziwei worker failed: $error\n$stack');
    }
    if (message case [final Object error, final Object stack]) {
      throw StateError('Ziwei isolate error: $error\n$stack');
    }
    throw StateError('Ziwei worker exited without a result: $message');
  } finally {
    port.close();
  }
}

void _ziweiWorkerMain((SendPort, String, int) message) {
  final (sendPort, coreLibraryPath, iterations) = message;
  EphemerisContext? context;
  ZiweiContext? ziwei;
  try {
    context = Ephemeris.attach(libraryPath: coreLibraryPath).createContext();
    ziwei = context.ziwei;
    var checksum = 0;
    for (var index = 0; index < iterations; index++) {
      final local = AstroDateTime(2003, 3, 13, 14, 15);
      final chart = ziwei.calculateLocal(local, gender: ZiweiGender.male).value;
      checksum =
          0x7fffffff &
          (checksum * 31 +
              chart.summary.bureauId * 17 +
              chart.anchors.ziwei * 13 +
              chart.flowLayerCount);
      chart.close();
    }
    sendPort.send(['result', checksum]);
  } catch (error, stack) {
    sendPort.send(['error', '$error', '$stack']);
  } finally {
    ziwei?.close();
    context?.close();
  }
}

void main() {
  test('independent isolates calculate Ziwei charts concurrently', () async {
    final owner = Ephemeris.open(libraryPath: libraryPath).createContext();
    try {
      final checksums = await Future.wait([
        for (var worker = 0; worker < 4; worker++)
          _runZiweiWorker(libraryPath, 16),
      ]).timeout(const Duration(seconds: 30));
      expect(checksums, hasLength(4));
      expect(checksums.toSet(), hasLength(1));
    } finally {
      owner.close();
    }
  }, skip: nativeLibraryAvailable ? false : libraryUnavailableSkip);
}
