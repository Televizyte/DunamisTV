import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/feature_card.dart';
import '../../widgets/gradient_page_background.dart';
import '../../widgets/hero_banner.dart';

class ExploreToolsScreen extends StatelessWidget {
  const ExploreToolsScreen({super.key});

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
              children: const [
                SizedBox(width: 16),
                Text(
                  'Explore',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: GradientPageBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const HeroBanner(
              height: 180,
              slides: [
                HeroSlide(assetPath: 'assets/images/more_1.jpg'),
              ],
              showArrows: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              child: Column(
                children: [
                  FeatureCard(
                    title: 'Quick Tools',
                    subtitle: 'Quote Creator • Notes • Bible',
                    icon: Icons.widgets_rounded,
                    onTap: () => context.push('/tools'),
                  ),
                  const SizedBox(height: 12),
                  FeatureCard(
                    title: 'Entertainment',
                    subtitle: 'Music • Movies',
                    icon: Icons.movie_filter_rounded,
                    onTap: () => context.push('/entertainment'),
                  ),
                  const SizedBox(height: 12),
                  FeatureCard(
                    title: 'Games',
                    subtitle: 'Bible Quiz & more',
                    icon: Icons.videogame_asset_rounded,
                    onTap: () => context.push('/games'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
