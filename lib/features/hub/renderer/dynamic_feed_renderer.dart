import 'package:flutter/material.dart';

import '../models/dynamic_section.dart';
import 'dynamic_section_renderer.dart';

class DynamicHubFeedRenderer extends StatelessWidget {
  final List<HubDynamicSection> sections;
  final EdgeInsetsGeometry padding;
  final Widget? emptyState;
  final Widget? header;
  final Widget? footer;

  const DynamicHubFeedRenderer({
    super.key,
    required this.sections,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.emptyState,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSections = sections
        .where((section) {
          if (!section.enabled) return false;
          if (section.isAdSection) return true;
          return section.items.isNotEmpty;
        })
        .toList(growable: false);

    if (visibleSections.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) header!,
          emptyState ?? const DynamicHubEmptyFeedState(),
          if (footer != null) footer!,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header!,
        ...List.generate(visibleSections.length, (index) {
          return DynamicHubSectionRenderer(
            section: visibleSections[index],
            padding: padding,
          );
        }),
        if (footer != null) footer!,
      ],
    );
  }
}

class DynamicHubEmptyFeedState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const DynamicHubEmptyFeedState({
    super.key,
    this.title = 'Nothing to show yet',
    this.message =
        'Content will appear here when it is enabled from AppsHub.',
    this.icon = Icons.dynamic_feed_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.055),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1D5CFF),
                    Color(0xFFE2388A),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    color: Colors.black.withOpacity(0.18),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isNotEmpty ? title.trim() : 'Nothing to show yet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message.trim().isNotEmpty
                        ? message.trim()
                        : 'Content will appear here when it is enabled from AppsHub.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.68),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DynamicHubFeedSliverRenderer extends StatelessWidget {
  final List<HubDynamicSection> sections;
  final EdgeInsetsGeometry padding;
  final Widget? emptyState;
  final Widget? header;
  final Widget? footer;

  const DynamicHubFeedSliverRenderer({
    super.key,
    required this.sections,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.emptyState,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final visibleSections = sections
        .where((section) {
          if (!section.enabled) return false;
          if (section.isAdSection) return true;
          return section.items.isNotEmpty;
        })
        .toList(growable: false);

    if (visibleSections.isEmpty) {
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) header!,
            emptyState ?? const DynamicHubEmptyFeedState(),
            if (footer != null) footer!,
          ],
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final extraHeader = header != null ? 1 : 0;
          final sectionStartIndex = extraHeader;
          final sectionEndIndex = sectionStartIndex + visibleSections.length;
          final footerIndex = sectionEndIndex;

          if (header != null && index == 0) {
            return header!;
          }

          if (index >= sectionStartIndex && index < sectionEndIndex) {
            final section = visibleSections[index - sectionStartIndex];
            return DynamicHubSectionRenderer(
              section: section,
              padding: padding,
            );
          }

          if (footer != null && index == footerIndex) {
            return footer!;
          }

          return const SizedBox.shrink();
        },
        childCount: visibleSections.length +
            (header != null ? 1 : 0) +
            (footer != null ? 1 : 0),
      ),
    );
  }
}
