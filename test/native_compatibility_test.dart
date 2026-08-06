import 'package:taiyin/src/native_compatibility.dart';
import 'package:test/test.dart';

void main() {
  group('native compatibility', () {
    test('accepts ABI 6 with split-time and Chinese-calendar support', () {
      expect(
        () => validateTaiyinNativeCompatibility(
          abiVersion: taiyinSupportedAbiVersion,
          capabilities:
              taiyinSplitTimeCapability | taiyinChineseCalendarCapability,
        ),
        returnsNormally,
      );
    });

    test(
      'rejects an ABI-6 library without the Chinese-calendar capability',
      () {
        expect(
          () => validateTaiyinNativeCompatibility(
            abiVersion: taiyinSupportedAbiVersion,
            capabilities: taiyinSplitTimeCapability,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('Chinese-calendar capability'),
            ),
          ),
        );
      },
    );

    test('rejects an ABI-6 library without split-time support', () {
      expect(
        () => validateTaiyinNativeCompatibility(
          abiVersion: taiyinSupportedAbiVersion,
          capabilities: 0,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('split-time capability'),
          ),
        ),
      );
    });

    test('rejects the retired ABI-5 major first', () {
      expect(
        () => validateTaiyinNativeCompatibility(
          abiVersion: taiyinSupportedAbiVersion - 1,
          capabilities:
              taiyinSplitTimeCapability | taiyinChineseCalendarCapability,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Unsupported Taiyin C ABI'),
          ),
        ),
      );
    });

    test('accepts a library that exposes every required ABI-6 symbol', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: taiyinRequiredAbi6Symbols.contains,
        ),
        returnsNormally,
      );
    });

    test(
      'accepts a library without BaZi symbols when the set is not required',
      () {
        // BaZi is an optional module: symbols are required only when the loaded
        // library advertises the BaZi capability.
        expect(
          () => validateTaiyinRequiredSymbols(
            providesSymbol: (symbol) => !symbol.startsWith('taiyin_bazi_'),
          ),
          returnsNormally,
        );
      },
    );

    test(
      'reports incomplete BaZi symbols when the extension is advertised',
      () {
        expect(
          () => validateTaiyinRequiredSymbols(
            providesSymbol: (symbol) =>
                !symbol.startsWith('taiyin_bazi_') ||
                symbol != 'taiyin_bazi_context_create',
            requiredSymbols: taiyinBaziSymbols,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('taiyin_bazi_context_create'),
            ),
          ),
        );
      },
    );

    test('reports missing Chinese-calendar symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_chinese_calendar_calc_year_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_chinese_calendar_calc_year_ut'),
          ),
        ),
      );
    });

    test('reports missing Ganzhi rule primitives before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) => symbol != 'taiyin_ganzhi_make',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_ganzhi_make'),
          ),
        ),
      );
    });

    test(
      'reports missing four-pillars Ganzhi symbol from the required set',
      () {
        // calc_four_pillars_ut is always exported (it returns UNSUPPORTED when
        // the extension is off), so it belongs to the required baseline.
        expect(
          () => validateTaiyinRequiredSymbols(
            providesSymbol: (symbol) =>
                symbol != 'taiyin_chinese_calendar_calc_four_pillars_ut',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('taiyin_chinese_calendar_calc_four_pillars_ut'),
            ),
          ),
        );
      },
    );

    test('reports missing ABI-6 symbols before lazy lookup', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) => symbol != 'taiyin_get_library_codename',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('missing symbols'),
              contains('taiyin_get_library_codename'),
            ),
          ),
        ),
      );
    });

    test('reports missing diagnostic-format and astrology-target symbols', () {
      for (final missingSymbol in [
        'taiyin_format_ephemeris_diagnostic',
        'taiyin_register_builtin_astrology_targets',
      ]) {
        expect(
          () => validateTaiyinRequiredSymbols(
            providesSymbol: (symbol) => symbol != missingSymbol,
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains(missingSymbol),
            ),
          ),
        );
      }
    });

    test('reports missing solar-time and phenomena symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) => symbol != 'taiyin_calc_body_phenomena_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_calc_body_phenomena_ut'),
          ),
        ),
      );
    });

    test('reports missing orbital symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_search_next_body_plane_node_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_search_next_body_plane_node_ut'),
          ),
        ),
      );
    });

    test('reports missing custom-target lifecycle symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_unregister_native_position_evaluator',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_unregister_native_position_evaluator'),
          ),
        ),
      );
    });

    test('reports missing custom astrology lifecycle symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_unregister_ayanamsha_model_with_token',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_unregister_ayanamsha_model_with_token'),
          ),
        ),
      );
    });

    test('reports missing astrology symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) => symbol != 'taiyin_calc_houses_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_calc_houses_ut'),
          ),
        ),
      );
    });

    test('reports missing lunar-point symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_calc_lunar_fitted_apogee_tt',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_calc_lunar_fitted_apogee_tt'),
          ),
        ),
      );
    });

    test('reports missing visibility symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_search_solar_twilight_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_search_solar_twilight_ut'),
          ),
        ),
      );
    });

    test('reports missing heliacal symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_search_next_star_heliacal_visibility_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_search_next_star_heliacal_visibility_ut'),
          ),
        ),
      );
    });

    test('reports missing events symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_search_next_local_solar_transit_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_search_next_local_solar_transit_ut'),
          ),
        ),
      );
    });

    test('reports missing occultation symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_compute_lunar_body_occultation_where_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_compute_lunar_body_occultation_where_ut'),
          ),
        ),
      );
    });

    test('reports missing lunar-eclipse symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_compute_local_lunar_eclipse_visibility_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_compute_local_lunar_eclipse_visibility_ut'),
          ),
        ),
      );
    });

    test('reports missing solar-eclipse symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_compute_local_solar_circumstances_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_compute_local_solar_circumstances_ut'),
          ),
        ),
      );
    });

    test('reports missing solar Besselian symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_evaluate_solar_besselian_polynomial',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_evaluate_solar_besselian_polynomial'),
          ),
        ),
      );
    });

    test('reports missing solar route symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_compute_solar_eclipse_route_map_product_ut',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_compute_solar_eclipse_route_map_product_ut'),
          ),
        ),
      );
    });
  });
}
