part of '../taiyin.dart';

const int _taiyinStatusOk = 0;
const int _taiyinErrorInvalidArgument = -1;
const int _taiyinErrorInternal = -3;

typedef _NativeCustomDependencyPosition =
    taiyin_status Function(
      Pointer<taiyin_context>,
      Int32,
      Double,
      Double,
      Uint32,
      Pointer<Double>,
      Pointer<taiyin_ephemeris_diagnostic>,
    );
typedef _DartCustomDependencyPosition =
    int Function(
      Pointer<taiyin_context>,
      int,
      double,
      double,
      int,
      Pointer<Double>,
      Pointer<taiyin_ephemeris_diagnostic>,
    );

/// Inputs supplied by Taiyin when evaluating a custom target.
///
/// A request borrows its native calculation context and is valid only for the
/// duration of the evaluator call.
final class TaiyinCustomTargetRequest {
  const TaiyinCustomTargetRequest._({
    required this.target,
    required this.julianDateTdb,
    required this.julianDateTt,
    required this.rawFlags,
    required Pointer<taiyin_context> context,
    required Pointer<NativeFunction<_NativeCustomDependencyPosition>>
    dependencyPosition,
  }) : _context = context,
       _dependencyPosition = dependencyPosition;

  final TaiyinCustomTarget target;
  final double julianDateTdb;
  final double julianDateTt;
  final int rawFlags;
  final Pointer<taiyin_context> _context;
  final Pointer<NativeFunction<_NativeCustomDependencyPosition>>
  _dependencyPosition;

  Set<TaiyinPositionFlag> get flags => Set.unmodifiable({
    for (final flag in TaiyinPositionFlag.values)
      if ((rawFlags & flag.mask) != 0) flag,
  });

  bool hasFlag(TaiyinPositionFlag flag) => (rawFlags & flag.mask) != 0;

  /// Calculates another target with the borrowed context and callback epoch.
  ///
  /// A native failure is rethrown as [TaiyinCustomEvaluatorFailure], so it
  /// automatically becomes the custom evaluator's status unless caught.
  List<double> positionOf(
    TaiyinTarget dependency, {
    Set<TaiyinPositionFlag> flags = const {},
  }) {
    final mask = flags.fold(0, (value, flag) => value | flag.mask);
    final calculate = _dependencyPosition
        .asFunction<_DartCustomDependencyPosition>();
    return using((arena) {
      final output = arena<Double>(6);
      final diagnostic = arena<taiyin_ephemeris_diagnostic>();
      diagnostic.ref.struct_size = sizeOf<taiyin_ephemeris_diagnostic>();
      final status = calculate(
        _context,
        dependency.id,
        julianDateTdb,
        julianDateTt,
        mask,
        output,
        diagnostic,
      );
      if (status != _taiyinStatusOk) {
        throw TaiyinCustomEvaluatorFailure(status);
      }
      return List<double>.unmodifiable([
        for (var index = 0; index < 6; index++) output[index],
      ]);
    });
  }
}

/// Calculates the six native position values for a custom target.
///
/// The returned list must contain exactly six finite values. Components 0–2
/// are coordinates and components 3–5 are rates; their frame and units follow
/// [TaiyinCustomTargetRequest.flags].
typedef TaiyinCustomPositionEvaluator =
    List<double> Function(TaiyinCustomTargetRequest request);

/// Calculates an exact Cartesian state for a custom target.
///
/// When omitted during registration, Taiyin derives the state with its native
/// finite-difference fallback.
typedef TaiyinCustomStateEvaluator =
    TaiyinCartesianState Function(TaiyinCustomTargetRequest request);

/// A deliberate non-success status returned by a custom target evaluator.
final class TaiyinCustomEvaluatorFailure implements Exception {
  const TaiyinCustomEvaluatorFailure(this.status)
    : assert(status != 0, 'A failure status must be non-zero.');

  final int status;

  @override
  String toString() => 'TaiyinCustomEvaluatorFailure($status)';
}

final class _TaiyinCustomTargetRegistration {
  const _TaiyinCustomTargetRegistration(this.position, this.state);

