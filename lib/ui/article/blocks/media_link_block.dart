import 'package:flutter/material.dart';

import '../../media/universal_media_launcher.dart';

class MediaLinkBlock extends StatelessWidget {
  final Map<String, dynamic> block;
  final String fallbackAsset;

  const MediaLinkBlock({
    super.key,
    required this.block,
    required this.fallbackAsset,
  });

  @override
  Widget build(BuildContext context) {
    final explicitType = (block['type'] ?? '').toString().trim().toLowerCase();
    final rawUrl = _firstNonEmpty(
      block,
      const [
        'url',
        'link',
        'src',
        'stream_url',
        'video_url',
        'audio_url',
      ],
    );
    final url = _normalizeUrl(rawUrl);
    final resolvedType = _resolveMediaType(url: url, explicitType: explicitType);
    final title =
        _firstNonEmpty(block, const ['title', 'name']).trim().isEmpty
            ? _defaultTitle(resolvedType)
            : _firstNonEmpty(block, const ['title', 'name']).trim();
    final subtitle =
        _firstNonEmpty(block, const ['subtitle', 'description', 'caption']).trim().isEmpty
            ? _defaultSubtitle(resolvedType)
            : _firstNonEmpty(block, const ['subtitle', 'description', 'caption']).trim();
    final imageUrl = _normalizeUrl(
      _firstNonEmpty(
        block,
        const [
          'image_url',
          'cover_url',
          'thumbnail_url',
          'poster_url',
          'image',
        ],
      ),
    );

    if (url.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 188,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => UniversalMediaLauncher.open(
            context,
            title: title,
            url: url,
            type: resolvedType,
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: _SmartImage(
                      imageUrl: imageUrl,
                      fallbackAsset: fallbackAsset,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.10),
                          Colors.black.withOpacity(0.24),
                          Colors.black.withOpacity(0.84),
                        ],
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _MediaBadge(text: _badgeText(resolvedType)),
                          const Spacer(),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.26),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.16),
                              ),
                            ),
                            child: Icon(
                              _iconForType(resolvedType),
                              color: Colors.white.withOpacity(0.94),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
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
                          color: Colors.white.withOpacity(0.90),
                          fontSize: 12.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _footerText(resolvedType),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.72),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Tap to open',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
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

  static String _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _normalizeUrl(String input) {
    final value = input.trim();
    if (value.isEmpty) return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('//')) {
      return 'https:$value';
    }

    if (value.startsWith('/')) {
      return 'https://admin.apps.digitxtramedia.com$value';
    }

    return value;
  }

  static String _resolveMediaType({
    required String url,
    required String explicitType,
  }) {
    final type = explicitType.toLowerCase();
    final lowerUrl = url.toLowerCase();

    if (type.contains('youtube') ||
        type == 'video' ||
        type == 'yt' ||
        type == 'playlist') {
      return 'youtube';
    }

    if (type.contains('hls') ||
        type.contains('live') ||
        type.contains('m3u8')) {
      return 'hls';
    }

    if (type.contains('audio') ||
        type.contains('podcast') ||
        type.contains('radio') ||
        type.contains('music')) {
      return 'audio';
    }

    if (lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('youtube-nocookie.com')) {
      return 'youtube';
    }

    if (lowerUrl.endsWith('.m3u8') || lowerUrl.contains('.m3u8?')) {
      return 'hls';
    }

    if (lowerUrl.endsWith('.mp3') ||
        lowerUrl.endsWith('.wav') ||
        lowerUrl.endsWith('.m4a') ||
        lowerUrl.endsWith('.aac') ||
        lowerUrl.endsWith('.ogg') ||
        lowerUrl.contains('.mp3?') ||
        lowerUrl.contains('.wav?') ||
        lowerUrl.contains('.m4a?') ||
        lowerUrl.contains('.aac?') ||
        lowerUrl.contains('.ogg?')) {
      return 'audio';
    }

    return 'web';
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'hls':
        return Icons.live_tv_rounded;
      case 'web':
      default:
        return Icons.public_rounded;
    }
  }

  static String _badgeText(String type) {
    switch (type) {
      case 'youtube':
        return 'VIDEO';
      case 'audio':
        return 'AUDIO';
      case 'hls':
        return 'LIVE';
      case 'web':
      default:
        return 'LINK';
    }
  }

  static String _defaultTitle(String type) {
    switch (type) {
      case 'youtube':
        return 'Open Video';
      case 'audio':
        return 'Open Audio';
      case 'hls':
        return 'Open Live Stream';
      case 'web':
      default:
        return 'Open Link';
    }
  }

  static String _defaultSubtitle(String type) {
    switch (type) {
      case 'youtube':
        return 'Backend video link ready';
      case 'audio':
        return 'Backend audio link ready';
      case 'hls':
        return 'Backend live stream ready';
      case 'web':
      default:
        return 'Backend web link ready';
    }
  }

  static String _footerText(String type) {
    switch (type) {
      case 'youtube':
        return 'Video player will open';
      case 'audio':
        return 'Web/audio page will open';
      case 'hls':
        return 'Live player will open';
      case 'web':
      default:
        return 'Web page will open';
    }
  }
}

class _SmartImage extends StatelessWidget {
  final String imageUrl;
  final String fallbackAsset;

  const _SmartImage({
    required this.imageUrl,
    required this.fallbackAsset,
  });

  bool get _hasRemoteImage => imageUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            fallbackAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1B1B2A),
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
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
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF1B1B2A),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  final String text;

  const _MediaBadge({
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
