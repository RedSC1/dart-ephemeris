/// A native execution fact reported by Taiyin for one completed call.
enum ResultFlag {
  /// The requested route failed and a lower-priority route completed the call.
  fallbackOccurred(1 << 0),

  /// At least one requested derivative was evaluated numerically.
  numericalDerivative(1 << 1),

  /// A physical center was reconstructed or approximated from a barycenter.
  barycenterApproximation(1 << 2),

  /// A requested time-scale conversion used its configured estimate fallback.
  timeScaleFallback(1 << 3),

  /// Historical event-to-civil-day assignment rules affected the result.
  historicalEventAssignmentApplied(1 << 4),

  /// Historical Chinese-calendar rules affected the result.
  historicalCalendarRulesApplied(1 << 5),

  /// Historical solar-term rules affected a Ganzhi pillar calculation.
  historicalPillarTermsApplied(1 << 6);

  const ResultFlag(this.mask);

  /// The bit used by the native C ABI.
  final int mask;
}

/// Immutable bit mask containing zero or more [ResultFlag] values.
extension type const ResultFlags(int mask) {
  /// No execution facts were reported.
  static const none = ResultFlags(0);

  /// Whether this mask contains [flag].
  bool contains(ResultFlag flag) => (mask & flag.mask) != 0;

  /// Whether no execution facts were reported.
  bool get isEmpty => mask == 0;

  /// Whether at least one execution fact was reported.
  bool get isNotEmpty => mask != 0;

  /// The reported facts as an immutable set.
  Set<ResultFlag> get values => Set.unmodifiable({
    for (final flag in ResultFlag.values)
      if (contains(flag)) flag,
  });

  /// Combines facts reported by independent calls in one high-level operation.
  ResultFlags operator |(ResultFlags other) => ResultFlags(mask | other.mask);
}

/// The value and execution facts produced by one successful native operation.
typedef OperationResult<T> = ({T value, ResultFlags flags});

/// Creates an [OperationResult] while keeping record construction consistent.
OperationResult<T> operationResult<T>(T value, ResultFlags flags) =>
    (value: value, flags: flags);
