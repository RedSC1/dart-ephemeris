/// Raw FFI surface for the official Taiyin extension packages
/// (`package:ephemeris_bazi`, `package:ephemeris_ziwei`).
///
/// This library exposes the generated bindings and the interop helpers the
/// extension packages need to share core contexts and load their own native
/// modules. Its shape tracks the native ABI and may change without a major
/// version bump of `package:ephemeris`; application code should prefer
/// `package:ephemeris/ephemeris.dart`.
library;

export 'src/bindings/taiyin_bindings.g.dart';
export 'src/interop/calendar.dart';
export 'src/interop/call_result.dart';
export 'src/interop/julian_date.dart';
export 'src/interop/native_arrays.dart';
export 'src/native_compatibility.dart';
