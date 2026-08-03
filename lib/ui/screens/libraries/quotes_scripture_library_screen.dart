import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/hub/state/hub_scope.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
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
        final allItems = QuoteScriptureLibraryMapper.fromRawHub(
          store?.raw ?? const <String, dynamic>{},
        );
        final categories = QuoteScriptureLibraryMapper.categories(allItems);
        final filtered = _category.isEmpty
            ? allItems
            : allItems
                .where((item) => _normalize(item.categoryKey) == _category)
                .toList();
        final visible = filtered.take(_visibleCount).toList();

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
                          itemCount: visible.length +
                              (visible.length >= 3 ? visible.length ~/ 3 : 0),
                          itemBuilder: (context, index) {
                            if ((index + 1) % 4 == 0) {
                              return const Padding(
                                padding: EdgeInsets.fromLTRB(14, 0, 14, 14),
                                child: NativeInlineAdTile(
                                  tabKey: 'quotes.library',
                                  label: 'Sponsored',
                                  minHeight: 150,
                                ),
                              );
                            }
                            final itemIndex = index - (index ~/ 4);
                            if (itemIndex >= visible.length) {
                              return const SizedBox.shrink();
                            }
                            final item = visible[itemIndex];
                            return Padding(
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

  @override
  void initState() {
    super.initState();
    final index =
        widget.items.indexWhere((item) => item.id == widget.initialId);
    _controller =
        PageController(initialPage: _contentToPage(index < 0 ? 0 : index));
  }

  int _contentToPage(int index) => index + (index ~/ 3);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adCount = widget.items.length ~/ 3;
    final total = widget.items.length + adCount;
    return Scaffold(
      backgroundColor: const Color(0xFF090713),
      body: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: total,
        itemBuilder: (context, pageIndex) {
          if ((pageIndex + 1) % 4 == 0) {
            return const ColoredBox(
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
          final itemIndex = pageIndex - (pageIndex ~/ 4);
          final item = widget.items[itemIndex];
          return SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 90, 24, 90),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF27135E), Color(0xFF9D174D)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.categoryLabel,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              item.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.attribution.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              Text(
                                item.attribution,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
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

  const QuoteScriptureLibraryItem({
    required this.id,
    required this.categoryKey,
    required this.categoryLabel,
    required this.text,
    required this.attribution,
    required this.raw,
  });
}

class QuoteScriptureLibraryMapper {
  const QuoteScriptureLibraryMapper._();

  static List<QuoteScriptureLibraryItem> fromRawHub(
    Map<String, dynamic> rawHub,
  ) {
    final out = <QuoteScriptureLibraryItem>[];
    final seen = <String>{};

    void scan(dynamic value, {String path = ''}) {
      if (value is List) {
        for (final item in value) scan(item, path: path);
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
      if (looksRelevant && text.trim().length >= 12) {
        final category = _category(joined);
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
          ));
        }
      }
      for (final entry in map.entries) {
        if (entry.value is Map || entry.value is List) {
          scan(entry.value, path: '$path ${entry.key}');
        }
      }
    }

    scan(rawHub);
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

  static _Category _category(String joined) {
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
