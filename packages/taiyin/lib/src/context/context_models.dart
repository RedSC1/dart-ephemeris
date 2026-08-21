import '../position/position_api.dart';
import '../time/time_models.dart';

/// Atmosphere-policy options applied to a native calculation context.
enum AtmospherePolicyFlag {
  allowStandardFallback(1 << 0);

  const AtmospherePolicyFlag(this.mask);

  final int mask;
}

/// Precession model used by apparent and coordinate calculations.
enum PrecessionModel {
  vondrak2011(0),
  iau2006(1),
  iau1976(2),
  newcomb1895(3);

  const PrecessionModel(this.id);

  final int id;
}

/// Nutation model used by apparent and coordinate calculations.
enum NutationModel {
  iau2000B(0),
  iau2000A(1);

  const NutationModel(this.id);

  final int id;
}

/// Obliquity model used by Ephemeris.
///
/// ABI version 2 currently exposes one implementation.
enum ObliquityModel {
  iau2006(0);

  const ObliquityModel(this.id);

  final int id;
}

/// Route used to transform between equatorial reference frames.
enum FrameRoute {
  equinox(0),
  cirs(1);

  const FrameRoute(this.id);

  final int id;
}

/// A native ephemeris route-rule table identifier.
///
/// [raw] accepts the signed 64-bit bit pattern passed to the C ABI's
/// `uint64_t`. Unknown identifiers are rejected by the native library.
final class RouteRule {
  const RouteRule.raw(this.id);

  static const automatic = RouteRule.raw(0);
  static const opm2 = RouteRule.raw(1);
  static const spk = RouteRule.raw(2);
  static const semiAnalytic = RouteRule.raw(3);

  final int id;
}

/// Atmospheric-refraction implementation.
enum RefractionModel {
  bennett(0),
  skyfield(1),
  hybrid(2),
  auerStandish(3),
  sofa(4);

  const RefractionModel(this.id);

  final int id;
}

/// Model used by heliacal-visibility calculations.
enum HeliacalVisibilityModel {
  belokrylov2011(0),
  schaefer1993(1);

  const HeliacalVisibilityModel(this.id);

  final int id;
}

/// Corrections and outputs enabled in an apparent-position calculation.
enum ApparentFlag {
  lightTime(1 << 0),
  spherical(1 << 2),
  aberration(1 << 3),
  deflection(1 << 4),
  velocity(1 << 5),
  acceleration(1 << 6),
  shapiroDelay(1 << 7);

  const ApparentFlag(this.mask);

  final int mask;
}

/// Aberration implementation.
///
/// ABI version 2 currently exposes one implementation.
enum AberrationModel {
  annualRelativistic(0);

  const AberrationModel(this.id);

  final int id;
}

/// Gravitational-deflection implementation.
enum DeflectionModel {
  erfa(0),
  solarDisk(1);

  const DeflectionModel(this.id);

  final int id;
}

/// Light-time implementation.
///
/// ABI version 2 currently exposes one implementation.
enum LightTimeMethod {
  iterative(0);

  const LightTimeMethod(this.id);

  final int id;
}

/// Shapiro-delay implementation.
///
/// ABI version 2 currently exposes one implementation.
enum ShapiroDelayModel {
  standard(0);

  const ShapiroDelayModel(this.id);

  final int id;
}

/// Earth-shadow model used by eclipse calculations.
enum EclipseShadowModel {
  nasaDanjon(0),
  chauvenet(1),
  geometric(2),
  rawDanjon(3);

  const EclipseShadowModel(this.id);

  final int id;
}

/// Lunar-radius model used by eclipse calculations.
enum EclipseMoonRadiusModel {
  almanac(0),
  mean(1);

  const EclipseMoonRadiusModel(this.id);

  final int id;
}

/// Geographic observer coordinates.
///
/// Longitude and latitude are expressed in degrees and height in metres.
final class ObserverLocation {
  const ObserverLocation({
    required this.longitudeDegrees,
    required this.latitudeDegrees,
    this.heightMeters = 0,
  });

  final double longitudeDegrees;
  final double latitudeDegrees;
  final double heightMeters;
}

/// Atmospheric conditions used for refraction and visibility.
final class Atmosphere {
  const Atmosphere({
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
final class AstroModelConfig {
  const AstroModelConfig({
    this.tdbModel = TdbModel.fastPeriodic,
    this.precessionModel,
    this.nutationModel,
    this.obliquityModel = ObliquityModel.iau2006,
    this.frameRoute = FrameRoute.equinox,
  });

  final TdbModel tdbModel;
  final PrecessionModel? precessionModel;
  final NutationModel? nutationModel;
  final ObliquityModel obliquityModel;
  final FrameRoute frameRoute;
}

/// Apparent-position options copied into a native context.
final class ApparentConfig {
  ApparentConfig({
    Set<ApparentFlag> flags = const {
      ApparentFlag.lightTime,
      ApparentFlag.spherical,
    },
    this.outputFrame = ApparentFrame.trueEclipticOfDate,
    this.lightTimeMethod = LightTimeMethod.iterative,
    this.shapiroDelayModel = ShapiroDelayModel.standard,
    this.aberrationModel = AberrationModel.annualRelativistic,
    this.deflectionModel = DeflectionModel.erfa,
    this.maxLightTimeIterations = 8,
    this.lightTimeToleranceDays = 1e-13,
    this.matrixDerivativeStepDays = 1e-3,
  }) : flags = Set.unmodifiable(flags);

  final Set<ApparentFlag> flags;
  final ApparentFrame outputFrame;
  final LightTimeMethod lightTimeMethod;
  final ShapiroDelayModel shapiroDelayModel;
  final AberrationModel aberrationModel;
  final DeflectionModel deflectionModel;
  final int maxLightTimeIterations;
  final double lightTimeToleranceDays;
  final double matrixDerivativeStepDays;
}

/// A body that contributes to gravitational light deflection.
final class ApparentDeflector {
  const ApparentDeflector({
    required this.bodyId,
    required this.schwarzschildRadiusAu,
    this.limit = 0,
  });

  final int bodyId;
  final double schwarzschildRadiusAu;
  final double limit;
}
