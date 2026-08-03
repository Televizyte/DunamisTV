import 'package:flutter/material.dart';

import '../models/short_video_item.dart';
import 'short_video_navigation.dart';

class ShortVideoFeedRenderer extends StatelessWidget {
  final List<ShortVideoItem> items;
  final EdgeInsetsGeometry padding;
  final Widget? emptyState;

  const ShortVideoFeedRenderer({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.enabled && item.hasVideo)
        .toList(growable: false);

    if (visibleItems.isEmpty) {
      return emptyState ?? const ShortVideoEmptyState();
    }

    return ListView.separated(
      padding: padding,
      itemCount: visibleItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return ShortVideoPreviewCard(
          item: visibleItems[index],
          index: index,
          reelItems: visibleItems,
          reelIndex: index,
        );
      },
    );
  }
}

class ShortVideoInlineFeedRenderer extends StatelessWidget {
  final List<ShortVideoItem> items;
  final EdgeInsetsGeometry padding;
  final Widget? emptyState;

  const ShortVideoInlineFeedRenderer({
    super.key,
    required this.items,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items
        .where((item) => item.enabled && item.hasVideo)
        .toList(growable: false);

    if (visibleItems.isEmpty) {
      return emptyState ?? const ShortVideoEmptyState();
    }

    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(visibleItems.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == visibleItems.length - 1 ? 0 : 14,
            ),
            child: ShortVideoPreviewCard(
              item: visibleItems[index],
              index: index,
              reelItems: visibleItems,
              reelIndex: index,
            ),
          );
        }),
      ),
    );
  }
}

class ShortVideoPreviewCard extends StatelessWidget {
  final ShortVideoItem item;
  final int index;
  final VoidCallback? onTap;
  final bool enableReelNavigation;
  final List<ShortVideoItem> reelItems;
  final int reelIndex;

  const ShortVideoPreviewCard({
    super.key,
    required this.item,
    this.index = 0,
    this.onTap,
    this.enableReelNavigation = true,
    this.reelItems = const [],
    this.reelIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final title = item.title.trim().isNotEmpty ? item.title.trim() : 'Short Video';
    final description = item.description.trim();
    final creator = item.creatorName.trim();
    final duration = _formatDuration(item.durationSeconds);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          if (onTap != null) {
            onTap!.call();
            return;
          }

          if (!enableReelNavigation) {
            return;
          }

          ShortVideoNavigation.openReel(
            context: context,
            items: reelItems.isEmpty ? [item] : reelItems,
            initialIndex: reelIndex,
          );
        },
        child: Ink(
          height: 420,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 12),
                color: Colors.black.withOpacity(0.20),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _ShortVideoPoster(
                  thumbnailUrl: item.thumbnailUrl,
                  index: index,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.12),
                      Colors.black.withOpacity(0.18),
                      Colors.black.withOpacity(0.78),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: _ShortVideoBadge(
                  text: duration.isNotEmpty ? duration : 'SHORT',
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (creator.isNotEmpty) ...[
                      Text(
                        creator,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.86),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                    ],
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 13,
                          height: 1.30,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes <= 0) {
      return '0:${remainingSeconds.toString().padLeft(2, '0')}';
    }

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class ShortVideoEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const ShortVideoEmptyState({
    super.key,
    this.title = 'No short videos yet',
    this.message = 'Short videos will appear here when enabled from AppsHub.',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1D5CFF),
                    Color(0xFFE2388A),
                  ],
                ),
              ),
              child: const Icon(
                Icons.video_collection_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isNotEmpty ? title.trim() : 'No short videos yet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message.trim().isNotEmpty
                        ? message.trim()
                        : 'Short videos will appear here when enabled from AppsHub.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
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

class _ShortVideoPoster extends StatelessWidget {
  final String thumbnailUrl;
  final int index;

  const _ShortVideoPoster({
    required this.thumbnailUrl,
    required this.index,
  });

  bool get _hasRemoteImage {
    final uri = Uri.tryParse(thumbnailUrl.trim());
    if (uri == null) return false;

    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        thumbnailUrl.trim(),
        height: 420,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _ShortVideoGradientPlaceholder(index: index);
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Stack(
            children: [
              _ShortVideoGradientPlaceholder(index: index),
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white.withOpacity(0.86),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return _ShortVideoGradientPlaceholder(index: index);
  }
}

class _ShortVideoGradientPlaceholder extends StatelessWidget {
  final int index;

  const _ShortVideoGradientPlaceholder({
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFF0B1F4D), Color(0xFF1D5CFF), Color(0xFFE2388A)],
      [Color(0xFF180B3A), Color(0xFF5F3BFF), Color(0xFF35C6FF)],
      [Color(0xFF081F2D), Color(0xFF087E8B), Color(0xFFB9FBC0)],
      [Color(0xFF2A0D30), Color(0xFF8E24AA), Color(0xFFFF4E8A)],
      [Color(0xFF111827), Color(0xFF2563EB), Color(0xFF9333EA)],
    ];

    final colors = palettes[index % palettes.length];

    return Container(
      height: 420,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -44,
            top: -44,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: -38,
            bottom: -44,
            child: Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white.withOpacity(0.34),
              size: 92,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortVideoBadge extends StatelessWidget {
  final String text;

  const _ShortVideoBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final safeText = text.trim().isEmpty ? 'SHORT' : text.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Text(
        safeText.toUpperCase(),
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
