class AppEngineCapability {
  final String key;
  final String title;
  final String description;
  final List<String> requiredEngines;
  final List<String> optionalEngines;
  final List<String> reservedFutureEngines;

  const AppEngineCapability({
    required this.key,
    required this.title,
    required this.description,
    required this.requiredEngines,
    required this.optionalEngines,
    required this.reservedFutureEngines,
  });

  bool requiresEngine(String engine) {
    return requiredEngines.contains(_normalize(engine));
  }

  bool supportsEngine(String engine) {
    final normalized = _normalize(engine);

    return requiredEngines.contains(normalized) ||
        optionalEngines.contains(normalized) ||
        reservedFutureEngines.contains(normalized);
  }

  List<String> get allEngines => [
        ...requiredEngines,
        ...optionalEngines,
        ...reservedFutureEngines,
      ];

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_');
  }
}
