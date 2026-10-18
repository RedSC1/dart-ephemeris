// These members deliberately preserve Emscripten's exported JS symbol names.
// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('createTaiyinModule')
external JSPromise<WasmModule> _createModule();

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Script createElement(String tag);
  external _Head get head;
}

extension type _Head(JSObject _) implements JSObject {
  external void appendChild(JSObject node);
}

extension type _Script(JSObject _) implements JSObject {
  external set src(String value);
  external set onload(JSFunction value);
  external set onerror(JSFunction value);
  external void remove();
}

/// The version-1 wasm32 transport module, intentionally independent of FFI.
extension type WasmModule(JSObject _) implements JSObject {
  external set taiyinBaziPredicate(JSFunction value);
  external int _malloc(int bytes);
  external void _free(int pointer);
  external JSFloat64Array get HEAPF64;
  external JSUint8Array get HEAPU8;
  external WasmFileSystem get FS;
  external String UTF8ToString(int pointer);
  external void stringToUTF8(String value, int pointer, int size);
  external int lengthBytesUTF8(String value);
  external int _taiyin_web_bridge_version();
  external int _taiyin_web_solar_time(
    int context,
    int operation,
    int input,
    int output,
  );
  external int _taiyin_get_c_abi_version();
  external int _taiyin_get_library_version();
  external int _taiyin_get_library_codename();
  external int _taiyin_status_name(int status);
  external int _taiyin_status_message(int status);
  external int _taiyin_status_category(int status);
  external int _taiyin_web_initialize(int input, int output);
  external int _taiyin_web_load_file(int kind, int path, int output);
  external int _taiyin_web_resource(int operation, int output);
  external int _taiyin_web_star_memory(int bytes, int length, int output);
  external int _taiyin_web_star_magnitude(int key, int output);
  external int _taiyin_web_context_create(int output);
  external int _taiyin_web_context_clone(int context, int output);
  external void _taiyin_context_destroy(int context);
  external int _taiyin_web_position(
    int context,
    int state,
    int input,
    int output,
  );
  external int _taiyin_web_positions(
    int context,
    int count,
    int input,
    int output,
  );
  external int _taiyin_web_configure(
    int context,
    int operation,
    int input,
    int output,
  );
  external int _taiyin_web_time(
    int context,
    int operation,
    int input,
    int output,
  );
  external int _taiyin_web_calendar_create(int context, int input, int output);
  external int _taiyin_web_calendar(
    int context,
    int operation,
    int input,
    int output,
  );
  external void _taiyin_chinese_calendar_context_destroy(int context);
  external int _taiyin_web_eclipse(
    int context,
    int operation,
    int input,
    int count,
  );
  external int _taiyin_web_eclipse_length(int reply);
  external int _taiyin_web_bazi(
    int context,
    int calendar,
    int operation,
    int input,
    int count,
  );
  external int _taiyin_web_ziwei(
    int context,
    int chart,
    int calendar,
    int operation,
    int input,
    int count,
  );
  external void _taiyin_bazi_context_destroy(int context);
  external int _taiyin_web_eclipse_data(int reply);
  external void _taiyin_web_eclipse_destroy(int reply);
}

extension type WasmFileSystem(JSObject _) implements JSObject {
  external void mkdirTree(String path);
  external void writeFile(String path, JSUint8Array bytes);
  external void unlink(String path);
}

Future<WasmModule>? _loading;
Uri? _loadingUri;

/// Loads a classic Emscripten module once per browser realm/Dart application.
Future<WasmModule> loadWasmModule(Uri uri) {
  final resolved = Uri.base.resolveUri(uri);
  if (resolved.scheme != 'http' && resolved.scheme != 'https') {
    throw ArgumentError.value(uri, 'wasmModuleUri', 'must resolve to HTTP(S)');
  }
  if (_loading != null) {
    if (_loadingUri != resolved) {
      throw StateError(
        'A different Wasm module is already loaded in this application.',
      );
    }
    return _loading!;
  }
  _loadingUri = resolved;
  final completer = Completer<WasmModule>();
  _loading = completer.future;
  final script = _document.createElement('script');
  script.src = resolved.toString();
  void failed(Object error, StackTrace stack) {
    if (completer.isCompleted) return;
    script.remove();
    _loading = null;
    _loadingUri = null;
    completer.completeError(error, stack);
  }

  script.onerror = ((JSAny? _) {
    failed(
      StateError('Could not load Wasm module script: $resolved'),
      StackTrace.current,
    );
  }).toJS;
  script.onload = ((JSAny? _) {
    () async {
      try {
        final module = await _createModule().toDart;
        if (module._taiyin_web_bridge_version() != 1 ||
            module._taiyin_get_c_abi_version() != 11) {
          throw StateError('Incompatible Taiyin Wasm bridge or C ABI.');
        }
        completer.complete(module);
      } catch (error, stack) {
        failed(error, stack);
      }
    }();
  }).toJS;
  _document.head.appendChild(script);
  return completer.future;
}

