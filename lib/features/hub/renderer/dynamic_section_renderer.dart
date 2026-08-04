import 'package:flutter/material.dart';

import '../../../services/ads_service.dart';
import '../../../ui/widgets/ads/native_inline_ad_tile.dart';
import '../../../ui/widgets/banner_ad_widget.dart';
import '../models/dynamic_section.dart';
import '../models/short_video_item.dart';
import 'dynamic_card_renderer.dart';
import 'short_video_feed_renderer.dart';
import 'short_video_mapper.dart';
import 'short_video_navigation.dart';

class DynamicHubSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const DynamicHubSectionRenderer({
    super.key,
    required this.section,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    if (!section.enabled) {
      return const SizedBox.shrink();
    }

    if (!section.hasItems && !section.isAdSection) {
      return const SizedBox.shrink();
    }

    if (_sectionLooksLikeShortVideo(section)) {
      return _ShortVideoHorizontalSectionRenderer(
        section: section,
        padding: padding,
      );
    }

    if (_sectionLooksLikeQuoteChannel(section)) {
      return _QuoteSectionRenderer(section: section, padding: padding);
    }

    switch (section.layout) {
      case HubDynamicSectionLayout.hero:
        return _HeroSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.carousel:
        return _CarouselSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.horizontalScroll:
        return _HorizontalSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.grid:
        return _GridSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.iconGrid:
      case HubDynamicSectionLayout.toolGrid:
        return _IconGridSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.compact:
        return _CompactSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.quote:
      case HubDynamicSectionLayout.scripture:
        return _QuoteSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.verticalList:
      case HubDynamicSectionLayout.videoFeed:
      case HubDynamicSectionLayout.unknown:
        return _VerticalListSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.shortVideoFeed:
        return _ShortVideoSectionRenderer(section: section, padding: padding);

      case HubDynamicSectionLayout.adBlock:
        return _AdPlaceholderSection(section: section, padding: padding);
    }
  }
}

bool _sectionLooksLikeShortVideo(HubDynamicSection section) {
  final buffer = StringBuffer()
    ..write(' ')
    ..write(section.key)
    ..write(' ')
    ..write(section.title)
    ..write(' ')
    ..write(section.subtitle)
    ..write(' ')
    ..write(section.layout.name);

  void add(dynamic value) {
    if (value == null) return;
    if (value is Map) {
      for (final child in value.values) add(child);
      return;
    }
    if (value is List) {
      for (final child in value) add(child);
      return;
    }
    buffer.write(' ');
    buffer.write(value.toString());
  }

  add(section.settings);
  for (final item in section.items.take(3)) add(item);

  final text = buffer.toString().toLowerCase();
  return text.contains('short_video') ||
      text.contains('short videos') ||
      text.contains('short-videos') ||
      text.contains('shorts') ||
      text.contains('reel');
}

bool _sectionLooksLikeQuoteChannel(HubDynamicSection section) {
  final bucket = (section.settings['bucket'] ??
          section.settings['source_bucket'] ??
          section.key)
      .toString()
      .toLowerCase();
  final sourceType = (section.settings['source_type'] ??
          section.settings['content_source'] ??
          section.settings['source'])
      .toString()
      .toLowerCase();

  if (section.title.toLowerCase().contains('seed of destiny') ||
      section.key.toLowerCase().contains('inspire_sod')) {
    return false;
  }

  return sourceType.contains('quote') ||
      bucket.startsWith('quote_') ||
      bucket == 'daily_quotes' ||
      bucket == 'sod_quotes';
}

class _SectionWrapper extends StatelessWidget {
  final HubDynamicSection section;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionWrapper({
    required this.section,
    required this.child,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = section.title.trim().isNotEmpty;
    final hasSubtitle = section.subtitle.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle || hasSubtitle)
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTitle)
                    Text(
                      section.title.trim(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.94),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 6),
                    Text(
                      section.subtitle.trim(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class _HeroSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _HeroSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cards = section.items
        .map((e) => HubDynamicCard.fromMap(e))
        .where((e) => e.enabled)
        .toList();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: Padding(
        padding: padding,
        child: DynamicHubCardRenderer(
          card: cards.first,
          height: _sectionCardHeight(section, fallback: 220),
          index: 0,
        ),
      ),
    );
  }
}

class _CarouselSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _CarouselSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cards = section.items
        .map((e) => HubDynamicCard.fromMap(e))
        .where((e) => e.enabled)
        .toList();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final height = _sectionCardHeight(section, fallback: 185);
    final width = _sectionCardWidth(section, fallback: 310);

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: padding,
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return SizedBox(
              width: width,
              child: DynamicHubCardRenderer(
                card: cards[index],
                index: index,
                height: height,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HorizontalSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _HorizontalSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cards = section.items
        .map((e) => HubDynamicCard.fromMap(e))
        .where((e) => e.enabled)
        .toList();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final height = _sectionCardHeight(section, fallback: 165);
    final width = _sectionCardWidth(section, fallback: 290);

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: padding,
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return SizedBox(
              width: width,
              child: DynamicHubCardRenderer(
                card: cards[index],
                index: index,
                height: height,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GridSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _GridSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cards = section.items
        .map((e) => HubDynamicCard.fromMap(e))
        .where((e) => e.enabled)
        .toList();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final columns = section.columns.clamp(1, 6);
    final aspectRatio = _sectionAspectRatio(section, fallback: 0.92);

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: Padding(
        padding: padding,
        child: GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return DynamicHubCardRenderer(
              card: cards[index],
              index: index,
              height: _sectionCardHeight(section, fallback: 170),
            );
          },
        ),
      ),
    );
  }
}

