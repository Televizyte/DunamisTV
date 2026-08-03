import 'package:flutter/material.dart';

@immutable
class RaceGameConfig {
  final String appSlug;
  final String gameKey;
  final String title;
  final String subtitle;
  final String routePath;
  final String adsTabKey;
  final RaceThemeConfig theme;
  final int maxGeneratedLevel;

  const RaceGameConfig({
    this.appSlug = 'dunamis-tv',
    this.gameKey = 'race_of_faith',
    this.title = 'Race of Faith',
    this.subtitle =
        'Run with focus, dodge obstacles, collect light, and finish strong.',
    this.routePath = '/games/race-of-faith',
    this.adsTabKey = 'game.race_of_faith',
    this.theme = const RaceThemeConfig(),
    this.maxGeneratedLevel = 60,
  });

  RaceGameConfig copyWith({
    String? appSlug,
    String? gameKey,
    String? title,
    String? subtitle,
    String? routePath,
    String? adsTabKey,
    RaceThemeConfig? theme,
    int? maxGeneratedLevel,
  }) {
    return RaceGameConfig(
      appSlug: appSlug ?? this.appSlug,
      gameKey: gameKey ?? this.gameKey,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      routePath: routePath ?? this.routePath,
      adsTabKey: adsTabKey ?? this.adsTabKey,
      theme: theme ?? this.theme,
      maxGeneratedLevel: maxGeneratedLevel ?? this.maxGeneratedLevel,
    );
  }
}

@immutable
class RaceStageConfig {
  final int index;
  final String name;
  final String environmentName;
  final String subtitle;
  final Color skyTop;
  final Color skyBottom;
  final Color roadGlow;
  final Color accent;
  final double speedMultiplier;
  final double densityMultiplier;
  final List<String> featuredItems;

  const RaceStageConfig({
    required this.index,
    required this.name,
    required this.environmentName,
    required this.subtitle,
    required this.skyTop,
    required this.skyBottom,
    required this.roadGlow,
    required this.accent,
    required this.speedMultiplier,
    required this.densityMultiplier,
    required this.featuredItems,
  });

