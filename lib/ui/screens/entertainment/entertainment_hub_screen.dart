import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../widgets/banner_ad_widget.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/gradient_page_background.dart';
import '../../widgets/hero_banner.dart';

class EntertainmentHubScreen extends StatelessWidget {
  const EntertainmentHubScreen({super.key});

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
                const Text(
                  'Entertainment',
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const HeroBanner(
                    height: 160,
                    slides: [
                      HeroSlide(assetPath: 'assets/images/home_2.jpg'),
                      HeroSlide(assetPath: 'assets/images/home_1.jpg'),
                      HeroSlide(assetPath: 'assets/images/home_5.jpg'),
                    ],
                    showArrows: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                    child: Column(
                      children: [
                        FeatureCard(
                          title: 'Music',
                          subtitle: 'Gospel music videos',
                          icon: Icons.music_note_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Music hub coming next.'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        FeatureCard(
                          title: 'Movies',
                          subtitle: 'Christian movies & content',
                          icon: Icons.movie_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Movies hub coming next.'),
                              ),
                            );
                          },
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
