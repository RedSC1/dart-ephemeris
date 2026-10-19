import 'dart:ffi';
export 'value_validation.dart';

/// Validates a non-negative Dart integer before passing it as native `size_t`.
void validateNativeSize(int value, String name) {
  final maxValue = sizeOf<Size>() == 4 ? 0xffffffff : 0x7fffffffffffffff;
  if (value < 0 || value > maxValue) {
    throw RangeError.range(value, 0, maxValue, name);
  }
}
