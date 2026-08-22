part of 'taiyin.dart';

/// FFI handle exposed by core Taiyin objects for the official extension
/// packages (`package:ephemeris_bazi`, `package:ephemeris_ziwei`).
///
/// This surface exists so sibling extension packages can reuse the owning core
/// context, status decoder, and diagnostic sink. Extension entry points live
/// in their own native modules and are loaded through [TaiyinExtensionModule].
/// Its shape tracks the native ABI and may change without a major version bump
/// of `package:ephemeris`.
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

  /// The raw native handle of the source object (astronomy or calendar
  /// context). It is `nullptr` for hosts created by [TaiyinExtensionHost.open].
  Pointer<T> nativeHandle<T extends NativeType>() => _nativeHandle.cast();

  /// Throws [StateError] when the source object has been closed.
  void ensureOpen() => _onEnsureOpen();

  /// Throws [EphemerisError] when [rawResult] contains a failure status.
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

/// One separately packaged official native extension module.
///
/// The module is resolved lazily in the current isolate. An explicit
/// [libraryPath] wins, followed by [environmentVariable], the package-bundled
/// `lib/native/` asset, and finally the platform loader search path.
final class TaiyinExtensionModule {
  TaiyinExtensionModule._(this._state);

  factory TaiyinExtensionModule.open({
    required String packageName,
    required String environmentVariable,
    required String libraryBaseName,
    required String identitySymbol,
    required Set<String> requiredSymbols,
    String? libraryPath,
  }) {
    try {
      final library = _openExtensionLibrary(
        packageName: packageName,
        environmentVariable: environmentVariable,
        libraryBaseName: libraryBaseName,
        libraryPath: libraryPath,
      );
      final identity = library
          .lookup<NativeFunction<Void Function(Pointer<Void>)>>(identitySymbol);
      final state = _extensionModuleStates.putIfAbsent(identity.address, () {
        validateTaiyinRequiredSymbols(
          providesSymbol: library.providesSymbol,
          requiredSymbols: requiredSymbols,
        );
        return _ExtensionModuleState(TaiyinBindings(library), library);
      });
      return TaiyinExtensionModule._(state);
    } on ArgumentError catch (error) {
      throw UnsupportedError(
        'Unable to load the $packageName native extension '
        '($libraryBaseName): $error',
      );
    }
  }

  final _ExtensionModuleState _state;

  /// Generated ABI bindings backed by this extension library.
  TaiyinBindings get bindings => _state.bindings;

  /// Loaded extension dynamic library.
  DynamicLibrary get library => _state.library;

  /// Creates a finalizer from an extension-owned destroy function.
  NativeFinalizer finalizerFor(String symbol) => NativeFinalizer(
    library.lookup<NativeFunction<Void Function(Pointer<Void>)>>(symbol),
  );
}

final class _ExtensionModuleState {
  const _ExtensionModuleState(this.bindings, this.library);

  final TaiyinBindings bindings;
  final DynamicLibrary library;
}

// DynamicLibrary wrappers do not own an unload operation in Dart. Keep one
// binding state per loaded image/identity symbol in each isolate.
final Map<int, _ExtensionModuleState> _extensionModuleStates = {};

DynamicLibrary _openExtensionLibrary({
  required String packageName,
  required String environmentVariable,
  required String libraryBaseName,
  required String? libraryPath,
}) {
  if (Platform.isIOS) return DynamicLibrary.process();
  final configured = libraryPath ?? Platform.environment[environmentVariable];
  if (configured != null) return DynamicLibrary.open(configured);

  final fileName = _extensionLibraryFileName(libraryBaseName);
  // Only resolve a package-bundled module when this release ships a matching
  // architecture. Unsupported architectures fall through to an application-
  // supplied module on the platform loader path.
  if (_supportsBundledExtensionAbi()) {
    final resolved = Isolate.resolvePackageUriSync(
      Uri.parse('package:$packageName/native/$fileName'),
    );
    if (resolved != null && resolved.scheme == 'file') {
      final bundled = resolved.toFilePath();
      if (File(bundled).existsSync()) return DynamicLibrary.open(bundled);
    }
  }
  return DynamicLibrary.open(fileName);
}

bool _supportsBundledExtensionAbi() {
  final abi = Abi.current();
  if (Platform.isMacOS) return abi == Abi.macosArm64;
  if (Platform.isLinux) return abi == Abi.linuxX64;
  if (Platform.isWindows) return abi == Abi.windowsX64;
  return false;
}

String _extensionLibraryFileName(String baseName) {
  if (Platform.isWindows) return '$baseName.dll';
  if (Platform.isMacOS) return 'lib$baseName.dylib';
  return 'lib$baseName.so';
}
