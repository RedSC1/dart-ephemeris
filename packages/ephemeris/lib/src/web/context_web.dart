import '../context/context_models.dart';
import '../position/position_models.dart';
import '../time/time_models.dart';

/// Context configuration implemented by the initial Wasm position backend.
final class ContextConfiguration {
  ContextConfiguration.internal(this._configure, this._setTdbModel);
  final void Function(int, List<num>) _configure;
  final void Function(TdbModel) _setTdbModel;

  void _set(int operation, List<num> values) {
    if (values.any((v) => !v.isFinite)) {
      throw ArgumentError('Configuration must be finite.');
    }
    _configure(operation, values);
  }

  void reset() {
    _set(9, []);
    _setTdbModel(TdbModel.fastPeriodic);
  }

  void setRouteRule(RouteRule rule) {
    if (rule.id < 0 || rule.id > 3) {
      throw UnsupportedError(
        'The initial Web backend supports built-in route IDs 0–3.',
      );
    }
    _set(0, [rule.id]);
  }

  void setGeocentricObserver({required int observerId, required int centerId}) {
    _int32(observerId, 'observerId');
    _int32(centerId, 'centerId');
    _set(2, [observerId, centerId]);
  }

  void setObserverLocation(ObserverLocation location) {
    if (location.latitudeDegrees < -90 || location.latitudeDegrees > 90) {
      throw RangeError.range(
        location.latitudeDegrees,
        -90,
        90,
        'latitudeDegrees',
      );
    }
    _set(3, [
      location.longitudeDegrees,
      location.latitudeDegrees,
      location.heightMeters,
    ]);
  }

  void clearObserverLocation() => _set(4, []);
  void setAstroModels(AstroModelConfig config) {
    _set(5, [
      config.tdbModel.id,
      config.precessionModel?.id ?? -1,
      config.nutationModel?.id ?? -1,
      config.obliquityModel.id,
      config.frameRoute.id,
    ]);
    _setTdbModel(config.tdbModel);
  }

  void setApparentConfig(ApparentConfig config) {
    if (config.outputFrame == ApparentFrame.unknown) {
      throw ArgumentError.value(config.outputFrame, 'outputFrame');
    }
    _int32(config.maxLightTimeIterations, 'maxLightTimeIterations');
    if (config.maxLightTimeIterations < 0) {
      throw RangeError('maxLightTimeIterations must be non-negative');
    }
    if (config.lightTimeToleranceDays < 0) {
      throw RangeError.range(
        config.lightTimeToleranceDays,
        0,
        null,
        'lightTimeToleranceDays',
      );
    }
    if (config.matrixDerivativeStepDays <= 0) {
      throw RangeError.value(
        config.matrixDerivativeStepDays,
        'matrixDerivativeStepDays',
        'must be positive',
      );
    }
    if (config.flags.contains(ApparentFlag.shapiroDelay) &&
        !config.flags.contains(ApparentFlag.lightTime)) {
      throw ArgumentError(
        'Shapiro delay requires the light-time correction flag.',
      );
    }
    _set(6, [
      config.flags.fold<int>(0, (m, f) => m | f.mask),
      config.outputFrame.id,
      config.lightTimeMethod.id,
      config.shapiroDelayModel.id,
      config.aberrationModel.id,
      config.deflectionModel.id,
      config.maxLightTimeIterations,
      config.lightTimeToleranceDays,
      config.matrixDerivativeStepDays,
    ]);
  }

  void useSolarDeflector() => _set(7, []);
  void clearDeflectors() => _set(8, []);
  void setLightTimeIteration({
    required int maxIterations,
    required double toleranceDays,
  }) {
    if (maxIterations < 0 || maxIterations > 0x7fffffff) {
      throw RangeError.range(maxIterations, 0, 0x7fffffff);
    }
    if (toleranceDays < 0) {
      throw RangeError.range(toleranceDays, 0, null, 'toleranceDays');
    }
    _set(10, [maxIterations, toleranceDays]);
  }

  static void _int32(int n, String name) {
    if (n < -0x80000000 || n > 0x7fffffff) {
      throw RangeError.range(n, -0x80000000, 0x7fffffff, name);
    }
  }
}
