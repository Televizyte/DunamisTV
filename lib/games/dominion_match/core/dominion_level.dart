import 'package:flutter/material.dart';

enum DominionDifficulty { beginner, normal, pro, challenge, endless }

enum DominionWorldType { garden, rescue, hazard, stronghold, crown, endless }

enum DominionMissionType {
  score,
  rescue,
  hazard,
  stronghold,
  crownTrial,
  survival
}

class DominionWorldTheme {
  final DominionWorldType type;
  final String name;
  final String missionTitle;
  final String missionVerb;
  final String story;
  final IconData icon;
  final List<Color> background;
  final Color accentColor;
  final Color warningColor;
  final Color boardColor;
  final String meterLabel;

  const DominionWorldTheme({
    required this.type,
    required this.name,
    required this.missionTitle,
    required this.missionVerb,
    required this.story,
    required this.icon,
    required this.background,
    required this.accentColor,
    required this.warningColor,
    required this.boardColor,
    required this.meterLabel,
  });

  static DominionWorldTheme fromType(DominionWorldType type) {
    return switch (type) {
      DominionWorldType.garden => const DominionWorldTheme(
          type: DominionWorldType.garden,
          name: 'Learning Garden',
          missionTitle: 'Grow the Garden',
          missionVerb: 'Grow faith by matching peaceful tiles.',
          story:
              'A calm training ground where every match waters the garden of faith.',
          icon: Icons.local_florist_rounded,
          background: [Color(0xFF071B2E), Color(0xFF0D3A60), Color(0xFF177C92)],
          accentColor: Color(0xFF38D5FF),
          warningColor: Color(0xFFFFD84D),
          boardColor: Color(0xFF082236),
          meterLabel: 'Growth',
        ),
      DominionWorldType.rescue => const DominionWorldTheme(
          type: DominionWorldType.rescue,
          name: 'Rescue Mission',
          missionTitle: 'Rescue the Light',
          missionVerb: 'Fill the rescue meter before time runs out.',
          story:
              'The trapped light must be rescued through focused matches and combos.',
          icon: Icons.flashlight_on_rounded,
          background: [Color(0xFF090D2B), Color(0xFF321E74), Color(0xFFB70E7C)],
          accentColor: Color(0xFFFF4DB8),
          warningColor: Color(0xFFFFD84D),
          boardColor: Color(0xFF0D1230),
          meterLabel: 'Rescue',
        ),
      DominionWorldType.hazard => const DominionWorldTheme(
          type: DominionWorldType.hazard,
          name: 'Storm Breaker',
          missionTitle: 'Stop the Hazard',
          missionVerb: 'Push the danger back with power matches.',
          story:
              'A rising storm challenges your speed, combos, and special tile timing.',
          icon: Icons.thunderstorm_rounded,
          background: [Color(0xFF1B0B13), Color(0xFF5A1328), Color(0xFFFF7043)],
          accentColor: Color(0xFFFF7043),
          warningColor: Color(0xFFFFD84D),
          boardColor: Color(0xFF1B1119),
          meterLabel: 'Hazard',
        ),
      DominionWorldType.stronghold => const DominionWorldTheme(
          type: DominionWorldType.stronghold,
          name: 'Stronghold Breaker',
          missionTitle: 'Break the Stronghold',
          missionVerb: 'Use special tiles to weaken the shielded board.',
          story:
              'The board becomes tougher. Power tiles and precision are now important.',
          icon: Icons.shield_rounded,
          background: [Color(0xFF080B18), Color(0xFF251C4E), Color(0xFF555C7A)],
          accentColor: Color(0xFF8D6CFF),
          warningColor: Color(0xFFFF7474),
          boardColor: Color(0xFF0B0E1F),
          meterLabel: 'Stronghold',
        ),
      DominionWorldType.crown => const DominionWorldTheme(
          type: DominionWorldType.crown,
          name: 'Crown Challenge',
          missionTitle: 'Win the Royal Trial',
          missionVerb: 'Clear score, combo, and power objectives.',
          story:
              'A premium trial with fewer moves, richer rewards, and harder goals.',
          icon: Icons.workspace_premium_rounded,
          background: [Color(0xFF100A2A), Color(0xFF4A2785), Color(0xFFD7A928)],
          accentColor: Color(0xFFFFD84D),
          warningColor: Color(0xFFFF5B8F),
          boardColor: Color(0xFF130F26),
          meterLabel: 'Crown',
        ),
      DominionWorldType.endless => const DominionWorldTheme(
          type: DominionWorldType.endless,
          name: 'Endless Dominion',
          missionTitle: 'Keep Dominion',
          missionVerb: 'Survive wave after wave as the pressure rises.',
          story:
              'A long-run mode for replay value, streaks, and future daily challenges.',
          icon: Icons.all_inclusive_rounded,
          background: [Color(0xFF020914), Color(0xFF073C64), Color(0xFF00D4FF)],
          accentColor: Color(0xFF00D4FF),
          warningColor: Color(0xFFFFD84D),
          boardColor: Color(0xFF06101E),
          meterLabel: 'Dominion',
        ),
    };
  }
}

