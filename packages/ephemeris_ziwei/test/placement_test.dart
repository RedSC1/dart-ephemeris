import 'dart:isolate';

import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

int digest(ZiweiContext c, ZiweiCastingChart chart) {
  final s = chart.summary;
  final values = [
    s.bureau.id,
    chart.starPosition(c.findStar('ziwei')!.id)!,
    chart.starPosition(c.findStar('tianfu')!.id)!,
    s.bodyPalace,
    ...s.palaceBranches,
    ...s.palaceStems,
    s.lifeMaster,
    s.bodyMaster,
    ...s.transformations,
    for (var i = 0; i < c.starCount; i++) chart.starPosition(i) ?? 255,
    for (var i = 0; i < c.starCount; i++) chart.transformMask(i),
  ];
  var h = 0x811c9dc5;
  for (final v in values) {
    for (var i = 0; i < 4; i++) {
      h = ((h ^ ((v >> (8 * i)) & 255)) * 0x01000193) & 0xffffffff;
    }
  }
  return h;
}

void main() {
  group(
    'Manual placement and casting C ABI',
    () {
      late EphemerisContext owner;
      late ZiweiContext c;
      final charts = <ZiweiCastingChart>[];
      ZiweiCastingChart keep(ZiweiCastingChart v) {
        charts.add(v);
        return v;
      }

      setUp(() {
        owner = Ephemeris.open(libraryPath: libraryPath).createContext();
        c = owner.ziwei;
      });
      tearDown(() {
        for (final chart in charts) {
          chart.close();
        }
        charts.clear();
        c.close();
        owner.close();
      });

      test(
        'JS oracle all stars and all transformation bits, six chart variants',
        () {
          const expected = [
            3769082376,
            3769082376,
            1666642794,
            962889352,
            962889352,
            1680750442,
          ];
          for (final gender in ZiweiGender.values) {
            for (final mode in ZiweiChartMode.values) {
              final chart = keep(
                c.castingFromIndex(0, gender: gender, chartMode: mode),
              );
              expect(digest(c, chart), expected[gender.id * 3 + mode.id]);
              expect(chart.summary.input.day, 1);
            }
          }
        },
      );
      test('number-v1 matches JS and edits/reset keep original metadata', () {
        final chart = keep(
          c.castingFromNumber('000123456', gender: ZiweiGender.male),
        );
        expect(chart.summary.index, 209225);
        expect(chart.summary.number, '123456');
        final hash = digest(c, chart);
        final edited = keep(
          chart.modify(
            const ZiweiPlacementPatch(month: 3, day: 30, updateBureau: true),
          ),
        );
        final shifted = keep(edited.shiftLifePalace(1));
        expect(shifted.summary.input.month, 3);
        expect(shifted.summary.index, 209225);
        expect(digest(c, keep(shifted.reset())), hash);
        expect(digest(c, chart), hash);
      });
      test('OS random draws can be reproduced by index', () {
        for (var i = 0; i < 12; i++) {
          final chart = keep(c.randomCastingChart(gender: ZiweiGender.female));
          final index = chart.summary.index!;
          expect(index, inInclusiveRange(0, 259199));
          expect(
            digest(c, chart),
            digest(
              c,
              keep(c.castingFromIndex(index, gender: ZiweiGender.female)),
            ),
          );
          expect(keep(chart.reset()).summary.index, index);
        }
      });
      test(
        'manual inputs preserve fixed bureau and expose missing-input stars',
        () {
          for (final bureau in ZiweiBureau.values) {
            final chart = keep(
              c.createCastingChart(
                const ZiweiPlacementInput(yearBranch: 1),
                gender: ZiweiGender.male,
                fixedBureau: bureau,
              ),
            );
            expect(chart.summary.index, isNull);
            expect(chart.summary.bureau, bureau);
            expect(chart.omittedPlacements, isNotEmpty);
            for (final missing in chart.omittedPlacements) {
              expect(chart.starPosition(missing.starId), isNull);
              expect(missing.missingInputs, isPositive);
            }
            expect(
              keep(
                chart.modify(const ZiweiPlacementPatch(day: 15)),
              ).summary.bureau,
              bureau,
            );
          }
        },
      );
      test(
        'reject integers before FFI narrowing, malformed decimal strings',
        () {
          for (final value in [-1, 259200, 0x100000000]) {
            expect(
              () => c.castingFromIndex(value, gender: ZiweiGender.male),
              throwsRangeError,
            );
          }
          for (final value in ['', '-1', '１２', '123\u0000bad', '12\n']) {
            expect(
              () => c.castingFromNumber(value, gender: ZiweiGender.male),
              throwsArgumentError,
            );
          }
          final chart = keep(c.castingFromIndex(0, gender: ZiweiGender.male));
          expect(
            () => chart.modify(const ZiweiPlacementPatch(month: 0x100000001)),
            throwsRangeError,
          );
          expect(() => chart.shiftLifePalace(0x100000001), throwsRangeError);
          expect(
            () => c.createCastingChart(
              const ZiweiPlacementInput(hourBranch: -1),
              gender: ZiweiGender.male,
            ),
            throwsRangeError,
          );
        },
      );
      test('natal immutable edits clear flow stack and restore original', () {
        final chart = c
            .calculateLocal(
              AstroDateTime(2003, 3, 13, 14, 15),
              gender: ZiweiGender.male,
            )
            .value;
        final edited = chart.modify(
          const ZiweiPlacementPatch(month: 3, day: 30, updateBureau: true),
        );
        final shifted = edited.shiftLifePalace(-1), reset = shifted.reset();
        try {
          expect(edited.flowLayerCount, 0);
          expect(edited.placement.input.day, 30);
          expect(reset.anchors.values, chart.anchors.values);
          expect(chart.placement.overrides.day, isNull);
          final target = AstroDateTime(2026, 5, 1, 12);
          edited.setFlow(
            targetInstantUtc: target.toJulianDate<UtcScale>().addSeconds(
              -8 * 3600,
            ),
            targetVirtualTime: target,
          );
          expect(edited.flowLayerCount, greaterThan(0));
          expect(chart.flowLayerCount, 0);
        } finally {
          reset.close();
          shifted.close();
          edited.close();
          chart.close();
        }
      });
      test('independent isolates can cast and edit concurrently', () async {
        final path = libraryPath;
        final results = await Future.wait(
          List.generate(
            4,
            (_) => Isolate.run(() {
              final owner = Ephemeris.open(libraryPath: path).createContext();
              final c = owner.ziwei;
              final source = c.castingFromIndex(0, gender: ZiweiGender.male);
              final edited = source.modify(const ZiweiPlacementPatch(day: 15));
              source.close();
              final restored = edited.reset();
              try {
                return digest(c, restored);
              } finally {
                restored.close();
                edited.close();
                c.close();
                owner.close();
              }
            }),
          ),
        );
        expect(results, everyElement(3769082376));
      });

      test('lifetime checks and idempotent cleanup', () {
        final chart = keep(c.castingFromIndex(0, gender: ZiweiGender.male));
        c.close();
        expect(chart.reset, throwsStateError);
        chart.close();
        chart.close();
        expect(() => chart.summary, throwsStateError);
      });
    },
    skip: nativeLibraryAvailable ? false : libraryUnavailableSkip,
  );
}
