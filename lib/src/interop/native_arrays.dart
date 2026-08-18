/// Guards for array sizes returned by the native two-call sizing pattern.
library;

/// Validates a native-required element [count] before allocating the buffer.
int validatedNativeArrayCount(int count, String noun) {
  if (count < 0) {
    throw StateError('Native $noun returned a negative count');
  }
  return count;
}

/// Validates the element [count] reported by a native array fill against the
/// [capacity] of the buffer that was passed in.
int validatedNativeResultCount(int count, int capacity) {
  if (count < 0 || count > capacity) {
    throw StateError(
      'Native array fill returned count=$count outside 0..$capacity',
    );
  }
  return count;
}
