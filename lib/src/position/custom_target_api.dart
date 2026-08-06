part of '../taiyin.dart';

const int _taiyinStatusOk = 0;
const int _taiyinErrorInvalidArgument = -1;
const int _taiyinErrorInternal = -3;

typedef _NativeCustomDependencyPosition =
    taiyin_status Function(
      Pointer<taiyin_context>,
      Int32,
      Pointer<taiyin_split_julian_date>,
      Pointer<taiyin_split_julian_date>,
      Uint32,
      Pointer<Double>,
      Pointer<taiyin_ephemeris_diagnostic>,
    );
typedef _DartCustomDependencyPosition =
    int Function(
      Pointer<taiyin_context>,
      int,
      Pointer<taiyin_split_julian_date>,
      Pointer<taiyin_split_julian_date>,
      int,
      Pointer<Double>,
      Pointer<taiyin_ephemeris_diagnostic>,
    );

final class _CustomTargetRequestScope {
  bool isActive = true;

  void invalidate() {
    isActive = false;
  }
}

/// Inputs supplied by Ephemeris when evaluating a custom target.
///
/// A request borrows its native calculation context and is valid only for the
/// duration of the evaluator call.
final class CustomTargetRequest {
  const CustomTargetRequest._({
    required this.target,
    required this.julianDateTdb,
    required this.julianDateTt,
    required this.rawFlags,
    required Pointer<taiyin_context> context,
    required Pointer<NativeFunction<_NativeCustomDependencyPosition>>
    dependencyPosition,
    required _CustomTargetRequestScope scope,
  }) : _context = context,
       _dependencyPosition = dependencyPosition,
       _scope = scope;

  final CustomTarget target;
  final JulianDate<TdbScale> julianDateTdb;
  final JulianDate<TtScale> julianDateTt;
  final int rawFlags;
  final Pointer<taiyin_context> _context;
  final Pointer<NativeFunction<_NativeCustomDependencyPosition>>
  _dependencyPosition;
  final _CustomTargetRequestScope _scope;

  Set<PositionFlag> get flags => Set.unmodifiable({
    for (final flag in PositionFlag.values)
      if ((rawFlags & flag.mask) != 0) flag,
  });

  bool hasFlag(PositionFlag flag) => (rawFlags & flag.mask) != 0;

