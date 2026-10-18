import '../backend/backend_call.dart';
import '../backend/position_backend.dart';
import '../result_flags.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import 'position_models.dart';

export 'position_models.dart';

/// Shared position API for native and Web calculation contexts.
///
/// Time coordinates retain their split precision. Batch failures are atomic
/// to the caller and retain every per-target diagnostic. All memory/ABI work
/// is delegated to the internal backend; this facade imports no FFI or JS.
final class PositionApi {
  /// Internal constructor used by an owning calculation context.
  PositionApi.internal(this._backend, this._ensureOpen, this._complete);
  final PositionBackend _backend;
  final void Function() _ensureOpen;
  final BackendCallCompletion _complete;

  /// Calculates one body at a TT Julian date.
  OperationResult<Position> atTt(
    Target body,
    TtJulianDate julianDate, {
    Set<PositionFlag> flags = const {},
  }) => _position(body, PositionTime.atTt(julianDate), flags);

  /// Calculates one body at UT1 using the configured Delta-T policy.
  OperationResult<Position> atUt1(
    Target body,
    Ut1JulianDate julianDate, {
    Set<PositionFlag> flags = const {},
  }) => _position(body, PositionTime.atUt1(julianDate), flags);

  /// Calculates one body with explicit TDB and TT coordinates.
  OperationResult<Position> atTdb(
    Target body,
    TdbJulianDate tdb,
    TtJulianDate tt, {
    Set<PositionFlag> flags = const {},
  }) => _position(body, PositionTime.atTdb(tdb, tt), flags);

  /// Calculates one body at UT1 with an explicit TT−UT1 offset in seconds.
  OperationResult<Position> atUt1WithDeltaT(
    Target body,
    Ut1JulianDate julianDate,
    double deltaTSeconds, {
    Set<PositionFlag> flags = const {},
  }) => _position(
    body,
    PositionTime.atUt1WithDeltaT(julianDate, deltaTSeconds),
    flags,
  );

  /// Calculates one body from a UTC calendar value using the context policy.
  OperationResult<Position> atUtc(
    Target body,
    AstroDateTime utc, {
    Set<PositionFlag> flags = const {},
  }) => _position(body, PositionTime.atUtc(utc), flags);

  /// Calculates several bodies at one TT Julian date.
  OperationResult<List<Position>> batchAtTt(
    List<Target> bodies,
    TtJulianDate julianDate, {
    Set<PositionFlag> flags = const {},
  }) => _positions(bodies, PositionTime.atTt(julianDate), flags);

  /// Calculates several bodies at one UT1 Julian date.
  OperationResult<List<Position>> batchAtUt1(
    List<Target> bodies,
    Ut1JulianDate julianDate, {
    Set<PositionFlag> flags = const {},
  }) => _positions(bodies, PositionTime.atUt1(julianDate), flags);

  /// Calculates several bodies with explicit TDB and TT coordinates.
  OperationResult<List<Position>> batchAtTdb(
    List<Target> bodies,
    TdbJulianDate tdb,
    TtJulianDate tt, {
    Set<PositionFlag> flags = const {},
  }) => _positions(bodies, PositionTime.atTdb(tdb, tt), flags);

  /// Calculates several bodies with an explicit TT−UT1 offset in seconds.
  OperationResult<List<Position>> batchAtUt1WithDeltaT(
    List<Target> bodies,
    Ut1JulianDate julianDate,
    double deltaTSeconds, {
    Set<PositionFlag> flags = const {},
  }) => _positions(
    bodies,
    PositionTime.atUt1WithDeltaT(julianDate, deltaTSeconds),
    flags,
  );

  /// Calculates several bodies from one UTC calendar value.
  OperationResult<List<Position>> batchAtUtc(
    List<Target> bodies,
    AstroDateTime utc, {
    Set<PositionFlag> flags = const {},
  }) => _positions(bodies, PositionTime.atUtc(utc), flags);

  /// Calculates Cartesian position, velocity and acceleration at TT.
  /// XYZ and SPEED are implicit for state calls; correction flags still apply.
  OperationResult<CartesianState> stateAtTt(
    Target body,
    TtJulianDate julianDate, {
    Set<PositionFlag> flags = const {},
  }) => _state(body, PositionTime.atTt(julianDate), flags);

