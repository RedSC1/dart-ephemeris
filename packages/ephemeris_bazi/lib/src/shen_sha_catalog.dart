part of 'bazi_api.dart';

Pointer<Char> _shenString(String value, Arena arena) {
  if (value.contains('\u0000')) {
    throw ArgumentError('Embedded NUL in Shen Sha text');
  }
  return value.toNativeUtf8(allocator: arena).cast();
}

final class _ShenCallback {
  _ShenCallback(this.moduleLabel, BaziShenShaRule rule) {
    callable =
        NativeCallable<taiyin_bazi_shen_sha_predicateFunction>.isolateLocal((
          Pointer<taiyin_ganzhi_four_pillars> pillars,
          int target,
          int kind,
          int gender,
          Pointer<Void> data,
        ) {
          try {
            final p = pillars.ref;
            return rule.test(
                  BaziShenShaInput.internal(
                    [p.year, p.month, p.day, p.hour],
                    target,
                    BaziShenShaTargetKind.fromId(kind),
                    gender == -1 ? null : BaziGender.fromId(gender),
                  ),
                )
                ? 1
                : 0;
          } catch (e, s) {
            error = e;
            stack = s;
            return -1;
          }
        }, exceptionalReturn: -1);
    callable.keepIsolateAlive = false;
  }
  late final NativeCallable<taiyin_bazi_shen_sha_predicateFunction> callable;
  final String moduleLabel;
  int refs = 0;
  bool busy = false;
  Object? error;
  StackTrace? stack;
  void retain() => refs++;
  void release() {
    if (--refs == 0) callable.close();
  }
}

// Finalizer state must not retain the Dart facade itself.
final class _ShenHandle {
  _ShenHandle(
    this.module,
    this.pointer,
    this.isContext,
    List<_ShenCallback> callbacks,
  ) : callbacks = List.of(callbacks) {
    for (final callback in callbacks) {
      callback.retain();
    }
  }
  final TaiyinExtensionModule module;
  Pointer<Void> pointer;
  final bool isContext;
  final List<_ShenCallback> callbacks;
  bool busy = false;
  void ensureOpen() {
    if (pointer == nullptr) throw StateError('Shen Sha handle is closed');
  }

  void dispose() {
    if (busy) {
      throw StateError('Cannot close Shen Sha context during evaluation');
    }
    if (pointer == nullptr) return;
    if (isContext) {
      module.bindings.taiyin_bazi_shen_sha_context_destroy(pointer.cast());
    } else {
      module.bindings.taiyin_bazi_shen_sha_catalog_destroy(pointer.cast());
    }
    pointer = nullptr;
    for (final callback in callbacks) {
      callback.release();
    }
    callbacks.clear();
  }
}

final _shenFinalizer = Finalizer<_ShenHandle>((handle) => handle.dispose());

