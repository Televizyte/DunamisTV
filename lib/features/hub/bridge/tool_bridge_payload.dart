class ToolBridgePayload {
  final String engine;
  final String text;
  final String reference;
  final String sourceType;
  final String sourceId;
  final String sourceTitle;
  final Map<String, dynamic> extra;

  const ToolBridgePayload({
    required this.engine,
    required this.text,
    required this.reference,
    required this.sourceType,
    required this.sourceId,
    required this.sourceTitle,
    required this.extra,
  });

  factory ToolBridgePayload.fromMap(Map<String, dynamic> map) {
    return ToolBridgePayload(
      engine: _first([
        map['engine'],
        map['native_engine'],
        map['tool'],
        map['tool_key'],
      ]),
      text: _first([
        map['text'],
        map['quote_text'],
        map['note_text'],
        map['verse_text'],
        map['verse'],
        map['content'],
        map['prefill'],
      ]),
      reference: _first([
        map['reference'],
        map['verse_reference'],
        map['ref'],
      ]),
      sourceType: _first([
        map['source_type'],
        map['sourceType'],
        map['bucket'],
        map['type'],
      ]),
      sourceId: _first([
        map['source_id'],
        map['sourceId'],
        map['content_id'],
        map['id'],
      ]),
      sourceTitle: _first([
        map['source_title'],
        map['sourceTitle'],
        map['title'],
        map['label'],
      ]),
      extra: {...map},
    );
  }

  bool get hasText => text.trim().isNotEmpty;

  bool get hasReference => reference.trim().isNotEmpty;
}

String _first(List<dynamic> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }

  return '';
}