  static RaceStageConfig forLevel(int level) {
    final stage = _stageIndexForLevel(level);
    switch (stage) {
      case 0:
        return const RaceStageConfig(
          index: 0,
          name: 'Beginner Faith Path',
          environmentName: 'Faith Path',
          subtitle: 'Simple rhythm, light orbs, and basic barriers.',
          skyTop: Color(0xFF071B38),
          skyBottom: Color(0xFF211047),
          roadGlow: Color(0xFF32E3FF),
          accent: Color(0xFFFFC857),
          speedMultiplier: 1.0,
          densityMultiplier: 1.0,
          featuredItems: ['LIGHT', 'WORD', 'JUMP'],
        );
      case 1:
        return const RaceStageConfig(
          index: 1,
          name: 'Riverside Path',
          environmentName: 'Riverside',
          subtitle: 'More light, faster water-flow rhythm, and tighter lanes.',
          skyTop: Color(0xFF062C46),
          skyBottom: Color(0xFF073B50),
          roadGlow: Color(0xFF37F3E8),
          accent: Color(0xFF70F7C8),
          speedMultiplier: 1.12,
          densityMultiplier: 1.18,
          featuredItems: ['LIGHT', 'CROSS', 'MOVE'],
        );
      case 2:
        return const RaceStageConfig(
          index: 2,
          name: 'Mountain Trail',
          environmentName: 'Mountain',
          subtitle: 'Higher pressure, more jump timing, and stronger focus.',
          skyTop: Color(0xFF0A1731),
          skyBottom: Color(0xFF2E2259),
          roadGlow: Color(0xFF8C7BFF),
          accent: Color(0xFFD8D4FF),
          speedMultiplier: 1.24,
          densityMultiplier: 1.34,
          featuredItems: ['WORD', 'CROSS', 'FEAR'],
        );
      case 3:
        return const RaceStageConfig(
          index: 3,
          name: 'City Road',
          environmentName: 'City',
          subtitle: 'Lane discipline, distractions, and quicker decisions.',
          skyTop: Color(0xFF071B2F),
          skyBottom: Color(0xFF271242),
          roadGlow: Color(0xFFFF2DA1),
          accent: Color(0xFF32E3FF),
          speedMultiplier: 1.36,
          densityMultiplier: 1.50,
          featuredItems: ['CROWN', 'MOVE', 'DISTRACTION'],
        );
      case 4:
        return const RaceStageConfig(
          index: 4,
          name: 'Valley Run',
          environmentName: 'Valley',
          subtitle: 'Mixed rewards, wider patterns, and endurance pressure.',
          skyTop: Color(0xFF132A22),
          skyBottom: Color(0xFF4A2D16),
          roadGlow: Color(0xFFFFC857),
          accent: Color(0xFF70F7C8),
          speedMultiplier: 1.48,
          densityMultiplier: 1.68,
          featuredItems: ['LIGHT', 'CROWN', 'BURDEN'],
        );
      case 5:
        return const RaceStageConfig(
          index: 5,
          name: 'Desert Endurance',
          environmentName: 'Desert',
          subtitle: 'Fewer easy pickups, hotter pace, and heavier obstacles.',
          skyTop: Color(0xFF2F1B08),
          skyBottom: Color(0xFF4A1230),
          roadGlow: Color(0xFFFF9F45),
          accent: Color(0xFFFFD37A),
          speedMultiplier: 1.62,
          densityMultiplier: 1.84,
          featuredItems: ['CROSS', 'DOUBT', 'BURDEN'],
        );
      case 6:
        return const RaceStageConfig(
          index: 6,
          name: 'Royal Road',
          environmentName: 'Royal Road',
          subtitle: 'Crowns, scrolls, and a faster royal challenge.',
          skyTop: Color(0xFF170A35),
          skyBottom: Color(0xFF3D1A63),
          roadGlow: Color(0xFFFFC857),
          accent: Color(0xFFFFD86B),
          speedMultiplier: 1.78,
          densityMultiplier: 2.02,
          featuredItems: ['CROWN', 'WORD', 'FEAR'],
        );
      case 7:
        return const RaceStageConfig(
          index: 7,
          name: 'Storm Path',
          environmentName: 'Storm',
          subtitle: 'Sharper danger, storm visuals, and stronger reactions.',
          skyTop: Color(0xFF07111F),
          skyBottom: Color(0xFF101A3F),
          roadGlow: Color(0xFF7EA7FF),
          accent: Color(0xFFFF4F93),
          speedMultiplier: 1.95,
          densityMultiplier: 2.20,
          featuredItems: ['SHIELD', 'TEMPTATION', 'FEAR'],
        );
      default:
        return const RaceStageConfig(
          index: 8,
          name: 'Glory Path',
          environmentName: 'Glory',
          subtitle: 'High speed, strong light, and champion-level focus.',
          skyTop: Color(0xFF10132D),
          skyBottom: Color(0xFF4A1F70),
          roadGlow: Color(0xFFFFF0A3),
          accent: Color(0xFFFFF4C4),
          speedMultiplier: 2.16,
          densityMultiplier: 2.42,
          featuredItems: ['LIGHT', 'CROSS', 'CROWN', 'SHIELD'],
        );
    }
  }

  static int _stageIndexForLevel(int level) {
    if (level <= 5) return 0;
    if (level <= 10) return 1;
    if (level <= 15) return 2;
    if (level <= 20) return 3;
    if (level <= 25) return 4;
    if (level <= 30) return 5;
    if (level <= 40) return 6;
    if (level <= 50) return 7;
    return 8;
  }
}

@immutable
class RaceLevelConfig {
  final int number;
  final String title;
  final String subtitle;
  final double targetMeters;
  final double baseSpeed;
  final double maxSpeed;
  final String rewardTitle;
  final String rewardMessage;
  final String scriptureReference;
  final String pathName;
  final RaceStageConfig stage;

  const RaceLevelConfig({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.targetMeters,
    required this.baseSpeed,
    required this.maxSpeed,
    required this.rewardTitle,
    required this.rewardMessage,
    required this.scriptureReference,
    required this.pathName,
    required this.stage,
  });

