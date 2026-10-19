import 'dart:typed_data';
import '../backend/backend_call.dart';

/// Internal loading destinations. Each uses its existing C++ parser.
enum RuntimeByteSourceKind { ephemeris, earthOrientation, lunarLimb, starText }

/// Owns backend storage and registration, not astronomical calculation logic.
abstract interface class RuntimeBytesBackend {
  BackendCall<bool> load(
    RuntimeByteSourceKind kind,
    String name,
    Uint8List bytes,
  );
}

/// Shared validation and API semantics, independent of native/virtual paths.
final class RuntimeBytesLoader {
  RuntimeBytesLoader.internal(this._backend, this._complete);
  final RuntimeBytesBackend _backend;
  final BackendCallCompletion _complete;

  void addSourceBytes(String name, Uint8List bytes) {
    validateEphemerisBytes(name, bytes);
    _complete(_backend.load(RuntimeByteSourceKind.ephemeris, name, bytes));
  }

  void loadEopTableBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'must not be empty');
    }
    _complete(
      _backend.load(
        RuntimeByteSourceKind.earthOrientation,
        'finals2000A.all',
        bytes,
      ),
    );
  }

  void loadLunarLimbModelBytes(Uint8List bytes) {
    _requireMagic('lunar-limb.tll1', bytes, 'TLL1');
    _complete(
      _backend.load(RuntimeByteSourceKind.lunarLimb, 'lunar-limb.tll1', bytes),
    );
  }
}

/// Checks only the transport envelope; C++ validates the complete contents.
void validateEphemerisBytes(String name, Uint8List bytes) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]*$').hasMatch(name)) {
    throw ArgumentError.value(name, 'name', 'must be a basename, not a path');
  }
  final suffix = name.substring(name.lastIndexOf('.') + 1);
  switch (suffix.toLowerCase()) {
    case 'opm2':
      _requireMagic(name, bytes, 'OPM2');
    case 'bsp':
    case 'spk':
      _requireMagic(name, bytes, 'DAF/SPK');
    // The original TKC1/TKE1 discoverers use case-sensitive suffixes.
    case 'tkc1':
    case 'tke1':
      if (suffix != suffix.toLowerCase()) {
        throw ArgumentError.value(name, 'name', 'use a lowercase suffix');
      }
      if (suffix == 'tkc1') {
        _requireMagic(name, bytes, 'TKC1');
      } else if (bytes.isEmpty) {
        throw ArgumentError.value(name, 'bytes', 'must not be empty');
      }
    // TKE1 is text: the C++ reader also accepts leading comments/blank lines.
    default:
      throw ArgumentError.value(
        name,
        'name',
        'expected .opm2, .bsp, .spk, .tkc1 or .tke1',
      );
  }
}

void _requireMagic(String name, Uint8List bytes, String magic) {
  if (bytes.length < magic.length ||
      !Iterable<int>.generate(
        magic.length,
      ).every((i) => bytes[i] == magic.codeUnitAt(i))) {
    throw ArgumentError.value(name, 'bytes', 'must contain $magic data');
  }
}
