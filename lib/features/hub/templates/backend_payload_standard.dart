class BackendPayloadStandard {
  const BackendPayloadStandard._();

  static const Map<String, List<String>> requiredFields = {
    'section': [
      'section_key',
      'title',
      'type',
      'layout',
    ],
    'item': [
      'id',
      'title',
      'type',
    ],
    'action': [
      'engine',
      'route',
      'url',
      'content_id',
    ],
  };

  static bool validateSection(Map<String, dynamic> section) {
    return _hasRequired(section, requiredFields['section']!);
  }

  static bool validateItem(Map<String, dynamic> item) {
    return _hasRequired(item, requiredFields['item']!);
  }

  static bool validateAction(Map<String, dynamic> action) {
    return _hasAtLeastOne(action, requiredFields['action']!);
  }

  static bool _hasRequired(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = (map[key] ?? '').toString().trim();
      if (value.isEmpty) return false;
    }
    return true;
  }

  static bool _hasAtLeastOne(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = (map[key] ?? '').toString().trim();
      if (value.isNotEmpty) return true;
    }
    return false;
  }
}
