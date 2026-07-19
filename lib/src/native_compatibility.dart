const int taiyinSupportedAbiVersion = 1;
const int taiyinSplitTimeCapability = 1 << 14;

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
