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
    'OrbitalApi native integration',
    () {
      late EphemerisContext context;
      final startUt1 = JulianDate<Ut1Scale>.fromDouble(2460409.0);

      setUp(() {
        context = Ephemeris.open(
          libraryPath: libraryPath,
          options: RuntimeOptions(
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
        final result = context.orbits.osculatingAtUt1(Body.moon, startUt1);
        final orbit = result;

        expect(orbit.body, Body.moon);
        expect(orbit.center, Body.earth);
        expect(orbit.referenceFrame, ApparentFrame.j2000Ecliptic);
        expect(orbit.eccentricity, inInclusiveRange(0.01, 0.2));
        expect(orbit.osculatingPeriodDays, inInclusiveRange(20.0, 35.0));
        expect(orbit.periapsisDistanceAu, lessThan(orbit.currentDistanceAu));
        expect(orbit.currentDistanceAu, lessThan(orbit.apoapsisDistanceAu));
        expect(orbit.gravitationalParameterAu3PerDay2, greaterThan(0.0));
        expect(context.lastDiagnostic?.status, 0);
        expect(context.lastDiagnostic?.targetId, Body.moon.id);
      });

      test('ports the osculating reference-point geometry checks', () {
        final orbit = context.orbits.osculatingAtUt1(Body.moon, startUt1);
        final points = context.orbits.referencePointsAtUt1(Body.moon, startUt1);

        expect(points.body, Body.moon);
        expect(points.center, Body.earth);
        expect(points.model, OrbitReferencePointModel.osculating);
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
        final utOrbit = context.orbits.osculatingAtUt1(Body.moon, startUt1);
        final ttOrbit = context.orbits.osculatingAtTt(Body.moon, tt);
        final utPoints = context.orbits.referencePointsAtUt1(
          Body.moon,
          startUt1,
        );
        final ttPoints = context.orbits.referencePointsAtTt(Body.moon, tt);

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
        for (final frame in ApparentFrame.values.where(
          (value) => value != ApparentFrame.unknown,
        )) {
          final orbit = context.orbits.osculatingAtUt1(
            Body.moon,
            startUt1,
            referenceFrame: frame,
          );
          expect(orbit.referenceFrame, frame);
          expect(orbit.rawReferenceFrameId, frame.id);
        }
      });

      test('ports lunar apsis and node Swiss Ephemeris oracles', () {
        final perigee = context.orbits.searchApsisFromUt1(
          Body.moon,
          ApsisKind.pericenter,
          startUt1,
        );
        final previousApogee = context.orbits.searchApsisFromUt1(
          Body.moon,
          ApsisKind.apocenter,
          startUt1,
          direction: OrbitalSearchDirection.reverse,
        );
        final ascendingNode = context.orbits.searchPlaneNodeFromUt1(
          Body.moon,
          PlaneNodeKind.ascending,
          startUt1,
        );
        final previousAscendingNode = context.orbits.searchPlaneNodeFromUt1(
          Body.moon,
          PlaneNodeKind.ascending,
          startUt1,
          direction: OrbitalSearchDirection.reverse,
        );

        expect(
          perigee.coordinate.toDouble(),
          closeTo(2460436.4196451753, 1e-4),
        );
        expect(perigee.radialVelocityAuPerDay.abs(), lessThan(1e-8));
        expect(perigee.kind, ApsisKind.pericenter);
        expect(perigee.direction, OrbitalSearchDirection.forward);
        expect(perigee.iterationCount, greaterThan(0));
        expect(perigee.evaluationCount, greaterThan(0));

        expect(
          previousApogee.coordinate.toDouble(),
          closeTo(2460393.1562406393, 1e-4),
        );
        expect(previousApogee.coordinate.isBefore(startUt1), isTrue);
        expect(previousApogee.direction, OrbitalSearchDirection.reverse);

        expect(
          ascendingNode.coordinate.toDouble(),
          closeTo(2460409.0138973210, 1e-4),
        );
        expect(ascendingNode.kind, PlaneNodeKind.ascending);
        expect(ascendingNode.referenceFrame, ApparentFrame.j2000Ecliptic);
        expect(ascendingNode.referencePlaneAngleRadians.isFinite, isTrue);

        expect(previousAscendingNode.coordinate.isBefore(startUt1), isTrue);
        expect(previousAscendingNode.kind, PlaneNodeKind.ascending);
        expect(previousAscendingNode.direction, OrbitalSearchDirection.reverse);
      });

      test('TT and UT1 event searches preserve their time-scale types', () {
        final perigeeUt1 = context.orbits.searchApsisFromUt1(
          Body.moon,
          ApsisKind.pericenter,
          startUt1,
        );
        final perigeeTt = context.orbits.searchApsisFromTt(
          Body.moon,
          ApsisKind.pericenter,
          ttFor(startUt1),
        );
        final expectedTt = ttFor(perigeeUt1.coordinate);

        expect(perigeeUt1.coordinate, isA<JulianDate<Ut1Scale>>());
        expect(perigeeTt.coordinate, isA<JulianDate<TtScale>>());
        expect(
          perigeeTt.coordinate.toDouble(),
          closeTo(expectedTt.toDouble(), 1e-10),
        );

        final nodeTt = context.orbits.searchPlaneNodeFromTt(
          Body.moon,
          PlaneNodeKind.ascending,
          ttFor(startUt1),
        );
        expect(nodeTt.coordinate, isA<JulianDate<TtScale>>());
        expect(context.lastDiagnostic?.status, 0);
      });

      test('supports planet barycenters and explicit approximation policy', () {
        final venus = context.orbits.osculatingAtUt1(
          Body.venusBarycenter,
          startUt1,
          allowBarycenterApproximation: true,
        );

        expect(venus.center, Body.sun);
        expect(venus.semiMajorAxisAu, inInclusiveRange(0.6, 0.85));
        expect(venus.eccentricity, inInclusiveRange(0.0, 0.05));
        expect(venus.allowBarycenterApproximation, isTrue);
      });

      test('rejects unsupported inputs and use after close', () {
        expect(
          () => context.orbits.osculatingAtUt1(Body.sun, startUt1),
          throwsArgumentError,
        );
        expect(
          () => context.orbits.osculatingAtUt1(
            Body.moon,
            startUt1,
            referenceFrame: ApparentFrame.unknown,
          ),
          throwsArgumentError,
        );

        context.close();
        expect(
          () => context.orbits.osculatingAtUt1(Body.moon, startUt1),
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
