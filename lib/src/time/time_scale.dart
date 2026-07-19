/// Marker base class for astronomical time scales.
///
/// The subclasses are used as type arguments on [JulianDate] so that, for
/// example, a UT1 value cannot be passed to an API requiring TT.
sealed class TimeScale {
  const TimeScale._();
}

/// Coordinated Universal Time.
final class UtcScale extends TimeScale {
  const UtcScale._() : super._();
}

/// International Atomic Time.
final class TaiScale extends TimeScale {
  const TaiScale._() : super._();
}

/// Terrestrial Time.
final class TtScale extends TimeScale {
  const TtScale._() : super._();
}

/// Universal Time 1.
final class Ut1Scale extends TimeScale {
  const Ut1Scale._() : super._();
}

/// Barycentric Dynamical Time.
final class TdbScale extends TimeScale {
  const TdbScale._() : super._();
}
