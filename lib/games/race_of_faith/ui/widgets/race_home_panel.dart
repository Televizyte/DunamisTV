import 'package:flutter/material.dart';

import '../../config/race_game_config.dart';
import '../../state/race_game_controller.dart';

class RaceHomePanel extends StatelessWidget {
  final RaceGameConfig config;
  final RaceGameController controller;
  final VoidCallback onStart;
  final VoidCallback onChooseLevels;

  const RaceHomePanel({
    super.key,
    required this.config,
    required this.controller,
    required this.onStart,
    required this.onChooseLevels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = config.theme;
    final selected = controller.currentLevel;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: theme.heroGradient,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: theme.actionGradient,
                  boxShadow: [
                    BoxShadow(
                      color: theme.dangerPink.withOpacity(0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.directions_run_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Run through faith stages, avoid fear and doubt, collect light, word, cross, crown, and shield rewards, then unlock the next level.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatCard(
                  label: 'Best Score',
                  value: controller.bestScore.toString(),
                  icon: Icons.emoji_events_rounded),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Unlocked',
                  value: 'Level ${controller.unlockedLevel}',
                  icon: Icons.lock_open_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                  label: 'Total Light',
                  value: controller.totalLight.toString(),
                  icon: Icons.lightbulb_rounded),
              const SizedBox(width: 10),
              _StatCard(
                  label: 'Completed',
                  value: '${controller.completedLevels.length}',
                  icon: Icons.verified_rounded),
            ],
          ),
          const SizedBox(height: 14),
          _SelectedLevelCard(
            theme: theme,
            level: selected,
            bestScore: controller.bestScoreForLevel(selected.number),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: theme.actionGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'Start Level ${selected.number}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.18)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: onChooseLevels,
            icon: const Icon(Icons.grid_view_rounded),
            label: Text(
              'Open Full Level Selector · ${controller.maxAvailableLevel} levels',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 16),
          _LevelPreview(controller: controller, theme: theme),
          const SizedBox(height: 14),
          _InstructionGrid(theme: theme),
        ],
      ),
    );
  }
}

class _SelectedLevelCard extends StatelessWidget {
  final RaceThemeConfig theme;
  final RaceLevelConfig level;
  final int bestScore;

  const _SelectedLevelCard({
    required this.theme,
    required this.level,
    required this.bestScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.lightCyan.withOpacity(0.13)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: theme.actionGradient,
            ),
            child: Center(
              child: Text(
                level.number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${level.pathName} · ${level.targetLabel} target · 3 lives',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (bestScore > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Best on this level: $bestScore',
                    style: TextStyle(
                      color: theme.crownGold.withOpacity(0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelPreview extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;

  const _LevelPreview({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    final preview = controller.levels.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Level Preview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: preview.map((level) {
            final unlocked = controller.isLevelUnlocked(level.number);
            final selected = controller.selectedLevel == level.number;
            final completed = controller.isLevelCompleted(level.number);
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap:
                  unlocked ? () => controller.selectLevel(level.number) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 132,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.14)
                      : Colors.black.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? theme.crownGold.withOpacity(0.55)
                        : Colors.white.withOpacity(0.07),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          completed
                              ? Icons.verified_rounded
                              : unlocked
                                  ? Icons.flag_rounded
                                  : Icons.lock_rounded,
                          color: completed
                              ? theme.lightCyan
                              : unlocked
                                  ? theme.crownGold
                                  : Colors.white38,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Level ${level.number}',
                          style: TextStyle(
                            color: unlocked ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      unlocked ? level.title : 'Locked',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unlocked
                            ? Colors.white.withOpacity(0.72)
                            : Colors.white38,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unlocked ? level.targetLabel : 'Complete previous',
                      style: TextStyle(
                        color: unlocked
                            ? theme.lightCyan.withOpacity(0.82)
                            : Colors.white30,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.56), fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionGrid extends StatelessWidget {
  final RaceThemeConfig theme;

  const _InstructionGrid({required this.theme});

  @override
  Widget build(BuildContext context) {
    const blessings = [
      (Icons.lightbulb_rounded, 'Light', '+Light'),
      (Icons.menu_book_rounded, 'Word', '+Word'),
      (Icons.add_rounded, 'Cross', '+Grace'),
      (Icons.workspace_premium_rounded, 'Crown', '+Crown'),
      (Icons.shield_rounded, 'Shield', 'Protects life'),
    ];

    const dangers = [
      (Icons.psychology_alt_rounded, 'Fear', '-1 Life'),
      (Icons.help_outline_rounded, 'Doubt', '-1 Life'),
      (Icons.visibility_off_rounded, 'Distraction', '-1 Life'),
      (Icons.inventory_2_rounded, 'Burden', '-1 Life'),
      (Icons.warning_rounded, 'Temptation', '-1 Life'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faith Items',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        _GuideWrap(items: blessings, theme: theme, danger: false),
        const SizedBox(height: 14),
        const Text(
          'Obstacles to Avoid',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        _GuideWrap(items: dangers, theme: theme, danger: true),
      ],
    );
  }
}

class _GuideWrap extends StatelessWidget {
  final List<(IconData, String, String)> items;
  final RaceThemeConfig theme;
  final bool danger;

  const _GuideWrap({
    required this.items,
    required this.theme,
    required this.danger,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final accent = danger ? theme.dangerPink : theme.crownGold;
        return Container(
          width: 137,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              Icon(item.$1, color: accent, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
