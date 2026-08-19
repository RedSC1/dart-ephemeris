import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

void main() {
  group(
    'BaziContext lifecycle',
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

      test('closing the owning ephemeris context does not close BaZi', () {
        // A BaZi context borrows nothing from the ephemeris context, so it
        // stays usable after the owner closes.
        final bazi = context.bazi;
        expect(bazi.isClosed, isFalse);

        context.close();

        expect(bazi.isClosed, isFalse);
        expect(bazi.calcLiunian(2024).stemId, inInclusiveRange(0, 9));
        bazi.close();
        expect(bazi.isClosed, isTrue);
        expect(() => bazi.calcLiunian(2024), throwsStateError);
      });

      test('a caller-closed cache entry is replaced on the next access', () {
        final first = context.bazi;
        first.close();

        final second = context.bazi;
        expect(identical(first, second), isFalse);
        expect(second.isClosed, isFalse);
        second.close();
      });

      test('a clone gets an independent cached BaZi context', () {
        final clone = context.clone();
        final cloneBazi = clone.bazi;

        expect(identical(context.bazi, cloneBazi), isFalse);
        expect(cloneBazi.isClosed, isFalse);

        clone.close();
        cloneBazi.close();
      });

      test('binds an explicit caller-owned calendar', () {
        final calendar = context.createChineseCalendar();
        final bazi = context.createBazi(calendar: calendar);

        expect(identical(bazi.chineseCalendar, calendar), isTrue);

        bazi.close();
        calendar.close();
      });

      test('rejects a calendar owned by a different ephemeris context', () {
        final other = context.clone();
        expect(
          () => context.createBazi(calendar: other.chineseCalendar),
          throwsArgumentError,
        );
        other.close();
      });

      test('a cached entry whose calendar was closed is replaced', () {
        final calendar = context.chineseCalendar;
        final first = context.bazi;
        calendar.close();

        final second = context.bazi;
        expect(identical(first, second), isFalse);
        expect(second.chineseCalendar.isClosed, isFalse);
        second.close();
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
