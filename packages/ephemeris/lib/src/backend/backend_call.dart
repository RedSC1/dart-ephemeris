import '../position/position_models.dart';
import '../result_flags.dart';

/// Internal, platform-independent result of one backend operation.
///
/// This boundary carries Dart data, never FFI pointers, Wasm addresses, arenas,
/// packed native return words, or views into backend-owned memory.
final class BackendCall<T> {
  BackendCall({
    required this.status,
    required this.flags,
    required T? value,
    this.diagnostic,
    Iterable<EphemerisDiagnostic> diagnostics = const [],
  }) : _value = value,
       diagnostics = diagnostics.isEmpty
           ? const []
           : List.unmodifiable(diagnostics);

  final int status;
  final ResultFlags flags;
  final T? _value;

  /// Only consume after the owning facade has checked [status]. Failures do
  /// not need to fabricate a valid astronomical value merely to carry errors.
  T get value => _value as T;
  final EphemerisDiagnostic? diagnostic;
  final List<EphemerisDiagnostic> diagnostics;

  BackendCall<T> withDiagnostic(EphemerisDiagnostic? primary) => BackendCall(
    status: status,
    flags: flags,
    value: _value,
    diagnostic: primary,
    diagnostics: diagnostics,
  );
}

/// Publishes a call's diagnostic/flags and throws the owning runtime's typed
/// exception on failure. A shared API facade calls this before using a value.
typedef BackendCallCompletion = void Function(BackendCall<Object?> call);
