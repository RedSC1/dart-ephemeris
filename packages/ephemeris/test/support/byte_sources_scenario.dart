import 'dart:convert';
import 'dart:typed_data';
import 'package:ephemeris/ephemeris.dart';
import 'backend_scenario.dart' show require;

final class _Target implements Target {
  const _Target(this.id);
  @override
  final int id;
}

Uint8List sampleEop({bool replacement = false}) {
  // Same two fixed-column finals2000A records as the C++ EOP parser test.
  var text =
      '73 1 2 41684.00 I  0.120733 0.009786  0.136966 0.015902  I 0.8084178 0.0002710  0.0000 0.1916  P    -0.766    0.199    -0.720    0.300   .143000   .137000   .8075000   -18.637    -3.667  \n'
      '73 1 3 41685.00 I  0.118980 0.011039  0.135656 0.013616  I 0.8056163 0.0002710  3.5563 0.1916  P    -0.751    0.199    -0.701    0.300   .141000   .134000   .8044000   -18.636    -3.571  \n';
  if (replacement) {
    text = text
        .replaceAll('0.8084178', '0.7000000')
        .replaceAll('0.8056163', '0.6000000');
  }
  return Uint8List.fromList(utf8.encode(text));
}

Uint8List sampleLimb() {
  // The 2×2×4 grid used by test_lunar_limb_tll1.cpp; header = 192 bytes.
  final data = ByteData(224);
  final bytes = data.buffer.asUint8List()..setAll(0, ascii.encode('TLL1'));
  data.setUint16(4, 1, Endian.little);
  data.setUint16(6, 192, Endian.little);
  for (final entry in {8: 3, 12: 2, 16: 2, 20: 4, 32: 192, 40: 32}.entries) {
    data.setUint32(entry.key, entry.value, Endian.little);
  }
  final fields = [-1.0, 2.0, -2.0, 4.0, 0.0, 90.0, 1737400.0, 384398550.0, 0.5];
  for (var i = 0; i < fields.length; i++) {
    data.setFloat64(48 + i * 8, fields[i], Endian.little);
  }
  for (var i = 0; i < 16; i++) {
    data.setInt16(
      192 + i * 2,
      (i ~/ 8) * 1000 + (i ~/ 4 % 2) * 100 + (i % 4) * 10,
      Endian.little,
    );
  }
  return bytes;
}

Uint8List sampleKepler() => Uint8List.fromList(
  utf8.encode('''
# Leading comments are accepted by the original TKE1 reader.
TKE1
version=1
target_id=2000999
center_id=10
method_id=3001
frame_id=1
jd_tdb_start=2451000
jd_tdb_end=2453000
element_count=1
element.0.jd_tdb_start=2451000
element.0.jd_tdb_end=2453000
element.0.epoch_jd_tdb=2451545
element.0.mu_au3_day2=0.0002959122082855911
element.0.semi_major_axis_au=2
element.0.eccentricity=0.25
element.0.inclination_rad=0.1
element.0.longitude_ascending_node_rad=0.2
element.0.argument_periapsis_rad=0.3
element.0.mean_anomaly_at_epoch_rad=0.4
'''),
);

/// A 4 KiB DAF/SPK type-2 fixture, not a downloaded planetary kernel.
Uint8List sampleSpk() {
  final data = ByteData(4096);
  final bytes = data.buffer.asUint8List()..setAll(0, ascii.encode('DAF/SPK '));
  for (final entry in {8: 2, 12: 6, 76: 2, 80: 2, 84: 397}.entries) {
    data.setInt32(entry.key, entry.value, Endian.little);
  }
  bytes.setAll(88, ascii.encode('LTL-IEEE'));
  data.setFloat64(1040, 1, Endian.little);
  data.setFloat64(1048, -86400, Endian.little);
  data.setFloat64(1056, 86400, Endian.little);
  final ints = [2000777, 0, 1, 2, 385, 396];
  for (var i = 0; i < ints.length; i++) {
    data.setInt32(1064 + i * 4, ints[i], Endian.little);
  }
  final words = [
    0.0,
    86400.0,
    1e8,
    0.0,
    0.0,
    1e5,
    0.0,
    0.0,
    -86400.0,
    172800.0,
    8.0,
    1.0,
  ];
  for (var i = 0; i < words.length; i++) {
    data.setFloat64(3072 + i * 8, words[i], Endian.little);
  }
  return bytes;
}

