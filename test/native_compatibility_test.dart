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
  });
}
