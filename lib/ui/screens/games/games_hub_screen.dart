import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/banner_ad_widget.dart';
import '../../widgets/gradient_page_background.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  static const _topGradient = LinearGradient(
    colors: [
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const List<_GameHubItem> _games = [
    _GameHubItem(
      title: 'Dominion Match',
      subtitle: 'Match 3 puzzle with scripture reward flow.',
      route: '/games/dominion-match',
      badge: 'PUZZLE',
      icon: Icons.grid_view_rounded,
      colors: [Color(0xFF101C54), Color(0xFF5B1FA8), Color(0xFFB70E7C)],
    ),
    _GameHubItem(
      title: 'Race of Faith',
      subtitle: '3-lane endless runner preview interface.',
      route: '/games/race-of-faith',
      badge: 'RUNNER',
      icon: Icons.directions_run_rounded,
      colors: [Color(0xFF06263F), Color(0xFF1A5D8F), Color(0xFFFF2DA1)],
    ),
    _GameHubItem(
      title: 'Kingdom Builder',
      subtitle: 'Build a living ministry through people, service, and growth.',
      route: '/games/kingdom-builder',
      badge: 'SIMULATION',
      icon: Icons.account_balance_rounded,
      colors: [Color(0xFF102A43), Color(0xFF244F78), Color(0xFFC8952E)],
    ),
    _GameHubItem(
      title: 'Bible Quiz',
      subtitle: 'Quiz engine entry with levels, XP, and medals.',
      route: '/games/bible-quiz',
      badge: 'QUIZ',
      icon: Icons.quiz_rounded,
      colors: [Color(0xFF101C54), Color(0xFF4C2EA8), Color(0xFF0AA6C2)],
    ),
  ];

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
                      context.go('/explore');
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Games Hub',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
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
                  const _GamesHeroHeader(),
                  const SizedBox(height: 16),
                  const Text(
                    'Game Preview Interfaces',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These screens are the first real interface layer. AppsHub will control visibility, order, metadata, route exposure, and ads policy.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.66),
                      fontSize: 12.8,
                      height: 1.38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 12.0;
                      final columns = constraints.maxWidth > 620 ? 2 : 1;
                      final width =
                          (constraints.maxWidth - (spacing * (columns - 1))) /
                              columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: _games
                            .map(
                              (game) => SizedBox(
                                width: width,
                                height: 178,
                                child: _GameHubCard(
                                  item: game,
                                  onTap: () => context.push(game.route),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SafeArea(
              top: false,
              child: BannerAdWidget(tabKey: 'explore.games'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamesHeroHeader extends StatelessWidget {
  const _GamesHeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF111C5C), Color(0xFF5B1FA8), Color(0xFFB70E7C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB70E7C).withOpacity(0.20),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -26,
            child: Icon(
              Icons.sports_esports_rounded,
              size: 160,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HubPill(
                  text: 'EXPLORE MODULE', icon: Icons.explore_rounded),
              const SizedBox(height: 28),
              const Text(
                'Faith-friendly games that create engagement.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Dominion Match, Race of Faith, Kingdom Builder, and Bible Quiz are available from one Games Hub.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.84),
                  fontSize: 13.2,
                  height: 1.34,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameHubCard extends StatelessWidget {
  final _GameHubItem item;
  final VoidCallback onTap;

  const _GameHubCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: item.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: item.colors.last.withOpacity(0.20),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -12,
                child: Icon(
                  item.icon,
                  size: 112,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HubPill(text: item.badge, icon: item.icon),
                    const Spacer(),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 12.5,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.touch_app_rounded,
                            color: Colors.white.withOpacity(0.86), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Open preview',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.86),
                            fontSize: 11.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
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

class _HubPill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _HubPill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.6,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameHubItem {
  final String title;
  final String subtitle;
  final String route;
  final String badge;
  final IconData icon;
  final List<Color> colors;

  const _GameHubItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.badge,
    required this.icon,
    required this.colors,
  });
}
