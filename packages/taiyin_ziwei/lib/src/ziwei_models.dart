/// Ziwei Doushu (紫微斗数) models backed by the Ephemeris Ziwei extension.
library;

import 'package:taiyin/taiyin.dart';

/// The birth gender used by Ziwei direction and transformation rules.
enum ZiweiGender {
  male(0),
  female(1);

  const ZiweiGender(this.id);

  final int id;

  static ZiweiGender fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown Ziwei gender');
  }
}

/// The 五行局 (five-element bureau) of a chart.
enum ZiweiBureau {
  water2(0),
  wood3(1),
  metal4(2),
  earth5(3),
  fire6(4);

  const ZiweiBureau(this.id);

  final int id;

  static ZiweiBureau fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown Ziwei bureau');
  }
}

/// The twelve palaces in semantic order.
enum ZiweiPalace {
  life(0),
  siblings(1),
  spouse(2),
  children(3),
  wealth(4),
  health(5),
  travel(6),
  friends(7),
  career(8),
  property(9),
  fortune(10),
  parents(11);

  const ZiweiPalace(this.id);

  final int id;

  static ZiweiPalace fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown Ziwei palace');
  }
}

/// The 31 stable natal anchors of a Ziwei chart.
enum ZiweiAnchorSlot {
  solarYearStem(0),
  solarYearBranch(1),
  solarMonthStem(2),
  solarMonthBranch(3),
  solarDayStem(4),
  solarDayBranch(5),
  solarHourStem(6),
  solarHourBranch(7),
  lunarYearStem(8),
  lunarYearBranch(9),
  lunarMonthStem(10),
  lunarMonthBranch(11),
  lunarDayStem(12),
  lunarDayBranch(13),
  lunarHourStem(14),
  lunarHourBranch(15),
  bureau(16),
  ziwei(17),
  tianfu(18),
  palaceLife(19),
  palaceSiblings(20),
  palaceSpouse(21),
  palaceChildren(22),
  palaceWealth(23),
  palaceHealth(24),
  palaceTravel(25),
  palaceFriends(26),
  palaceCareer(27),
  palaceProperty(28),
  palaceFortune(29),
  palaceParents(30);

  const ZiweiAnchorSlot(this.id);

  final int id;

  /// The number of anchors in a chart, matching `TAIYIN_ZIWEI_ANCHOR_COUNT`.
  static const int count = 31;
}

/// Which calendar boundary a year pillar uses.
enum ZiweiPillarBoundary {
  solarTerm(0),
  lunar(1);

  const ZiweiPillarBoundary(this.id);

  final int id;
}

/// The chart plate (天盘/地盘/人盘).
enum ZiweiChartMode {
  tianPan(0),
  diPan(1),
  renPan(2);

  const ZiweiChartMode(this.id);

  final int id;
}

/// How a leap lunar month is attributed.
enum ZiweiLeapMonthStrategy {
  asPrevious(0),
  asNext(1),
  splitAfterFifteenth(2);

  const ZiweiLeapMonthStrategy(this.id);

  final int id;
}

/// A level of the flow (限运) stack.
enum ZiweiFlowLevel {
  decade(0),
  year(1),
  month(2),
  day(3),
  hour(4);

  const ZiweiFlowLevel(this.id);

  final int id;
}

/// How childhood years before the first decade are handled.
enum ZiweiChildhoodStrategy {
  skip(0),
  sequential(1);

  const ZiweiChildhoodStrategy(this.id);

  final int id;
}

/// Which 子 (Zi) segment a logical flow-hour target belongs to.
enum ZiweiRatHourSegment {
  none(0),
  unified(1),
  early(2),
  late(3);

  const ZiweiRatHourSegment(this.id);

  final int id;

  static ZiweiRatHourSegment fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown Ziwei rat-hour segment');
  }
}

/// Star brightness (星曜亮度).
enum ZiweiBrightness {
  none(-1),
  xian(0),
  bu(1),
  ping(2),
  li(3),
  de(4),
  wang(5),
  miao(6);

  const ZiweiBrightness(this.id);

  final int id;

