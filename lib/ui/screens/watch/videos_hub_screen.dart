import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../media/universal_media_launcher.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/gradient_page_background.dart';
import '../../widgets/hero_banner.dart';

class VideosHubScreen extends StatelessWidget {
  const VideosHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DxmTopBar(
        title: 'Videos',
        showBack: true,
        showMenu: true,
        onBack: () => context.pop(),
      ),
      body: GradientPageBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const HeroBanner(
              height: 160,
              slides: [
                HeroSlide(assetPath: 'assets/images/watch_1.jpg'),
              ],
              showArrows: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              child: Column(
                children: [
                  FeatureCard(
                    title: 'Commanding The Day Prayer Broadcast',
                    subtitle: 'Watch in-app',
                    icon: Icons.play_circle_fill_rounded,
                    onTap: () => UniversalMediaLauncher.open(
                      context,
                      title: 'Commanding The Day Prayer Broadcast',
                      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                      type: 'youtube',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FeatureCard(
                    title: 'Healing and Deliverance Service',
                    subtitle: 'Watch in-app',
                    icon: Icons.play_circle_fill_rounded,
                    onTap: () => UniversalMediaLauncher.open(
                      context,
                      title: 'Healing and Deliverance Service',
                      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                      type: 'youtube',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FeatureCard(
                    title: 'Testimonies at Dunamis',
                    subtitle: 'Watch in-app',
                    icon: Icons.play_circle_fill_rounded,
                    onTap: () => UniversalMediaLauncher.open(
                      context,
                      title: 'Testimonies at Dunamis',
                      url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                      type: 'youtube',
                    ),
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
