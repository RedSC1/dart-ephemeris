part of 'ziwei_api.dart';

Pointer<taiyin_ziwei_chart_clock> _writeClock(Arena arena, ZiweiClock clock) {
  if (clock.mode != ZiweiClockMode.fixedOffset &&
      (!clock.longitudeRadians.isFinite ||
          clock.longitudeRadians.abs() > 3.141592653589793)) {
    throw ArgumentError.value(
      clock.longitudeRadians,
      'longitudeRadians',
      'must be finite and within [-pi, pi]',
    );
  }
  final out = arena<taiyin_ziwei_chart_clock>();
  out.ref
    ..struct_size = sizeOf<taiyin_ziwei_chart_clock>()
    ..mode = clock.mode.index
    ..longitude_rad = clock.longitudeRadians;
  return out;
}

OperationResult<T> _clockOperation<T>(
  ZiweiContext context,
  T Function(Arena, Pointer<taiyin_ephemeris_diagnostic>, void Function(int))
  action,
) {
  context._ensureOpen();
  return using((arena) {
    final diagnostic = arena<taiyin_ephemeris_diagnostic>();
    context._coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
    var flags = ResultFlags.none;
    void check(int status) {
      final mapped = context._host.readDiagnostic(diagnostic.ref);
      context._host.recordDiagnostic(mapped);
      flags |= _checkStatus(context._host, status, diagnostic: mapped);
      context._coreBindings.taiyin_ephemeris_diagnostic_init(diagnostic);
    }

    final value = action(arena, diagnostic, check);
    return operationResult(value, flags);
  });
}
