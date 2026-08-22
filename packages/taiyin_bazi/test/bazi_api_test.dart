import 'package:taiyin/taiyin.dart';
import 'package:taiyin_bazi/taiyin_bazi.dart';
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
        final pillars = context.chineseCalendar
            .fourPillars(
              instantUtc: JulianDate<UtcScale>.fromDouble(2460351.0),
              virtualTime: AstroDateTime(2024, 2, 10, 12),
            )
            .value;
        return context.bazi.calcChart(pillars);
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

        final triple = context.bazi.calcBranchTripleRelation(8, 0, 4); // 申子辰
        expect(
          triple.flags,
          contains(BaziBranchTripleRelationFlags.combination),
        );
        expect(triple.combinedElementId, BaziWuxing.water);
      });

      test('covers flow-month, direct xiao-yun, and both life-stage modes', () {
        final jiaChen = context.ganzhi.make(stemId: 0, branchId: 4);
        final flowMonth = context.bazi.calcLiuyue(jiaChen, 2);
        expect(flowMonth.stemId, 2); // 甲年寅月为丙寅.
        expect(flowMonth.branchId, 2);

        expect(
          context.bazi.getLifeStage(
            stemId: 4,
            branchId: 2,
            mode: BaziEarthPalaceMode.fireEarth,
          ),
          0,
        );
        expect(
          context.bazi.getLifeStage(
            stemId: 4,
            branchId: 8,
            mode: BaziEarthPalaceMode.waterEarth,
          ),
          0,
        );

        final chart = chartFor2024();
        final direct = context.bazi.calcXiaoyun(chart, -1, 7);
        final filled = context.bazi.fillXiaoyun(
          chart: chart,
          direction: -1,
          startAge: 7,
          requestedCount: 1,
        );
        expect(filled.single.ganzhi, direct);
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
        final qiyun = context.bazi
            .calcQiyun(
              birthJdUt: JulianDate<Ut1Scale>.fromDouble(2460351.0),
              birthCivilTime: AstroDateTime(2024, 2, 10, 12),
              chart: chart,
              gender: BaziGender.male,
            )
            .value;
        expect(context.lastDiagnostic?.status, 0);
        expect(qiyun.startAgeYears, greaterThan(0));
        // 甲 year male advances forward (+1).
        expect(qiyun.direction, 1);

        final dayun = context.bazi.fillDayun(
          birthCivilTime: AstroDateTime(2024, 2, 10, 12),
          chart: chart,
          qiyun: qiyun,
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

      test('calculates a complete result with call-scoped flags', () {
        final result = context.bazi.calculateLocal(
          AstroDateTime(2003, 3, 13, 14, 15),
          gender: BaziGender.male,
        );

        expect(result.value.pillars.year, result.value.chart.yearPillar);
        expect(result.value.qiyun.startAgeYears, greaterThan(0));
        expect(result.flags, isA<ResultFlags>());
        expect(context.lastResultFlags, result.flags);

        final instantResult = context.bazi.calculateInstant(
          result.value.instantUtc,
          gender: BaziGender.male,
        );
        expect(
          [
            instantResult.value.pillars.year.raw,
            instantResult.value.pillars.month.raw,
            instantResult.value.pillars.day.raw,
            instantResult.value.pillars.hour.raw,
          ],
          [
            result.value.pillars.year.raw,
            result.value.pillars.month.raw,
            result.value.pillars.day.raw,
            result.value.pillars.hour.raw,
          ],
        );

        final utcCalendar = context.time
            .reverseJulianDay(result.value.instantUtc)
            .value;
        final birthUt1 = context.time
            .scalesFromUtc(utcCalendar)
            .value
            .value
            .ut1;
        final directQiyun = context.bazi
            .calcQiyun(
              birthJdUt: birthUt1,
              birthCivilTime: result.value.localTime,
              chart: result.value.chart,
              gender: BaziGender.male,
            )
            .value;
        expect(
          instantResult.value.qiyun.jieIntervalDays,
          closeTo(directQiyun.jieIntervalDays, 1e-13),
        );
        expect(
          instantResult.value.qiyun.startJdUt.coordinateSecondsDifference(
            directQiyun.startJdUt,
          ),
          closeTo(0, 1e-8),
        );
      });

      test('propagates the configured UTC-to-UT1 fallback into results', () {
        context.close();
        runtime = Ephemeris.open(
          libraryPath: libraryPath,
          options: const RuntimeOptions(loadBuiltinEop: false),
        );
        context = runtime.createContext();
        context.time.setAllowUtcOutOfRangeEstimate(true);

        final result = context.bazi.calculateLocal(
          AstroDateTime(2003, 3, 13, 14, 15),
          gender: BaziGender.male,
        );

        expect(result.flags.contains(ResultFlag.timeScaleFallback), isTrue);
        expect(result.value.qiyun.startAgeYears, greaterThan(0));
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

        final neutral = context.bazi.collectTargetShenSha(
          chart: chart,
          target: chart.yearPillar,
          targetKind: BaziShenShaTargetKind.year,
        );
        expect(neutral.every((id) => id.id >= 0 && id.id <= 65), isTrue);
      });

      test('returns renyuan siling segments for a month branch', () {
        final segments = context.bazi.getRenyuanSilingSegments(
          2,
          BaziRenyuanSilingTableModel.common,
        );
        expect(segments, isNotEmpty);
        expect(segments.length, lessThanOrEqualTo(3));
      });

      test('calculates renyuan siling at a solar-term-relative instant', () {
        final local = AstroDateTime(2026, 2, 19, 23, 28);
        final instantUtc = local.toJulianDate<UtcScale>().addSeconds(-8 * 3600);
        final instantUt = JulianDate<Ut1Scale>.fromParts(
          instantUtc.dayNumber,
          instantUtc.dayFraction,
        );
        final pillars = context.chineseCalendar
            .fourPillars(instantUtc: instantUtc, virtualTime: local)
            .value;
        final chart = context.bazi.calcChart(pillars);
        final previousJie = context.chineseCalendar
            .getPrevJieUt(instantUt)
            .value;
        final result = context.bazi
            .calcRenyuanSiling(
              instantJdUt: previousJie.jdUt.addSeconds(5 * 86400),
              chart: chart,
              tableModel: BaziRenyuanSilingTableModel.sanMingTongHui,
              timeModel: BaziRenyuanSilingTimeModel.elapsed24Hours,
            )
            .value;

        expect(result.monthBranchId, 2);
        expect(result.stemId, 2);
        expect(result.originKind, BaziRenyuanSilingOriginKind.stem);
        expect(result.segmentIndex, 1);
        expect(result.segmentStartDay, 5.0);
      });

      test('rejects use after close', () {
        final bazi = context.bazi;
        bazi.close();
        expect(() => bazi.calcLiunian(2024), throwsStateError);
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
