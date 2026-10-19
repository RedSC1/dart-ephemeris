part of '../taiyin.dart';

final class _NativeStarCatalogBackend implements StarCatalogBackend {
  _NativeStarCatalogBackend(this._state);
  final _NativeLibraryState _state;
  TaiyinBindings get _bindings => _state.bindings;

  BackendCall<bool> _result(int raw) {
    final decoded = decodeNativeCallResult(raw);
    return BackendCall(
      status: decoded.status,
      flags: decoded.flags,
      value: decoded.status == 0,
    );
  }

  @override
  BackendCall<bool> addPath(String path, {required bool compiled}) =>
      using((arena) {
        final pointer = path.toNativeUtf8(allocator: arena).cast<Char>();
        return _result(
          compiled
              ? _bindings.taiyin_star_catalog_add_tsc1(pointer)
              : _bindings.taiyin_star_catalog_add_tsf1(pointer),
        );
      });
  @override
  BackendCall<bool> addBytes(Uint8List bytes, {required bool compiled}) {
    if (!compiled) {
      return _NativeRuntimeBytesBackend(
        _state,
      ).load(RuntimeByteSourceKind.starText, 'stars.tsf1', bytes);
    }
    return using((arena) {
      final pointer = arena<Uint8>(bytes.length);
      pointer.asTypedList(bytes.length).setAll(0, bytes);
      return _result(
        _bindings.taiyin_star_catalog_add_tsc1_memory(pointer, bytes.length),
      );
    });
  }

  @override
  void clear() => _bindings.taiyin_star_catalog_clear();
  @override
  int get count => _bindings.taiyin_star_catalog_count();
  @override
  BackendCall<double> magnitudeOf(String key) => using((arena) {
    final output = arena<Double>();
    final decoded = decodeNativeCallResult(
      _bindings.taiyin_star_find_magnitude(
        key.toNativeUtf8(allocator: arena).cast<Char>(),
        output,
      ),
    );
    return BackendCall(
      status: decoded.status,
      flags: decoded.flags,
      value: output.value,
    );
  });
}
