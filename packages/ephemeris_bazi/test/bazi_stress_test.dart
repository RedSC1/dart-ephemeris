import 'dart:io';

import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_bazi/ephemeris_bazi.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

void main() {
  final requestedCases =
      int.tryParse(Platform.environment['TAIYIN_BAZI_STRESS_CASES'] ?? '') ?? 0;

  test(
    'optional BaZi and Qi-Yun wrapper stress matrix',
    () {
      final owner = Ephemeris.open(libraryPath: libraryPath).createContext();
      final bazi = owner.bazi;
      try {
        for (var index = 0; index < requestedCases; index++) {
          final local = AstroDateTime(
            1984 + (index ~/ 72576) % 60,
            1 + (index ~/ 6048) % 12,
            1 + (index ~/ 216) % 28,
            ((index ~/ 18) % 12) * 2,
          );
          final result = bazi.calculateLocal(
            local,
            gender: BaziGender.values[index % 2],
            ratHourMode: GanzhiRatHourMode.values[(index ~/ 2) % 3],
          );
          expect(result.value.qiyun.direction.abs(), 1);
          expect(result.value.qiyun.startAgeYears.isFinite, isTrue);
          expect(result.value.chart.hiddenStems, hasLength(4));
          expect(result.value.chart.lifeStages, hasLength(4));
        }
      } finally {
        bazi.close();
        owner.close();
      }
    },
    skip: !nativeLibraryAvailable
        ? libraryUnavailableSkip
        : requestedCases > 0
        ? false
        : 'Set TAIYIN_BAZI_STRESS_CASES to enable the maintainer matrix.',
  );
}