  final NativeCallable<taiyin_native_position_evaluator_fnFunction> position;
  final NativeCallable<taiyin_native_state_evaluator_fnFunction>? state;
}

TaiyinCustomTarget _registerCustomTarget(
  DynamicLibrary library,
  _TaiyinNativeLibraryState nativeState,
  int targetId,
  TaiyinCustomPositionEvaluator positionEvaluator,
  TaiyinCustomStateEvaluator? stateEvaluator,
) {
  final target = TaiyinCustomTarget(targetId);
  if (nativeState.customTargetRegistrations.containsKey(targetId)) {
    throw ArgumentError.value(
      targetId,
      'targetId',
      'has already been registered in this process',
    );
  }

  NativeCallable<taiyin_native_position_evaluator_fnFunction>? positionCallable;
  NativeCallable<taiyin_native_state_evaluator_fnFunction>? stateCallable;
  final dependencyPositionAddress = library
      .lookup<NativeFunction<_NativeCustomDependencyPosition>>(
        'taiyin_calc_position_tdb',
      )
      .address;
  try {
    positionCallable = _createCustomPositionCallable(
      positionEvaluator,
      dependencyPositionAddress,
    );
    if (stateEvaluator != null) {
      stateCallable = _createCustomStateCallable(
        stateEvaluator,
        dependencyPositionAddress,
      );
    }
  } catch (_) {
    stateCallable?.close();
    positionCallable?.close();
    rethrow;
  }

  final registeredPosition = positionCallable;
  final status = nativeState.bindings.taiyin_register_native_position_evaluator(
    targetId,
    registeredPosition.nativeFunction,
    stateCallable?.nativeFunction ?? nullptr,
    nullptr,
  );
  if (status != _taiyinStatusOk) {
    stateCallable?.close();
    registeredPosition.close();
    _checkStatus(nativeState.bindings, status);
  }

  nativeState.customTargetRegistrations[targetId] =
      _TaiyinCustomTargetRegistration(registeredPosition, stateCallable);
  return target;
}

NativeCallable<taiyin_native_position_evaluator_fnFunction>
_createCustomPositionCallable(
  TaiyinCustomPositionEvaluator evaluator,
  int dependencyPositionAddress,
) {
  final frozenEvaluator = evaluator;
  final frozenDependencyPositionAddress = dependencyPositionAddress;
  final callable =
      NativeCallable<
        taiyin_native_position_evaluator_fnFunction
      >.isolateGroupBound((
        Pointer<taiyin_context> context,
        int callbackTargetId,
        double jdTdb,
        double jdTt,
        int flags,
        Pointer<Double> output,
        Pointer<taiyin_ephemeris_diagnostic> diagnostic,
        Pointer<Void> userData,
      ) {
        if (output == nullptr) return _taiyinErrorInvalidArgument;
        for (var index = 0; index < 6; index++) {
          output[index] = 0;
        }
        try {
          final values = frozenEvaluator(
            TaiyinCustomTargetRequest._(
              target: TaiyinCustomTarget(callbackTargetId),
              julianDateTdb: jdTdb,
              julianDateTt: jdTt,
              rawFlags: flags,
              context: context,
              dependencyPosition:
                  Pointer<
                    NativeFunction<_NativeCustomDependencyPosition>
                  >.fromAddress(frozenDependencyPositionAddress),
            ),
          );
          if (values.length != 6 || values.any((value) => !value.isFinite)) {
            _finishCustomDiagnostic(
              diagnostic,
              _taiyinErrorInvalidArgument,
              callbackTargetId,
              jdTdb,
            );
            return _taiyinErrorInvalidArgument;
          }
          for (var index = 0; index < 6; index++) {
            output[index] = values[index];
          }
          _finishCustomDiagnostic(
            diagnostic,
            _taiyinStatusOk,
            callbackTargetId,
            jdTdb,
          );
          return _taiyinStatusOk;
        } on TaiyinCustomEvaluatorFailure catch (error) {
          final status = error.status == 0
              ? _taiyinErrorInvalidArgument
              : error.status;
          _finishCustomDiagnostic(diagnostic, status, callbackTargetId, jdTdb);
          return status;
        } catch (_) {
          _finishCustomDiagnostic(
            diagnostic,
            _taiyinErrorInternal,
            callbackTargetId,
            jdTdb,
          );
          return _taiyinErrorInternal;
        }
      }, exceptionalReturn: _taiyinErrorInternal);
  callable.keepIsolateAlive = false;
  return callable;
}

