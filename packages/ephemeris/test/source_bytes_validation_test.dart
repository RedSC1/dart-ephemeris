import 'dart:convert';
import 'dart:typed_data';
import 'package:ephemeris/src/backend/backend_call.dart';
import 'package:ephemeris/src/result_flags.dart';
import 'package:ephemeris/src/runtime/source_bytes.dart';
import 'package:test/test.dart';

final class _Backend implements RuntimeBytesBackend {
  final kinds = <RuntimeByteSourceKind>[];
  @override
  BackendCall<bool> load(
    RuntimeByteSourceKind kind,
    String name,
    Uint8List bytes,
  ) {
    kinds.add(kind);
    return BackendCall(status: 0, flags: ResultFlags.none, value: true);
  }
}

Uint8List _bytes(String header) => Uint8List.fromList(utf8.encode(header));

void main() {
  test(
    'accepts the supported source envelopes without parsing the formats twice',
    () {
      for (final entry in {
        'sun.opm2': 'OPM2',
        'tiny.bsp': 'DAF/SPK ',
        'tiny.SPK': 'DAF/SPK ',
        'asteroids.tkc1': 'TKC1',
        'orbit.tke1': '# comment\nTKE1\n',
      }.entries) {
        validateEphemerisBytes(entry.key, _bytes(entry.value));
      }
    },
  );
  test(
    'rejects paths, unsupported caches, extension/magic mismatches and empty files',
    () {
      for (final name in [
        '../sun.opm2',
        '/sun.opm2',
        'a\\sun.opm2',
        'sun\u0000.opm2',
        'index.opc',
        'catalog.tsc1',
        'orbit.TKE1',
      ]) {
        expect(
          () => validateEphemerisBytes(name, _bytes('OPM2')),
          throwsArgumentError,
        );
      }
      expect(
        () => validateEphemerisBytes('x.bsp', _bytes('OPM2')),
        throwsArgumentError,
      );
      expect(
        () => validateEphemerisBytes('x.tkc1', _bytes('OPM2')),
        throwsArgumentError,
      );
      expect(
        () => validateEphemerisBytes('x.tke1', Uint8List(0)),
        throwsArgumentError,
      );
    },
  );
  test(
    'routes auxiliary data to dedicated loaders and validates before backend calls',
    () {
      final backend = _Backend();
      var completions = 0;
      final api = RuntimeBytesLoader.internal(backend, (_) {
        completions++;
      });
      expect(() => api.loadEopTableBytes(Uint8List(0)), throwsArgumentError);
      expect(
        () => api.loadLunarLimbModelBytes(_bytes('OPM2')),
        throwsArgumentError,
      );
      expect(backend.kinds, isEmpty);
      api.addSourceBytes('x.tkc1', _bytes('TKC1'));
      api.loadEopTableBytes(
        _bytes('finals table: parser validates the content'),
      );
      api.loadLunarLimbModelBytes(_bytes('TLL1'));
      expect(backend.kinds, [
        RuntimeByteSourceKind.ephemeris,
        RuntimeByteSourceKind.earthOrientation,
        RuntimeByteSourceKind.lunarLimb,
      ]);
      expect(completions, 3);
    },
  );
}
