import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:taiyin/src/bindings/taiyin_bindings.g.dart';
import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  final libraryPath =
      Platform.environment['TAIYIN_TEST_LIBRARY'] ??
      '../taiyin-ephemeris/build-c-api-release/libtaiyin.dylib';
  final nativeLibraryAvailable = File(libraryPath).existsSync();

  group(
    'Taiyin native integration',
    () {
      late Taiyin taiyin;

      setUp(() {
        taiyin = Taiyin.open(libraryPath: libraryPath);
      });

      tearDown(() {
        taiyin.close();
      });

      test('validates metadata and initializes the catalog', () {
        expect(taiyin.abiVersion, 1);
        expect(taiyin.libraryVersion, '1.0.0');
        expect(taiyin.catalogSize, greaterThan(0));
        expect(
          taiyin.availableCapabilities,
          containsAll({
            TaiyinCapability.runtime,
            TaiyinCapability.time,
            TaiyinCapability.splitTime,
            TaiyinCapability.position,
            TaiyinCapability.eclipse,
            TaiyinCapability.astrology,
          }),
        );
        expect(taiyin.hasCapability(TaiyinCapability.runtime), isTrue);
        expect(taiyin.hasCapability(TaiyinCapability.splitTime), isTrue);
        expect(taiyin.hasCapability(TaiyinCapability.position), isTrue);
      });

      test('maps native status metadata', () {
        const invalidArgument = -1;

        expect(
          taiyin.statusName(invalidArgument),
          'TAIYIN_ERROR_INVALID_ARGUMENT',
        );
        expect(taiyin.statusMessage(invalidArgument), isNotEmpty);
        expect(
          taiyin.statusCategory(invalidArgument),
          TaiyinStatusCategory.generic,
        );
        expect(taiyin.statusCategory(-1001), TaiyinStatusCategory.ephemeris);
        expect(taiyin.statusCategory(-3001), TaiyinStatusCategory.time);
        expect(taiyin.statusCategory(-6001), TaiyinStatusCategory.runtime);
      });

      test('calculates a finite Moon state vector', () {
        final position = taiyin.positionTt(
          TaiyinBody.moon,
          JulianDate<TtScale>.fromDouble(2460409.0),
          flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
        );

        expect(position.values, hasLength(6));
        expect(position.values, everyElement(isA<double>()));
        expect(position.values.every((value) => value.isFinite), isTrue);
        expect(position.isCartesian, isTrue);
      });

      test('matches native fractional calendar conversion', () {
        final bindings = TaiyinBindings(DynamicLibrary.open(libraryPath));
        final value = AstroDateTime(2026, 7, 19, 12, 34, 56, 123456789);

        using((arena) {
          final nativeCalendar = arena<taiyin_calendar_datetime>();
          final nativeJulianDate = arena<Double>();
          bindings.taiyin_calendar_datetime_init(nativeCalendar);
          nativeCalendar.ref
            ..year = value.year
            ..month = value.month
            ..day = value.day
            ..hour = value.hour
            ..minute = value.minute
            ..second = value.fractionalSecond;

          expect(
            bindings.taiyin_julian_day(nativeCalendar, nativeJulianDate),
            0,
          );
          expect(nativeJulianDate.value, value.toJulianDay());

          final reversed = arena<taiyin_calendar_datetime>();
          bindings.taiyin_calendar_datetime_init(reversed);
          expect(
            bindings.taiyin_reverse_julian_day(
              nativeJulianDate.value,
              reversed,
            ),
            0,
          );
          expect(reversed.ref.second, closeTo(value.fractionalSecond, 0.00005));
        });
      });

      test('clones a context without reinitializing the runtime', () {
        final clone = taiyin.clone();
        try {
          final epoch = JulianDate<TtScale>.fromDouble(2460409.0);
          final original = taiyin.positionTt(TaiyinBody.sun, epoch);
          final copied = clone.positionTt(TaiyinBody.sun, epoch);
          expect(copied.values, original.values);
        } finally {
          clone.close();
        }
      });

      test('rejects calls after close', () {
        taiyin.close();
        expect(
          () => taiyin.positionTt(
            TaiyinBody.sun,
            JulianDate<TtScale>.fromDouble(2460409.0),
          ),
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
