import '../time/julian_date.dart';
import '../time/time_scale.dart';

/// A date-level transition in morning or evening heliacal visibility.
///
/// Its stable values are the `TAIYIN_C_HELIACAL_EVENT_*` C ABI constants;
/// the native runtime names the equivalent constants
/// `TAIYIN_HELIACAL_VISIBILITY_EVENT_*`.
enum TaiyinHeliacalEventKind {
  morningFirst(1),
  morningLast(2),
  eveningFirst(3),
  eveningLast(4),
  unknown(-1);

  const TaiyinHeliacalEventKind(this.id);

  /// Stable value used by the Taiyin C ABI.
  final int id;

  static TaiyinHeliacalEventKind fromId(int id) {
    return values.where((value) => value.id == id).firstOrNull ?? unknown;
  }
}

/// Options specific to heliacal-visibility calculations.
enum TaiyinHeliacalFlag {
  /// Includes the selected model's moonlight contribution when available.
  includeMoonlight(1 << 32),

  /// Requires explicit complete meteorological inputs instead of fallback.
  strictMeteorology(1 << 33);

  const TaiyinHeliacalFlag(this.mask);

  /// Bit used by the Taiyin C ABI.
  final int mask;
}

/// Optional measured conditions supplied to a heliacal-visibility model.
///
/// A `null` property asks the selected native profile to use its calibrated or
/// derived value. Values that are supplied must be finite and positive.
final class TaiyinHeliacalVisibilityConditions {
  const TaiyinHeliacalVisibilityConditions({
    this.extinctionMagnitudePerAirmass,
    this.skyBrightnessNanolambert,
    this.nightSkyBrightnessNanolambert,
  });

  /// Locally measured zenith extinction, in visual magnitudes per airmass.
  final double? extinctionMagnitudePerAirmass;

  /// Measured target-direction background brightness, in nanoLamberts.
  final double? skyBrightnessNanolambert;

  /// Measured dark-sky zenith brightness, in nanoLamberts.
  final double? nightSkyBrightnessNanolambert;
}

/// Visibility diagnostics returned by the selected heliacal model.
///
/// [requiredSunAltitudeRadians] and [solarDepressionMarginRadians] are the
/// only optional scalar diagnostics: native non-finite sentinels map to
/// `null`. The other numeric fields preserve the native model output and are
/// finite for the bundled models on a successful calculation.
final class TaiyinHeliacalVisibilityResult {
  const TaiyinHeliacalVisibilityResult({
    required this.visible,
    required this.modelId,
    required this.extinctionModelId,
    required this.twilightModelId,
    required this.moonlightModelId,
    required this.visualThresholdModelId,
    required this.targetMagnitude,
    required this.limitingMagnitude,
    required this.targetAltitudeRadians,
    required this.targetAzimuthRadians,
    required this.sunAltitudeRadians,
    required this.sunAzimuthRadians,
    required this.targetSunSeparationRadians,
    required this.airmass,
    required this.extinctionMagnitudePerAirmass,
    required this.extinctionMagnitude,
    required this.skyBrightnessNanolambert,
    required this.moonlightBrightnessNanolambert,
    required this.thresholdIlluminanceFootcandles,
    required this.targetIlluminanceFootcandles,
    required this.visibilityMarginMagnitude,
    required this.requiredSunAltitudeRadians,
    required this.solarDepressionMarginRadians,
  });

  final bool visible;

  /// Identifier of the native heliacal-visibility model that produced this
  /// result.
  final int modelId;

  /// Native component identifiers, useful when recording a model result.
  final int extinctionModelId;
  final int twilightModelId;
  final int moonlightModelId;
  final int visualThresholdModelId;

  final double targetMagnitude;
  final double limitingMagnitude;
  final double targetAltitudeRadians;
  final double targetAzimuthRadians;
  final double sunAltitudeRadians;
  final double sunAzimuthRadians;
  final double targetSunSeparationRadians;
  final double airmass;
  final double extinctionMagnitudePerAirmass;
  final double extinctionMagnitude;
  final double skyBrightnessNanolambert;
  final double moonlightBrightnessNanolambert;
  final double thresholdIlluminanceFootcandles;
  final double targetIlluminanceFootcandles;

  /// Positive when the target is brighter than the limiting magnitude.
  final double visibilityMarginMagnitude;

  /// Inverse Sun-altitude criterion, when supplied by the selected model.
  final double? requiredSunAltitudeRadians;

  /// Solar-depression margin, when supplied by the selected model.
  final double? solarDepressionMarginRadians;
}

/// A located heliacal-visibility transition and its best visibility window.
///
/// The native ABI returns these UT1 dates as scalar Julian dates, so they
/// cannot retain split-JD precision at the FFI boundary.
final class TaiyinHeliacalVisibilitySearchResult {
  const TaiyinHeliacalVisibilitySearchResult({
    required this.event,
    required this.coordinate,
    required this.windowStart,
    required this.windowEnd,
    required this.scannedDayCount,
    required this.sampledWindowCount,
    required this.visibilityEvaluationCount,
    required this.visibility,
  });

  final TaiyinHeliacalEventKind event;
  final JulianDate<Ut1Scale> coordinate;
  final JulianDate<Ut1Scale> windowStart;
  final JulianDate<Ut1Scale> windowEnd;
  final int scannedDayCount;
  final int sampledWindowCount;
  final int visibilityEvaluationCount;
  final TaiyinHeliacalVisibilityResult visibility;
}
