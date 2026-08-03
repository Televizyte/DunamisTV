import 'package:flutter/material.dart';

import '../models/dynamic_tab.dart';
import '../renderer/dynamic_tab_renderer.dart';

class DynamicTabScreen extends StatelessWidget {
  final HubDynamicTab tab;

  const DynamicTabScreen({
    super.key,
    required this.tab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: SafeArea(
        child: DynamicTabRenderer(
          tab: tab,
        ),
      ),
    );
  }
}
