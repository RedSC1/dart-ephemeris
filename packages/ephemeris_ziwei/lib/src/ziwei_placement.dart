part of 'ziwei_api.dart';

void _requirePlacement(ZiweiContext context) {
  // Keep existing natal APIs usable with beta.8 bundles. New APIs require the
  // matching CI-built native module; fail clearly before allocating a handle.
  for (final name in taiyinZiweiPlacementSymbols) {
    if (!context._module.library.providesSymbol(name)) {
      throw UnsupportedError(
        'Manual placement/casting requires the updated Ziwei '
        'native module (Taiyin v1.0.0-beta.9 or later). Missing: $name',
      );
    }
  }
}

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
  ZiweiCastingSummary._(taiyin_ziwei_casting_summary s, this.number)
    : input = _readPlacementInput(s.input),
      originalInput = _readPlacementInput(s.original_input),
      overrides = _readPlacementPatch(s.overrides),
      index = s.index == 0xffffffff ? null : s.index,
      method = ZiweiCastingMethod.values[s.method],
      gender = ZiweiGender.fromId(s.gender),
      chartMode = ZiweiChartMode.values[s.chart_mode],
      bureau = ZiweiBureau.fromId(s.bureau),
      originalBureau = ZiweiBureau.fromId(s.original_bureau),
      bodyPalace = s.body_palace,
      lifeMaster = s.life_master,
      bodyMaster = s.body_master,
      yearTransformStem = s.year_transform_stem,
      transformations = List.unmodifiable([
        s.year_lu,
        s.year_quan,
        s.year_ke,
        s.year_ji,
      ]),
      updateBureau = s.update_bureau != 0,
      lifePalaceShift = s.life_palace_shift,
      palaceBranches = List.unmodifiable([
        for (var i = 0; i < 12; i++) s.palace_branches[i],
      ]),
      palaceStems = List.unmodifiable([
        for (var i = 0; i < 12; i++) s.palace_stems[i],
      ]);
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

void _placementInt(int value, int min, int max, String name) {
  if (value < min || value > max) throw RangeError.range(value, min, max, name);
}

Pointer<taiyin_ziwei_placement_input> _writePlacementInput(
  TaiyinBindings b,
  Arena a,
  ZiweiPlacementInput v,
) {
  _placementInt(v.yearStem, 0, 9, 'yearStem');
  _placementInt(v.yearBranch, 0, 11, 'yearBranch');
  _placementInt(v.month, 1, 12, 'month');
  _placementInt(v.day, 1, 30, 'day');
  _placementInt(v.hourBranch, 0, 11, 'hourBranch');
  final p = a<taiyin_ziwei_placement_input>();
  b.taiyin_ziwei_placement_input_init(p);
  p.ref
    ..year_stem = v.yearStem
    ..year_branch = v.yearBranch
    ..month = v.month
    ..day = v.day
    ..hour_branch = v.hourBranch;
  return p;
}

Pointer<taiyin_ziwei_placement_patch> _writePlacementPatch(
  TaiyinBindings b,
  Arena a,
  ZiweiPlacementPatch v,
) {
  if (v.yearStem != null) _placementInt(v.yearStem!, 0, 9, 'yearStem');
  if (v.yearBranch != null) _placementInt(v.yearBranch!, 0, 11, 'yearBranch');
  if (v.month != null) _placementInt(v.month!, 1, 12, 'month');
  if (v.day != null) _placementInt(v.day!, 1, 30, 'day');
  if (v.hourBranch != null) _placementInt(v.hourBranch!, 0, 11, 'hourBranch');
  final p = a<taiyin_ziwei_placement_patch>();
  b.taiyin_ziwei_placement_patch_init(p);
  p.ref
    ..year_stem = v.yearStem ?? -1
    ..year_branch = v.yearBranch ?? -1
    ..month = v.month ?? -1
    ..day = v.day ?? -1
    ..hour_branch = v.hourBranch ?? -1
    ..update_bureau = v.updateBureau == null ? -1 : (v.updateBureau! ? 1 : 0);
  return p;
}

