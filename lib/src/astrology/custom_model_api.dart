part of '../taiyin.dart';

/// Inputs supplied by Taiyin when evaluating a custom ayanamsha model.
final class TaiyinCustomAyanamshaRequest {
  const TaiyinCustomAyanamshaRequest._({
    required this.julianDateTt,
    required this.rawFlags,
  });

  /// TT coordinate at which the model is being evaluated.
  ///
  /// The native callback ABI currently supplies a scalar Julian date, so this
  /// value has the same native calculation-boundary precision as other
  /// physical calculations.
  final JulianDate<TtScale> julianDateTt;

  /// Unmapped native position-flag bitset supplied to the evaluator.
  final int rawFlags;

  /// Recognized native position flags supplied to the evaluator.
  Set<TaiyinPositionFlag> get flags => Set.unmodifiable({
    for (final flag in TaiyinPositionFlag.values)
      if ((rawFlags & flag.mask) != 0) flag,
  });

  bool hasFlag(TaiyinPositionFlag flag) => (rawFlags & flag.mask) != 0;
}

/// Calculates an ayanamsha in radians for a custom process-wide model.
///
/// The returned value must be finite. Taiyin normalizes a successful result to
/// `[0, 2π)` before publishing it to the requesting calculation.
typedef TaiyinCustomAyanamshaEvaluator =
    double Function(TaiyinCustomAyanamshaRequest request);

/// Inputs supplied by Taiyin when evaluating a custom house-system model.
final class TaiyinCustomHouseSystemRequest {
  const TaiyinCustomHouseSystemRequest._({
    required this.armcRadians,
    required this.observerLatitudeRadians,
    required this.trueObliquityRadians,
    required this.ascendantRadians,
    required this.midheavenRadians,
  });

  /// Right ascension of the meridian in radians.
  final double armcRadians;

  /// Geodetic observer latitude in radians.
  final double observerLatitudeRadians;

  /// True obliquity of the ecliptic in radians.
  final double trueObliquityRadians;

  /// Native corrected ascendant in radians.
  final double ascendantRadians;

  /// Native corrected midheaven in radians.
  final double midheavenRadians;
}

/// Calculates twelve zero-based cusp longitudes for a custom house system.
///
/// The returned list must contain exactly twelve finite values. Taiyin applies
/// its normal cusp validation and fallback policy after this evaluator returns.
typedef TaiyinCustomHouseSystemEvaluator =
    List<double> Function(TaiyinCustomHouseSystemRequest request);

/// Owns one process-wide Dart-backed custom ayanamsha registration.
///
/// Call [close] before discarding the registration. Closing first removes the
/// native callback pointer and only then releases the Dart callback.
final class TaiyinCustomAyanamshaRegistration {
  TaiyinCustomAyanamshaRegistration._(
    this.model,
    this._nativeState,
    this._callable,
    this._registrationToken,
  );

  final TaiyinCustomAyanamshaModel model;
  final _TaiyinNativeLibraryState _nativeState;
  final NativeCallable<taiyin_ayanamsha_evaluator_fnFunction> _callable;
  final int _registrationToken;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Unregisters this model and releases its Dart callback.
  ///
  /// Calling this more than once is safe. This setup-time operation must not
  /// overlap calculations in any isolate.
  void close() {
    if (_closed) return;
    final status = _nativeState.bindings
        .taiyin_unregister_ayanamsha_model_with_token(
          model.id,
          _registrationToken,
        );
    // A process-wide runtime reset, C-API clear, or replacement by another
    // isolate can remove this token first. A token mismatch cannot affect the
    // newer same-ID model, so releasing this isolate's callable is safe.
    if (status != _taiyinStatusOk && status != _taiyinErrorInvalidArgument) {
      _checkStatus(_nativeState.bindings, status);
    }
    _closeAfterNativeClear();
  }

  void _closeAfterNativeClear() {
    if (_closed) return;
    _closed = true;
    if (identical(_nativeState.customAyanamshaRegistrations[model.id], this)) {
      _nativeState.customAyanamshaRegistrations.remove(model.id);
    }
    _callable.close();
  }
}