List<Map<String, Object?>> exerciseByteSources(
  Ephemeris runtime,
  Uint8List tkc,
  Uint8List stars,
) {
  final rows = <Map<String, Object?>>[];
  final ctx = runtime.createContext();
  try {
    final utc = AstroDateTime(1973, 1, 2, 12);
    runtime.clearEopTable();
    final bytes = sampleEop();
    runtime.loadEopTableBytes(bytes);
    require(runtime.hasEopTable, 'EOP bytes were not loaded');
    bytes.fillRange(0, bytes.length, 0);
    final first = ctx.position.atUtc(Body.sun, utc);
    require(
      (ctx.lastDiagnostic!.dut1Seconds - 0.80701705).abs() < 1e-12,
      'Wrong EOP interpolation',
    );
    require(
      !first.flags.contains(ResultFlag.timeScaleFallback),
      'EOP was silently estimated',
    );
    rows.add({
      'label': 'eop/loaded',
      'flags': first.flags.mask,
      'values': first.value.values,
    });
    runtime.loadEopTableBytes(sampleEop(replacement: true));
    final replaced = ctx.position.atUtc(Body.sun, utc);
    require(
      (ctx.lastDiagnostic!.dut1Seconds - 0.65).abs() < 1e-12,
      'Context reused stale EOP after replacement',
    );
    rows.add({
      'label': 'eop/replaced',
      'flags': replaced.flags.mask,
      'values': replaced.value.values,
    });
    try {
      runtime.loadEopTableBytes(
        Uint8List.fromList(ascii.encode('not finals data')),
      );
      throw StateError('Invalid EOP accepted');
    } on EphemerisError {
      /* parser rejection */
    }
    require(
      runtime.hasEopTable,
      'Failed EOP load discarded the previous table',
    );
    runtime.clearEopTable();
    require(!runtime.hasEopTable, 'EOP clear failed');
    try {
      ctx.position.atUtc(Body.sun, utc);
      throw StateError('Context reused EOP after clear');
    } on EarthOrientationDataError {
      /* must not silently estimate */
    }
    runtime.loadBuiltinEopTable();
    require(runtime.hasEopTable, 'Built-in EOP reload failed');

    final limb = sampleLimb();
    runtime.loadLunarLimbModelBytes(limb);
    limb.fillRange(0, limb.length, 0);
    require(runtime.hasLunarLimbModel, 'TLL1 byte loading failed');
    try {
      runtime.loadLunarLimbModelBytes(
        Uint8List.fromList(ascii.encode('TLL1bad')),
      );
      throw StateError('Invalid TLL1 accepted');
    } on EphemerisError {
      /* actual parser rejection */
    }
    require(
      runtime.hasLunarLimbModel,
      'Failed TLL1 load discarded previous model',
    );
    runtime.clearLunarLimbModel();
    require(!runtime.hasLunarLimbModel, 'TLL1 clear failed');

    runtime.addSourceBytes('minor-bodies.tkc1', tkc);
    tkc.fillRange(0, tkc.length, 0);
    final ceres = ctx.position.atTt(
      const _Target(2000001),
      TtJulianDate.fromDouble(2460409.25),
    );
    require(
      ceres.value.values.every((v) => v.isFinite),
      'TKC1 not usable for calculation',
    );
    rows.add({
      'label': 'tkc1/ceres',
      'flags': ceres.flags.mask,
      'values': ceres.value.values,
    });
    runtime.addSourceBytes('custom-orbit.tke1', sampleKepler());
    final orbit = ctx.position.atTt(
      const _Target(2000999),
      TtJulianDate.fromDouble(2451545),
    );
    require(
      orbit.value.values.every((v) => v.isFinite),
      'TKE1 not usable for calculation',
    );
    rows.add({
      'label': 'tke1/custom',
      'flags': orbit.flags.mask,
      'values': orbit.value.values,
    });

    runtime.addSourceBytes('tiny.bsp', sampleSpk());
    ctx.configuration.setRouteRule(RouteRule.spk);
    ctx.configuration.setGeocentricObserver(observerId: 0, centerId: 0);
    ctx.configuration.setApparentConfig(
      ApparentConfig(outputFrame: ApparentFrame.icrf),
    );
    final spk = ctx.position.atTdb(
      const _Target(2000777),
      TdbJulianDate.fromDouble(2451545),
      TtJulianDate.fromDouble(2451545),
      flags: {PositionFlag.xyz, PositionFlag.truePosition},
    );
    require(
      (spk.value.values[0] - 1e8 / 149597870.7).abs() < 1e-14,
      'SPK was not evaluated',
    );
    rows.add({
      'label': 'spk/type2',
      'flags': spk.flags.mask,
      'values': spk.value.values,
    });
    runtime.starCatalog.clear();
    runtime.starCatalog.addTsc1Bytes(stars);
    stars.fillRange(0, stars.length, 0);
    require(runtime.starCatalog.count == 1, 'TSC1 byte catalog not loaded');
    final spica = runtime.starCatalog.magnitudeOf('spica');
    require(spica.isFinite, 'TSC1 buffer was not copied');
    final text = Uint8List.fromList(
      utf8.encode('''TSF1
version=1
star_count=1
star.0.id=byte_test_star
star.0.name=字节测试星
star.0.aliases=byte-alias
star.0.ra_deg=180
star.0.dec_deg=45
star.0.reference_epoch=2000
star.0.magnitude=5.5
'''),
    );
    runtime.starCatalog.addTsf1Bytes(text);
    text.fillRange(0, text.length, 0);
    require(runtime.starCatalog.count == 2, 'TSF1 byte catalog not loaded');
    final magnitude = runtime.starCatalog.magnitudeOf('字节测试星');
    require(
      magnitude == 5.5 && runtime.starCatalog.magnitudeOf('byte-alias') == 5.5,
      'TSF1 aliases or ownership failed',
    );
    rows.add({
      'label': 'stars/catalogs',
      'flags': 0,
      'values': [spica, magnitude],
    });
    runtime.starCatalog.clear();
    require(runtime.starCatalog.count == 0, 'Star catalog clear failed');
  } finally {
    ctx.close();
  }
  return rows;
}
