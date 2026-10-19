import 'package:ephemeris/ephemeris.dart';

/// Stable field-by-field comparison, including nullable contacts and full paths.
List<num> eclipseSnapshot(Object? value) {
  if (value == null) return [0];
  if (value is num) return value.isFinite ? [1, value] : [2];
  if (value is bool) return [value ? 3 : 4];
  if (value is Enum) return [5, value.index];
  if (value is JulianDate<TimeScale>) {
    return [6, value.dayNumber, value.dayFraction];
  }
  if (value is Iterable<Object?>) {
    return [7, value.length, for (final v in value) ...eclipseSnapshot(v)];
  }
  if (value is Map<Object?, Object?>) {
    return [
      8,
      value.length,
      for (final e in value.entries) ...[
        ...eclipseSnapshot(e.key),
        ...eclipseSnapshot(e.value),
      ],
    ];
  }
  if (value is LocalLunarEclipseContact<TimeScale>) {
    return [
      9,
      ...eclipseSnapshot(value.coordinate),
      ...eclipseSnapshot(value.moonAltitudeDegrees),
      ...eclipseSnapshot(value.moonAzimuthDegrees),
    ];
  }
  if (value is LunarEclipseResult<TimeScale>) {
    return [
      9,
      ...eclipseSnapshot(value.kinds),
      ...eclipseSnapshot(value.maximum),
      ...eclipseSnapshot(_scaled(value.deltaTSeconds)),
      ...eclipseSnapshot(value.umbralMagnitude),
      ...eclipseSnapshot(value.penumbralMagnitude),
      ...eclipseSnapshot(value.axisDistanceRadians),
      ...eclipseSnapshot(value.umbraRadiusRadians),
      ...eclipseSnapshot(value.penumbraRadiusRadians),
      ...eclipseSnapshot(value.moonRadiusRadians),
      ...eclipseSnapshot(value.contacts),
    ];
  }
  if (value is LocalLunarEclipseResult<TimeScale>) {
    return [
      9,
      ...eclipseSnapshot(value.kinds),
      ...eclipseSnapshot(value.visibility),
      ...eclipseSnapshot(value.maximum),
      ...eclipseSnapshot(_scaled(value.deltaTSeconds)),
      ...eclipseSnapshot(value.umbralMagnitude),
      ...eclipseSnapshot(value.penumbralMagnitude),
      ...eclipseSnapshot(value.contacts),
      ...eclipseSnapshot(value.moonrise),
      ...eclipseSnapshot(value.moonset),
    ];
  }
  if (value is SolarEclipseResult<TimeScale>) {
    return [
      9,
      ...eclipseSnapshot(value.kinds),
      ...eclipseSnapshot(value.maximum),
      ...eclipseSnapshot(_scaled(value.deltaTSeconds)),
      ...eclipseSnapshot(_scaled(value.axisDistanceKilometers)),
      ...eclipseSnapshot(_scaled(value.penumbraRadiusKilometers)),
      ...eclipseSnapshot(_scaled(value.coreRadiusKilometers)),
      ...eclipseSnapshot(_scaled(value.penumbralMarginKilometers)),
      ...eclipseSnapshot(_scaled(value.centralMarginKilometers)),
      ...eclipseSnapshot(value.maximumLatitudeDegrees),
      ...eclipseSnapshot(value.maximumLongitudeDegrees),
      ...eclipseSnapshot(value.contacts),
    ];
  }
  if (value is LocalSolarEclipseResult<TimeScale>) {
    return [
      9,
      ...eclipseSnapshot(value.kinds),
      ...eclipseSnapshot(value.visibility),
      ...eclipseSnapshot(value.maximum),
      ...eclipseSnapshot(_scaled(value.deltaTSeconds)),
      ...eclipseSnapshot(value.magnitude),
      ...eclipseSnapshot(value.obscuration),
      ...eclipseSnapshot(value.sunAltitudeDegrees),
      ...eclipseSnapshot(value.sunAzimuthDegrees),
      ...eclipseSnapshot(value.contacts),
      ...eclipseSnapshot(value.positionAngleC1Degrees),
      ...eclipseSnapshot(value.positionAngleC4Degrees),
      ...eclipseSnapshot(value.vertexAngleC1Degrees),
      ...eclipseSnapshot(value.vertexAngleC4Degrees),
      ...eclipseSnapshot(value.sunriseMagnitude),
      ...eclipseSnapshot(value.sunsetMagnitude),
      ...eclipseSnapshot(_scaled(value.durationSeconds)),
      ...eclipseSnapshot(value.moonSunRadiusRatio),
    ];
  }
  if (value is LocalSolarEclipseCircumstances<TimeScale>) {
    return [
      9,
      ...eclipseSnapshot(value.coordinate),
      ...eclipseSnapshot(_scaled(value.deltaTSeconds)),
      ...eclipseSnapshot(value.magnitude),
      ...eclipseSnapshot(value.obscuration),
      ...eclipseSnapshot(value.centerSeparationDegrees),
      ...eclipseSnapshot(value.sunAngularRadiusDegrees),
      ...eclipseSnapshot(value.moonAngularRadiusDegrees),
      ...eclipseSnapshot(value.sunAltitudeDegrees),
      ...eclipseSnapshot(value.sunAzimuthDegrees),
    ];
  }
  if (value is SolarEclipseRoutePoint) {
    return [
      9,
      ...eclipseSnapshot(value.coordinateTt),
      ...eclipseSnapshot(value.coordinateUt1),
      ...eclipseSnapshot(value.latitudeDegrees),
      ...eclipseSnapshot(value.longitudeDegrees),
      ...eclipseSnapshot(value.elevationMeters),
      ...eclipseSnapshot(value.sunAltitudeDegrees),
      ...eclipseSnapshot(value.sunAzimuthDegrees),
    ];
  }
  if (value is SolarEclipseRouteRow) {
    return [
      9,
      ...eclipseSnapshot(value.coordinateTt),
      ...eclipseSnapshot(value.coordinateUt1),
      ...eclipseSnapshot(value.centerLine),
      ...eclipseSnapshot(value.penumbralNorthLimit),
      ...eclipseSnapshot(value.penumbralSouthLimit),
      ...eclipseSnapshot(value.northLimit),
      ...eclipseSnapshot(value.southLimit),
      ...eclipseSnapshot(value.halfMagnitudeNorthLimit),
      ...eclipseSnapshot(value.halfMagnitudeSouthLimit),
      ...eclipseSnapshot(_scaled(value.pathWidthKilometers)),
      ...eclipseSnapshot(_scaled(value.durationSeconds)),
      ...eclipseSnapshot(value.sunAltitudeDegrees),
      ...eclipseSnapshot(value.sunAzimuthDegrees),
    ];
  }
  if (value is SolarEclipseWhere) {
    return [
      9,
      ...eclipseSnapshot(value.coordinateTt),
      ...eclipseSnapshot(value.coordinateUt1),
      ...eclipseSnapshot(value.centerLine),
      ...eclipseSnapshot(value.penumbralNorthLimit),
      ...eclipseSnapshot(value.penumbralSouthLimit),
      ...eclipseSnapshot(value.northLimit),
      ...eclipseSnapshot(value.southLimit),
      ...eclipseSnapshot(value.magnitude),
      ...eclipseSnapshot(value.obscuration),
      ...eclipseSnapshot(value.centerSeparationDegrees),
      ...eclipseSnapshot(value.sunAngularRadiusDegrees),
      ...eclipseSnapshot(value.moonAngularRadiusDegrees),
    ];
  }
  if (value is SolarEclipseRouteCurvePoint) {
    return [
      9,
      ...eclipseSnapshot(value.coordinateTt),
      ...eclipseSnapshot(value.coordinateUt1),
      ...eclipseSnapshot(value.kind),
      ...eclipseSnapshot(value.latitudeDegrees),
      ...eclipseSnapshot(value.longitudeDegrees),
    ];
  }
  if (value is SolarEclipseRouteProductPoint) {
    return [
      9,
      ...eclipseSnapshot(value.coordinateTt),
      ...eclipseSnapshot(value.coordinateUt1),
      ...eclipseSnapshot(value.kind),
      ...eclipseSnapshot(value.sourceCurveKind),
      ...eclipseSnapshot(value.latitudeDegrees),
      ...eclipseSnapshot(value.longitudeDegrees),
      ...eclipseSnapshot(value.unwrappedLongitudeDegrees),
    ];
  }
  if (value is SolarEclipseRouteProductSummary) {
    return [
      9,
      ...eclipseSnapshot(value.flags),
      ...eclipseSnapshot(value.curvePointCount),
      ...eclipseSnapshot(value.centerLineCount),
      ...eclipseSnapshot(value.coreNorthCount),
      ...eclipseSnapshot(value.coreSouthCount),
      ...eclipseSnapshot(value.coreBeginHorizonCount),
      ...eclipseSnapshot(value.coreEndHorizonCount),
      ...eclipseSnapshot(value.penumbralNorthCount),
      ...eclipseSnapshot(value.penumbralSouthCount),
      ...eclipseSnapshot(value.halfMagnitudeNorthCount),
      ...eclipseSnapshot(value.halfMagnitudeSouthCount),
      ...eclipseSnapshot(value.corePolygonPointCount),
      ...eclipseSnapshot(value.penumbralPolygonPointCount),
      ...eclipseSnapshot(value.halfMagnitudePolygonPointCount),
      ...eclipseSnapshot(value.polygonPointCount),
      ...eclipseSnapshot(value.minimumLatitudeDegrees),
      ...eclipseSnapshot(value.maximumLatitudeDegrees),
      ...eclipseSnapshot(value.minimumUnwrappedLongitudeDegrees),
      ...eclipseSnapshot(value.maximumUnwrappedLongitudeDegrees),
    ];
  }
  if (value is SolarEclipseRouteProduct) {
    return [
      9,
      ...eclipseSnapshot(value.points),
      ...eclipseSnapshot(value.summary),
    ];
  }
  if (value is LocalSolarEclipseBoundary) {
    return [
      9,
      ...eclipseSnapshot(value.centerKinds),
      ...eclipseSnapshot(value.centerLongitudeDegrees),
      ...eclipseSnapshot(value.centerLatitudeDegrees),
      ...eclipseSnapshot(value.umbraNorthLongitudeDegrees),
      ...eclipseSnapshot(value.umbraNorthLatitudeDegrees),
      ...eclipseSnapshot(value.umbraSouthLongitudeDegrees),
      ...eclipseSnapshot(value.umbraSouthLatitudeDegrees),
      ...eclipseSnapshot(value.penumbraNorthLongitudeDegrees),
      ...eclipseSnapshot(value.penumbraNorthLatitudeDegrees),
      ...eclipseSnapshot(value.penumbraSouthLongitudeDegrees),
      ...eclipseSnapshot(value.penumbraSouthLatitudeDegrees),
      ...eclipseSnapshot(_scaled(value.umbraWidthKilometers)),
    ];
  }
  if (value is SolarBesselianElements) {
    return [
      9,
      ...eclipseSnapshot(value.tHours),
      ...eclipseSnapshot(value.x),
      ...eclipseSnapshot(value.y),
      ...eclipseSnapshot(value.zeta),
      ...eclipseSnapshot(value.dDegrees),
      ...eclipseSnapshot(value.muDegrees),
      ...eclipseSnapshot(value.l1),
      ...eclipseSnapshot(value.l2),
      ...eclipseSnapshot(value.f1Degrees),
      ...eclipseSnapshot(value.f2Degrees),
      ...eclipseSnapshot(value.tanF1),
      ...eclipseSnapshot(value.tanF2),
      ...eclipseSnapshot(value.gamma),
    ];
  }
  if (value is SolarBesselianPolynomial) {
    return [
      9,
      ...eclipseSnapshot(value.referenceEpoch),
      ...eclipseSnapshot(value.spanHours),
      ...eclipseSnapshot(value.sampleStepHours),
      ...eclipseSnapshot(value.degree),
      ...eclipseSnapshot(value.xCoefficients),
      ...eclipseSnapshot(value.yCoefficients),
      ...eclipseSnapshot(value.zetaCoefficients),
      ...eclipseSnapshot(value.dDegreesCoefficients),
      ...eclipseSnapshot(value.muDegreesCoefficients),
      ...eclipseSnapshot(value.l1Coefficients),
      ...eclipseSnapshot(value.l2Coefficients),
      ...eclipseSnapshot(value.f1Degrees),
      ...eclipseSnapshot(value.f2Degrees),
      ...eclipseSnapshot(value.tanF1),
      ...eclipseSnapshot(value.tanF2),
      ...eclipseSnapshot(value.center),
      ...eclipseSnapshot(value.maxResidual),
    ];
  }
  throw StateError('Missing eclipse snapshot for ${value.runtimeType}');
}

num? _scaled(num? value) => value == null ? null : value / 1000;
