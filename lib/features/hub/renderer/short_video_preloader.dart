import 'package:video_player/video_player.dart';

class ShortVideoPreloader {
  VideoPlayerController? _nextController;
  String? _nextUrl;

  Future<void> preload(String url) async {
    if (_nextUrl == url) return;

    await dispose();

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _nextController = controller;
      _nextUrl = url;

      await controller.initialize();
      await controller.setLooping(true);
    } catch (_) {
      await dispose();
    }
  }

  VideoPlayerController? takeIfMatches(String url) {
    if (_nextUrl == url) {
      final controller = _nextController;
      _nextController = null;
      _nextUrl = null;
      return controller;
    }
    return null;
  }

  Future<void> dispose() async {
    if (_nextController != null) {
      await _nextController!.dispose();
      _nextController = null;
      _nextUrl = null;
    }
  }
}
