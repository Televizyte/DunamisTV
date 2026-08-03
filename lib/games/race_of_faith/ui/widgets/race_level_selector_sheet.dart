import 'package:flutter/material.dart';

import 'package:dunamis_tv/services/ads_service.dart';
import 'package:dunamis_tv/ui/widgets/ads/native_inline_ad_tile.dart';

import '../../config/race_game_config.dart';
import '../../state/race_game_controller.dart';

class RaceLevelSelectorSheet extends StatelessWidget {
  final RaceGameController controller;
  final RaceThemeConfig theme;
  final String adsTabKey;

  const RaceLevelSelectorSheet({
    super.key,
    required this.controller,
    required this.theme,
    required this.adsTabKey,
  });

  static Future<void> show(
    BuildContext context, {
    required RaceGameController controller,
    required RaceThemeConfig theme,
    required String adsTabKey,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return RaceLevelSelectorSheet(
            controller: controller,
            theme: theme,
            adsTabKey: adsTabKey,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.55,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10172D),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.38),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: theme.actionGradient,
                        ),
                        child:
                            const Icon(Icons.flag_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choose Race Level',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${controller.unlockedLevel} unlocked · ${controller.completedLevels.length} completed · ${controller.maxAvailableLevel} available',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.58),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (AdsService.instance.nativeAllowedForTab(adsTabKey))
                  NativeInlineAdTile(
                    tabKey: adsTabKey,
                    label: 'Race Level Sponsored',
                    minHeight: 92,
                    margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                    itemCount: controller.levels.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.82,
                    ),
                    itemBuilder: (context, index) {
                      final level = controller.levels[index];
                      return _LevelTile(
                        level: level,
                        theme: theme,
                        unlocked: controller.isLevelUnlocked(level.number),
                        selected: controller.selectedLevel == level.number,
                        completed: controller.isLevelCompleted(level.number),
                        bestScore: controller.bestScoreForLevel(level.number),
                        onTap: () async {
                          await controller.selectLevel(level.number);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final RaceLevelConfig level;
  final RaceThemeConfig theme;
  final bool unlocked;
  final bool selected;
  final bool completed;
  final int bestScore;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.theme,
    required this.unlocked,
    required this.selected,
    required this.completed,
    required this.bestScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: unlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: selected ? theme.heroGradient : null,
          color: selected ? null : Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? theme.crownGold.withOpacity(0.62)
                : completed
                    ? theme.lightCyan.withOpacity(0.34)
                    : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Opacity(
          opacity: unlocked ? 1 : 0.48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            : Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Level ${level.number}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                unlocked ? level.title : 'Locked',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.84),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Text(
                unlocked
                    ? '${level.targetLabel} · ${bestScore > 0 ? 'Best $bestScore' : level.pathName}'
                    : 'Complete previous level',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: unlocked
                      ? theme.lightCyan.withOpacity(0.82)
                      : Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
