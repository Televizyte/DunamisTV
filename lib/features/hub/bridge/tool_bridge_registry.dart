import 'tool_bridge_payload.dart';

class ToolBridgeRegistry {
  const ToolBridgeRegistry._();

  static const Set<String> bridgeEngines = {
    'bible',
    'notes',
    'note',
    'quote',
    'quote_creator',
  };

  static String normalize(String engine) {
    final raw = engine.trim().toLowerCase().replaceAll('-', '_');

    switch (raw) {
      case 'quote':
      case 'quotes':
      case 'quote_maker':
      case 'quotecreator':
        return 'quote_creator';

      case 'note':
      case 'notepad':
      case 'my_notes':
        return 'notes';

      case 'scripture':
      case 'holy_bible':
        return 'bible';

      default:
        return raw;
    }
  }

  static bool isBridgeEngine(String engine) {
    return bridgeEngines.contains(normalize(engine));
  }

  static String routeForEngine(String engine) {
    switch (normalize(engine)) {
      case 'quote_creator':
        return '/tools/quote';

      case 'notes':
        return '/tools/notes/editor';

      case 'bible':
        return '/tools/bible';

      default:
        return '';
    }
  }

  static Map<String, dynamic> buildPayloadForEngine(
    String engine,
    ToolBridgePayload payload,
  ) {
    final normalized = normalize(engine);

    switch (normalized) {
      case 'quote_creator':
        return {
          ...payload.extra,
          'quote': payload.text,
          'quote_text': payload.text,
          'text': payload.text,
          'author': payload.sourceTitle,
          'sourceType': payload.sourceType,
          'source_type': payload.sourceType,
          'sourceId': payload.sourceId,
          'source_id': payload.sourceId,
          'reference': payload.reference,
          'openedFromConnectedTool': true,
        };

      case 'notes':
        return {
          ...payload.extra,
          'title': payload.sourceTitle,
          'prefill': payload.text,
          'sourceType': payload.sourceType,
          'source_type': payload.sourceType,
          'sourceId': payload.sourceId,
          'source_id': payload.sourceId,
          if (payload.hasReference)
            'insertScripture': {
              'ref': payload.reference,
              'reference': payload.reference,
              'verse': payload.text,
            },
        };

      case 'bible':
        return {
          ...payload.extra,
          'ref': payload.reference,
          'reference': payload.reference,
          'verse': payload.text,
        };

      default:
        return payload.extra;
    }
  }
}
