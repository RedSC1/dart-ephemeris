/// BaZi (八字) extension bindings for the Taiyin ephemeris.
///
/// Import alongside `package:ephemeris/ephemeris.dart`; the [BaziExtension] adds
/// `context.bazi` and `context.createBazi()` to `EphemerisContext`.
library;

export 'src/bazi_api.dart' if (dart.library.js_interop) 'src/bazi_api_web.dart';
export 'src/bazi_models.dart';