ZiweiPlacementInput _readPlacementInput(taiyin_ziwei_placement_input v) =>
    ZiweiPlacementInput(
      yearStem: v.year_stem,
      yearBranch: v.year_branch,
      month: v.month,
      day: v.day,
      hourBranch: v.hour_branch,
    );
ZiweiPlacementPatch _readPlacementPatch(taiyin_ziwei_placement_patch v) =>
    ZiweiPlacementPatch(
      yearStem: v.year_stem < 0 ? null : v.year_stem,
      yearBranch: v.year_branch < 0 ? null : v.year_branch,
      month: v.month < 0 ? null : v.month,
      day: v.day < 0 ? null : v.day,
      hourBranch: v.hour_branch < 0 ? null : v.hour_branch,
      updateBureau: v.update_bureau < 0 ? null : v.update_bureau != 0,
    );

ZiweiCastingChart _createCasting(
  ZiweiContext c,
  int method,
  Object? value,
  ZiweiGender gender,
  ZiweiChartMode mode,
  ZiweiBureau? bureau,
) {
  c._ensureOpen();
  _requirePlacement(c);
  final finalizer = c._module.finalizerFor(
    'taiyin_ziwei_casting_chart_destroy',
  );
  return using((a) {
    final b = c._bindings, options = a<taiyin_ziwei_casting_options>();
    b.taiyin_ziwei_casting_options_init(options);
    options.ref
      ..gender = gender.id
      ..chart_mode = mode.id
      ..fixed_bureau = bureau?.id ?? -1;
    final out = a<Pointer<taiyin_ziwei_casting_chart>>();
    int status;
    if (method == 0) {
      status = b.taiyin_ziwei_casting_chart_create(
        c._context,
        _writePlacementInput(b, a, value as ZiweiPlacementInput),
        options,
        out,
      );
    } else if (method == 1) {
      _placementInt(value as int, 0, 259199, 'index');
      status = b.taiyin_ziwei_casting_chart_from_index(
        c._context,
        value,
        options,
        out,
      );
    } else if (method == 2) {
      final number = value as String;
      if (!RegExp(r'^[0-9]+$').hasMatch(number)) {
        throw ArgumentError.value(
          number,
          'number',
          'must be ASCII decimal digits',
        );
      }
      status = b.taiyin_ziwei_casting_chart_from_number(
        c._context,
        number.toNativeUtf8(allocator: a).cast(),
        options,
        out,
      );
    } else {
      status = b.taiyin_ziwei_casting_chart_random(
        c._context,
        options,
        nullptr,
        nullptr,
        out,
      );
    }
    _checkStatus(c._host, status);
    return ZiweiCastingChart._(c, out.value, finalizer);
  });
}

List<ZiweiOmittedPlacement> _readOmitted(
  ZiweiContext c,
  int Function(Pointer<taiyin_ziwei_omitted_placement>, int, Pointer<Size>)
  call,
) => using((a) {
  final count = a<Size>();
  _checkStatus(c._host, call(nullptr, 0, count));
  if (count.value == 0) return const <ZiweiOmittedPlacement>[];
  final out = a<taiyin_ziwei_omitted_placement>(count.value);
  _checkStatus(c._host, call(out, count.value, count));
  return List.unmodifiable([
    for (var i = 0; i < count.value; i++)
      ZiweiOmittedPlacement(out[i].star_id, out[i].missing_inputs),
  ]);
});

/// Owns a separate casting handle: no invented birthday and no real-date flow API.
/// Edits return new handles; reset restores the original draw, never resamples.
final class ZiweiCastingChart implements Finalizable {
  ZiweiCastingChart._(this._context, this._chart, this._finalizer) {
    _finalizer.attach(this, _chart.cast(), detach: this);
  }
  final ZiweiContext _context;
  final Pointer<taiyin_ziwei_casting_chart> _chart;
  final NativeFinalizer _finalizer;
  bool _closed = false;
  TaiyinBindings get _bindings => _context._bindings;
  bool get isClosed => _closed;
  void _ensureOpen() {
    if (_closed) throw StateError('Casting chart is closed');
    _context._ensureOpen();
  }

  /// Release the handle. Idempotent; also safe after the context is closed.
  void close() {
    if (_closed) return;
    _closed = true;
    _finalizer.detach(this);
    _bindings.taiyin_ziwei_casting_chart_destroy(_chart);
  }

