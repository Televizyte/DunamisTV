import 'package:flutter/material.dart';

import '../player/youtube_player_screen.dart';

class YoutubeVideoScreen extends StatelessWidget {
  final String title;
  final String url;

  const YoutubeVideoScreen({
    super.key,
    required this.title,
    required this.url,
  });

  factory YoutubeVideoScreen.fromExtra(Object? extra) {
    if (extra is Map) {
      final rawTitle = (extra['title'] ?? '').toString();
      final rawUrl = (extra['url'] ?? extra['link'] ?? '').toString();

      return YoutubeVideoScreen(
        title: rawTitle,
        url: rawUrl,
      );
    }

    return const YoutubeVideoScreen(
      title: 'YouTube',
      url: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScreen(
      title: title.trim().isEmpty ? 'YouTube' : title.trim(),
      url: url.trim(),
    );
  }
}
