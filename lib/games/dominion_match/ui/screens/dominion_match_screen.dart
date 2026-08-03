import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/widgets/banner_ad_widget.dart';
import '../../../../ui/widgets/gradient_page_background.dart';
import '../../core/dominion_level.dart';
import '../../state/dominion_match_controller.dart';
import '../widgets/dominion_feedback_overlay.dart';
import '../widgets/dominion_game_board.dart';
import '../widgets/dominion_scripture_dialog.dart';
import '../widgets/dominion_stats_bar.dart';

class DominionMatchScreen extends StatefulWidget {
  const DominionMatchScreen({super.key});

  @override
  State<DominionMatchScreen> createState() => _DominionMatchScreenState();
}

class _DominionMatchScreenState extends State<DominionMatchScreen> {
  late final DominionMatchController controller;

  @override
  void initState() {
    super.initState();
    controller = DominionMatchController();
    controller.addListener(_handleControllerUpdate);
  }

  void _handleControllerUpdate() {
    if (!mounted) return;
    if (controller.stage == DominionGameStage.result &&
        !controller.resultDialogShown) {
      controller.markResultDialogShown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDominionScriptureDialog(
          context: context,
          scripture: controller.scripture,
          victory: controller.isVictory,
          onContinue: controller.continueAfterResult,
          onRetry: controller.restart,
        );
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final showBanner = controller.stage != DominionGameStage.playing;
        final theme = controller.level.theme;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.background.first,
            leading: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/explore');
                }
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
            title: Text(
              controller.stage == DominionGameStage.playing
                  ? '${theme.name} • Stage ${controller.level.stage}'
                  : 'Dominion Match',
            ),
            actions: [
              IconButton(
                tooltip: controller.soundEnabled
                    ? 'Mute sound effects'
                    : 'Enable sound effects',
                onPressed: controller.toggleSound,
                icon: Icon(
                  controller.soundEnabled
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                ),
              ),
              IconButton(
                tooltip:
                    controller.musicEnabled ? 'Mute music' : 'Enable music',
                onPressed: controller.toggleMusic,
                icon: Icon(
                  controller.musicEnabled
                      ? Icons.music_note_rounded
                      : Icons.music_off_rounded,
                ),
              ),
              if (controller.stage == DominionGameStage.playing)
                IconButton(
                  tooltip: 'Restart stage',
                  onPressed: controller.isBusy ? null : controller.restart,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              IconButton(
                tooltip: 'Stages',
                onPressed: () => _showLevelSheet(context),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.background,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: GradientPageBackground(
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: switch (controller.stage) {
                        DominionGameStage.intro => _IntroView(
                            key: ValueKey('intro_${controller.level.stage}'),
                            controller: controller,
                            onChooseStage: () => _showLevelSheet(context),
                          ),
                        DominionGameStage.playing => _GameplayView(
                            key: ValueKey('playing_${controller.level.stage}'),
                            controller: controller,
                          ),
                        DominionGameStage.result => _ResultView(
                            key: ValueKey('result_${controller.level.stage}'),
                            controller: controller,
                            onRewardTap: () => showDominionScriptureDialog(
                              context: context,
                              scripture: controller.scripture,
                              victory: controller.isVictory,
                              onContinue: controller.continueAfterResult,
                              onRetry: controller.restart,
                            ),
                          ),
                      },
                    ),
                  ),
                  if (showBanner)
                    const SafeArea(
                      top: false,
                      child: BannerAdWidget(tabKey: 'explore.games'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLevelSheet(BuildContext context) {
    final theme = controller.level.theme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF11172E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.44,
          maxChildSize: 0.94,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.accentColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(theme.icon, color: theme.accentColor),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Choose Stage World',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Each world changes the mission, board mood, pressure, rewards, and difficulty flow.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.64),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._availableLevelChoices().map((level) {
                    final selected = controller.level.stage == level.stage;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _LevelTile(
                        level: level,
                        selected: selected,
                        locked: level.stage > controller.bestUnlockedStage + 6,
                        onTap: () {
                          if (controller.stage == DominionGameStage.playing) {
                            controller.startStage(level);
                          } else {
                            controller.chooseLevel(level);
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<DominionLevel> _availableLevelChoices() {
    const stages = <int>[
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      15,
      20,
      25,
      26,
      30,
      40,
      50,
      51,
      60,
      75,
      76,
      90,
      100,
      101,
    ];
    return stages.map(DominionLevel.forStage).toList(growable: false);
  }
}

class _IntroView extends StatelessWidget {
  final DominionMatchController controller;
  final VoidCallback onChooseStage;

  const _IntroView({
    super.key,
    required this.controller,
    required this.onChooseStage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = controller.level.theme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      children: [
        _WorldHeroCard(
          level: controller.level,
          scriptureTitle: controller.scripture.title,
          scriptureText: controller.scripture.text,
          reference: controller.scripture.reference,
          onChooseStage: onChooseStage,
          onStart: controller.startGame,
        ),
        const SizedBox(height: 14),
        _MissionCard(
          level: controller.level,
          objectiveSummary: controller.objectiveSummary,
        ),
        const SizedBox(height: 14),
        _PreviewBoard(theme: theme),
        const SizedBox(height: 14),
        const _RulesCard(),
      ],
    );
  }
}

class _GameplayView extends StatelessWidget {
  final DominionMatchController controller;

  const _GameplayView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = controller.level.theme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            DominionStatsBar(
              score: controller.score,
              movesLeft: controller.movesLeft,
              combo: controller.combo,
              powerActivations: controller.powerActivations,
              level: controller.level,
              timeLeft: controller.timeLeft,
              scoreProgress: controller.progress,
              missionProgress: controller.missionPercent,
            ),
            const SizedBox(height: 9),
            _MissionStatusLine(controller: controller),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    DominionGameBoard(
                      board: controller.board,
                      selectedPoint: controller.selectedPoint,
                      busy: controller.isBusy,
                      theme: theme,
                      shakeSeed: controller.boardShakeSeed,
                      flashSeed: controller.boardFlashSeed,
                      lowTimePulse: controller.lowTimePulse,
                      onTileTap: controller.tapTile,
                    ),
                    Positioned.fill(
                      child: DominionFeedbackOverlay(
                        message: controller.feedbackText,
                        kind: controller.feedbackKind,
                        seed: controller.feedbackSeed,
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.isBusy ? null : controller.restart,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Restart'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        controller.isBusy ? null : controller.backToIntro,
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Intro'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final DominionMatchController controller;
  final VoidCallback onRewardTap;

  const _ResultView({
    super.key,
    required this.controller,
    required this.onRewardTap,
  });

  @override
  Widget build(BuildContext context) {
    final victory = controller.isVictory;
    final theme = controller.level.theme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: victory
                  ? theme.background
                  : const [
                      Color(0xFF17213D),
                      Color(0xFF2F255E),
                      Color(0xFF5B164A),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Pill(
                icon:
                    victory ? Icons.emoji_events_rounded : Icons.replay_rounded,
                label: victory
                    ? '${theme.name.toUpperCase()} CLEARED'
                    : 'ENCOURAGEMENT',
              ),
              const SizedBox(height: 18),
              Text(
                victory
                    ? 'Stage ${controller.level.stage} Cleared'
                    : 'Rise Again',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 29,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score: ${controller.score} / ${controller.level.targetScore} • Best combo x${controller.bestCombo <= 0 ? 1 : controller.bestCombo} • Power ${controller.powerActivations}/${controller.level.requiredPowerActivations}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (victory) ...[
                const SizedBox(height: 8),
                Row(
                  children: List.generate(3, (index) {
                    return Icon(
                      index < controller.stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFFFD84D),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 18),
              _ScriptureTopCard(
                scriptureTitle: controller.scripture.title,
                scriptureText: controller.scripture.text,
                reference: controller.scripture.reference,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.continueAfterResult,
                      icon: Icon(victory
                          ? Icons.arrow_forward_rounded
                          : Icons.refresh_rounded),
                      label: Text(victory ? 'Next Stage' : 'Repeat Stage'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRewardTap,
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('Reward'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorldHeroCard extends StatelessWidget {
  final DominionLevel level;
  final String scriptureTitle;
  final String scriptureText;
  final String reference;
  final VoidCallback onChooseStage;
  final VoidCallback onStart;

  const _WorldHeroCard({
    required this.level,
    required this.scriptureTitle,
    required this.scriptureText,
    required this.reference,
    required this.onChooseStage,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = level.theme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: theme.background,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withOpacity(0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(
            icon: theme.icon,
            label:
                '${theme.name.toUpperCase()} • ${level.stageLabel.toUpperCase()}',
          ),
          const SizedBox(height: 18),
          Text(
            theme.missionTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              height: 1.02,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            theme.story,
            style: TextStyle(
              color: Colors.white.withOpacity(0.84),
              fontSize: 14,
              height: 1.36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _ScriptureTopCard(
            scriptureTitle: scriptureTitle,
            scriptureText: scriptureText,
            reference: reference,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Start Stage ${level.stage}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2EA6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onChooseStage,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Stage'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.26)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final DominionLevel level;
  final String objectiveSummary;

  const _MissionCard({required this.level, required this.objectiveSummary});

  @override
  Widget build(BuildContext context) {
    final theme = level.theme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.accentColor.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(theme.icon, color: theme.accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  theme.missionVerb,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            objectiveSummary,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionStatusLine extends StatelessWidget {
  final DominionMatchController controller;

  const _MissionStatusLine({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = controller.level.theme;
    return Row(
      children: [
        _TinyLevelBadge(level: controller.level),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            controller.status,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(theme.icon, color: theme.accentColor, size: 18),
      ],
    );
  }
}

class _LevelTile extends StatelessWidget {
  final DominionLevel level;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final time = level.timeLimit == null
        ? 'No timer'
        : '${level.timeLimit!.inMinutes}:${(level.timeLimit!.inSeconds % 60).toString().padLeft(2, '0')} timer';
    final theme = level.theme;
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? theme.accentColor.withOpacity(0.16)
                : Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.accentColor.withOpacity(0.60)
                  : Colors.white.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.accentColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  locked
                      ? Icons.lock_rounded
                      : selected
                          ? Icons.check_rounded
                          : theme.icon,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${level.stageLabel} • ${theme.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${level.moves} moves • ${level.targetScore} target • $time',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.62),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      theme.missionTitle,
                      style: TextStyle(
                        color: theme.accentColor.withOpacity(0.92),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScriptureTopCard extends StatelessWidget {
  final String scriptureTitle;
  final String scriptureText;
  final String reference;

  const _ScriptureTopCard({
    required this.scriptureTitle,
    required this.scriptureText,
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Color(0xFFFF4DB8),
            size: 25,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scriptureTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  scriptureText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 12.8,
                    height: 1.34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reference,
                  style: const TextStyle(
                    color: Color(0xFFFFD6F0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBoard extends StatelessWidget {
  final DominionWorldTheme theme;

  const _PreviewBoard({required this.theme});

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.menu_book_rounded,
      Icons.church_rounded,
      Icons.flutter_dash_rounded,
      Icons.local_fire_department_rounded,
      Icons.favorite_rounded,
      Icons.auto_awesome_rounded,
      Icons.wb_sunny_rounded,
      Icons.diamond_rounded,
    ];
    return AspectRatio(
      aspectRatio: 1.65,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.boardColor.withOpacity(0.72),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.accentColor.withOpacity(0.20)),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: 32,
          itemBuilder: (context, index) {
            final color = index.isEven ? theme.accentColor : theme.warningColor;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.92), color.withOpacity(0.42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.20), blurRadius: 8),
                ],
              ),
              child: Icon(
                icons[index % icons.length],
                color: Colors.white,
                size: 15,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RulesCard extends StatelessWidget {
  const _RulesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Game Rules',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _RuleLine(
            icon: Icons.swap_horiz_rounded,
            text: 'Tap two adjacent tiles to swap.',
          ),
          _RuleLine(
            icon: Icons.auto_awesome_rounded,
            text: 'Use special tiles to complete harder missions.',
          ),
          _RuleLine(
            icon: Icons.timeline_rounded,
            text: 'Each world changes the pressure, mood, and objective.',
          ),
          _RuleLine(
            icon: Icons.menu_book_rounded,
            text: 'Scripture rewards rotate so the game stays fresh.',
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.pinkAccent.shade100, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyLevelBadge extends StatelessWidget {
  final DominionLevel level;

  const _TinyLevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final theme = level.theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.accentColor.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.accentColor.withOpacity(0.36)),
      ),
      child: Text(
        'Stage ${level.stage} • ${theme.name}',
        style: TextStyle(
          color: theme.accentColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
