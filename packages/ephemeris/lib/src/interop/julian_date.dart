import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/taiyin_bindings.g.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// Marshals a split Julian date into an arena-owned C ABI struct.
///
/// The C ABI represents absolute times as `taiyin_split_julian_date`
/// (`int64 day_number` + `double day_fraction`). Physical-calculation entry
/// points consume and produce this representation end to end, so the Dart
/// package crosses the FFI boundary with the split intact rather than merging
/// to `double` (which would discard the low-order fraction).
Pointer<taiyin_split_julian_date> writeJulianDate<S extends TimeScale>(
  Arena arena,
  JulianDate<S> value,
) {
  validateNativeJulianDate(value);
  final native = arena<taiyin_split_julian_date>();
  native.ref
    ..day_number = value.dayNumber
    ..day_fraction = value.dayFraction;
  return native;
}

/// Validates fields that can narrow at the native split-JD ABI boundary.
void validateNativeJulianDate<S extends TimeScale>(JulianDate<S> value) {
  // The native Dart VM already represents `int` as a signed 64-bit value,
  // matching the C ABI field. Keep this hook so extension packages can
  // validate a complete split-JD before manually embedding it in a struct.
  if (!value.dayFraction.isFinite) {
    throw ArgumentError.value(
      value.dayFraction,
      'dayFraction',
      'must be finite',
    );
  }
}

/// Reads a split Julian date returned by the C ABI into a [JulianDate].
JulianDate<S> readJulianDate<S extends TimeScale>(
  taiyin_split_julian_date value,
) {
  return JulianDate<S>.fromParts(value.day_number, value.day_fraction);
}
