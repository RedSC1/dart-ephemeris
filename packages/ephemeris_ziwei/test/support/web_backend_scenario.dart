import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';

/// Same public calls on native, Dart2JS and Dart2Wasm. No FFI in this driver.
List<Object?> exerciseZiweiWeb(Ephemeris runtime) {
  final ctx = runtime.createContext();
  ctx.time.setAllowUtcOutOfRangeEstimate(true);
  final rows = <Object?>[];
  void check(bool value, String message) {
    if (!value) throw StateError(message);
  }

  void add(
    String label,
    List<num> values, [
    ResultFlags flags = ResultFlags.none,
  ]) => rows.add({
    'label': 'ziwei/$label',
    'flags': flags.mask,
    'values': values,
  });
  List<num> date(AstroDateTime v) => [
    v.year,
    v.month,
    v.day,
    v.hour,
    v.minute,
    v.fractionalSecond / 1000,
  ];
  List<num> flow(ZiweiFlowResolution v) => [
    v.effectiveBirthYear,
    v.effectiveTargetYear,
    v.targetLunarYear,
    v.targetMonth,
    v.targetEffectiveMonth,
    v.targetMonthSequence,
    v.targetMonthName,
    v.targetPalaceMonthIndex,
    v.targetMonthBuildingBranch,
    v.targetDay,
    v.targetHourIndex,
    v.targetRatHourSegment.id,
    v.targetMonthIsLeap ? 1 : 0,
    v.decade.index,
    v.decade.startAge,
    v.decade.endAge,
    v.smallLimit.virtualAge,
    v.smallLimit.stemId,
    v.smallLimit.branchId,
  ];
  List<num> input(ZiweiPlacementInput v) => [
    v.yearStem,
    v.yearBranch,
    v.month,
    v.day,
    v.hourBranch,
  ];
  final catalog = ZiweiDataCatalog();
  final ziwei = ctx.createZiwei(catalog: catalog);
  final z = ziwei.findStar('ziwei')!;
  void natal(String label, ZiweiChart chart) {
    add('$label/anchors', chart.anchors.values);
    final s = chart.summary;
    add('$label/summary', [
      s.gender.id,
      s.bureau.id,
      s.bodyPalaceBranch,
      s.lifeMaster,
      s.bodyMaster,
      s.transforms.lu,
      s.transforms.quan,
      s.transforms.ke,
      s.transforms.ji,
      ...s.palaceStems,
    ]);
    add('$label/placement', [
      ...input(chart.placement.input),
      chart.placement.lifePalaceShift,
    ]);
    add('$label/omitted', [
      for (final v in chart.omittedPlacements) ...[v.starId, v.missingInputs],
    ]);
    for (final p in chart.palaces) {
      add('$label/palace', [
        p.palace.id,
        p.branchId,
        p.stemId,
        ...p.stars.map((s) => s.id),
      ]);
    }
    check(
      chart.palace(ZiweiPalace.life).branchId ==
          chart.anchors.palacePosition(ZiweiPalace.life),
      'palace lookup',
    );
    for (var id = 0; id < ziwei.starCount; id++) {
      add('$label/star', [
        id,
        chart.starPosition(id) ?? -1,
        chart.starPalace(id) ?? -1,
        chart.brightness(id).id,
        chart.transformMask(id),
        for (final mark in ZiweiTransformMark.values)
          chart.hasTransform(id, mark) ? 1 : 0,
      ]);
    }
  }

  void cast(String label, ZiweiCastingChart c) {
    final s = c.summary;
    add('$label/summary', [
      ...input(s.input),
      ...input(s.originalInput),
      s.index ?? -1,
      s.method.index,
      s.gender.id,
      s.chartMode.id,
      s.bureau.id,
      s.originalBureau.id,
      s.bodyPalace,
      s.lifeMaster,
      s.bodyMaster,
      s.yearTransformStem,
      s.updateBureau ? 1 : 0,
      s.lifePalaceShift,
      ...s.palaceBranches,
      ...s.palaceStems,
      ...s.transformations,
      ...s.number.codeUnits,
    ]);
    for (var id = 0; id < ziwei.starCount; id++) {
      add('$label/stars', [
        id,
        c.starPosition(id) ?? -1,
        c.starPalace(id) ?? -1,
        c.transformMask(id),
        c.brightness(id).id,
      ]);
    }
    add('$label/omitted', [
      for (final v in c.omittedPlacements) ...[v.starId, v.missingInputs],
    ]);
    for (var b = 0; b < 12; b++) {
      add('$label/palace', [b, ...c.palaceStars(b).map((s) => s.id)]);
    }
  }

  try {
    add('catalog', [catalog.generation, ziwei.generation, ziwei.starCount]);
    catalog.reload();
    check(catalog.generation > ziwei.generation, 'catalog snapshot generation');
    catalog.close();
    check(ziwei.findStar('not_a_star') == null, 'unknown star');
    add('metadata', [
      z.id,
      z.category.id,
      z.isNatal ? 1 : 0,
      ...z.key.codeUnits,
    ]);
    final local = AstroDateTime(2003, 3, 13, 14, 15);
    final utc = ctx.chineseCalendar.instantFromLocal(local).value;
    final chart = ziwei
        .createChart(
          instantUtc: utc,
          virtualTime: local,
          gender: ZiweiGender.male,
        )
        .value;
    try {
      natal('natal', chart);
      for (final c in [
        chart.modify(const ZiweiPlacementPatch(month: 5, updateBureau: true)),
        chart.shiftLifePalace(-2),
        chart.reset(),
      ]) {
        add('edited', [
          ...c.anchors.values,
          ...input(c.placement.input),
          c.placement.lifePalaceShift,
          c.flowLayerCount,
        ]);
        c.close();
      }
      for (final mode in ZiweiClockMode.values) {
        final clock = ZiweiClock(
          mode: mode,
          longitudeRadians: 118.582 * 3.141592653589793 / 180,
        );
        final start = ziwei.chartTimeToUt1(
          AstroDateTime(2003, 3, 13, 22),
          clock: clock,
        );
        final round = ziwei.chartTimeFromUt1(start.value, clock: clock);
        add('clock/${mode.index}', [
          start.value.dayNumber,
          start.value.dayFraction,
          ...date(round.value),
        ], start.flags | round.flags);
        final natalClock = ziwei
            .createChartAtUt1(
              instantUt1: start.value,
              gender: ZiweiGender.female,
              clock: clock,
            )
            .value;
        add('clockChart/${mode.index}', natalClock.anchors.values);
        natalClock.close();
        final localChart = ziwei.calculateLocal(
          local,
          gender: ZiweiGender.male,
          clock: clock,
        );
        add(
          'localClock/${mode.index}',
          localChart.value.anchors.values,
          localChart.flags,
        );
        localChart.value.close();
        final instantChart = ziwei.calculateInstant(
          utc,
          gender: ZiweiGender.male,
          clock: clock,
        );
        add(
          'instantClock/${mode.index}',
          instantChart.value.anchors.values,
          instantChart.flags,
        );
        instantChart.value.close();
        for (final rat in GanzhiRatHourMode.values) {
          for (final dir in [-1, 1]) {
            final target = ziwei.stepFlowHourAtUt1(
              instantUt1: start.value,
              clock: clock,
              ratHourMode: rat,
              direction: dir,
            );
            add('step/${mode.index}/${rat.id}/$dir', [
              target.value.instantUt1.dayNumber,
              target.value.instantUt1.dayFraction,
              ...date(target.value.virtualTime),
              target.value.ratHourSegment.id,
            ], target.flags);
          }
          final f = chart.setFlowAtUt1(
            targetInstantUt1: start.value,
            clock: clock,
            options: ZiweiFlowOptions(ratHourMode: rat),
          );
          add('clockFlow/${mode.index}/${rat.id}', flow(f.value), f.flags);
        }
        final day = ziwei.stepFlowDayAtUt1(
          instantUt1: start.value,
          clock: clock,
        );
        add('clockDay/${mode.index}', [
          day.value.instantUt1.dayNumber,
          day.value.instantUt1.dayFraction,
          ...date(day.value.virtualTime),
        ], day.flags);
        final end = ziwei
            .chartTimeToUt1(AstroDateTime(2003, 3, 13, 23), clock: clock)
            .value;
        final expected = ziwei
            .createChartAtUt1(
              instantUt1: start.value,
              gender: ZiweiGender.male,
              clock: clock,
            )
            .value;
        final reverse = ziwei.reverseLookupTier1AtUt1(
          startInstantUt1: start.value,
          endInstantUt1: end,
          gender: ZiweiGender.male,
          clock: clock,
          query: ZiweiTier1ReverseQuery(
            ziweiBranch: expected.starPosition(z.id),
          ),
        );
        add('reverseCount/${mode.index}', [
          reverse.value.length,
        ], reverse.flags);
        for (final c in reverse.value) {
          add('reverse/${mode.index}', [
            c.instantUt1.dayNumber,
            c.instantUt1.dayFraction,
            ...date(c.virtualTime),
            c.lunarYear,
            c.lunarMonth,
            c.lunarDay,
            c.lunarIsLeap ? 1 : 0,
            c.hourBranch,
            c.ratHourSegment.id,
          ]);
        }
        expected.close();
      }
      final reverse = ziwei.reverseLookupTier1(
        startInstantUtc: utc,
        endInstantUtc: utc.addSeconds(3600),
        startVirtualTime: local,
        gender: ZiweiGender.male,
        query: ZiweiTier1ReverseQuery(ziweiBranch: chart.starPosition(z.id)),
      );
      add('legacyReverse', [reverse.value.length], reverse.flags);
      for (final boundary in ZiweiPillarBoundary.values) {
        final t = AstroDateTime(2034, 1, 20, 23);
        final r = chart.setFlow(
          targetInstantUtc: ctx.chineseCalendar.instantFromLocal(t).value,
          targetVirtualTime: t,
          options: ZiweiFlowOptions(boundary: boundary),
        );
        add('flow/${boundary.id}', flow(r.value), r.flags);
        add('layerCount', [chart.flowLayerCount]);
        for (final level in ZiweiFlowLevel.values) {
          final layer = chart.flowLayerSummary(level);
          add('layer', [
            level.id,
            layer.lifePalace,
            layer.coordinateStem,
            layer.coordinateBranch,
            layer.transforms.lu,
            layer.transforms.quan,
            layer.transforms.ke,
            layer.transforms.ji,
            chart.flowStarPosition(level, z.id) ?? -1,
          ]);
          for (var b = 0; b < 12; b++) {
            add('flowStars', [
              level.id,
              b,
              ...chart.flowPalaceStars(level, b).map((s) => s.id),
            ]);
          }
        }
        chart.truncateFlow(ZiweiFlowLevel.month);
        check(chart.flowLayerCount == 2, 'truncate flow');
      }
      for (final mode in GanzhiRatHourMode.values) {
        final next = ziwei.nextFlowHourTarget(
          instantUtc: utc,
          virtualTime: local,
          ratHourMode: mode,
        );
        final prev = ziwei.previousFlowHourTarget(
          instantUtc: next.instantUtc,
          virtualTime: next.virtualTime,
          ratHourMode: mode,
        );
        add('legacyHour', [
          ...date(next.virtualTime),
          ...date(prev.virtualTime),
        ]);
      }
      final next = ziwei.nextFlowDayTarget(instantUtc: utc, virtualTime: local);
      final prev = ziwei.previousFlowDayTarget(
        instantUtc: next.instantUtc,
        virtualTime: next.virtualTime,
      );
      add('legacyDay', [...date(next.virtualTime), ...date(prev.virtualTime)]);
    } finally {
      chart.close();
    }
    final solar = ziwei
        .calculateSolarDay(
          const SolarDate(year: 2003, month: 3, day: 13),
          hour: 14,
          minute: 15,
          gender: ZiweiGender.male,
        )
        .value;
    add('solarDay', solar.anchors.values);
    solar.close();
    final lunar = ziwei
        .calculateLunarDay(
          ctx.chineseCalendar.fromLocal(local).value,
          hour: 14,
          minute: 15,
          gender: ZiweiGender.male,
        )
        .value;
    add('lunarDay', lunar.anchors.values);
    lunar.close();
    for (final method in [0, 1, 2]) {
      final c = method == 0
          ? ziwei.createCastingChart(
              const ZiweiPlacementInput(
                yearStem: 9,
                yearBranch: 7,
                month: 2,
                day: 11,
                hourBranch: 7,
              ),
              gender: ZiweiGender.male,
            )
          : method == 1
          ? ziwei.castingFromIndex(259199, gender: ZiweiGender.female)
          : ziwei.castingFromNumber(
              '123456789012345678901234567890',
              gender: ZiweiGender.male,
            );
      try {
        cast('casting/$method', c);
        for (final edited in [
          c.modify(const ZiweiPlacementPatch(month: 5, updateBureau: true)),
          c.shiftLifePalace(-2),
          c.reset(),
        ]) {
          add('castingEdit', [
            ...input(edited.summary.input),
            edited.summary.lifePalaceShift,
          ]);
          edited.close();
        }
      } finally {
        c.close();
      }
    }
    final random = ziwei.randomCastingChart(gender: ZiweiGender.male);
    check(
      random.summary.index! >= 0 && random.summary.index! < 259200,
      'secure random range',
    );
    random.close();
    add('random', [1]);
    final custom = ctx.createZiwei(
      ruleset: const ZiweiRuleset().addModule(
        const ZiweiJsonRuleModule(
          label: 'web-school',
          starsJson: '[{"key":"ziwei","rule":{"type":"constant","value":5}}]',
        ),
      ),
      selection: const ZiweiOptionSelection(
        placement: {'ziwei': 'web-school'},
        longevity: 'option2',
      ),
    );
    try {
      final c = custom.calculateLocal(local, gender: ZiweiGender.male).value;
      add('custom', [c.starPosition(custom.findStar('ziwei')!.id)!]);
      c.close();
    } finally {
      custom.close();
    }
    for (final t in [
      AstroDateTime(1984, 2, 1, 23),
      AstroDateTime(2033, 12, 22, 23),
      AstroDateTime(23, 12, 2, 23),
      AstroDateTime(-456, 11, 10, 23),
    ]) {
      final c = ziwei
          .calculateLocal(
            t,
            gender: ZiweiGender.male,
            options: const ZiweiBirthOptions(
              ratHourMode: GanzhiRatHourMode.todayGan,
            ),
          )
          .value;
      try {
        final f = c.setFlow(
          targetInstantUtc: ctx.chineseCalendar.instantFromLocal(t).value,
          targetVirtualTime: t,
        );
        add('boundary', [...c.anchors.values, ...flow(f.value)], f.flags);
      } finally {
        c.close();
      }
    }
    var rejected = false;
    try {
      ziwei.castingFromIndex(259200, gender: ZiweiGender.male);
    } on RangeError {
      rejected = true;
    }
    check(rejected, 'invalid casting index');
    ctx.close();
    rejected = false;
    try {
      ziwei.star(z.id);
    } on StateError {
      rejected = true;
    }
    check(rejected, 'closed owner');
    add('lifecycle', [1]);
  } finally {
    ziwei.close();
    catalog.close();
    ctx.close();
  }
  return rows;
}
