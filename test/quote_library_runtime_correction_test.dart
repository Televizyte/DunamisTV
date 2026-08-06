import 'package:dunamis_tv/ui/screens/libraries/quotes_scripture_library_screen.dart';
import 'package:dunamis_tv/ui/shared/designers/dxm_dynamic_quote_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quote public-content boundary', () {
    test('design and style maps cannot become quote text', () {
      final items = QuoteScriptureLibraryMapper.fromRawHub({
        'quote_channel': {
          'channel_key': 'daily_quote',
          'items': [
            {
              'id': 'design-map',
              'quote': {'font_family': 'Inter', 'font_size': 22},
            },
            {
              'id': 'style-map',
              'content': {'color': '#ffffff', 'align': 'center'},
            },
          ],
        },
      });

      expect(items, isEmpty);
    });

    test('queue and status maps cannot become quote text', () {
      final items = QuoteScriptureLibraryMapper.fromRawHub({
        'quote_channel': {
          'channel_key': 'daily_quote',
          'items': [
            {
              'id': 'queue-map',
              'message': {'status': 'queued', 'queued_at': 'tomorrow'},
            },
            {
              'id': 'status-map',
              'body': {'status': 'processing'},
            },
          ],
        },
      });

      expect(items, isEmpty);
    });

    test('JSON container strings and status values are rejected', () {
      final items = QuoteScriptureLibraryMapper.fromRawHub({
        'quote_channel': {
          'channel_key': 'daily_quote',
          'items': [
            {'id': 'json-object', 'text': '{"font_key":"heading"}'},
            {'id': 'json-array', 'text': '["queued","pending"]'},
            {'id': 'malformed-json', 'text': '{"status":"queued"'},
            {'id': 'status', 'text': 'processing'},
            {'id': 'exception', 'message': 'Exception: backend failed'},
          ],
        },
      });

      expect(items, isEmpty);
    });

    test('valid public quote text remains accepted with complete raw design',
        () {
      final items = QuoteScriptureLibraryMapper.fromRawHub({
        'quote_channel': {
          'channel_key': 'daily_quote',
          'items': [
            {
              'id': 'valid',
              'quote_text': 'A valid public quote with meaningful content.',
              'design': {
                'background_color': '#112233',
                'text_color': '#ffffff',
              },
            },
          ],
        },
      });

      expect(items, hasLength(1));
      expect(
        items.single.text,
        'A valid public quote with meaningful content.',
      );
      expect(items.single.raw['design'], isA<Map>());
      expect(items.single.design, isNotNull);
    });
  });

  group('Filtered quote-library channel selection', () {
    const available = <String>[
      'sod_quotes',
      'daily_scripture',
      'daily_quote',
      'future_prophetic_messages',
      'daily_quote_extra',
    ];

    test('known quote routes select exact channels', () {
      expect(
        QuoteLibraryChannelSelection.resolve('sod_quotes', available),
        'sod_quotes',
      );
      expect(
        QuoteLibraryChannelSelection.resolve('Daily Scripture', available),
        'daily_scripture',
      );
      expect(
        QuoteLibraryChannelSelection.resolve('daily_quote', available),
        'daily_quote',
      );
    });

    test('future arbitrary channels remain routable', () {
      expect(
        QuoteLibraryChannelSelection.resolve(
          'future_prophetic_messages',
          available,
        ),
        'future_prophetic_messages',
      );
    });

    test('invalid channel falls back to All', () {
      expect(
        QuoteLibraryChannelSelection.resolve('missing_channel', available),
        isEmpty,
      );
    });

    test('similarly named channels do not collide', () {
      expect(
        QuoteLibraryChannelSelection.resolve('daily_quote', available),
        'daily_quote',
      );
      expect(
        QuoteLibraryChannelSelection.resolve('daily', available),
        isEmpty,
      );
    });
  });

  testWidgets(
    'valid design uses shared renderer and malformed design falls back',
    (tester) async {
      final designed = _item({
        'design': {'background_color': '#112233', 'text_color': '#ffffff'},
      });
      await tester.pumpWidget(_presentation(designed));
      expect(find.byType(DxmDynamicQuoteCard), findsOneWidget);

      final malformed = _item({'design_json': '{not valid json'});
      await tester.pumpWidget(_presentation(malformed));
      expect(find.byType(DxmDynamicQuoteCard), findsNothing);
      expect(
        find.text('A valid public quote with meaningful content.'),
        findsOneWidget,
      );
    },
  );
}

QuoteScriptureLibraryItem _item(Map<String, dynamic> raw) {
  return QuoteScriptureLibraryItem(
    id: 'quote',
    categoryKey: 'daily_quote',
    categoryLabel: 'Daily Quote',
    text: 'A valid public quote with meaningful content.',
    attribution: 'Source',
    raw: raw,
  );
}

Widget _presentation(QuoteScriptureLibraryItem item) {
  return MaterialApp(
    home: Scaffold(
      body: QuoteScripturePresentation(item: item, minHeight: 220),
    ),
  );
}
