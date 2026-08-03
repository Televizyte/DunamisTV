import 'package:flutter/material.dart';

import '../../../features/hub/state/hub_scope.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/gradient_page_background.dart';

class SodKeyPointsScreen extends StatelessWidget {
  const SodKeyPointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);
    final Map<String, dynamic> hubMap = store?.raw ?? const <String, dynamic>{};

    final inspire =
        (hubMap['inspire'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final raw = inspire['sod_keypoints'];

    final List<String> points = (raw is List)
        ? raw.map((e) => e.toString()).toList()
        : const [];

    return Scaffold(
      backgroundColor: Colors.transparent,

      appBar: DxmTopBar(
        title: 'Key Points',
        showBack: true,
        showMenu: true,
        onBack: () => Navigator.pop(context),
        onRefresh: () => store?.refresh(),
      ),

      body: GradientPageBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const HeroBanner(
              title: 'Today’s Key Points',
              height: 190,
              slides: [
                HeroSlide(label: 'Wisdom'),
                HeroSlide(label: 'Faith'),
                HeroSlide(label: 'Prayer'),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
              child: points.isEmpty
                  ? const _EmptyCard()
                  : _KeyPointsCard(points: points),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyPointsCard extends StatelessWidget {
  final List<String> points;

  const _KeyPointsCard({
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: points
          .map(
            (t) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: const Color(0xFF101533),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)],
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        color: const Color(0xFF0D1228),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF5B1FA8),
                  Color(0xFFB70E7C),
                ],
              ),
            ),
            child: const Icon(Icons.lightbulb, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'AppsHub will publish today’s Seed of Destiny key points here.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.80),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
