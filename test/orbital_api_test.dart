import 'dart:io';

import 'package:taiyin/taiyin.dart';
import 'package:test/test.dart';
import 'support/native_library.dart';

void main() {
  final opm2DataPath =
      Platform.environment['TAIYIN_OPM2_DATA_DIR'] ??
      '../taiyin-ephemeris/data/ephemerides/opm2/major-bodies/600y';
  final opm2DataAvailable = Directory(opm2DataPath).existsSync();

  group(
    'TaiyinOrbitalApi native integration',
    () {
      late TaiyinContext context;
      final startUt1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);

      setUp(() {
        context = Taiyin.open(
          libraryPath: libraryPath,
          options: TaiyinRuntimeOptions(
            sourcePaths: [opm2DataPath],
            loadPackagedData: false,
          ),
        ).createContext();
      });

      tearDown(() {
        context.close();
      });

      JulianDate<TtScale> ttFor(JulianDate<Ut1Scale> ut1) {
        return context.time.ut1ToTt(
          ut1,
          deltaTSeconds: context.time.estimatedDeltaTFromUt1(ut1),
        );
      }

      test('ports the Moon osculating-orbit physical checks', () {
        final result = context.orbits.osculatingAtUt1(
          TaiyinBody.moon,
          startUt1,
        );
        final orbit = result.value;

        expect(orbit.body, TaiyinBody.moon);
        expect(orbit.center, TaiyinBody.earth);
        expect(orbit.referenceFrame, TaiyinApparentFrame.j2000Ecliptic);
        expect(orbit.eccentricity, inInclusiveRange(0.01, 0.2));
        expect(orbit.osculatingPeriodDays, inInclusiveRange(20.0, 35.0));
        expect(orbit.periapsisDistanceAu, lessThan(orbit.currentDistanceAu));
        expect(orbit.currentDistanceAu, lessThan(orbit.apoapsisDistanceAu));
        expect(orbit.gravitationalParameterAu3PerDay2, greaterThan(0.0));
        expect(result.diagnostic.status, 0);
        expect(result.diagnostic.targetId, TaiyinBody.moon.id);
      });

      test('ports the osculating reference-point geometry checks', () {
        final orbit = context.orbits
            .osculatingAtUt1(TaiyinBody.moon, startUt1)
            .value;
        final points = context.orbits
            .referencePointsAtUt1(TaiyinBody.moon, startUt1)
            .value;

        expect(points.body, TaiyinBody.moon);
        expect(points.center, TaiyinBody.earth);
        expect(points.model, TaiyinOrbitReferencePointModel.osculating);
        expect(points.rawModelId, 0);
        expect(points.ascendingNode.positionAu.z, 0.0);
        expect(points.descendingNode.positionAu.z, 0.0);
        expect(
          points.ascendingNode.longitudeRadians,
          closeTo(orbit.longitudeOfAscendingNodeRadians, 1e-12),
        );
        expect(
          points.periapsis.distanceAu,
          closeTo(orbit.periapsisDistanceAu, 1e-15),
        );
        expect(
          points.apoapsis.distanceAu,
          closeTo(orbit.apoapsisDistanceAu, 1e-15),
        );
        expect(
          points.secondFocus.distanceAu,
          closeTo(2.0 * orbit.semiMajorAxisAu * orbit.eccentricity, 1e-15),
        );
        final periapsis = points.periapsis.positionAu;
        final apoapsis = points.apoapsis.positionAu;
        final dot =
            periapsis.x * apoapsis.x +
            periapsis.y * apoapsis.y +
            periapsis.z * apoapsis.z;
        expect(dot, lessThan(0.0));
      });

      test('TT and UT1 orbit and reference-point routes agree', () {
        final tt = ttFor(startUt1);
        final utOrbit = context.orbits
            .osculatingAtUt1(TaiyinBody.moon, startUt1)
            .value;
        final ttOrbit = context.orbits
            .osculatingAtTt(TaiyinBody.moon, tt)
            .value;
        final utPoints = context.orbits
            .referencePointsAtUt1(TaiyinBody.moon, startUt1)
            .value;
        final ttPoints = context.orbits
            .referencePointsAtTt(TaiyinBody.moon, tt)
            .value;

        expect(
          ttOrbit.currentDistanceAu,
          closeTo(utOrbit.currentDistanceAu, 1e-13),
        );
        expect(ttOrbit.eccentricity, closeTo(utOrbit.eccentricity, 1e-13));
        expect(
          ttPoints.periapsis.longitudeRadians,
          closeTo(utPoints.periapsis.longitudeRadians, 1e-12),
        );
      });

      test('supports every native orbital reference frame', () {
        for (final frame in TaiyinApparentFrame.values.where(
          (value) => value != TaiyinApparentFrame.unknown,
        )) {
          final orbit = context.orbits
              .osculatingAtUt1(TaiyinBody.moon, startUt1, referenceFrame: frame)
              .value;
          expect(orbit.referenceFrame, frame);
          expect(orbit.rawReferenceFrameId, frame.id);
        }
      });

      test('ports lunar apsis and node Swiss Ephemeris oracles', () {
        final perigee = context.orbits
            .searchApsisFromUt1(
              TaiyinBody.moon,
              TaiyinApsisKind.pericenter,
              startUt1,
            )
            .value;
        final previousApogee = context.orbits
            .searchApsisFromUt1(
              TaiyinBody.moon,
              TaiyinApsisKind.apocenter,
              startUt1,
              direction: TaiyinOrbitalSearchDirection.reverse,
            )
            .value;
        final ascendingNode = context.orbits
            .searchPlaneNodeFromUt1(
              TaiyinBody.moon,
              TaiyinPlaneNodeKind.ascending,
              startUt1,
            )
            .value;
        final previousAscendingNode = context.orbits
            .searchPlaneNodeFromUt1(
              TaiyinBody.moon,
              TaiyinPlaneNodeKind.ascending,
              startUt1,
              direction: TaiyinOrbitalSearchDirection.reverse,
            )
            .value;

        expect(
          perigee.coordinate.toDouble(),
          closeTo(2460436.4196451753, 1e-4),
        );
        expect(perigee.radialVelocityAuPerDay.abs(), lessThan(1e-8));
        expect(perigee.kind, TaiyinApsisKind.pericenter);
        expect(perigee.direction, TaiyinOrbitalSearchDirection.forward);
        expect(perigee.iterationCount, greaterThan(0));
        expect(perigee.evaluationCount, greaterThan(0));

        expect(
          previousApogee.coordinate.toDouble(),
          closeTo(2460393.1562406393, 1e-4),
        );
        expect(previousApogee.coordinate.isBefore(startUt1), isTrue);
        expect(previousApogee.direction, TaiyinOrbitalSearchDirection.reverse);

        expect(
          ascendingNode.coordinate.toDouble(),
          closeTo(2460409.0138973210, 1e-4),
        );
        expect(ascendingNode.kind, TaiyinPlaneNodeKind.ascending);
        expect(ascendingNode.referenceFrame, TaiyinApparentFrame.j2000Ecliptic);
        expect(ascendingNode.referencePlaneAngleRadians.isFinite, isTrue);

        expect(previousAscendingNode.coordinate.isBefore(startUt1), isTrue);
        expect(previousAscendingNode.kind, TaiyinPlaneNodeKind.ascending);
        expect(
          previousAscendingNode.direction,
          TaiyinOrbitalSearchDirection.reverse,
        );
      });

      test('TT and UT1 event searches preserve their time-scale types', () {
        final perigeeUt1 = context.orbits
            .searchApsisFromUt1(
              TaiyinBody.moon,
              TaiyinApsisKind.pericenter,
              startUt1,
            )
            .value;
        final perigeeTt = context.orbits
            .searchApsisFromTt(
              TaiyinBody.moon,
              TaiyinApsisKind.pericenter,
              ttFor(startUt1),
            )
            .value;
        final expectedTt = ttFor(perigeeUt1.coordinate);

        expect(perigeeUt1.coordinate, isA<JulianDate<Ut1Scale>>());
        expect(perigeeTt.coordinate, isA<JulianDate<TtScale>>());
        expect(
          perigeeTt.coordinate.toDouble(),
          closeTo(expectedTt.toDouble(), 1e-10),
        );

        final nodeTt = context.orbits.searchPlaneNodeFromTt(
          TaiyinBody.moon,
          TaiyinPlaneNodeKind.ascending,
          ttFor(startUt1),
        );
        expect(nodeTt.value.coordinate, isA<JulianDate<TtScale>>());
        expect(nodeTt.diagnostic.status, 0);
      });

      test('supports planet barycenters and explicit approximation policy', () {
        final venus = context.orbits
            .osculatingAtUt1(
              TaiyinBody.venusBarycenter,
              startUt1,
              allowBarycenterApproximation: true,
            )
            .value;

        expect(venus.center, TaiyinBody.sun);
        expect(venus.semiMajorAxisAu, inInclusiveRange(0.6, 0.85));
        expect(venus.eccentricity, inInclusiveRange(0.0, 0.05));
        expect(venus.allowBarycenterApproximation, isTrue);
      });

      test('rejects unsupported inputs and use after close', () {
        expect(
          () => context.orbits.osculatingAtUt1(TaiyinBody.sun, startUt1),
          throwsArgumentError,
        );
        expect(
          () => context.orbits.osculatingAtUt1(
            TaiyinBody.moon,
            startUt1,
            referenceFrame: TaiyinApparentFrame.unknown,
          ),
          throwsArgumentError,
        );

        context.close();
        expect(
          () => context.orbits.osculatingAtUt1(TaiyinBody.moon, startUt1),
          throwsStateError,
        );
      });
    },
    skip: !nativeLibraryAvailable
        ? 'Set TAIYIN_TEST_LIBRARY to a built Taiyin shared library.'
        : !opm2DataAvailable
        ? 'Set TAIYIN_OPM2_DATA_DIR to the major-bodies/600y data directory.'
        : false,
  );
}