  String get targetLabel => '${targetMeters.round()}m';

  static List<RaceLevelConfig> generateLevels([int count = 60]) {
    return List<RaceLevelConfig>.generate(count, (index) {
      final level = index + 1;
      final stage = RaceStageConfig.forLevel(level);
      final tier = stage.index;
      final position = (level - 1) % 10;
      final target = 320.0 + (level * 105.0) + (tier * 185.0);
      final base =
          (265.0 + (level * 10.0) + (tier * 24.0)) * stage.speedMultiplier;
      final max = base + 170.0 + (tier * 44.0) + (position * 9.0);
      return RaceLevelConfig(
        number: level,
        title: _titleForLevel(level, tier, position),
        subtitle: stage.subtitle,
        targetMeters: target.clamp(360.0, 12000.0),
        baseSpeed: base.clamp(265.0, 1450.0),
        maxSpeed: max.clamp(480.0, 1850.0),
        rewardTitle: _rewardTitleForStage(stage),
        rewardMessage: _rewardMessageForStage(stage),
        scriptureReference: _scriptureForLevel(level),
        pathName: stage.name,
        stage: stage,
      );
    });
  }

  static String _titleForLevel(int level, int tier, int position) {
    const firstTen = [
      'The Beginning',
      'Keep Moving',
      'Stay Focused',
      'Endurance Path',
      'Faith Race',
      'Riverside Start',
      'Steady Stream',
      'Clear Crossing',
      'Grace Flow',
      'River Finish',
    ];
    if (level <= firstTen.length) return firstTen[level - 1];
    return '${RaceStageConfig.forLevel(level).environmentName} ${position + 1}';
  }

  static String _rewardTitleForStage(RaceStageConfig stage) {
    switch (stage.index) {
      case 0:
        return 'Good Start';
      case 1:
        return 'Grace Flow';
      case 2:
        return 'Mountain Focus';
      case 3:
        return 'Discipline Runner';
      case 4:
        return 'Valley Endurance';
      case 5:
        return 'Desert Strength';
      case 6:
        return 'Royal Runner';
      case 7:
        return 'Storm Victor';
      default:
        return 'Glory Champion';
    }
  }

  static String _rewardMessageForStage(RaceStageConfig stage) {
    switch (stage.index) {
      case 0:
        return 'You stayed on the path. Keep running with focus.';
      case 1:
        return 'You kept moving with grace and steady rhythm.';
      case 2:
        return 'You climbed higher and stayed focused.';
      case 3:
        return 'You avoided distractions and kept your lane.';
      case 4:
        return 'You endured the valley and kept pressing forward.';
      case 5:
        return 'You ran through pressure with discipline.';
      case 6:
        return 'You ran like a royal champion with purpose.';
      case 7:
        return 'You stayed strong through storm and pressure.';
      default:
        return 'You completed a champion-level faith race.';
    }
  }

  static String _scriptureForLevel(int level) {
    const references = [
      'Hebrews 12:1',
      'Philippians 3:14',
      '1 Corinthians 9:24',
      'James 1:12',
      '2 Timothy 4:7',
      'Isaiah 40:31',
      'Psalm 119:105',
      'Proverbs 4:25',
      'Romans 5:3-4',
      'Galatians 6:9',
    ];
    return references[(level - 1) % references.length];
  }
}

@immutable
class RaceThemeConfig {
  final Color midnight;
  final Color deepBlue;
  final Color royalPurple;
  final Color crownGold;
  final Color lightCyan;
  final Color dangerPink;

  const RaceThemeConfig({
    this.midnight = const Color(0xFF071123),
    this.deepBlue = const Color(0xFF082F5F),
    this.royalPurple = const Color(0xFF43207C),
    this.crownGold = const Color(0xFFFFC857),
    this.lightCyan = const Color(0xFF32E3FF),
    this.dangerPink = const Color(0xFFFF2DA1),
  });

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [midnight, deepBlue, royalPurple],
      );

  LinearGradient get actionGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [lightCyan, dangerPink],
      );
}
