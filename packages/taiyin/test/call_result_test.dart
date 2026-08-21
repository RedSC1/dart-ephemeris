import 'package:taiyin/ffi.dart';
import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';

void main() {
  group('ABI-9 call results', () {
    test('decodes successful execution facts', () {
      final decoded = decodeNativeCallResult(
        ResultFlag.fallbackOccurred.mask | ResultFlag.numericalDerivative.mask,
      );

      expect(decoded.status, 0);
      expect(decoded.flags.contains(ResultFlag.fallbackOccurred), isTrue);
      expect(decoded.flags.contains(ResultFlag.numericalDerivative), isTrue);
      expect(decoded.flags.contains(ResultFlag.timeScaleFallback), isFalse);
    });

    test('decodes a failed call without losing its execution facts', () {
      const status = -1002;
      final rawResult = (status << 32) | ResultFlag.fallbackOccurred.mask;
      final decoded = decodeNativeCallResult(rawResult);

      expect(decoded.status, status);
      expect(decoded.flags.values, {ResultFlag.fallbackOccurred});
    });

    test('retains legacy int32 statuses used by setup APIs', () {
      final decoded = decodeNativeCallResult(-3);

      expect(decoded.status, -3);
      expect(decoded.flags, ResultFlags.none);
    });
  });
}
