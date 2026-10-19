// Generated field-wise transport DTOs; not native struct offsets.
// ignore_for_file: camel_case_types, non_constant_identifier_names

final class Web_taiyin_split_julian_date {
  const Web_taiyin_split_julian_date(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 2;
  int get day_number => values[offset + 0].toInt();
  double get day_fraction => values[offset + 1];
}

final class Web_taiyin_lunar_eclipse_result_tt {
  const Web_taiyin_lunar_eclipse_result_tt(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 23;
  int get kind => values[offset + 0].toInt();
  Web_taiyin_split_julian_date get maximum_jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 1);
  double get umbral_magnitude => values[offset + 3];
  double get penumbral_magnitude => values[offset + 4];
  double get axis_distance_rad => values[offset + 5];
  double get umbra_radius_rad => values[offset + 6];
  double get penumbra_radius_rad => values[offset + 7];
  double get moon_radius_rad => values[offset + 8];
  List<Web_taiyin_split_julian_date> get contact_jd_tt => List.generate(
    7,
    (i) => Web_taiyin_split_julian_date(values, offset + 9 + i * 2),
    growable: false,
  );
}

final class Web_taiyin_lunar_eclipse_result_ut {
  const Web_taiyin_lunar_eclipse_result_ut(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 24;
  int get kind => values[offset + 0].toInt();
  Web_taiyin_split_julian_date get maximum_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 1);
  double get delta_t_seconds => values[offset + 3];
  double get umbral_magnitude => values[offset + 4];
  double get penumbral_magnitude => values[offset + 5];
  double get axis_distance_rad => values[offset + 6];
  double get umbra_radius_rad => values[offset + 7];
  double get penumbra_radius_rad => values[offset + 8];
  double get moon_radius_rad => values[offset + 9];
  List<Web_taiyin_split_julian_date> get contact_jd_ut => List.generate(
    7,
    (i) => Web_taiyin_split_julian_date(values, offset + 10 + i * 2),
    growable: false,
  );
}

final class Web_taiyin_local_lunar_eclipse_result_tt {
  const Web_taiyin_local_lunar_eclipse_result_tt(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 38;
  int get eclipse_kind => values[offset + 0].toInt();
  int get visibility_flags => values[offset + 1].toInt();
  Web_taiyin_split_julian_date get maximum_jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 2);
  double get umbral_magnitude => values[offset + 4];
  double get penumbral_magnitude => values[offset + 5];
  List<Web_taiyin_split_julian_date> get contact_jd_tt => List.generate(
    7,
    (i) => Web_taiyin_split_julian_date(values, offset + 6 + i * 2),
    growable: false,
  );
  List<double> get contact_moon_altitude_deg =>
      List.generate(7, (i) => values[offset + 20 + i], growable: false);
  List<double> get contact_moon_azimuth_deg =>
      List.generate(7, (i) => values[offset + 27 + i], growable: false);
  Web_taiyin_split_julian_date get moonrise_jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 34);
  Web_taiyin_split_julian_date get moonset_jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 36);
}

final class Web_taiyin_local_lunar_eclipse_result_ut {
  const Web_taiyin_local_lunar_eclipse_result_ut(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 39;
  int get eclipse_kind => values[offset + 0].toInt();
  int get visibility_flags => values[offset + 1].toInt();
  Web_taiyin_split_julian_date get maximum_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 2);
  double get delta_t_seconds => values[offset + 4];
  double get umbral_magnitude => values[offset + 5];
  double get penumbral_magnitude => values[offset + 6];
  List<Web_taiyin_split_julian_date> get contact_jd_ut => List.generate(
    7,
    (i) => Web_taiyin_split_julian_date(values, offset + 7 + i * 2),
    growable: false,
  );
  List<double> get contact_moon_altitude_deg =>
      List.generate(7, (i) => values[offset + 21 + i], growable: false);
  List<double> get contact_moon_azimuth_deg =>
      List.generate(7, (i) => values[offset + 28 + i], growable: false);
  Web_taiyin_split_julian_date get moonrise_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 35);
  Web_taiyin_split_julian_date get moonset_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 37);
}