/// Copied operation result; never retains a view into growing Wasm memory.
typedef WasmReply = ({int status, List<double> values});

final class WasmBackend {
  WasmBackend(this.module);
  final WasmModule module;

  WasmReply _call(
    List<num> input,
    int Function(int, int) invoke, {
    int outputSize = 32,
  }) {
    if (input.length > 32) throw ArgumentError('Oversized bridge input');
    final pointer = module._malloc((32 + outputSize) * 8);
    if (pointer == 0) throw StateError('Wasm allocation failed');
    try {
      final heap = module.HEAPF64.toDart;
      final offset = pointer ~/ 8;
      heap.fillRange(offset, offset + 32 + outputSize, 0);
      heap.setRange(
        offset,
        offset + input.length,
        input.map((n) => n.toDouble()),
      );
      final status = invoke(pointer, pointer + 32 * 8);
      // A calculation may grow memory. Obtain the fresh heap after invoking it.
      final values = List<double>.of(
        module.HEAPF64.toDart.getRange(offset + 32, offset + 32 + outputSize),
      );
      return (status: status, values: values);
    } finally {
      module._free(pointer);
    }
  }

  WasmReply initialize(List<num> values) => _call(
    values,
    (input, output) => module._taiyin_web_initialize(input, output),
  );
  WasmReply createContext() =>
      _call([], (_, out) => module._taiyin_web_context_create(out));
  WasmReply cloneContext(int context) =>
      _call([], (_, out) => module._taiyin_web_context_clone(context, out));
  void destroyContext(int context) => module._taiyin_context_destroy(context);
  WasmReply position(int context, bool state, List<num> values) => _call(
    values,
    (input, out) =>
        module._taiyin_web_position(context, state ? 1 : 0, input, out),
  );
  ({int status, List<List<double>> values}) positions(
    int context,
    List<int> targets,
    List<num> input,
  ) {
    final count = targets.length;
    if (count == 0 || count > 100000) {
      throw RangeError.range(count, 1, 100000, 'targetCount');
    }
    final inputSize = 32 + count;
    final size = (inputSize + count * 32) * 8;
    final pointer = module._malloc(size);
    if (pointer == 0) throw StateError('Wasm allocation failed');
    try {
      final offset = pointer ~/ 8;
      final heap = module.HEAPF64.toDart;
      heap.fillRange(offset, offset + inputSize + count * 32, 0);
      heap.setRange(
        offset,
        offset + input.length,
        input.map((v) => v.toDouble()),
      );
      heap.setRange(
        offset + 32,
        offset + inputSize,
        targets.map((v) => v.toDouble()),
      );
      final status = module._taiyin_web_positions(
        context,
        count,
        pointer,
        pointer + inputSize * 8,
      );
      final updated = module.HEAPF64.toDart;
      return (
        status: status,
        values: [
          for (var i = 0; i < count; i++)
            List<double>.of(
              updated.getRange(
                offset + inputSize + i * 32,
                offset + inputSize + (i + 1) * 32,
              ),
            ),
        ],
      );
    } finally {
      module._free(pointer);
    }
  }

  WasmReply configure(int context, int operation, List<num> values) => _call(
    values,
    (input, out) =>
        module._taiyin_web_configure(context, operation, input, out),
  );
  WasmReply solarTime(int context, int operation, List<num> values) => _call(
    values,
    (input, out) =>
        module._taiyin_web_solar_time(context, operation, input, out),
  );
  WasmReply time(int context, int operation, List<num> values) => _call(
    values,
    (input, out) => module._taiyin_web_time(context, operation, input, out),
  );
  WasmReply createCalendar(int context, List<num> values) => _call(
    values,
    (input, out) => module._taiyin_web_calendar_create(context, input, out),
  );
  WasmReply calendar(int context, int operation, List<num> values) => _call(
    values,
    (input, out) => module._taiyin_web_calendar(context, operation, input, out),
    outputSize: 512,
  );
  void destroyCalendar(int context) =>
      module._taiyin_chinese_calendar_context_destroy(context);

