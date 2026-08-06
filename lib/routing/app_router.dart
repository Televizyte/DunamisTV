import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/books/models/book_models.dart';
import '../features/hub/debug/native_engine_test_screen.dart';
import '../features/hub/renderer/short_video_navigation.dart';
import '../features/hub/renderer/short_video_reel_screen.dart';
import '../features/hub/widgets/dynamic_tab_lookup_screen.dart';
import '../ui/shell/bottom_shell.dart';

// Tabs
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/watch/watch_screen.dart';
import '../ui/screens/inspire/inspire_screen.dart';
import '../ui/screens/explore/explore_screen.dart';
import '../ui/screens/more/more_screen.dart';

// More
import '../ui/screens/more/account_screen.dart';
import '../ui/screens/more/saved_screen.dart';
import '../ui/screens/more/downloads_screen.dart';
import '../ui/screens/more/settings_screen.dart';
import '../ui/screens/more/rate_app_screen.dart';
import '../ui/screens/more/more_information_pages.dart';

// Notifications
import '../ui/screens/notifications/notifications_screen.dart';
import '../ui/screens/notifications/notification_detail_screen.dart';

// Watch
import '../ui/screens/watch/live_options_screen.dart';
import '../ui/screens/watch/channels_list_screen.dart';
import '../ui/screens/watch/watch_video_hub_screen.dart';
import '../ui/screens/watch/hls_player_screen_mobile.dart';
import '../ui/screens/watch/youtube_video_screen.dart';
import '../ui/screens/watch/webview_screen.dart';

// SOD
import '../ui/screens/sod/sod_hub_screen.dart';
import '../ui/screens/sod/sod_quotes_screen.dart';
import '../ui/screens/libraries/short_video_library_screen.dart';
import '../ui/screens/libraries/quotes_scripture_library_screen.dart';

// Articles
import '../ui/screens/articles/articles_hub_screen.dart';
import '../ui/screens/articles/article_detail_screen.dart';

// Highlights
import '../ui/screens/highlights/message_highlight_hub_screen.dart';

// Wordification + Motivation hubs
import '../ui/screens/inspire/wordification_hub_screen.dart';
import '../ui/screens/inspire/motivation_hub_screen.dart';

// Web + YouTube
import '../ui/screens/web/web_screen.dart';
import '../ui/screens/player/youtube_player_screen.dart';

// Explore tools
import '../ui/screens/tools/tools_hub_screen.dart';
import '../ui/screens/tools/quote_creator_screen.dart';
import '../ui/screens/tools/quote_preview_screen.dart';
import '../ui/screens/tools/quote_library_screen.dart';
import '../ui/screens/tools/notes_screen.dart';
import '../ui/screens/tools/note_editor_screen.dart';
import '../ui/screens/tools/note_detail_screen.dart';
import '../ui/screens/tools/note_categories_screen.dart';
import '../ui/screens/tools/note_favorites_screen.dart';
import '../ui/screens/tools/bible_screen.dart';
import '../ui/screens/tools/bible_books_screen.dart';
import '../ui/screens/tools/bible_chapters_screen.dart';
import '../ui/screens/tools/bible_reader_screen.dart';
import '../ui/screens/tools/bible_search_screen.dart';
import '../ui/screens/tools/bible_saved_verses_screen.dart';

// Books
import '../ui/screens/books/books_library_screen.dart';
import '../ui/screens/books/book_detail_screen.dart';
import '../ui/screens/books/book_chapter_reader_screen.dart';

// Hubs
import '../ui/screens/entertainment/entertainment_hub_screen.dart';
import '../ui/screens/games/games_hub_screen.dart';
import '../ui/screens/games/dominion_match_screen.dart';
import '../ui/screens/games/race_of_faith_screen.dart';
import '../games/kingdom_builder/ui/screens/kingdom_builder_screen.dart';
import '../ui/screens/games/bible_quiz_preview_screen.dart';
import '../ui/screens/quiz/quiz_placeholder_screen.dart';