  static ZiweiBrightness fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown Ziwei brightness');
  }
}

/// The category a star belongs to in the rule catalog.
enum ZiweiStarCategory {
  major(0),
  lucky(1),
  minor(2),
  malefic(3),
  cycle(4),
  other(5);

  const ZiweiStarCategory(this.id);

  final int id;

  static ZiweiStarCategory fromId(int id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    throw ArgumentError.value(id, 'id', 'unknown Ziwei star category');
  }
}

/// One transformation (四化) overlay mark attached to a natal star.
enum ZiweiTransformMark {
  birthYearLu(0),
  birthYearQuan(1),
  birthYearKe(2),
  birthYearJi(3),
  centrifugalLu(4),
  centrifugalQuan(5),
  centrifugalKe(6),
  centrifugalJi(7),
  centripetalLu(8),
  centripetalQuan(9),
  centripetalKe(10),
  centripetalJi(11);

  const ZiweiTransformMark(this.id);

  final int id;

  /// The bit this mark sets in a native star-transformation mask.
  int get mask => 1 << id;
}

/// Independent choices for placement, brightness, Si-Hua, and life-stage
/// tables of a rule catalog.
///
/// Unspecified fields select the profile's default, which is `option1` for
/// the bundled catalog. A selection never reparses TOML; it creates an
/// immutable view of an existing [ZiweiDataCatalog] snapshot.
final class ZiweiOptionSelection {
  const ZiweiOptionSelection({
    this.placementDefault = '',
    this.brightnessDefault = '',
    this.sihuaDefault = '',
    this.masters = '',
    this.longevity = '',
    this.placement = const {},
    this.brightness = const {},
    this.sihua = const {},
  });

  /// Component-wide placement default; empty keeps the profile default.
  final String placementDefault;

  /// Component-wide brightness default; empty keeps the profile default.
  final String brightnessDefault;

  /// Component-wide Si-Hua default; empty keeps the profile default.
  final String sihuaDefault;

  /// Master (命主/身主) table choice; empty keeps the profile default.
  final String masters;

  /// Whole-table choice for the twelve life-stage stars (Changsheng through
  /// Yang); empty keeps the profile default.
  final String longevity;

  /// Per-star placement choices keyed by star key.
  final Map<String, String> placement;

  /// Per-star brightness choices keyed by star key.
  final Map<String, String> brightness;

  /// Per-star Si-Hua choices keyed by star key.
  final Map<String, String> sihua;
}

/// Options controlling how a natal chart resolves the birth instant.
final class ZiweiBirthOptions {
  const ZiweiBirthOptions({
    this.ratHourMode = GanzhiRatHourMode.noSplit,
    this.leapMonthStrategy = ZiweiLeapMonthStrategy.splitAfterFifteenth,
    this.chartMode = ZiweiChartMode.tianPan,
    this.wuHuDunYearBoundary = ZiweiPillarBoundary.lunar,
    this.sihuaYearBoundary = ZiweiPillarBoundary.lunar,
    this.bodyMasterYearBoundary = ZiweiPillarBoundary.lunar,
  });

  final GanzhiRatHourMode ratHourMode;
  final ZiweiLeapMonthStrategy leapMonthStrategy;
  final ZiweiChartMode chartMode;
  final ZiweiPillarBoundary wuHuDunYearBoundary;
  final ZiweiPillarBoundary sihuaYearBoundary;
  final ZiweiPillarBoundary bodyMasterYearBoundary;
}

/// Options controlling flow (限运) stack resolution.
final class ZiweiFlowOptions {
  const ZiweiFlowOptions({
    this.boundary = ZiweiPillarBoundary.lunar,
    this.ratHourMode = GanzhiRatHourMode.noSplit,
    this.childhoodStrategy = ZiweiChildhoodStrategy.skip,
  });

  final ZiweiPillarBoundary boundary;
  final GanzhiRatHourMode ratHourMode;
  final ZiweiChildhoodStrategy childhoodStrategy;
}

