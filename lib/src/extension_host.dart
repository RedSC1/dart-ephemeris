part of 'taiyin.dart';

/// FFI handle exposed by core Taiyin objects for the official extension
/// packages (`package:taiyin_bazi`, `package:taiyin_ziwei`).
///
/// This surface exists so the sibling extension packages can share one loaded
/// native library with `package:taiyin`. Its shape tracks the native ABI and
/// may change without a major version bump of `package:taiyin`.
final class TaiyinExtensionHost {
  TaiyinExtensionHost._(
    this._state,
    this._nativeHandle,
    this._onEnsureOpen,
    this._onDiagnostic,
    this._onComplete,
  );

  /// Opens the native library without initializing the process-wide runtime,
  /// for extension handles that need no astronomy context (for example Ziwei
  /// rule-catalog loading).
  factory TaiyinExtensionHost.open({String? libraryPath}) {
    final state = _nativeLibraryStateFor(_openLibrary(libraryPath));
    return TaiyinExtensionHost._(
      state,
      nullptr,
      () {},
      (_) {},
      (rawResult, {diagnostic, diagnostics = const []}) => _checkStatus(
        state.bindings,
        rawResult,
        diagnostic: diagnostic,
        diagnostics: diagnostics,
      ),
    );
  }

  final _NativeLibraryState _state;
  final Pointer<Void> _nativeHandle;
  final void Function() _onEnsureOpen;
  final void Function(EphemerisDiagnostic) _onDiagnostic;
  final ResultFlags Function(
    int rawResult, {
    EphemerisDiagnostic? diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics,
  })
  _onComplete;

  /// The generated bindings for the loaded library.
  TaiyinBindings get bindings => _state.bindings;

  /// The loaded dynamic library.
  DynamicLibrary get library => _state._library;

  /// The capability mask reported by the loaded library.
  int get capabilities => _state.capabilities;

  /// The raw native handle of the source object (astronomy or calendar
  /// context). It is `nullptr` for hosts created by [TaiyinExtensionHost.open].
  Pointer<T> nativeHandle<T extends NativeType>() => _nativeHandle.cast();

  /// Whether the loaded library reports [capabilityMask].
  bool supports(int capabilityMask) => (capabilities & capabilityMask) != 0;

  /// Throws [StateError] when the source object has been closed.
  void ensureOpen() => _onEnsureOpen();

  /// A finalizer keyed by the destroy [symbol], or null when
  /// [capabilityMask] is absent — in which case the symbol must never be
  /// looked up because the build does not export it.
  NativeFinalizer? finalizerFor(String symbol, {required int capability}) {
    if (!supports(capability)) return null;
    return NativeFinalizer(
      library.lookup<NativeFunction<Void Function(Pointer<Void>)>>(symbol),
    );
  }

  /// Throws [EphemerisError] when [status] is not `TAIYIN_STATUS_OK`.
  ResultFlags checkStatus(
    int rawResult, {
    EphemerisDiagnostic? diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics = const [],
  }) =>
      _onComplete(rawResult, diagnostic: diagnostic, diagnostics: diagnostics);

  /// Maps a native diagnostic struct to its Dart form.
  EphemerisDiagnostic readDiagnostic(taiyin_ephemeris_diagnostic value) =>
      _readEphemerisDiagnostic(value);

  /// Publishes a diagnostic snapshot on the owning [EphemerisContext]
  /// ([EphemerisContext.lastDiagnostic]); a no-op for hosts created by
  /// [TaiyinExtensionHost.open].
  void recordDiagnostic(EphemerisDiagnostic diagnostic) =>
      _onDiagnostic(diagnostic);
}