final class Web_taiyin_solar_eclipse_result_tt {
  const Web_taiyin_solar_eclipse_result_tt(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 20;
  int get kind => values[offset + 0].toInt();
  Web_taiyin_split_julian_date get maximum_jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 1);
  double get axis_distance_km => values[offset + 3];
  double get penumbra_radius_km => values[offset + 4];
  double get core_radius_km => values[offset + 5];
  double get penumbral_margin_km => values[offset + 6];
  double get central_margin_km => values[offset + 7];
  double get maximum_latitude_deg => values[offset + 8];
  double get maximum_longitude_deg => values[offset + 9];
  List<Web_taiyin_split_julian_date> get contact_jd_tt => List.generate(
    5,
    (i) => Web_taiyin_split_julian_date(values, offset + 10 + i * 2),
    growable: false,
  );
}

final class Web_taiyin_solar_eclipse_result_ut {
  const Web_taiyin_solar_eclipse_result_ut(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 21;
  int get kind => values[offset + 0].toInt();
  Web_taiyin_split_julian_date get maximum_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 1);
  double get delta_t_seconds => values[offset + 3];
  double get axis_distance_km => values[offset + 4];
  double get penumbra_radius_km => values[offset + 5];
  double get core_radius_km => values[offset + 6];
  double get penumbral_margin_km => values[offset + 7];
  double get central_margin_km => values[offset + 8];
  double get maximum_latitude_deg => values[offset + 9];
  double get maximum_longitude_deg => values[offset + 10];
  List<Web_taiyin_split_julian_date> get contact_jd_ut => List.generate(
    5,
    (i) => Web_taiyin_split_julian_date(values, offset + 11 + i * 2),
    growable: false,
  );
}

final class Web_taiyin_local_solar_eclipse_circumstances_tt {
  const Web_taiyin_local_solar_eclipse_circumstances_tt(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 9;
  Web_taiyin_split_julian_date get jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 0);
  double get magnitude => values[offset + 2];
  double get obscuration => values[offset + 3];
  double get center_separation_deg => values[offset + 4];
  double get sun_angular_radius_deg => values[offset + 5];
  double get moon_angular_radius_deg => values[offset + 6];
  double get sun_altitude_deg => values[offset + 7];
  double get sun_azimuth_deg => values[offset + 8];
}

final class Web_taiyin_local_solar_eclipse_circumstances_ut {
  const Web_taiyin_local_solar_eclipse_circumstances_ut(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 10;
  Web_taiyin_split_julian_date get jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 0);
  double get delta_t_seconds => values[offset + 2];
  double get magnitude => values[offset + 3];
  double get obscuration => values[offset + 4];
  double get center_separation_deg => values[offset + 5];
  double get sun_angular_radius_deg => values[offset + 6];
  double get moon_angular_radius_deg => values[offset + 7];
  double get sun_altitude_deg => values[offset + 8];
  double get sun_azimuth_deg => values[offset + 9];
}

final class Web_taiyin_local_solar_eclipse_result_tt {
  const Web_taiyin_local_solar_eclipse_result_tt(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 25;
  int get kind => values[offset + 0].toInt();
  Web_taiyin_split_julian_date get maximum_jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 1);
  double get magnitude => values[offset + 3];
  double get obscuration => values[offset + 4];
  double get sun_altitude_deg => values[offset + 5];
  double get sun_azimuth_deg => values[offset + 6];
  List<Web_taiyin_split_julian_date> get contact_jd_tt => List.generate(
    5,
    (i) => Web_taiyin_split_julian_date(values, offset + 7 + i * 2),
    growable: false,
  );
  double get position_angle_c1_deg => values[offset + 17];
  double get position_angle_c4_deg => values[offset + 18];
  double get vertex_angle_c1_deg => values[offset + 19];
  double get vertex_angle_c4_deg => values[offset + 20];
  double get sunrise_magnitude => values[offset + 21];
  double get sunset_magnitude => values[offset + 22];
  double get duration_seconds => values[offset + 23];
  double get moon_sun_radius_ratio => values[offset + 24];
}

