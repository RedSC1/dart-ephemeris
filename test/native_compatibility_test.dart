import 'package:taiyin/src/native_compatibility.dart';
import 'package:test/test.dart';

void main() {
  group('native compatibility', () {
    test('accepts ABI 1 with split-time support', () {
      expect(
        () => validateTaiyinNativeCompatibility(
          abiVersion: taiyinSupportedAbiVersion,
          capabilities: taiyinSplitTimeCapability,
        ),
        returnsNormally,
      );
    });

    test('rejects an old ABI-1 library without split-time symbols', () {
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

    test('still rejects an unsupported ABI major first', () {
      expect(
        () => validateTaiyinNativeCompatibility(
          abiVersion: taiyinSupportedAbiVersion + 1,
          capabilities: taiyinSplitTimeCapability,
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

    test('accepts a library that exposes every required ABI-1 symbol', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: taiyinRequiredAbi1Symbols.contains,
        ),
        returnsNormally,
      );
    });

    test('reports missing late ABI-1 symbols before lazy lookup', () {
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

    test('reports missing split solar-time symbols before use', () {
      expect(
        () => validateTaiyinRequiredSymbols(
          providesSymbol: (symbol) =>
              symbol != 'taiyin_calc_equation_of_time_ut_split',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('taiyin_calc_equation_of_time_ut_split'),
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
  });
}