/// Immutable native catalog, independent of an astronomy context.
///
/// Add/remove return NEW catalogs. Built-ins cannot be changed. Close catalogs
/// and contexts when finished; derived snapshots keep callbacks alive. Handles
/// and callbacks must not be shared across isolates.
final class _NativeShenCatalogBackend
    implements BaziShenShaCatalogBackend, Finalizable {
  factory _NativeShenCatalogBackend({
    String? libraryPath,
    String? coreLibraryPath,
  }) {
    final host = TaiyinExtensionHost.open(libraryPath: coreLibraryPath);
    final module = _openBaziModule(libraryPath);
    // Validate even if the module was previously cached by a regular BaZi call.
    validateTaiyinRequiredSymbols(
      providesSymbol: module.library.providesSymbol,
      requiredSymbols: taiyinBaziShenShaSymbols,
    );
    return using((arena) {
      final out = arena<Pointer<taiyin_bazi_shen_sha_catalog>>();
      host.checkStatus(
        module.bindings.taiyin_bazi_shen_sha_catalog_create(out),
      );
      return _NativeShenCatalogBackend._(
        host,
        _ShenHandle(module, out.value.cast(), false, []),
      );
    });
  }
  _NativeShenCatalogBackend._(this._host, this._handle) {
    _shenFinalizer.attach(this, _handle, detach: this);
  }
  final TaiyinExtensionHost _host;
  final _ShenHandle _handle;

  @override
  _NativeShenCatalogBackend addModule(BaziShenShaModule module) {
    _handle.ensureOpen();
    final callbacks = <_ShenCallback>[];
    try {
      return using((arena) {
        final rules = arena<taiyin_bazi_shen_sha_rule>(module.rules.length);
        for (var i = 0; i < module.rules.length; i++) {
          final rule = module.rules[i];
          final callback = _ShenCallback(module.label, rule);
          callbacks.add(callback);
          rules[i]
            ..struct_size = sizeOf<taiyin_bazi_shen_sha_rule>()
            ..id = _shenString(rule.id, arena)
            ..name = _shenString(rule.name, arena)
            ..predicate = callback.callable.nativeFunction
            ..user_data = nullptr;
        }
        final out = arena<Pointer<taiyin_bazi_shen_sha_catalog>>();
        _host.checkStatus(
          _handle.module.bindings.taiyin_bazi_shen_sha_catalog_add_module(
            _handle.pointer.cast(),
            _shenString(module.label, arena),
            rules,
            module.rules.length,
            out,
          ),
        );
        return _NativeShenCatalogBackend._(
          _host,
          _ShenHandle(_handle.module, out.value.cast(), false, [
            ..._handle.callbacks,
            ...callbacks,
          ]),
        );
      });
    } finally {
      for (final callback in callbacks) {
        if (callback.refs == 0) callback.callable.close();
      }
    }
  }

  /// Removes ALL rules in [label], leaving existing snapshots unchanged.
  @override
  _NativeShenCatalogBackend removeModule(String label) {
    _handle.ensureOpen();
    return using((arena) {
      final out = arena<Pointer<taiyin_bazi_shen_sha_catalog>>();
      _host.checkStatus(
        _handle.module.bindings.taiyin_bazi_shen_sha_catalog_remove_module(
          _handle.pointer.cast(),
          _shenString(label, arena),
          out,
        ),
      );
      return _NativeShenCatalogBackend._(
        _host,
        _ShenHandle(
          _handle.module,
          out.value.cast(),
          false,
          _handle.callbacks.where((c) => c.moduleLabel != label).toList(),
        ),
      );
    });
  }

  @override
  _NativeShenContextBackend createContext({
    List<String> disabledIds = const [],
  }) {
    _handle.ensureOpen();
    return using((arena) {
      final ids = arena<Pointer<Char>>(disabledIds.length);
      for (var i = 0; i < disabledIds.length; i++) {
        ids[i] = _shenString(disabledIds[i], arena);
      }
      final out = arena<Pointer<taiyin_bazi_shen_sha_context>>();
      _host.checkStatus(
        _handle.module.bindings.taiyin_bazi_shen_sha_context_create(
          _handle.pointer.cast(),
          ids,
          disabledIds.length,
          out,
        ),
      );
      return _NativeShenContextBackend._(
        _host,
        _ShenHandle(_handle.module, out.value.cast(), true, _handle.callbacks),
      );
    });
  }

  @override
  void close() {
    _handle.dispose();
    _shenFinalizer.detach(this);
  }
}

/// Frozen rule selection. Callback exceptions are rethrown after native unwind.
/// Reentry into contexts sharing callback storage is rejected.
final class _NativeShenContextBackend
    implements BaziShenShaContextBackend, Finalizable {
  _NativeShenContextBackend._(this._host, this._handle) {
    _shenFinalizer.attach(this, _handle, detach: this);
  }
  final TaiyinExtensionHost _host;
  final _ShenHandle _handle;
  @override
  List<BaziShenShaMatch> evaluate({
    required BaziChart chart,
    required Ganzhi target,
    required BaziShenShaTargetKind targetKind,
    BaziGender? gender,
  }) {
    _handle.ensureOpen();
    if (_handle.busy || _handle.callbacks.any((c) => c.busy)) {
      throw StateError('Reentrant Shen Sha evaluation');
    }
    _handle.busy = true;
    for (final c in _handle.callbacks) {
      c.busy = true;
      c.error = null;
      c.stack = null;
    }
    try {
      return using((arena) {
        final bindings = _handle.module.bindings;
        final out = arena<Pointer<taiyin_bazi_shen_sha_matches>>();
        try {
          final result = bindings.taiyin_bazi_shen_sha_evaluate(
            _handle.pointer.cast(),
            _writeBaziChart(bindings, arena, chart),
            target.raw,
            targetKind.id,
            gender?.id ?? -1,
            out,
          );
          for (final c in _handle.callbacks) {
            if (c.error != null) Error.throwWithStackTrace(c.error!, c.stack!);
          }
          _host.checkStatus(result);
          final id = arena<Pointer<Char>>(), name = arena<Pointer<Char>>();
          final builtin = arena<Int32>();
          final matches = <BaziShenShaMatch>[];
          final count = bindings.taiyin_bazi_shen_sha_matches_count(out.value);
          for (var i = 0; i < count; i++) {
            _host.checkStatus(
              bindings.taiyin_bazi_shen_sha_matches_get(
                out.value,
                i,
                id,
                name,
                builtin,
              ),
            );
            matches.add(
              BaziShenShaMatch(
                id.value.cast<Utf8>().toDartString(),
                name.value.cast<Utf8>().toDartString(),
                builtin.value < 0 ? null : builtin.value,
              ),
            );
          }
          return List.unmodifiable(matches);
        } finally {
          bindings.taiyin_bazi_shen_sha_matches_destroy(out.value);
        }
      });
    } finally {
      for (final c in _handle.callbacks) {
        c.busy = false;
        c.error = null;
        c.stack = null;
      }
      _handle.busy = false;
    }
  }

  @override
  void close() {
    _handle.dispose();
    _shenFinalizer.detach(this);
  }
}
