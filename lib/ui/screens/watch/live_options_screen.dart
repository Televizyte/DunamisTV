import 'package:flutter/material.dart';

import '../../media/universal_media_launcher.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/gradient_page_background.dart';
import '../../widgets/hero_banner.dart';

class LiveOptionsScreen extends StatelessWidget {
  const LiveOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const DxmTopBar(
        title: 'Live Broadcast',
        showBack: true,
        showMenu: true,
      ),
      body: GradientPageBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const HeroBanner(
              title: 'Live Broadcast',
              height: 190,
              slides: [
                HeroSlide(label: 'Live'),
                HeroSlide(label: 'Worship'),
                HeroSlide(label: 'Word'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  FeatureCard(
                    title: 'Dunamis TV Live',
                    subtitle: '24/7 live television stream',
                    icon: Icons.live_tv_rounded,
                    onTap: () => UniversalMediaLauncher.open(
                      context,
                      title: 'Dunamis TV Live',
                      url: 'https://atechgroupuk.site/DTV.m3u8',
                      type: 'hls',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FeatureCard(
                    title: 'Live Service',
                    subtitle: 'Open live church services and special programs',
                    icon: Icons.play_circle_fill_rounded,
                    onTap: () => UniversalMediaLauncher.open(
                      context,
                      title: 'Live Service',
                      url:
                          'https://youtube.com/playlist?list=PLsFcFNo2Ku199zMhBztn8Kf5L_q5NSkdG&si=t8Q_1hIly-uqHgg8',
                      type: 'youtube',
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
