/// Runtime data-source models for the process-wide Taiyin runtime.
library;

/// The kind of a registered runtime data source.
enum RuntimeDataSourceKind {
  ephemeris(1),
  earthOrientation(2),
  lunarLimb(3);

  const RuntimeDataSourceKind(this.id);

  final int id;

  static RuntimeDataSourceKind fromId(int id) {
    for (final kind in values) {
      if (kind.id == id) return kind;
    }
    throw ArgumentError.value(id, 'id', 'unknown runtime data source kind');
  }
}

/// The storage format of a registered runtime data source.
enum RuntimeDataSourceFormat {
  unknown(0),
  opm2(1),
  spk(2),
  kepler(3),
  semiAnalytic(4),
  fixedStar(5),
  tsc1(6),
  tkc1(7),
  custom(8),
  finals2000a(100),
  builtinEop(101),
  tll1(200),
  memory(1000);

  const RuntimeDataSourceFormat(this.id);

  final int id;

  static RuntimeDataSourceFormat fromId(int id) {
    for (final format in values) {
      if (format.id == id) return format;
    }
    throw ArgumentError.value(id, 'id', 'unknown runtime data source format');
  }
}

/// Attribute bits on a registered runtime data source.
enum RuntimeDataSourceFlag {
  hasCoverage(1 << 0),
  builtin(1 << 1),
  memory(1 << 2);

  const RuntimeDataSourceFlag(this.mask);

  final int mask;
}

/// A data source registered with the process-wide Taiyin runtime.
final class RegisteredDataSource {
  const RegisteredDataSource({
    required this.kind,
    required this.format,
    required this.flags,
    required this.source,
    required this.itemCount,
    required this.jdStart,
    required this.jdEnd,
  });

  final RuntimeDataSourceKind kind;
  final RuntimeDataSourceFormat format;
  final Set<RuntimeDataSourceFlag> flags;

  /// The physical path for file-backed data, or a stable label such as
  /// `builtin:semi-analytic` for built-in data.
  final String source;
  final int itemCount;
  final double jdStart;
  final double jdEnd;
}