  /// Variable-length copied C ABI results. Only this transport owns addresses.
  WasmReply eclipse(int context, int operation, List<num> input) => _structured(
    input,
    (pointer, count) =>
        module._taiyin_web_eclipse(context, operation, pointer, count),
  );
  WasmReply bazi(int context, int calendar, int operation, List<num> input) =>
      _structured(
        input,
        (pointer, count) => module._taiyin_web_bazi(
          context,
          calendar,
          operation,
          pointer,
          count,
        ),
      );
  void destroyBazi(int context) => module._taiyin_bazi_context_destroy(context);
  WasmReply ziwei(
    int context,
    int chart,
    int calendar,
    int operation,
    List<num> input,
  ) => _structured(
    input,
    (pointer, count) => module._taiyin_web_ziwei(
      context,
      chart,
      calendar,
      operation,
      pointer,
      count,
    ),
  );
  WasmReply _structured(List<num> input, int Function(int, int) invoke) {
    final pointer = module._malloc((input.isEmpty ? 1 : input.length) * 8);
    if (pointer == 0) throw StateError('Wasm allocation failed');
    var reply = 0;
    try {
      module.HEAPF64.toDart.setRange(
        pointer ~/ 8,
        pointer ~/ 8 + input.length,
        input.map((v) => v.toDouble()),
      );
      reply = invoke(pointer, input.length);
      if (reply == 0) throw StateError('Wasm result allocation failed');
      final count = module._taiyin_web_eclipse_length(reply);
      final data = module._taiyin_web_eclipse_data(reply);
      if (count < 32 || data == 0) {
        throw StateError('Invalid Wasm operation reply');
      }
      final values = List<double>.of(
        module.HEAPF64.toDart.getRange(data ~/ 8, data ~/ 8 + count),
      );
      return (status: values[1].toInt(), values: values);
    } finally {
      if (reply != 0) module._taiyin_web_eclipse_destroy(reply);
      module._free(pointer);
    }
  }

  WasmReply addSource(String path) {
    return loadFile(0, path);
  }

  WasmReply resource(int operation) =>
      _call([], (_, out) => module._taiyin_web_resource(operation, out));

  WasmReply loadFile(int kind, String path) {
    final size = module.lengthBytesUTF8(path) + 1;
    final pointer = module._malloc(size);
    if (pointer == 0) throw StateError('Wasm allocation failed');
    try {
      module.stringToUTF8(path, pointer, size);
      return _call(
        [],
        (_, out) => module._taiyin_web_load_file(kind, pointer, out),
      );
    } finally {
      module._free(pointer);
    }
  }

  void writeBytes(String path, Uint8List bytes) {
    module.FS.mkdirTree(path.substring(0, path.lastIndexOf('/')));
    module.FS.writeFile(path, bytes.toJS);
  }

  WasmReply starCatalogBytes(Uint8List bytes) {
    final pointer = module._malloc(bytes.length);
    if (pointer == 0) throw StateError('Wasm allocation failed');
    try {
      module.HEAPU8.toDart.setRange(pointer, pointer + bytes.length, bytes);
      return _call(
        [],
        (_, out) => module._taiyin_web_star_memory(pointer, bytes.length, out),
      );
    } finally {
      module._free(pointer);
    }
  }

  WasmReply starMagnitude(String key) {
    final length = module.lengthBytesUTF8(key) + 1;
    final pointer = module._malloc(length);
    if (pointer == 0) throw StateError('Wasm allocation failed');
    try {
      module.stringToUTF8(key, pointer, length);
      return _call(
        [],
        (_, out) => module._taiyin_web_star_magnitude(pointer, out),
      );
    } finally {
      module._free(pointer);
    }
  }

  void unlink(String path) => module.FS.unlink(path);
  int get abiVersion => module._taiyin_get_c_abi_version();
  String get libraryVersion =>
      module.UTF8ToString(module._taiyin_get_library_version());
  String get libraryCodename =>
      module.UTF8ToString(module._taiyin_get_library_codename());
  String statusName(int status) =>
      module.UTF8ToString(module._taiyin_status_name(status));
  String statusMessage(int status) =>
      module.UTF8ToString(module._taiyin_status_message(status));
  int statusCategory(int status) => module._taiyin_status_category(status);
}
