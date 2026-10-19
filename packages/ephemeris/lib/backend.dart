/// Internal typed services for the official extension packages.
///
/// Ordinary applications should import `ephemeris.dart`. This boundary does
/// not expose native pointers, Wasm addresses, arenas or growing memory views.
///
/// @nodoc
library;

export 'src/chinese_calendar/calendar_shared.dart' show CalendarContextBase;
export 'src/backend/backend_call.dart';
export 'src/interop/value_validation.dart';
export 'src/web/eclipse_records.dart' show Web_taiyin_split_julian_date;
