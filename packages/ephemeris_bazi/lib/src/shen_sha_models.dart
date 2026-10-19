import 'bazi_models.dart';

/// Immutable input to a synchronous custom Shen Sha predicate.
final class BaziShenShaInput {
  BaziShenShaInput.internal(
    List<int> pillars,
    this.target,
    this.targetKind,
    this.gender,
  ) : pillars = List.unmodifiable(pillars);

  /// Packed Ganzhi bytes in year/month/day/hour order; 255 means unknown.
  final List<int> pillars;
  final int target;
  final BaziShenShaTargetKind targetKind;
  final BaziGender? gender;
}

/// A user-defined rule. The predicate runs synchronously in its own isolate.
final class BaziShenShaRule {
  const BaziShenShaRule({
    required this.id,
    required this.name,
    required this.test,
  });
  final String id;
  final String name;
  final bool Function(BaziShenShaInput) test;
}

/// A named collection of user rules. Full IDs are `label:ruleId`.
final class BaziShenShaModule {
  BaziShenShaModule({
    required this.label,
    required Iterable<BaziShenShaRule> rules,
  }) : rules = List.unmodifiable(rules);
  final String label;
  final List<BaziShenShaRule> rules;
}

/// One match, copied out of native storage.
final class BaziShenShaMatch {
  const BaziShenShaMatch(this.id, this.name, this.builtinId);
  final String id;
  final String name;

  /// Null for custom rules; built-ins use the existing native enum ID.
  final int? builtinId;
}
