import 'package:ephemeris/ephemeris.dart';
import 'backend_scenario.dart' show require;
import 'eclipse_snapshot.dart';

/// Every public eclipse operation, unchanged on native and both Web compilers.
List<Object?> exerciseEclipses(Ephemeris runtime) {
  final ctx = runtime.createContext();
  final rows = <Object?>[];
  void add<T>(String label, OperationResult<T> result) {
    rows.add({
      'label': label,
      'flags': result.flags.mask,
      'values': eclipseSnapshot(result.value),
    });
  }

  try {
    ctx.configuration.setObserverLocation(
      const ObserverLocation(longitudeDegrees: -106.4, latitudeDegrees: 23.2),
    );
    final e = ctx.eclipses;
    final tt = TtJulianDate.fromDouble(2460409.263);
    final ut = Ut1JulianDate.fromDouble(2460409.262);
    final ltt = TtJulianDate.fromDouble(2460926.26);
    final lut = Ut1JulianDate.fromDouble(2460926.25);
    final lunarTt = e.solveLunarAtTt(
      ltt,
      options: {LunarEclipseSolveOption.includeContacts},
    );
    final lunarUt = e.solveLunarAtUt1(
      lut,
      options: {LunarEclipseSolveOption.includeContacts},
    );
    require(
      lunarUt.value.contacts.values.whereType<Ut1JulianDate>().length == 7,
      'High contact flag lost',
    );
    add('eclipse/lunar/solve/tt', lunarTt);
    add('eclipse/lunar/solve/ut', lunarUt);
    add(
      'eclipse/lunar/next/tt',
      e.nextLunarAtTt(ltt, options: {LunarEclipseSearchOption.includeContacts}),
    );
    add(
      'eclipse/lunar/next/ut',
      e.nextLunarAtUt1(
        lut,
        options: {LunarEclipseSearchOption.includeContacts},
      ),
    );
    add(
      'eclipse/lunar/previous',
      e.nextLunarAtUt1(
        lut.addSeconds(86400),
        options: {
          LunarEclipseSearchOption.includeContacts,
          LunarEclipseSearchOption.backward,
        },
      ),
    );
    add(
      'eclipse/lunar/range/tt',
      e.lunarEclipsesAtTt(
        ltt.addSeconds(-86400),
        ltt.addSeconds(86400),
        maxResults: 4,
        options: {LunarEclipseSearchOption.includeContacts},
      ),
    );
    add(
      'eclipse/lunar/range/ut',
      e.lunarEclipsesAtUt1(
        lut.addSeconds(-86400),
        lut.addSeconds(86400),
        maxResults: 4,
        options: {LunarEclipseSearchOption.includeContacts},
      ),
    );
    add('eclipse/lunar/local/tt', e.localLunarVisibilityAtTt(lunarTt.value));
    add('eclipse/lunar/local/ut', e.localLunarVisibilityAtUt1(lunarUt.value));
    add(
      'eclipse/lunar/next-local/tt',
      e.nextLocalLunarAtTt(ltt.addSeconds(-86400)),
    );
    add(
      'eclipse/lunar/next-local/ut',
      e.nextLocalLunarAtUt1(lut.addSeconds(-86400)),
    );
    add(
      'eclipse/solar/solve/tt',
      e.solveSolarAtTt(tt, options: {SolarEclipseSolveOption.includeContacts}),
    );
    add(
      'eclipse/solar/solve/ut',
      e.solveSolarAtUt1(ut, options: {SolarEclipseSolveOption.includeContacts}),
    );
    add(
      'eclipse/solar/next/tt',
      e.nextSolarAtTt(
        tt.addSeconds(-86400),
        options: {SolarEclipseSearchOption.includeContacts},
      ),
    );
    add(
      'eclipse/solar/next/ut',
      e.nextSolarAtUt1(
        ut.addSeconds(-86400),
        options: {SolarEclipseSearchOption.includeContacts},
      ),
    );
    add(
      'eclipse/solar/range/tt',
      e.solarEclipsesAtTt(
        tt.addSeconds(-86400),
        tt.addSeconds(86400),
        maxResults: 4,
      ),
    );
    add(
      'eclipse/solar/range/ut',
      e.solarEclipsesAtUt1(
        ut.addSeconds(-86400),
        ut.addSeconds(86400),
        maxResults: 4,
      ),
    );
    add('eclipse/solar/local/tt', e.solveLocalSolarAtTt(tt));
    add('eclipse/solar/local/ut', e.solveLocalSolarAtUt1(ut));
    add(
      'eclipse/solar/next-local/tt',
      e.nextLocalSolarAtTt(tt.addSeconds(-86400)),
    );
    add(
      'eclipse/solar/next-local/ut',
      e.nextLocalSolarAtUt1(ut.addSeconds(-86400)),
    );
    add('eclipse/solar/circumstances/tt', e.localSolarCircumstancesAtTt(tt));
    add('eclipse/solar/circumstances/ut', e.localSolarCircumstancesAtUt1(ut));
    add('eclipse/bessel/elements', e.solarBesselianElementsAtTt(tt));
    final poly = e.solarBesselianPolynomialAtTt(
      tt,
      spanHours: 3,
      sampleStepHours: 0.5,
    );
    add('eclipse/bessel/polynomial', poly);
    add(
      'eclipse/bessel/evaluate',
      e.evaluateSolarBesselianPolynomial(poly.value, 0.25),
    );
    add('eclipse/route/row/tt', e.solarEclipseRouteRowAtTt(tt));
    add('eclipse/route/row/ut', e.solarEclipseRouteRowAtUt1(ut));
    add('eclipse/route/where/tt', e.solarEclipseWhereAtTt(tt));
    add('eclipse/route/where/ut', e.solarEclipseWhereAtUt1(ut));
    add(
      'eclipse/route/range/tt',
      e.solarEclipseRouteAtTt(
        tt,
        tt.addSeconds(60),
        stepMinutes: 1,
        maxRows: 4,
      ),
    );
    add(
      'eclipse/route/range/ut',
      e.solarEclipseRouteAtUt1(
        ut,
        ut.addSeconds(60),
        stepMinutes: 1,
        maxRows: 4,
      ),
    );
    add(
      'eclipse/route/curves/tt',
      e.solarEclipseRouteCurvesAtTt(tt, routeSampleCount: 32),
    );
    add(
      'eclipse/route/curves/ut',
      e.solarEclipseRouteCurvesAtUt1(ut, routeSampleCount: 32),
    );
    add(
      'eclipse/route/product/tt',
      e.solarEclipseRouteProductAtTt(tt, routeSampleCount: 32),
    );
    add(
      'eclipse/route/product/ut',
      e.solarEclipseRouteProductAtUt1(ut, routeSampleCount: 32),
    );
    add(
      'eclipse/route/map/tt',
      e.solarEclipseRouteMapProductAtTt(tt, routeSampleCount: 32),
    );
    add(
      'eclipse/route/map/ut',
      e.solarEclipseRouteMapProductAtUt1(ut, routeSampleCount: 32),
    );
    add(
      'eclipse/route/boundary/tt',
      e.localSolarEclipseBoundaryAtTt(
        tt,
        longitudeDegrees: -106.4,
        latitudeDegrees: 23.2,
      ),
    );
    add(
      'eclipse/route/boundary/ut',
      e.localSolarEclipseBoundaryAtUt1(
        ut,
        longitudeDegrees: -106.4,
        latitudeDegrees: 23.2,
      ),
    );
    try {
      e.solveSolarAtTt(tt, positionFlags: {PositionFlag.speed});
      throw StateError('Unsupported flags accepted');
    } on ArgumentError {
      /* same validation */
    }
    try {
      e.solveLocalSolarAtTt(
        tt,
        visibilityOptions: {
          LocalSolarEclipseVisibilityOption.strictMeteorology,
        },
      );
      throw StateError('Invalid meteorology accepted');
    } on ArgumentError {
      /* strict requires refraction */
    }
    ctx.close();
    try {
      e.solveSolarAtTt(tt);
      throw StateError('Closed context accepted');
    } on StateError catch (error) {
      require(error.message.toString().contains('closed'), 'Wrong close error');
    }
  } finally {
    ctx.close();
  }
  return rows;
}
