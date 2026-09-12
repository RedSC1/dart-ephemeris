# Explicit chart clocks

`ZiweiClock` selects `fixedOffset`, `meanSolar`, or `apparentSolar` independently
of the calendar's month/day-boundary policy. Solar longitude is east-positive
in radians. Fixed offset applies the calendar offset to **UT1**; it is not a
UTC/DST service. Convert UTC through the base time API first, explicitly
choosing whether missing EOP may be estimated.

```dart
import 'dart:math' as math;
import 'package:ephemeris/ephemeris.dart';
import 'package:ephemeris_ziwei/ephemeris_ziwei.dart';

final context = Ephemeris.open().createContext();
final ziwei = context.ziwei;
final clock = ZiweiClock(
  mode: ZiweiClockMode.apparentSolar,
  longitudeRadians: 118.582 * math.pi / 180,
);
// These fields explicitly denote apparent solar time, not civil UTC+8.
final instant = ziwei.chartTimeToUt1(
  AstroDateTime(2003, 3, 13, 14, 15), clock: clock,
).value;
final chart = ziwei.createChartAtUt1(
  instantUt1: instant, gender: ZiweiGender.male, clock: clock,
).value;
final target = ziwei.stepFlowHourAtUt1(
  instantUt1: instant, clock: clock,
).value;
final flow = chart.setFlowAtUt1(
  targetInstantUt1: target.instantUt1, clock: clock,
);
print(flow.flags);
```

| Task | API |
| --- | --- |
| Instant → virtual clock | `chartTimeFromUt1` |
| Virtual clock → instant | `chartTimeToUt1` |
| Natal chart | `createChartAtUt1` |
| Flow stack | `chart.setFlowAtUt1` |
| Navigation | `stepFlowHourAtUt1`, `stepFlowDayAtUt1`, `direction: 1/-1` |
| Reverse lookup | `reverseLookupTier1AtUt1(startInstantUt1: ..., endInstantUt1: ..., gender: ..., query: ..., clock: ...)` |

All return `OperationResult<T>` with `.value` and `.flags`; fatal errors throw.
New navigation/reverse results carry `JulianDate<Ut1Scale> instantUt1`.
Navigation retains virtual minutes/seconds. Split-Rat modes use one hour near
midnight (forward 22:00–01:00, backward 23:00–02:00), otherwise two hours.
Apparent-solar destinations are inverted independently: a virtual day need not
be 86400 physical seconds. Inverse failure never silently changes clock mode.

Physical instants control Jie/year/month boundaries; virtual clocks control
Ziwei lunar-date/day/hour labels. Previous-Jie day counting maps that Jie at
its own instant, not with a correction frozen at today's date. Reverse lookup
visits actual hour/Jie boundaries and returns matching slot starts.

Use the same clock explicitly in later operations. Existing dual-time APIs
retain fixed-offset semantics. These new APIs require matching new native
artifacts. Close the owning context when finished.

## 中文说明

这是独立的排盘时钟配置，不改变定朔日界或农历结构。`meanSolar` 是平太阳时，
`apparentSolar` 是真太阳时；新接口物理输入输出均为 UT1，不要把 UTC 换个
类型就直接传入。例子里的 14:15 是真太阳时字段，不是当地民用时间。

流日、流时先按虚拟时钟导航，再重新求解 UT1；年/月节界仍按物理瞬间判断。
因此真太阳时下一天不能直接加 86400 秒。结果保持 Dart 的 `OperationResult`，
不改成 Python 的二元组。失败抛异常，附加执行信息在 `.flags`。