NativeCallable<taiyin_native_state_evaluator_fnFunction>
_createCustomStateCallable(
  TaiyinCustomStateEvaluator evaluator,
  int dependencyPositionAddress,
) {
  final frozenEvaluator = evaluator;
  final frozenDependencyPositionAddress = dependencyPositionAddress;
  final callable =
      NativeCallable<
        taiyin_native_state_evaluator_fnFunction
      >.isolateGroupBound((
        Pointer<taiyin_context> context,
        int callbackTargetId,
        double jdTdb,
        double jdTt,
        int flags,
        Pointer<taiyin_cartesian_state> output,
        Pointer<taiyin_ephemeris_diagnostic> diagnostic,
        Pointer<Void> userData,
      ) {
        if (output == nullptr) return _taiyinErrorInvalidArgument;
        try {
          final state = frozenEvaluator(
            TaiyinCustomTargetRequest._(
              target: TaiyinCustomTarget(callbackTargetId),
              julianDateTdb: jdTdb,
              julianDateTt: jdTt,
              rawFlags: flags,
              context: context,
              dependencyPosition:
                  Pointer<
                    NativeFunction<_NativeCustomDependencyPosition>
                  >.fromAddress(frozenDependencyPositionAddress),
            ),
          );
          if (!_isFiniteCustomState(state)) {
            _finishCustomDiagnostic(
              diagnostic,
              _taiyinErrorInvalidArgument,
              callbackTargetId,
              jdTdb,
            );
            return _taiyinErrorInvalidArgument;
          }
          _writeCustomState(output, state);
          _finishCustomDiagnostic(
            diagnostic,
            _taiyinStatusOk,
            callbackTargetId,
            jdTdb,
          );
          return _taiyinStatusOk;
        } on TaiyinCustomEvaluatorFailure catch (error) {
          final status = error.status == 0
              ? _taiyinErrorInvalidArgument
              : error.status;
          _finishCustomDiagnostic(diagnostic, status, callbackTargetId, jdTdb);
          return status;
        } catch (_) {
          _finishCustomDiagnostic(
            diagnostic,
            _taiyinErrorInternal,
            callbackTargetId,
            jdTdb,
          );
          return _taiyinErrorInternal;
        }
      }, exceptionalReturn: _taiyinErrorInternal);
  callable.keepIsolateAlive = false;
  return callable;
}

void _finishCustomDiagnostic(
  Pointer<taiyin_ephemeris_diagnostic> diagnostic,
  int status,
  int targetId,
  double jdTdb,
) {
  if (diagnostic == nullptr) return;
  diagnostic.ref
    ..status = status
    ..target_id = targetId
    ..jd_tdb = jdTdb;
}

bool _isFiniteCustomState(TaiyinCartesianState state) {
  return <TaiyinVector3>[
    state.positionAu,
    state.velocityAuPerDay,
    state.accelerationAuPerDay2,
  ].every(
    (vector) => vector.x.isFinite && vector.y.isFinite && vector.z.isFinite,
  );
}

void _writeCustomState(
  Pointer<taiyin_cartesian_state> output,
  TaiyinCartesianState state,
) {
  output.ref
    ..position_au.x = state.positionAu.x
    ..position_au.y = state.positionAu.y
    ..position_au.z = state.positionAu.z
    ..velocity_au_per_day.x = state.velocityAuPerDay.x
    ..velocity_au_per_day.y = state.velocityAuPerDay.y
    ..velocity_au_per_day.z = state.velocityAuPerDay.z
    ..acceleration_au_per_day2.x = state.accelerationAuPerDay2.x
    ..acceleration_au_per_day2.y = state.accelerationAuPerDay2.y
    ..acceleration_au_per_day2.z = state.accelerationAuPerDay2.z;
}
