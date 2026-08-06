import 'package:dunamis_tv/features/hub/models/short_video_item.dart';
import 'package:dunamis_tv/ui/screens/explore/explore_screen.dart';
import 'package:dunamis_tv/ui/screens/games/games_hub_screen.dart';
import 'package:dunamis_tv/ui/screens/libraries/quotes_scripture_library_screen.dart';
import 'package:dunamis_tv/ui/screens/libraries/short_video_library_screen.dart';
import 'package:dunamis_tv/ui/shared/designers/dxm_dynamic_quote_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Explore route precedence', () {
    test('exact Quote Library route wins over Quote Creator inference', () {
      expect(
        ExploreReleaseContract.resolveRoute(
          '/quotes-scripture/library',
          title: 'Quote Creator Library',
        ),
        '/quotes-scripture/library',
      );
    });

    test('Short Video Library cannot be inferred as Books', () {
      expect(
        ExploreReleaseContract.resolveRoute(
          '/short-videos/library',
          title: 'Short Video Library',
        ),
        '/short-videos/library',
      );
      expect(
        ExploreReleaseContract.resolveRoute(
          '/short-videos',
          title: 'Play All',
        ),
        '/short-videos',
      );
    });

    test('placement zones retain approved broad order', () {
      const zones = <String>[
        'featured',
        'quick_tools',
        'media',
        'libraries',
        'resources',
        'games',
      ];
      final priorities = zones
          .map((zone) => ExploreReleaseContract.zonePriority(zone))
          .toList();
      expect(priorities, orderedEquals(<int?>[10, 20, 40, 50, 60, 70]));
      expect(ExploreReleaseContract.zonePriority('unknown'), isNull);
    });
  });

  group('Quote channels and design', () {
    test('arbitrary future channels remain distinct and All includes both', () {
      final items = QuoteScriptureLibraryMapper.fromRawHub({
        'sections': [
          {
            'type': 'quote_channel',
            'channel_key': 'future_prophetic_messages',
            'channel_title': 'Future Prophetic Messages',
            'channel_order': 20,
            'items': [
              {
                'id': 'future-1',
                'quote': 'A sufficiently long future-channel quote.',
              },
            ],
          },
          {
            'renderer_type': 'quote_channel',
            'channel_key': 'future_leadership_lessons',
            'channel_title': 'Future Leadership Lessons',
            'channel_order': 10,
            'items': [
              {
                'id': 'future-2',
                'quote': 'A sufficiently long leadership-channel quote.',
              },
            ],
          },
        ],
      });

      expect(items, hasLength(2));
      expect(
        QuoteScriptureLibraryMapper.categories(items).keys,
        containsAll(<String>[
          'future_prophetic_messages',
          'future_leadership_lessons',
        ]),
      );
      expect(items.first.categoryKey, 'future_leadership_lessons');
      expect(items.last.categoryKey, 'future_prophetic_messages');
    });

    test('unrelated channel metadata does not admit non-quote content', () {
      final items = QuoteScriptureLibraryMapper.fromRawHub({
        'sections': [
          {
            'type': 'article_channel',
            'channel_key': 'general-news',
            'items': [
              {
                'id': 'article-1',
                'text': 'This is a sufficiently long unrelated article.',
              },
            ],
          },
        ],
      });
      expect(items, isEmpty);
    });

    test('legacy quote classifications remain available', () {
      final items = QuoteScriptureLibraryMapper.fromRawHub({
        'daily_scripture': {
          'id': 'scripture',
          'verse_text': 'A sufficiently long daily Scripture passage.',
        },
        'sod_quotes': [
          {'id': 'sod', 'quote': 'A sufficiently long SOD quotation.'},
        ],
        'motivation': [
          {'id': 'motivation', 'text': 'A sufficiently long motivation item.'},
        ],
        'daily_quote': {
          'id': 'daily',
          'quote': 'A sufficiently long daily quotation.',
        },
      });
      expect(
        items.map((item) => item.categoryKey),
        containsAll(<String>[
          'daily_scripture',
          'sod_quotes',
          'motivational_quotes',
          'daily_quote',
        ]),
      );
    });

    testWidgets('designed payload reaches shared renderer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final item = _quote(<String, dynamic>{
        'design': <String, dynamic>{
          'background_color': '#112233',
          'text_color': '#ffffff',
          'font_size': 22,
        },
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuoteScripturePresentation(
              item: item,
              minHeight: 220,
              allowVerticalScroll: true,
            ),
          ),
        ),
      );
      expect(find.byType(DxmDynamicQuoteCard), findsOneWidget);
    });

    testWidgets('missing design safely uses text fallback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuoteScripturePresentation(
              item: _quote(const <String, dynamic>{}),
              minHeight: 220,
            ),
          ),
        ),
      );
      expect(find.byType(DxmDynamicQuoteCard), findsNothing);
      expect(
          find.text('A release-safe quote with enough text.'), findsOneWidget);
    });

    test('malformed design safely resolves to text fallback', () {
      expect(
        QuoteScriptureDesign.resolve(
          const <String, dynamic>{'design_json': '{not valid json'},
        ),
        isNull,
      );
    });
  });

  test('similarly named short-video channels do not collide', () {
    final item = ShortVideoItem.fromMap(<String, dynamic>{
      'id': 'one',
      'title': 'One',
      'video_url': 'https://example.invalid/video.mp4',
      'category_key': 'weird-facts-extra',
      'channel_key': 'weird-facts-extra',
    });
    expect(ShortVideoChannelMatcher.matches(item, 'weird facts extra'), isTrue);
    expect(ShortVideoChannelMatcher.matches(item, 'weird facts'), isFalse);
  });

  test('existing game routes remain unchanged', () {
    expect(
      GameHubReleaseContract.routes,
      containsAll(<String>{
        '/games/dominion-match',
        '/games/race-of-faith',
        '/games/kingdom-builder',
        '/games/bible-quiz',
      }),
    );
  });
}

QuoteScriptureLibraryItem _quote(Map<String, dynamic> raw) {
  return QuoteScriptureLibraryItem(
    id: 'quote-1',
    categoryKey: 'test',
    categoryLabel: 'Test',
    text: 'A release-safe quote with enough text.',
    attribution: 'Source',
    raw: raw,
  );
}