  ZiweiCastingSummary get summary {
    _ensureOpen();
    return using((a) {
      final s = a<taiyin_ziwei_casting_summary>();
      _bindings.taiyin_ziwei_casting_summary_init(s);
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_get_summary(_chart, s),
      );
      final n = a<Size>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_get_number(_chart, nullptr, 0, n),
      );
      final text = a<Char>(n.value);
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_get_number(
          _chart,
          text,
          n.value,
          n,
        ),
      );
      return ZiweiCastingSummary._(s.ref, text.cast<Utf8>().toDartString());
    });
  }

  List<ZiweiOmittedPlacement> get omittedPlacements {
    _ensureOpen();
    return _readOmitted(
      _context,
      (out, cap, n) =>
          _bindings.taiyin_ziwei_casting_chart_get_omitted_placements(
            _chart,
            out,
            cap,
            n,
          ),
    );
  }

  ({List<int> positions, List<int> masks}) _stars() {
    _ensureOpen();
    return using((a) {
      final n = a<Size>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_get_stars(
          _chart,
          nullptr,
          nullptr,
          0,
          n,
        ),
      );
      final p = a<Uint8>(n.value), m = a<Uint16>(n.value);
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_get_stars(
          _chart,
          p,
          m,
          n.value,
          n,
        ),
      );
      return (
        positions: [for (var i = 0; i < n.value; i++) p[i]],
        masks: [for (var i = 0; i < n.value; i++) m[i]],
      );
    });
  }

  int? starPosition(int starId) {
    _placementInt(starId, 0, 65535, 'starId');
    final stars = _stars().positions;
    return starId >= stars.length || stars[starId] == 255
        ? null
        : stars[starId];
  }

  int? starPalace(int starId) {
    final branch = starPosition(starId);
    if (branch == null) return null;
    final index = summary.palaceBranches.indexOf(branch);
    return index < 0 ? null : index;
  }

  int transformMask(int starId) {
    _placementInt(starId, 0, 65535, 'starId');
    final masks = _stars().masks;
    return starId < masks.length ? masks[starId] : 0;
  }

  bool hasTransform(int starId, ZiweiTransformMark mark) =>
      (transformMask(starId) & (1 << mark.id)) != 0;
  List<ZiweiStar> palaceStars(int branch) {
    _placementInt(branch, 0, 11, 'branch');
    final positions = _stars().positions;
    return List.unmodifiable([
      for (var i = 0; i < positions.length; i++)
        if (positions[i] == branch) _context.star(i),
    ]);
  }

  ZiweiBrightness brightness(int starId) {
    _ensureOpen();
    _placementInt(starId, 0, 65535, 'starId');
    return using((a) {
      final out = a<Int32>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_get_brightness(
          _context._context,
          _chart,
          starId,
          out,
        ),
      );
      return ZiweiBrightness.fromId(out.value);
    });
  }

  ZiweiCastingChart modify(ZiweiPlacementPatch patch) {
    _ensureOpen();
    return using((a) {
      final out = a<Pointer<taiyin_ziwei_casting_chart>>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_modify(
          _context._context,
          _chart,
          _writePlacementPatch(_bindings, a, patch),
          out,
        ),
      );
      return ZiweiCastingChart._(_context, out.value, _finalizer);
    });
  }

  ZiweiCastingChart shiftLifePalace(int steps) {
    _ensureOpen();
    _placementInt(steps, -2147483648, 2147483647, 'steps');
    return using((a) {
      final out = a<Pointer<taiyin_ziwei_casting_chart>>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_shift_life_palace(
          _chart,
          steps,
          out,
        ),
      );
      return ZiweiCastingChart._(_context, out.value, _finalizer);
    });
  }

  ZiweiCastingChart reset() {
    _ensureOpen();
    return using((a) {
      final out = a<Pointer<taiyin_ziwei_casting_chart>>();
      _checkStatus(
        _context._host,
        _bindings.taiyin_ziwei_casting_chart_reset(_chart, out),
      );
      return ZiweiCastingChart._(_context, out.value, _finalizer);
    });
  }
}
