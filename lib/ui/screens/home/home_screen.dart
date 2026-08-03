import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../features/hub/state/hub_scope.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../shell/bottom_shell.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';
import '../../widgets/dxm_top_bar.dart';
import 'widgets/home_daily_cards.dart';
import 'widgets/home_short_video_carousel.dart';

bool _dxmBool(dynamic value, {bool fallback = false}) {
  final raw = (value ?? '').toString().trim().toLowerCase();
  if (raw.isEmpty) return fallback;
  return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
}

double _dxmDouble(
  dynamic value, {
  required double fallback,
  double? min,
  double? max,
}) {
  final raw = (value ?? '').toString().trim();
  final parsed = double.tryParse(raw);
  if (parsed == null) return fallback;

  var output = parsed;
  if (min != null && output < min) output = min;
  if (max != null && output > max) output = max;
  return output;
}

double _dxmClampDouble(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

String _dxmPick(Map<String, String> source, List<String> keys) {
  for (final key in keys) {
    final value = (source[key] ?? '').trim();
    if (value.isNotEmpty) return value;
  }
  return '';
}

Color _dxmColor(dynamic value, {required Color fallback}) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return fallback;

  var hex = raw;
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.startsWith('0x')) hex = hex.substring(2);
  if (hex.length == 6) hex = 'FF$hex';

  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;

  return Color(parsed);
}

FontWeight _dxmFontWeight(
  dynamic value, {
  FontWeight fallback = FontWeight.w900,
}) {
  final raw = (value ?? '').toString().trim();
  final parsed = int.tryParse(raw);
  if (parsed == null) return fallback;

  if (parsed <= 100) return FontWeight.w100;
  if (parsed <= 200) return FontWeight.w200;
  if (parsed <= 300) return FontWeight.w300;
  if (parsed <= 400) return FontWeight.w400;
  if (parsed <= 500) return FontWeight.w500;
  if (parsed <= 600) return FontWeight.w600;
  if (parsed <= 700) return FontWeight.w700;
  if (parsed <= 800) return FontWeight.w800;
  return FontWeight.w900;
}

TextAlign _dxmTextAlign(
  dynamic value, {
  TextAlign fallback = TextAlign.center,
}) {
  switch ((value ?? '').toString().trim().toLowerCase()) {
    case 'left':
    case 'start':
      return TextAlign.left;
    case 'right':
    case 'end':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    case 'center':
      return TextAlign.center;
    default:
      return fallback;
  }
}

