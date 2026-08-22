import 'package:taiyin/taiyin.dart';
import 'package:taiyin_ziwei/taiyin_ziwei.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  group(
    'Ziwei native integration',
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

      ZiweiChart createReferenceChart(ZiweiContext ziwei) {
        final local = AstroDateTime(2003, 3, 13, 14, 15);
        final instant = local.toJulianDate<UtcScale>().addSeconds(-8 * 3600);
        return ziwei
            .createChart(
              instantUtc: instant,
              virtualTime: local,
              gender: ZiweiGender.male,
            )
            .value;
      }

      test('default catalog produces a chart', () {
        final ziwei = context.ziwei;
        final chart = createReferenceChart(ziwei);

        expect(ziwei.starCount, 159);
        expect(chart.anchors.values, hasLength(31));
        expect(chart.summary.bureauId, 1);

        final star = ziwei.findStar('ziwei');
        expect(star, isNotNull);
        expect(star!.key, 'ziwei');
        expect(star.category, ZiweiStarCategory.major);
        expect(chart.starPosition(star.id), 4);
        expect(chart.starPalace(star.id), isNotNull);
        expect(chart.brightness(star.id), ZiweiBrightness.de);

        expect(ziwei.findStar('no-such-star'), isNull);
        expect(() => ziwei.findStar(''), throwsArgumentError);
        expect(() => ziwei.findStar('ziwei\u0000invalid'), throwsArgumentError);
      });

      test('named anchors and palaces expose the semantic chart view', () {
        final ziwei = context.ziwei;
        final chart = createReferenceChart(ziwei);
        final anchors = chart.anchors;

        expect(anchors[ZiweiAnchorSlot.ziwei], 4);
        expect(anchors.ziwei, 4);
        expect(anchors.bureau, ZiweiBureau.wood3);
        expect(chart.summary.bureau, ZiweiBureau.wood3);

        final life = chart.palace(ZiweiPalace.life);
        expect(life.branchId, anchors.palacePosition(ZiweiPalace.life));
        expect(life.stemId, chart.summary.palaceStems[life.branchId]);
        expect(chart.palaces, hasLength(12));
        expect(chart.palaces[ZiweiPalace.life.id].palace, ZiweiPalace.life);
        expect(life.stars.map((star) => star.key), contains('lianzhen'));
      });

      test('exposes palace stars and the transform overlay', () {
        final ziwei = context.ziwei;
        final chart = createReferenceChart(ziwei);
        final star = ziwei.findStar('lianzhen');
        expect(star, isNotNull);

        final lifePalace = chart.anchors[ZiweiAnchorSlot.palaceLife];
        expect(
          chart.palaceStars(lifePalace).map((item) => item.id),
          contains(star!.id),
        );
        expect(chart.transformMask(star.id), isNot(0));
        expect(
          ZiweiTransformMark.values.any(
            (mark) => chart.hasTransform(star.id, mark),
          ),
          isTrue,
        );
      });

      test('catalog selection context reuses loaded resources', () {
        final catalog = ZiweiDataCatalog(coreLibraryPath: libraryPath);
        addTearDown(catalog.close);
        final firstGeneration = catalog.generation;

        catalog.reload();
        expect(catalog.generation, greaterThan(firstGeneration));

        final ziwei = context.createZiwei(
          catalog: catalog,
          selection: const ZiweiOptionSelection(placementDefault: 'option1'),
        );
        addTearDown(ziwei.close);

        expect(ziwei.generation, catalog.generation);
        expect(ziwei.findStar('ziwei')!.key, 'ziwei');
      });

      test(
        'selects an independent longevity table and rejects bad options',
        () {
          // This retained case resolves to an Earth-5 bureau, the only bureau
          // slice on which bundled longevity option2 differs from option1.
          final local = AstroDateTime(2100, 2, 4, 12);
          final defaultZiwei = context.createZiwei();
          final alternateZiwei = context.createZiwei(
            selection: const ZiweiOptionSelection(longevity: 'option2'),
          );
          addTearDown(defaultZiwei.close);
          addTearDown(alternateZiwei.close);

          final defaultChart = defaultZiwei
              .calculateLocal(local, gender: ZiweiGender.male)
              .value;
          final alternateChart = alternateZiwei
              .calculateLocal(local, gender: ZiweiGender.male)
              .value;
          addTearDown(defaultChart.close);
          addTearDown(alternateChart.close);

          final changsheng = defaultZiwei.findStar('changsheng')!;
          expect(
            defaultChart.starPosition(changsheng.id),
            isNot(alternateChart.starPosition(changsheng.id)),
          );
          expect(
            () => context.createZiwei(
              selection: const ZiweiOptionSelection(longevity: 'option99'),
            ),
            throwsA(isA<EphemerisError>()),
          );
        },
      );

      test('a caller catalog owns the native-module selection', () {
        final catalog = ZiweiDataCatalog(coreLibraryPath: libraryPath);
        addTearDown(catalog.close);
        expect(
          () => context.createZiwei(
            catalog: catalog,
            libraryPath: '/different/libtaiyin_ziwei.dylib',
          ),
          throwsArgumentError,
        );
      });

      test('calculates charts from local time and from an instant', () {
        final ziwei = context.ziwei;
        final local = AstroDateTime(2003, 3, 13, 14, 15);

        final localResult = ziwei.calculateLocal(
          local,
          gender: ZiweiGender.male,
        );
        final fromLocal = localResult.value;
        addTearDown(fromLocal.close);

        final instant = local.toJulianDate<UtcScale>().addSeconds(-8 * 3600);
        final instantResult = ziwei.calculateInstant(
          instant,
          gender: ZiweiGender.male,
        );
        final fromInstant = instantResult.value;
        addTearDown(fromInstant.close);

        expect(fromLocal.anchors.values, fromInstant.anchors.values);
        expect(fromLocal.summary.bureau, fromInstant.summary.bureau);
        expect(localResult.flags, isA<ResultFlags>());
        expect(instantResult.flags, isA<ResultFlags>());
      });

      test('sets and truncates the flow stack', () {
        final ziwei = context.ziwei;
        final chart = createReferenceChart(ziwei);

        final target = AstroDateTime(2024, 2, 10, 12);
        final targetInstant = target.toJulianDate<UtcScale>().addSeconds(
          -8 * 3600,
        );
        final flowResult = chart.setFlow(
          targetInstantUtc: targetInstant,
          targetVirtualTime: target,
        );
        final resolution = flowResult.value;

        expect(chart.flowLayerCount, 5);
        expect(resolution.decade.startAge, lessThan(resolution.decade.endAge));
        expect(resolution.smallLimit.virtualAge, greaterThan(0));
        expect(flowResult.flags, isA<ResultFlags>());

        final decadeSummary = chart.flowLayerSummary(ZiweiFlowLevel.decade);
        expect(decadeSummary.lifePalace, inInclusiveRange(0, 11));
        expect(decadeSummary.coordinateStem, inInclusiveRange(0, 9));
        expect(decadeSummary.coordinateBranch, inInclusiveRange(0, 11));

        final ziweiStar = ziwei.findStar('ziwei')!;
        final branch = chart.flowStarPosition(
          ZiweiFlowLevel.year,
          ziweiStar.id,
        );
        if (branch != null) {
          expect(branch, inInclusiveRange(0, 11));
          expect(
            chart
                .flowPalaceStars(ZiweiFlowLevel.year, branch)
                .map((star) => star.id),
            contains(ziweiStar.id),
          );
        }

        chart.truncateFlow(ZiweiFlowLevel.month);
        expect(chart.flowLayerCount, 2);
      });

      test('steps flow hour and day targets', () {
        final ziwei = context.ziwei;
        final local = AstroDateTime(2003, 3, 13, 14, 15);
        final instant = local.toJulianDate<UtcScale>().addSeconds(-8 * 3600);

        final nextHour = ziwei.nextFlowHourTarget(
          instantUtc: instant,
          virtualTime: local,
        );
        expect(nextHour.instantUtc.isAfter(instant), isTrue);

        final previousHour = ziwei.previousFlowHourTarget(
          instantUtc: nextHour.instantUtc,
          virtualTime: nextHour.virtualTime,
        );
        // Stepping lands on canonical slot centers, so the round trip from
        // 14:15 returns the center of its slot (14:00), not 14:15 itself.
        expect(previousHour.virtualTime.hour, 14);
        expect(previousHour.virtualTime.minute, 0);
        expect(previousHour.instantUtc.isBefore(nextHour.instantUtc), isTrue);

        final nextDay = ziwei.nextFlowDayTarget(
          instantUtc: instant,
          virtualTime: local,
        );
        expect(nextDay.virtualTime.day, 14);
        expect(nextDay.virtualTime.hour, local.hour);
        expect(nextDay.virtualTime.minute, local.minute);

        expect(
          () => ziwei.stepFlowDayTarget(
            instantUtc: instant,
            virtualTime: local,
            direction: 0,
          ),
          throwsArgumentError,
        );
      });

      test('reverse lookup finds the reference birth slot', () {
        final ziwei = context.ziwei;
        final local = AstroDateTime(2003, 3, 13, 14, 15);
        final instant = local.toJulianDate<UtcScale>().addSeconds(-8 * 3600);

        final chart = createReferenceChart(ziwei);
        final ziweiStar = ziwei.findStar('ziwei')!;
        final branch = chart.starPosition(ziweiStar.id);
        expect(branch, isNotNull);

        final dayStart = AstroDateTime(2003, 3, 13);
        final startInstant = dayStart.toJulianDate<UtcScale>().addSeconds(
          -8 * 3600,
        );
        final result = ziwei
            .reverseLookupTier1(
              startInstantUtc: startInstant,
              endInstantUtc: startInstant.addSeconds(86400),
              startVirtualTime: dayStart,
              gender: ZiweiGender.male,
              query: ZiweiTier1ReverseQuery(ziweiBranch: branch),
            )
            .value;
        final candidates = result;

        expect(candidates, isNotEmpty);
        expect(
          candidates.any(
            (candidate) =>
                candidate.virtualTime.hour == local.hour &&
                (candidate.instantUtc.toDouble() - instant.toDouble()).abs() <
                    1 / 24,
          ),
          isTrue,
          reason: 'the 14:15 birth slot matches the ziweiBranch filter',
        );

        expect(
          () => ziwei
              .reverseLookupTier1(
                startInstantUtc: startInstant,
                endInstantUtc: startInstant,
                startVirtualTime: dayStart,
                gender: ZiweiGender.male,
                query: const ZiweiTier1ReverseQuery(),
              )
              .value,
          throwsArgumentError,
        );
        expect(
          () => ziwei
              .reverseLookupTier1(
                startInstantUtc: startInstant,
                endInstantUtc: startInstant,
                startVirtualTime: dayStart,
                gender: ZiweiGender.male,
                query: const ZiweiTier1ReverseQuery(ziweiBranch: 12),
              )
              .value,
          throwsArgumentError,
        );
      });

      test('charts invalidate with their context', () {
        final ziwei = context.createZiwei();
        final chart = createReferenceChart(ziwei);

        ziwei.close();
        expect(() => chart.anchors, throwsStateError);
        expect(ziwei.isClosed, isTrue);

        final replacement = context.ziwei;
        expect(replacement.isClosed, isFalse);
      });

      test('rejects a calendar owned by a different ephemeris context', () {
        final other = context.clone();
        expect(
          () => context.createZiwei(calendar: other.chineseCalendar),
          throwsArgumentError,
        );
        other.close();
      });
    },
    skip: nativeLibraryAvailable
        ? false
        : 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.',
  );
}
