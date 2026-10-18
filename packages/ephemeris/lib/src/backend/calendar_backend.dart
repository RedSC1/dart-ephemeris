import '../chinese_calendar/chinese_calendar_models.dart';
import '../ganzhi/ganzhi_models.dart';
import '../time/astro_date_time.dart';
import '../time/julian_date.dart';
import '../time/time_scale.dart';
import 'backend_call.dart';

/// One owned calendar kernel; no platform pointers cross this boundary.
abstract interface class ChineseCalendarBackend {
  void close();
  BackendCall<ChineseCalendarYear> calcYearUt(JulianDate<Ut1Scale> jd);
  BackendCall<ChineseSolarTermEvent> getSpecificJieQiUt({
    required int civilYear,
    required int termIndexFromVernalEquinox,
  });
  BackendCall<ChineseSolarTermEvent> getPrevJieQiUt(JulianDate<Ut1Scale> jd);
  BackendCall<ChineseSolarTermEvent> getNextJieQiUt(JulianDate<Ut1Scale> jd);
  BackendCall<ChineseSolarTermEvent> getPrevJieUt(JulianDate<Ut1Scale> jd);
  BackendCall<ChineseSolarTermEvent> getNextJieUt(JulianDate<Ut1Scale> jd);
  BackendCall<ChineseSolarTermEvent> getPrevQiUt(JulianDate<Ut1Scale> jd);
  BackendCall<ChineseSolarTermEvent> getNextQiUt(JulianDate<Ut1Scale> jd);
  BackendCall<LunarDate> fromSolar(SolarDate date);
  BackendCall<LunarDate> fromInstantUt1(JulianDate<Ut1Scale> jd);
  BackendCall<SolarDate> fromLunar(LunarDate date);
  BackendCall<int> getMonthDays({
    required int lunarYear,
    required int month,
    required bool isLeap,
  });
  BackendCall<GanzhiFourPillars> fourPillars({
    required JulianDate<UtcScale> instantUtc,
    required AstroDateTime virtualTime,
    GanzhiRatHourMode ratHourMode = GanzhiRatHourMode.noSplit,
  });
}
