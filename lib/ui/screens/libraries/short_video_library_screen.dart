import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/hub/models/short_video_item.dart';
import '../../../features/hub/renderer/short_video_mapper.dart';
import '../../../features/hub/renderer/short_video_navigation.dart';
import '../../../features/hub/state/hub_scope.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/ads/native_list_injection.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class ShortVideoLibraryScreen extends StatefulWidget {
  final String initialChannelKey;

  const ShortVideoLibraryScreen({
    super.key,
    this.initialChannelKey = '',
  });

  @override
  State<ShortVideoLibraryScreen> createState() =>
      _ShortVideoLibraryScreenState();
}

class _ShortVideoLibraryScreenState extends State<ShortVideoLibraryScreen> {
  String _channel = '';
  int _visibleCount = 24;
  Map<String, dynamic>? _cachedRaw;
  List<ShortVideoItem> _cachedItems = const [];

  @override
  void initState() {
    super.initState();
    _channel = ShortVideoChannelMatcher.normalize(widget.initialChannelKey);
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
          _cachedItems = ShortVideoMapper.fromRawHub(raw)
              .where((item) => item.enabled && item.hasVideo)
              .toList(growable: false);
        }
        final allItems = _cachedItems;
        final categories = ShortVideoMapper.categoriesFor(allItems);
        final filtered = _channel.isEmpty
            ? allItems
            : allItems
                .where(
                  (item) => ShortVideoChannelMatcher.matches(item, _channel),
                )
                .toList();
        final visible = filtered.take(_visibleCount).toList();
        final entries = NativeListInjection.buildEntries(
          visible,
          tabKey: 'shorts.library',
        );

        return Scaffold(
          body: Column(
            children: [
              DxmTopBar(
                title: 'Short Video Library',
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
                          child: _ChannelFilters(
                            selected: _channel,
                            categories: categories,
                            onSelected: (value) => setState(() {
                              _channel = value;
                              _visibleCount = 24;
                            }),
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
                                'No short videos are available in this channel yet.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                          sliver: SliverGrid.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.62,
                            ),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              if (entry.isAd) {
                                return NativeInlineAdTile(
                                  key: ValueKey(
                                    'shorts.library.native.${entry.itemIndex}',
                                  ),
                                  tabKey: 'shorts.library',
                                  label: 'Sponsored',
                                  minHeight: 220,
                                );
                              }
                              final item = entry.item!;
                              return _ShortTile(
                                key: ValueKey('short.${item.safeId}'),
                                item: item,
                                onTap: () => ShortVideoNavigation.openReel(
                                  context: context,
                                  items: filtered,
                                  initialItemId: item.safeId,
                                  initialChannelKey: _channel,
                                  title: 'Short Videos',
                                ),
                              );
                            },
                          ),
                        ),
                      if (_visibleCount < filtered.length)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 30),
                            child: FilledButton.icon(
                              onPressed: () => setState(() {
                                _visibleCount += 24;
                              }),
                              icon: const Icon(Icons.expand_more_rounded),
                              label: const Text('Load more videos'),
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
}

class ShortVideoChannelMatcher {
  const ShortVideoChannelMatcher._();

  static bool matches(ShortVideoItem item, String wanted) {
    final candidates = <String>[
      item.categoryKey,
      item.categoryLabel,
      item.raw['channel_key']?.toString() ?? '',
      item.raw['channel']?.toString() ?? '',
      item.raw['_section_key']?.toString() ?? '',
      item.raw['_section_title']?.toString() ?? '',
      item.raw['_section_source_channel']?.toString() ?? '',
      item.raw['source_channel']?.toString() ?? '',
    ];
    final normalizedWanted = normalize(wanted);
    if (normalizedWanted.isEmpty) return true;
    return candidates.any((value) => normalize(value) == normalizedWanted);
  }

  static String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class _ChannelFilters extends StatelessWidget {
  final String selected;
  final List<ShortVideoCategory> categories;
  final ValueChanged<String> onSelected;

  const _ChannelFilters({
    required this.selected,
    required this.categories,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected.isEmpty,
            onSelected: (_) => onSelected(''),
          ),
          const SizedBox(width: 8),
          for (final category in categories) ...[
            ChoiceChip(
              label: Text(category.label),
              selected:
                  selected == ShortVideoChannelMatcher.normalize(category.key),
              onSelected: (_) => onSelected(
                ShortVideoChannelMatcher.normalize(category.key),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ShortTile extends StatelessWidget {
  final ShortVideoItem item;
  final VoidCallback onTap;

  const _ShortTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final image = item.thumbnailUrl.trim();
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image.isNotEmpty)
              Image.network(
                image,
                fit: BoxFit.cover,
                cacheWidth: 480,
                errorBuilder: (_, __, ___) => const _FallbackThumb(),
              )
            else
              const _FallbackThumb(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            const Center(
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.black54,
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 34),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.categoryLabel.trim().isNotEmpty)
                    Text(
                      item.categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  Text(
                    item.title.trim().isEmpty ? 'Short Video' : item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackThumb extends StatelessWidget {
  const _FallbackThumb();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24144F), Color(0xFF9D174D)],
        ),
      ),
      child: Center(
        child:
            Icon(Icons.video_library_rounded, color: Colors.white54, size: 48),
      ),
    );
  }
}

class _NoopListenable extends ChangeNotifier {
  _NoopListenable();
}
