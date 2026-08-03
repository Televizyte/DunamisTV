import 'package:flutter/material.dart';

@immutable
class KingdomBuilderConfig {
  final String gameKey;
  final String displayName;
  final String routePath;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final int offlineCapMinutes;

  const KingdomBuilderConfig({
    this.gameKey = 'kingdom_builder',
    this.displayName = 'Kingdom Builder',
    this.routePath = '/games/kingdom-builder',
    this.primaryColor = const Color(0xFF102A43),
    this.secondaryColor = const Color(0xFF244F78),
    this.accentColor = const Color(0xFFC8952E),
    this.offlineCapMinutes = 360,
  });

  KingdomBuilderConfig copyWith({
    String? displayName,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    int? offlineCapMinutes,
  }) {
    return KingdomBuilderConfig(
      gameKey: gameKey,
      displayName: displayName ?? this.displayName,
      routePath: routePath,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      offlineCapMinutes: offlineCapMinutes ?? this.offlineCapMinutes,
    );
  }
}
