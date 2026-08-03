import '../models/dynamic_section.dart';
import 'section_action_registry.dart';

class DynamicSectionActionBuilder {
  const DynamicSectionActionBuilder._();

  static List<Map<String, dynamic>> buildFallbackActions(
    HubDynamicSection section,
  ) {
    final type = SectionActionRegistry.normalize(section.type);

    if (SectionActionRegistry.isScripture(type)) {
      return _scriptureActions(section);
    }

    if (SectionActionRegistry.isQuote(type)) {
      return _quoteActions(section);
    }

    if (SectionActionRegistry.isMedia(type)) {
      return _mediaActions(section);
    }

    return const [];
  }

  static List<Map<String, dynamic>> _scriptureActions(
    HubDynamicSection section,
  ) {
    final payload = _basePayload(section);

    return [
      {
        ...payload,
        'label': 'Open Bible',
        'engine': 'bible',
      },
      {
        ...payload,
        'label': 'Add to Notes',
        'engine': 'notes',
      },
      {
        ...payload,
        'label': 'Make Quote',
        'engine': 'quote_creator',
      },
    ];
  }

  static List<Map<String, dynamic>> _quoteActions(
    HubDynamicSection section,
  ) {
    final payload = _basePayload(section);

    return [
      {
        ...payload,
        'label': 'Add to Notes',
        'engine': 'notes',
      },
      {
        ...payload,
        'label': 'Design Quote',
        'engine': 'quote_creator',
      },
    ];
  }

  static List<Map<String, dynamic>> _mediaActions(
    HubDynamicSection section,
  ) {
    final payload = _basePayload(section);

    return [
      {
        ...payload,
        'label': 'Take Notes',
        'engine': 'notes',
      },
    ];
  }

  static Map<String, dynamic> _basePayload(HubDynamicSection section) {
    final firstItem = section.items.isNotEmpty ? section.items.first : {};

    return {
      ...section.settings,
      ...firstItem,
      'section_key': section.key,
      'source_type': section.type,
      'source_id': section.key,
      'source_title': section.title,
      'title': section.title,
      'text': _first([
        firstItem['text'],
        firstItem['quote_text'],
        firstItem['note_text'],
        firstItem['verse_text'],
        firstItem['content'],
        section.settings['text'],
        section.settings['quote_text'],
        section.settings['note_text'],
        section.settings['verse_text'],
      ]),
      'reference': _first([
        firstItem['reference'],
        firstItem['verse_reference'],
        firstItem['ref'],
        section.settings['reference'],
        section.settings['verse_reference'],
        section.settings['ref'],
      ]),
    };
  }

  static String _first(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }

    return '';
  }
}
