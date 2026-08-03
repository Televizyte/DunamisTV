import 'package:flutter/material.dart';

import '../models/dynamic_section.dart';
import '../models/dynamic_tab.dart';
import 'dynamic_section_renderer.dart';

class DynamicTabRenderer extends StatelessWidget {
  final HubDynamicTab tab;
  final EdgeInsetsGeometry padding;
  final Widget? emptyState;
  final Widget? header;
  final Widget? footer;

  const DynamicTabRenderer({
    super.key,
    required this.tab,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
    this.emptyState,
    this.header,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final sections = tab.sections
        .where((section) {
          if (!section.enabled) return false;
          if (section.isAdSection) return true;
          return section.items.isNotEmpty;
        })
        .toList(growable: false);

    if (sections.isEmpty) {
      return emptyState ??
          DynamicTabEmptyState(
            title: tab.title.isNotEmpty ? tab.title : tab.label,
            message: 'No content has been added to this tab yet.',
          );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (header != null) header!,
        const SizedBox(height: 14),
        ...sections.map(
          (section) => DynamicHubSectionRenderer(
            section: section,
            padding: padding,
          ),
        ),
        if (footer != null) footer!,
        const SizedBox(height: 24),
      ],
    );
  }
}

class DynamicSectionsRenderer extends StatelessWidget {
  final List<HubDynamicSection> sections;
  final EdgeInsetsGeometry padding;
  final Widget? emptyState;
  final Widget? header;
  final Widget? footer;

  const DynamicSectionsRenderer({
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
      return emptyState ?? const SizedBox.shrink();
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (header != null) header!,
        const SizedBox(height: 14),
        ...visibleSections.map(
          (section) => DynamicHubSectionRenderer(
            section: section,
            padding: padding,
          ),
        ),
        if (footer != null) footer!,
        const SizedBox(height: 24),
      ],
    );
  }
}

class DynamicTabEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const DynamicTabEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final safeTitle = title.trim().isNotEmpty ? title.trim() : 'Empty tab';
    final safeMessage = message.trim().isNotEmpty
        ? message.trim()
        : 'No content has been added yet.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
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
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1D5CFF),
                      Color(0xFFE2388A),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.dynamic_feed_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      safeMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
