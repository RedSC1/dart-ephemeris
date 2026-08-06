import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

import 'support/native_library.dart';

void main() {
  group(
    'BaziApi native integration',
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

      BaziChart chartFor2024() {
        final pillars = context.chineseCalendar.fourPillars(
          instantUtc: JulianDate<UtcScale>.fromDouble(2460351.0),
          virtualTime: AstroDateTime(2024, 2, 10, 12),
        );
        return context.bazi.calcChart(pillars.value);
      }

      test('computes kong-wang (空亡) of a sexagenary item', () {
        final jiaZi = context.ganzhi.make(stemId: 0, branchId: 0);
        final kongWang = context.bazi.getKongWang(jiaZi);
        // 甲子旬空戌亥.
        expect(kongWang.a, EarthlyBranch.xu);
        expect(kongWang.b, EarthlyBranch.hai);
      });

      test('computes the ten god of a stem relative to the day master', () {
        // 甲 day master vs 丁 target is 伤官.
        expect(
          context.bazi.getTenGod(dayStemId: 0, targetStemId: 3),
          BaziTenGod.shangGuan,
        );
      });

      test('resolves hidden stems of an earthly branch', () {
        final hidden = context.bazi.getHiddenStems(4); // 辰
        expect(hidden.count, greaterThanOrEqualTo(1));
        expect(hidden.stems, isNotEmpty);
        expect(hidden.stems.every((stem) => stem >= 0 && stem <= 9), isTrue);
      });

      test('computes stem and branch relations', () {
        final stemRel = context.bazi.calcStemRelation(0, 5); // 甲己
        expect(stemRel.flags, contains(BaziStemRelationFlags.combination));
        expect(stemRel.combinedElementId, BaziWuxing.earth);

        final branchRel = context.bazi.calcBranchRelation(0, 1); // 子丑
        expect(branchRel.flags, contains(BaziBranchRelationFlags.combination));
      });

      test('derives a chart from the four pillars', () {
        final chart = chartFor2024();
        // 2024 is 甲辰 (stem 0, branch 4).
        expect(chart.yearPillar.stemId, 0);
        expect(chart.yearPillar.branchId, 4);
        expect(chart.hiddenStems[0], isNotEmpty);
      });

      test('computes flow-year, flow-day, and flow-hour Ganzhi', () {
        expect(context.bazi.calcLiunian(2024).raw, (0 << 4) | 4); // 甲辰
        expect(
          context.bazi.calcLiuri(AstroDateTime(2024, 2, 10)).raw,
          (0 << 4) | 4,
        ); // 甲辰
        final jiaChen = context.ganzhi.make(stemId: 0, branchId: 4);
        // 甲 day, 子 hour via 五鼠遁 is 甲子.
        expect(context.bazi.calcLiushi(jiaChen, 0).raw, 0);
      });

      test('calculates qi-yun and fills da-yun', () {
        final chart = chartFor2024();
        final qiyun = context.bazi.calcQiyun(
          birthJdUt: JulianDate<Ut1Scale>.fromDouble(2460351.0),
          birthCivilTime: AstroDateTime(2024, 2, 10, 12),
          chart: chart,
          gender: BaziGender.male,
          calendar: context.chineseCalendar,
        );
        expect(qiyun.diagnostic.status, 0);
        expect(qiyun.value.startAgeYears, greaterThan(0));
        // 甲 year male advances forward (+1).
        expect(qiyun.value.direction, 1);

        final dayun = context.bazi.fillDayun(
          birthCivilTime: AstroDateTime(2024, 2, 10, 12),
          chart: chart,
          qiyun: qiyun.value,
          requestedCount: 5,
        );
        expect(dayun, hasLength(5));
        // First da-yun after the 丙寅 month pillar, forward: 丁卯.
        expect(dayun.first.ganzhi.stemId, 3);
        expect(dayun.first.ganzhi.branchId, 3);
        // Each step advances one stem and one branch.
        expect(dayun[1].ganzhi.stemId, 4);
        expect(dayun[1].ganzhi.branchId, 4);
      });

      test('fills a contiguous xiao-yun range', () {
        final chart = chartFor2024();
        final entries = context.bazi.fillXiaoyun(
          chart: chart,
          direction: 1,
          startAge: 1,
          requestedCount: 5,
        );
        expect(entries, hasLength(5));
        for (var index = 0; index < entries.length; index++) {
          expect(entries[index].age, 1 + index);
          expect(entries[index].ganzhi, isA<Ganzhi>());
        }
      });

      test('collects chart relations', () {
        final relations = context.bazi.collectChartRelations(
          chart: chartFor2024(),
        );
        expect(relations, isNotEmpty);
        for (final relation in relations) {
          expect(relation.kind, isA<BaziRelationKind>());
          expect(relation.pillarMask, isNotEmpty);
        }
      });

      test('collects shen-sha for a target pillar', () {
        final chart = chartFor2024();
        final set = context.bazi.collectTargetShenSha(
          chart: chart,
          target: chart.yearPillar,
          targetKind: BaziShenShaTargetKind.year,
          gender: BaziGender.male,
        );
        expect(set, isA<Set<BaziShenShaId>>());
        expect(
          set.every((id) => id.id >= 0 && id.id <= 65),
          isTrue,
          reason: 'shen-sha ids must stay within the 66 stable ids',
        );
      });

      test('returns renyuan siling segments for a month branch', () {
        final segments = context.bazi.getRenyuanSilingSegments(
          2,
          BaziRenyuanSilingTableModel.common,
        );
        expect(segments, isNotEmpty);
        expect(segments.length, lessThanOrEqualTo(3));
      });

      test('rejects use after close', () {
        final bazi = context.bazi;
        context.close();
        expect(() => bazi.calcLiunian(2024), throwsStateError);
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
