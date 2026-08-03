import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/ads_service.dart';
import '../../media/universal_media_launcher.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/gradient_page_background.dart';

import 'watch_payload_resolver.dart';

class ChannelsListScreen extends StatelessWidget {
  const ChannelsListScreen({super.key});

  static const _topGradient = LinearGradient(
    colors: [
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final extra = (GoRouterState.of(context).extra as Map?) ?? {};
    final pageTitle = (extra['title'] ?? 'Watch Channels').toString().trim();
    final rawItems = (extra['items'] as List?) ?? const [];

    final seen = <String>{};

    final items = rawItems
        .whereType<Map>()
        .map<_ChannelItem>((m) {
          final map = Map<String, dynamic>.from(m);

          return _ChannelItem(
            title: (map['title'] ?? '').toString().trim(),
            url: WatchPayloadResolver.resolveUrl(map),
            subtitle: WatchPayloadResolver.resolveSubtitle(map),
            type: WatchPayloadResolver.resolveType(map, fallback: 'web'),
            badge: WatchPayloadResolver.resolveBadge(map),
            imageUrl: WatchPayloadResolver.resolveImageUrl(map),
            fallbackAsset: '',
          );
        })
        .where((m) => m.url.isNotEmpty || m.title.isNotEmpty)
        .where((m) {
          final signature = '${m.title.toLowerCase()}|${m.url.toLowerCase()}';
          if (seen.contains(signature)) return false;
          seen.add(signature);
          return true;
        })
        .toList(growable: false)
        .asMap()
        .entries
        .map(
          (entry) => _ChannelItem(
            title: entry.value.title,
            subtitle: entry.value.subtitle.isNotEmpty
                ? entry.value.subtitle
                : 'Open available content',
            type: entry.value.type,
            badge: entry.value.badge,
            url: entry.value.url,
            imageUrl: entry.value.imageUrl,
            fallbackAsset: _fallbackAssetFor(entry.key),
          ),
        )
        .toList(growable: false);

    final slides = _buildSlides(pageTitle, items);

    AdsService.instance.preloadInterstitial(
      tabKey: 'watch.action.open_channels',
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          decoration: const BoxDecoration(gradient: _topGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/watch');
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      pageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'More',
                    onPressed: () => _openTopMenu(context),
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: BannerAdWidget(
          tabKey: 'watch.channels',
          padding: EdgeInsets.fromLTRB(12, 4, 12, 8),
        ),
      ),
      body: GradientPageBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _ChannelsHeroCarousel(slides: slides),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Channels',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Open alternative Christian TV channels and external viewing options.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const NativeInlineAdTile(
                    key: ValueKey('watch-native-channel-list'),
                    tabKey: 'watch.native.channel_list',
                    label: 'Sponsored',
                    minHeight: 120,
                    margin: EdgeInsets.only(bottom: 14),
                  ),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == items.length - 1 ? 20 : 14,
                      ),
                      child: _ChannelLargeCard(
                        item: item,
                        fallbackAsset: item.fallbackAsset,
                        onTap: item.url.trim().isNotEmpty
                            ? () => _open(
                                  context,
                                  title: item.title,
                                  url: item.url,
                                  type: item.type,
                                )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Map<String, String>> _buildSlides(
    String pageTitle,
    List<_ChannelItem> items,
  ) {
    if (items.isEmpty) {
      return [
        {
          'title': pageTitle,
          'subtitle': 'Open available channels and programs',
          'image_url': '',
        },
      ];
    }

    return items
        .map(
          (item) => {
            'title': item.title,
            'subtitle': item.subtitle.isNotEmpty
                ? item.subtitle
                : 'Open available content',
            'image_url': item.imageUrl,
          },
        )
        .toList(growable: false);
  }

  static void _openTopMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D1228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                _TopMenuItem(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Notification center will be connected next',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Notifications screen not connected yet.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _TopMenuItem(
                  icon: Icons.refresh_rounded,
                  title: 'Refresh',
                  subtitle: 'Refresh will be standardized globally next',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Refresh will be standardized globally next.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _open(
    BuildContext context, {
    required String title,
    required String url,
    required String type,
  }) async {
    await AdsService.instance.maybeShowInterstitialOnSafeNav(
      context,
      tabKey: 'watch.action.open_channels',
    );
    if (!context.mounted) return;

    UniversalMediaLauncher.open(
      context,
      title: title,
      url: url,
      type: type,
    );
  }

  static String _fallbackAssetFor(int index) {
    const assets = [
      'assets/images/watch_1.jpg',
      'assets/images/watch_2.jpg',
      'assets/images/watch_3.jpg',
      'assets/images/watch_4.jpg',
      'assets/images/watch_5.jpg',
    ];
    return assets[index % assets.length];
  }
}

class _ChannelsHeroCarousel extends StatefulWidget {
  final List<Map<String, String>> slides;

  const _ChannelsHeroCarousel({
    required this.slides,
  });

  @override
  State<_ChannelsHeroCarousel> createState() => _ChannelsHeroCarouselState();
}

class _ChannelsHeroCarouselState extends State<_ChannelsHeroCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  List<Map<String, String>> get _effectiveSlides {
    if (widget.slides.isNotEmpty) return widget.slides;

    return const [
      {
        'title': 'Watch Channels',
        'subtitle': 'Open available channels and programs',
        'image_url': '',
      },
    ];
  }

  String _fallbackAssetFor(int index) {
    const assets = [
      'assets/images/watch_4.jpg',
      'assets/images/watch_5.jpg',
      'assets/images/watch_2.jpg',
      'assets/images/watch_3.jpg',
      'assets/images/watch_1.jpg',
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
  void didUpdateWidget(covariant _ChannelsHeroCarousel oldWidget) {
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
          height: 190,
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
                    return _ChannelsHeroSlideCard(
                      title: slide['title']?.trim().isNotEmpty == true
                          ? slide['title']!
                          : 'Channels',
                      subtitle: slide['subtitle']?.trim().isNotEmpty == true
                          ? slide['subtitle']!
                          : 'Open available channels and programs',
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
                  child: _ChannelsHeroArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _goTo(_index - 1),
                  ),
                ),
              if (slides.length > 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: _ChannelsHeroArrowButton(
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

class _ChannelsHeroSlideCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String fallbackAsset;

  const _ChannelsHeroSlideCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ChannelsSmartImage(
          imageUrl: imageUrl,
          fallbackAsset: fallbackAsset,
          height: 190,
        ),
        Container(
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.16),
                Colors.black.withOpacity(0.28),
                Colors.black.withOpacity(0.82),
              ],
              stops: const [0.0, 0.42, 1.0],
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

class _ChannelsHeroArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ChannelsHeroArrowButton({
    required this.icon,
    required this.onTap,
  });

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
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChannelLargeCard extends StatelessWidget {
  final _ChannelItem item;
  final String fallbackAsset;
  final VoidCallback? onTap;

  const _ChannelLargeCard({
    required this.item,
    required this.fallbackAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final badgeText = item.badge.trim().isNotEmpty
        ? item.badge.trim().toUpperCase()
        : 'CHANNEL';

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            height: 176,
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
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _ChannelsSmartImage(
                    imageUrl: item.imageUrl,
                    fallbackAsset: fallbackAsset,
                    height: 176,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.10),
                        Colors.black.withOpacity(0.22),
                        Colors.black.withOpacity(0.80),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ChannelBadge(text: badgeText),
                          const Spacer(),
                          Icon(
                            Icons.tv_rounded,
                            color: Colors.white.withOpacity(0.92),
                            size: 24,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        item.title,
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
                        item.subtitle.isNotEmpty
                            ? item.subtitle
                            : 'Open available content',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
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
}

class _ChannelsSmartImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final double height;

  const _ChannelsSmartImage({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.height,
  });

  bool get _hasRemoteImage => (imageUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl!.trim(),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            fallbackAsset,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: height,
              width: double.infinity,
              color: const Color(0xFF1B1B2A),
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: double.infinity,
            color: const Color(0xFF151528),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
      );
    }

    return Image.asset(
      fallbackAsset,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: const Color(0xFF1B1B2A),
      ),
    );
  }
}

class _ChannelBadge extends StatelessWidget {
  final String text;

  const _ChannelBadge({
    required this.text,
  });

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

class _TopMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TopMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.78),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelItem {
  final String title;
  final String subtitle;
  final String type;
  final String badge;
  final String url;
  final String imageUrl;
  final String fallbackAsset;

  const _ChannelItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.badge,
    required this.url,
    required this.imageUrl,
    required this.fallbackAsset,
  });
}
