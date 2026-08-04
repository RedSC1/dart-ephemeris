/// BaZi (八字) astrology models backed by the Taiyin BaZi extension.
library;

import '../ganzhi/ganzhi_models.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// How the 安命宫 (life-palace) / 安身宫 (body-palace) earth position is derived.
enum TaiyinBaziEarthPalaceMode {
  /// 火土 (fire-earth) palace rules.
  fireEarth(0),

  /// 水土 (water-earth) palace rules.
  waterEarth(1);

  const TaiyinBaziEarthPalaceMode(this.id);

  final int id;

  static TaiyinBaziEarthPalaceMode fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi earth palace mode');
  }
}

/// The birth gender used by the 大运 (da-yun) direction rules.
enum TaiyinBaziGender {
  female(0),
  male(1);

  const TaiyinBaziGender(this.id);

  final int id;

  static TaiyinBaziGender fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi gender');
  }
}

/// How the 起运 (qi-yun) direction is selected.
enum TaiyinBaziQiyunDirectionMode {
  /// Derived from the year-pillar stem yin/yang and the birth gender.
  yearStemGender(0);

  const TaiyinBaziQiyunDirectionMode(this.id);

  final int id;

  static TaiyinBaziQiyunDirectionMode fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi qi-yun direction mode');
  }
}

/// Which year length is used when converting the 起运 (qi-yun) day offset into
/// a year/month/day offset.
enum TaiyinBaziQiyunTimeModel {
  /// Traditional calendar years (standard 起运 conversion).
  traditionalCalendar(0),

  /// Julian years of 365.25 days.
  julianYear(1),

  /// Tropical years of 365.2422 days.
  tropicalYear(2);

  const TaiyinBaziQiyunTimeModel(this.id);

  final int id;

  static TaiyinBaziQiyunTimeModel fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi qi-yun time model');
  }
}

/// Which calendar is used when naming the 大运 (da-yun) boundary years.
enum TaiyinBaziDayunBoundaryModel {
  /// Civil (proleptic Gregorian/Julian) year boundaries.
  civilYears(0),

  /// Julian-year boundaries.
  julianYears(1),

  /// Tropical-year boundaries.
  tropicalYears(2);

  const TaiyinBaziDayunBoundaryModel(this.id);

  final int id;

  static TaiyinBaziDayunBoundaryModel fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi da-yun boundary model');
  }
}

/// Which 人元司令 (ren-yuan si-ling) command-day table is used.
enum TaiyinBaziRenyuanSilingTableModel {
  /// 三命通会 table.
  sanMingTongHui(0),

  /// The common (standard) table.
  common(1);

  const TaiyinBaziRenyuanSilingTableModel(this.id);

  final int id;

  static TaiyinBaziRenyuanSilingTableModel fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi renyuan siling table');
  }
}

/// How 人元司令 (ren-yuan si-ling) instants are measured.
enum TaiyinBaziRenyuanSilingTimeModel {
  /// Elapsed full 24-hour days from the governing 节.
  elapsed24Hours(0),

  /// Local civil days from the governing 节.
  localCivilDays(1);

  const TaiyinBaziRenyuanSilingTimeModel(this.id);

  final int id;

  static TaiyinBaziRenyuanSilingTimeModel fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(
      id,
      'id',
      'unknown BaZi renyuan siling time model',
    );
  }
}

/// The origin of a 人元司令 (ren-yuan si-ling) command segment.
enum TaiyinBaziRenyuanSilingOriginKind {
  /// The segment is governed by a heavenly stem.
  stem(0),

  /// 艮土 (gen earth).
  genEarth(1),

  /// 坤土 (kun earth).
  kunEarth(2);

  const TaiyinBaziRenyuanSilingOriginKind(this.id);

  final int id;

  static TaiyinBaziRenyuanSilingOriginKind fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi renyuan siling origin');
  }
}

/// The five elements (五行).
enum TaiyinBaziWuxing {
  water(0),
  wood(1),
  metal(2),
  earth(3),
  fire(4);

  const TaiyinBaziWuxing(this.id);

  final int id;

  static TaiyinBaziWuxing fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi five element');
  }
}

/// The ten gods (十神).
enum TaiyinBaziTenGod {
  /// 比肩 (peer).
  biJian(0),

  /// 劫财 (rob wealth).
  jieCai(1),

  /// 食神 (eating god).
  shiShen(2),

  /// 伤官 (hurting officer).
  shangGuan(3),

  /// 偏财 (indirect wealth).
  pianCai(4),

  /// 正财 (direct wealth).
  zhengCai(5),

  /// 七杀 (seven killings).
  qiSha(6),

  /// 正官 (direct officer).
  zhengGuan(7),

  /// 偏印 (indirect seal).
  pianYin(8),

