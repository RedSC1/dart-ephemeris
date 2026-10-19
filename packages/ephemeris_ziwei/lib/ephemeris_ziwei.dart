/// Ziwei Doushu (紫微斗数) extension bindings for the Taiyin ephemeris.
///
/// Import alongside `package:ephemeris/ephemeris.dart`; the [ZiweiExtension] adds
/// `context.ziwei` and `context.createZiwei()` to `EphemerisContext`. The
/// default rule profile ships bundled in this package.
library;

export 'src/ziwei_api.dart'
    if (dart.library.js_interop) 'src/ziwei_api_web.dart';
export 'src/ziwei_models.dart';
