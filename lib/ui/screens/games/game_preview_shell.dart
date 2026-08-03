import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/banner_ad_widget.dart';
import '../../widgets/gradient_page_background.dart';

class GamePreviewStat {
  final String label;
  final String value;
  final IconData icon;

  const GamePreviewStat({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class GamePreviewAction {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const GamePreviewAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class GamePreviewShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String comingSoonText;
  final IconData heroIcon;
  final List<Color> gradientColors;
  final List<String> highlights;
  final List<GamePreviewStat> stats;
  final List<Widget> previewWidgets;
  final String routeKey;
  final bool showBannerAd;
  final String bannerTabKey;

  const GamePreviewShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.comingSoonText,
    required this.heroIcon,
    required this.gradientColors,
    required this.highlights,
    required this.stats,
    required this.previewWidgets,
    required this.routeKey,
    this.showBannerAd = true,
    this.bannerTabKey = 'explore.games',
  });

  static const _topGradient = LinearGradient(
    colors: [
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(gradient: _topGradient),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/games');
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Game info',
                  onPressed: () => _showInfo(context),
                  icon: const Icon(Icons.info_outline_rounded,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
      body: GradientPageBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                children: [
                  _HeroPanel(
                    title: title,
                    subtitle: subtitle,
                    badge: badge,
                    comingSoonText: comingSoonText,
                    heroIcon: heroIcon,
                    gradientColors: gradientColors,
                    routeKey: routeKey,
                  ),
                  const SizedBox(height: 14),
                  if (stats.isNotEmpty) _StatsGrid(stats: stats),
                  if (stats.isNotEmpty) const SizedBox(height: 14),
                  _PreviewCard(
                    title: 'Preview Interface',
                    subtitle:
                        'This is the first real screen for this game. Full gameplay comes next.',
                    children: previewWidgets,
                  ),
                  const SizedBox(height: 14),
                  _PreviewCard(
                    title: 'What this game will include',
                    subtitle: 'Locked from the game blueprint.',
                    children: highlights
                        .map((text) => _HighlightRow(text: text))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _ActionPanel(title: title),
                ],
              ),
            ),
            if (showBannerAd)
              SafeArea(
                top: false,
                child: BannerAdWidget(tabKey: bannerTabKey),
              ),
          ],
        ),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101529),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.26),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(heroIcon, color: const Color(0xFFFF4DB8), size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Understood'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side:
                              BorderSide(color: Colors.white.withOpacity(0.28)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String comingSoonText;
  final IconData heroIcon;
  final List<Color> gradientColors;
  final String routeKey;

  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.comingSoonText,
    required this.heroIcon,
    required this.gradientColors,
    required this.routeKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors.length >= 2
        ? gradientColors
        : const [Color(0xFF1A1F5A), Color(0xFFB70E7C)];

    return Container(
      constraints: const BoxConstraints(minHeight: 238),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 18),
            color: colors.last.withOpacity(0.24),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -20,
            child: Icon(heroIcon,
                size: 168, color: Colors.white.withOpacity(0.10)),
          ),
          Positioned(
            right: 0,
            top: 0,
            child:
                _Pill(text: comingSoonText, icon: Icons.construction_rounded),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Pill(text: badge, icon: heroIcon),
              const SizedBox(height: 34),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 13.5,
                  height: 1.32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.route_rounded,
                        color: Colors.white.withOpacity(0.82), size: 16),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        routeKey,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<GamePreviewStat> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final columns = constraints.maxWidth > 650 ? 4 : 2;
        final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: width,
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.055),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.09)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2DA1).withOpacity(0.16),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(stat.icon,
                              color: const Color(0xFFFF4DB8), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                stat.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.62),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.048),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.66),
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String text;

  const _HighlightRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF38D5FF), size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                fontSize: 13,
                height: 1.36,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final String title;

  const _ActionPanel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF2DA1).withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFF4DB8).withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview build',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '$title is now routed and has a real first interface. The complete game engine will be added in a later drop.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 12.8,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Coming Soon'),
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.white.withOpacity(0.18),
                    disabledForegroundColor: Colors.white.withOpacity(0.58),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => context.go('/games'),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('Hub'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.26)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class MatchBoardPreview extends StatelessWidget {
  const MatchBoardPreview({super.key});

  static const _colors = [
    Color(0xFF365DFF),
    Color(0xFFFFC928),
    Color(0xFF49D3FF),
    Color(0xFFFF6A3D),
    Color(0xFFFF4DB8),
    Color(0xFF8D6CFF),
  ];

  static const _icons = [
    Icons.menu_book_rounded,
    Icons.add_rounded,
    Icons.flutter_dash_rounded,
    Icons.local_fire_department_rounded,
    Icons.favorite_rounded,
    Icons.workspace_premium_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF090D1F),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 36,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
          ),
          itemBuilder: (context, index) {
            final color = _colors[index % _colors.length];
            return Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.45)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(index % 7 == 0 ? 0.38 : 0.10),
                    blurRadius: index % 7 == 0 ? 12 : 4,
                  ),
                ],
              ),
              child:
                  Icon(_icons[index % _icons.length], color: color, size: 18),
            );
          },
        ),
      ),
    );
  }
}

