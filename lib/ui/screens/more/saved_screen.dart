import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme_controller.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final panelBg =
            isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430);
        final border =
            isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);
        final titleColor =
            isLight ? const Color(0xFF1E1B16) : Colors.white.withOpacity(0.94);
        final bodyColor =
            isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.72);

        return Scaffold(
          appBar:
              const DxmTopBar(title: 'Saved', showBack: true, showMenu: true),
          bottomNavigationBar: const BannerAdWidget(tabKey: 'more.saved'),
          body: GradientPageBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: panelBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: border)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saved Library',
                            style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text(
                            'Your saved items and bookmarked scripture collections are organized here.',
                            style: TextStyle(
                                color: bodyColor,
                                fontSize: 12.8,
                                height: 1.35,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
                const SizedBox(height: 14),
                const NativeInlineAdTile(
                    tabKey: 'more.saved', label: 'Sponsored', minHeight: 120),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/tools/bible/saved'),
                    child: Ink(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: panelBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border)),
                      child: Row(children: [
                        Icon(Icons.bookmark_rounded,
                            color: titleColor, size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Saved Bible Verses',
                                  style: TextStyle(
                                      color: titleColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text('Open your saved scripture collection',
                                  style: TextStyle(
                                      color: bodyColor,
                                      fontSize: 12.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600)),
                            ])),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: titleColor),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