class DominionLevel {
  final int stage;
  final DominionDifficulty difficulty;
  final DominionWorldType worldType;
  final DominionMissionType missionType;
  final String title;
  final String label;
  final String packName;
  final String description;
  final int moves;
  final int targetScore;
  final Duration? timeLimit;
  final double dominionChance;
  final double powerTileChance;
  final int tileVariety;
  final int requiredCombo;
  final int requiredPowerActivations;
  final int missionTarget;
  final Color accentColor;

  const DominionLevel({
    required this.stage,
    required this.difficulty,
    required this.worldType,
    required this.missionType,
    required this.title,
    required this.label,
    required this.packName,
    required this.description,
    required this.moves,
    required this.targetScore,
    required this.timeLimit,
    required this.dominionChance,
    required this.powerTileChance,
    required this.tileVariety,
    required this.requiredCombo,
    required this.requiredPowerActivations,
    required this.missionTarget,
    required this.accentColor,
  });

  bool get isTimed => timeLimit != null;
  String get stageLabel => 'Stage $stage';
  DominionWorldTheme get theme => DominionWorldTheme.fromType(worldType);

  int starsForScore(int score) {
    if (score >= (targetScore * 1.45).round()) return 3;
    if (score >= (targetScore * 1.18).round()) return 2;
    if (score >= targetScore) return 1;
    return 0;
  }

  bool objectivesMet({
    required int score,
    required int bestCombo,
    required int powerActivations,
    required int missionProgress,
  }) {
    if (score < targetScore) return false;
    if (bestCombo < requiredCombo) return false;
    if (powerActivations < requiredPowerActivations) return false;
    if (missionProgress < missionTarget) return false;
    return true;
  }

