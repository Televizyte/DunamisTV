import '../models/short_video_item.dart';

class ShortVideoFeedState {
  final List<ShortVideoItem> items;
  final int activeIndex;

  const ShortVideoFeedState({
    required this.items,
    required this.activeIndex,
  });

  factory ShortVideoFeedState.initial() {
    return const ShortVideoFeedState(
      items: <ShortVideoItem>[],
      activeIndex: 0,
    );
  }

  bool get hasItems => items.isNotEmpty;

  ShortVideoFeedState replaceItems(List<ShortVideoItem> nextItems) {
    return copyWith(
      items: List<ShortVideoItem>.unmodifiable(nextItems),
      activeIndex: _safeIndex(nextItems, activeIndex),
    );
  }

  ShortVideoFeedState setActiveIndex(int index) {
    return copyWith(activeIndex: _safeIndex(items, index));
  }

  ShortVideoFeedState copyWith({
    List<ShortVideoItem>? items,
    int? activeIndex,
  }) {
    final nextItems = items ?? this.items;
    return ShortVideoFeedState(
      items: List<ShortVideoItem>.unmodifiable(nextItems),
      activeIndex: _safeIndex(nextItems, activeIndex ?? this.activeIndex),
    );
  }

  static int _safeIndex(List<ShortVideoItem> items, int index) {
    if (items.isEmpty || index < 0) {
      return 0;
    }

    if (index >= items.length) {
      return items.length - 1;
    }

    return index;
  }
}
