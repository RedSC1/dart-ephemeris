import 'dart:io';

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
        expect(taiyin.libraryVersion, isNotEmpty);
        expect(taiyin.catalogSize, greaterThan(0));
      });

      test('calculates a finite Moon state vector', () {
        final position = taiyin.positionTt(
          TaiyinBody.moon,
          2460409.0,
          flags: {TaiyinPositionFlag.xyz, TaiyinPositionFlag.speed},
        );

        expect(position.values, hasLength(6));
        expect(position.values, everyElement(isA<double>()));
        expect(position.values.every((value) => value.isFinite), isTrue);
        expect(position.isCartesian, isTrue);
      });

      test('clones a context without reinitializing the runtime', () {
        final clone = taiyin.clone();
        try {
          final original = taiyin.positionTt(TaiyinBody.sun, 2460409.0);
          final copied = clone.positionTt(TaiyinBody.sun, 2460409.0);
          expect(copied.values, original.values);
        } finally {
          clone.close();
        }
      });

      test('rejects calls after close', () {
        taiyin.close();
        expect(
          () => taiyin.positionTt(TaiyinBody.sun, 2460409.0),
          throwsStateError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
