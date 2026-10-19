import '../native_compatibility.dart';
import '../position/position_models.dart';
import '../result_flags.dart';

/// A feature module reported by the loaded Taiyin native library.
enum Capability {
  /// Process-wide runtime and data-source management.
  runtime(1 << 0),

  /// Time-scale conversion and Delta-T/EOP services.
  time(1 << 1),

  /// Solar-system position and state-vector calculations.
  position(1 << 2),

  /// Fixed-star catalog and position calculations.
  star(1 << 3),

  /// Rise, set, transit, and twilight calculations.
  visibility(1 << 4),

  /// Angular phenomena and phase calculations.
  phenomena(1 << 5),

  /// General event-search calculations.
  events(1 << 6),

  /// Solar- and lunar-eclipse calculations.
  eclipse(1 << 7),

  /// Occultation calculations.
  occultation(1 << 8),

  /// Heliacal-event calculations.
  heliacal(1 << 9),

  /// Houses, sidereal coordinates, and other astrology calculations.
  astrology(1 << 10),

  /// Registration of caller-defined ephemeris targets.
  customTargets(1 << 11),

  /// Registration of caller-defined ayanamsha models.
  customAyanamsha(1 << 12),

  /// Registration of caller-defined house systems.
  customHouses(1 << 13),

  /// Split-Julian-date ABI support.
  splitTime(taiyinSplitTimeCapability),

  /// Chinese lunisolar-calendar calculations.
  chineseCalendar(taiyinChineseCalendarCapability),

  /// Ganzhi calendar and four-pillar calculations.
  ganzhiCalendar(taiyinGanzhiCalendarCapability);

  const Capability(this.mask);

  /// The bit used by the native capability mask.
  final int mask;
}

/// Broad category assigned to an Ephemeris status code.
enum StatusCategory {
  /// Successful completion.
  ok(0),

  /// Invalid arguments, allocation failures, or internal calculation errors.
  generic(1),

  /// Ephemeris routing, coverage, or evaluation errors.
  ephemeris(10),

  /// Data-file parsing and I/O errors.
  file(20),

  /// Time-scale, EOP, or Delta-T errors.
  time(30),

  /// Invalid or unsupported observer configuration.
  observer(40),

  /// Event-search convergence or range errors.
  event(50),

  /// Process-wide runtime service errors.
  runtime(60),

  /// A status category unknown to this Dart package version.
  unknown(999);

  const StatusCategory(this.id);

  /// The numeric category identifier used by the native ABI.
  final int id;

  /// Returns the category for [id], or [unknown] for a newer native value.
  static StatusCategory fromId(int id) {
    return values.firstWhere((value) => value.id == id, orElse: () => unknown);
  }
}

/// A non-success status returned by the Taiyin C ABI.
class EphemerisError implements Exception {
  EphemerisError(
    this.status,
    this.name,
    this.message, {
    this.resultFlags = ResultFlags.none,
    this.diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics = const [],
  }) : diagnostics = List.unmodifiable(
         diagnostics.isEmpty && diagnostic != null ? [diagnostic] : diagnostics,
       );

  /// The negative status code returned by the native operation.
  final int status;

  /// The stable native status name, when known by the loaded library.
  final String name;

  /// A human-readable description of the failure.
  final String message;

  /// Execution facts reported before this operation failed.
  final ResultFlags resultFlags;

  /// Native route and coverage details for a failed ephemeris calculation.
  final EphemerisDiagnostic? diagnostic;

  /// Every native diagnostic available for the failed operation.
  ///
  /// Single-target failures contain [diagnostic]. Batch failures may contain
  /// several entries while [diagnostic] remains the primary first failure.
  final List<EphemerisDiagnostic> diagnostics;

  @override
  String toString() => 'EphemerisError($status, $name): $message';
}

/// An argument failed native validation.
final class InvalidArgumentError extends EphemerisError {
  InvalidArgumentError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// The native operation could not allocate required memory.
final class EphemerisOutOfMemoryError extends EphemerisError {
  EphemerisOutOfMemoryError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// The native calculation reached an invalid internal state.
final class InternalCalculationError extends EphemerisError {
  InternalCalculationError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// The requested operation or configuration is not currently supported.
final class UnsupportedOperationError extends EphemerisError {
  UnsupportedOperationError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// No usable ephemeris route or coverage could satisfy the request.
final class EphemerisRouteError extends EphemerisError {
  EphemerisRouteError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// A native data file could not be opened, parsed, or validated.
final class DataFileError extends EphemerisError {
  DataFileError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// A time-scale conversion lacked required data or received an invalid value.
class TimeScaleError extends EphemerisError {
  TimeScaleError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// Earth-orientation data is missing or does not cover the requested UTC.
final class EarthOrientationDataError extends TimeScaleError {
  EarthOrientationDataError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// Leap-second data is unavailable for the requested UTC.
final class LeapSecondDataError extends TimeScaleError {
  LeapSecondDataError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// The observer configuration is incomplete, invalid, or unsupported.
final class ObserverError extends EphemerisError {
  ObserverError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// An event search failed to converge or find an event in the requested range.
final class EventSearchError extends EphemerisError {
  EventSearchError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// A process-wide native runtime service failed.
final class RuntimeServiceError extends EphemerisError {
  RuntimeServiceError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}

/// A newer native library returned a status unknown to this Dart package.
final class UnknownNativeError extends EphemerisError {
  UnknownNativeError(
    super.status,
    super.name,
    super.message, {
    super.resultFlags,
    super.diagnostic,
    super.diagnostics,
  });
}
