part of '../taiyin.dart';

typedef _SingleStarPositionCalculation =
    int Function(
      Pointer<Char> starKey,
      int mask,
      Pointer<Double> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostic,
    );
typedef _BatchStarPositionCalculation =
    int Function(
      Pointer<Pointer<Char>> starKeys,
      int starCount,
      int mask,
      Pointer<Double> output,
      Pointer<taiyin_ephemeris_diagnostic> diagnostics,
    );
typedef _StarStatusChecker =
    void Function(
      int status,
      TaiyinEphemerisDiagnostic? diagnostic,
      List<TaiyinEphemerisDiagnostic> diagnostics,
    );

/// Process-wide fixed-star catalog management.
///
/// Catalog mutation is a setup-time operation. Finish adding or clearing
/// catalogs before calculations begin in any isolate.
final class TaiyinStarCatalog {
  TaiyinStarCatalog._(this._bindings);

  final TaiyinBindings _bindings;

  /// Adds a compiled TSC1 catalog from [path].
  void addTsc1(String path) {
    _requireStarPath(path, 'path');
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_star_catalog_add_tsc1(nativePath),
      );
    });
  }

  /// Adds a compiled TSC1 catalog from memory.
  ///
  /// The native runtime copies the bytes before this method returns.
  void addTsc1Bytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'must not be empty');
    }
    using((arena) {
      final nativeBytes = arena<Uint8>(bytes.length);
      nativeBytes.asTypedList(bytes.length).setAll(0, bytes);
      _checkStatus(
        _bindings,
        _bindings.taiyin_star_catalog_add_tsc1_memory(
          nativeBytes,
          bytes.length,
        ),
      );
    });
  }

  /// Adds an editable TSF1 catalog from [path].
  void addTsf1(String path) {
    _requireStarPath(path, 'path');
    using((arena) {
      final nativePath = path.toNativeUtf8(allocator: arena).cast<Char>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_star_catalog_add_tsf1(nativePath),
      );
    });
  }

  /// Removes all process-wide fixed-star catalogs.
  void clear() {
    _bindings.taiyin_star_catalog_clear();
  }

  /// Number of loaded TSC1 and TSF1 catalogs.
  int get count => _bindings.taiyin_star_catalog_count();

  /// Looks up a star's visual magnitude using its ID, name, or alias.
  ///
  /// Throws [TaiyinException] when no loaded catalog contains a finite
  /// magnitude for [starKey].
  double magnitudeOf(String starKey) {
    _requireStarKey(starKey);
    return using((arena) {
      final nativeKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      final output = arena<Double>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_star_find_magnitude(nativeKey, output),
      );
      return output.value;
    });
  }
}

/// Fixed-star calculations owned by one [TaiyinContext].
///
/// Star keys may be canonical IDs, names, or aliases from any loaded global
/// star catalog. Position batches preserve successful entries and their native
/// diagnostics when another star fails. Observed batches throw if any entry
/// fails because the native C ABI does not return partial observed values.
final class TaiyinStarApi {
  TaiyinStarApi._(
    this._bindings,
    this._context,
    this._ensureOpen,
    this._checkStatus,
    this._observedMapper,
  );

  final TaiyinBindings _bindings;
  final Pointer<taiyin_context> _context;
  final void Function() _ensureOpen;
  final _StarStatusChecker _checkStatus;
  final TaiyinObservedApi _observedMapper;