  static DominionLevel forStage(int stage) {
    final safeStage = stage < 1 ? 1 : stage;

    if (safeStage <= 10) {
      final step = safeStage - 1;
      const world = DominionWorldType.garden;
      final theme = DominionWorldTheme.fromType(world);
      return DominionLevel(
        stage: safeStage,
        difficulty: DominionDifficulty.beginner,
        worldType: world,
        missionType: DominionMissionType.score,
        title: 'Beginner Flow',
        label: 'Beginner',
        packName: 'Beginner Flow',
        description:
            'Gentle practice stages with simple targets and calm pacing.',
        moves: 34 - (step ~/ 4),
        targetScore: 900 + (step * 130),
        timeLimit: null,
        dominionChance: 0.012 + (step * 0.0005),
        powerTileChance: 0.018 + (step * 0.0008),
        tileVariety: 5,
        requiredCombo: step >= 5 ? 2 : 1,
        requiredPowerActivations: 0,
        missionTarget: 1,
        accentColor: theme.accentColor,
      );
    }

    if (safeStage <= 25) {
      final step = safeStage - 11;
      const world = DominionWorldType.rescue;
      final theme = DominionWorldTheme.fromType(world);
      return DominionLevel(
        stage: safeStage,
        difficulty: DominionDifficulty.normal,
        worldType: world,
        missionType: DominionMissionType.rescue,
        title: 'Dominion Rise',
        label: 'Rescue',
        packName: 'Dominion Rise',
        description: 'Fill the rescue meter before time and moves run out.',
        moves: 31 - (step ~/ 5),
        targetScore: 1600 + (step * 150),
        timeLimit: Duration(seconds: 185 - (step * 2).clamp(0, 25)),
        dominionChance: 0.016 + (step * 0.0005),
        powerTileChance: 0.035 + (step * 0.0008),
        tileVariety: 6,
        requiredCombo: 2,
        requiredPowerActivations: step >= 8 ? 1 : 0,
        missionTarget: 100,
        accentColor: theme.accentColor,
      );
    }

    if (safeStage <= 50) {
      final step = safeStage - 26;
      const world = DominionWorldType.hazard;
      final theme = DominionWorldTheme.fromType(world);
      return DominionLevel(
        stage: safeStage,
        difficulty: DominionDifficulty.pro,
        worldType: world,
        missionType: DominionMissionType.hazard,
        title: 'Power Run',
        label: 'Hazard',
        packName: 'Power Run',
        description: 'Stop the rising storm with combos and power tiles.',
        moves: 27 - (step ~/ 7),
        targetScore: 2500 + (step * 170),
        timeLimit: Duration(seconds: 150 - (step * 2).clamp(0, 35)),
        dominionChance: 0.020 + (step * 0.00035),
        powerTileChance: 0.050 + (step * 0.00065),
        tileVariety: 7,
        requiredCombo: 3,
        requiredPowerActivations: 1 + (step ~/ 14),
        missionTarget: 100,
        accentColor: theme.accentColor,
      );
    }

    if (safeStage <= 75) {
      final step = safeStage - 51;
      const world = DominionWorldType.stronghold;
      final theme = DominionWorldTheme.fromType(world);
      return DominionLevel(
        stage: safeStage,
        difficulty: DominionDifficulty.challenge,
        worldType: world,
        missionType: DominionMissionType.stronghold,
        title: 'Stronghold Breaker',
        label: 'Stronghold',
        packName: 'Faith Battle',
        description: 'Use power tiles and combos to break shield pressure.',
        moves: 24 - (step ~/ 10),
        targetScore: 3900 + (step * 190),
        timeLimit: Duration(seconds: 130 - (step).clamp(0, 28)),
        dominionChance: 0.027 + (step * 0.00025),
        powerTileChance: 0.070 + (step * 0.00045),
        tileVariety: 8,
        requiredCombo: 3 + (step ~/ 12),
        requiredPowerActivations: 2,
        missionTarget: 100,
        accentColor: theme.accentColor,
      );
    }

    if (safeStage <= 100) {
      final step = safeStage - 76;
      const world = DominionWorldType.crown;
      final theme = DominionWorldTheme.fromType(world);
      return DominionLevel(
        stage: safeStage,
        difficulty: DominionDifficulty.challenge,
        worldType: world,
        missionType: DominionMissionType.crownTrial,
        title: 'Crown Challenge',
        label: 'Crown',
        packName: 'Crown Challenge',
        description: 'Royal trial stages with fewer moves and multiple goals.',
        moves: 22 - (step ~/ 10),
        targetScore: 5100 + (step * 230),
        timeLimit: Duration(seconds: 115 - (step).clamp(0, 28)),
        dominionChance: 0.032 + (step * 0.00025),
        powerTileChance: 0.085 + (step * 0.00035),
        tileVariety: 9,
        requiredCombo: 4,
        requiredPowerActivations: 2 + (step ~/ 14),
        missionTarget: 100,
        accentColor: theme.accentColor,
      );
    }

    const world = DominionWorldType.endless;
    final theme = DominionWorldTheme.fromType(world);
    return DominionLevel(
      stage: safeStage,
      difficulty: DominionDifficulty.endless,
      worldType: world,
      missionType: DominionMissionType.survival,
      title: 'Endless Dominion',
      label: 'Endless',
      packName: 'Endless Dominion',
      description:
          'Long-run survival stage for replay value and future daily challenges.',
      moves: 22,
      targetScore: 9800 + ((safeStage - 101) * 260),
      timeLimit: const Duration(seconds: 95),
      dominionChance: 0.038,
      powerTileChance: 0.095,
      tileVariety: 9,
      requiredCombo: 5,
      requiredPowerActivations: 3,
      missionTarget: 100,
      accentColor: theme.accentColor,
    );
  }

  static DominionLevel get beginner => forStage(1);

  static List<DominionLevel> get featuredLevels => <DominionLevel>[
        forStage(1),
        forStage(5),
        forStage(11),
        forStage(26),
        forStage(51),
        forStage(76),
        forStage(101),
      ];

  static List<DominionLevel> get all => featuredLevels;
}
