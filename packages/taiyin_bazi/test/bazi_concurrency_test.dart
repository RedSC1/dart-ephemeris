import 'dart:isolate';

import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

Future<int> _runBaziWorker(String coreLibraryPath, int iterations) async {
  final port = ReceivePort();
  await Isolate.spawn(
    _baziWorkerMain,
    (port.sendPort, coreLibraryPath, iterations),
    onError: port.sendPort,
    onExit: port.sendPort,
  );
  try {
    final message = await port.first;
    if (message case ['result', final int checksum]) return checksum;
    if (message case ['error', final Object error, final Object stack]) {
      throw StateError('BaZi worker failed: $error\n$stack');
    }
    if (message case [final Object error, final Object stack]) {
      throw StateError('BaZi isolate error: $error\n$stack');
    }
    throw StateError('BaZi worker exited without a result: $message');
  } finally {
    port.close();
  }
}

void _baziWorkerMain((SendPort, String, int) message) {
  final (sendPort, coreLibraryPath, iterations) = message;
  EphemerisContext? context;
  BaziContext? bazi;
  try {
    context = Ephemeris.attach(libraryPath: coreLibraryPath).createContext();
    bazi = context.bazi;
    var checksum = 0;
    for (var index = 0; index < iterations; index++) {
      final year = context.ganzhi.make(
        stemId: index % 10,
        branchId: index % 12,
      );
      final month = bazi.calcLiuyue(year, index % 12);
      final day = bazi.calcLiuri(AstroDateTime(2000, 1, 1 + (index % 27)));
      final hour = bazi.calcLiushi(day, index % 12);
      final chart = bazi.calcChart(
        GanzhiFourPillars(year: year, month: month, day: day, hour: hour),
      );
      checksum =
          0x7fffffff &
          (checksum * 31 +
              chart.mingGong.raw * 17 +
              chart.shenGong.raw * 13 +
              chart.nayinIds.fold(0, (sum, value) => sum + value));
    }
    sendPort.send(['result', checksum]);
  } catch (error, stack) {
    sendPort.send(['error', '$error', '$stack']);
  } finally {
    bazi?.close();
    context?.close();
  }
}

void main() {
  test('independent isolates calculate BaZi concurrently', () async {
    final owner = Ephemeris.open(libraryPath: libraryPath).createContext();
    try {
      final checksums = await Future.wait([
        for (var worker = 0; worker < 4; worker++)
          _runBaziWorker(libraryPath, 128),
      ]).timeout(const Duration(seconds: 30));
      expect(checksums, hasLength(4));
      expect(checksums.toSet(), hasLength(1));
    } finally {
      owner.close();
    }
  }, skip: nativeLibraryAvailable ? false : libraryUnavailableSkip);
}
