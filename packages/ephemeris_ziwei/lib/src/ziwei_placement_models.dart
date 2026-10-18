import 'ziwei_models.dart';

/// Finite rule inputs, not a solar/lunar birth date. Month is 1..12, day 1..30.
final class ZiweiPlacementInput {
  const ZiweiPlacementInput({
    this.yearStem = 0,
    this.yearBranch = 0,
    this.month = 1,
    this.day = 1,
    this.hourBranch = 0,
  });
  final int yearStem, yearBranch, month, day, hourBranch;
}

/// Null preserves a field. False restores the original bureau, true recomputes.
final class ZiweiPlacementPatch {
  const ZiweiPlacementPatch({
    this.yearStem,
    this.yearBranch,
    this.month,
    this.day,
    this.hourBranch,
    this.updateBureau,
  });
  final int? yearStem, yearBranch, month, day, hourBranch;
  final bool? updateBureau;
}

/// Current finite inputs plus cumulative overrides and role rotation.
final class ZiweiPlacementState {
  const ZiweiPlacementState(this.input, this.overrides, this.lifePalaceShift);
  final ZiweiPlacementInput input;
  final ZiweiPlacementPatch overrides;
  final int lifePalaceShift;
}

/// An unplaced star and a bit mask of missing native RuleInputSource IDs.
final class ZiweiOmittedPlacement {
  const ZiweiOmittedPlacement(this.starId, this.missingInputs);
  final int starId, missingInputs;
}

/// How the original finite-input chart was selected.
enum ZiweiCastingMethod { manual, indexed, number, random }

/// Immutable snapshot of a casting chart (there is deliberately no birth time).
final class ZiweiCastingSummary {
  ZiweiCastingSummary.internal({
    required this.input,
    required this.originalInput,
    required this.overrides,
    required this.index,
    required this.number,
    required this.method,
    required this.gender,
    required this.chartMode,
    required this.bureau,
    required this.originalBureau,
    required this.bodyPalace,
    required this.lifeMaster,
    required this.bodyMaster,
    required this.yearTransformStem,
    required this.transformations,
    required this.updateBureau,
    required this.lifePalaceShift,
    required this.palaceBranches,
    required this.palaceStems,
  });
  final ZiweiPlacementInput input, originalInput;
  final ZiweiPlacementPatch overrides;
  final int? index;
  final String number;
  final ZiweiCastingMethod method;
  final ZiweiGender gender;
  final ZiweiChartMode chartMode;
  final ZiweiBureau bureau, originalBureau;
  final int bodyPalace,
      lifeMaster,
      bodyMaster,
      yearTransformStem,
      lifePalaceShift;
  final bool updateBureau;
  final List<int> palaceBranches, palaceStems, transformations;
}
