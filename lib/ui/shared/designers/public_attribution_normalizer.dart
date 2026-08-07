class PublicAttributionNormalizer {
  const PublicAttributionNormalizer._();

  static const _placeholders = <String>{
    'null',
    'undefined',
    'n/a',
    'na',
    'none',
    'unknown',
    'not available',
    'not applicable',
    '-',
    '--',
  };

  static const _operationalPatterns = <String>[
    'exception',
    'stack trace',
    'sqlstate',
    'fatal error',
    'platformexception',
    'renderflex overflow',
    'internal server error',
    'object instance',
    'instance of',
  ];

  static String? normalize(Object? value) {
    if (value is! String) return null;

    final text = value.trim();
    if (text.isEmpty) return null;

    final normalized = text.toLowerCase();
    if (_placeholders.contains(normalized)) return null;
    if (text.startsWith('{') || text.startsWith('[')) return null;
    if (_operationalPatterns.any(normalized.contains)) return null;
    if (normalized.startsWith('error:')) return null;

    return text;
  }
}