  /// Calculates a Cartesian state at UT1.
  OperationResult<CartesianState> stateAtUt1(
    Target body,
    Ut1JulianDate julianDate, {
    Set<PositionFlag> flags = const {},
  }) => _state(body, PositionTime.atUt1(julianDate), flags);

  /// Calculates a Cartesian state with explicit TDB and TT coordinates.
  OperationResult<CartesianState> stateAtTdb(
    Target body,
    TdbJulianDate tdb,
    TtJulianDate tt, {
    Set<PositionFlag> flags = const {},
  }) => _state(body, PositionTime.atTdb(tdb, tt), flags);

  /// Calculates a Cartesian state with an explicit TT−UT1 offset in seconds.
  OperationResult<CartesianState> stateAtUt1WithDeltaT(
    Target body,
    Ut1JulianDate julianDate,
    double deltaTSeconds, {
    Set<PositionFlag> flags = const {},
  }) => _state(
    body,
    PositionTime.atUt1WithDeltaT(julianDate, deltaTSeconds),
    flags,
  );

  /// Calculates a Cartesian state from UTC.
  OperationResult<CartesianState> stateAtUtc(
    Target body,
    AstroDateTime utc, {
    Set<PositionFlag> flags = const {},
  }) => _state(body, PositionTime.atUtc(utc), flags);

  OperationResult<Position> _position(
    Target body,
    PositionTime time,
    Set<PositionFlag> flags,
  ) {
    _ensureOpen();
    _validateTime(time);
    final frozen = Set<PositionFlag>.unmodifiable(flags);
    final call = _backend.position(_targetId(body), time, _mask(frozen));
    _complete(call);
    return operationResult(Position.internal(call.value, frozen), call.flags);
  }

  OperationResult<List<Position>> _positions(
    List<Target> bodies,
    PositionTime time,
    Set<PositionFlag> flags,
  ) {
    _ensureOpen();
    _validateTime(time);
    if (bodies.isEmpty) {
      return operationResult(const <Position>[], ResultFlags.none);
    }
    final frozen = Set<PositionFlag>.unmodifiable(flags);
    final call = _backend.positions(
      List<int>.unmodifiable(bodies.map(_targetId)),
      time,
      _mask(frozen),
    );
    final diagnostics = call.diagnostics;
    final primary = diagnostics.isEmpty
        ? call.diagnostic
        : call.status == 0
        ? diagnostics.last
        : diagnostics.firstWhere(
            (d) => d.status == call.status,
            orElse: () => diagnostics.firstWhere(
              (d) => d.status != 0,
              orElse: () => diagnostics.last,
            ),
          );
    _complete(call.withDiagnostic(primary));
    return operationResult(
      List<Position>.unmodifiable([
        for (final values in call.value) Position.internal(values, frozen),
      ]),
      call.flags,
    );
  }

  OperationResult<CartesianState> _state(
    Target body,
    PositionTime time,
    Set<PositionFlag> flags,
  ) {
    _ensureOpen();
    _validateTime(time);
    final call = _backend.state(_targetId(body), time, _mask(flags));
    _complete(call);
    return operationResult(call.value, call.flags);
  }

  static int _targetId(Target target) {
    final id = target.id;
    if (id < -0x80000000 || id > 0x7fffffff) {
      throw RangeError.range(id, -0x80000000, 0x7fffffff, 'targetId');
    }
    return id;
  }

  static void _validateTime(PositionTime time) {
    if (!time.deltaT.isFinite) {
      throw ArgumentError.value(time.deltaT, 'deltaTSeconds', 'must be finite');
    }
    final year = time.utc?.year;
    if (year != null && (year < -0x80000000 || year > 0x7fffffff)) {
      throw RangeError.range(year, -0x80000000, 0x7fffffff, 'year');
    }
  }

  static int _mask(Set<PositionFlag> flags) =>
      flags.fold<int>(0, (mask, flag) => mask | flag.mask);
}