/// Owns one process-wide Dart-backed custom house-system registration.
///
/// Call [close] before discarding the registration. Closing first removes the
/// native callback pointer and only then releases the Dart callback.
final class TaiyinCustomHouseSystemRegistration {
  TaiyinCustomHouseSystemRegistration._(
    this.model,
    this._nativeState,
    this._callable,
    this._registrationToken,
  );

  final TaiyinCustomHouseSystemModel model;
  final _TaiyinNativeLibraryState _nativeState;
  final NativeCallable<taiyin_house_system_evaluator_fnFunction> _callable;
  final int _registrationToken;
  bool _closed = false;

  bool get isClosed => _closed;

  /// Unregisters this model and releases its Dart callback.
  ///
  /// Calling this more than once is safe. This setup-time operation must not
  /// overlap calculations in any isolate.
  void close() {
    if (_closed) return;
    final status = _nativeState.bindings
        .taiyin_unregister_house_system_model_with_token(
          model.id,
          _registrationToken,
        );
    // See the ayanamsha variant for why INVALID_ARGUMENT is safe here. An
    // UNSUPPORTED result means a live dependent still selects this model as a
    // fallback, so retain the callback and let the caller remove dependents.
    if (status != _taiyinStatusOk && status != _taiyinErrorInvalidArgument) {
      _checkStatus(_nativeState.bindings, status);
    }
    _closeAfterNativeClear();
  }

  void _closeAfterNativeClear() {
    if (_closed) return;
    _closed = true;
    if (identical(
      _nativeState.customHouseSystemRegistrations[model.id],
      this,
    )) {
      _nativeState.customHouseSystemRegistrations.remove(model.id);
    }
    _callable.close();
  }
}

TaiyinCustomAyanamshaRegistration _registerCustomAyanamshaModel(
  _TaiyinNativeLibraryState nativeState,
  int modelId,
  TaiyinCustomAyanamshaEvaluator evaluator,
  TaiyinPrecessionModel? referencePrecessionModel,
) {
  final model = TaiyinCustomAyanamshaModel(modelId);
  if (nativeState.customAyanamshaRegistrations.containsKey(model.id)) {
    throw ArgumentError.value(
      modelId,
      'modelId',
      'has already been registered in this process',
    );
  }
  final callable = _createCustomAyanamshaCallable(evaluator);
  var registrationToken = 0;
  final int status;
  try {
    status = using((arena) {
      final outRegistrationToken = arena<Uint64>();
      final result = nativeState.bindings
          .taiyin_register_ayanamsha_model_with_token(
            model.id,
            callable.nativeFunction,
            referencePrecessionModel?.id ?? -1,
            nullptr,
            outRegistrationToken,
          );
      registrationToken = outRegistrationToken.value;
      return result;
    });
  } catch (_) {
    callable.close();
    rethrow;
  }
  if (status != _taiyinStatusOk) {
    callable.close();
    _checkStatus(nativeState.bindings, status);
  }
  if (registrationToken == 0) {
    callable.close();
    throw StateError('Taiyin returned an invalid custom ayanamsha token.');
  }
  final registration = TaiyinCustomAyanamshaRegistration._(
    model,
    nativeState,
    callable,
    registrationToken,
  );
  nativeState.customAyanamshaRegistrations[model.id] = registration;
  return registration;
}

