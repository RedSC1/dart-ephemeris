import '../position/position_api.dart';
import '../time/time_models.dart';

/// Atmosphere-policy options applied to a native calculation context.
enum TaiyinAtmospherePolicyFlag {
  allowStandardFallback(1 << 0);

  const TaiyinAtmospherePolicyFlag(this.mask);

  final int mask;
}

/// Precession model used by apparent and coordinate calculations.
enum TaiyinPrecessionModel {
  vondrak2011(0),
  iau2006(1),
  iau1976(2),
  newcomb1895(3);

  const TaiyinPrecessionModel(this.id);

  final int id;
}

/// Nutation model used by apparent and coordinate calculations.
enum TaiyinNutationModel {
  iau2000B(0),
  iau2000A(1);

  const TaiyinNutationModel(this.id);

  final int id;
}

/// Obliquity model used by Taiyin.
///
/// ABI version 2 currently exposes one implementation.
enum TaiyinObliquityModel {
  iau2006(0);

  const TaiyinObliquityModel(this.id);

  final int id;
}

/// Route used to transform between equatorial reference frames.
enum TaiyinFrameRoute {
  equinox(0),
  cirs(1);

  const TaiyinFrameRoute(this.id);

  final int id;
}

/// A native ephemeris route-rule table identifier.
///
/// [raw] accepts the signed 64-bit bit pattern passed to the C ABI's
/// `uint64_t`. Unknown identifiers are rejected by the native library.
final class TaiyinRouteRule {
  const TaiyinRouteRule.raw(this.id);

  static const automatic = TaiyinRouteRule.raw(0);
  static const opm2 = TaiyinRouteRule.raw(1);
  static const spk = TaiyinRouteRule.raw(2);
  static const semiAnalytic = TaiyinRouteRule.raw(3);

  final int id;
}

/// Atmospheric-refraction implementation.
enum TaiyinRefractionModel {
  bennett(0),
  skyfield(1),
  hybrid(2),
  auerStandish(3),
  sofa(4);

  const TaiyinRefractionModel(this.id);

  final int id;
}

/// Model used by heliacal-visibility calculations.
enum TaiyinHeliacalVisibilityModel {
  belokrylov2011(0),
  schaefer1993(1);

  const TaiyinHeliacalVisibilityModel(this.id);

  final int id;
}

/// Corrections and outputs enabled in an apparent-position calculation.
enum TaiyinApparentFlag {
  lightTime(1 << 0),
  spherical(1 << 2),
  aberration(1 << 3),
  deflection(1 << 4),
  velocity(1 << 5),
  acceleration(1 << 6),
  shapiroDelay(1 << 7);

  const TaiyinApparentFlag(this.mask);

  final int mask;
}

/// Aberration implementation.
///
/// ABI version 2 currently exposes one implementation.
enum TaiyinAberrationModel {
  annualRelativistic(0);

  const TaiyinAberrationModel(this.id);

  final int id;
}

/// Gravitational-deflection implementation.
enum TaiyinDeflectionModel {
  erfa(0),
  solarDisk(1);

  const TaiyinDeflectionModel(this.id);

  final int id;
}

/// Light-time implementation.
///
/// ABI version 2 currently exposes one implementation.
enum TaiyinLightTimeMethod {
  iterative(0);

  const TaiyinLightTimeMethod(this.id);

  final int id;
}

/// Shapiro-delay implementation.
///
/// ABI version 2 currently exposes one implementation.
enum TaiyinShapiroDelayModel {
  standard(0);

  const TaiyinShapiroDelayModel(this.id);

  final int id;
}

/// Earth-shadow model used by eclipse calculations.
enum TaiyinEclipseShadowModel {
  nasaDanjon(0),
  chauvenet(1),
  geometric(2),
  rawDanjon(3);

  const TaiyinEclipseShadowModel(this.id);

  final int id;
}

/// Lunar-radius model used by eclipse calculations.
enum TaiyinEclipseMoonRadiusModel {
  almanac(0),
  mean(1);

  const TaiyinEclipseMoonRadiusModel(this.id);

  final int id;
}

/// Geographic observer coordinates.
///
/// Longitude and latitude are expressed in degrees and height in metres.
final class TaiyinObserverLocation {
  const TaiyinObserverLocation({
    required this.longitudeDegrees,
    required this.latitudeDegrees,
    this.heightMeters = 0,
  });

  final double longitudeDegrees;
  final double latitudeDegrees;
  final double heightMeters;
}

/// Atmospheric conditions used for refraction and visibility.
final class TaiyinAtmosphere {
  const TaiyinAtmosphere({
    this.pressureMillibars = 1013.25,
    this.temperatureCelsius = 15,
    this.relativeHumidityPercent = 0,
    this.wavelengthMicrometers = 0.55,
  });

  final double pressureMillibars;
  final double temperatureCelsius;
  final double relativeHumidityPercent;
  final double wavelengthMicrometers;
}

/// Astronomy-model selection for a native context.
///
/// A null precession or nutation model requests Taiyin's current default.
final class TaiyinAstroModelConfig {
  const TaiyinAstroModelConfig({
    this.tdbModel = TdbModel.fastPeriodic,
    this.precessionModel,
    this.nutationModel,
    this.obliquityModel = TaiyinObliquityModel.iau2006,
    this.frameRoute = TaiyinFrameRoute.equinox,
  });

  final TdbModel tdbModel;
  final TaiyinPrecessionModel? precessionModel;
  final TaiyinNutationModel? nutationModel;
  final TaiyinObliquityModel obliquityModel;
  final TaiyinFrameRoute frameRoute;
}

/// Apparent-position options copied into a native context.
final class TaiyinApparentConfig {
  TaiyinApparentConfig({
    Set<TaiyinApparentFlag> flags = const {
      TaiyinApparentFlag.lightTime,
      TaiyinApparentFlag.spherical,
    },
    this.outputFrame = TaiyinApparentFrame.trueEclipticOfDate,
    this.lightTimeMethod = TaiyinLightTimeMethod.iterative,
    this.shapiroDelayModel = TaiyinShapiroDelayModel.standard,
    this.aberrationModel = TaiyinAberrationModel.annualRelativistic,
    this.deflectionModel = TaiyinDeflectionModel.erfa,
    this.maxLightTimeIterations = 8,
    this.lightTimeToleranceDays = 1e-13,
    this.matrixDerivativeStepDays = 1e-3,
  }) : flags = Set.unmodifiable(flags);

  final Set<TaiyinApparentFlag> flags;
  final TaiyinApparentFrame outputFrame;
  final TaiyinLightTimeMethod lightTimeMethod;
  final TaiyinShapiroDelayModel shapiroDelayModel;
  final TaiyinAberrationModel aberrationModel;
  final TaiyinDeflectionModel deflectionModel;
  final int maxLightTimeIterations;
  final double lightTimeToleranceDays;
  final double matrixDerivativeStepDays;
}

/// A body that contributes to gravitational light deflection.
final class TaiyinApparentDeflector {
  const TaiyinApparentDeflector({
    required this.bodyId,
    required this.schwarzschildRadiusAu,
    this.limit = 0,
  });

  final int bodyId;
  final double schwarzschildRadiusAu;
  final double limit;
}