  /// 正印 (direct seal).
  zhengYin(9);

  const TaiyinBaziTenGod(this.id);

  final int id;

  static TaiyinBaziTenGod fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi ten god');
  }
}

/// The pillar or palace a 神煞 (shen-sha) target refers to.
enum TaiyinBaziShenShaTargetKind {
  year(0),
  month(1),
  day(2),
  hour(3),
  mingGong(4),
  shenGong(5),
  taiYuan(6),
  taiXi(7),
  daYun(8),
  flowYear(9),
  flowMonth(10),
  flowDay(11),
  flowHour(12);

  const TaiyinBaziShenShaTargetKind(this.id);

  final int id;

  static TaiyinBaziShenShaTargetKind fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi shen-sha target kind');
  }
}

/// The interaction kind carried by a chart relation.
enum TaiyinBaziRelationKind {
  stemCombination(0),
  stemClash(1),
  stemRestraint(2),
  branchCombination(3),
  branchClash(4),
  branchHarm(5),
  branchDestruction(6),
  branchTriplePunishment(7),
  branchPunishment(8),
  branchSelfPunishment(9),
  branchTripleCombination(10),
  branchTripleDirection(11),
  branchHalfCombination(12),
  branchArchingCombination(13),
  branchHiddenCombination(14),
  branchSeverance(15);

  const TaiyinBaziRelationKind(this.id);

  final int id;

  static TaiyinBaziRelationKind fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi relation kind');
  }
}

/// Bitmask identifying which pillars/palaces a relation connects.
enum TaiyinBaziRelationPillarFlags {
  year(1 << 0),
  month(1 << 1),
  day(1 << 2),
  hour(1 << 3),
  mingGong(1 << 4),
  shenGong(1 << 5),
  taiYuan(1 << 6),
  taiXi(1 << 7),

  /// Composite mask covering the four primary pillars (year–hour).
  primary(0x0f),

  /// Composite mask covering the four extra palaces (命宫–胎息).
  extra(0xf0),

  /// Composite mask covering every pillar and palace.
  all(0xff);

  const TaiyinBaziRelationPillarFlags(this.mask);

  final int mask;

  /// The eight single-pillar flags in id order, excluding the composite masks.
  static const List<TaiyinBaziRelationPillarFlags> pillars = [
    year,
    month,
    day,
    hour,
    mingGong,
    shenGong,
    taiYuan,
    taiXi,
  ];

  /// Folds a native pillar bitmask into the set of single-pillar flags it sets.
  static Set<TaiyinBaziRelationPillarFlags> fold(int value) {
    return {
      for (final flag in pillars)
        if ((value & flag.mask) != 0) flag,
    };
  }
}

/// A stable 神煞 (shen-sha) id (0–65).
///
/// The numeric ids match the C ABI bitset positions; values are deliberately
/// not sorted by name because each id is fixed by the native bitset.
enum TaiyinBaziShenShaId {
  tianYiGuiRen(0),
  yiMa(1),
  xianChiTaoHua(2),
  hongLuan(3),
  tianXi(4),
  yangRen(5),
  feiRen(6),
  fuXingGuiRen(7),
  zaiSha(8),
  jieSha(9),
  wangShen(10),
  kongWang(11),
  tianChuGuiRenXun(12),
  tianChuGuiRen(13),
  deXiuGuiRen(14),
  tianYiMedicine(15),
  xueRen(16),
  yueDeHe(17),
  gouSha(18),
  jiaoSha(19),
  yuanChen(20),
  guChen(21),
  guaSu(22),
  hongYanSha(23),
  jinYu(24),
  jinShen(25),
  tianSheDay(26),
  liuXia(27),
  sangMen(28),
  diaoKe(29),
  piMa(30),
  tongZi(31),
  tianDeHe(32),
  sanQiTian(33),
  sanQiDi(34),
  sanQiRen(35),
  jiangXing(36),
  huaGai(37),
  kuiGang(38),
  shiLingDay(39),
  baZhuanDay(40),
  liuXiuDay(41),
  jiuChouDay(42),
  siFeiDay(43),
  shiEDaBai(44),
  tianLuoDiWang(45),
  yinChaYangCuo(46),
  guLuanSha(47),
  gongLu(48),
  gongGui(49),
  diZhuan(50),
  tianZhuan(51),
  taiJiGuiRen(52),
  wenChangGuiRen(53),
  guoYinGuiRen(54),
  tianDeGuiRen(55),
  yueDeGuiRen(56),
  luShen(57),
  riGanXueTang(58),
  riGanCiGuan(59),
  zhengXueTang(60),
  zhengCiGuan(61),
  guanGuiXueTang(62),
  guanGuiCiGuan(63),
  guanXingXueTang(64),
  xueTangHuiGui(65);

  const TaiyinBaziShenShaId(this.id);

