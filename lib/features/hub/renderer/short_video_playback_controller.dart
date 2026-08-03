import '../models/short_video_item.dart';

class ShortVideoPlaybackController {
  final List<ShortVideoItem> items;
  int _activeIndex;

  ShortVideoPlaybackController({
    required this.items,
    int initialIndex = 0,
  }) : _activeIndex = _normalizeIndex(
          initialIndex,
          items.length,
        );

  int get activeIndex => _activeIndex;

  ShortVideoItem? get activeItem {
    if (items.isEmpty) return null;
    if (_activeIndex < 0 || _activeIndex >= items.length) return null;
    return items[_activeIndex];
  }

  bool get hasItems => items.isNotEmpty;

  bool get canGoNext => items.isNotEmpty && _activeIndex < items.length - 1;

  bool get canGoPrevious => items.isNotEmpty && _activeIndex > 0;

  ShortVideoItem? goTo(int index) {
    if (items.isEmpty) return null;

    _activeIndex = _normalizeIndex(
      index,
      items.length,
    );

    return activeItem;
  }

  ShortVideoItem? next() {
    if (!canGoNext) return activeItem;

    _activeIndex++;

    return activeItem;
  }

  ShortVideoItem? previous() {
    if (!canGoPrevious) return activeItem;

    _activeIndex--;

    return activeItem;
  }

  ShortVideoItem? first() {
    if (items.isEmpty) return null;

    _activeIndex = 0;

    return activeItem;
  }

  ShortVideoItem? last() {
    if (items.isEmpty) return null;

    _activeIndex = items.length - 1;

    return activeItem;
  }

  static int _normalizeIndex(
    int index,
    int length,
  ) {
    if (length <= 0) return 0;

    if (index < 0) return 0;

    if (index >= length) return length - 1;

    return index;
  }
}