final class Web_taiyin_local_solar_eclipse_result_ut {
  const Web_taiyin_local_solar_eclipse_result_ut(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 26;
  int get kind => values[offset + 0].toInt();
  Web_taiyin_split_julian_date get maximum_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 1);
  double get delta_t_seconds => values[offset + 3];
  double get magnitude => values[offset + 4];
  double get obscuration => values[offset + 5];
  double get sun_altitude_deg => values[offset + 6];
  double get sun_azimuth_deg => values[offset + 7];
  List<Web_taiyin_split_julian_date> get contact_jd_ut => List.generate(
    5,
    (i) => Web_taiyin_split_julian_date(values, offset + 8 + i * 2),
    growable: false,
  );
  double get position_angle_c1_deg => values[offset + 18];
  double get position_angle_c4_deg => values[offset + 19];
  double get vertex_angle_c1_deg => values[offset + 20];
  double get vertex_angle_c4_deg => values[offset + 21];
  double get sunrise_magnitude => values[offset + 22];
  double get sunset_magnitude => values[offset + 23];
  double get duration_seconds => values[offset + 24];
  double get moon_sun_radius_ratio => values[offset + 25];
}

final class Web_taiyin_local_solar_eclipse_boundary {
  const Web_taiyin_local_solar_eclipse_boundary(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 12;
  double get center_longitude_deg => values[offset + 0];
  double get center_latitude_deg => values[offset + 1];
  int get center_kind => values[offset + 2].toInt();
  double get umbra_north_longitude_deg => values[offset + 3];
  double get umbra_north_latitude_deg => values[offset + 4];
  double get umbra_south_longitude_deg => values[offset + 5];
  double get umbra_south_latitude_deg => values[offset + 6];
  double get penumbra_north_longitude_deg => values[offset + 7];
  double get penumbra_north_latitude_deg => values[offset + 8];
  double get penumbra_south_longitude_deg => values[offset + 9];
  double get penumbra_south_latitude_deg => values[offset + 10];
  double get umbra_width_km => values[offset + 11];
}

final class Web_taiyin_solar_eclipse_path_point {
  const Web_taiyin_solar_eclipse_path_point(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 9;
  Web_taiyin_split_julian_date get jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 0);
  Web_taiyin_split_julian_date get jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 2);
  double get latitude_deg => values[offset + 4];
  double get longitude_deg => values[offset + 5];
  double get elevation_m => values[offset + 6];
  double get sun_altitude_deg => values[offset + 7];
  double get sun_azimuth_deg => values[offset + 8];
}

final class Web_taiyin_solar_eclipse_route_row {
  const Web_taiyin_solar_eclipse_route_row(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 71;
  Web_taiyin_split_julian_date get jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 0);
  Web_taiyin_split_julian_date get jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 2);
  Web_taiyin_solar_eclipse_path_point get center_line =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 4);
  Web_taiyin_solar_eclipse_path_point get penumbral_north_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 13);
  Web_taiyin_solar_eclipse_path_point get penumbral_south_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 22);
  Web_taiyin_solar_eclipse_path_point get north_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 31);
  Web_taiyin_solar_eclipse_path_point get south_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 40);
  Web_taiyin_solar_eclipse_path_point get half_magnitude_north_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 49);
  Web_taiyin_solar_eclipse_path_point get half_magnitude_south_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 58);
  double get path_width_km => values[offset + 67];
  double get duration_seconds => values[offset + 68];
  double get sun_altitude_deg => values[offset + 69];
  double get sun_azimuth_deg => values[offset + 70];
}

final class Web_taiyin_solar_eclipse_where {
  const Web_taiyin_solar_eclipse_where(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 54;
  Web_taiyin_split_julian_date get jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 0);
  Web_taiyin_split_julian_date get jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 2);
  Web_taiyin_solar_eclipse_path_point get center_line =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 4);
  Web_taiyin_solar_eclipse_path_point get penumbral_north_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 13);
  Web_taiyin_solar_eclipse_path_point get penumbral_south_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 22);
  Web_taiyin_solar_eclipse_path_point get north_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 31);
  Web_taiyin_solar_eclipse_path_point get south_limit =>
      Web_taiyin_solar_eclipse_path_point(values, offset + 40);
  double get magnitude => values[offset + 49];
  double get obscuration => values[offset + 50];
  double get center_separation_deg => values[offset + 51];
  double get sun_angular_radius_deg => values[offset + 52];
  double get moon_angular_radius_deg => values[offset + 53];
}

final class Web_taiyin_solar_eclipse_route_curve_point {
  const Web_taiyin_solar_eclipse_route_curve_point(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 7;
  Web_taiyin_split_julian_date get jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 0);
  Web_taiyin_split_julian_date get jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 2);
  int get curve_kind => values[offset + 4].toInt();
  double get latitude_deg => values[offset + 5];
  double get longitude_deg => values[offset + 6];
}