  final int id;

  /// The C ABI bitset index of this shen-sha.
  int get bitIndex => id;

  static TaiyinBaziShenShaId fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown BaZi shen-sha id');
  }
}

/// 天干 relation flags (干合/干冲/干克).
enum TaiyinBaziStemRelationFlags {
  combination(1 << 0),
  clash(1 << 1),
  restraint(1 << 2);

  const TaiyinBaziStemRelationFlags(this.mask);

  final int mask;

  static Set<TaiyinBaziStemRelationFlags> fold(int value) {
    return {
      for (final flag in values)
        if ((value & flag.mask) != 0) flag,
    };
  }
}

/// 地支 relation flags (六合/六冲/六害/破/刑/自刑/暗合/绝).
enum TaiyinBaziBranchRelationFlags {
  combination(1 << 0),
  clash(1 << 1),
  harm(1 << 2),
  destruction(1 << 3),
  punishment(1 << 4),
  selfPunishment(1 << 5),
  hiddenCombination(1 << 6),
  severance(1 << 7);

  const TaiyinBaziBranchRelationFlags(this.mask);

  final int mask;

  static Set<TaiyinBaziBranchRelationFlags> fold(int value) {
    return {
      for (final flag in values)
        if ((value & flag.mask) != 0) flag,
    };
  }
}

/// 地支 triple relation flags (三合/三会/三刑).
enum TaiyinBaziBranchTripleRelationFlags {
  combination(1 << 0),
  direction(1 << 1),
  punishment(1 << 2);

  const TaiyinBaziBranchTripleRelationFlags(this.mask);

  final int mask;

  static Set<TaiyinBaziBranchTripleRelationFlags> fold(int value) {
    return {
      for (final flag in values)
        if ((value & flag.mask) != 0) flag,
    };
  }
}

/// Configuration for a BaZi context.
final class TaiyinBaziContextConfig {
  const TaiyinBaziContextConfig({
    this.earthPalaceMode = TaiyinBaziEarthPalaceMode.fireEarth,
    this.qiyunDirectionMode = TaiyinBaziQiyunDirectionMode.yearStemGender,
    this.qiyunTimeModel = TaiyinBaziQiyunTimeModel.traditionalCalendar,
    this.dayunBoundaryModel = TaiyinBaziDayunBoundaryModel.civilYears,
  });

  final TaiyinBaziEarthPalaceMode earthPalaceMode;
  final TaiyinBaziQiyunDirectionMode qiyunDirectionMode;
  final TaiyinBaziQiyunTimeModel qiyunTimeModel;
  final TaiyinBaziDayunBoundaryModel dayunBoundaryModel;
}

/// A decoded BaZi chart (四柱 + 命宫/身宫/胎元/胎息).
final class TaiyinBaziChart {
  const TaiyinBaziChart({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.mingGong,
    required this.shenGong,
    required this.taiYuan,
    required this.taiXi,
    required this.hiddenStemCount,
    required this.hiddenStems,
    required this.visibleTenGods,
    required this.hiddenTenGods,
    required this.lifeStages,
    required this.nayinIds,
  });

  final TaiyinGanzhi yearPillar;
  final TaiyinGanzhi monthPillar;
  final TaiyinGanzhi dayPillar;
  final TaiyinGanzhi hourPillar;
  final TaiyinGanzhi mingGong;
  final TaiyinGanzhi shenGong;
  final TaiyinGanzhi taiYuan;
  final TaiyinGanzhi taiXi;

  /// Number of hidden stems per pillar (year, month, day, hour).
  final List<int> hiddenStemCount;

  /// Hidden-stem ids per pillar, each a list of up to three stem ids.
  final List<List<int>> hiddenStems;

  /// Ten-god ids of the visible pillars (year, month, day, hour).
  final List<int> visibleTenGods;

  /// Ten-god ids of the hidden stems per pillar.
  final List<List<int>> hiddenTenGods;

  /// 长生十二宫 life-stage ids per pillar.
  final List<int> lifeStages;

  /// NaYin ids per pillar.
  final List<int> nayinIds;
}

/// A single relation between two pillars of a chart.
final class TaiyinBaziRelation {
  const TaiyinBaziRelation({
    required this.kind,
    required this.pillarMask,
    this.combinedElementId,
  });

  final TaiyinBaziRelationKind kind;

  /// The pillars/palaces connected by this relation.
  final Set<TaiyinBaziRelationPillarFlags> pillarMask;

  /// The combined element when the relation is a combination, otherwise null.
  final TaiyinBaziWuxing? combinedElementId;
}

/// A 天干 relation result (合/冲/克).
final class TaiyinBaziStemRelationResult {
  const TaiyinBaziStemRelationResult({
    required this.flags,
    this.combinedElementId,
  });

