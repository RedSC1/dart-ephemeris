part of '../taiyin.dart';

/// Pure Ganzhi (干支) rule primitives backed by the Taiyin Chinese-calendar
/// module.
///
/// Requires the `ganzhiCalendar` capability. When the loaded library is built
/// without the Ganzhi extension, every method throws [UnsupportedError] rather
/// than reaching a native stub.
final class TaiyinGanzhiApi {
  TaiyinGanzhiApi._(this._bindings, this._capabilities);

  final TaiyinBindings _bindings;
  final int _capabilities;

  void _requireGanzhi() {
    if ((_capabilities & taiyinGanzhiCalendarCapability) == 0) {
      throw UnsupportedError(
        'The loaded Taiyin library does not include the Ganzhi calendar '
        'extension (build with TAIYIN_BUILD_GANZHI_CALENDAR_EXTENSION=ON).',
      );
    }
  }

  /// Builds a Ganzhi from a heavenly-stem id and earthly-branch id.
  ///
  /// Rejects invalid yin/yang stem-branch combinations.
  TaiyinGanzhi make({required int stemId, required int branchId}) {
    _requireGanzhi();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_ganzhi_make(stemId, branchId, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Advances a Ganzhi by [delta] places along the sexagenary cycle.
  TaiyinGanzhi advance(TaiyinGanzhi value, int delta) {
    _requireGanzhi();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_ganzhi_advance(value.raw, delta, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Returns the month pillar stem (五虎遁) for a [yearStemId].
  ///
  /// [monthIndex] follows the C ABI: 0 = 寅, …, 10 = 子, 11 = 丑.
  TaiyinGanzhi monthPillar({required int yearStemId, required int monthIndex}) {
    _requireGanzhi();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_ganzhi_get_month(yearStemId, monthIndex, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Returns the hour pillar stem (五鼠遁) for a [dayStemId].
  ///
  /// [hourIndex] follows the C ABI: 0 = 子, …, 11 = 亥.
  TaiyinGanzhi hourPillar({required int dayStemId, required int hourIndex}) {
    _requireGanzhi();
    return using((arena) {
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_ganzhi_get_hour(dayStemId, hourIndex, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Returns the day pillar for a civil date (noon/J2000 convention; the
  /// time-of-day fields of [civilDate] are ignored).
  TaiyinGanzhi dayPillar(AstroDateTime civilDate) {
    _requireGanzhi();
    return using((arena) {
      final calendar = writeNativeCalendar(_bindings, arena, civilDate);
      final output = arena<taiyin_ganzhi>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_ganzhi_calc_day_pillar(calendar, output),
      );
      return TaiyinGanzhi.fromNative(output.value);
    });
  }

  /// Returns the five-element (五行) of a Ganzhi's NaYin.
  TaiyinGanzhiWuxing nayinElement(TaiyinGanzhi value) {
    _requireGanzhi();
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_ganzhi_get_nayin_element(value.raw, output),
      );
      return TaiyinGanzhiWuxing.fromId(output.value);
    });
  }

  /// Returns the NaYin id (0–29) of a Ganzhi.
  int nayinId(TaiyinGanzhi value) {
    _requireGanzhi();
    return using((arena) {
      final output = arena<Uint8>();
      _checkStatus(
        _bindings,
        _bindings.taiyin_ganzhi_get_nayin_id(value.raw, output),
      );
      return output.value;
    });
  }
}
