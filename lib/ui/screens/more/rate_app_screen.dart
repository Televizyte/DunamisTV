import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/app_profile_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class RateAppScreen extends StatelessWidget {
  const RateAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppPublicProfile>(
      future: AppProfileService.instance.getProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? AppPublicProfile.fallback();

        return AnimatedBuilder(
          animation: ThemeController.instance,
          builder: (context, _) {
            final isLight = ThemeController.instance.isLightMode;
            final panelBg = isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430);
            final border = isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.08);
            final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white.withOpacity(0.94);
            final bodyColor = isLight ? const Color(0xFF6B6256) : Colors.white.withOpacity(0.72);

            return Scaffold(
              appBar: const DxmTopBar(title: 'Rate App', showBack: true, showMenu: true),
              body: GradientPageBackground(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      width: 540,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: panelBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: border)),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star_rate_rounded, color: Color(0xFFFFB400), size: 42),
                        const SizedBox(height: 14),
                        Text('Enjoying ${profile.displayName}?', textAlign: TextAlign.center, style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        Text(profile.hasPlayStore ? 'Your rating helps others discover the app.' : 'The Play Store rating link is managed from AppsHub App Settings. You can still share the app with someone today.', textAlign: TextAlign.center, style: TextStyle(color: bodyColor, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 18),
                        if (profile.hasPlayStore)
                          ElevatedButton.icon(onPressed: () { context.push('/web', extra: {'title': 'Rate ${profile.displayName}', 'url': profile.playStoreUrl}); }, icon: const Icon(Icons.open_in_new_rounded), label: const Text('Open Play Store'))
                        else
                          ElevatedButton.icon(onPressed: () { Share.share('I’m enjoying ${profile.displayName}. Check it out:\n${profile.bestShareLink}'); }, icon: const Icon(Icons.share_rounded), label: const Text('Share App')),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