CrossAxisAlignment _crossAxisFromTextAlign(TextAlign align) {
  switch (align) {
    case TextAlign.left:
    case TextAlign.start:
      return CrossAxisAlignment.start;
    case TextAlign.right:
    case TextAlign.end:
      return CrossAxisAlignment.end;
    case TextAlign.center:
    case TextAlign.justify:
      return CrossAxisAlignment.center;
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String tabKey = 'home';

  @override
  Widget build(BuildContext context) {
    final hub = HubScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([hub, ThemeController.instance]),
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;

        final heroSlides = hub.homeHeroSlides;
        final liveCard = hub.homeLiveCard;
        final sodCard = hub.homeSodCard;
        final articlesCard = hub.homeArticlesCard;
        final highlightsCard = hub.homeHighlightsCard;
        final tools = hub.exploreTools;

        final prayerTitle = (hub.homePrayerTitle).trim().isNotEmpty
            ? hub.homePrayerTitle
            : 'Commanding The Day Prayer Broadcast';
        final prayerUrl = hub.homePrayerYoutubeUrl;
        final prayerCardSubtitle = (prayerUrl ?? '').trim().isNotEmpty
            ? 'Tap to open in Watch'
            : 'Open broadcast';

        final scripture = hub.homeDailyScripture;
        final hasScripture = hub.hasHomeDailyScripture;
        final scriptureRef = (scripture['ref'] ?? '').trim();
        final scriptureVerse = (scripture['verse'] ?? '').trim();
        final scriptureNote = (scripture['note'] ?? '').trim();
        final scriptureImageUrl = (scripture['image_url'] ?? '').trim();
        final scriptureUseSolidBackground = _dxmBool(
          _dxmPick(scripture, const ['use_solid_background', 'use_solid_bg']),
        );
        final scriptureBackgroundColor = _dxmColor(
          _dxmPick(scripture, const ['background_color', 'bg_color']),
          fallback: const Color(0xFFFDF2F8),
        );
        final scriptureTextColor = _dxmColor(
          scripture['text_color'],
          fallback: scriptureUseSolidBackground
              ? const Color(0xFF500724)
              : Colors.white,
        );
        final scriptureAccentColor = _dxmColor(
          scripture['accent_color'],
          fallback: const Color(0xFFEC4899),
        );
        final scriptureFontSize = _dxmDouble(
          scripture['font_size'],
          fallback: 22,
          min: 10,
          max: 42,
        );
        final scriptureTitleSize = _dxmDouble(
          scripture['title_size'],
          fallback: 14,
          min: 10,
          max: 34,
        );
        final scriptureOverlayStrength = _dxmDouble(
          scripture['overlay_strength'],
          fallback: scriptureUseSolidBackground ? 0 : 0.72,
          min: 0,
          max: 1,
        );
        final scriptureFontWeight = _dxmFontWeight(
          scripture['font_weight'],
          fallback: FontWeight.w900,
        );
        final scriptureTextAlign = _dxmTextAlign(scripture['text_align']);

        final dailyQuote = hub.homeDailyQuote;
        final hasDailyQuote = hub.hasHomeDailyQuote;
        final quoteText = (dailyQuote['quote'] ?? '').trim();
        final quoteSource = (dailyQuote['source'] ?? '').trim();
        final quoteImageUrl = (dailyQuote['image_url'] ?? '').trim();
        final quoteUseSolidBackground = _dxmBool(
          _dxmPick(dailyQuote, const ['use_solid_background', 'use_solid_bg']),
        );
        final quoteBackgroundColor = _dxmColor(
          _dxmPick(dailyQuote, const ['background_color', 'bg_color']),
          fallback: const Color(0xFF4B3A1F),
        );
        final quoteTextColor = _dxmColor(
          dailyQuote['text_color'],
          fallback:
              quoteUseSolidBackground ? const Color(0xFFFFFFFF) : Colors.white,
        );
        final quoteAccentColor = _dxmColor(
          dailyQuote['accent_color'],
          fallback: const Color(0xFFEC4899),
        );
        final quoteFontSize = _dxmDouble(
          dailyQuote['font_size'],
          fallback: 24,
          min: 10,
          max: 44,
        );
        final quoteTitleSize = _dxmDouble(
          dailyQuote['title_size'],
          fallback: 13.4,
          min: 9,
          max: 32,
        );
        final quoteOverlayStrength = _dxmDouble(
          dailyQuote['overlay_strength'],
          fallback: quoteUseSolidBackground ? 0 : 0.72,
          min: 0,
          max: 1,
        );
        final quoteFontWeight = _dxmFontWeight(
          dailyQuote['font_weight'],
          fallback: FontWeight.w900,
        );
        final quoteTextAlign = _dxmTextAlign(dailyQuote['text_align']);

        final quickItems = _buildQuickItems(hub, tools);
        final quickToolEntries =
            NativeListInjection.buildEntries<Map<String, String>>(
          quickItems,
          tabKey: 'home.native.quick_tools',
        );
        AdsService.instance.preloadInterstitial();

        return Scaffold(
          backgroundColor:
              isLight ? const Color(0xFFF7F1E6) : Colors.transparent,
          appBar: DxmTopBar(
            title: 'Home',
            showMenu: true,
            onRefresh: hub.refresh,
          ),
          body: Container(
            color: isLight ? const Color(0xFFF7F1E6) : Colors.transparent,
            child: ListView(
              padding: EdgeInsets.only(
                bottom: BottomShellInsets.of(context) + 12,
              ),
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _HomeHeroCarousel(slides: heroSlides),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _SectionHeader(
                    title: 'Quick Access',
                    subtitle: 'Start from the main things you came for today.',
                    isLight: isLight,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _GroupedSectionShell(
                    isLight: isLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final spacing = 12.0;
                            final wide = constraints.maxWidth >= 760;
                            final cardWidth = wide
                                ? (constraints.maxWidth - spacing) / 2
                                : constraints.maxWidth;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                SizedBox(
                                  width: cardWidth,
                                  child: _HomeBannerShortcutCard(
                                    title:
                                        liveCard['title'] ?? 'Dunamis TV Live',
                                    subtitle: liveCard['subtitle'] ??
                                        'Watch live broadcast and streaming content',
                                    imageUrl: liveCard['image_url'],
                                    fallbackAsset: 'assets/images/home_1.jpg',
                                    badge: 'WATCH',
                                    onTap: () => _goWithAd(
                                      context,
                                      '/watch',
                                      policyKey: 'home.action.watch',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _HomeBannerShortcutCard(
                                    title:
                                        sodCard['title'] ?? 'SEED of Destiny',
                                    subtitle: sodCard['subtitle'] ??
                                        'Read today’s devotional and key spiritual insights',
                                    imageUrl: sodCard['image_url'],
                                    fallbackAsset: 'assets/images/home_2.jpg',
                                    badge: 'READ',
                                    onTap: () =>
                                        _goWithoutAd(context, '/inspire'),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _HomeBannerShortcutCard(
                                    title: articlesCard['title'] ??
                                        'Inside Dunamis',
                                    subtitle: articlesCard['subtitle'] ??
                                        'Read featured articles and ministry updates',
                                    imageUrl: articlesCard['image_url'],
                                    fallbackAsset: 'assets/images/home_3.jpg',
                                    badge: 'INSPIRE',
                                    onTap: () => _pushWithAd(
                                      context,
                                      '/articles',
                                      policyKey: 'home.action.articles',
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: cardWidth,
                                  child: _HomeBannerShortcutCard(
                                    title: highlightsCard['title'] ??
                                        'Message Highlight',
                                    subtitle: highlightsCard['subtitle'] ??
                                        'Catch short message summaries and spiritual takeaways',
                                    imageUrl: highlightsCard['image_url'],
                                    fallbackAsset: 'assets/images/home_4.jpg',
                                    badge: 'FEATURED',
                                    onTap: () => _pushWithAd(
                                      context,
                                      '/highlights',
                                      policyKey:
                                          'home.action.message_highlights',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _InnerSectionLabel(
                          title: 'Prayer Broadcast',
                          subtitle:
                              'Open the current prayer stream from Watch.',
                          isLight: isLight,
                        ),
                        const SizedBox(height: 12),
                        _PrayerBroadcastCard(
                          title: prayerTitle,
                          subtitle: prayerCardSubtitle,
                          imageUrl: hub.homePrayerImageUrl,
                          fallbackAsset: 'assets/images/home_5.jpg',
                          enabled: true,
                          onTap: () => _goWithAd(
                            context,
                            '/watch',
                            policyKey: 'home.action.watch',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: NativeInlineAdTile(
                    tabKey: 'home.native.after_quick_access',
                    label: 'Sponsored',
                    minHeight: 92,
                    margin: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _SectionHeader(
                    title: 'Short Videos',
                    subtitle:
                        'Fresh short clips and quick inspiration from the video engine.',
                    isLight: isLight,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _GroupedSectionShell(
                    isLight: isLight,
                    child: HomeShortVideoCarousel(
                      rawHub: hub.raw,
                      isLight: isLight,
                      onTap: (route) => _pushWithAd(
                        context,
                        route.trim().isNotEmpty
                            ? route.trim()
                            : '/short-videos',
                        policyKey: 'home.action.short_videos',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _SectionHeader(
                    title: "Today's Scripture",
                    subtitle:
                        'A clean daily encouragement card you can read or share quickly.',
                    isLight: isLight,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: hasScripture
                      ? DxmDailyScriptureCarousel(
                          cards: hub.homeDailyScriptureCards,
                          fallbackRef: scriptureRef,
                          fallbackVerse: scriptureVerse,
                          fallbackNote: scriptureNote,
                          imageUrl: scriptureImageUrl,
                          useSolidBackground: scriptureUseSolidBackground,
                          backgroundColor: scriptureBackgroundColor,
                          textColor: scriptureTextColor,
                          accentColor: scriptureAccentColor,
                          fontSize: scriptureFontSize,
                          referenceFontSize: scriptureTitleSize,
                          fontWeight: scriptureFontWeight,
                          textAlign: scriptureTextAlign,
                          overlayStrength: scriptureOverlayStrength,
                          onShare: (card) {
                            final shareText = _dailyScriptureShareText(card);
                            if (shareText.trim().isNotEmpty) {
                              Share.share(shareText);
                            }
                          },
                          onOpenInQuoteCreator: (card) => _pushWithAd(
                            context,
                            '/tools/quote',
                            policyKey:
                                'home.action.daily_scripture.quote_creator',
                            extra: _dailyScriptureQuoteCreatorExtra(card),
                          ),
                          onReadFullBible: (card) => _pushWithAd(
                            context,
                            '/tools/bible',
                            policyKey: 'home.action.daily_scripture.bible',
                            extra: {
                              'ref': _dailyPick(card, const [
                                'ref',
                                'reference',
                                'quote_source',
                              ]),
                              'verse': _dailyPick(card, const [
                                'verse',
                                'quote_text',
                                'text',
                              ]),
                              'note': _dailyPick(card, const [
                                'note',
                                'subtitle',
                                'description',
                              ]),
                            },
                          ),
                        )
                      : _DailyScripturePlaceholderCard(
                          imageUrl: null,
                          onReadFullBible: () => _pushWithAd(
                            context,
                            '/tools/bible',
                            policyKey: 'home.action.daily_scripture.bible',
                          ),
                        ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _SectionHeader(
                    title: 'Quick Tools',
                    subtitle:
                        'Quote Creator, Notes, Bible and Books Reader/Library.',
                    isLight: isLight,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _GroupedSectionShell(
                    isLight: isLight,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Keep Quick Tools as a true 2 x 2 tool grid on phones.
                        // The surrounding section shell already adds padding, so the
                        // inner width on smaller Android devices can fall below 320px.
                        // Using a lower breakpoint prevents the cards from collapsing
                        // into a single vertical list while preserving the existing card
                        // component and desktop behavior.
                        final spacing =
                            constraints.maxWidth >= 300 ? 12.0 : 10.0;
                        final useTwoColumns = constraints.maxWidth >= 240;
                        final cardWidth = useTwoColumns
                            ? (constraints.maxWidth - spacing) / 2
                            : constraints.maxWidth;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: List.generate(quickToolEntries.length, (
                            index,
                          ) {
                            final entry = quickToolEntries[index];

                            if (entry.isAd) {
                              return SizedBox(
                                width: cardWidth,
                                child: const NativeInlineAdTile(
                                  tabKey: 'home.native.quick_tools',
                                  label: 'Sponsored',
                                  minHeight: 126,
                                ),
                              );
                            }

                            final item = entry.item!;
                            return SizedBox(
                              width: cardWidth,
                              child: _MiniBannerCard(
                                title: item['title'] ?? 'Tool',
                                subtitle: item['subtitle'] ?? 'Open tool',
                                imageUrl: item['image_url'],
                                fallbackAsset:
                                    'assets/images/home_${(entry.itemIndex % 5) + 1}.jpg',
                                onTap: () {
                                  final route = item['route'] ?? '/tools';
                                  _pushWithAd(
                                    context,
                                    route,
                                    policyKey: _homePolicyKeyForRoute(route),
                                  );
                                },
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: _SectionHeader(
                    title: 'Daily Quote',
                    subtitle:
                        'A strong quote moment that should stand out at a glance.',
                    isLight: isLight,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                  child: hasDailyQuote
                      ? DxmDailyQuoteCarousel(
                          cards: hub.homeDailyQuoteCards,
                          fallbackQuote: quoteText,
                          fallbackSource: quoteSource,
                          imageUrl: quoteImageUrl,
                          useSolidBackground: quoteUseSolidBackground,
                          backgroundColor: quoteBackgroundColor,
                          textColor: quoteTextColor,
                          accentColor: quoteAccentColor,
                          fontSize: quoteFontSize,
                          brandFontSize: quoteTitleSize,
                          fontWeight: quoteFontWeight,
                          textAlign: quoteTextAlign,
                          overlayStrength: quoteOverlayStrength,
                          onShare: (card) {
                            final shareText = _dailyQuoteShareText(card);
                            if (shareText.trim().isNotEmpty) {
                              Share.share(shareText);
                            }
                          },
                          onOpenInQuoteCreator: (card) => _pushWithAd(
                            context,
                            '/tools/quote',
                            policyKey: 'home.action.daily_quote.quote_creator',
                            extra: _dailyQuoteCreatorExtra(card),
                          ),
                          onAddToNotes: (card) => _pushWithAd(
                            context,
                            '/tools/notes/editor',
                            policyKey: 'home.action.daily_quote.notes',
                            extra: {
                              'prefill': _dailyQuoteShareText(card),
                              'title': 'Daily Quote',
                              'sourceType': 'daily-quote',
                              'sourceId': _dailyPick(
                                card,
                                const ['source', 'quote_source'],
                              ).isNotEmpty
                                  ? _dailyPick(
                                      card,
                                      const ['source', 'quote_source'],
                                    )
                                  : 'daily-quote',
                              'image_url': _dailyPick(
                                card,
                                const ['image_url', 'image'],
                              ),
                            },
                          ),
                        )
                      : _DailyQuotePlaceholderCard(
                          imageUrl: null,
                          onOpenInQuoteCreator: () => _pushWithAd(
                            context,
                            '/tools/quote',
                            policyKey: 'home.action.quick_tools.quote_creator',
                          ),
                          onAddToNotes: () => _pushWithAd(
                            context,
                            '/tools/notes/editor',
                            policyKey: 'home.action.quick_tools.notes',
                          ),
                        ),
                ),
                if ((hub.error ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                    child: Text(
                      'Backend currently unavailable. Showing fallback content where needed.',
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF6B6256)
                            : Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _dailyPick(Map<String, String> card, List<String> keys) {
    for (final key in keys) {
      final value = (card[key] ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _dailyScriptureShareText(Map<String, String> card) {
    final verse = _dailyPick(card, const ['verse', 'quote_text', 'text']);
    final ref = _dailyPick(card, const ['ref', 'reference', 'quote_source']);
    final note = _dailyPick(card, const ['note', 'subtitle', 'description']);

    return [
      if (verse.isNotEmpty) verse,
      if (ref.isNotEmpty) ref,
      if (note.isNotEmpty) note,
    ].join('\n\n');
  }

  static String _dailyQuoteShareText(Map<String, String> card) {
    final quote = _dailyPick(card, const ['quote', 'quote_text', 'text']);
    final source = _dailyPick(card, const ['source', 'quote_source']);

    return [
      if (quote.isNotEmpty) quote,
      if (source.isNotEmpty) '— $source',
    ].join('\n\n');
  }

  static Map<String, dynamic> _dailyScriptureQuoteCreatorExtra(
    Map<String, String> card,
  ) {
    final ref = _dailyPick(card, const ['ref', 'reference', 'quote_source']);
    final note = _dailyPick(card, const ['note', 'subtitle', 'description']);
    final imageUrl = _dailyPick(card, const ['image_url', 'image']);

    return {
      ...card,
      'prefill': _dailyScriptureShareText(card),
      'source': 'daily-scripture',
      'reference': ref,
      'note': note,
      'image_url': imageUrl,
      'background_image_url': imageUrl,
      'source_type': 'daily-scripture',
      'source_id': ref,
    };
  }

  static Map<String, dynamic> _dailyQuoteCreatorExtra(
    Map<String, String> card,
  ) {
    final source = _dailyPick(card, const ['source', 'quote_source']);
    final imageUrl = _dailyPick(card, const ['image_url', 'image']);

    return {
      ...card,
      'prefill': _dailyQuoteShareText(card),
      'source': 'daily-quote',
      'author': source,
      'image_url': imageUrl,
      'background_image_url': imageUrl,
      'source_type': 'daily-quote',
      'source_id': source.isNotEmpty ? source : 'daily-quote',
    };
  }

  static String _homePolicyKeyForRoute(String route) {
    final normalized = route.trim().toLowerCase();
    if (normalized.startsWith('/watch')) return 'home.action.watch';
    if (normalized.startsWith('/articles')) return 'home.action.articles';
    if (normalized.startsWith('/highlights')) {
      return 'home.action.message_highlights';
    }
    if (normalized.startsWith('/short-videos')) {
      return 'home.action.short_videos';
    }
    if (normalized.startsWith('/tools/quote')) {
      return 'home.action.quick_tools.quote_creator';
    }
    if (normalized.startsWith('/tools/notes')) {
      return 'home.action.quick_tools.notes';
    }
    if (normalized.startsWith('/tools/bible')) {
      return 'home.action.quick_tools.bible';
    }
    if (normalized.startsWith('/books')) {
      return 'home.action.quick_tools.books';
    }
    return 'home.action.other';
  }

  static Future<void> _goWithAd(
    BuildContext context,
    String route, {
    String? policyKey,
  }) async {
    final resolvedPolicy = AdsService.instance.resolveConfiguredPolicyKey(
      <String>[
        if (policyKey != null) policyKey,
        _homePolicyKeyForRoute(route),
      ],
      fallback: tabKey,
    );

    await AdsService.instance.maybeShowInterstitialOnSafeNav(
      context,
      tabKey: resolvedPolicy,
    );

    if (!context.mounted) return;
    context.go(route);
  }

  static void _goWithoutAd(BuildContext context, String route) {
    context.go(route);
  }

  static Future<void> _pushWithAd(
    BuildContext context,
    String route, {
    String? policyKey,
    Object? extra,
  }) async {
    final resolvedPolicy = AdsService.instance.resolveConfiguredPolicyKey(
      <String>[
        if (policyKey != null) policyKey,
        _homePolicyKeyForRoute(route),
      ],
      fallback: tabKey,
    );

    await AdsService.instance.maybeShowInterstitialOnSafeNav(
      context,
      tabKey: resolvedPolicy,
    );

    if (!context.mounted) return;
    context.push(route, extra: extra);
  }

  static void _pushWithoutAd(
    BuildContext context,
    String route, {
    Object? extra,
  }) {
    context.push(route, extra: extra);
  }

  static List<Map<String, String>> _buildQuickItems(
    dynamic hub,
    List<Map<String, String>> backendTools,
  ) {
    final Map<String, Map<String, String>> byRoute =
        <String, Map<String, String>>{};

    for (final item in backendTools) {
      final rawTitle = item['title'] ?? 'Tool';
      final route = _mapBackendToolRoute(item['route'], title: rawTitle);
      if (route == '/tools') continue;

      final title = _canonicalQuickToolTitle(route, rawTitle);
      byRoute[route] = <String, String>{
        'title': title,
        'subtitle': _toolSubtitle(title, item['subtitle'] ?? ''),
        'route': route,
        'image_url': item['image_url'] ?? '',
      };
    }

    byRoute.putIfAbsent(
      '/tools/quote',
      () => <String, String>{
        'title': 'Quote Creator',
        'subtitle': 'Create shareable quote designs',
        'route': '/tools/quote',
        'image_url': '',
      },
    );

    byRoute.putIfAbsent(
      '/tools/notes',
      () => <String, String>{
        'title': 'Notes',
        'subtitle': 'Write and save personal notes',
        'route': '/tools/notes',
        'image_url': '',
      },
    );

    byRoute.putIfAbsent(
      '/tools/bible',
      () => <String, String>{
        'title': 'Bible',
        'subtitle': 'Read and explore scripture',
        'route': '/tools/bible',
        'image_url': '',
      },
    );

    byRoute.putIfAbsent(
      '/tab/books_reader',
      () => <String, String>{
        'title': 'Books Reader/Library',
        'subtitle': 'Read books and study materials',
        'route': '/tab/books_reader',
        'image_url': '',
      },
    );

    const preferredOrder = <String>[
      '/tools/quote',
      '/tools/notes',
      '/tools/bible',
      '/tab/books_reader',
    ];

    return preferredOrder
        .where((route) => byRoute.containsKey(route))
        .map((route) => byRoute[route]!)
        .toList();
  }

  static String _mapBackendToolRoute(String? route, {String title = ''}) {
    final raw = (route ?? '').trim();
    final lower = raw.toLowerCase();
    final lowerTitle = title.trim().toLowerCase();

    if (lower == '/explore/quotes' ||
        lower == 'quote_creator' ||
        lower == 'quote-creator') {
      return '/tools/quote';
    }

    if (lower == '/explore/notes' || lower == 'notes' || lower == 'notepad') {
      return '/tools/notes';
    }

    if (lower == '/explore/bible' || lower == 'bible') {
      return '/tools/bible';
    }

    if (lower.contains('book') ||
        lower.contains('library') ||
        lowerTitle.contains('book') ||
        lowerTitle.contains('library')) {
      return '/tab/books_reader';
    }

    if (lower == '/games' || lower == '/explore/games') {
      return '/tools';
    }

    return '/tools';
  }

  static String _canonicalQuickToolTitle(String route, String title) {
    final lowerRoute = route.trim().toLowerCase();
    final lowerTitle = title.trim().toLowerCase();

    if (lowerRoute == '/tools/quote' || lowerTitle.contains('quote')) {
      return 'Quote Creator';
    }

    if (lowerRoute == '/tools/notes' || lowerTitle.contains('note')) {
      return 'Notes';
    }

    if (lowerRoute == '/tools/bible' || lowerTitle.contains('bible')) {
      return 'Bible';
    }

    if (lowerRoute == '/tab/books_reader' ||
        lowerTitle.contains('book') ||
        lowerTitle.contains('library')) {
      return 'Books Reader/Library';
    }

    return title.trim().isNotEmpty ? title.trim() : 'Tool';
  }

  static String _toolSubtitle(String title, String rawSubtitle) {
    if (rawSubtitle.trim().isNotEmpty) return rawSubtitle.trim();

    switch (title.trim().toLowerCase()) {
      case 'quote creator':
        return 'Create shareable quote designs';
      case 'notes':
        return 'Write and save personal notes';
      case 'bible':
        return 'Read and explore scripture';
      case 'books reader/library':
      case 'book reader/library':
      case 'book reader':
      case 'books reader':
      case 'library':
        return 'Read books and study materials';
      case 'games':
      case 'game hub':
        return 'Open the games hub and play available games';
      default:
        return 'Open tool';
    }
  }
}

class _HomeHeroCarousel extends StatefulWidget {
  final List<Map<String, String>> slides;

  const _HomeHeroCarousel({required this.slides});

  @override
  State<_HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<_HomeHeroCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  List<Map<String, String>> get _effectiveSlides {
    if (widget.slides.isNotEmpty) return widget.slides;

    return const [
      {
        'title': 'Dunamis TV',
        'subtitle': 'Watch • Read • Be Inspired',
        'image_url': '',
      },
    ];
  }

  String _fallbackAssetFor(int index) {
    const assets = [
      'assets/images/home_1.jpg',
      'assets/images/home_2.jpg',
      'assets/images/home_3.jpg',
      'assets/images/home_4.jpg',
      'assets/images/home_5.jpg',
    ];
    return assets[index % assets.length];
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slides.length != widget.slides.length) {
      _index = 0;
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();

    final count = _effectiveSlides.length;
    if (count <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_index + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _goTo(int next) {
    final count = _effectiveSlides.length;
    if (count == 0) return;

    final safe = (next % count + count) % count;
    _controller.animateToPage(
      safe,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _effectiveSlides;

    return Column(
      children: [
        SizedBox(
          height: 208,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slides.length,
                  onPageChanged: (value) {
                    if (!mounted) return;
                    setState(() => _index = value);
                  },
                  itemBuilder: (context, i) {
                    final slide = slides[i];
                    return _HeroSlideCard(
                      title: slide['title']?.trim().isNotEmpty == true
                          ? slide['title']!
                          : 'Dunamis TV',
                      subtitle: slide['subtitle']?.trim().isNotEmpty == true
                          ? slide['subtitle']!
                          : 'Watch • Read • Be Inspired',
                      imageUrl: slide['image_url'],
                      fallbackAsset: _fallbackAssetFor(i),
                    );
                  },
                ),
              ),
              if (slides.length > 1)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: _HeroArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _goTo(_index - 1),
                  ),
                ),
              if (slides.length > 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: _HeroArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _goTo(_index + 1),
                  ),
                ),
            ],
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 16 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index
                      ? const Color(0xFFFF3CA6)
                      : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroSlideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAsset;

  const _HeroSlideCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _SmartCardImage(
          imageUrl: imageUrl,
          fallbackAsset: fallbackAsset,
          height: 208,
        ),
        Container(
          height: 208,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.14),
                Colors.black.withOpacity(0.28),
                Colors.black.withOpacity(0.82),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.black.withOpacity(0.28),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLight;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isLight ? const Color(0xFF1E1B16) : Colors.white,
            fontSize: 18,
            height: 1.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: isLight
                ? const Color(0xFF6B6256)
                : Colors.white.withOpacity(0.68),
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InnerSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isLight;

  const _InnerSectionLabel({
    required this.title,
    required this.subtitle,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isLight ? const Color(0xFF1E1B16) : Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: isLight
                ? const Color(0xFF6B6256)
                : Colors.white.withOpacity(0.64),
            fontSize: 12,
            height: 1.32,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GroupedSectionShell extends StatelessWidget {
  final Widget child;
  final bool isLight;

  const _GroupedSectionShell({required this.child, required this.isLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(isLight ? 0.08 : 0.12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HomeBannerShortcutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAsset;
  final String badge;
  final VoidCallback onTap;

  const _HomeBannerShortcutCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ImageOverlayCard(
      height: 176,
      imageUrl: imageUrl,
      fallbackAsset: fallbackAsset,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Badge(text: badge),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontSize: 12.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerBroadcastCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAsset;
  final bool enabled;
  final VoidCallback? onTap;

  const _PrayerBroadcastCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: _ImageOverlayCard(
        height: 170,
        imageUrl: imageUrl,
        fallbackAsset: fallbackAsset,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Badge(text: 'PRAYER'),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.82),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBannerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAsset;
  final VoidCallback onTap;

  const _MiniBannerCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth <= 0
            ? 150.0
            : _dxmClampDouble(constraints.maxWidth, 128.0, 210.0);

        final compact = size < 150;

        return _ImageOverlayCard(
          height: size,
          imageUrl: imageUrl,
          fallbackAsset: fallbackAsset,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(compact ? 11 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ToolIconBadge(
                  icon: _toolIconForTitle(title),
                  compact: compact,
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 14 : 15.5,
                    height: 1.06,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  subtitle,
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.84),
                    fontSize: compact ? 10.5 : 11.5,
                    height: 1.14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ToolIconBadge extends StatelessWidget {
  final IconData icon;
  final bool compact;

  const _ToolIconBadge({
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: compact ? 40 : 50,
        height: compact ? 40 : 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.88),
          size: compact ? 22 : 27,
        ),
      ),
    );
  }
}

IconData _toolIconForTitle(String title) {
  final lower = title.trim().toLowerCase();

  if (lower.contains('quote')) return Icons.format_quote_rounded;
  if (lower.contains('note')) return Icons.edit_note_rounded;
  if (lower.contains('bible')) return Icons.menu_book_rounded;
  if (lower.contains('book') || lower.contains('library')) {
    return Icons.library_books_rounded;
  }

  return Icons.grid_view_rounded;
}

class _DailyScripturePremiumCard extends StatelessWidget {
  final String ref;
  final String verse;
  final String note;
  final String? imageUrl;
  final bool useSolidBackground;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final double referenceFontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double overlayStrength;
  final VoidCallback? onShare;
  final VoidCallback? onOpenInQuoteCreator;
  final VoidCallback onReadFullBible;

  const _DailyScripturePremiumCard({
    required this.ref,
    required this.verse,
    required this.note,
    required this.imageUrl,
    required this.useSolidBackground,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.fontSize,
    required this.referenceFontSize,
    required this.fontWeight,
    required this.textAlign,
    required this.overlayStrength,
    required this.onShare,
    required this.onOpenInQuoteCreator,
    required this.onReadFullBible,
  });

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = textColor.withOpacity(0.88);

    return _FeatureHighlightCard(
      imageUrl: imageUrl,
      fallbackAsset: 'assets/images/home_5.jpg',
      minImageHeight: 170,
      useSolidBackground: useSolidBackground,
      backgroundColor: backgroundColor,
      accentColor: accentColor,
      overlayStrength: overlayStrength,
      actions: [
        _ActionButtonConfig(
          icon: Icons.auto_awesome_rounded,
          label: 'Quote Creator',
          onPressed: onOpenInQuoteCreator,
          primary: false,
        ),
        _ActionButtonConfig(
          icon: Icons.menu_book_rounded,
          label: 'Open Bible',
          onPressed: onReadFullBible,
          primary: false,
        ),
        _ActionButtonConfig(
          icon: Icons.share_rounded,
          label: 'Share',
          onPressed: onShare,
          primary: true,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: _crossAxisFromTextAlign(textAlign),
        children: [
          if (verse.trim().isNotEmpty)
            Text(
              verse,
              textAlign: textAlign,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                height: 1.45,
                fontWeight: fontWeight,
              ),
            ),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              note,
              textAlign: textAlign,
              style: TextStyle(
                color: mutedTextColor,
                fontSize: _dxmClampDouble(fontSize * 0.64, 11.0, 18.0),
                height: 1.52,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (ref.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              ref,
              textAlign: textAlign,
              style: TextStyle(
                color: mutedTextColor,
                fontSize: _dxmClampDouble(
                  referenceFontSize,
                  8.0,
                  fontSize * 0.55,
                ),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyScripturePlaceholderCard extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onReadFullBible;

  const _DailyScripturePlaceholderCard({
    required this.imageUrl,
    required this.onReadFullBible,
  });

  @override
  Widget build(BuildContext context) {
    return _FeatureHighlightCard(
      imageUrl: null,
      fallbackAsset: '',
      minImageHeight: 180,
      useSolidBackground: true,
      backgroundColor: const Color(0xFF150A45),
      accentColor: const Color(0xFF22D3EE),
      overlayStrength: 0,
      actions: [
        const _ActionButtonConfig(
          icon: Icons.auto_awesome_rounded,
          label: 'Quote Creator',
          onPressed: null,
          primary: false,
        ),
        _ActionButtonConfig(
          icon: Icons.menu_book_rounded,
          label: 'Open Bible',
          onPressed: onReadFullBible,
          primary: false,
        ),
        const _ActionButtonConfig(
          icon: Icons.share_rounded,
          label: 'Share',
          onPressed: null,
          primary: true,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: Colors.white.withOpacity(0.82),
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Daily Scripture',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyQuotePremiumCard extends StatelessWidget {
  final String quote;
  final String brandText;
  final String? imageUrl;
  final bool useSolidBackground;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double fontSize;
  final double brandFontSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final double overlayStrength;
  final VoidCallback? onShare;
  final VoidCallback? onOpenInQuoteCreator;
  final VoidCallback onAddToNotes;

  const _DailyQuotePremiumCard({
    required this.quote,
    required this.brandText,
    required this.imageUrl,
    required this.useSolidBackground,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.fontSize,
    required this.brandFontSize,
    required this.fontWeight,
    required this.textAlign,
    required this.overlayStrength,
    required this.onShare,
    required this.onOpenInQuoteCreator,
    required this.onAddToNotes,
  });

  @override
  Widget build(BuildContext context) {
    final mutedTextColor = textColor.withOpacity(0.86);

    return _FeatureHighlightCard(
      imageUrl: imageUrl,
      fallbackAsset: 'assets/images/home_5.jpg',
      minImageHeight: 150,
      useSolidBackground: useSolidBackground,
      backgroundColor: backgroundColor,
      accentColor: accentColor,
      overlayStrength: overlayStrength,
      actions: [
        _ActionButtonConfig(
          icon: Icons.auto_awesome_rounded,
          label: 'Quote Creator',
          onPressed: onOpenInQuoteCreator,
          primary: false,
        ),
        _ActionButtonConfig(
          icon: Icons.note_add_rounded,
          label: 'Add to Notes',
          onPressed: onAddToNotes,
          primary: false,
        ),
        _ActionButtonConfig(
          icon: Icons.share_rounded,
          label: 'Share',
          onPressed: onShare,
          primary: true,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: _crossAxisFromTextAlign(textAlign),
        children: [
          if (quote.trim().isNotEmpty)
            Text(
              quote,
              textAlign: textAlign,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                height: 1.38,
                fontWeight: fontWeight,
              ),
            ),
          if (brandText.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              brandText,
              textAlign: textAlign,
              style: TextStyle(
                color: mutedTextColor,
                fontSize: _dxmClampDouble(brandFontSize, 9.0, fontSize * 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyQuotePlaceholderCard extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onOpenInQuoteCreator;
  final VoidCallback onAddToNotes;

  const _DailyQuotePlaceholderCard({
    required this.imageUrl,
    required this.onOpenInQuoteCreator,
    required this.onAddToNotes,
  });

  @override
  Widget build(BuildContext context) {
    return _FeatureHighlightCard(
      imageUrl: null,
      fallbackAsset: '',
      minImageHeight: 180,
      useSolidBackground: true,
      backgroundColor: const Color(0xFF270A4B),
      accentColor: const Color(0xFFFF3CA6),
      overlayStrength: 0,
      actions: [
        _ActionButtonConfig(
          icon: Icons.auto_awesome_rounded,
          label: 'Quote Creator',
          onPressed: onOpenInQuoteCreator,
          primary: false,
        ),
        _ActionButtonConfig(
          icon: Icons.note_add_rounded,
          label: 'Add to Notes',
          onPressed: onAddToNotes,
          primary: false,
        ),
        const _ActionButtonConfig(
          icon: Icons.share_rounded,
          label: 'Share',
          onPressed: null,
          primary: true,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: Colors.white.withOpacity(0.82),
            size: 44,
          ),
          const SizedBox(height: 12),
          const Text(
            'Daily Quote',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonConfig {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  const _ActionButtonConfig({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.primary,
  });
}

class _FeatureHighlightCard extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final double minImageHeight;
  final Widget child;
  final List<_ActionButtonConfig> actions;
  final bool useSolidBackground;
  final Color backgroundColor;
  final Color accentColor;
  final double overlayStrength;

  const _FeatureHighlightCard({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.minImageHeight,
    required this.child,
    required this.actions,
    this.useSolidBackground = false,
    this.backgroundColor = const Color(0xFF090F28),
    this.accentColor = const Color(0xFFEC4899),
    this.overlayStrength = 0.72,
  });

  @override
  Widget build(BuildContext context) {
    final safeOverlay = _dxmClampDouble(overlayStrength, 0.0, 1.0);
    final cardColor =
        useSolidBackground ? backgroundColor : const Color(0xFF090F28);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (useSolidBackground ? accentColor : Colors.white).withOpacity(
            useSolidBackground ? 0.50 : 0.08,
          ),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Positioned.fill(
                  child: useSolidBackground
                      ? DecoratedBox(
                          decoration: BoxDecoration(color: backgroundColor),
                        )
                      : _FillSmartCardImage(
                          imageUrl: imageUrl,
                          fallbackAsset: fallbackAsset,
                        ),
                ),
                if (safeOverlay > 0)
                  Positioned.fill(
                    child: useSolidBackground
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(
                                _dxmClampDouble(safeOverlay * 0.35, 0.0, 0.35),
                              ),
                            ),
                          )
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.10 * safeOverlay),
                                  Colors.black.withOpacity(0.20 * safeOverlay),
                                  Colors.black.withOpacity(0.72 * safeOverlay),
                                ],
                                stops: const [0.0, 0.42, 1.0],
                              ),
                            ),
                          ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: minImageHeight,
                    minWidth: double.infinity,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF090F28),
                border: Border(
                  top: BorderSide(
                    color: (useSolidBackground ? accentColor : Colors.white)
                        .withOpacity(useSolidBackground ? 0.35 : 0.08),
                  ),
                ),
              ),
              child: Row(
                children: List.generate(actions.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    return const SizedBox(width: 10);
                  }

                  final item = actions[index ~/ 2];
                  return Expanded(
                    child: item.primary
                        ? _PrimaryActionButton(
                            icon: item.icon,
                            label: item.label,
                            onPressed: item.onPressed,
                          )
                        : _GlassActionButton(
                            icon: item.icon,
                            label: item.label,
                            onPressed: item.onPressed,
                          ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageOverlayCard extends StatelessWidget {
  final double height;
  final String? imageUrl;
  final String fallbackAsset;
  final Widget child;
  final VoidCallback? onTap;

  const _ImageOverlayCard({
    required this.height,
    required this.imageUrl,
    required this.fallbackAsset,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          _SmartCardImage(
            imageUrl: imageUrl,
            fallbackAsset: fallbackAsset,
            height: height,
          ),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.12),
                  Colors.black.withOpacity(0.26),
                  Colors.black.withOpacity(0.78),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SizedBox(height: height, width: double.infinity, child: child),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.18),
              ),
            ],
          ),
          child: card,
        ),
      ),
    );
  }
}

class _SmartCardImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final double height;

  const _SmartCardImage({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.height,
  });

  bool get _hasRemoteImage {
    final raw = (imageUrl ?? '').trim();
    if (raw.isEmpty) return false;

    final uri = Uri.tryParse(raw);
    if (uri == null) return false;
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) return false;
    if ((uri.host).trim().isEmpty) return false;
    if (uri.host.contains('your-real-')) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl!.trim(),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _DxmGradientBackdrop(height: height),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _DxmGradientBackdrop(
            height: height,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
      );
    }

    return _DxmGradientBackdrop(height: height);
  }
}

class _FillSmartCardImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;

  const _FillSmartCardImage({
    required this.imageUrl,
    required this.fallbackAsset,
  });

  bool get _hasRemoteImage {
    final raw = (imageUrl ?? '').trim();
    if (raw.isEmpty) return false;

    final uri = Uri.tryParse(raw);
    if (uri == null) return false;
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) return false;
    if ((uri.host).trim().isEmpty) return false;
    if (uri.host.contains('your-real-')) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl!.trim(),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _DxmGradientBackdrop(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const _DxmGradientBackdrop(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
      );
    }

    return const _DxmGradientBackdrop();
  }
}

class _DxmGradientBackdrop extends StatelessWidget {
  final double? height;
  final Widget? child;

  const _DxmGradientBackdrop({this.height, this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = ThemeController.instance.isLightMode;

    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? const [
                  Color(0xFFFFF7ED),
                  Color(0xFFEDE9FE),
                  Color(0xFFFCE7F3),
                ]
              : const [
                  Color(0xFF0A1028),
                  Color(0xFF31106B),
                  Color(0xFFB10072),
                ],
        ),
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _GlassActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.34)),
        backgroundColor: Colors.white.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF141225),
        disabledBackgroundColor: Colors.white.withOpacity(0.55),
        disabledForegroundColor: const Color(0xFF141225).withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
      ),
    );
  }
}