class RunnerTrackPreview extends StatelessWidget {
  const RunnerTrackPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.35,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF090D1F),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.035),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: Container(
                  width: 62,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4DB8), Color(0xFF38D5FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4DB8).withOpacity(0.30),
                        blurRadius: 22,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_run_rounded,
                      color: Colors.white, size: 34),
                ),
              ),
            ),
            Positioned(
                left: 38, top: 20, child: _Obstacle(icon: Icons.block_rounded)),
            Positioned(
                right: 44,
                top: 58,
                child: _Collectible(icon: Icons.lightbulb_rounded)),
            Positioned(
                left: 70,
                bottom: 82,
                child: _Collectible(icon: Icons.workspace_premium_rounded)),
          ],
        ),
      ),
    );
  }
}

class _Obstacle extends StatelessWidget {
  final IconData icon;

  const _Obstacle({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D6D).withOpacity(0.16),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFF4D6D).withOpacity(0.36)),
      ),
      child: Icon(icon, color: const Color(0xFFFF6A7E), size: 22),
    );
  }
}

class _Collectible extends StatelessWidget {
  final IconData icon;

  const _Collectible({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC928).withOpacity(0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFFFC928).withOpacity(0.44)),
      ),
      child: Icon(icon, color: const Color(0xFFFFD84D), size: 20),
    );
  }
}

class GrowthCorePreview extends StatelessWidget {
  const GrowthCorePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF090D1F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ResourceChip(
                  label: 'Faith',
                  value: '1,240',
                  icon: Icons.auto_awesome_rounded),
              const SizedBox(width: 8),
              _ResourceChip(
                  label: 'Per sec',
                  value: '+12',
                  icon: Icons.trending_up_rounded),
            ],
          ),
          const Spacer(),
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFFF2A6),
                  Color(0xFF38D5FF),
                  Color(0xFF5B1FA8)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38D5FF).withOpacity(0.32),
                  blurRadius: 36,
                ),
              ],
            ),
            child: const Icon(Icons.local_florist_rounded,
                color: Colors.white, size: 54),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                  child:
                      _UpgradeMiniCard(title: 'Tap Strength', level: 'Lv. 3')),
              const SizedBox(width: 8),
              Expanded(
                  child: _UpgradeMiniCard(
                      title: 'Passive Growth', level: 'Lv. 2')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResourceChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.09)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFD84D), size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900)),
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 10.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeMiniCard extends StatelessWidget {
  final String title;
  final String level;

  const _UpgradeMiniCard({required this.title, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(level,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.62),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class QuizStartPreview extends StatelessWidget {
  const QuizStartPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF090D1F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _QuizLevelTile(
              title: 'Level 1 — Easy',
              questions: '5 questions',
              pass: '60% pass',
              active: true),
          const SizedBox(height: 9),
          _QuizLevelTile(
              title: 'Level 2 — Medium',
              questions: '5 questions',
              pass: '70% pass',
              active: false),
          const SizedBox(height: 9),
          _QuizLevelTile(
              title: 'Level 3 — Hard',
              questions: '5 questions',
              pass: '80% pass',
              active: false),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _ResourceChip(
                      label: 'XP Reward',
                      value: '+100',
                      icon: Icons.bolt_rounded)),
              const SizedBox(width: 8),
              Expanded(
                  child: _ResourceChip(
                      label: 'Medals',
                      value: '4',
                      icon: Icons.military_tech_rounded)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuizLevelTile extends StatelessWidget {
  final String title;
  final String questions;
  final String pass;
  final bool active;

  const _QuizLevelTile({
    required this.title,
    required this.questions,
    required this.pass,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        active ? const Color(0xFFFF4DB8) : Colors.white.withOpacity(0.18);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(active ? 0.12 : 0.055),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withOpacity(active ? 0.35 : 0.20)),
      ),
      child: Row(
        children: [
          Icon(
              active
                  ? Icons.play_circle_fill_rounded
                  : Icons.lock_outline_rounded,
              color: active
                  ? const Color(0xFFFF4DB8)
                  : Colors.white.withOpacity(0.44)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('$questions • $pass',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.60),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
