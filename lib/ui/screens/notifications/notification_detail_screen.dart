import 'package:flutter/material.dart';

import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';
import 'notification_message_card.dart';

class NotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const NotificationDetailScreen({super.key, required this.item});

  String _first(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<void> _openAction(BuildContext context) async {
    await AdsService.instance.maybeShowInterstitialOnSafeNav(context,
        tabKey: 'notification.action.open');
    if (!context.mounted) return;
    await NotificationActionHelper.openTarget(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final data = item['data'] is Map ? item['data'] as Map : const {};
    final title = _first([item['title'], 'Notification']);
    final body = _first([item['body'], item['message']]);
    final imageUrl = _first([
      item['image_url'],
      item['image'],
      data['image_url'],
      data['image'],
      data['thumbnail_url'],
      data['thumbnail']
    ]);
    final actionLabel = _first(
        [item['action_label'], data['action_label'], 'Open related content']);

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final panel =
            isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430);
        final titleColor = isLight ? const Color(0xFF1E1B16) : Colors.white;
        final bodyColor =
            isLight ? const Color(0xFF514A41) : Colors.white.withOpacity(0.82);
        return Scaffold(
          appBar: const DxmTopBar(
              title: 'Notification', showBack: true, showMenu: true),
          bottomNavigationBar:
              const BannerAdWidget(tabKey: 'more.notifications.message'),
          body: GradientPageBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: panel, borderRadius: BorderRadius.circular(24)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl.isNotEmpty)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _DetailFallback()),
                          )
                        else
                          const _DetailFallback(),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: TextStyle(
                                        color: titleColor,
                                        fontSize: 21,
                                        height: 1.2,
                                        fontWeight: FontWeight.w900)),
                                if (body.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  SelectableText(body,
                                      style: TextStyle(
                                          color: bodyColor,
                                          fontSize: 14.2,
                                          height: 1.58,
                                          fontWeight: FontWeight.w600)),
                                ],
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _openAction(context),
                                    icon: const Icon(Icons.open_in_new_rounded),
                                    label: Text(actionLabel),
                                  ),
                                ),
                              ]),
                        ),
                      ]),
                ),
                const SizedBox(height: 14),
                const NativeInlineAdTile(
                    tabKey: 'more.notifications.message',
                    label: 'Sponsored',
                    minHeight: 120),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailFallback extends StatelessWidget {
  const _DetailFallback();
  @override
  Widget build(BuildContext context) => Container(
        height: 170,
        color: const Color(0xFF171D45),
        alignment: Alignment.center,
        child: const Icon(Icons.notifications_active_rounded,
            color: Color(0xFFFF4DB8), size: 54),
      );
}
