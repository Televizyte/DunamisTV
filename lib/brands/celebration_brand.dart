import 'package:flutter/material.dart';

import 'brand_config.dart';

class CelebrationBrandConfig extends BrandConfig {
  const CelebrationBrandConfig();

  static const CelebrationBrandConfig instance = CelebrationBrandConfig();

  @override
  String get appName => 'Celebration TV';

  @override
  String get appTagline => 'Digitxtra Media Apps';

  @override
  String get appSlug => 'celebration-tv';

  @override
  String get appToken => '';

  @override
  String get apiBaseUrl => 'https://admin.apps.digitxtramedia.com';

  @override
  Color get primaryBrandColor => const Color(0xFF0B0F2A);

  @override
  Color get secondaryBrandColor => const Color(0xFF4B1D8A);

  @override
  Color get accentColor => const Color(0xFFE4007C);

  @override
  Color get softAccentColor => const Color(0xFFE9D9FF);

  @override
  String get liveTitle => 'Celebration TV Live';

  @override
  String get homeSodTitle => 'Daily Devotional';

  @override
  String get homeArticlesTitle => 'Featured Articles';

  @override
  String get homeHighlightsTitle => 'Message Highlight';

  @override
  String get commandingDayTitle => 'Prayer Broadcast';

  @override
  String get heroDefaultTitle => 'Celebration TV';

  @override
  String get heroDefaultSubtitle => 'Watch • Read • Be Inspired';
}
