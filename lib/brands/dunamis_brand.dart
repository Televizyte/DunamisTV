import 'package:flutter/material.dart';

import 'brand_config.dart';

class DunamisBrandConfig extends BrandConfig {
  const DunamisBrandConfig();

  static const DunamisBrandConfig instance = DunamisBrandConfig();

  @override
  String get appName => 'Dunamis TV';

  @override
  String get appTagline => 'Digitxtra Media Apps';

  @override
  String get appSlug => 'dunamis-tv';

  @override
  String get appToken =>
      'YXyY05lF4tEmqMXhNVnHhduF8pggT3AyoFfzln1pjRZopp0Bzr120kWgdaiO';

  @override
  String get apiBaseUrl => 'https://admin.appshub.digitxtramedia.com';

  @override
  Color get primaryBrandColor => const Color(0xFF0B0F2A);

  @override
  Color get secondaryBrandColor => const Color(0xFF4B1D8A);

  @override
  Color get accentColor => const Color(0xFFE4007C);

  @override
  Color get softAccentColor => const Color(0xFFE9D9FF);

  @override
  String get liveTitle => 'Dunamis TV Live';

  @override
  String get homeSodTitle => 'SEED of Destiny';

  @override
  String get homeArticlesTitle => 'Inside Dunamis';

  @override
  String get homeHighlightsTitle => 'Message Highlight';

  @override
  String get commandingDayTitle => 'Commanding The Day Prayer Broadcast';

  @override
  String get heroDefaultTitle => 'Dunamis TV';

  @override
  String get heroDefaultSubtitle => 'Watch • Read • Be Inspired';
}