/// Physical-branch filters for direct birth-time reverse lookup.
///
/// Each supplied value is a branch id from 0 (Zi) through 11 (Hai). At least
/// one field must be supplied. Results are logical birth-time slots, not
/// minute-precise reconstructions.
final class ZiweiTier1ReverseQuery {
  const ZiweiTier1ReverseQuery({
    this.lucunBranch,
    this.hongluanBranch,
    this.zuofuBranch,
    this.youbiBranch,
    this.wenchangBranch,
    this.wenquBranch,
    this.santaiBranch,
    this.bazuoBranch,
    this.ziweiBranch,
  });

  final int? lucunBranch;
  final int? hongluanBranch;
  final int? zuofuBranch;
  final int? youbiBranch;
  final int? wenchangBranch;
  final int? wenquBranch;
  final int? santaiBranch;
  final int? bazuoBranch;
  final int? ziweiBranch;

  List<int?> get _values => [
    lucunBranch,
    hongluanBranch,
    zuofuBranch,
    youbiBranch,
    wenchangBranch,
    wenquBranch,
    santaiBranch,
    bazuoBranch,
    ziweiBranch,
  ];

  void validate() {
    var any = false;
    for (final value in _values) {
      if (value == null) continue;
      any = true;
      if (value < 0 || value > 11) {
        throw ArgumentError.value(
          value,
          'branch',
          'Ziwei Tier-1 branch constraints must be from 0 through 11',
        );
      }
    }
    if (!any) {
      throw ArgumentError(
        'Ziwei Tier-1 reverse lookup requires at least one constraint',
      );
    }
  }
}

/// One logical birth-time slot matching a Tier-1 reverse lookup.
final class ZiweiReverseLookupCandidate {
  const ZiweiReverseLookupCandidate({
    required this.instantUtc,
    required this.virtualTime,
    required this.lunarYear,
    required this.lunarMonth,
    required this.lunarDay,
    required this.lunarIsLeap,
    required this.hourBranch,
    required this.ratHourSegment,
  });

  final JulianDate<UtcScale> instantUtc;
  final AstroDateTime virtualTime;

  final int lunarYear;
  final int lunarMonth;
  final int lunarDay;
  final bool lunarIsLeap;

  /// Hour branch id (0 = Zi … 11 = Hai).
  final int hourBranch;
  final ZiweiRatHourSegment ratHourSegment;
}

/// The canonical center of an adjacent logical flow hour.
final class ZiweiFlowHourTarget {
  const ZiweiFlowHourTarget({
    required this.instantUtc,
    required this.virtualTime,
    required this.ratHourSegment,
  });

  final JulianDate<UtcScale> instantUtc;
  final AstroDateTime virtualTime;
  final ZiweiRatHourSegment ratHourSegment;
}

/// The same wall-clock field one local civil flow day over.
final class ZiweiFlowDayTarget {
  const ZiweiFlowDayTarget({required this.instantUtc, required this.virtualTime});

  final JulianDate<UtcScale> instantUtc;
  final AstroDateTime virtualTime;
}

/// A star registered in a Ziwei rule catalog.
final class ZiweiStar {
  const ZiweiStar({required this.id, required this.key, required this.category});

  final int id;
  final String key;
  final ZiweiStarCategory category;

  @override
  bool operator ==(Object other) =>
      other is ZiweiStar &&
      other.id == id &&
      other.key == key &&
      other.category == category;

  @override
  int get hashCode => Object.hash(id, key, category);

  @override
  String toString() => 'ZiweiStar($id, $key, $category)';
}

/// The four transformation star ids (禄/权/科/忌) of one stem.
final class ZiweiTransformSet {
  const ZiweiTransformSet({
    required this.lu,
    required this.quan,
    required this.ke,
    required this.ji,
  });

  final int lu;
  final int quan;
  final int ke;
  final int ji;
}

/// The natal summary of a chart.
final class ZiweiChartSummary {
  const ZiweiChartSummary({
    required this.gender,
    required this.bureau,
    required this.bodyPalaceBranch,
    required this.lifeMaster,
    required this.bodyMaster,
    required this.transforms,
    required this.palaceStems,
  });

  final ZiweiGender gender;
  final ZiweiBureau bureau;