TaiyinCustomHouseSystemRegistration _registerCustomHouseSystemModel(
  _TaiyinNativeLibraryState nativeState,
  int modelId,
  TaiyinCustomHouseSystemEvaluator evaluator,
  TaiyinHouseSystemModel? fallback,
) {
  final model = TaiyinCustomHouseSystemModel(modelId);
  if (nativeState.customHouseSystemRegistrations.containsKey(model.id)) {
    throw ArgumentError.value(
      modelId,
      'modelId',
      'has already been registered in this process',
    );
  }
  if (fallback?.id == model.id) {
    throw ArgumentError.value(
      fallback,
      'fallback',
      'must not identify the model being registered',
    );
  }
  final callable = _createCustomHouseSystemCallable(evaluator);
  var registrationToken = 0;
  final int status;
  try {
    status = using((arena) {
      final outRegistrationToken = arena<Uint64>();
      final result = nativeState.bindings
          .taiyin_register_house_system_model_with_token(
            model.id,
            callable.nativeFunction,
            fallback?.id ?? -1,
            nullptr,
            outRegistrationToken,
          );
      registrationToken = outRegistrationToken.value;
      return result;
    });
  } catch (_) {
    callable.close();
    rethrow;
  }
  if (status != _taiyinStatusOk) {
    callable.close();
    _checkStatus(nativeState.bindings, status);
  }
  if (registrationToken == 0) {
    callable.close();
    throw StateError('Taiyin returned an invalid custom house-system token.');
  }
  final registration = TaiyinCustomHouseSystemRegistration._(
    model,
    nativeState,
    callable,
    registrationToken,
  );
  nativeState.customHouseSystemRegistrations[model.id] = registration;
  return registration;
}

void _closeCustomAyanamshaRegistrationsAfterNativeClear(
  _TaiyinNativeLibraryState nativeState,
) {
  final registrations = nativeState.customAyanamshaRegistrations.values
      .toList();
  nativeState.customAyanamshaRegistrations.clear();
  for (final registration in registrations) {
    registration._closeAfterNativeClear();
  }
}

void _closeCustomHouseSystemRegistrationsAfterNativeClear(
  _TaiyinNativeLibraryState nativeState,
) {
  final registrations = nativeState.customHouseSystemRegistrations.values
      .toList();
  nativeState.customHouseSystemRegistrations.clear();
  for (final registration in registrations) {
    registration._closeAfterNativeClear();
  }
}

NativeCallable<taiyin_ayanamsha_evaluator_fnFunction>
_createCustomAyanamshaCallable(TaiyinCustomAyanamshaEvaluator evaluator) {
  final frozenEvaluator = evaluator;
  return NativeCallable<
    taiyin_ayanamsha_evaluator_fnFunction
  >.isolateGroupBound((
    Pointer<taiyin_context> context,
    Pointer<taiyin_split_julian_date> jdTt,
    int rawFlags,
    Pointer<Double> output,
    Pointer<Void> userData,
  ) {
    if (output == nullptr) return _taiyinErrorInvalidArgument;
    output.value = double.nan;
    try {
      final value = frozenEvaluator(
        TaiyinCustomAyanamshaRequest._(
          julianDateTt: readJulianDate<TtScale>(jdTt.ref),
          rawFlags: rawFlags,
        ),
      );
      if (!value.isFinite) return _taiyinErrorInvalidArgument;
      output.value = value;
      return _taiyinStatusOk;
    } catch (_) {
      return _taiyinErrorInternal;
    }
  }, exceptionalReturn: _taiyinErrorInternal);
}

NativeCallable<taiyin_house_system_evaluator_fnFunction>
_createCustomHouseSystemCallable(TaiyinCustomHouseSystemEvaluator evaluator) {
  final frozenEvaluator = evaluator;
  return NativeCallable<
    taiyin_house_system_evaluator_fnFunction
  >.isolateGroupBound((
    Pointer<taiyin_house_system_dispatch_data> data,
    Pointer<Double> outputCusps,
    Pointer<Void> userData,
  ) {
    if (data == nullptr || outputCusps == nullptr) return 0;
    for (var index = 0; index < 12; index++) {
      outputCusps[index] = double.nan;
    }
    try {
      final native = data.ref;
      final cusps = frozenEvaluator(
        TaiyinCustomHouseSystemRequest._(
          armcRadians: native.armc_rad,
          observerLatitudeRadians: native.observer_latitude_rad,
          trueObliquityRadians: native.true_obliquity_rad,
          ascendantRadians: native.ascendant_rad,
          midheavenRadians: native.midheaven_rad,
        ),
      );
      if (cusps.length != 12 || cusps.any((value) => !value.isFinite)) {
        return 0;
      }
      for (var index = 0; index < 12; index++) {
        outputCusps[index] = cusps[index];
      }
      return 1;
    } catch (_) {
      return 0;
    }
  }, exceptionalReturn: 0);
}
