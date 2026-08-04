import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../features/hub/state/hub_scope.dart';
import '../../../theme/theme_controller.dart';
import '../../../services/ads_service.dart';
import '../../shared/designers/dxm_design_parser.dart';
import '../../shared/designers/dxm_dynamic_quote_card.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class SodQuotesScreen extends StatelessWidget {
  const SodQuotesScreen({super.key});

  static const String pageKey = 'inspire.sod.quotes';

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        AdsService.instance.policyRevision,
        if (store != null) store,
      ]),
      builder: (context, _) {
        final hubMap = store?.raw ?? const <String, dynamic>{};
        final inspire = _asMap(hubMap['inspire']) ?? const <String, dynamic>{};
        final quotes = _extractQuotes(inspire);
        final sortedQuotes = [...quotes]..sort((a, b) {
            final aDate = _parseDate(_firstString(a, const [
              'published_at',
              'created_at',
              'date',
              'updated_at',
            ]));
            final bDate = _parseDate(_firstString(b, const [
              'published_at',
              'created_at',
              'date',
              'updated_at',
            ]));
            if (aDate == null && bDate == null) return 0;
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return bDate.compareTo(aDate);
          });

        final listEntries =
            NativeListInjection.buildEntries<Map<String, dynamic>>(
          sortedQuotes,
          tabKey: pageKey,
        );
        final colors = _SodQuoteColors.fromBrightness(
          ThemeController.instance.isLightMode,
        );

        return Scaffold(
          backgroundColor: colors.scaffold,
          bottomNavigationBar: const SafeArea(
            top: false,
            child: BannerAdWidget(
              tabKey: pageKey,
              padding: EdgeInsets.fromLTRB(12, 8, 12, 10),
            ),
          ),
          body: Column(
            children: [
              DxmTopBar(
                title: 'SOD Quotes',
                showBack: true,
                showMenu: true,
                onBack: () => Navigator.pop(context),
                onRefresh: () => store?.refresh(),
              ),
              Expanded(
                child: GradientPageBackground(
                  child: sortedQuotes.isEmpty
                      ? _EmptyCard(colors: colors)
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    '/quotes-scripture/library?category=sod_quotes',
                                  ),
                                  icon: const Icon(Icons.library_books_rounded),
                                  label: const Text('Browse Library'),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 14, 14, 92),
                                itemCount: listEntries.length,
                                itemBuilder: (context, i) {
                                  final entry = listEntries[i];
                                  if (entry.isAd) {
                                    return const Padding(
                                      padding: EdgeInsets.only(bottom: 14),
                                      child: NativeInlineAdTile(
                                        label: 'Sponsored',
                                        minHeight: 120,
                                      ),
                                    );
                                  }

                                  final quote =
                                      _SodQuotePayload.fromMap(entry.item!);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _DesignedSodQuoteCard(
                                      quote: quote,
                                      colors: colors,
                                      onCopy: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: quote.shareText),
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Quote copied'),
                                            ),
                                          );
                                        }
                                      },
                                      onOpenInQuoteCreator: () {
                                        context.push(
                                          '/tools/quote',
                                          extra: {
                                            'designData':
                                                quote.toQuotePayload(),
                                          },
                                        );
                                      },
                                      onAddToNotes: () {
                                        context.push(
                                          '/tools/notes/editor',
                                          extra: {
                                            'title': quote.title.isNotEmpty
                                                ? quote.title
                                                : 'SOD Quote',
                                            'prefill': quote.noteText,
                                            'sourceType': 'sod_quotes',
                                            'sourceId': quote.id,
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static List<Map<String, dynamic>> _extractQuotes(
      Map<String, dynamic> inspire) {
    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addQuoteMap(Map<String, dynamic> item) {
      final normalized = Map<String, dynamic>.from(item);
      final quote = _firstString(normalized, const [
        'quote_text',
        'quote',
        'text',
        'body',
        'content',
        'message',
        'excerpt',
        'subtitle',
      ]).trim();

      final payload = _asMap(normalized['payload']);
      final meta = _asMap(normalized['meta']);
      final isQuoteCard = normalized['type'] == 'quote_card' ||
          normalized['type'] == 'quote' ||
          payload?['designer_type'] == 'quote_card' ||
          payload?['screen'] == 'quote_card' ||
          meta?['designer_type'] == 'quote_card';

      if (quote.isEmpty && !isQuoteCard) return;

      final title =
          _firstString(normalized, const ['title', 'name', 'headline']);
      final route = _firstString(normalized, const [
        'route',
        'path',
        'href',
        'url',
        'link',
      ]).toLowerCase();
      final joined = '$title $quote $route'.toLowerCase();

      if (joined.contains('read sod') ||
          joined.contains('watch sod') ||
          joined.contains('read seed') ||
          joined.contains('watch seed') ||
          joined.contains('youtube.com') ||
          joined.contains('youtu.be') ||
          joined.contains('dunamisgospel.org/category/seed-of-destiny')) {
        return;
      }

      final id = _firstString(normalized, const ['id', 'slug']).trim();
      final signature =
          id.isNotEmpty ? id : '${title.toLowerCase()}|${quote.toLowerCase()}';
      if (seen.contains(signature)) return;
      seen.add(signature);
      out.add(normalized);
    }

    void scanRaw(dynamic raw) {
      if (raw == null) return;
      if (raw is List) {
        for (final item in raw) {
          scanRaw(item);
        }
        return;
      }

      final map = _asMap(raw);
      if (map == null || map.isEmpty) return;

      final nestedCandidates = <dynamic>[
        map['quotes'],
        map['items'],
        map['data'],
        map['records'],
        map['posts'],
        map['contents'],
        map['content'],
      ];

      var scannedNested = false;
      for (final candidate in nestedCandidates) {
        if (candidate is List && candidate.isNotEmpty) {
          scannedNested = true;
          scanRaw(candidate);
        }
      }

      if (!scannedNested) addQuoteMap(map);
    }

    scanRaw(inspire['sod_quotes']);
    scanRaw(inspire['sod']);
    scanRaw(inspire['seed_of_destiny_quotes']);
    scanRaw(inspire['seed_of_destiny']);
    scanRaw(inspire['quotes']);

    void scanSections(dynamic rawSections) {
      if (rawSections is! List) return;

      for (final raw in rawSections) {
        final section = _asMap(raw);
        if (section == null) continue;

        final key = _firstString(section, const [
          'key',
          'bucket',
          'route_key',
          'slug',
          'title',
          'name',
        ]).toLowerCase();
        final route = _firstString(section, const ['route', 'path', 'href'])
            .toLowerCase();
        final looksLikeSodQuoteSection =
            (key.contains('sod') || key.contains('seed')) &&
                (key.contains('quote') || route.contains('quote'));
        if (!looksLikeSodQuoteSection) continue;

        scanRaw(section['quotes']);
        scanRaw(section['items']);
        scanRaw(section['data']);
      }
    }

    scanSections(inspire['sections']);
    scanSections(inspire['hub_cards']);
    scanSections(inspire['cards']);

    return out;
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }

    for (final nestedKey in const [
      'payload',
      'quote_card',
      'design',
      'render_style',
      'style',
      'meta',
      'cover',
      'media',
    ]) {
      final nested = _asMap(map[nestedKey]);
      if (nested == null) continue;
      final value = _firstStringFlat(nested, keys);
      if (value.isNotEmpty) return value;

      for (final childKey in const [
        'quote_card',
        'design',
        'layout',
        'typography',
        'colors'
      ]) {
        final child = _asMap(nested[childKey]);
        if (child == null) continue;
        final childValue = _firstStringFlat(child, keys);
        if (childValue.isNotEmpty) return childValue;
      }
    }

    return '';
  }

  static String _firstStringFlat(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _formatPublishedDate(String raw) {
    final parsed = _parseDate(raw);
    if (parsed == null) return '';
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((key, value) => MapEntry('$key', value));
    return null;
  }
}

class _DesignedSodQuoteCard extends StatefulWidget {
  final _SodQuotePayload quote;
  final _SodQuoteColors colors;
  final VoidCallback onCopy;
  final VoidCallback onOpenInQuoteCreator;
  final VoidCallback onAddToNotes;

  const _DesignedSodQuoteCard({
    required this.quote,
    required this.colors,
    required this.onCopy,
    required this.onOpenInQuoteCreator,
    required this.onAddToNotes,
  });

  @override
  State<_DesignedSodQuoteCard> createState() => _DesignedSodQuoteCardState();
}

class _DesignedSodQuoteCardState extends State<_DesignedSodQuoteCard> {
  final GlobalKey _canvasKey = GlobalKey();
  bool _isSharing = false;

  _SodQuotePayload get quote => widget.quote;
  _SodQuoteColors get colors => widget.colors;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - 28).clamp(278.0, 318.0).toDouble();

    return Center(
      child: SizedBox(
        width: cardWidth,
        child: DxmDynamicQuoteCard(
          mainText: quote.text,
          supportText: quote.source,
          design: quote.design,
          margin: EdgeInsets.zero,
          showActionsBar: true,
          canvasKey: _canvasKey,
          maxPreviewWidth: cardWidth,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          actions: [
            Expanded(
              child: _InlineQuoteActionButton(
                icon: Icons.auto_awesome_rounded,
                label: 'Quote',
                onPressed: widget.onOpenInQuoteCreator,
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InlineQuoteActionButton(
                icon: Icons.note_add_rounded,
                label: 'Add',
                onPressed: widget.onAddToNotes,
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InlineQuoteActionButton(
                icon: _isSharing
                    ? Icons.hourglass_top_rounded
                    : Icons.share_rounded,
                label: _isSharing ? 'Wait' : 'Share',
                onPressed: _isSharing ? null : _shareRenderedDesign,
                colors: colors,
                primary: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareRenderedDesign() async {
    setState(() => _isSharing = true);

    try {
      await AdsService.instance.maybeShowInterstitialOnSafeNav(
        context,
        tabKey: 'inspire.action.sod_quotes.share',
      );
      if (!mounted) return;

      final bytes = await _renderDesignToPng();
      final fileName = 'sod_quote_${DateTime.now().millisecondsSinceEpoch}.png';

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        text: 'Seeds of Destiny Quote',
        subject: 'Seeds of Destiny Quote',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share design image')),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<Uint8List> _renderDesignToPng() async {
    await WidgetsBinding.instance.endOfFrame;

    final boundaryContext = _canvasKey.currentContext;
    if (boundaryContext == null) {
      throw Exception('Quote design is not ready yet.');
    }

    final renderObject = boundaryContext.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception('Quote design boundary is unavailable.');
    }

    final pixelRatio =
        MediaQuery.of(context).devicePixelRatio.clamp(2.0, 4.0).toDouble();
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Unable to render quote design.');
    }

    return byteData.buffer.asUint8List();
  }
}

class _InlineQuoteActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final _SodQuoteColors colors;
  final bool primary;

  const _InlineQuoteActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.colors,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? Colors.white : Colors.white.withOpacity(0.06);
    final fg = primary ? const Color(0xFF101528) : Colors.white;
    final border = primary ? Colors.white : colors.actionText.withOpacity(0.22);

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withOpacity(0.55),
        disabledForegroundColor: fg.withOpacity(0.55),
        side: BorderSide(color: border.withOpacity(0.78)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SodQuotePayload {
  final String id;
  final String title;
  final String text;
  final String source;
  final String publishedLabel;
  final String formatLabel;
  final DxmDesignData design;

  const _SodQuotePayload({
    required this.id,
    required this.title,
    required this.text,
    required this.source,
    required this.publishedLabel,
    required this.formatLabel,
    required this.design,
  });

  factory _SodQuotePayload.fromMap(Map<String, dynamic> item) {
    final text = SodQuotesScreen._firstString(item, const [
      'quote_text',
      'quote',
      'text',
      'body',
      'content',
      'message',
    ]).trim();
    final source = SodQuotesScreen._firstString(item, const [
      'quote_source',
      'source',
      'author',
      'author_name',
      'credit',
      'subtitle',
    ]).trim();
    final imageUrl = _pickImage(item);

    return _SodQuotePayload(
      id: SodQuotesScreen._firstString(item, const ['id', 'slug']).trim(),
      title: SodQuotesScreen._firstString(item, const [
        'title',
        'name',
        'headline',
      ]).trim(),
      text: text.isNotEmpty ? text : 'Quote',
      source: source,
      publishedLabel: SodQuotesScreen._formatPublishedDate(
        SodQuotesScreen._firstString(item, const [
          'published_at',
          'created_at',
          'date',
          'updated_at',
        ]),
      ),
      formatLabel: SodQuotesScreen._firstString(item, const [
        'format_label',
        'card_format_label',
      ]).trim().isNotEmpty
          ? SodQuotesScreen._firstString(item, const [
              'format_label',
              'card_format_label',
            ]).trim()
          : _formatLabelFor(SodQuotesScreen._firstString(item, const [
              'card_format',
              'format',
            ])),
      design: DxmDesignData.fromMap(
        item,
        imageUrl: imageUrl,
        fallbackMainFontSize: 23,
        fallbackSupportFontSize: 12,
      ),
    );
  }

  String get shareText => source.isEmpty ? '“$text”' : '“$text” — $source';
  String get noteText => source.isEmpty ? '“$text”' : '“$text”\n\n$source';

  Map<String, dynamic> toQuotePayload() {
    return {
      'quote': text,
      'author': source,
      'source_type': 'sod_quotes',
      'source_id': id,
      'fontSize': design.mainFontSize,
      'authorFontSize': design.supportFontSize,
      'textColor': design.textColor.value,
      'authorColor': design.sourceColor.value,
      'backgroundColor': design.backgroundColor.value,
      'gradient': [design.backgroundColor.value, design.backgroundColor2.value],
      'backgroundImage':
          design.imageUrl.trim().isEmpty ? null : design.imageUrl.trim(),
      'overlayStrength': design.overlayStrength,
      'textAlign': design.textAlign.name,
      'showWatermark': true,
      'cardFormat': design.cardFormat,
      'formatRatio': design.aspectRatio,
      'lineHeight': design.lineHeight,
      'contentWidth': design.contentWidthPercent,
      'cardPadding': design.cardPadding,
      'cardPaddingX': design.cardPaddingX,
      'cardPaddingY': design.cardPaddingY,
      'showQuoteMark': design.showQuoteMark,
      'fontFamily': design.fontFamily,
      'fontWeight': design.fontWeight.value,
    };
  }

  static String _pickImage(Map<String, dynamic> item) {
    const keys = [
      'background_image_url',
      'image_url',
      'card_image_url',
      'background_image',
      'cover_image_url',
      'cover_image',
      'cover_url',
      'banner_url',
      'featured_image',
      'thumbnail_url',
      'thumbnail',
      'image',
      'imageUrl',
      'poster',
      'photo',
      'cover_asset_url',
    ];

    String fromMap(Map<String, dynamic>? source) {
      if (source == null) return '';
      for (final key in keys) {
        final value = source[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      for (final childKey in const [
        'payload',
        'quote_card',
        'cover',
        'media',
        'meta'
      ]) {
        final child = SodQuotesScreen._asMap(source[childKey]);
        final found = fromMap(child);
        if (found.isNotEmpty) return found;
      }
      return '';
    }

    return fromMap(item);
  }

  static String _formatLabelFor(String cardFormat) {
    switch (cardFormat.trim().toLowerCase()) {
      case 'square':
      case '1:1':
        return 'Square 1:1';
      case 'story':
      case '9:16':
        return 'Story 9:16';
      case 'wide':
      case '16:9':
        return 'Wide 16:9';
      case 'cinematic':
      case '21:9':
        return 'Cinematic 21:9';
      case 'classic':
      case '3:4':
        return 'Classic 3:4';
      case 'portrait':
      case '4:5':
      default:
        return 'Portrait 4:5';
    }
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _SodQuoteColors colors;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.actionBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.actionText, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors.actionText,
                  fontSize: 12.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final _SodQuoteColors colors;

  const _EmptyCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.cardBorder),
            color: colors.cardBg,
            boxShadow: colors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)],
                  ),
                ),
                child: const Icon(Icons.format_quote, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AppsHub will publish backend-designed Seed of Destiny quotes here.',
                  style: TextStyle(
                    color: colors.meta,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SodQuoteColors {
  final Color scaffold;
  final Color cardBg;
  final Color actionPanelBg;
  final Color cardBorder;
  final List<BoxShadow>? cardShadow;
  final Color meta;
  final Color badgeBg;
  final Color badgeBorder;
  final Color badgeText;
  final Color actionBg;
  final Color actionText;

  const _SodQuoteColors({
    required this.scaffold,
    required this.cardBg,
    required this.actionPanelBg,
    required this.cardBorder,
    required this.cardShadow,
    required this.meta,
    required this.badgeBg,
    required this.badgeBorder,
    required this.badgeText,
    required this.actionBg,
    required this.actionText,
  });

  factory _SodQuoteColors.fromBrightness(bool isLight) {
    if (isLight) {
      return _SodQuoteColors(
        scaffold: const Color(0xFFF6F7FB),
        cardBg: Colors.white.withOpacity(0.95),
        actionPanelBg: const Color(0xFF090F28),
        cardBorder: const Color(0xFFE6E8F0),
        cardShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        meta: Colors.white.withOpacity(0.82),
        badgeBg: Colors.white.withOpacity(0.08),
        badgeBorder: Colors.white.withOpacity(0.12),
        badgeText: Colors.white,
        actionBg: Colors.white.withOpacity(0.07),
        actionText: Colors.white,
      );
    }

    return _SodQuoteColors(
      scaffold: const Color(0xFF0B1020),
      cardBg: const Color(0xFF0D1228),
      actionPanelBg: const Color(0xFF090F28),
      cardBorder: Colors.white.withOpacity(0.08),
      cardShadow: null,
      meta: Colors.white.withOpacity(0.74),
      badgeBg: Colors.white.withOpacity(0.05),
      badgeBorder: Colors.white.withOpacity(0.08),
      badgeText: Colors.white,
      actionBg: Colors.white.withOpacity(0.05),
      actionText: Colors.white,
    );
  }
}
