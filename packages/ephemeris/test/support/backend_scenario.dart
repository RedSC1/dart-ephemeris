import 'dart:typed_data';
import 'package:ephemeris/ephemeris.dart';

void require(bool value, String message) {
  if (!value) throw StateError(message);
}

/// Shared native/Web integration scenario: no dart:io, dart:ffi or JS logic.
Map<String, Object?> exerciseBackend(
  Ephemeris runtime,
  Map<String, Uint8List> sources,
) {
  for (final capability in [
    Capability.runtime,
    Capability.position,
    Capability.time,
    Capability.eclipse,
  ]) {
    require(
      runtime.hasCapability(capability),
      'Implemented capability was not advertised: $capability',
    );
    require(
      runtime.availableCapabilities.contains(capability),
      'Capability set omitted $capability',
    );
  }
  final results = <Object?>[];
  final tt = TtJulianDate.fromParts(2460409, 0.25);
  final ut = Ut1JulianDate.fromParts(2460409, 0.25);
  final tdb = TdbJulianDate.fromParts(2460409, 0.25);
  final utc = AstroDateTime(2024, 4, 8, 18);

  void positions(EphemerisContext ctx, String label) {
    for (final body in [
      Body.sun,
      Body.moon,
      Body.marsBarycenter,
      Body.jupiterBarycenter,
    ]) {
      for (final flags in [
        <PositionFlag>{},
        {PositionFlag.speed},
        {PositionFlag.xyz, PositionFlag.truePosition},
      ]) {
        final result = ctx.position.atTt(body, tt, flags: flags);
        require(
          result.value.values.every((v) => v.isFinite),
          'Non-finite position',
        );
        require(
          ctx.lastDiagnostic?.targetId == body.id,
          'Missing operation diagnostic',
        );
        results.add({
          'label': label,
          'body': body.id,
          'inputFlags': flags.fold<int>(0, (m, f) => m | f.mask),
          'flags': result.flags.mask,
          'values': result.value.values,
        });
      }
    }
    for (final result in [
      ctx.position.atUt1(Body.sun, ut),
      ctx.position.atUt1WithDeltaT(Body.sun, ut, 69.184),
      ctx.position.atTdb(Body.sun, tdb, tt),
    ]) {
      results.add({
        'label': '$label/time',
        'flags': result.flags.mask,
        'values': result.value.values,
      });
    }
    final bodies = [Body.sun, Body.moon, Body.marsBarycenter];
    final batches = [
      ctx.position.batchAtTt(bodies, tt),
      ctx.position.batchAtUt1(bodies, ut),
      ctx.position.batchAtUt1WithDeltaT(bodies, ut, 69.184),
      ctx.position.batchAtTdb(bodies, tdb, tt),
    ];
    for (var i = 0; i < batches.length; i++) {
      final batch = batches[i];
      require(
        batch.value.length == bodies.length,
        'Batch result count changed',
      );
      if (i == 0) {
        for (var j = 0; j < bodies.length; j++) {
          final single = ctx.position.atTt(bodies[j], tt).value.values;
          require(
            List.generate(
              6,
              (k) => (single[k] - batch.value[j].values[k]).abs() < 1e-12,
            ).every((v) => v),
            'Batch and single calculations disagree',
          );
        }
      }
      results.add({
        'label': '$label/batch/$i',
        'flags': batch.flags.mask,
        'values': [for (final position in batch.value) ...position.values],
      });
    }
    require(ctx.position.batchAtTt([], tt).value.isEmpty, 'Empty batch failed');
    try {
      ctx.position.batchAtTt([
        Body.sun,
        CustomTarget(-123456789),
        Body.moon,
      ], tt);
      throw StateError('Failed batch returned partial success');
    } on EphemerisRouteError catch (error) {
      require(error.diagnostics.length == 3, 'Batch diagnostics lost');
      require(
        error.diagnostic?.targetId == -123456789,
        'Batch primary diagnostic selected the wrong target',
      );
      require(
        ctx.lastDiagnostic?.targetId == -123456789,
        'Batch context diagnostic selected the wrong target',
      );
    }
    final state = ctx.position.stateAtTt(Body.moon, tt).value;
    results.add({
      'label': '$label/state',
      'values': [
        ...state.positionAu.values,
        ...state.velocityAuPerDay.values,
        ...state.accelerationAuPerDay2.values,
      ],
    });
  }

  final analytic = runtime.createContext();
  try {
    analytic.configuration.setRouteRule(RouteRule.semiAnalytic);
    positions(analytic, 'analytic');
    // No EOP was loaded. UTC must fail until explicit estimation is enabled.
    try {
      analytic.position.atUtc(Body.sun, utc);
      throw StateError('UTC silently ignored missing EOP');
    } on EarthOrientationDataError catch (error) {
      require(error.status == -3001, 'Wrong EOP error');
      require(
        analytic.lastDiagnostic?.status == error.status,
        'Failure diagnostic was not recorded',
      );
    }
    analytic.time.setAllowUtcOutOfRangeEstimate(true);
    final estimated = analytic.position.atUtc(Body.sun, utc);
    require(
      estimated.flags.contains(ResultFlag.timeScaleFallback),
      'UTC fallback flag lost',
    );
    results.add({
      'label': 'utc/estimated',
      'flags': estimated.flags.mask,
      'values': estimated.value.values,
    });
    final clone = analytic.clone();
    try {
      final expected = clone.position.atTt(Body.sun, tt).value.values;
      analytic.configuration.setAstroModels(
        const AstroModelConfig(precessionModel: PrecessionModel.iau1976),
      );
      final changed = analytic.position.atTt(Body.sun, tt).value.values;
      require(
        (changed[0] - expected[0]).abs() > 1e-10,
        'Selected precession model was ignored',
      );
      require(
        clone.position.atTt(Body.sun, tt).value.values.toString() ==
            expected.toString(),
        'Changing one context changed its clone',
      );
    } finally {
      clone.close();
    }
  } finally {
    analytic.close();
  }
  try {
    analytic.position.atTt(Body.sun, tt);
    throw StateError('Closed context remained usable');
  } on StateError catch (error) {
    require(
      error.message.toString().contains('closed'),
      'Wrong closed-context error',
    );
  }
  for (final badName in ['../sun.opm2', 'sun.bsp', 'sun\u0000.opm2']) {
    try {
      runtime.addSourceBytes(badName, Uint8List(28));
      throw StateError('Invalid source name accepted');
    } on ArgumentError {
      /* expected before native/JS narrowing */
    }
  }
  final corrupt = Uint8List(28)..setRange(0, 4, [79, 80, 77, 50]);
  try {
    runtime.addSourceBytes('corrupt.opm2', corrupt);
    throw StateError('Corrupt OPM2 accepted');
  } on EphemerisError {
    /* real parser rejection, not only a magic check */
  }
  try {
    runtime.addSourceBytes('wrong-magic.opm2', Uint8List(28));
    throw StateError('Invalid magic accepted');
  } on ArgumentError {
    /* expected */
  }
  for (final entry in sources.entries) {
    runtime.addSourceBytes(entry.key, entry.value);
  }
  for (final duplicate in [
    sources.keys.first,
    sources.keys.first.toUpperCase(),
  ]) {
    try {
      runtime.addSourceBytes(duplicate, sources.values.first);
      throw StateError('Duplicate byte source overwritten');
    } on StateError catch (error) {
      require(
        error.message.toString().contains('already'),
        'Wrong duplicate error',
      );
    }
  }
  // Mutating caller-owned data must not corrupt the registered source.
  for (final bytes in sources.values) {
    bytes.fillRange(0, bytes.length, 0);
  }
  final precise = runtime.createContext();
  try {
    precise.configuration.setRouteRule(RouteRule.opm2);
    positions(precise, 'opm2');
    try {
      precise.position.atTt(Body.sun, TtJulianDate.fromDouble(2000000.5));
      throw StateError('OPM2-only silently fell back outside coverage');
    } on EphemerisRouteError {
      /* expected */
    }
  } finally {
    precise.close();
    precise.close();
  }
  return {
    'status': 'PASS',
    'abiVersion': runtime.abiVersion,
    'results': results,
  };
}
