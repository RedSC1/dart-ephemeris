/// Raw FFI surface for the official Taiyin extension packages
/// (`package:taiyin_bazi`, `package:taiyin_ziwei`).
///
/// This library exposes the generated bindings and the interop helpers the
/// extension packages need to share one loaded native library with
/// `package:taiyin`. Its shape tracks the native ABI and may change without a
/// major version bump of `package:taiyin`; application code should prefer
/// `package:taiyin/taiyin.dart`.
library;

export 'src/bindings/taiyin_bindings.g.dart';
export 'src/interop/calendar.dart';
export 'src/interop/call_result.dart';
export 'src/interop/julian_date.dart';
export 'src/interop/native_arrays.dart';
export 'src/native_compatibility.dart';
