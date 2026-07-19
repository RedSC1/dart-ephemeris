const int taiyinSupportedAbiVersion = 1;
const int taiyinSplitTimeCapability = 1 << 14;

/// Symbols added while ABI 1 was still in development and required by this
/// package's runtime and fixed-star APIs.
const Set<String> taiyinRequiredAbi1Symbols = {
  'taiyin_get_library_codename',
  'taiyin_runtime_add_source_path',
  'taiyin_runtime_load_eop_table',
  'taiyin_runtime_load_builtin_eop_table',
  'taiyin_runtime_clear_eop_table',
  'taiyin_runtime_has_eop_table',
  'taiyin_runtime_load_lunar_limb_model',
  'taiyin_runtime_clear_lunar_limb_model',
  'taiyin_runtime_has_lunar_limb_model',
  'taiyin_runtime_clear_ephemeris_cache',
  'taiyin_runtime_cache_entry_count',
  'taiyin_star_catalog_add_tsc1',
  'taiyin_star_catalog_add_tsc1_memory',
  'taiyin_star_catalog_add_tsf1',
  'taiyin_star_catalog_clear',
  'taiyin_star_catalog_count',
  'taiyin_star_find_magnitude',
  'taiyin_calc_star_position_tdb',
  'taiyin_calc_star_position_tt',
  'taiyin_calc_star_position_ut',
  'taiyin_calc_star_position_ut_delta_t',
  'taiyin_calc_star_positions_tdb',
  'taiyin_calc_star_positions_tt',
  'taiyin_calc_star_positions_ut',
  'taiyin_calc_star_positions_ut_delta_t',
  'taiyin_calc_observed_star_ut',
  'taiyin_calc_observed_stars_ut',
};

/// Validates the native metadata available before any optional symbol lookup.
///
/// This stays independent of generated bindings so compatibility behavior can
/// be tested without loading a platform-specific dynamic library.
///
/// The Dart package exposes its split-date time service as a required part of
/// every `TaiyinContext`, so it intentionally rejects otherwise-compatible
/// intermediate ABI-1 builds that predate the capability marker.
void validateTaiyinNativeCompatibility({
  required int abiVersion,
  required int capabilities,
}) {
  if (abiVersion != taiyinSupportedAbiVersion) {
    throw StateError(
      'Unsupported Taiyin C ABI $abiVersion; '
      'this package supports ABI $taiyinSupportedAbiVersion.',
    );
  }
  if ((capabilities & taiyinSplitTimeCapability) == 0) {
    throw StateError(
      'The loaded Taiyin library does not provide the split-time capability '
      'required by this package.',
    );
  }
}

/// Rejects intermediate ABI-1 builds before generated bindings lazily look up
/// a missing symbol.
void validateTaiyinRequiredSymbols({
  required bool Function(String symbol) providesSymbol,
  Set<String> requiredSymbols = taiyinRequiredAbi1Symbols,
}) {
  final missing = [
    for (final symbol in requiredSymbols)
      if (!providesSymbol(symbol)) symbol,
  ];
  if (missing.isNotEmpty) {
    throw StateError(
      'The loaded Taiyin ABI-1 library is missing symbols required by this '
      'package: ${missing.join(', ')}. Rebuild or update the native library.',
    );
  }
}
