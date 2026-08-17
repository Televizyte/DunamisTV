import 'package:flutter/material.dart';

import 'brands/brand_config.dart';
import 'brands/dunamis_brand.dart';
import 'core/config/backend_environment.dart';

class AppConfig {
  AppConfig._();

  static BrandConfig _brand = DunamisBrandConfig.instance;

  static BrandConfig get brand => _brand;

  static void setBrand(BrandConfig config) {
    _brand = config;
  }

  static const bool useTestAds = false;
  static const bool enableBannerOnSafeScreens = true;
  static const bool enableInterstitialOnSafeNavigation = true;
  static const bool enableNativeAdsInLists = true;
  static const bool enableRewardedAds = false;
  static const int interstitialEveryNClicks = 4;

  static String get appName => _brand.appName;
  static String get appTagline => _brand.appTagline;
  static String get appSlug => _brand.appSlug;
  static String get appToken => _brand.appToken;

  static bool get isDunamis => appSlug == 'dunamis-tv';
  static bool get isCelebration => appSlug == 'celebration-tv';

  static String get apiBaseUrl =>
      isDunamis ? BackendEnvironment.active.apiBaseUrl : _brand.apiBaseUrl;

  static String get hubBootstrapUrl =>
      '$apiBaseUrl/api/v1/apps/$appSlug/bootstrap';

  static String get contentBaseUrl =>
      '$apiBaseUrl/api/v1/apps/$appSlug/content';

  static String articleShareUrl(String idOrSlug) =>
      '$apiBaseUrl/share/$appSlug/articles/${Uri.encodeComponent(idOrSlug)}';

  static String shortShareUrl(String idOrSlug) =>
      '$apiBaseUrl/share/$appSlug/shorts/${Uri.encodeComponent(idOrSlug)}';

  static String get watchUrl => '$apiBaseUrl/api/v1/apps/$appSlug/watch';

  static String get routesUrl => '$apiBaseUrl/api/v1/apps/$appSlug/routes';

  static String get hubBaseUrl => '$apiBaseUrl/api/v1/apps/$appSlug/hub';

  static String hubTabUrl(String tab) => '$hubBaseUrl?tab=$tab';

  static String contentListUrl({
    String tab = 'inspire',
    String? bucket,
    int page = 1,
    int perPage = 20,
    String? type,
  }) {
    final qp = <String>[
      'tab=$tab',
      'page=$page',
      'per_page=$perPage',
      if (bucket != null && bucket.trim().isNotEmpty) 'bucket=$bucket',
      if (type != null && type.trim().isNotEmpty) 'type=$type',
    ].join('&');

    return '$contentBaseUrl?$qp';
  }

  static String contentDetailUrl(
    String idOrSlug, {
    String tab = 'inspire',
  }) {
    return '$contentBaseUrl/$idOrSlug?tab=$tab';
  }

  static int get primaryNavy => _brand.primaryBrandColor.value;
  static int get primaryPurple => _brand.secondaryBrandColor.value;
  static int get accentPink => _brand.accentColor.value;
  static int get softLilac => _brand.softAccentColor.value;

  static Color get primaryNavyColor => _brand.primaryBrandColor;
  static Color get primaryPurpleColor => _brand.secondaryBrandColor;
  static Color get accentPinkColor => _brand.accentColor;
  static Color get softLilacColor => _brand.softAccentColor;

  static Color get appBackgroundDark => const Color(0xFF0B1020);
  static Color get cardBackgroundDark => const Color(0xFF0D1228);

  static String get tabHomeLabel => 'Home';
  static String get tabWatchLabel => 'Watch';
  static String get tabInspireLabel => 'Inspire';
  static String get tabExploreLabel => 'Explore';
  static String get tabMoreLabel => 'More';

  static String get quickAccessLabel => 'Quick Access';
  static String get quickToolsLabel => 'Quick Tools';
  static String get watchChannelsLabel => 'Watch Channels';
  static String get prayerBroadcastLabel => 'Prayer Broadcast';
  static String get todaysScriptureLabel => "Today's Scripture";
  static String get dailyQuoteLabel => 'Daily Quote';

  static String get inspireEmptyTitle => 'No Inspire sections yet';
  static String get inspireEmptySubtitle =>
      'AppsHub will publish Inspire sections here automatically.';

  static String get liveTitle => _brand.liveTitle;
  static String get homeSodTitle => _brand.homeSodTitle;
  static String get homeArticlesTitle => _brand.homeArticlesTitle;
  static String get homeHighlightsTitle => _brand.homeHighlightsTitle;
  static String get commandingDayTitle => _brand.commandingDayTitle;
  static String get heroDefaultTitle => _brand.heroDefaultTitle;
  static String get heroDefaultSubtitle => _brand.heroDefaultSubtitle;
}
