import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/taiyin_bindings.g.dart';
import '../time/astro_date_time.dart';
import 'native_validation.dart';

/// Marshals an astronomical calendar value into an arena-owned C ABI struct.
Pointer<taiyin_calendar_datetime> writeNativeCalendar(
  TaiyinBindings bindings,
  Arena arena,
  AstroDateTime value,
) {
  validateNativeCalendar(value);
  final native = arena<taiyin_calendar_datetime>();
  bindings.taiyin_calendar_datetime_init(native);
  native.ref
    ..year = value.year
    ..month = value.month
    ..day = value.day
    ..hour = value.hour
    ..minute = value.minute
    ..second = value.fractionalSecond;
  return native;
}

/// Validates fields that can narrow at the native calendar ABI boundary.
void validateNativeCalendar(AstroDateTime value) {
  validateNativeInt32(value.year, 'year');
}

/// Converts a native calendar struct into an [AstroDateTime] using the same
/// second rounding the time API applies to `reverseJulianDay`.
AstroDateTime readCalendarDateTime(taiyin_calendar_datetime value) {
  final minute = AstroDateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
  );
  return minute.addNanoseconds(
    (value.second * Duration.microsecondsPerSecond * 1000).round(),
  );
}
