import 'package:flutter/material.dart';

abstract class BrandConfig {
  const BrandConfig();

  // Identity
  String get appName;
  String get appTagline;
  String get appSlug;
  String get appToken;

  // Network
  String get apiBaseUrl;

  // Brand colors
  Color get primaryBrandColor;
  Color get secondaryBrandColor;
  Color get accentColor;
  Color get softAccentColor;

  // Fallback labels
  String get liveTitle;
  String get homeSodTitle;
  String get homeArticlesTitle;
  String get homeHighlightsTitle;
  String get commandingDayTitle;
  String get heroDefaultTitle;
  String get heroDefaultSubtitle;
}
