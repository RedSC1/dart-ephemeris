import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_bazi/ephemeris_bazi.dart';

List<Object?> exerciseBaziWeb(Ephemeris runtime) {
  final ctx = runtime.createContext();
  final rows = <Object?>[];
  void add(
    String label,
    List<num> values, [
    ResultFlags flags = ResultFlags.none,
  ]) =>
      rows.add({'label': 'bazi/$label', 'flags': flags.mask, 'values': values});
  List<num> chart(BaziChart v) => [
    v.yearPillar.raw,
    v.monthPillar.raw,
    v.dayPillar.raw,
    v.hourPillar.raw,
    v.mingGong.raw,
    v.shenGong.raw,
    v.taiYuan.raw,
    v.taiXi.raw,
    ...v.hiddenStemCount,
    for (final r in v.hiddenStems) ...r,
    ...v.visibleTenGods,
    for (final r in v.hiddenTenGods) ...r,
    ...v.lifeStages,
    ...v.nayinIds,
  ];
  final bazi = ctx.bazi;
  try {
    final local = AstroDateTime(2003, 3, 13, 14, 15);
    final result = bazi.calculateLocal(local, gender: BaziGender.male);
    add('chart', chart(result.value.chart), result.flags);
    final q = result.value.qiyun;
    add('qiyun', [
      q.direction,
      q.timeModel.id,
      q.referenceJieIndex,
      q.jieIntervalDays,
      q.startAgeYears,
      q.offsetYears,
      q.offsetMonths,
      q.offsetDays,
      q.offsetHours,
      q.offsetMinutes,
      q.offsetSeconds,
      q.referenceJieJdUt.dayNumber,
      q.referenceJieJdUt.dayFraction,
      q.startJdUt.dayNumber,
      q.startJdUt.dayFraction,
    ]);
    final c = result.value.chart;
    for (final mode in BaziClockMode.values) {
      final p = bazi.calculateLocal(
        local,
        gender: BaziGender.female,
        clock: BaziClock(
          mode: mode,
          longitudeRadians: 118.582 * 3.141592653589793 / 180,
        ),
      );
      add('clock/${mode.index}', [
        ...chart(p.value.chart),
        p.value.chartTime.hour,
        p.value.chartTime.minute,
        p.value.chartTime.fractionalSecond,
      ], p.flags);
    }
    final kw = bazi.getKongWang(c.dayPillar);
    add('kongwang', [kw.a.id, kw.b.id]);
    add('tengod', [bazi.getTenGod(dayStemId: 2, targetStemId: 4).id]);
    final hidden = bazi.getHiddenStems(8);
    add('hidden', [hidden.count, ...hidden.stems]);
    add('stemrelation', [
      bazi.calcStemRelation(0, 5).combinedElementId?.id ?? -1,
    ]);
    add('branchrelation', [
      bazi.calcBranchRelation(0, 1).combinedElementId?.id ?? -1,
    ]);
    add('triplerelation', [
      bazi.calcBranchTripleRelation(8, 0, 4).combinedElementId?.id ?? -1,
    ]);
    add('lifestage', [bazi.getLifeStage(stemId: 2, branchId: 3)]);
    add('flows', [
      bazi.calcLiunian(2026).raw,
      bazi.calcLiuyue(c.yearPillar, 3).raw,
      bazi.calcLiuri(local).raw,
      bazi.calcLiushi(c.dayPillar, 7).raw,
      bazi.calcXiaoyun(c, 1, 2).raw,
    ]);
    for (final x in bazi.fillXiaoyun(
      chart: c,
      direction: 1,
      startAge: 1,
      requestedCount: 5,
    )) {
      add('xiaoyun', [x.age, x.ganzhi.raw]);
    }
    for (final d in bazi.fillDayun(
      birthCivilTime: local,
      chart: c,
      qiyun: q,
      requestedCount: 5,
    )) {
      add('dayun', [
        d.index,
        d.ganzhi.raw,
        d.startVirtualAge,
        d.endVirtualAge,
        d.startJdUt.dayNumber,
        d.startJdUt.dayFraction,
        d.endJdUt.dayNumber,
        d.endJdUt.dayFraction,
      ]);
    }
    final instant = ctx.time
        .scalesFromUtc(ctx.time.reverseJulianDay(result.value.instantUtc).value)
        .value
        .value
        .ut1;
    for (final table in BaziRenyuanSilingTableModel.values) {
      for (final segment in bazi.getRenyuanSilingSegments(3, table)) {
        add('segments', [
          segment.stemId,
          segment.originKind.id,
          segment.segmentIndex,
          segment.startDay,
          segment.endDay,
        ]);
      }
      for (final time in BaziRenyuanSilingTimeModel.values) {
        final r = bazi.calcRenyuanSiling(
          instantJdUt: instant,
          chart: c,
          tableModel: table,
          timeModel: time,
        );
        final v = r.value;
        add('siling', [
          v.tableModel.id,
          v.timeModel.id,
          v.monthBranchId,
          v.stemId,
          v.originKind.id,
          v.segmentIndex,
          v.previousJieIndex,
          v.daysSinceJie,
          v.segmentStartDay,
          v.segmentEndDay,
          v.previousJieJdUt.dayNumber,
          v.previousJieJdUt.dayFraction,
        ], r.flags);
      }
    }
    for (final relation in bazi.collectChartRelations(chart: c)) {
      add('relations', [
        relation.kind.id,
        relation.combinedElementId?.id ?? -1,
      ]);
    }
    for (final gender in [null, BaziGender.male, BaziGender.female]) {
      add('shensha', [
        ...bazi
            .collectTargetShenSha(
              chart: c,
              target: c.dayPillar,
              targetKind: BaziShenShaTargetKind.day,
              gender: gender,
            )
            .map((s) => s.id),
      ]);
    }
    final instantResult = bazi.calculateInstant(
      result.value.instantUtc,
      gender: BaziGender.male,
    );
    add('instant', chart(instantResult.value.chart), instantResult.flags);
    add(
      'solar',
      chart(
        bazi
            .calculateSolarDay(
              const SolarDate(year: 2003, month: 3, day: 13),
              hour: 14,
              minute: 15,
              gender: BaziGender.male,
            )
            .value
            .chart,
      ),
    );
    final lunar = ctx.chineseCalendar.fromLocal(local).value;
    add(
      'lunar',
      chart(
        bazi
            .calculateLunarDay(
              lunar,
              hour: 14,
              minute: 15,
              gender: BaziGender.male,
            )
            .value
            .chart,
      ),
    );
    // Custom C++ catalog snapshots retain callbacks after their source closes.
    final base = BaziShenShaCatalog();
    final added = base.addModule(
      BaziShenShaModule(
        label: 'web-school',
        rules: [
          BaziShenShaRule(
            id: 'always',
            name: '自定义',
            test: (i) => i.pillars.length == 4,
          ),
        ],
      ),
    );
    final custom = added.createContext();
    final disabled = added.createContext(disabledIds: ['web-school:always']);
    final removed = added.removeModule('web-school');
    final clean = removed.createContext();
    base.close();
    added.close();
    removed.close();
    List<BaziShenShaMatch> evaluate(BaziShenShaContext s) => s.evaluate(
      chart: c,
      target: c.dayPillar,
      targetKind: BaziShenShaTargetKind.day,
      gender: BaziGender.male,
    );
    try {
      final matches = evaluate(custom);
      if (!matches.any((m) => m.id == 'web-school:always' && m.name == '自定义')) {
        throw StateError('Custom callback snapshot lost');
      }
      if (evaluate(disabled).any((m) => m.id == 'web-school:always') ||
          evaluate(clean).any((m) => m.id == 'web-school:always')) {
        throw StateError('Disabled/removed callback survived');
      }
      add('custom-shensha', [
        for (final m in matches) ...[
          m.builtinId ?? -1,
          m.id.length,
          ...m.id.codeUnits,
          m.name.length,
          ...m.name.codeUnits,
        ],
      ]);
    } finally {
      custom.close();
      disabled.close();
      clean.close();
    }
    final root = BaziShenShaCatalog();
    final error = StateError('predicate identity');
    final throwing = root.addModule(
      BaziShenShaModule(
        label: 'throws',
        rules: [BaziShenShaRule(id: 'x', name: 'x', test: (_) => throw error)],
      ),
    );
    final failing = throwing.createContext();
    try {
      var caught = false;
      try {
        evaluate(failing);
      } catch (e) {
        caught = identical(e, error);
      }
      if (!caught) throw StateError('Callback exception identity lost');
    } finally {
      failing.close();
      throwing.close();
    }
    late BaziShenShaContext guard;
    var reentry = false, closing = false;
    final guarded = root.addModule(
      BaziShenShaModule(
        label: 'guarded',
        rules: [
          BaziShenShaRule(
            id: 'x',
            name: 'x',
            test: (_) {
              try {
                evaluate(guard);
              } on StateError {
                reentry = true;
              }
              try {
                guard.close();
              } on StateError {
                closing = true;
              }
              return true;
            },
          ),
        ],
      ),
    );
    guard = guarded.createContext();
    try {
      evaluate(guard);
      if (!reentry || !closing) {
        throw StateError('Callback reentry/close not guarded');
      }
      add('callback-errors', [1, 1, 1]);
    } finally {
      guard.close();
      guarded.close();
      root.close();
    }
    ctx.close(); // pure chart operations may outlive the astronomy context.
    add('after-owner-close', chart(bazi.calcChart(result.value.pillars)));
  } finally {
    bazi.close();
    ctx.close();
  }
  return rows;
}