  /// Calculates one star with explicit TDB and TT coordinates.
  TaiyinEphemerisResult<TaiyinStarPosition> atTdb(
    String starKey,
    JulianDate<TdbScale> tdb,
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _position(
      starKey,
      flags,
      (key, mask, output, diagnostic) =>
          _bindings.taiyin_calc_star_position_tdb(
            _context,
            key,
            tdb.toDouble(),
            tt.toDouble(),
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates one star at a TT Julian date.
  TaiyinEphemerisResult<TaiyinStarPosition> atTt(
    String starKey,
    JulianDate<TtScale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _position(
      starKey,
      flags,
      (key, mask, output, diagnostic) => _bindings.taiyin_calc_star_position_tt(
        _context,
        key,
        julianDate.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one star at a UT1 Julian date using Taiyin's time policy.
  TaiyinEphemerisResult<TaiyinStarPosition> atUt1(
    String starKey,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _position(
      starKey,
      flags,
      (key, mask, output, diagnostic) => _bindings.taiyin_calc_star_position_ut(
        _context,
        key,
        julianDate.toDouble(),
        mask,
        output,
        diagnostic,
      ),
    );
  }

  /// Calculates one star at UT1 with an explicit TT−UT1 value.
  TaiyinEphemerisResult<TaiyinStarPosition> atUt1WithDeltaT(
    String starKey,
    JulianDate<Ut1Scale> julianDate,
    double deltaTSeconds, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireStarFinite(deltaTSeconds, 'deltaTSeconds');
    return _position(
      starKey,
      flags,
      (key, mask, output, diagnostic) =>
          _bindings.taiyin_calc_star_position_ut_delta_t(
            _context,
            key,
            julianDate.toDouble(),
            deltaTSeconds,
            mask,
            output,
            diagnostic,
          ),
    );
  }

  /// Calculates several stars with explicit TDB and TT coordinates.
  List<TaiyinEphemerisResult<TaiyinStarPosition>> batchAtTdb(
    List<String> starKeys,
    JulianDate<TdbScale> tdb,
    JulianDate<TtScale> tt, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _positions(
      starKeys,
      flags,
      (keys, count, mask, output, diagnostics) =>
          _bindings.taiyin_calc_star_positions_tdb(
            _context,
            keys,
            count,
            tdb.toDouble(),
            tt.toDouble(),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several stars at a TT Julian date.
  List<TaiyinEphemerisResult<TaiyinStarPosition>> batchAtTt(
    List<String> starKeys,
    JulianDate<TtScale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _positions(
      starKeys,
      flags,
      (keys, count, mask, output, diagnostics) =>
          _bindings.taiyin_calc_star_positions_tt(
            _context,
            keys,
            count,
            julianDate.toDouble(),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several stars at a UT1 Julian date.
  List<TaiyinEphemerisResult<TaiyinStarPosition>> batchAtUt1(
    List<String> starKeys,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    return _positions(
      starKeys,
      flags,
      (keys, count, mask, output, diagnostics) =>
          _bindings.taiyin_calc_star_positions_ut(
            _context,
            keys,
            count,
            julianDate.toDouble(),
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates several stars at UT1 with an explicit TT−UT1 value.
  List<TaiyinEphemerisResult<TaiyinStarPosition>> batchAtUt1WithDeltaT(
    List<String> starKeys,
    JulianDate<Ut1Scale> julianDate,
    double deltaTSeconds, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireStarFinite(deltaTSeconds, 'deltaTSeconds');
    return _positions(
      starKeys,
      flags,
      (keys, count, mask, output, diagnostics) =>
          _bindings.taiyin_calc_star_positions_ut_delta_t(
            _context,
            keys,
            count,
            julianDate.toDouble(),
            deltaTSeconds,
            mask,
            output,
            diagnostics,
          ),
    );
  }

  /// Calculates one complete observed star position at UT1.
  TaiyinObservedStarPosition observedAtUt1(
    String starKey,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinObservedFlag> flags = const {},
  }) {
    _ensureOpen();
    _requireStarKey(starKey);
    _observedMapper._validateFlags(flags);
    final frozenFlags = Set<TaiyinObservedFlag>.unmodifiable(flags);
    final mask = frozenFlags.fold(0, (value, flag) => value | flag.mask);
    return using((arena) {
      final nativeKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      final output = arena<taiyin_observed_position>();
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings
        ..taiyin_observed_position_init(output)
        ..taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = _bindings.taiyin_calc_observed_star_ut(
        _context,
        nativeKey,
        julianDate.toDouble(),
        mask,
        output,
        diagnostic,
      );
      final mappedDiagnostic = _observedMapper._readObservedDiagnostic(
        diagnostic.ref,
      );
      _checkStatus(status, mappedDiagnostic, const []);
      return _readObservedStarPosition(output.ref, starKey, frozenFlags);
    });
  }

  /// Calculates complete observed star positions at UT1.
  List<TaiyinObservedStarPosition> observedBatchAtUt1(
    List<String> starKeys,
    JulianDate<Ut1Scale> julianDate, {
    Set<TaiyinObservedFlag> flags = const {},
  }) {
    _ensureOpen();
    if (starKeys.isEmpty) return const [];
    _validateStarKeys(starKeys);
    _observedMapper._validateFlags(flags);
    final frozenFlags = Set<TaiyinObservedFlag>.unmodifiable(flags);
    final mask = frozenFlags.fold(0, (value, flag) => value | flag.mask);

    return using((arena) {
      final nativeKeys = _writeStarKeys(arena, starKeys);
      final output = arena<taiyin_observed_position>(starKeys.length);
      final diagnostics = arena<taiyin_ephemeris_diagnostic>(starKeys.length);
      for (var index = 0; index < starKeys.length; index++) {
        _bindings
          ..taiyin_observed_position_init(output + index)
          ..taiyin_ephemeris_diagnostic_init(diagnostics + index);
      }
      final status = _bindings.taiyin_calc_observed_stars_ut(
        _context,
        nativeKeys,
        starKeys.length,
        julianDate.toDouble(),
        mask,
        output,
        diagnostics,
      );
      if (status != 0) {
        final mapped = [
          for (var index = 0; index < starKeys.length; index++)
            _observedMapper._readObservedDiagnostic(diagnostics[index]),
        ];
        final failures = [
          for (final diagnostic in mapped)
            if (diagnostic.status != 0) diagnostic,
        ];
        _checkStatus(status, failures.firstOrNull ?? mapped.first, mapped);
      }
      final results = List<TaiyinObservedStarPosition>.unmodifiable([
        for (var index = 0; index < starKeys.length; index++)
          _readObservedStarPosition(
            output[index],
            starKeys[index],
            frozenFlags,
          ),
      ]);
      final inconsistent = [
        for (final result in results)
          if (result.status != 0 || result.apparent.status != 0) result,
      ];
      if (inconsistent.isNotEmpty) {
        final first = inconsistent.first;
        final status = first.status != 0 ? first.status : first.apparent.status;
        final diagnostics = [
          for (final result in inconsistent) result.diagnostic,
        ];
        _checkStatus(status, first.diagnostic, diagnostics);
      }
      return results;
    });
  }

  TaiyinEphemerisResult<TaiyinStarPosition> _position(
    String starKey,
    Set<TaiyinPositionFlag> flags,
    _SingleStarPositionCalculation calculate,
  ) {
    _requireStarKey(starKey);
    final frozenFlags = Set<TaiyinPositionFlag>.unmodifiable(flags);
    final mask = frozenFlags.fold(0, (value, flag) => value | flag.mask);
    return using((arena) {
      final nativeKey = starKey.toNativeUtf8(allocator: arena).cast<Char>();
      final output = arena<Double>(6);
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      _bindings.taiyin_ephemeris_diagnostic_init(diagnostic);
      final status = calculate(nativeKey, mask, output, diagnostic);
      final mappedDiagnostic = _observedMapper._readObservedDiagnostic(
        diagnostic.ref,
      );
      _checkStatus(status, mappedDiagnostic, const []);
      return TaiyinEphemerisResult(
        value: TaiyinStarPosition(
          starKey: starKey,
          values: [for (var index = 0; index < 6; index++) output[index]],
          flags: frozenFlags,
        ),
        diagnostic: mappedDiagnostic,
      );
    });
  }

  List<TaiyinEphemerisResult<TaiyinStarPosition>> _positions(
    List<String> starKeys,
    Set<TaiyinPositionFlag> flags,
    _BatchStarPositionCalculation calculate,
  ) {
    if (starKeys.isEmpty) return const [];
    _validateStarKeys(starKeys);
    final frozenFlags = Set<TaiyinPositionFlag>.unmodifiable(flags);
    final mask = frozenFlags.fold(0, (value, flag) => value | flag.mask);
    return using((arena) {
      final nativeKeys = _writeStarKeys(arena, starKeys);
      final output = arena<Double>(starKeys.length * 6);
      final diagnostics = arena<taiyin_ephemeris_diagnostic>(starKeys.length);
      for (var index = 0; index < starKeys.length; index++) {
        _bindings.taiyin_ephemeris_diagnostic_init(diagnostics + index);
      }
      final status = calculate(
        nativeKeys,
        starKeys.length,
        mask,
        output,
        diagnostics,
      );
      final entries = [
        for (var starIndex = 0; starIndex < starKeys.length; starIndex++)
          (
            diagnostic: _observedMapper._readObservedDiagnostic(
              diagnostics[starIndex],
            ),
            starIndex: starIndex,
          ),
      ];
      if (status != 0 &&
          !entries.any((entry) => entry.diagnostic.status == status)) {
        _checkStatus(status, null, const []);
      }
      return List.unmodifiable([
        for (final entry in entries)
          TaiyinEphemerisResult(
            value: TaiyinStarPosition(
              starKey: starKeys[entry.starIndex],
              values: entry.diagnostic.status == 0
                  ? [
                      for (var valueIndex = 0; valueIndex < 6; valueIndex++)
                        output[entry.starIndex * 6 + valueIndex],
                    ]
                  : List.filled(6, double.nan),
              flags: frozenFlags,
            ),
            diagnostic: entry.diagnostic,
          ),
      ]);
    });
  }

  Pointer<Pointer<Char>> _writeStarKeys(
    Allocator allocator,
    List<String> starKeys,
  ) {
    final nativeKeys = allocator<Pointer<Char>>(starKeys.length);
    for (var index = 0; index < starKeys.length; index++) {
      nativeKeys[index] = starKeys[index]
          .toNativeUtf8(allocator: allocator)
          .cast<Char>();
    }
    return nativeKeys;
  }

  TaiyinObservedStarPosition _readObservedStarPosition(
    taiyin_observed_position value,
    String starKey,
    Set<TaiyinObservedFlag> flags,
  ) {
    final wantsHorizontal =
        flags.contains(TaiyinObservedFlag.horizontal) ||
        flags.contains(TaiyinObservedFlag.refraction);
    final wantsSpeed = flags.contains(TaiyinObservedFlag.speed);
    final wantsRefraction = flags.contains(TaiyinObservedFlag.refraction);
    return TaiyinObservedStarPosition(
      starKey: starKey,
      status: value.status,
      diagnostic: _observedMapper._readObservedDiagnostic(value.diagnostic),
      apparent: TaiyinApparentStarPosition(
        starKey: starKey,
        status: value.apparent.status,
        diagnostic: _observedMapper._readObservedDiagnostic(
          value.apparent.diagnostic,
        ),
        geometricState: _observedMapper._readObservedState(
          value.apparent.geometric_state,
        ),
        apparentState: _observedMapper._readObservedState(
          value.apparent.apparent_state,
        ),
        longitudeRadians: value.apparent.longitude_rad,
        latitudeRadians: value.apparent.latitude_rad,
        distanceAu: value.apparent.distance_au,
        lightTimeDays: value.apparent.light_time_days,
        cacheHit: value.apparent.cache_hit != 0,
      ),
      flags: flags,
      horizontal: wantsHorizontal
          ? _observedMapper._readHorizontal(value.horizontal)
          : null,
      horizontalRates: wantsHorizontal && wantsSpeed
          ? _observedMapper._readHorizontalRates(value.horizontal_rates)
          : null,
      refractedHorizontal: wantsRefraction
          ? _observedMapper._readHorizontal(value.refracted_horizontal)
          : null,
      refractedHorizontalRates: wantsRefraction && wantsSpeed
          ? _observedMapper._readHorizontalRates(
              value.refracted_horizontal_rates,
            )
          : null,
    );
  }
}

void _validateStarKeys(List<String> starKeys) {
  for (final starKey in starKeys) {
    _requireStarKey(starKey);
  }
}

void _requireStarKey(String starKey) {
  if (starKey.isEmpty) {
    throw ArgumentError.value(starKey, 'starKey', 'must not be empty');
  }
  if (starKey.contains('\u0000')) {
    throw ArgumentError.value(
      starKey,
      'starKey',
      'must not contain a NUL character',
    );
  }
}

void _requireStarPath(String path, String name) {
  if (path.isEmpty) {
    throw ArgumentError.value(path, name, 'must not be empty');
  }
  if (path.contains('\u0000')) {
    throw ArgumentError.value(path, name, 'must not contain a NUL character');
  }
}

void _requireStarFinite(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'must be finite');
  }
}
