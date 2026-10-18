/// Validates a Dart integer before passing it to a native `int32_t` field.
void validateNativeInt32(int value, String name) {
  if (value < -0x80000000 || value > 0x7fffffff) {
    throw RangeError.range(value, -0x80000000, 0x7fffffff, name);
  }
}

/// Validates a Dart integer before passing it to a native `uint8_t` field.
void validateNativeUint8(int value, String name) {
  if (value < 0 || value > 0xff) {
    throw RangeError.range(value, 0, 0xff, name);
  }
}

/// Validates a Dart integer before passing it to a native `uint16_t` field.
void validateNativeUint16(int value, String name) {
  if (value < 0 || value > 0xffff) {
    throw RangeError.range(value, 0, 0xffff, name);
  }
}

/// Validates a Dart integer before passing it to a native `uint32_t` field.
void validateNativeUint32(int value, String name) {
  if (value < 0 || value > 0xffffffff) {
    throw RangeError.range(value, 0, 0xffffffff, name);
  }
}

/// Requires a finite floating-point value at an FFI boundary.
void validateNativeFinite(double value, String name) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, name, 'must be finite');
  }
}