  /// Calculates another target with the borrowed context and callback epoch.
  ///
  /// A native failure is rethrown as [CustomEvaluatorFailure], so it
  /// automatically becomes the custom evaluator's status unless caught.
  List<double> positionOf(
    Target dependency, {
    Set<PositionFlag> flags = const {},
  }) {
    if (!_scope.isActive) {
      throw StateError(
        'This CustomTargetRequest is no longer valid. '
        'positionOf() may only be called synchronously while its evaluator '
        'is running.',
      );
    }
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
        writeJulianDate(arena, julianDateTdb),
        writeJulianDate(arena, julianDateTt),
        mask,
        output,
        diagnostic,
      );
      if (status != _taiyinStatusOk) {
        throw CustomEvaluatorFailure(status);
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
/// [CustomTargetRequest.flags].
typedef CustomPositionEvaluator =
    List<double> Function(CustomTargetRequest request);

/// Calculates an exact Cartesian state for a custom target.
///
/// When omitted during registration, Ephemeris derives the state with its native
/// finite-difference fallback.
typedef CustomStateEvaluator =
    CartesianState Function(CustomTargetRequest request);

/// A deliberate non-success status returned by a custom target evaluator.
final class CustomEvaluatorFailure implements Exception {
  const CustomEvaluatorFailure(this.status)
    : assert(status != 0, 'A failure status must be non-zero.');

  final int status;

  @override
  String toString() => 'CustomEvaluatorFailure($status)';
}

/// Owns one process-wide Dart-backed custom-target registration.
///
/// Call [close] before discarding the registration. Closing first removes the
/// native callback pointers and only then releases the Dart callbacks.
final class CustomTargetRegistration {
  CustomTargetRegistration._(
    this.target,
    this._nativeState,
    this._position,
    this._state,
  );

  final CustomTarget target;
  final _NativeLibraryState _nativeState;
  final NativeCallable<taiyin_native_position_evaluator_fnFunction> _position;
  final NativeCallable<taiyin_native_state_evaluator_fnFunction>? _state;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Unregisters this target and releases its Dart callbacks.
  ///
  /// Calling this more than once is safe. This setup-time operation must not
  /// overlap calculations in any isolate.
  void close() {
    if (_closed) return;
    final status = _nativeState.bindings
        .taiyin_unregister_native_position_evaluator(target.id);
    // Another process-wide runtime reset may already have removed the native
    // pointer. In that case it is safe and necessary to release this isolate's
    // remaining Dart callable.
    if (status != _taiyinStatusOk && status != _taiyinErrorInvalidArgument) {
      _checkStatus(_nativeState.bindings, status);
    }
    _closeAfterNativeClear();
  }

  void _closeAfterNativeClear() {
    if (_closed) return;
    _closed = true;
    if (identical(_nativeState.customTargetRegistrations[target.id], this)) {
      _nativeState.customTargetRegistrations.remove(target.id);
    }
    _state?.close();
    _position.close();
  }
}

CustomTargetRegistration _registerCustomTarget(
  DynamicLibrary library,
  _NativeLibraryState nativeState,
  int targetId,
  CustomPositionEvaluator positionEvaluator,
  CustomStateEvaluator? stateEvaluator,
) {
  final target = CustomTarget(targetId);
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

  final registration = CustomTargetRegistration._(
    target,
    nativeState,
    registeredPosition,
    stateCallable,
  );
  nativeState.customTargetRegistrations[targetId] = registration;
  return registration;
}

void _closeCustomTargetRegistrationsAfterNativeClear(
  _NativeLibraryState nativeState,
) {
  final registrations = nativeState.customTargetRegistrations.values.toList();
  nativeState.customTargetRegistrations.clear();
  for (final registration in registrations) {
    registration._closeAfterNativeClear();
  }
}

NativeCallable<taiyin_native_position_evaluator_fnFunction>
_createCustomPositionCallable(
  CustomPositionEvaluator evaluator,
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
        Pointer<taiyin_split_julian_date> jdTdb,
        Pointer<taiyin_split_julian_date> jdTt,
        int flags,
        Pointer<Double> output,
        Pointer<taiyin_ephemeris_diagnostic> diagnostic,
        Pointer<Void> userData,
      ) {
        if (output == nullptr) return _taiyinErrorInvalidArgument;
        for (var index = 0; index < 6; index++) {
          output[index] = 0;
        }
        final requestScope = _CustomTargetRequestScope();
        try {
          final values = frozenEvaluator(
            CustomTargetRequest._(
              target: CustomTarget(callbackTargetId),
              julianDateTdb: readJulianDate<TdbScale>(jdTdb.ref),
              julianDateTt: readJulianDate<TtScale>(jdTt.ref),
              rawFlags: flags,
              context: context,
              dependencyPosition:
                  Pointer<
                    NativeFunction<_NativeCustomDependencyPosition>
                  >.fromAddress(frozenDependencyPositionAddress),
              scope: requestScope,
            ),
          );
          if (values.length != 6 || values.any((value) => !value.isFinite)) {
            _finishCustomDiagnostic(
              diagnostic,
              _taiyinErrorInvalidArgument,
              callbackTargetId,
              readJulianDate<TdbScale>(jdTdb.ref),
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
            readJulianDate<TdbScale>(jdTdb.ref),
          );
          return _taiyinStatusOk;
        } on CustomEvaluatorFailure catch (error) {
          final status = error.status == 0
              ? _taiyinErrorInvalidArgument
              : error.status;
          _finishCustomDiagnostic(
            diagnostic,
            status,
            callbackTargetId,
            readJulianDate<TdbScale>(jdTdb.ref),
          );
          return status;
        } catch (_) {
          _finishCustomDiagnostic(
            diagnostic,
            _taiyinErrorInternal,
            callbackTargetId,
            readJulianDate<TdbScale>(jdTdb.ref),
          );
          return _taiyinErrorInternal;
        } finally {
          requestScope.invalidate();
        }
      }, exceptionalReturn: _taiyinErrorInternal);
  return callable;
}

NativeCallable<taiyin_native_state_evaluator_fnFunction>
_createCustomStateCallable(
  CustomStateEvaluator evaluator,
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
        Pointer<taiyin_split_julian_date> jdTdb,
        Pointer<taiyin_split_julian_date> jdTt,
        int flags,
        Pointer<taiyin_cartesian_state> output,
        Pointer<taiyin_ephemeris_diagnostic> diagnostic,
        Pointer<Void> userData,
      ) {
        if (output == nullptr) return _taiyinErrorInvalidArgument;
        final requestScope = _CustomTargetRequestScope();
        try {
          final state = frozenEvaluator(
            CustomTargetRequest._(
              target: CustomTarget(callbackTargetId),
              julianDateTdb: readJulianDate<TdbScale>(jdTdb.ref),
              julianDateTt: readJulianDate<TtScale>(jdTt.ref),
              rawFlags: flags,
              context: context,
              dependencyPosition:
                  Pointer<
                    NativeFunction<_NativeCustomDependencyPosition>
                  >.fromAddress(frozenDependencyPositionAddress),
              scope: requestScope,
            ),
          );
          if (!_isFiniteCustomState(state)) {
            _finishCustomDiagnostic(
              diagnostic,
              _taiyinErrorInvalidArgument,
              callbackTargetId,
              readJulianDate<TdbScale>(jdTdb.ref),
            );
            return _taiyinErrorInvalidArgument;
          }
          _writeCustomState(output, state);
          _finishCustomDiagnostic(
            diagnostic,
            _taiyinStatusOk,
            callbackTargetId,
            readJulianDate<TdbScale>(jdTdb.ref),
          );
          return _taiyinStatusOk;
        } on CustomEvaluatorFailure catch (error) {
          final status = error.status == 0
              ? _taiyinErrorInvalidArgument
              : error.status;
          _finishCustomDiagnostic(
            diagnostic,
            status,
            callbackTargetId,
            readJulianDate<TdbScale>(jdTdb.ref),
          );
          return status;
        } catch (_) {
          _finishCustomDiagnostic(
            diagnostic,
            _taiyinErrorInternal,
            callbackTargetId,
            readJulianDate<TdbScale>(jdTdb.ref),
          );
          return _taiyinErrorInternal;
        } finally {
          requestScope.invalidate();
        }
      }, exceptionalReturn: _taiyinErrorInternal);
  return callable;
}

void _finishCustomDiagnostic(
  Pointer<taiyin_ephemeris_diagnostic> diagnostic,
  int status,
  int targetId,
  JulianDate<TdbScale> jdTdb,
) {
  if (diagnostic == nullptr) return;
  diagnostic.ref
    ..status = status
    ..target_id = targetId
    ..center_id = -1
    ..frame = -1
    ..jd_tdb.day_number = jdTdb.dayNumber
    ..jd_tdb.day_fraction = jdTdb.dayFraction;
  diagnostic.ref
    ..attempted_method_id = -1
    ..component_target_id = -1
    ..component_center_id = -1
    ..component_method_id = -1;
}

bool _isFiniteCustomState(CartesianState state) {
  return <Vector3>[
    state.positionAu,
    state.velocityAuPerDay,
    state.accelerationAuPerDay2,
  ].every(
    (vector) => vector.x.isFinite && vector.y.isFinite && vector.z.isFinite,
  );
}

void _writeCustomState(
  Pointer<taiyin_cartesian_state> output,
  CartesianState state,
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
