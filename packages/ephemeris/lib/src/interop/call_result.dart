import '../result_flags.dart';

/// Decoded status and execution facts from a native ABI call.
typedef DecodedCallResult = ({int status, ResultFlags flags});

/// Decodes an ABI-9 packed call result or a retained legacy status return.
///
/// This is exported only through `package:ephemeris/ffi.dart` for the official
/// extension packages. Application code should consume [OperationResult]
/// records instead of native return words.
DecodedCallResult decodeNativeCallResult(int rawResult) {
  if (rawResult >= 0) {
    return (status: 0, flags: ResultFlags(rawResult & 0xffffffff));
  }
  if (rawResult >= -0x80000000) {
    return (status: rawResult, flags: ResultFlags.none);
  }
  return (status: rawResult >> 32, flags: ResultFlags(rawResult & 0xffffffff));
}
