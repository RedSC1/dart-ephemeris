import 'dart:isolate';

import 'package:ephemeris/ephemeris.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

void main() {
  group(
    'EphemerisContext child-context lifecycle',
    () {
      late Ephemeris runtime;
      late EphemerisContext context;

      setUp(() {
        runtime = Ephemeris.open(libraryPath: libraryPath);
        context = runtime.createContext();
      });

      tearDown(() {
        context.close();
      });

      test('closing the owning context closes its cached child contexts', () {
        final calendar = context.chineseCalendar;
        expect(calendar.isClosed, isFalse);

        context.close();

        expect(calendar.isClosed, isTrue);
        expect(
          () => calendar
              .calcYearUt(JulianDate<Ut1Scale>.fromDouble(2460348.0))
              .value,
          throwsStateError,
        );
      });

      test(
        'closing the owner invalidates caller-created calendar contexts',
        () {
          // A caller-created calendar context borrows the owner's native state;
          // closing the owner must invalidate it too, not just the cached one.
          final custom = context.createChineseCalendar(
            config: const ChineseCalendarConfig.localAstronomicalUtcOffset(0),
          );
          expect(custom.isClosed, isFalse);

          context.close();

          expect(custom.isClosed, isTrue);
          expect(
            () => custom
                .calcYearUt(JulianDate<Ut1Scale>.fromDouble(2460348.0))
                .value,
            throwsStateError,
          );
        },
      );

      test('clone creates independent cached child contexts', () {
        final originalCalendar = context.chineseCalendar;
        final clone = context.clone();
        final cloneCalendar = clone.chineseCalendar;

        expect(identical(originalCalendar, cloneCalendar), isFalse);

        clone.close();
        expect(cloneCalendar.isClosed, isTrue);
        // The original context and its calendar are unaffected.
        expect(context.chineseCalendar.isClosed, isFalse);
        context.close();
        expect(originalCalendar.isClosed, isTrue);
      });

      test('a worker isolate attaches its own child contexts', () async {
        final result = await _attachWorker(
          libraryPath,
          JulianDate<Ut1Scale>.fromDouble(2460348.0),
        );
        expect(result, 'ok');
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}

Future<String> _attachWorker(
  String libraryPath,
  JulianDate<Ut1Scale> jd,
) async {
  final port = ReceivePort();
  await Isolate.spawn(_workerMain, (
    sendPort: port.sendPort,
    libraryPath: libraryPath,
    jd: jd,
  ));
  final result = await port.first;
  port.close();
  return result as String;
}

void _workerMain(
  ({SendPort sendPort, String libraryPath, JulianDate<Ut1Scale> jd}) message,
) {
  final context = Ephemeris.attach(
    libraryPath: message.libraryPath,
  ).createContext();
  try {
    final calendar = context.chineseCalendar;
    final year = calendar.calcYearUt(message.jd).value;
    if (year.solarTermCount != 25) {
      message.sendPort.send('unexpected term count');
      return;
    }
    message.sendPort.send('ok');
  } finally {
    context.close();
  }
}
