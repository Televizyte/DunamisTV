import 'package:flutter/material.dart';

import '../../../../features/quote_creator/state/quote_creator_store.dart';

class QuoteCreatorIncomingPayloadResult {
  final String sourceType;
  final String sourceId;
  final String reference;
  final String sourceLabel;
  final bool openedFromConnectedTool;

  const QuoteCreatorIncomingPayloadResult({
    required this.sourceType,
    required this.sourceId,
    required this.reference,
    required this.sourceLabel,
    required this.openedFromConnectedTool,
  });
}

QuoteCreatorIncomingPayloadResult? applyQuoteCreatorIncomingPayload({
  required QuoteCreatorStore store,
  required Object? extra,
  required TextEditingController quoteController,
  required TextEditingController authorController,
  required String Function(String sourceType) resolveSourceLabel,
}) {
  if (extra is! Map) return null;

  final data = Map<String, dynamic>.from(extra);
  final designDataRaw = data['designData'];

  if (designDataRaw is Map) {
    final designData = Map<String, dynamic>.from(designDataRaw);
    store.loadFromPayload(designData);
    quoteController.text = store.quote;
    authorController.text = store.author;

    final sourceType = (designData['source_type'] ?? data['source_type'] ?? '')
        .toString()
        .trim();
    final sourceId =
        (designData['source_id'] ?? data['source_id'] ?? '').toString().trim();
    final reference =
        (designData['reference'] ?? data['reference'] ?? '').toString().trim();

    return QuoteCreatorIncomingPayloadResult(
      sourceType: sourceType,
      sourceId: sourceId,
      reference: reference,
      sourceLabel: resolveSourceLabel(sourceType),
      openedFromConnectedTool: sourceType.isNotEmpty,
    );
  }

  final prefill = (data['prefill'] ?? '').toString().trim();
  final author = (data['author'] ?? '').toString().trim();
  final reference = (data['reference'] ?? '').toString().trim();
  final sourceType =
      (data['source_type'] ?? data['source'] ?? '').toString().trim();
  final sourceId = (data['source_id'] ?? '').toString().trim();

  final resolvedAuthor =
      author.isNotEmpty ? author : (reference.isNotEmpty ? reference : '');

  if (prefill.isNotEmpty) {
    quoteController.text = prefill;
    store.setQuote(prefill);
  }

  if (resolvedAuthor.isNotEmpty) {
    authorController.text = resolvedAuthor;
    store.setAuthor(resolvedAuthor);
  }

  _applyDesignFields(store, data);

  return QuoteCreatorIncomingPayloadResult(
    sourceType: sourceType,
    sourceId: sourceId,
    reference: reference,
    sourceLabel: resolveSourceLabel(sourceType),
    openedFromConnectedTool: prefill.isNotEmpty || sourceType.isNotEmpty,
  );
}

void _applyDesignFields(QuoteCreatorStore store, Map<String, dynamic> data) {
  final imageUrl = (data['background_image_url'] ??
          data['backgroundImage'] ??
          data['image_url'] ??
          data['image'] ??
          '')
      .toString()
      .trim();

  final useSolidBackground = _asBool(
    data['use_solid_background'] ?? data['use_solid_bg'],
  );

  final backgroundColor = _parseColor(
    data['backgroundColor'] ?? data['background_color'] ?? data['bg_color'],
  );

  final textColor = _parseColor(data['textColor'] ?? data['text_color']);
  final authorColor = _parseColor(data['authorColor'] ?? data['author_color']);
  final highlightColor =
      _parseColor(data['highlightColor'] ?? data['accent_color']);

  final fontSize = _parseDouble(data['fontSize'] ?? data['font_size']);
  final authorFontSize = _parseDouble(
    data['authorFontSize'] ?? data['title_size'] ?? data['brandFontSize'],
  );
  final textScale = _parseDouble(data['textScale'] ?? data['text_scale']);

  final overlayStrength =
      _parseDouble(data['overlayStrength'] ?? data['overlay_strength']);

  final textAlign = _parseTextAlign(data['textAlign'] ?? data['text_align']);

  final gradient = _parseGradient(data['gradient']);

  if (gradient != null) {
    store.setBackgroundGradient(gradient);
  } else if (useSolidBackground && backgroundColor != null) {
    store.setBackgroundColor(backgroundColor);
  } else if (!useSolidBackground && imageUrl.isNotEmpty) {
    store.setBackgroundImage(imageUrl);
  } else if (backgroundColor != null) {
    store.setBackgroundColor(backgroundColor);
  } else if (imageUrl.isNotEmpty) {
    store.setBackgroundImage(imageUrl);
  }

  if (textColor != null) store.setTextColor(textColor);
  if (authorColor != null) store.setAuthorColor(authorColor);
  if (highlightColor != null) store.setHighlightColor(highlightColor);
  if (fontSize != null) store.setFontSize(fontSize);
  if (authorFontSize != null) store.setAuthorFontSize(authorFontSize);
  if (textScale != null) store.setTextScale(textScale);
  if (overlayStrength != null) store.setOverlayStrength(overlayStrength);
  if (textAlign != null) store.setAlignment(textAlign);
}

LinearGradient? _parseGradient(dynamic value) {
  if (value is! List || value.length < 2) return null;

  final colors = value.map(_parseColor).whereType<Color>().toList();
  if (colors.length < 2) return null;

  return LinearGradient(
    colors: colors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

bool _asBool(dynamic value) {
  final raw = (value ?? '').toString().trim().toLowerCase();
  return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
}

double? _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString().trim());
}

TextAlign? _parseTextAlign(dynamic value) {
  switch ((value ?? '').toString().trim().toLowerCase()) {
    case 'left':
    case 'start':
      return TextAlign.left;
    case 'right':
    case 'end':
      return TextAlign.right;
    case 'center':
      return TextAlign.center;
    default:
      return null;
  }
}

Color? _parseColor(dynamic value) {
  if (value is Color) return value;
  if (value is int) return Color(value);
  if (value is num) return Color(value.toInt());

  var raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return null;

  if (raw.startsWith('#')) raw = raw.substring(1);
  if (raw.startsWith('0x')) raw = raw.substring(2);
  if (raw.length == 6) raw = 'FF$raw';

  final parsed = int.tryParse(raw, radix: 16) ?? int.tryParse(raw);
  if (parsed == null) return null;
  return Color(parsed);
}