class _IconGridSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _IconGridSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cards = section.items
        .map((e) => HubDynamicCard.fromMap(e))
        .where((e) => e.enabled)
        .toList();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final columns = section.columns.clamp(2, 6);
    final aspectRatio = _sectionAspectRatio(section, fallback: 0.92);

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: Padding(
        padding: padding,
        child: GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            return DynamicHubIconCardRenderer(
              card: cards[index],
              index: index,
            );
          },
        ),
      ),
    );
  }
}

class _QuoteSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _QuoteSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cards = section.items
        .map((e) => HubDynamicCard.fromMap(e))
        .where((e) => e.enabled)
        .toList();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final width = _sectionCardWidth(section, fallback: 286)
        .clamp(268.0, 304.0)
        .toDouble();
    final aspectRatio = _quoteCardAspectRatio(section, cards.first);
    final requiredHeight = (width / aspectRatio) + 102;
    final height = _sectionCardHeight(section, fallback: requiredHeight)
        .clamp(requiredHeight, requiredHeight + 72)
        .toDouble();

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: padding,
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return SizedBox(
              width: width,
              child: DynamicHubCardRenderer(
                card: cards[index],
                index: index,
                height: height,
                borderRadius: const BorderRadius.all(Radius.circular(24)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompactSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _CompactSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cards = section.items
        .map((e) => HubDynamicCard.fromMap(e))
        .where((e) => e.enabled)
        .toList();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: Padding(
        padding: padding,
        child: Column(
          children: List.generate(cards.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == cards.length - 1 ? 0 : 10,
              ),
              child: DynamicHubCompactCardRenderer(
                card: cards[index],
                index: index,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _VerticalListSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _VerticalListSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cards = section.items
        .map((e) => HubDynamicCard.fromMap(e))
        .where((e) => e.enabled)
        .toList();

    if (cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final height = _sectionCardHeight(section, fallback: 170);

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: Padding(
        padding: padding,
        child: Column(
          children: List.generate(cards.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == cards.length - 1 ? 0 : 12,
              ),
              child: DynamicHubCardRenderer(
                card: cards[index],
                index: index,
                height: height,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ShortVideoHorizontalSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _ShortVideoHorizontalSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final items = ShortVideoMapper.fromRawList(section.items)
        .where((item) => item.enabled)
        .toList(growable: false);

    if (items.isEmpty) return const SizedBox.shrink();

    final height =
        _sectionCardHeight(section, fallback: 238).clamp(210.0, 286.0);
    final width = _sectionCardWidth(section, fallback: 178).clamp(150.0, 230.0);

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: padding,
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return SizedBox(
              width: width,
              child: _InlineShortVideoCard(
                item: items[index],
                index: index,
                items: items,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InlineShortVideoCard extends StatelessWidget {
  final ShortVideoItem item;
  final int index;
  final List<ShortVideoItem> items;

  const _InlineShortVideoCard({
    required this.item,
    required this.index,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        item.title.trim().isNotEmpty ? item.title.trim() : 'Short Video';
    final thumb = item.thumbnailUrl.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => ShortVideoNavigation.openReel(
          context: context,
          items: items,
          initialIndex: index,
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF10162A),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isRemoteUrl(thumb))
                  Image.network(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _shortVideoFallback(index),
                  )
                else
                  _shortVideoFallback(index),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.18),
                        Colors.black.withOpacity(0.78),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.34),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Tap to watch',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _isRemoteUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  static Widget _shortVideoFallback(int index) {
    final colors = [
      const [Color(0xFF1D5CFF), Color(0xFFE2388A)],
      const [Color(0xFF7C2D12), Color(0xFFF97316)],
      const [Color(0xFF0F766E), Color(0xFF22D3EE)],
      const [Color(0xFF581C87), Color(0xFFDB2777)],
    ][index % 4];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}

class _ShortVideoSectionRenderer extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _ShortVideoSectionRenderer({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final items = ShortVideoMapper.fromRawList(section.items);

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionWrapper(
      section: section,
      padding: padding,
      child: Padding(
        padding: padding,
        child: Column(
          children: List.generate(items.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 14,
              ),
              child: ShortVideoPreviewCard(
                item: items[index],
                index: index,
                reelItems: items,
                reelIndex: index,
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AdPlaceholderSection extends StatelessWidget {
  final HubDynamicSection section;
  final EdgeInsetsGeometry padding;

  const _AdPlaceholderSection({
    required this.section,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AdsService.instance.policyRevision,
      builder: (context, _, __) => _buildForPolicy(context),
    );
  }

  Widget _buildForPolicy(BuildContext context) {
    final settings = section.settings;
    final format = (settings['ad_format'] ??
            settings['format'] ??
            settings['placement_format'] ??
            '')
        .toString()
        .trim()
        .toLowerCase();
    final policyKey = (settings['policy_key'] ??
            settings['route_key'] ??
            settings['ad_policy_key'] ??
            '')
        .toString()
        .trim();
    if (policyKey.isEmpty) return const SizedBox.shrink();

    final ads = AdsService.instance;
    if (format == 'banner') {
      if (!ads.bannerAllowedForPlacement(policyKey, 'page_bottom') ||
          !ads.hasUnitForFormat('banner')) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: padding,
        child: BannerAdWidget(
          tabKey: policyKey,
          placement: 'page_bottom',
        ),
      );
    }
    if (format == 'native') {
      if (!ads.nativeAllowedForTab(policyKey) ||
          !ads.hasUnitForFormat('native')) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: padding,
        child: NativeInlineAdTile(
          tabKey: policyKey,
          label: section.title.trim().isEmpty ? 'Sponsored' : section.title,
          minHeight: _sectionCardHeight(section, fallback: 120),
          margin: EdgeInsets.zero,
        ),
      );
    }

    // Interstitial sections and malformed/unsupported formats fail closed.
    return const SizedBox.shrink();
  }
}

double _sectionCardHeight(
  HubDynamicSection section, {
  required double fallback,
}) {
  final settings = section.settings;
  return _doubleValue(
    settings['card_height'] ??
        settings['height'] ??
        settings['item_height'] ??
        settings['mobile_card_height'],
    fallback: fallback,
    min: 90,
    max: 560,
  );
}

Map<String, dynamic>? _asLocalMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}

double _quoteCardAspectRatio(
  HubDynamicSection section,
  HubDynamicCard card,
) {
  final raw = card.raw;
  final payload = _asLocalMap(raw['payload']) ?? const <String, dynamic>{};
  final design = _asLocalMap(raw['design']) ??
      _asLocalMap(payload['design']) ??
      const <String, dynamic>{};
  final designText = _asLocalMap(design['text']) ?? const <String, dynamic>{};

  String readString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      if (value is Map || value is Iterable) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  final explicit = _doubleValue(
    section.settings['aspect_ratio'] ??
        section.settings['child_aspect_ratio'] ??
        raw['aspect_ratio'] ??
        payload['aspect_ratio'],
    fallback: -1,
    min: -1,
    max: 4,
  );
  if (explicit > 0) return explicit;

  final format = readString([
    section.settings['card_format'],
    section.settings['canvas_format'],
    raw['card_format'],
    payload['card_format'],
    design['format'],
    designText['format'],
  ]).toLowerCase();

  switch (format) {
    case 'square':
    case '1:1':
      return 1;
    case 'story':
    case '9:16':
      return 9 / 16;
    case 'landscape':
    case 'wide':
    case '16:9':
      return 16 / 9;
    case 'cinematic':
    case '21:9':
      return 21 / 9;
    case 'classic':
    case '3:2':
    case '3:4':
      return 3 / 4;
    case 'portrait':
    case '4:5':
    default:
      return 4 / 5;
  }
}

double _sectionCardWidth(
  HubDynamicSection section, {
  required double fallback,
}) {
  final settings = section.settings;
  return _doubleValue(
    settings['card_width'] ??
        settings['width'] ??
        settings['item_width'] ??
        settings['mobile_card_width'],
    fallback: fallback,
    min: 140,
    max: 520,
  );
}

double _sectionAspectRatio(
  HubDynamicSection section, {
  required double fallback,
}) {
  final settings = section.settings;
  final explicit = _doubleValue(
    settings['aspect_ratio'] ?? settings['child_aspect_ratio'],
    fallback: -1,
    min: -1,
    max: 4,
  );

  if (explicit > 0) {
    return explicit;
  }

  final format = (settings['card_format'] ?? settings['canvas_format'] ?? '')
      .toString()
      .trim()
      .toLowerCase();

  switch (format) {
    case 'square':
      return 1;
    case 'story':
      return 9 / 16;
    case 'landscape':
    case 'wide':
      return 16 / 9;
    case 'classic':
      return 3 / 2;
    case 'portrait':
      return 4 / 5;
    default:
      return fallback;
  }
}

double _doubleValue(
  dynamic value, {
  required double fallback,
  required double min,
  required double max,
}) {
  final parsed = double.tryParse((value ?? '').toString().trim());

  if (parsed == null) {
    return fallback;
  }

  if (parsed < min) {
    return min;
  }

  if (parsed > max) {
    return max;
  }

  return parsed;
}
