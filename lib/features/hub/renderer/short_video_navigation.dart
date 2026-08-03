import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/short_video_item.dart';
import 'short_video_mapper.dart';

class ShortVideoNavigation {
  const ShortVideoNavigation._();

  static const String route = '/short-videos';

  static Future<void> openReel({
    required BuildContext context,
    required List<ShortVideoItem> items,
    int initialIndex = 0,
    String initialItemId = '',
    String initialChannelKey = '',
    String title = 'Short Videos',
  }) async {
    final visibleItems = items
        .where((item) => item.enabled && item.hasVideo)
        .toList(growable: false);
    if (visibleItems.isEmpty) return;
    await context.push(route,
        extra: buildExtra(
          items: visibleItems,
          initialIndex: initialIndex,
          initialItemId: initialItemId,
          initialChannelKey: initialChannelKey,
          title: title,
        ));
  }

  static String routeWithInitialIndex(int index) {
    final safeIndex = index < 0 ? 0 : index;
    return '$route?initialIndex=$safeIndex';
  }

  static String routeWithItemId(String id) {
    final safeId = id.trim();
    if (safeId.isEmpty) return route;
    return '$route?id=${Uri.encodeQueryComponent(safeId)}';
  }

  static Map<String, dynamic> buildExtra({
    required List<ShortVideoItem> items,
    int initialIndex = 0,
    String initialItemId = '',
    String initialChannelKey = '',
    String title = 'Short Videos',
  }) {
    return {
      'items': items,
      'initialIndex': initialIndex,
      'initialItemId': initialItemId,
      'initialChannelKey': initialChannelKey,
      'title': title,
    };
  }

  static List<ShortVideoItem> extractItems(dynamic extra) {
    if (extra is! Map) return const [];
    final rawItems = extra['items'];
    if (rawItems is List<ShortVideoItem>) {
      return rawItems
          .where((item) => item.enabled && item.hasVideo)
          .toList(growable: false);
    }
    if (rawItems is List) {
      final typed =
          rawItems.whereType<ShortVideoItem>().toList(growable: false);
      if (typed.isNotEmpty) {
        return typed
            .where((item) => item.enabled && item.hasVideo)
            .toList(growable: false);
      }
      return ShortVideoMapper.fromRawList(rawItems);
    }
    return const [];
  }

  static int extractInitialIndex(dynamic extra, {int fallback = 0}) {
    if (extra is! Map) return fallback;
    final value = extra['initialIndex'];
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static String extractInitialItemId(dynamic extra, {String fallback = ''}) {
    if (extra is! Map) return fallback;
    final value = (extra['initialItemId'] ??
            extra['initial_item_id'] ??
            extra['targetItemId'] ??
            extra['target_item_id'] ??
            extra['content_id'] ??
            extra['post_id'] ??
            extra['id'] ??
            '')
        .toString()
        .trim();
    return value.isNotEmpty ? value : fallback;
  }


  static String extractInitialChannelKey(dynamic extra, {String fallback = ''}) {
    if (extra is! Map) return fallback;
    final value = (extra['initialChannelKey'] ??
            extra['initial_channel_key'] ??
            extra['channel_key'] ??
            extra['channel'] ??
            extra['short_channel_key'] ??
            '')
        .toString()
        .trim();
    return value.isNotEmpty ? value : fallback;
  }

  static String extractTitle(dynamic extra) {
    if (extra is! Map) return 'Short Videos';
    final value = (extra['title'] ?? '').toString().trim();
    return value.isNotEmpty ? value : 'Short Videos';
  }
}
