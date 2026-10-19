// Field-wise, owned copies; independent of native struct layout.
// ignore_for_file: camel_case_types, non_constant_identifier_names
import 'package:ephemeris/backend.dart';

final class Web_taiyin_ziwei_chart_clock {
  const Web_taiyin_ziwei_chart_clock(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 2;
  int get mode => values[offset + 0].toInt();
  double get longitude_rad => values[offset + 1];
}

final class Web_taiyin_ziwei_placement_input {
  const Web_taiyin_ziwei_placement_input(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 5;
  int get year_stem => values[offset + 0].toInt();
  int get year_branch => values[offset + 1].toInt();
  int get month => values[offset + 2].toInt();
  int get day => values[offset + 3].toInt();
  int get hour_branch => values[offset + 4].toInt();
}

final class Web_taiyin_ziwei_placement_patch {
  const Web_taiyin_ziwei_placement_patch(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 6;
  int get year_stem => values[offset + 0].toInt();
  int get year_branch => values[offset + 1].toInt();
  int get month => values[offset + 2].toInt();
  int get day => values[offset + 3].toInt();
  int get hour_branch => values[offset + 4].toInt();
  int get update_bureau => values[offset + 5].toInt();
}

final class Web_taiyin_ziwei_casting_options {
  const Web_taiyin_ziwei_casting_options(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 3;
  int get gender => values[offset + 0].toInt();
  int get chart_mode => values[offset + 1].toInt();
  int get fixed_bureau => values[offset + 2].toInt();
}

final class Web_taiyin_ziwei_casting_summary {
  const Web_taiyin_ziwei_casting_summary(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 56;
  Web_taiyin_ziwei_placement_input get input =>
      Web_taiyin_ziwei_placement_input(values, offset + 0);
  Web_taiyin_ziwei_placement_input get original_input =>
      Web_taiyin_ziwei_placement_input(values, offset + 5);
  Web_taiyin_ziwei_placement_patch get overrides =>
      Web_taiyin_ziwei_placement_patch(values, offset + 10);
  int get index => values[offset + 16].toInt();
  int get method => values[offset + 17].toInt();
  int get gender => values[offset + 18].toInt();
  int get chart_mode => values[offset + 19].toInt();
  int get bureau => values[offset + 20].toInt();
  int get original_bureau => values[offset + 21].toInt();
  int get body_palace => values[offset + 22].toInt();
  int get update_bureau => values[offset + 23].toInt();
  int get life_palace_shift => values[offset + 24].toInt();
  int get year_transform_stem => values[offset + 25].toInt();
  List<int> get palace_branches => List.generate(
    12,
    (i) => values[offset + 26 + i].toInt(),
    growable: false,
  );
  List<int> get palace_stems => List.generate(
    12,
    (i) => values[offset + 38 + i].toInt(),
    growable: false,
  );
  int get life_master => values[offset + 50].toInt();
  int get body_master => values[offset + 51].toInt();
  int get year_lu => values[offset + 52].toInt();
  int get year_quan => values[offset + 53].toInt();
  int get year_ke => values[offset + 54].toInt();
  int get year_ji => values[offset + 55].toInt();
}

final class Web_taiyin_ziwei_omitted_placement {
  const Web_taiyin_ziwei_omitted_placement(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 2;
  int get star_id => values[offset + 0].toInt();
  int get missing_inputs => values[offset + 1].toInt();
}

final class Web_taiyin_ziwei_birth_options {
  const Web_taiyin_ziwei_birth_options(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 6;
  int get rat_hour_mode => values[offset + 0].toInt();
  int get leap_month_strategy => values[offset + 1].toInt();
  int get chart_mode => values[offset + 2].toInt();
  int get wu_hu_dun_year_boundary => values[offset + 3].toInt();
  int get sihua_year_boundary => values[offset + 4].toInt();
  int get body_master_year_boundary => values[offset + 5].toInt();
}

final class Web_taiyin_ziwei_flow_options {
  const Web_taiyin_ziwei_flow_options(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 4;
  int get boundary => values[offset + 0].toInt();
  int get rat_hour_mode => values[offset + 1].toInt();
  int get childhood_strategy => values[offset + 2].toInt();
  int get flow_month_palace_strategy => values[offset + 3].toInt();
}

final class Web_taiyin_ziwei_transform_set {
  const Web_taiyin_ziwei_transform_set(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 4;
  int get lu => values[offset + 0].toInt();
  int get quan => values[offset + 1].toInt();
  int get ke => values[offset + 2].toInt();
  int get ji => values[offset + 3].toInt();
}

final class Web_taiyin_ziwei_flow_summary {
  const Web_taiyin_ziwei_flow_summary(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 19;
  int get effective_birth_year => values[offset + 0].toInt();
  int get effective_target_year => values[offset + 1].toInt();
  int get target_month => values[offset + 2].toInt();
  int get target_month_sequence => values[offset + 3].toInt();
  int get target_day => values[offset + 4].toInt();
  int get target_hour_index => values[offset + 5].toInt();
  int get target_rat_hour_segment => values[offset + 6].toInt();
  int get target_month_is_leap => values[offset + 7].toInt();
  int get decade_index => values[offset + 8].toInt();
  int get decade_start_age => values[offset + 9].toInt();
  int get decade_end_age => values[offset + 10].toInt();
  int get small_limit_virtual_age => values[offset + 11].toInt();
  int get small_limit_stem => values[offset + 12].toInt();
  int get small_limit_branch => values[offset + 13].toInt();
  int get target_month_building_branch => values[offset + 14].toInt();
  int get target_effective_month => values[offset + 15].toInt();
  int get target_month_name => values[offset + 16].toInt();
  int get target_palace_month_index => values[offset + 17].toInt();
  int get target_lunar_year => values[offset + 18].toInt();
}

final class Web_taiyin_ziwei_reverse_query {
  const Web_taiyin_ziwei_reverse_query(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 9;
  int get lucun_branch => values[offset + 0].toInt();
  int get hongluan_branch => values[offset + 1].toInt();
  int get zuofu_branch => values[offset + 2].toInt();
  int get youbi_branch => values[offset + 3].toInt();
  int get wenchang_branch => values[offset + 4].toInt();
  int get wenqu_branch => values[offset + 5].toInt();
  int get santai_branch => values[offset + 6].toInt();
  int get bazuo_branch => values[offset + 7].toInt();
  int get ziwei_branch => values[offset + 8].toInt();
}

final class Web_taiyin_ziwei_reverse_request {
  const Web_taiyin_ziwei_reverse_request(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 26;
  Web_taiyin_split_julian_date get start_instant_utc =>
      Web_taiyin_split_julian_date(values, offset + 0);
  Web_taiyin_split_julian_date get end_instant_utc =>
      Web_taiyin_split_julian_date(values, offset + 2);
  Web_taiyin_calendar_datetime get start_virtual_time =>
      Web_taiyin_calendar_datetime(values, offset + 4);
  int get gender => values[offset + 10].toInt();
  Web_taiyin_ziwei_birth_options get birth_options =>
      Web_taiyin_ziwei_birth_options(values, offset + 11);
  Web_taiyin_ziwei_reverse_query get query =>
      Web_taiyin_ziwei_reverse_query(values, offset + 17);
}

final class Web_taiyin_ziwei_reverse_candidate {
  const Web_taiyin_ziwei_reverse_candidate(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 14;
  Web_taiyin_split_julian_date get instant_utc =>
      Web_taiyin_split_julian_date(values, offset + 0);
  Web_taiyin_calendar_datetime get virtual_time =>
      Web_taiyin_calendar_datetime(values, offset + 2);
  int get lunar_year => values[offset + 8].toInt();
  int get lunar_month => values[offset + 9].toInt();
  int get lunar_day => values[offset + 10].toInt();
  int get lunar_is_leap => values[offset + 11].toInt();
  int get hour_branch => values[offset + 12].toInt();
  int get rat_hour_segment => values[offset + 13].toInt();
}

final class Web_taiyin_calendar_datetime {
  const Web_taiyin_calendar_datetime(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  int get year => values[offset].toInt();
  int get month => values[offset + 1].toInt();
  int get day => values[offset + 2].toInt();
  int get hour => values[offset + 3].toInt();
  int get minute => values[offset + 4].toInt();
  double get second => values[offset + 5];
}
