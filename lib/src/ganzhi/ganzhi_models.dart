/// Ganzhi (干支) calendar models backed by the Taiyin Chinese-calendar module.
library;

/// How the 子时 (rat-hour) day boundary is applied when building the four
/// pillars.
enum TaiyinGanzhiRatHourMode {
  /// The day pillar does not split at the rat hour.
  noSplit(0),

  /// A 子时 hour uses the current day's stem.
  todayGan(1),

  /// A 子时 hour uses the next day's stem.
  tomorrowGan(2);

  const TaiyinGanzhiRatHourMode(this.id);

  final int id;
}

/// The five elements (五行) assigned to a stem or branch.
enum TaiyinGanzhiWuxing {
  water(0),
  wood(1),
  metal(2),
  earth(3),
  fire(4);

  const TaiyinGanzhiWuxing(this.id);

  final int id;

  static TaiyinGanzhiWuxing fromId(int id) {
    for (final element in values) {
      if (element.id == id) return element;
    }
    throw ArgumentError.value(id, 'id', 'unknown Ganzhi five element');
  }
}

/// The ten heavenly stems, indexed 0–9.
enum TaiyinHeavenlyStem {
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

  const TaiyinHeavenlyStem(this.id);

  final int id;

  static TaiyinHeavenlyStem fromId(int id) {
    for (final stem in values) {
      if (stem.id == id) return stem;
    }
    throw ArgumentError.value(id, 'id', 'unknown heavenly stem');
  }
}

/// The twelve earthly branches, indexed 0–11.
enum TaiyinEarthlyBranch {
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

  const TaiyinEarthlyBranch(this.id);

  final int id;

  static TaiyinEarthlyBranch fromId(int id) {
    for (final branch in values) {
      if (branch.id == id) return branch;
    }
    throw ArgumentError.value(id, 'id', 'unknown earthly branch');
  }
}

/// One Ganzhi value: a heavenly stem (high nibble) and an earthly branch
/// (low nibble) packed into the C ABI's `uint8_t` representation.
final class TaiyinGanzhi {
  const TaiyinGanzhi({required this.stemId, required this.branchId})
    : assert(stemId >= 0 && stemId <= 9, 'stemId must be in 0..9'),
      assert(branchId >= 0 && branchId <= 11, 'branchId must be in 0..11');

  /// Decodes a raw C ABI value (`0xff` is invalid).
  factory TaiyinGanzhi.fromNative(int raw) {
    if (raw == 0xff || (raw & 0x0f) == 0x0f || ((raw >> 4) & 0x0f) == 0x0f) {
      throw ArgumentError.value(raw, 'raw', 'invalid packed Ganzhi');
    }
    return TaiyinGanzhi(stemId: raw >> 4, branchId: raw & 0x0f);
  }

  final int stemId;
  final int branchId;

  TaiyinHeavenlyStem get stem => TaiyinHeavenlyStem.fromId(stemId);
  TaiyinEarthlyBranch get branch => TaiyinEarthlyBranch.fromId(branchId);

  /// The C ABI byte: high nibble stem, low nibble branch.
  int get raw => (stemId << 4) | branchId;

  @override
  bool operator ==(Object other) =>
      other is TaiyinGanzhi &&
      other.stemId == stemId &&
      other.branchId == branchId;

  @override
  int get hashCode => Object.hash(stemId, branchId);

  @override
  String toString() => 'TaiyinGanzhi(${stem.name}-${branch.name})';
}

/// The four pillars (四柱) of a birth moment.
final class TaiyinGanzhiFourPillars {
  const TaiyinGanzhiFourPillars({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
  });

  final TaiyinGanzhi year;
  final TaiyinGanzhi month;
  final TaiyinGanzhi day;
  final TaiyinGanzhi hour;
}