  /// Physical branch id (0 = Zi … 11 = Hai) of the body palace (身宫).
  final int bodyPalaceBranch;

  /// Star id of the life master (命主).
  final int lifeMaster;

  /// Star id of the body master (身主).
  final int bodyMaster;
  final ZiweiTransformSet transforms;

  /// Palace stem id per physical branch, indexed 0 (Zi) through 11 (Hai).
  final List<int> palaceStems;

  /// Stable numeric bureau id retained for compact serialization.
  int get bureauId => bureau.id;
}

/// The 31 stable natal anchors, addressable by [ZiweiAnchorSlot].
final class ZiweiAnchors {
  ZiweiAnchors(List<int> values)
    : values = List.unmodifiable(values) {
    if (this.values.length != ZiweiAnchorSlot.count) {
      throw ArgumentError.value(
        this.values.length,
        'values',
        'Ziwei anchors must contain exactly ${ZiweiAnchorSlot.count} values',
      );
    }
  }

  final List<int> values;

  int operator [](ZiweiAnchorSlot slot) => values[slot.id];

  ZiweiBureau get bureau => ZiweiBureau.fromId(values[ZiweiAnchorSlot.bureau.id]);
  int get ziwei => values[ZiweiAnchorSlot.ziwei.id];
  int get tianfu => values[ZiweiAnchorSlot.tianfu.id];

  /// The physical branch id a semantic palace occupies.
  int palacePosition(ZiweiPalace palace) =>
      values[ZiweiAnchorSlot.palaceLife.id + palace.id];
}

/// One natal palace with its physical branch, stem, and resident stars.
final class ZiweiPalaceState {
  const ZiweiPalaceState({
    required this.palace,
    required this.branchId,
    required this.stemId,
    required this.stars,
  });

  final ZiweiPalace palace;

  /// Physical branch id (0 = Zi … 11 = Hai).
  final int branchId;
  final int stemId;
  final List<ZiweiStar> stars;
}

/// The decade-limit portion of a flow resolution.
final class ZiweiDecadeLimit {
  const ZiweiDecadeLimit({
    required this.index,
    required this.startAge,
    required this.endAge,
  });

  final int index;
  final int startAge;
  final int endAge;
}

/// The small-limit (小限) portion of a flow resolution.
final class ZiweiSmallLimit {
  const ZiweiSmallLimit({
    required this.virtualAge,
    required this.stemId,
    required this.branchId,
  });

  final int virtualAge;
  final int stemId;
  final int branchId;
}

/// The resolved calendar facts of a flow (限运) target.
final class ZiweiFlowResolution {
  const ZiweiFlowResolution({
    required this.effectiveBirthYear,
    required this.effectiveTargetYear,
    required this.targetMonth,
    required this.targetMonthSequence,
    required this.targetMonthBuildingBranch,
    required this.targetDay,
    required this.targetHourIndex,
    required this.targetRatHourSegment,
    required this.targetMonthIsLeap,
    required this.decade,
    required this.smallLimit,
  });

  final int effectiveBirthYear;
  final int effectiveTargetYear;
  final int targetMonth;

  /// One-based sequence of the target month within its lunar year.
  final int targetMonthSequence;

  /// Earthly-branch id (0 = Zi … 11 = Hai) the target month is built from.
  final int targetMonthBuildingBranch;
  final int targetDay;
  final int targetHourIndex;
  final ZiweiRatHourSegment targetRatHourSegment;
  final bool targetMonthIsLeap;
  final ZiweiDecadeLimit decade;
  final ZiweiSmallLimit smallLimit;
}

/// The summary of one flow (限运) layer of a chart.
final class ZiweiFlowLayerSummary {
  const ZiweiFlowLayerSummary({
    required this.lifePalace,
    required this.coordinateStem,
    required this.coordinateBranch,
    required this.transforms,
  });

  /// Physical branch id (0 = Zi … 11 = Hai) of the layer's life palace.
  final int lifePalace;
  final int coordinateStem;
  final int coordinateBranch;
  final ZiweiTransformSet transforms;
}
