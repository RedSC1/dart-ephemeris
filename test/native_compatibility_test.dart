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
  });
}
