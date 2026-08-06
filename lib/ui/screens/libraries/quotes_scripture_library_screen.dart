import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/hub/state/hub_scope.dart';
import '../../shared/designers/dxm_design_parser.dart';
import '../../shared/designers/dxm_dynamic_quote_card.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class QuotesScriptureLibraryScreen extends StatefulWidget {
  final String initialCategory;

  const QuotesScriptureLibraryScreen({
    super.key,
    this.initialCategory = '',
  });

  @override
  State<QuotesScriptureLibraryScreen> createState() =>
      _QuotesScriptureLibraryScreenState();
}

class _QuotesScriptureLibraryScreenState
    extends State<QuotesScriptureLibraryScreen> {
  String _category = '';
  int _visibleCount = 30;
  Map<String, dynamic>? _cachedRaw;
  List<QuoteScriptureLibraryItem> _cachedItems = const [];

  @override
  void initState() {
    super.initState();
    _category = _normalize(widget.initialCategory);
  }

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);

    return AnimatedBuilder(
      animation: store ?? _NoopListenable(),
      builder: (context, _) {
        final raw = store?.raw ?? const <String, dynamic>{};
        if (!identical(raw, _cachedRaw)) {
          _cachedRaw = raw;
          _cachedItems = QuoteScriptureLibraryMapper.fromRawHub(raw);
        }
        final allItems = _cachedItems;
        final categories = QuoteScriptureLibraryMapper.categories(allItems);
        final filtered = _category.isEmpty
            ? allItems
            : allItems
                .where((item) => _normalize(item.categoryKey) == _category)
                .toList();
        final visible = filtered.take(_visibleCount).toList();
        final entries = NativeListInjection.buildEntries(
          visible,
          tabKey: 'quotes.library',
        );

        return Scaffold(
          body: Column(
            children: [
              DxmTopBar(
                title: 'Quotes & Scripture',
                showBack: true,
                showMenu: true,
                onBack: () => context.pop(),
                onRefresh: () => store?.refresh(),
              ),
              Expanded(
                child: GradientPageBackground(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _category.isEmpty,
                                  onSelected: (_) => setState(() {
                                    _category = '';
                                    _visibleCount = 30;
                                  }),
                                ),
                                const SizedBox(width: 8),
                                for (final entry in categories.entries) ...[
                                  ChoiceChip(
                                    label: Text(entry.value),
                                    selected: _category == entry.key,
                                    onSelected: (_) => setState(() {
                                      _category = entry.key;
                                      _visibleCount = 30;
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (visible.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No quotes or Scriptures are available in this category yet.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverList.builder(
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            if (entry.isAd) {
                              return Padding(
                                key: ValueKey(
                                  'quotes.library.native.${entry.itemIndex}',
                                ),
                                padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                                child: NativeInlineAdTile(
                                  tabKey: 'quotes.library',
                                  label: 'Sponsored',
                                  minHeight: 150,
                                ),
                              );
                            }
                            final item = entry.item!;
                            return Padding(
                              key: ValueKey('quote.${item.id}'),
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                              child: _QuoteCard(
                                item: item,
                                onTap: () => context.push(
                                  '/quotes-scripture/reader',
                                  extra: {
                                    'items': filtered,
                                    'initialId': item.id,
                                    'category': _category,
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      if (_visibleCount < filtered.length)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
                            child: FilledButton.icon(
                              onPressed: () => setState(() {
                                _visibleCount += 30;
                              }),
                              icon: const Icon(Icons.expand_more_rounded),
                              label: const Text('Load more'),
                            ),
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

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class QuoteScriptureReaderScreen extends StatefulWidget {
  final List<QuoteScriptureLibraryItem> items;
  final String initialId;

  const QuoteScriptureReaderScreen({
    super.key,
    required this.items,
    this.initialId = '',
  });

  @override
  State<QuoteScriptureReaderScreen> createState() =>
      _QuoteScriptureReaderScreenState();
}

class _QuoteScriptureReaderScreenState
    extends State<QuoteScriptureReaderScreen> {
  late final PageController _controller;
  late final List<NativeListEntry<QuoteScriptureLibraryItem>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = NativeListInjection.buildEntries(
      widget.items,
      tabKey: 'quotes.library.reader',
    );
    final contentIndex =
        widget.items.indexWhere((item) => item.id == widget.initialId);
    final safeIndex = contentIndex < 0 ? 0 : contentIndex;
    final pageIndex = _entries.indexWhere(
      (entry) => !entry.isAd && entry.itemIndex == safeIndex,
    );
    _controller = PageController(initialPage: pageIndex < 0 ? 0 : pageIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090713),
      body: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: _entries.length,
        itemBuilder: (context, pageIndex) {
          final entry = _entries[pageIndex];
          if (entry.isAd) {
            return ColoredBox(
              key: ValueKey(
                'quotes.library.reader.native.${entry.itemIndex}',
              ),
              color: Color(0xFF07070A),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.campaign_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sponsored',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Expanded(
                        child: NativeInlineAdTile(
                          tabKey: 'quotes.library.reader',
                          label: 'Sponsored',
                          minHeight: 620,
                          margin: EdgeInsets.zero,
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Swipe to continue',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final item = entry.item!;
          return SafeArea(
            key: ValueKey('quote.reader.${item.id}'),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 90, 24, 90),
                    child: QuoteScripturePresentation(
                      item: item,
                      minHeight: 420,
                      allowVerticalScroll: true,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: IconButton.filledTonal(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton.filledTonal(
                    tooltip: 'Browse library',
                    onPressed: () => context.push('/quotes-scripture/library'),
                    icon: const Icon(Icons.library_books_rounded),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final QuoteScriptureLibraryItem item;
  final VoidCallback onTap;

  const _QuoteCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (item.design != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: IgnorePointer(
          child: QuoteScripturePresentation(item: item, minHeight: 220),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.categoryLabel,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.text,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, height: 1.45),
              ),
              if (item.attribution.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.attribution,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class QuoteScriptureLibraryItem {
  final String id;
  final String categoryKey;
  final String categoryLabel;
  final String text;
  final String attribution;
  final Map<String, dynamic> raw;
  final int channelOrder;

  const QuoteScriptureLibraryItem({
    required this.id,
    required this.categoryKey,
    required this.categoryLabel,
    required this.text,
    required this.attribution,
    required this.raw,
    this.channelOrder = 0,
  });

  DxmDesignData? get design => QuoteScriptureDesign.resolve(raw);
}

class QuoteScriptureDesign {
  const QuoteScriptureDesign._();

  static const _signals = <String>{
    'design',
    'design_json',
    'style',
    'background_mode',
    'background_color',
    'background_image_url',
    'gradient',
    'font_family',
    'font_size',
    'text_color',
    'text_align',
    'card_format',
    'aspect_ratio',
    'overlay_style',
  };

  static DxmDesignData? resolve(Map<String, dynamic> raw) {
    if (!_containsDesign(raw)) return null;
    try {
      final normalized = Map<String, dynamic>.from(raw);
      for (final key in const ['design', 'design_json', 'style']) {
        final value = normalized[key];
        if (value == null || value is Map) continue;
        if (value is! String || value.trim().isEmpty) return null;
        final decoded = jsonDecode(value);
        if (decoded is! Map) return null;
        normalized[key == 'design_json' ? 'design' : key] =
            decoded.map((key, value) => MapEntry(key.toString(), value));
      }
      return DxmDesignData.fromMap(normalized);
    } catch (_) {
      return null;
    }
  }

  static bool _containsDesign(dynamic value) {
    if (value is! Map) return false;
    for (final entry in value.entries) {
      final key = entry.key.toString().trim().toLowerCase();
      if (_signals.contains(key)) return true;
      if (entry.value is Map && _containsDesign(entry.value)) return true;
    }
    return false;
  }
}

class QuoteScripturePresentation extends StatelessWidget {
  final QuoteScriptureLibraryItem item;
  final double minHeight;
  final bool allowVerticalScroll;

  const QuoteScripturePresentation({
    super.key,
    required this.item,
    required this.minHeight,
    this.allowVerticalScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    final design = item.design;
    final Widget presentation;
    if (design == null) {
      presentation = Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.text, textAlign: TextAlign.center),
              if (item.attribution.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(item.attribution, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      );
    } else {
      presentation = LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final width = availableWidth.clamp(1.0, 720.0).toDouble();
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              child: DxmDynamicQuoteCard(
                mainText: item.text,
                referenceText: item.attribution,
                design: design,
                minHeight: minHeight,
                enableTapPreview: false,
              ),
            ),
          );
        },
      );
    }
    if (!allowVerticalScroll) return presentation;
    return SingleChildScrollView(
      primary: false,
      child: presentation,
    );
  }
}

class QuoteScriptureLibraryMapper {
  const QuoteScriptureLibraryMapper._();

  static List<QuoteScriptureLibraryItem> fromRawHub(
    Map<String, dynamic> rawHub,
  ) {
    final out = <QuoteScriptureLibraryItem>[];
    final seen = <String>{};

    void scan(
      dynamic value, {
      String path = '',
      _Category? inheritedCategory,
      int inheritedOrder = 0,
    }) {
      if (value is List) {
        for (final item in value) {
          scan(
            item,
            path: path,
            inheritedCategory: inheritedCategory,
            inheritedOrder: inheritedOrder,
          );
        }
        return;
      }
      if (value is! Map) return;
      final map = value.map((key, value) => MapEntry(key.toString(), value));
      final joined = '${map['bucket']} ${map['type']} ${map['key']} '
              '${map['title']} $path'
          .toLowerCase();
      final text = _first(map, const [
        'quote_text',
        'scripture_text',
        'verse_text',
        'quote',
        'text',
        'content',
        'body',
        'message',
        'excerpt',
      ]);
      final looksRelevant = joined.contains('quote') ||
          joined.contains('scripture') ||
          joined.contains('verse') ||
          joined.contains('motivation');
      final explicitlyQuote = _hasStructuredQuoteIdentity(map);
      final acceptedAsQuote =
          looksRelevant || explicitlyQuote || inheritedCategory != null;
      final containerCategory = map['items'] is List && acceptedAsQuote
          ? _category(map, joined, path, inheritedCategory)
          : inheritedCategory;
      final containerOrder = map['items'] is List
          ? _int(map, const [
              'channel_order',
              'channelOrder',
              'display_order',
              'order',
            ])
          : inheritedOrder;
      if (acceptedAsQuote && text.trim().length >= 12) {
        final category = _category(map, joined, path, inheritedCategory);
        final id =
            _first(map, const ['id', 'content_id', 'post_id', 'slug', 'key']);
        final signature =
            '${category.key}|${id.isEmpty ? text : id}'.toLowerCase();
        if (seen.add(signature)) {
          out.add(QuoteScriptureLibraryItem(
            id: id.isEmpty ? signature.hashCode.toString() : id,
            categoryKey: category.key,
            categoryLabel: category.label,
            text: _stripHtml(text),
            attribution: _first(map, const [
              'reference',
              'scripture_reference',
              'author',
              'author_name',
              'subtitle',
            ]),
            raw: Map<String, dynamic>.from(map),
            channelOrder: _int(
                map,
                const [
                  'channel_order',
                  'channelOrder',
                  'display_order',
                  'order',
                ],
                fallback: inheritedOrder),
          ));
        }
      }
      for (final entry in map.entries) {
        if (entry.value is Map || entry.value is List) {
          scan(
            entry.value,
            path: '$path ${entry.key}',
            inheritedCategory: containerCategory,
            inheritedOrder: containerOrder,
          );
        }
      }
    }

    scan(rawHub);
    out.sort((a, b) {
      final byChannel = a.channelOrder.compareTo(b.channelOrder);
      return byChannel != 0 ? byChannel : 0;
    });
    return out;
  }

  static Map<String, String> categories(
    List<QuoteScriptureLibraryItem> items,
  ) {
    final out = <String, String>{};
    for (final item in items) {
      out[item.categoryKey] = item.categoryLabel;
    }
    return out;
  }

  static _Category _category(
    Map<String, dynamic> map,
    String joined,
    String path,
    _Category? inherited,
  ) {
    final explicitKey = _first(map, const [
      'channel_key',
      'channelKey',
      'source_channel',
      'sourceChannel',
      'category_key',
      'categoryKey',
    ]);
    final explicitLabel = _first(map, const [
      'channel_title',
      'channelTitle',
      'channel_label',
      'channelLabel',
      'category_label',
      'categoryLabel',
      'category',
    ]);
    if (explicitKey.isNotEmpty) {
      final key = normalizeChannelKey(explicitKey);
      return _Category(
          key, explicitLabel.isNotEmpty ? explicitLabel : _humanize(key));
    }
    if (map['items'] is List) {
      final sectionKey = _first(
        map,
        const ['section_key', 'key', 'slug', 'route_key'],
      );
      final sectionLabel = _first(map, const ['title', 'label', 'name']);
      if (sectionKey.isNotEmpty) {
        final key = normalizeChannelKey(sectionKey);
        return _Category(
          key,
          sectionLabel.isNotEmpty ? sectionLabel : _humanize(key),
        );
      }
    }
    if (inherited != null) return inherited;
    if (joined.contains('daily_scripture') ||
        joined.contains('daily scripture') ||
        joined.contains('verse')) {
      return const _Category('daily_scripture', 'Daily Scripture');
    }
    if (joined.contains('sod')) {
      return const _Category('sod_quotes', 'SOD Quotes');
    }
    if (joined.contains('enenche')) {
      return const _Category('paul_enenche_quotes', 'Dr Paul Enenche Quotes');
    }
    if (joined.contains('motivation')) {
      return const _Category('motivational_quotes', 'Motivational Quotes');
    }
    if (joined.contains('daily_quote') || joined.contains('daily quote')) {
      return const _Category('daily_quote', 'Daily Quote');
    }
    return const _Category('other_quotes', 'Other Quotes');
  }

  static bool _hasStructuredQuoteIdentity(Map<String, dynamic> map) {
    final type = _first(map, const [
      'engine_type',
      'engineType',
      'type',
      'renderer_type',
      'rendererType',
    ]);
    final normalizedType = normalizeChannelKey(type);
    if (normalizedType == 'quote_channel' ||
        normalizedType == 'quote' ||
        normalizedType == 'scripture_quote') {
      return true;
    }

    final channelKey = _first(map, const [
      'channel_key',
      'channelKey',
      'source_channel',
      'sourceChannel',
      'category_key',
      'categoryKey',
    ]);
    if (channelKey.isEmpty) return false;

    return _first(map, const [
      'quote_text',
      'scripture_text',
      'verse_text',
      'quote',
    ]).isNotEmpty;
  }

  static String normalizeChannelKey(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static String _humanize(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  static int _int(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toInt();
      final parsed = int.tryParse((value ?? '').toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static String _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static String _stripHtml(String input) => input
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .trim();
}

class _Category {
  final String key;
  final String label;
  const _Category(this.key, this.label);
}

class _NoopListenable extends ChangeNotifier {
  _NoopListenable();
}
