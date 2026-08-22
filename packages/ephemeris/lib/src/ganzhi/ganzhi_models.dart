/// Ganzhi (干支) calendar models backed by the Ephemeris Chinese-calendar module.
library;

/// How the 子时 (rat-hour) day boundary is applied when building the four
/// pillars.
enum GanzhiRatHourMode {
  /// The day pillar does not split at the rat hour.
  noSplit(0),

  /// A 子时 hour uses the current day's stem.
  todayGan(1),

  /// A 子时 hour uses the next day's stem.
  tomorrowGan(2);

  const GanzhiRatHourMode(this.id);

  final int id;
}

/// The five elements (五行) assigned to a stem or branch.
enum GanzhiWuxing {
  water(0),
  wood(1),
  metal(2),
  earth(3),
  fire(4);

  const GanzhiWuxing(this.id);

  final int id;

  static GanzhiWuxing fromId(int id) {
    for (final element in values) {
      if (element.id == id) return element;
    }
    throw ArgumentError.value(id, 'id', 'unknown Ganzhi five element');
  }
}

/// The ten heavenly stems, indexed 0–9.
enum HeavenlyStem {
  jia(0),
  yi(1),
  bing(2),
  ding(3),
  wu(4),
  ji(5),
  geng(6),
  xin(7),
  ren(8),
  gui(9);

  const HeavenlyStem(this.id);

  final int id;

  static HeavenlyStem fromId(int id) {
    for (final stem in values) {
      if (stem.id == id) return stem;
    }
    throw ArgumentError.value(id, 'id', 'unknown heavenly stem');
  }
}

/// The twelve earthly branches, indexed 0–11.
enum EarthlyBranch {
  zi(0),
  chou(1),
  yin(2),
  mao(3),
  chen(4),
  si(5),
  wu(6),
  wei(7),
  shen(8),
  you(9),
  xu(10),
  hai(11);

  const EarthlyBranch(this.id);

  final int id;

  static EarthlyBranch fromId(int id) {
    for (final branch in values) {
      if (branch.id == id) return branch;
    }
    throw ArgumentError.value(id, 'id', 'unknown earthly branch');
  }
}

/// One Ganzhi value: a heavenly stem (high nibble) and an earthly branch
/// (low nibble) packed into the C ABI's `uint8_t` representation.
final class Ganzhi {
  /// Creates a Ganzhi from validated stem and branch ids.
  ///
  /// Validates at runtime (not only via `assert`), so invalid ids are rejected
  /// in release builds too.
  factory Ganzhi({required int stemId, required int branchId}) {
    if (stemId < 0 || stemId > 9) {
      throw ArgumentError.value(stemId, 'stemId', 'must be in 0..9');
    }
    if (branchId < 0 || branchId > 11) {
      throw ArgumentError.value(branchId, 'branchId', 'must be in 0..11');
    }
    return Ganzhi._(stemId, branchId);
  }

  const Ganzhi._(this.stemId, this.branchId);

  /// Decodes a raw C ABI value (`0xff` is invalid).
  factory Ganzhi.fromNative(int raw) {
    final stemId = raw >> 4;
    final branchId = raw & 0x0f;
    if (raw == 0xff || stemId > 9 || branchId > 11) {
      throw ArgumentError.value(raw, 'raw', 'invalid packed Ganzhi');
    }
    return Ganzhi(stemId: stemId, branchId: branchId);
  }

  final int stemId;
  final int branchId;

  HeavenlyStem get stem => HeavenlyStem.fromId(stemId);
  EarthlyBranch get branch => EarthlyBranch.fromId(branchId);

  /// The C ABI byte: high nibble stem, low nibble branch.
  int get raw => (stemId << 4) | branchId;

  @override
  bool operator ==(Object other) =>
      other is Ganzhi && other.stemId == stemId && other.branchId == branchId;

  @override
  int get hashCode => Object.hash(stemId, branchId);

  @override
  String toString() => 'Ganzhi(${stem.name}-${branch.name})';
}

/// The four pillars (四柱) of a birth moment.
final class GanzhiFourPillars {
  const GanzhiFourPillars({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
  });

  final Ganzhi year;
  final Ganzhi month;
  final Ganzhi day;
  final Ganzhi hour;
}
