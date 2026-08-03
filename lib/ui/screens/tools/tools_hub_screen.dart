import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/banner_ad_widget.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/gradient_page_background.dart';
import '../../widgets/hero_banner.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

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
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Quick Tools',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/explore'),
                  child: const Text(
                    'Explore',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
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
                padding: EdgeInsets.zero,
                children: [
                  const HeroBanner(
                    height: 160,
                    slides: [
                      HeroSlide(assetPath: 'assets/images/home_3.jpg'),
                      HeroSlide(assetPath: 'assets/images/home_4.jpg'),
                      HeroSlide(assetPath: 'assets/images/home_5.jpg'),
                    ],
                    showArrows: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open the built-in connected tools for note taking, scripture reading, quote creation, and light interaction.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.74),
                            fontSize: 12.8,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        FeatureCard(
                          title: 'Quote Creator',
                          subtitle: 'Create, style & share quotes',
                          icon: Icons.format_quote_rounded,
                          onTap: () => context.push('/tools/quote'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Notes',
                          subtitle: 'Write, save, organize & reopen notes',
                          icon: Icons.note_alt_rounded,
                          onTap: () => context.push('/tools/notes'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Bible',
                          subtitle: 'Read scripture in-app',
                          icon: Icons.menu_book_rounded,
                          onTap: () => context.push('/tools/bible'),
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Games',
                          subtitle: 'Open the games hub',
                          icon: Icons.sports_esports_rounded,
                          onTap: () => context.push('/games'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SafeArea(
              top: false,
              child: BannerAdWidget(
                tabKey: 'explore',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
