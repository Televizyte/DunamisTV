import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UniversalMediaLauncher {
  static void open(
    BuildContext context, {
    required String title,
    required String url,
    String? type,
  }) {
    final cleanTitle = title.trim().isEmpty ? 'Open' : title.trim();
    final cleanUrl = _normalizeUrl(url);

    if (cleanUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media link is not available yet.')),
      );
      return;
    }

    final resolvedType = _resolveType(
      explicitType: type,
      url: cleanUrl,
      title: cleanTitle,
    );

    switch (resolvedType) {
      case 'hls':
        context.push(
          '/player/hls',
          extra: {
            'title': cleanTitle,
            'url': cleanUrl,
          },
        );
        return;

      case 'youtube_playlist':
        context.push(
          '/player/youtube',
          extra: {
            'title': cleanTitle,
            'url': cleanUrl,
          },
        );
        return;

      case 'youtube':
        context.push(
          '/player/youtube',
          extra: {
            'title': cleanTitle,
            'url': cleanUrl,
          },
        );
        return;

      case 'audio':
      case 'web':
      default:
        context.push(
          '/watch/web',
          extra: {
            'title': cleanTitle,
            'url': cleanUrl,
          },
        );
        return;
    }
  }

  static String _normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    if (trimmed.startsWith('www.')) {
      return 'https://$trimmed';
    }

    return trimmed;
  }

  static String _resolveType({
    String? explicitType,
    required String url,
    required String title,
  }) {
    final type = (explicitType ?? '').trim().toLowerCase();
    final lowerUrl = url.toLowerCase();
    final lowerTitle = title.trim().toLowerCase();

    // 1. Always honor explicit web intent first.
    if (_isExplicitWebType(type)) {
      return 'web';
    }

    // 2. Known web-player wrappers and channel pages must stay in WebView.
    if (_shouldForceWebView(
      lowerUrl: lowerUrl,
      lowerTitle: lowerTitle,
      explicitType: type,
    )) {
      return 'web';
    }

    // 3. Then allow direct media detection.
    if (_isHlsUrl(lowerUrl)) {
      return 'hls';
    }

    if (_isYoutubePlaylistUrl(lowerUrl)) {
      return 'youtube_playlist';
    }

    if (_isYoutubeUrl(lowerUrl)) {
      return 'youtube';
    }

    if (_isAudioUrl(lowerUrl)) {
      return 'audio';
    }

    // 4. Explicit media types come after web forcing.
    if (_isExplicitHlsType(type)) {
      return 'hls';
    }

    if (_isExplicitYoutubePlaylistType(type)) {
      return _isYoutubeUrl(lowerUrl) ? 'youtube_playlist' : 'web';
    }

    if (_isExplicitYoutubeType(type)) {
      return _isYoutubeUrl(lowerUrl) ? 'youtube' : 'web';
    }

    if (_isExplicitAudioType(type)) {
      return _isAudioUrl(lowerUrl) ? 'audio' : 'web';
    }

    // 5. Safe fallback.
    return 'web';
  }

  static bool _shouldForceWebView({
    required String lowerUrl,
    required String lowerTitle,
    required String explicitType,
  }) {
    if (_looksLikeWebWrapper(lowerUrl)) return true;
    if (_looksLikeHtmlPage(lowerUrl)) return true;
    if (_looksLikeChannelPage(lowerUrl, lowerTitle)) return true;

    // If backend says it's a channel-like destination, keep it as web.
    if (explicitType == 'channel' ||
        explicitType == 'embed' ||
        explicitType == 'iframe' ||
        explicitType == 'browser' ||
        explicitType == 'html' ||
        explicitType == 'page' ||
        explicitType == 'external' ||
        explicitType == 'link' ||
        explicitType == 'url' ||
        explicitType == 'web') {
      return true;
    }

    return false;
  }

  static bool _isExplicitYoutubeType(String type) {
    if (type.isEmpty) return false;

    return type == 'youtube' ||
        type == 'yt' ||
        type == 'youtube_video' ||
        type == 'video' ||
        type == 'vod' ||
        type == 'live_youtube' ||
        type == 'commanding_day';
  }

  static bool _isExplicitYoutubePlaylistType(String type) {
    if (type.isEmpty) return false;

    return type == 'playlist' ||
        type == 'youtube_playlist' ||
        type == 'yt_playlist';
  }

  static bool _isExplicitHlsType(String type) {
    if (type.isEmpty) return false;

    return type == 'hls' ||
        type == 'live_hls' ||
        type == 'm3u8' ||
        type == 'stream_hls';
  }

  static bool _isExplicitAudioType(String type) {
    if (type.isEmpty) return false;

    return type.contains('audio') ||
        type.contains('podcast') ||
        type.contains('music') ||
        type.contains('radio');
  }

  static bool _isExplicitWebType(String type) {
    if (type.isEmpty) return false;

    return type == 'web' ||
        type == 'channel' ||
        type == 'link' ||
        type == 'url' ||
        type == 'external' ||
        type == 'embed' ||
        type == 'iframe' ||
        type == 'browser' ||
        type == 'html' ||
        type == 'page';
  }

  static bool _isYoutubeUrl(String lowerUrl) {
    return lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('youtube-nocookie.com');
  }

  static bool _isYoutubePlaylistUrl(String lowerUrl) {
    if (!_isYoutubeUrl(lowerUrl)) return false;
    return lowerUrl.contains('list=');
  }

  static bool _isHlsUrl(String lowerUrl) {
    return lowerUrl.endsWith('.m3u8') ||
        lowerUrl.contains('.m3u8?') ||
        lowerUrl.contains('/m3u8');
  }

  static bool _isAudioUrl(String lowerUrl) {
    return lowerUrl.endsWith('.mp3') ||
        lowerUrl.endsWith('.wav') ||
        lowerUrl.endsWith('.m4a') ||
        lowerUrl.endsWith('.aac') ||
        lowerUrl.endsWith('.ogg') ||
        lowerUrl.contains('.mp3?') ||
        lowerUrl.contains('.wav?') ||
        lowerUrl.contains('.m4a?') ||
        lowerUrl.contains('.aac?') ||
        lowerUrl.contains('.ogg?');
  }

  static bool _looksLikeWebWrapper(String lowerUrl) {
    return lowerUrl.contains('viewmedia.tv') ||
        lowerUrl.contains('iframe.viewmedia.tv') ||
        lowerUrl.contains('bozztv.com') ||
        lowerUrl.contains('/embed/') ||
        lowerUrl.contains('/iframe/');
  }

  static bool _looksLikeHtmlPage(String lowerUrl) {
    return lowerUrl.endsWith('.html') ||
        lowerUrl.endsWith('.htm') ||
        lowerUrl.contains('.html?') ||
        lowerUrl.contains('.htm?');
  }

  static bool _looksLikeChannelPage(String lowerUrl, String lowerTitle) {
    final urlLooksChannelish = lowerUrl.contains('/watch') ||
        lowerUrl.contains('/live') ||
        lowerUrl.contains('/stream') ||
        lowerUrl.contains('/channel') ||
        lowerUrl.contains('/player') ||
        lowerUrl.contains('watch?') ||
        lowerUrl.contains('live?') ||
        lowerUrl.contains('stream?') ||
        lowerUrl.contains('channel?') ||
        lowerUrl.contains('player?');

    final titleLooksChannelish = lowerTitle.contains('channel') ||
        lowerTitle.contains('tv') ||
        lowerTitle.contains('christian tv') ||
        lowerTitle.contains('other channel') ||
        lowerTitle.contains('other channels');

    return urlLooksChannelish || titleLooksChannelish;
  }
}
