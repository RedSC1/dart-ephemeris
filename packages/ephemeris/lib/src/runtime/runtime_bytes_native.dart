part of '../taiyin.dart';

/// Native storage/registration only; byte API validation is platform-neutral.
final class _NativeRuntimeBytesBackend implements RuntimeBytesBackend {
  _NativeRuntimeBytesBackend(this.state);
  final _NativeLibraryState state;

  @override
  BackendCall<bool> load(
    RuntimeByteSourceKind kind,
    String name,
    Uint8List bytes,
  ) {
    final source = kind == RuntimeByteSourceKind.ephemeris;
    if (source && state.byteSources.contains(name.toLowerCase())) {
      throw StateError('Byte source already registered: $name');
    }
    final directory = state.byteSourceDirectory ??= Directory.systemTemp
        .createTempSync('ephemeris-bytes-');
    final group = source
        ? 'ephemeris'
        : '${kind.name}-${state.byteSourceSequence++}';
    final parent = Directory('${directory.path}${Platform.pathSeparator}$group')
      ..createSync();
    final file = File('${parent.path}${Platform.pathSeparator}$name');
    try {
      file.writeAsBytesSync(bytes, flush: true);
      final raw = using((arena) {
        final path = file.path.toNativeUtf8(allocator: arena).cast<Char>();
        return switch (kind) {
          RuntimeByteSourceKind.ephemeris =>
            state.bindings.taiyin_runtime_add_source_path(path),
          RuntimeByteSourceKind.earthOrientation =>
            state.bindings.taiyin_runtime_load_eop_table(path),
          RuntimeByteSourceKind.lunarLimb =>
            state.bindings.taiyin_runtime_load_lunar_limb_model(path),
          RuntimeByteSourceKind.starText =>
            state.bindings.taiyin_star_catalog_add_tsf1(path),
        };
      });
      final decoded = decodeNativeCallResult(raw);
      if (decoded.status == 0) {
        if (source) state.byteSources.add(name.toLowerCase());
      } else {
        file.deleteSync();
      }
      return BackendCall(
        status: decoded.status,
        flags: decoded.flags,
        value: decoded.status == 0,
      );
    } catch (_) {
      if (file.existsSync()) file.deleteSync();
      rethrow;
    }
  }
}
