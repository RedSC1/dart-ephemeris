/// Internal Web-only ownership types for the official extension adapters.
/// Import this only from a conditionally selected Web implementation.
///
/// @nodoc
library;

export 'src/web/ephemeris_web.dart'
    show EphemerisContext, ChineseCalendarContext, TaiyinExtensionHost;
