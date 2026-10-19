/// Configuration for Taiyin's process-wide native runtime.
final class RuntimeOptions {
  const RuntimeOptions({
    this.dataRoot,
    this.sourcePaths = const [],
    this.eopPath,
    this.lunarLimbPath,
    this.segmentCacheMaxEntries,
    this.loadPackagedData = true,
    this.loadBuiltinEop = true,
    this.strictDiscovery = false,
  });

  final String? dataRoot;
  final List<String> sourcePaths;
  final String? eopPath;
  final String? lunarLimbPath;
  final int? segmentCacheMaxEntries;

  /// Loads native packaged data and the Dart package's bundled lite star
  /// catalog. Set this to false for a completely caller-managed data setup.
  final bool loadPackagedData;
  final bool loadBuiltinEop;
  final bool strictDiscovery;
}
