import 'package:flutter/material.dart';

import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class FeaturedPlaceholderScreen extends StatelessWidget {
  const FeaturedPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DxmTopBar(
        title: 'Featured Teaching',
        showBack: true,
        showMenu: true,
      ),
      body: GradientPageBackground(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Featured Teaching will be controlled from AppsHub.\n\nWhen AppsHub sets inspire.featured.url, this screen will stop being used.',
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
