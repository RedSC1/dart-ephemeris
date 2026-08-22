/// Astronomy, Chinese-calendar, Ganzhi, and astrology APIs backed by Taiyin.
///
/// Open the process-wide native runtime once with [Ephemeris.open], then create
/// an independent [EphemerisContext] for each calculation policy or isolate:
///
/// ```dart
/// import 'package:ephemeris/ephemeris.dart' as taiyin;
///
/// final ephemeris = taiyin.Ephemeris.open();
/// final context = ephemeris.createContext();
/// try {
///   final result = context.position.atTt(
///     taiyin.Body.mars,
///     taiyin.TtJulianDate.fromDouble(2460409.0),
///   );
///   print(result.value.coordinates);
///   print(result.flags.values);
/// } finally {
///   context.close();
/// }
/// ```
///
/// Native failures are surfaced as [EphemerisError] subclasses. Successful
/// operations return an [OperationResult] record whose `flags` report facts
/// such as an ephemeris fallback or numerical derivative. BaZi and Ziwei
/// Doushu live in the separate `taiyin_bazi` and `taiyin_ziwei` packages.
library;

export 'src/taiyin.dart';
export 'src/astrology/astrology_models.dart';
export 'src/chinese_calendar/chinese_calendar_models.dart';
export 'src/context/context_models.dart';
export 'src/ganzhi/ganzhi_models.dart';
export 'src/eclipse/lunar_eclipse_models.dart';
export 'src/eclipse/solar_eclipse_models.dart';
export 'src/events/event_models.dart';
export 'src/heliacal/heliacal_models.dart';
export 'src/observed/observed_models.dart';
export 'src/occultation/occultation_models.dart';
export 'src/orbital/orbital_models.dart';
export 'src/phenomena/phenomena_models.dart';
export 'src/position/position_api.dart';
export 'src/runtime/runtime_models.dart';
export 'src/result_flags.dart';
export 'src/solar_time/solar_time_models.dart';
export 'src/star/star_models.dart';
export 'src/time/astro_date_time.dart';
export 'src/time/julian_date.dart';
export 'src/time/time_api.dart';
export 'src/time/time_models.dart';
export 'src/time/time_scale.dart';
export 'src/visibility/visibility_models.dart';