final class Web_taiyin_solar_eclipse_route_product_point {
  const Web_taiyin_solar_eclipse_route_product_point(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 9;
  Web_taiyin_split_julian_date get jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 0);
  Web_taiyin_split_julian_date get jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 2);
  int get point_kind => values[offset + 4].toInt();
  int get source_curve_kind => values[offset + 5].toInt();
  double get latitude_deg => values[offset + 6];
  double get longitude_deg => values[offset + 7];
  double get unwrapped_longitude_deg => values[offset + 8];
}

final class Web_taiyin_solar_eclipse_route_product_summary {
  const Web_taiyin_solar_eclipse_route_product_summary(
    this.values, [
    this.offset = 0,
  ]);
  final List<double> values;
  final int offset;
  static const int width = 19;
  int get flags => values[offset + 0].toInt();
  int get curve_point_count => values[offset + 1].toInt();
  int get center_line_count => values[offset + 2].toInt();
  int get core_north_count => values[offset + 3].toInt();
  int get core_south_count => values[offset + 4].toInt();
  int get core_begin_horizon_count => values[offset + 5].toInt();
  int get core_end_horizon_count => values[offset + 6].toInt();
  int get penumbral_north_count => values[offset + 7].toInt();
  int get penumbral_south_count => values[offset + 8].toInt();
  int get half_magnitude_north_count => values[offset + 9].toInt();
  int get half_magnitude_south_count => values[offset + 10].toInt();
  int get core_polygon_point_count => values[offset + 11].toInt();
  int get penumbral_polygon_point_count => values[offset + 12].toInt();
  int get half_magnitude_polygon_point_count => values[offset + 13].toInt();
  int get polygon_point_count => values[offset + 14].toInt();
  double get min_latitude_deg => values[offset + 15];
  double get max_latitude_deg => values[offset + 16];
  double get min_unwrapped_longitude_deg => values[offset + 17];
  double get max_unwrapped_longitude_deg => values[offset + 18];
}

final class Web_taiyin_solar_besselian_elements {
  const Web_taiyin_solar_besselian_elements(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 13;
  double get t_hours => values[offset + 0];
  double get x => values[offset + 1];
  double get y => values[offset + 2];
  double get zeta => values[offset + 3];
  double get d_deg => values[offset + 4];
  double get mu_deg => values[offset + 5];
  double get l1 => values[offset + 6];
  double get l2 => values[offset + 7];
  double get f1_deg => values[offset + 8];
  double get f2_deg => values[offset + 9];
  double get tan_f1 => values[offset + 10];
  double get tan_f2 => values[offset + 11];
  double get gamma => values[offset + 12];
}

final class Web_taiyin_solar_besselian_polynomial {
  const Web_taiyin_solar_besselian_polynomial(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 91;
  Web_taiyin_split_julian_date get t0_jd_tt =>
      Web_taiyin_split_julian_date(values, offset + 0);
  double get span_hours => values[offset + 2];
  double get sample_step_hours => values[offset + 3];
  int get degree => values[offset + 4].toInt();
  List<double> get x =>
      List.generate(8, (i) => values[offset + 5 + i], growable: false);
  List<double> get y =>
      List.generate(8, (i) => values[offset + 13 + i], growable: false);
  List<double> get zeta =>
      List.generate(8, (i) => values[offset + 21 + i], growable: false);
  List<double> get d_deg =>
      List.generate(8, (i) => values[offset + 29 + i], growable: false);
  List<double> get mu_deg =>
      List.generate(8, (i) => values[offset + 37 + i], growable: false);
  List<double> get l1 =>
      List.generate(8, (i) => values[offset + 45 + i], growable: false);
  List<double> get l2 =>
      List.generate(8, (i) => values[offset + 53 + i], growable: false);
  double get f1_deg => values[offset + 61];
  double get f2_deg => values[offset + 62];
  double get tan_f1 => values[offset + 63];
  double get tan_f2 => values[offset + 64];
  Web_taiyin_solar_besselian_elements get center =>
      Web_taiyin_solar_besselian_elements(values, offset + 65);
  Web_taiyin_solar_besselian_elements get max_residual =>
      Web_taiyin_solar_besselian_elements(values, offset + 78);
}