  final Set<TaiyinBaziStemRelationFlags> flags;

  /// The combined element when the relation is a 干合, otherwise null.
  final TaiyinBaziWuxing? combinedElementId;
}

/// A 地支 relation result (六合/六冲/六害/破/刑/自刑/暗合/绝).
final class TaiyinBaziBranchRelationResult {
  const TaiyinBaziBranchRelationResult({
    required this.flags,
    this.combinedElementId,
  });

  final Set<TaiyinBaziBranchRelationFlags> flags;

  /// The combined element when the relation is a 六合, otherwise null.
  final TaiyinBaziWuxing? combinedElementId;
}

/// A 地支 triple relation result (三合/三会/三刑).
final class TaiyinBaziBranchTripleRelationResult {
  const TaiyinBaziBranchTripleRelationResult({
    required this.flags,
    this.combinedElementId,
  });

  final Set<TaiyinBaziBranchTripleRelationFlags> flags;

  /// The combined element when the relation is a 三合, otherwise null.
  final TaiyinBaziWuxing? combinedElementId;
}

/// The 起运 (qi-yun) result: the start of the first 大运.
final class TaiyinBaziQiyunResult {
  const TaiyinBaziQiyunResult({
    required this.direction,
    required this.timeModel,
    required this.referenceJieIndex,
    required this.jieIntervalDays,
    required this.startAgeYears,
    required this.offsetYears,
    required this.offsetMonths,
    required this.offsetDays,
    required this.offsetHours,
    required this.offsetMinutes,
    required this.offsetSeconds,
    required this.referenceJieJdUt,
    required this.startJdUt,
    required this.startCivilTime,
  });

  /// The qi-yun direction: +1 for forward, -1 for reverse.
  final int direction;

  final TaiyinBaziQiyunTimeModel timeModel;

  /// Index (from 立春) of the governing 节 used as the reference.
  final int referenceJieIndex;

  /// Days between the birth instant and the governing 节.
  final double jieIntervalDays;

  /// The computed start age in years (may be fractional).
  final double startAgeYears;

  final int offsetYears;
  final int offsetMonths;
  final int offsetDays;
  final int offsetHours;
  final int offsetMinutes;
  final double offsetSeconds;

  final JulianDate<Ut1Scale> referenceJieJdUt;
  final JulianDate<Ut1Scale> startJdUt;
  final AstroDateTime startCivilTime;
}

/// One 大运 (da-yun) decade.
final class TaiyinBaziDayun {
  const TaiyinBaziDayun({
    required this.index,
    required this.ganzhi,
    required this.startVirtualAge,
    required this.endVirtualAge,
    required this.startJdUt,
    required this.endJdUt,
    required this.startCivilTime,
    required this.endCivilTime,
  });

  final int index;
  final TaiyinGanzhi ganzhi;
  final int startVirtualAge;
  final int endVirtualAge;
  final JulianDate<Ut1Scale> startJdUt;
  final JulianDate<Ut1Scale> endJdUt;
  final AstroDateTime startCivilTime;
  final AstroDateTime endCivilTime;
}

/// One 小运 (xiao-yun) year.
final class TaiyinBaziXiaoyun {
  const TaiyinBaziXiaoyun({required this.age, required this.ganzhi});

  final int age;
  final TaiyinGanzhi ganzhi;
}

/// One 人元司令 (ren-yuan si-ling) command segment.
final class TaiyinBaziRenyuanSilingSegment {
  const TaiyinBaziRenyuanSilingSegment({
    required this.stemId,
    required this.originKind,
    required this.segmentIndex,
    required this.startDay,
    required this.endDay,
  });

  final int stemId;
  final TaiyinBaziRenyuanSilingOriginKind originKind;
  final int segmentIndex;
  final double startDay;
  final double endDay;
}

/// The 人元司令 (ren-yuan si-ling) determination for an instant.
final class TaiyinBaziRenyuanSilingResult {
  const TaiyinBaziRenyuanSilingResult({
    required this.tableModel,
    required this.timeModel,
    required this.monthBranchId,
    required this.stemId,
    required this.originKind,
    required this.segmentIndex,
    required this.previousJieIndex,
    required this.daysSinceJie,
    required this.segmentStartDay,
    required this.segmentEndDay,
    required this.previousJieJdUt,
  });

  final TaiyinBaziRenyuanSilingTableModel tableModel;
  final TaiyinBaziRenyuanSilingTimeModel timeModel;
  final int monthBranchId;
  final int stemId;
  final TaiyinBaziRenyuanSilingOriginKind originKind;
  final int segmentIndex;
  final int previousJieIndex;
  final double daysSinceJie;
  final double segmentStartDay;
  final double segmentEndDay;
  final JulianDate<Ut1Scale> previousJieJdUt;
}
