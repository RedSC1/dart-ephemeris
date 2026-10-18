import 'dart:convert';
import 'dart:js_interop';
import 'package:ephemeris/ephemeris.dart' hide TaiyinExtensionHost;
import 'package:ephemeris/backend_web.dart' show TaiyinExtensionHost;
import 'bazi_models.dart';
import 'bazi_api_web.dart' show baziChartValues;
import 'shen_sha_models.dart';
import 'shen_sha_backend.dart';

final _callbacks = <int, _RuleState>{};
int _nextToken = 1;

final class _RuleState {
  _RuleState(this.label, this.rule) : token = _nextToken++ {
    _callbacks[token] = this;
  }
  final String label;
  final BaziShenShaRule rule;
  final int token;
  int refs = 0;
  bool busy = false;
  Object? error;
  StackTrace? stack;
  void retain() => refs++;
  void release() {
    if (--refs == 0) _callbacks.remove(token);
  }
}

int _predicate(
  int token,
  int year,
  int month,
  int day,
  int hour,
  int target,
  int kind,
  int gender,
) {
  final state = _callbacks[token];
  if (state == null) return -1;
  try {
    return state.rule.test(
          BaziShenShaInput.internal(
            [year, month, day, hour],
            target,
            BaziShenShaTargetKind.fromId(kind),
            gender < 0 ? null : BaziGender.fromId(gender),
          ),
        )
        ? 1
        : 0;
  } catch (error, stack) {
    state.error = error;
    state.stack = stack;
    return -1;
  }
}

List<num> _text(String value) {
  if (value.contains('\u0000')) {
    throw ArgumentError('Embedded NUL in Shen Sha text');
  }
  final bytes = utf8.encode(value);
  return [bytes.length, ...bytes];
}

BaziShenShaCatalogBackend createShenShaBackend({
  String? libraryPath,
  String? coreLibraryPath,
}) {
  if (libraryPath != null || coreLibraryPath != null) {
    throw UnsupportedError('Web has no native module paths.');
  }
  final host = TaiyinExtensionHost.open();
  host.installBaziPredicate(_predicate.toJS);
  final handle = host.callBazi(0, 22, []).values[32].toInt();
  return _Catalog(_Handle(host, handle, false, []));
}

final class _Handle {
  _Handle(this.host, this.value, this.isContext, List<_RuleState> rules)
    : rules = List.of(rules) {
    for (final rule in this.rules) {
      rule.retain();
    }
  }
  final TaiyinExtensionHost host;
  final int value;
  final bool isContext;
  final List<_RuleState> rules;
  bool closed = false;
  bool busy = false;
  void ensureOpen() {
    if (closed) throw StateError('Shen Sha handle is closed');
  }

  void close() {
    if (busy) {
      throw StateError('Cannot close Shen Sha context during evaluation');
    }
    if (closed) return;
    host.callBazi(value, isContext ? 28 : 27, []);
    closed = true;
    for (final rule in rules) {
      rule.release();
    }
    rules.clear();
  }
}

final class _Catalog implements BaziShenShaCatalogBackend {
  _Catalog(this.handle);
  final _Handle handle;
  @override
  BaziShenShaCatalogBackend addModule(BaziShenShaModule module) {
    handle.ensureOpen();
    final fresh = <_RuleState>[];
    try {
      final input = <num>[..._text(module.label), module.rules.length];
      for (final rule in module.rules) {
        final state = _RuleState(module.label, rule);
        fresh.add(state);
        input.addAll([..._text(rule.id), ..._text(rule.name), state.token]);
      }
      final next = handle.host
          .callBazi(handle.value, 23, input)
          .values[32]
          .toInt();
      return _Catalog(
        _Handle(handle.host, next, false, [...handle.rules, ...fresh]),
      );
    } finally {
      for (final state in fresh) {
        if (state.refs == 0) _callbacks.remove(state.token);
      }
    }
  }

  @override
  BaziShenShaCatalogBackend removeModule(String label) {
    handle.ensureOpen();
    final next = handle.host
        .callBazi(handle.value, 24, _text(label))
        .values[32]
        .toInt();
    return _Catalog(
      _Handle(
        handle.host,
        next,
        false,
        handle.rules.where((r) => r.label != label).toList(),
      ),
    );
  }

  @override
  BaziShenShaContextBackend createContext({
    List<String> disabledIds = const [],
  }) {
    handle.ensureOpen();
    final next = handle.host
        .callBazi(handle.value, 25, [
          disabledIds.length,
          for (final id in disabledIds) ..._text(id),
        ])
        .values[32]
        .toInt();
    return _Context(_Handle(handle.host, next, true, handle.rules));
  }

  @override
  void close() => handle.close();
}

final class _Context implements BaziShenShaContextBackend {
  _Context(this.handle);
  final _Handle handle;
  @override
  List<BaziShenShaMatch> evaluate({
    required BaziChart chart,
    required Ganzhi target,
    required BaziShenShaTargetKind targetKind,
    BaziGender? gender,
  }) {
    handle.ensureOpen();
    if (handle.busy || handle.rules.any((r) => r.busy)) {
      throw StateError('Reentrant Shen Sha evaluation');
    }
    handle.busy = true;
    for (final r in handle.rules) {
      r.busy = true;
      r.error = null;
      r.stack = null;
    }
    try {
      final reply = handle.host.callBazi(handle.value, 26, [
        ...baziChartValues(chart),
        target.raw,
        targetKind.id,
        gender?.id ?? -1,
      ], check: false);
      for (final r in handle.rules) {
        if (r.error != null) Error.throwWithStackTrace(r.error!, r.stack!);
      }
      handle.host.checkExtensionReply(reply);
      var at = 32;
      final values = reply.values;
      String string() {
        final count = values[at++].toInt();
        final bytes = values
            .sublist(at, at + count)
            .map((v) => v.toInt())
            .toList();
        at += count;
        return utf8.decode(bytes);
      }

      final matches = <BaziShenShaMatch>[];
      for (var i = 0; i < values[2]; i++) {
        final builtin = values[at++].toInt();
        matches.add(
          BaziShenShaMatch(string(), string(), builtin < 0 ? null : builtin),
        );
      }
      return List.unmodifiable(matches);
    } finally {
      for (final r in handle.rules) {
        r.busy = false;
        r.error = null;
        r.stack = null;
      }
      handle.busy = false;
    }
  }

  @override
  void close() => handle.close();
}
