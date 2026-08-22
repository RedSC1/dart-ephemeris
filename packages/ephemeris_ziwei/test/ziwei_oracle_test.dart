import 'dart:io';

import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

final class _ZiweiOracleCase {
  const _ZiweiOracleCase(
    this.localTime,
    this.gender,
    this.lifePalace,
    this.bodyPalace,
    this.bureauId,
    this.starFingerprint,
  );

  final AstroDateTime localTime;
  final ZiweiGender gender;
  final int lifePalace;
  final int bodyPalace;
  final int bureauId;
  final int starFingerprint;
}

// The same 23 physical clocks retained by the C++ core's legacy-oracle suite.
// Late-Zi cases retain the legacy no-split logical-day convention. Ancient
// reform boundaries lock the current calendar-backed public C ABI semantics
// rather than the core unit test's injected CalendarFacts. The compact
// fingerprint covers all 115 natal star positions; the first 115 stable
// StarIds are the natal registry.
final _oracleCases = <_ZiweiOracleCase>[
  _ZiweiOracleCase(
    AstroDateTime(181, 8, 20, 8),
    ZiweiGender.male,
    4,
    0,
    0,
    776110190,
  ),
  _ZiweiOracleCase(
    AstroDateTime(2003, 3, 13, 14, 15),
    ZiweiGender.female,
    8,
    10,
    1,
    1703697249,
  ),
  _ZiweiOracleCase(
    AstroDateTime(2023, 3, 25, 10, 30),
    ZiweiGender.male,
    10,
    8,
    0,
    887406099,
  ),
  _ZiweiOracleCase(
    AstroDateTime(-100, 1, 15, 22, 30),
    ZiweiGender.female,
    1,
    11,
    0,
    1978452087,
  ),
  _ZiweiOracleCase(
    AstroDateTime(1949, 10, 1, 15),
    ZiweiGender.male,
    1,
    5,
    0,
    1098447801,
  ),
  _ZiweiOracleCase(
    AstroDateTime(1984, 2, 4, 23, 30),
    ZiweiGender.male,
    2,
    2,
    4,
    1449979539,
  ),
  _ZiweiOracleCase(
    AstroDateTime(1984, 2, 4, 23, 30),
    ZiweiGender.female,
    2,
    2,
    4,
    1089783635,
  ),
  _ZiweiOracleCase(
    AstroDateTime(2000, 1, 1, 0, 30),
    ZiweiGender.male,
    0,
    0,
    0,
    1587881783,
  ),
  _ZiweiOracleCase(
    AstroDateTime(2000, 1, 1, 23, 30),
    ZiweiGender.female,
    0,
    0,
    0,
    1437700507,
  ),
  _ZiweiOracleCase(
    AstroDateTime(2023, 4, 5, 23, 30),
    ZiweiGender.female,
    4,
    4,
    3,
    2094248536,
  ),
  _ZiweiOracleCase(
    AstroDateTime(2033, 12, 22, 12),
    ZiweiGender.male,
    6,
    6,
    4,
    971375752,
  ),
  _ZiweiOracleCase(
    AstroDateTime(-720, 1, 15, 12),
    ZiweiGender.male,
    9,
    9,
    0,
    1573772085,
  ),
  _ZiweiOracleCase(
    AstroDateTime(-479, 1, 15, 12),
    ZiweiGender.female,
    9,
    9,
    4,
    795725980,
  ),
  _ZiweiOracleCase(
    AstroDateTime(-220, 1, 15, 12),
    ZiweiGender.male,
    7,
    7,
    3,
    1014281588,
  ),
  _ZiweiOracleCase(
    AstroDateTime(-104, 1, 15, 12),
    ZiweiGender.female,
    7,
    7,
    1,
    1369995404,
  ),
  _ZiweiOracleCase(
    AstroDateTime(237, 1, 15, 12),
    ZiweiGender.male,
    7,
    7,
    2,
    1193629388,
  ),
  _ZiweiOracleCase(
    AstroDateTime(690, 1, 15, 12),
    ZiweiGender.female,
    8,
    8,
    0,
    535271871,
  ),
  _ZiweiOracleCase(
    AstroDateTime(701, 1, 15, 12),
    ZiweiGender.male,
    7,
    7,
    1,
    17133223,
  ),
  _ZiweiOracleCase(
    AstroDateTime(762, 1, 15, 12),
    ZiweiGender.female,
    9,
    9,
    3,
    1250661078,
  ),
  _ZiweiOracleCase(
    AstroDateTime(1582, 10, 4, 12),
    ZiweiGender.male,
    4,
    4,
    4,
    2024539082,
  ),
  _ZiweiOracleCase(
    AstroDateTime(1900, 1, 31, 12),
    ZiweiGender.female,
    8,
    8,
    0,
    1175305433,
  ),
  _ZiweiOracleCase(
    AstroDateTime(2100, 2, 4, 12),
    ZiweiGender.male,
    7,
    7,
    3,
    1760087738,
  ),
  _ZiweiOracleCase(
    AstroDateTime(2200, 12, 31, 12),
    ZiweiGender.female,
    6,
    6,
    1,
    1743145862,
  ),
];

