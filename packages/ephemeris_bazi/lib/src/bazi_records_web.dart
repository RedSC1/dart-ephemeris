// Field-wise copied records. No native layout/addresses cross this boundary.
// ignore_for_file: camel_case_types, non_constant_identifier_names
import 'package:ephemeris/backend.dart';

final class Web_taiyin_calendar_datetime {
  const Web_taiyin_calendar_datetime(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 6;
  int get year => values[offset + 0].toInt();
  int get month => values[offset + 1].toInt();
  int get day => values[offset + 2].toInt();
  int get hour => values[offset + 3].toInt();
  int get minute => values[offset + 4].toInt();
  double get second => values[offset + 5];
}

final class Web_taiyin_ganzhi_four_pillars {
  const Web_taiyin_ganzhi_four_pillars(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 4;
  int get year => values[offset + 0].toInt();
  int get month => values[offset + 1].toInt();
  int get day => values[offset + 2].toInt();
  int get hour => values[offset + 3].toInt();
}

final class Web_taiyin_bazi_context_config {
  const Web_taiyin_bazi_context_config(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 4;
  int get earth_palace_mode => values[offset + 0].toInt();
  int get qiyun_direction_mode => values[offset + 1].toInt();
  int get qiyun_time_model => values[offset + 2].toInt();
  int get dayun_boundary_model => values[offset + 3].toInt();
}

final class Web_taiyin_bazi_chart {
  const Web_taiyin_bazi_chart(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 48;
  int get year_pillar => values[offset + 0].toInt();
  int get month_pillar => values[offset + 1].toInt();
  int get day_pillar => values[offset + 2].toInt();
  int get hour_pillar => values[offset + 3].toInt();
  int get ming_gong => values[offset + 4].toInt();
  int get shen_gong => values[offset + 5].toInt();
  int get tai_yuan => values[offset + 6].toInt();
  int get tai_xi => values[offset + 7].toInt();
  List<int> get hidden_stem_count => List.generate(
    4,
    (i0) => values[offset + 8 + i0 * 1].toInt(),
    growable: false,
  );
  List<List<int>> get hidden_stems => List.generate(
    4,
    (i0) => List.generate(
      3,
      (i1) => values[offset + 12 + i0 * 3 + i1 * 1].toInt(),
      growable: false,
    ),
    growable: false,
  );
  List<int> get visible_ten_gods => List.generate(
    4,
    (i0) => values[offset + 24 + i0 * 1].toInt(),
    growable: false,
  );
  List<List<int>> get hidden_ten_gods => List.generate(
    4,
    (i0) => List.generate(
      3,
      (i1) => values[offset + 28 + i0 * 3 + i1 * 1].toInt(),
      growable: false,
    ),
    growable: false,
  );
  List<int> get life_stages => List.generate(
    4,
    (i0) => values[offset + 40 + i0 * 1].toInt(),
    growable: false,
  );
  List<int> get nayin_ids => List.generate(
    4,
    (i0) => values[offset + 44 + i0 * 1].toInt(),
    growable: false,
  );
}

final class Web_taiyin_bazi_relation {
  const Web_taiyin_bazi_relation(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 3;
  int get kind => values[offset + 0].toInt();
  int get pillar_mask => values[offset + 1].toInt();
  int get combined_element_id => values[offset + 2].toInt();
}

final class Web_taiyin_bazi_qiyun_result {
  const Web_taiyin_bazi_qiyun_result(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 21;
  int get direction => values[offset + 0].toInt();
  int get time_model => values[offset + 1].toInt();
  int get reference_jie_index => values[offset + 2].toInt();
  double get jie_interval_days => values[offset + 3];
  double get start_age_years => values[offset + 4];
  int get offset_years => values[offset + 5].toInt();
  int get offset_months => values[offset + 6].toInt();
  int get offset_days => values[offset + 7].toInt();
  int get offset_hours => values[offset + 8].toInt();
  int get offset_minutes => values[offset + 9].toInt();
  double get offset_seconds => values[offset + 10];
  Web_taiyin_split_julian_date get reference_jie_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 11);
  Web_taiyin_split_julian_date get start_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 13);
  Web_taiyin_calendar_datetime get start_civil_time =>
      Web_taiyin_calendar_datetime(values, offset + 15);
}

final class Web_taiyin_bazi_dayun {
  const Web_taiyin_bazi_dayun(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 20;
  int get index => values[offset + 0].toInt();
  int get ganzhi => values[offset + 1].toInt();
  int get start_virtual_age => values[offset + 2].toInt();
  int get end_virtual_age => values[offset + 3].toInt();
  Web_taiyin_split_julian_date get start_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 4);
  Web_taiyin_split_julian_date get end_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 6);
  Web_taiyin_calendar_datetime get start_civil_time =>
      Web_taiyin_calendar_datetime(values, offset + 8);
  Web_taiyin_calendar_datetime get end_civil_time =>
      Web_taiyin_calendar_datetime(values, offset + 14);
}

final class Web_taiyin_bazi_xiaoyun {
  const Web_taiyin_bazi_xiaoyun(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 2;
  int get age => values[offset + 0].toInt();
  int get ganzhi => values[offset + 1].toInt();
}

final class Web_taiyin_bazi_renyuan_siling_segment {
  const Web_taiyin_bazi_renyuan_siling_segment(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 5;
  int get stem_id => values[offset + 0].toInt();
  int get origin_kind => values[offset + 1].toInt();
  int get segment_index => values[offset + 2].toInt();
  double get start_day => values[offset + 3];
  double get end_day => values[offset + 4];
}

final class Web_taiyin_bazi_renyuan_siling_result {
  const Web_taiyin_bazi_renyuan_siling_result(this.values, [this.offset = 0]);
  final List<double> values;
  final int offset;
  static const int width = 12;
  int get table_model => values[offset + 0].toInt();
  int get time_model => values[offset + 1].toInt();
  int get month_branch_id => values[offset + 2].toInt();
  int get stem_id => values[offset + 3].toInt();
  int get origin_kind => values[offset + 4].toInt();
  int get segment_index => values[offset + 5].toInt();
  int get previous_jie_index => values[offset + 6].toInt();
  double get days_since_jie => values[offset + 7];
  double get segment_start_day => values[offset + 8];
  double get segment_end_day => values[offset + 9];
  Web_taiyin_split_julian_date get previous_jie_jd_ut =>
      Web_taiyin_split_julian_date(values, offset + 10);
}
