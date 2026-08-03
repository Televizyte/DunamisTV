import 'package:flutter/material.dart';

import '../../../../features/hub/models/short_video_item.dart';
import '../../../../features/hub/renderer/short_video_navigation.dart';

class InspireShortVideoPreview {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String route;

  const InspireShortVideoPreview({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.route,
  });
}

class InspireShortVideoEntry extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<InspireShortVideoPreview> previews;
  final int count;
  final void Function(String route) onTap;
  final bool isLight;
  final List<ShortVideoItem> reelItems;

  const InspireShortVideoEntry({
    super.key,
    required this.title,
    required this.subtitle,
    required this.previews,
    required this.count,
    required this.onTap,
    required this.isLight,
    this.reelItems = const <ShortVideoItem>[],
  });

  @override
  Widget build(BuildContext context) {
    final items = previews.isNotEmpty
        ? previews
        : const [
            InspireShortVideoPreview(
              title: 'Watch Short Videos',
              subtitle: 'Tap to explore short inspirational videos',
              imageUrl: null,
              route: '/short-videos',
            ),
          ];

    final titleColor = isLight ? const Color(0xFF141827) : Colors.white;
    final subtitleColor =
        isLight ? const Color(0xFF667085) : Colors.white.withOpacity(0.76);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1D5CFF),
                      Color(0xFFE2388A),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trim().isNotEmpty ? title.trim() : 'Short Videos',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle.trim().isNotEmpty
                          ? subtitle.trim()
                          : 'Watch short inspirational video feeds',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  if (reelItems.isNotEmpty) {
                    ShortVideoNavigation.openReel(
                      context: context,
                      items: reelItems,
                      title: title.trim().isNotEmpty ? title.trim() : 'Short Videos',
                    );
                    return;
                  }
                  onTap('/short-videos');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isLight
                        ? const Color(0xFFF1F4FF)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFE1E7FF)
                          : Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Text(
                    count > 0 ? 'View $count' : 'View all',
                    style: TextStyle(
                      color: isLight ? const Color(0xFF1D5CFF) : Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 6),
              itemCount: items.length < 2 ? 2 : items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index % items.length];

                return _ShortVideoPortraitCard(
                  title: item.title,
                  subtitle: item.subtitle,
                  imageUrl: item.imageUrl,
                  route: _routeWithInitialIndex(
                    item.route.trim().isNotEmpty
                        ? item.route.trim()
                        : '/short-videos',
                    index % items.length,
                  ),
                  isLight: isLight,
                  reelItems: reelItems,
                  reelIndex: index % items.length,
                  onTap: onTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _routeWithInitialIndex(String route, int index) {
    final clean = route.trim().isEmpty ? '/short-videos' : route.trim();
    final safeIndex = index < 0 ? 0 : index;

    if (clean.contains('?')) {
      return '$clean&initialIndex=$safeIndex';
    }

    return '$clean?initialIndex=$safeIndex';
  }
}

class _ShortVideoPortraitCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String route;
  final bool isLight;
  final List<ShortVideoItem> reelItems;
  final int reelIndex;
  final void Function(String route) onTap;

  const _ShortVideoPortraitCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.route,
    required this.isLight,
    this.reelItems = const <ShortVideoItem>[],
    this.reelIndex = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width - 42) / 2;

    return SizedBox(
      width: width.clamp(142, 178),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () {
            if (reelItems.isNotEmpty) {
              ShortVideoNavigation.openReel(
                context: context,
                items: reelItems,
                initialIndex: reelIndex,
                title: 'Short Videos',
              );
              return;
            }
            onTap(route);
          },
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isLight ? 0.12 : 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _ShortVideoBackground(imageUrl: imageUrl),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.15),
                            Colors.black.withOpacity(0.82),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.34),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 11,
                    right: 11,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.trim().isNotEmpty
                              ? title.trim()
                              : 'Short Video',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.8,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle.trim().isNotEmpty
                              ? subtitle.trim()
                              : 'Tap to watch',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 11.2,
                            fontWeight: FontWeight.w700,
                            height: 1.12,
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
      ),
    );
  }
}

class _ShortVideoBackground extends StatelessWidget {
  final String? imageUrl;

  const _ShortVideoBackground({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final remote = (imageUrl ?? '').trim();

    if (_isRemoteImage(remote)) {
      return Image.network(
        remote,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _FallbackGradient(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return const _FallbackGradient(
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    return const _FallbackGradient();
  }

  bool _isRemoteImage(String value) {
    if (value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}

class _FallbackGradient extends StatelessWidget {
  final Widget? child;

  const _FallbackGradient({
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF160042),
            Color(0xFF1D5CFF),
            Color(0xFFE2388A),
          ],
        ),
      ),
      child: child,
    );
  }
}
