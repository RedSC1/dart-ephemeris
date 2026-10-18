import 'package:ephemeris/ephemeris.dart';
import 'bazi_models.dart';

abstract interface class BaziBackend {
  bool get isClosed;
  void close();
  ({EarthlyBranch a, EarthlyBranch b}) getKongWang(Ganzhi value);
  BaziTenGod getTenGod({required int dayStemId, required int targetStemId});
  ({List<int> stems, int count}) getHiddenStems(int branchId);
  BaziStemRelationResult calcStemRelation(int stemA, int stemB);
  BaziBranchRelationResult calcBranchRelation(int branchA, int branchB);
  BaziBranchTripleRelationResult calcBranchTripleRelation(
    int branchA,
    int branchB,
    int branchC,
  );
  int getLifeStage({
    required int stemId,
    required int branchId,
    BaziEarthPalaceMode mode = BaziEarthPalaceMode.fireEarth,
  });
  Ganzhi calcLiunian(int effectiveYear);
  Ganzhi calcLiuyue(Ganzhi yearPillar, int monthBranch);
  Ganzhi calcLiuri(AstroDateTime civilDate);
  Ganzhi calcLiushi(Ganzhi dayPillar, int hourIndex);
  Ganzhi calcXiaoyun(BaziChart chart, int direction, int age);
  List<BaziXiaoyun> fillXiaoyun({
    required BaziChart chart,
    required int direction,
    required int startAge,
    required int requestedCount,
  });
  BaziChart calcChart(GanzhiFourPillars pillars);
  OperationResult<BaziQiyunResult> calcQiyun({
    required JulianDate<Ut1Scale> birthJdUt,
    required AstroDateTime birthCivilTime,
    required BaziChart chart,
    required BaziGender gender,
  });
  List<BaziDayun> fillDayun({
    required AstroDateTime birthCivilTime,
    required BaziChart chart,
    required BaziQiyunResult qiyun,
    required int requestedCount,
  });
  OperationResult<BaziRenyuanSilingResult> calcRenyuanSiling({
    required JulianDate<Ut1Scale> instantJdUt,
    required BaziChart chart,
    required BaziRenyuanSilingTableModel tableModel,
    required BaziRenyuanSilingTimeModel timeModel,
  });
  List<BaziRenyuanSilingSegment> getRenyuanSilingSegments(
    int monthBranchId,
    BaziRenyuanSilingTableModel tableModel,
  );
  List<BaziRelation> collectChartRelations({
    required BaziChart chart,
    int pillarMask = 0xff,
    int relationMask = 0xffff,
  });
  Set<BaziShenShaId> collectTargetShenSha({
    required BaziChart chart,
    required Ganzhi target,
    required BaziShenShaTargetKind targetKind,
    BaziGender? gender,
  });
}
