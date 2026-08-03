import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum YoutubeLinkKind {
  video,
  playlist,
  channelLive,
  unknown,
}

class YoutubeLinkInfo {
  final YoutubeLinkKind kind;
  final String originalUrl;

  // For kind == video
  final String? videoId;

  // For kind == playlist
  final String? playlistId;

  const YoutubeLinkInfo._({
    required this.kind,
    required this.originalUrl,
    this.videoId,
    this.playlistId,
  });

  static YoutubeLinkInfo parse(String url) {
    final raw = url.trim();
    if (raw.isEmpty) {
      return YoutubeLinkInfo._(kind: YoutubeLinkKind.unknown, originalUrl: raw);
    }

    final uri = Uri.tryParse(raw);

    // 1) Playlist detection: playlist?list=...
    final list = uri?.queryParameters['list']?.trim();
    final hasList = (list ?? '').isNotEmpty;

    // Some playlist URLs can still include a videoId (watch?v=...&list=...).
    // We prioritize video if we can get a videoId.
    final videoId = YoutubePlayer.convertUrlToId(raw);

    if ((videoId ?? '').isNotEmpty) {
      return YoutubeLinkInfo._(
        kind: YoutubeLinkKind.video,
        originalUrl: raw,
        videoId: videoId,
      );
    }

    if (hasList) {
      return YoutubeLinkInfo._(
        kind: YoutubeLinkKind.playlist,
        originalUrl: raw,
        playlistId: list,
      );
    }

    // 2) Channel "live" patterns
    final host = (uri?.host ?? '').toLowerCase();
    final path = (uri?.path ?? '').toLowerCase();

    final isYoutubeHost = host.contains('youtube.com') || host.contains('youtu.be');
    final looksLikeChannelLive =
        isYoutubeHost && (path.endsWith('/live') || path.contains('/@') && path.endsWith('live'));

    if (looksLikeChannelLive || (raw.contains('/live') && isYoutubeHost)) {
      return YoutubeLinkInfo._(
        kind: YoutubeLinkKind.channelLive,
        originalUrl: raw,
      );
    }

    return YoutubeLinkInfo._(
      kind: YoutubeLinkKind.unknown,
      originalUrl: raw,
    );
  }
}