int _natalStarFingerprint(ZiweiChart chart) {
  var hash = 0;
  for (var starId = 0; starId < 115; starId++) {
    final position = chart.starPosition(starId) ?? -1;
    hash = ((hash * 16777619) ^ (position + 1)) & 0x7fffffff;
  }
  return hash;
}

void main() {
  group('Ziwei oracle coverage', () {
    late EphemerisContext owner;
    late ZiweiContext ziwei;

    setUpAll(() {
      owner = Ephemeris.open(libraryPath: libraryPath).createContext();
      ziwei = owner.ziwei;
    });

    tearDownAll(() {
      ziwei.close();
      owner.close();
    });

    test('locks the 23-case calendar-backed natal regression corpus', () {
      for (var index = 0; index < _oracleCases.length; index++) {
        final oracle = _oracleCases[index];
        final chart = ziwei
            .calculateLocal(oracle.localTime, gender: oracle.gender)
            .value;
        try {
          expect(
            chart.anchors.palacePosition(ZiweiPalace.life),
            oracle.lifePalace,
            reason: 'oracle $index life palace',
          );
          expect(
            chart.summary.bodyPalaceBranch,
            oracle.bodyPalace,
            reason: 'oracle $index body palace',
          );
          expect(
            chart.summary.bureauId,
            oracle.bureauId,
            reason: 'oracle $index bureau',
          );
          expect(
            _natalStarFingerprint(chart),
            oracle.starFingerprint,
            reason: 'oracle $index all 115 natal star positions',
          );
          for (var starId = 115; starId < ziwei.starCount; starId++) {
            expect(
              chart.starPosition(starId),
              isNull,
              reason: 'oracle $index flow-only star $starId leaked',
            );
          }
        } finally {
          chart.close();
        }
      }
    });

    final requestedStressCases =
        int.tryParse(Platform.environment['TAIYIN_ZIWEI_STRESS_CASES'] ?? '') ??
        0;
    test(
      'optional finite wrapper stress matrix',
      () {
        for (var index = 0; index < requestedStressCases; index++) {
          final local = AstroDateTime(
            1984 + (index ~/ 72576) % 60,
            1 + (index ~/ 6048) % 12,
            1 + (index ~/ 216) % 28,
            ((index ~/ 18) % 12) * 2,
          );
          final chart = ziwei
              .calculateLocal(
                local,
                gender: ZiweiGender.values[index % 2],
                options: ZiweiBirthOptions(
                  ratHourMode: GanzhiRatHourMode.values[(index ~/ 2) % 3],
                  chartMode: ZiweiChartMode.values[(index ~/ 6) % 3],
                ),
              )
              .value;
          try {
            expect(chart.anchors.values, hasLength(ZiweiAnchorSlot.count));
            expect(chart.summary.bodyPalaceBranch, inInclusiveRange(0, 11));
            expect(chart.summary.bureauId, inInclusiveRange(0, 4));
            expect(
              _natalStarFingerprint(chart),
              inInclusiveRange(0, 0x7fffffff),
            );
          } finally {
            chart.close();
          }
        }
      },
      skip: requestedStressCases > 0
          ? false
          : 'Set TAIYIN_ZIWEI_STRESS_CASES to enable the maintainer matrix.',
    );
  }, skip: nativeLibraryAvailable ? false : libraryUnavailableSkip);
}