// Inner pages
import '../ui/screens/home/daily_scripture_screen.dart';

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    errorBuilder: (context, state) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ROUTER ERROR:\n\n${state.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    },
    redirect: (context, state) {
      final location = state.uri.path;

      switch (location) {
        case '/bible':
        case '/scripture':
          return '/tools/bible';

        case '/notes':
        case '/note':
        case '/notepad':
          return '/tools/notes';

        case '/quote':
        case '/quotes':
        case '/quote-creator':
        case '/quote_creator':
          return '/tools/quote';

        case '/quotes/library':
        case '/quote-library':
        case '/quote_library':
          return '/tools/quote/library';

        case '/quotes/custom':
        case '/quote/custom':
        case '/custom-quotes':
        case '/custom_quotes':
          return '/highlights';

        case '/motivation/quotes':
        case '/inspire/motivation/quotes':
        case '/motivation-quotes':
        case '/motivation_quotes':
          return '/motivation';

        case '/daily/quote':
        case '/daily-quote':
        case '/daily_quote':
          return '/';

        case '/daily/scripture':
        case '/daily-scriptures':
        case '/daily_scripture':
        case '/daily_scriptures':
          return '/daily-scripture';

        case '/books':
        case '/library':
        case '/book-reader':
        case '/book_reader':
        case '/books-reader':
        case '/books_reader':
        case '/tab/books_reader':
        case '/tab/book_reader':
        case '/tab/books':
        case '/tab/library':
          return '/tools/books';

        case '/youtube':
        case '/video/youtube':
          return '/player/youtube';

        case '/hls':
        case '/stream':
        case '/live-stream':
        case '/livestream':
          return '/player/hls';

        case '/shorts':
        case '/reels':
        case '/short-video':
          return '/short-videos';

        case '/article':
        case '/article/detail':
          return '/articles/detail';

        case '/read-sod':
        case '/watch-sod':
          return '/inspire';

        case '/sod-quiz':
        case '/quiz/sod':
        case '/quiz/sod-quiz':
          return '/quiz/sod_quiz';

        case '/watch/sod':
        case '/watch/sod/':
        case '/watch/read-sod':
        case '/watch/read_sod':
          return '/sod';

        case '/watch/sod-quotes':
        case '/watch/sod_quotes':
        case '/watch/sod/quotes':
          return '/sod/quotes';

        case '/watch/sod-keypoints':
        case '/watch/sod_keypoints':
        case '/watch/sod/keypoints':
          return '/sod/quotes';

        case '/inspire/sod':
        case '/inspire/seed-of-destiny':
        case '/seed-of-destiny':
          return '/inspire';

        case '/inspire/sod-quotes':
        case '/inspire/sod/quotes':
        case '/sod-quotes':
          return '/sod/quotes';

        case '/inspire/sod-keypoints':
        case '/inspire/sod/keypoints':
        case '/sod-keypoints':
          return '/sod/quotes';

        case '/inspire/highlights':
        case '/message-highlights':
        case '/inspire/message-highlights':
          return '/highlights';

        case '/inspire/articles':
        case '/inside-dunamis':
        case '/inspire/inside-dunamis':
          return '/articles';

        case '/inspire/wordification':
          return '/wordification';

        case '/inspire/motivation':
          return '/motivation';

        case '/explore/games':
        case '/game':
        case '/games-hub':
        case '/game-hub':
          return '/games';

        case '/game/dominion-match':
        case '/dominion-match':
        case '/tab/game_dominion_match':
        case '/tab/dominion_match':
          return '/games/dominion-match';

        case '/game/race-of-faith':
        case '/race-of-faith':
        case '/tab/game_race_of_faith':
        case '/tab/race_of_faith':
          return '/games/race-of-faith';

        case '/game/kingdom-builder':
        case '/kingdom-builder':
        case '/tab/game_kingdom_builder':
        case '/tab/kingdom_builder':
        case '/game/dominion-growth':
        case '/dominion-growth':
        case '/dominion-builder':
        case '/games/dominion-builder':
        case '/games/dominion-growth':
        case '/tab/game_dominion_growth':
        case '/tab/dominion_growth':
        case '/tab/dominion_builder':
          return '/games/kingdom-builder';

        case '/game/bible-quiz':
        case '/games/bible-quiz':
        case '/bible-quiz':
        case '/quiz/bible-quiz':
        case '/tab/bible_quiz':
        case '/tab/game_bible_quiz':
          return '/quiz/bible_quiz';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/quiz/:quizKey',
        name: 'quiz-placeholder',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(
                  (state.extra as Map).cast<String, dynamic>())
              : const <String, dynamic>{};

          return QuizPlaceholderScreen(
            quizKey: state.pathParameters['quizKey'] ?? 'general_quiz',
            extra: extra,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => BottomShell(child: child),
        routes: [
          GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen()),
          GoRoute(
              path: '/watch',
              name: 'watch',
              builder: (context, state) => const WatchScreen()),
          GoRoute(
              path: '/inspire',
              name: 'inspire',
              builder: (context, state) => const InspireScreen()),
          GoRoute(
              path: '/explore',
              name: 'explore',
              builder: (context, state) => const ExploreScreen()),
          GoRoute(
              path: '/more',
              name: 'more',
              builder: (context, state) => const MoreScreen()),
          GoRoute(
            path: '/tab/:tabKey',
            name: 'dynamic-tab',
            builder: (context, state) {
              final tabKey = state.pathParameters['tabKey'] ?? '';
              return DynamicTabLookupScreen(tabKey: tabKey);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/more/technical-support',
        name: 'more-technical-support',
        builder: (context, state) =>
            const MoreInformationPage(section: 'technical_support'),
      ),
      GoRoute(
        path: '/more/about-ministry',
        name: 'more-about-ministry',
        builder: (context, state) =>
            const MoreInformationPage(section: 'ministry'),
      ),
      GoRoute(
        path: '/more/about-app',
        name: 'more-about-app',
        builder: (context, state) =>
            const MoreInformationPage(section: 'about_app'),
      ),
      GoRoute(
        path: '/more/legal',
        name: 'more-legal',
        builder: (context, state) =>
            const MoreInformationPage(section: 'legal_index'),
      ),
      GoRoute(
        path: '/more/build-with-dxm',
        name: 'more-build-with-dxm',
        builder: (context, state) =>
            const MoreInformationPage(section: 'build_with_dxm'),
      ),
      GoRoute(
          path: '/account',
          name: 'account',
          builder: (context, state) => const AccountScreen()),
      GoRoute(
          path: '/saved',
          name: 'saved',
          builder: (context, state) => const SavedScreen()),
      GoRoute(
          path: '/downloads',
          name: 'downloads',
          builder: (context, state) => const DownloadsScreen()),
      GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(
          path: '/rate-app',
          name: 'rate-app',
          builder: (context, state) => const RateAppScreen()),
      GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen()),
      GoRoute(
        path: '/notifications/message',
        name: 'notification-message',
        builder: (context, state) {
          final item = state.extra is Map
              ? Map<String, dynamic>.from(
                  (state.extra as Map).cast<String, dynamic>())
              : <String, dynamic>{};
          return NotificationDetailScreen(item: item);
        },
      ),
      GoRoute(
          path: '/watch/channels',
          name: 'channels-list',
          builder: (context, state) => const ChannelsListScreen()),
      GoRoute(
          path: '/watch/videos',
          name: 'watch-videos',
          builder: (context, state) => const WatchVideoHubScreen()),
      GoRoute(
          path: '/live',
          name: 'live-options',
          builder: (context, state) => const LiveOptionsScreen()),
      GoRoute(
        path: '/player/hls',
        name: 'hls-player',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? {};
          final url = extra['url'] as String? ?? '';
          final title = extra['title'] as String? ?? 'Live';
          return HlsPlayerScreen(title: title, url: url);
        },
      ),
      GoRoute(
        path: '/player/youtube-legacy',
        name: 'youtube-player-legacy',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? {};
          final url = extra['url'] as String? ?? '';
          final title = extra['title'] as String? ?? 'Video';
          return YoutubeVideoScreen(title: title, url: url);
        },
      ),
      GoRoute(
        path: '/player/youtube',
        name: 'youtube-player',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? {};
          final url = extra['url'] as String? ?? '';
          final title = extra['title'] as String? ?? 'YouTube';
          return YoutubePlayerScreen(title: title, url: url);
        },
      ),
      GoRoute(
        path: '/watch/web',
        name: 'webview-legacy',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? {};
          final url = extra['url'] as String? ?? '';
          final title = extra['title'] as String? ?? 'Open';
          return WebViewScreen(title: title, url: url);
        },
      ),
      GoRoute(
        path: '/web',
        name: 'web',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? {};
          final url = extra['url'] as String? ?? '';
          final title = extra['title'] as String? ?? 'Open';
          return WebScreen(title: title, url: url);
        },
      ),
      GoRoute(
          path: '/sod',
          name: 'sod-hub',
          builder: (context, state) => const SodHubScreen()),
      GoRoute(
          path: '/sod/quotes',
          name: 'sod-quotes',
          builder: (context, state) => const SodQuotesScreen()),
      GoRoute(
          path: '/highlights',
          name: 'highlights-hub',
          builder: (context, state) => const MessageHighlightHubScreen()),
      GoRoute(
          path: '/articles',
          name: 'articles',
          builder: (context, state) => const ArticlesHubScreen()),
      GoRoute(
        path: '/articles/detail',
        name: 'article-detail',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? {};
          final notificationItem = extra['notification_item'] is Map
              ? Map<String, dynamic>.from(
                  (extra['notification_item'] as Map).cast<String, dynamic>())
              : null;
          final id = (extra['id'] ??
                  extra['content_id'] ??
                  extra['article_id'] ??
                  notificationItem?['content_id'] ??
                  notificationItem?['article_id'] ??
                  (notificationItem?['data'] is Map
                      ? (notificationItem?['data'] as Map)['content_id']
                      : null) ??
                  (notificationItem?['data'] is Map
                      ? (notificationItem?['data'] as Map)['article_id']
                      : null) ??
                  state.uri.queryParameters['id'] ??
                  state.uri.queryParameters['content_id'] ??
                  state.uri.queryParameters['article_id'] ??
                  state.uri.queryParameters['slug'] ??
                  'demo')
              .toString();
          return ArticleDetailScreen(
            articleId: id,
            initialItem: notificationItem,
            sourceHint: extra['source']?.toString(),
          );
        },
      ),
      GoRoute(
          path: '/wordification',
          name: 'wordification-hub',
          builder: (context, state) => const WordificationHubScreen()),
      GoRoute(
          path: '/motivation',
          name: 'motivation-hub',
          builder: (context, state) => const MotivationHubScreen()),
      GoRoute(
          path: '/tools',
          name: 'tools-hub',
          builder: (context, state) => const ToolsHubScreen()),
      GoRoute(
          path: '/tools/books',
          name: 'books-library',
          builder: (context, state) => const BooksLibraryScreen()),
      GoRoute(
        path: '/tools/books/detail',
        name: 'book-detail',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? {};
          final book =
              extra['book'] is BookItem ? extra['book'] as BookItem : null;
          final bookId = (extra['bookId'] ??
                  extra['id'] ??
                  extra['slug'] ??
                  state.uri.queryParameters['bookId'] ??
                  state.uri.queryParameters['id'] ??
                  state.uri.queryParameters['slug'] ??
                  '')
              .toString();
          return BookDetailScreen(initialBook: book, bookId: bookId);
        },
      ),
      GoRoute(
        path: '/tools/books/chapter',
        name: 'book-chapter-reader',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? {};
          final book =
              extra['book'] is BookItem ? extra['book'] as BookItem : null;
          final chapter = extra['chapter'] is BookChapter
              ? extra['chapter'] as BookChapter
              : null;
          final bookId = (extra['bookId'] ??
                  extra['book_slug'] ??
                  state.uri.queryParameters['bookId'] ??
                  state.uri.queryParameters['book_slug'] ??
                  state.uri.queryParameters['book'] ??
                  '')
              .toString();
          final chapterId = (extra['chapterId'] ??
                  extra['chapter_slug'] ??
                  state.uri.queryParameters['chapterId'] ??
                  state.uri.queryParameters['chapter_slug'] ??
                  state.uri.queryParameters['chapter'] ??
                  '')
              .toString();
          return BookChapterReaderScreen(
            initialBook: book,
            initialChapter: chapter,
            bookId: bookId,
            chapterId: chapterId,
          );
        },
      ),
      GoRoute(
          path: '/tools/quote',
          name: 'quote-creator',
          builder: (context, state) => const QuoteCreatorScreen()),
      GoRoute(
          path: '/tools/quote/preview',
          name: 'quote-preview',
          builder: (context, state) => const QuotePreviewScreen()),
      GoRoute(
          path: '/tools/quote/library',
          name: 'quote-library',
          builder: (context, state) => const QuoteLibraryScreen()),
      GoRoute(
          path: '/tools/notes',
          name: 'notes',
          builder: (context, state) => const NotesScreen()),
      GoRoute(
          path: '/tools/notes/editor',
          name: 'notes-editor',
          builder: (context, state) => const NoteEditorScreen()),
      GoRoute(
          path: '/tools/notes/detail',
          name: 'notes-detail',
          builder: (context, state) => const NoteDetailScreen()),
      GoRoute(
          path: '/tools/notes/categories',
          name: 'notes-categories',
          builder: (context, state) => const NoteCategoriesScreen()),
      GoRoute(
          path: '/tools/notes/favorites',
          name: 'notes-favorites',
          builder: (context, state) => const NoteFavoritesScreen()),
      GoRoute(
          path: '/tools/bible',
          name: 'bible',
          builder: (context, state) => const BibleScreen()),
      GoRoute(
          path: '/tools/bible/books',
          name: 'bible-books',
          builder: (context, state) => const BibleBooksScreen()),
      GoRoute(
          path: '/tools/bible/chapters',
          name: 'bible-chapters',
          builder: (context, state) => const BibleChaptersScreen()),
      GoRoute(
          path: '/tools/bible/reader',
          name: 'bible-reader',
          builder: (context, state) => const BibleReaderScreen()),
      GoRoute(
          path: '/tools/bible/search',
          name: 'bible-search',
          builder: (context, state) => const BibleSearchScreen()),
      GoRoute(
          path: '/tools/bible/saved',
          name: 'bible-saved',
          builder: (context, state) => const BibleSavedVersesScreen()),
      GoRoute(
        path: '/short-videos/library',
        name: 'short-video-library',
        builder: (context, state) => ShortVideoLibraryScreen(
          initialChannelKey: state.uri.queryParameters['channel'] ?? '',
        ),
      ),
      GoRoute(
        path: '/quotes-scripture/library',
        name: 'quotes-scripture-library',
        builder: (context, state) => QuotesScriptureLibraryScreen(
          initialCategory: _firstNonEmpty([
            state.uri.queryParameters['channel'],
            state.uri.queryParameters['channel_key'],
            state.uri.queryParameters['category'],
          ]),
        ),
      ),
      GoRoute(
        path: '/quotes-scripture/reader',
        name: 'quotes-scripture-reader',
        builder: (context, state) {
          final extra = (state.extra as Map?) ?? const {};
          final rawItems = extra['items'];
          final items = rawItems is List<QuoteScriptureLibraryItem>
              ? rawItems
              : const <QuoteScriptureLibraryItem>[];
          return QuoteScriptureReaderScreen(
            items: items,
            initialId: (extra['initialId'] ?? '').toString(),
            categoryKey: (extra['category'] ?? '').toString(),
          );
        },
      ),
      GoRoute(
        path: '/short-videos',
        name: 'short-videos',
        builder: (context, state) {
          final extra = state.extra;
          final queryIndex =
              int.tryParse(state.uri.queryParameters['initialIndex'] ?? '') ??
                  0;
          final queryItemId = _firstNonEmpty([
            state.uri.queryParameters['id'],
            state.uri.queryParameters['content_id'],
            state.uri.queryParameters['post_id'],
            state.uri.queryParameters['item_id'],
            state.uri.queryParameters['video_id'],
          ]);
          final queryChannelKey = _firstNonEmpty([
            state.uri.queryParameters['channel'],
            state.uri.queryParameters['channel_key'],
            state.uri.queryParameters['short_channel'],
            state.uri.queryParameters['short_channel_key'],
          ]);
          return ShortVideoReelScreen(
            items: ShortVideoNavigation.extractItems(extra),
            initialIndex: ShortVideoNavigation.extractInitialIndex(extra,
                fallback: queryIndex),
            initialItemId: ShortVideoNavigation.extractInitialItemId(extra,
                fallback: queryItemId),
            initialChannelKey: ShortVideoNavigation.extractInitialChannelKey(
                extra,
                fallback: queryChannelKey),
            title: ShortVideoNavigation.extractTitle(extra),
          );
        },
      ),
      GoRoute(
          path: '/entertainment',
          name: 'entertainment-hub',
          builder: (context, state) => const EntertainmentHubScreen()),
      GoRoute(
          path: '/games',
          name: 'games-hub',
          builder: (context, state) => const GamesHubScreen()),
      GoRoute(
          path: '/games/dominion-match',
          name: 'game-dominion-match',
          builder: (context, state) => const DominionMatchScreen()),
      GoRoute(
          path: '/games/race-of-faith',
          name: 'game-race-of-faith',
          builder: (context, state) => const RaceOfFaithScreen()),
      GoRoute(
          path: '/games/kingdom-builder',
          name: 'game-kingdom-builder',
          builder: (context, state) => const KingdomBuilderScreen()),
      GoRoute(
          path: '/games/bible-quiz',
          redirect: (_, __) => '/quiz/bible_quiz',
          name: 'game-bible-quiz',
          builder: (context, state) => const BibleQuizPreviewScreen()),
      GoRoute(
          path: '/daily-scripture',
          name: 'daily-scripture',
          builder: (context, state) => const DailyScriptureScreen()),
      GoRoute(
          path: '/debug/native-engines',
          name: 'debug-native-engines',
          builder: (context, state) => const NativeEngineTestScreen()),
    ],
  );
}
