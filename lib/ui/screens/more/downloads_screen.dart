import 'package:flutter/material.dart';

import '../../../theme/theme_controller.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

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
          appBar: const DxmTopBar(
            title: 'Downloads',
            showBack: true,
            showMenu: true,
          ),
          bottomNavigationBar: const BannerAdWidget(tabKey: 'more.downloads'),
          body: GradientPageBackground(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  width: 520,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_done_rounded,
                        color: titleColor,
                        size: 38,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No Downloads Yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Downloaded messages, books, audio, and videos will appear here with artwork, type, file size, offline status, and quick actions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const NativeInlineAdTile(
                  tabKey: 'more.downloads',
                  label: 'Sponsored',
                  minHeight: 120,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
