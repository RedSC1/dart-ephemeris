import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

void main() {
  group(
    'GanzhiApi native integration',
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

      test('builds a Ganzhi from stem and branch ids', () {
        final jiaZi = context.ganzhi.make(stemId: 0, branchId: 0);
        expect(jiaZi.raw, 0);
        expect(jiaZi.stem, HeavenlyStem.jia);
        expect(jiaZi.branch, EarthlyBranch.zi);

        final wuXu = context.ganzhi.make(stemId: 4, branchId: 10);
        expect(wuXu.raw, (4 << 4) | 10);
      });

      test('advances along the sexagenary cycle', () {
        final jiaZi = context.ganzhi.make(stemId: 0, branchId: 0);
        // 甲子 + 1 = 乙丑 (stem 1, branch 1); the packed raw is (1<<4)|1 = 17.
        final yiChou = context.ganzhi.advance(jiaZi, 1);
        expect(yiChou.stemId, 1);
        expect(yiChou.branchId, 1);
        // A full cycle returns to 甲子.
        expect(context.ganzhi.advance(jiaZi, 60).raw, 0);
      });

      test('computes the day pillar for a civil date', () {
        // 2024-02-10 (甲辰 new year) has the 甲辰 day pillar.
        final day = context.ganzhi.dayPillar(AstroDateTime(2024, 2, 10));
        expect(day.stemId, 0);
        expect(day.branchId, 4);
      });

      test('derives month and hour pillar stems', () {
        // 甲 year, 寅 month (index 0) via 五虎遁 is 丙寅.
        final month = context.ganzhi.monthPillar(yearStemId: 0, monthIndex: 0);
        expect(month.stemId, 2);
        expect(month.branchId, 2);

        // 甲 day, 子 hour via 五鼠遁 is 甲子.
        final hour = context.ganzhi.hourPillar(dayStemId: 0, hourIndex: 0);
        expect(hour.stemId, 0);
        expect(hour.branchId, 0);
      });

      test('resolves NaYin element and id', () {
        final jiaZi = context.ganzhi.make(stemId: 0, branchId: 0);
        // 甲子/乙丑 share the 海中金 (metal) NaYin id 0.
        expect(context.ganzhi.nayinId(jiaZi), 0);
        expect(context.ganzhi.nayinElement(jiaZi), GanzhiWuxing.metal);
      });

      test('rejects invalid stem-branch combinations', () {
        expect(
          () => context.ganzhi.make(stemId: 0, branchId: 1),
          throwsA(isA<EphemerisError>()),
        );
        for (final invalidStem in [-1, 10, 256]) {
          expect(
            () => context.ganzhi.make(stemId: invalidStem, branchId: 0),
            throwsArgumentError,
          );
          expect(
            () => context.ganzhi.monthPillar(
              yearStemId: invalidStem,
              monthIndex: 0,
            ),
            throwsArgumentError,
          );
        }
        for (final invalidBranch in [-1, 12, 256]) {
          expect(
            () => context.ganzhi.make(stemId: 0, branchId: invalidBranch),
            throwsArgumentError,
          );
          expect(
            () => context.ganzhi.hourPillar(
              dayStemId: 0,
              hourIndex: invalidBranch,
            ),
            throwsArgumentError,
          );
        }
        final jiaZi = context.ganzhi.make(stemId: 0, branchId: 0);
        expect(
          () => context.ganzhi.advance(jiaZi, 0x80000000),
          throwsArgumentError,
        );
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
