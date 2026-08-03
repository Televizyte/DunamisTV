import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class InspireFeaturedScreen extends StatelessWidget {
  const InspireFeaturedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DxmTopBar(
        title: 'Featured Teaching',
        showBack: true,
        showMenu: true,
        onBack: () => context.pop(),
      ),
      body: GradientPageBackground(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Featured Teaching is coming soon.\n\nAppsHub will control what shows here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
