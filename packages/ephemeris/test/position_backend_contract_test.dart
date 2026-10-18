import 'package:ephemeris/src/backend/backend_call.dart';
import 'package:ephemeris/src/backend/position_backend.dart';
import 'package:ephemeris/src/position/position_api.dart';
import 'package:ephemeris/src/result_flags.dart';
import 'package:ephemeris/src/time/astro_date_time.dart';
import 'package:ephemeris/src/time/julian_date.dart';
import 'package:test/test.dart';

// No native library or JS runtime is needed to test the shared API contract.
final class _Backend implements PositionBackend {
  PositionTime? time;
  List<int>? targets;
  int? mask;
  int calls = 0;

  void _capture(List<int> ids, PositionTime value, int flags) {
    calls++;
    targets = ids;
    time = value;
    mask = flags;
  }

  @override
  BackendCall<List<double>> position(int id, PositionTime time, int flags) {
    _capture([id], time, flags);
    return BackendCall(
      status: 0,
      flags: const ResultFlags(0x80000008),
      value: [1, 2, 3, 4, 5, 6],
    );
  }

  @override
  BackendCall<List<List<double>>> positions(
    List<int> ids,
    PositionTime time,
    int flags,
  ) {
    _capture(ids, time, flags);
    return BackendCall(
      status: 0,
      flags: const ResultFlags(0x80000008),
      value: [
        for (final id in ids) [id.toDouble(), 0, 0, 0, 0, 0],
      ],
    );
  }

  @override
  BackendCall<CartesianState> state(int id, PositionTime time, int flags) {
    _capture([id], time, flags);
    return BackendCall(
      status: 0,
      flags: ResultFlags.none,
      value: const CartesianState(
        positionAu: Vector3(1, 2, 3),
        velocityAuPerDay: Vector3(4, 5, 6),
        accelerationAuPerDay2: Vector3(7, 8, 9),
      ),
    );
  }
}

void main() {
  late _Backend backend;
  late PositionApi api;
  BackendCall<Object?>? completed;
  var closed = false;
  final tt = TtJulianDate.fromParts(2460409, 0.25000000001);
  final ut = Ut1JulianDate.fromParts(2460409, 0.25);
  final tdb = TdbJulianDate.fromParts(2460409, 0.25000000002);
  final utc = AstroDateTime(2024, 4, 8, 18);

  setUp(() {
    backend = _Backend();
    closed = false;
    completed = null;
    api = PositionApi.internal(
      backend,
      () {
        if (closed) throw StateError('closed');
      },
      (call) {
        completed = call;
      },
    );
  });

  test('preserves all time modes, split dates and target ordering', () {
    api.atTt(Body.sun, tt);
    expect(backend.time!.date, same(tt));
    expect(backend.time!.kind, PositionTimeKind.tt);
    api.atUt1(Body.sun, ut);
    expect(backend.time!.date, same(ut));
    expect(backend.time!.kind, PositionTimeKind.ut1);
    api.atTdb(Body.sun, tdb, tt);
    expect(backend.time!.date, same(tdb));
    expect(backend.time!.tt, same(tt));
    expect(backend.time!.kind, PositionTimeKind.tdb);
    api.atUtc(Body.sun, utc);
    expect(backend.time!.utc, same(utc));
    expect(backend.time!.kind, PositionTimeKind.utc);
    api.batchAtUt1WithDeltaT([Body.moon, Body.sun], ut, 69.184);
    expect(backend.time!.deltaT, 69.184);
    expect(backend.time!.kind, PositionTimeKind.ut1WithDeltaT);
    expect(backend.targets, [301, 10]);
  });

  test('retains all 32 result bits and immutable position flags', () {
    final flags = {PositionFlag.speed, PositionFlag.noNutation};
    final result = api.atTt(Body.sun, tt, flags: flags);
    flags.clear();
    expect(
      backend.mask,
      PositionFlag.speed.mask | PositionFlag.noNutation.mask,
    );
    expect(result.flags.mask, 0x80000008);
    expect(completed!.flags.mask, result.flags.mask);
    expect(result.value.flags, {PositionFlag.speed, PositionFlag.noNutation});
    expect(() => result.value.values[0] = 99, throwsUnsupportedError);
    expect(() => result.value.flags.clear(), throwsUnsupportedError);
  });

  test('empty batches do not call backend or replace last diagnostic', () {
    expect(api.batchAtTt([], tt).value, isEmpty);
    expect(backend.calls, 0);
    expect(completed, isNull);
    expect(
      () => api.batchAtUtc([], AstroDateTime(0x1000007e8)),
      throwsRangeError,
    );
  });

  test('invalid delta T and closed contexts fail before backend calls', () {
    expect(
      () => api.atUt1WithDeltaT(Body.sun, ut, double.nan),
      throwsArgumentError,
    );
    expect(backend.calls, 0);
    closed = true;
    expect(
      () => api.atUt1WithDeltaT(Body.sun, ut, double.nan),
      throwsStateError,
    );
    expect(() => api.batchAtTt([], tt), throwsStateError);
    expect(() => api.stateAtTt(Body.sun, tt), throwsStateError);
    expect(backend.calls, 0);
  });
}
