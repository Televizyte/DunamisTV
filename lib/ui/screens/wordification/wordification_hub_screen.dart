import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/hub/state/hub_scope.dart';
import '../../widgets/inspire/inspire_featured_grid.dart';
import '../../widgets/inspire/inspire_inner_shell.dart';

class WordificationHubScreen extends StatelessWidget {
  const WordificationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);
    final hub = store?.raw ?? const <String, dynamic>{};

    final inspire =
        (hub['inspire'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final raw = inspire['wordification'];

    final List<Map<String, dynamic>> itemsRaw = (raw is List)
        ? raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
        : <Map<String, dynamic>>[];

    final featured = <InspireItem>[
      InspireItem(
        id: 'today',
        title: 'Today’s Wordification',
        subtitle: 'Scripture breakdown + application',
        pillText: 'FEATURED',
        icon: Icons.auto_awesome_rounded,
        designPayload: const {
          'background_mode': 'gradient',
          'bg_color': '#1B2350',
          'bg_color_2': '#B70E7C',
          'text_color': '#FFFFFF',
          'accent_color': '#38BDF8',
          'title_size': '18',
          'font_size': '12.8',
          'font_weight': '900',
          'overlay_strength': '72',
        },
        onTap: () => context.push(
          '/wordification/detail',
          extra: {'id': 'today'},
        ),
      ),
      InspireItem(
        id: 'topics',
        title: 'Hot Topics',
        subtitle: 'Faith • Purpose • Growth • Wisdom',
        pillText: 'TOPICS',
        icon: Icons.local_fire_department_rounded,
        designPayload: const {
          'background_mode': 'gradient',
          'bg_color': '#061B3A',
          'bg_color_2': '#0EA5E9',
          'text_color': '#FFFFFF',
          'accent_color': '#67E8F9',
          'title_size': '18',
          'font_size': '12.8',
          'font_weight': '900',
          'overlay_strength': '72',
        },
        onTap: () => context.push(
          '/wordification/detail',
          extra: {'id': 'topics'},
        ),
      ),
    ];

    final items = itemsRaw.map((m) {
      final id = (m['id'] ?? 'wf').toString();
      final title = (m['title'] ?? m['topic'] ?? 'Wordification').toString();
      final subtitle = _firstNonEmpty([
        (m['scripture'] ?? '').toString(),
        _resolveExcerpt(m),
        (m['subtitle'] ?? '').toString(),
        'Tap to open',
      ]);
      final imageUrl = _pickImage(m);
      return InspireItem(
        id: id,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        pillText: _resolvePillText(m, fallback: 'WORD'),
        icon: Icons.auto_awesome_rounded,
        designPayload: _extractDesignPayload(m),
        onTap: () => context.push(
          '/wordification/detail',
          extra: {'id': id},
        ),
      );
    }).toList();

    return InspireInnerShell(
      title: 'Wordification',
      onRefresh: () => store?.refresh(),
      child: InspireFeaturedGrid(
        featured: featured,
        items: items,
        emptyTitle: 'No Wordification yet',
        emptySubtitle:
            'FireDrive will publish Wordification posts here. This page stays ready.',
      ),
    );
  }

  static Map<String, dynamic>? _extractDesignPayload(Map<String, dynamic> item) {
    final payload = _asMap(item['payload']);
    final meta = _asMap(item['meta']);
    final design = _asMap(item['design']) ??
        _asMap(payload?['design']) ??
        _asMap(payload?['designer']) ??
        _asMap(payload?['quote_card']) ??
        _asMap(meta?['design']);

    final output = <String, dynamic>{};
    output.addAll(item);
    if (payload != null) output.addAll(payload);
    if (meta != null) output.addAll(meta);
    if (design != null) output.addAll(design);

    return output;
  }


  static String _resolveExcerpt(Map<String, dynamic> item) {
    final body = _firstNonEmpty([
      (item['body'] ?? '').toString(),
      (item['content'] ?? '').toString(),
      (item['text'] ?? '').toString(),
      (item['body_html'] ?? '').toString(),
      _textFromNested(item, 'payload', const [
        'body',
        'content',
        'text',
        'body_html',
      ]),
      (item['excerpt'] ?? '').toString(),
      (item['summary'] ?? '').toString(),
      (item['description'] ?? '').toString(),
    ]);
    final clean = body
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length <= 160) return clean;
    return '${clean.substring(0, 157).trim()}...';
  }

  static String _textFromNested(
    Map<String, dynamic> item,
    String key,
    List<String> fields,
  ) {
    final raw = item[key];
    if (raw is! Map) return '';
    return _firstNonEmpty(fields.map((field) {
      return (raw[field] ?? '').toString();
    }).toList());
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final s = value.trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  static String? _pickImage(Map<String, dynamic> item) {
    const keys = [
      'cover_image_url',
      'image_url',
      'card_image_url',
      'background_image_url',
      'cover_image',
      'cover_url',
      'banner_url',
      'featured_image',
      'thumbnail_url',
      'thumbnail',
      'image',
      'imageUrl',
      'poster',
      'photo',
      'cover_asset_url',
      'file_url',
    ];

    for (final source in [
      item,
      _asMap(item['payload']),
      _asMap(item['media']),
      _asMap(item['meta']),
      _asMap(item['cover']),
    ]) {
      if (source == null) continue;

      for (final key in keys) {
        final value = source[key];
        final s = value?.toString().trim() ?? '';
        if (_looksLikeImageUrl(s)) return s;
      }
    }

    return null;
  }

  static String _resolvePillText(
    Map<String, dynamic> item, {
    required String fallback,
  }) {
    for (final value in [
      item['pill_text'],
      item['badge'],
      item['label'],
      item['category'],
      item['type'],
    ]) {
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s.toUpperCase();
    }

    final meta = _asMap(item['meta']);
    if (meta != null) {
      for (final key in ['pill_text', 'badge', 'label', 'category', 'type']) {
        final value = meta[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s.toUpperCase();
      }
    }

    return fallback;
  }

  static bool _looksLikeImageUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return false;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return true;
    if (raw.startsWith('assets/')) return true;
    return raw.contains('/storage/') ||
        raw.contains('/uploads/') ||
        raw.contains('/images/') ||
        raw.endsWith('.jpg') ||
        raw.endsWith('.jpeg') ||
        raw.endsWith('.png') ||
        raw.endsWith('.webp');
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.map((key, value) => MapEntry('$key', value));
    return null;
  }
}
