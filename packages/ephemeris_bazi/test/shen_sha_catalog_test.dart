import 'dart:isolate';

import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_bazi/ephemeris_bazi.dart';
import 'package:test/test.dart';

int evaluateInIsolate() {
  final astro = Ephemeris.open().createContext();
  final gz = Ganzhi(stemId: 0, branchId: 0);
  final chart = astro.bazi.calcChart(
    GanzhiFourPillars(year: gz, month: gz, day: gz, hour: gz),
  );
  final base = BaziShenShaCatalog();
  final added = base.addModule(
    BaziShenShaModule(
      label: 'school',
      rules: [BaziShenShaRule(id: 'x', name: 'x', test: (_) => true)],
    ),
  );
  final context = added.createContext();
  try {
    return context
        .evaluate(
          chart: chart,
          target: gz,
          targetKind: BaziShenShaTargetKind.day,
        )
        .where((match) => match.id == 'school:x')
        .length;
  } finally {
    context.close();
    added.close();
    base.close();
    astro.bazi.close();
    astro.close();
  }
}

void main() {
  test('independent isolates own their own callbacks', () async {
    expect(
      await Future.wait(
        List.generate(4, (_) => Isolate.run(evaluateInIsolate)),
      ),
      [1, 1, 1, 1],
    );
  });
  late EphemerisContext astro;
  late BaziChart chart;
  final gz = Ganzhi(stemId: 0, branchId: 0);
  setUp(() {
    astro = Ephemeris.open().createContext();
    chart = astro.bazi.calcChart(
      GanzhiFourPillars(year: gz, month: gz, day: gz, hour: gz),
    );
  });
  tearDown(() {
    astro.bazi.close();
    astro.close();
  });
  List<BaziShenShaMatch> evaluate(BaziShenShaContext context) =>
      context.evaluate(
        chart: chart,
        target: gz,
        targetKind: BaziShenShaTargetKind.year,
      );

  test('snapshot owns callbacks after catalogs close', () {
    var calls = 0;
    final base = BaziShenShaCatalog();
    final added = base.addModule(
      BaziShenShaModule(
        label: 'school',
        rules: [
          BaziShenShaRule(
            id: 'x',
            name: 'Custom',
            test: (input) {
              calls++;
              expect(input.pillars, [0, 0, 0, 0]);
              expect(input.gender, isNull);
              return true;
            },
          ),
        ],
      ),
    );
    final context = added.createContext();
    final removed = added.removeModule('school');
    final without = removed.createContext();
    final disabled = added.createContext(disabledIds: ['school:x']);
    base.close();
    added.close();
    removed.close();
    try {
      final custom = evaluate(context).where((m) => m.id == 'school:x').single;
      expect(custom.name, 'Custom');
      expect(custom.builtinId, isNull);
      expect(calls, 1);
      expect(evaluate(without).any((m) => m.id == 'school:x'), isFalse);
      expect(evaluate(disabled).any((m) => m.id == 'school:x'), isFalse);
      expect(calls, 1);
    } finally {
      context.close();
      without.close();
      disabled.close();
    }
    expect(() => evaluate(context), throwsStateError);
  });

  test('exceptions unwind safely and context can be reused', () {
    var fail = true;
    final base = BaziShenShaCatalog();
    final added = base.addModule(
      BaziShenShaModule(
        label: 'school',
        rules: [
          BaziShenShaRule(
            id: 'x',
            name: 'Custom',
            test: (_) {
              if (fail) throw FormatException('from callback');
              return true;
            },
          ),
        ],
      ),
    );
    final context = added.createContext();
    try {
      expect(() => evaluate(context), throwsFormatException);
      fail = false;
      expect(evaluate(context).any((m) => m.id == 'school:x'), isTrue);
    } finally {
      context.close();
      added.close();
      base.close();
    }
  });

  test('reject reentry, close during call, duplicate and NUL IDs', () {
    final base = BaziShenShaCatalog();
    late BaziShenShaContext context;
    final module = BaziShenShaModule(
      label: 'school',
      rules: [
        BaziShenShaRule(
          id: 'x',
          name: 'x',
          test: (_) {
            expect(context.close, throwsStateError);
            expect(() => evaluate(context), throwsStateError);
            return true;
          },
        ),
      ],
    );
    final added = base.addModule(module);
    context = added.createContext();
    try {
      expect(() => added.addModule(module), throwsA(isA<EphemerisError>()));
      expect(
        () => base.removeModule('builtin'),
        throwsA(isA<EphemerisError>()),
      );
      expect(
        () => added.createContext(disabledIds: ['school:x\u0000bad']),
        throwsArgumentError,
      );
      expect(evaluate(context).any((m) => m.id == 'school:x'), isTrue);
    } finally {
      context.close();
      added.close();
      base.close();
    }
  });
}
