import 'package:flutter/material.dart';

import '../models/dynamic_section.dart';
import 'dynamic_section_renderer.dart';

class HomeDynamicSectionSlot extends StatelessWidget {
  final List<HubDynamicSection> sections;
  final EdgeInsetsGeometry padding;
  final bool enabled;

  const HomeDynamicSectionSlot({
    super.key,
    required this.sections,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final visibleSections = sections.where((section) {
      if (!section.enabled) return false;
      if (section.isAdSection) return true;
      return section.items.isNotEmpty;
    }).toList(growable: false);

    if (visibleSections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: visibleSections
          .map(
            (section) => DynamicHubSectionRenderer(
              section: section,
              padding: padding,
            ),
          )
          .toList(growable: false),
    );
  }
}
