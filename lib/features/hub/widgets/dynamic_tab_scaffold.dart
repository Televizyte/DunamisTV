import 'package:flutter/material.dart';

import '../models/dynamic_tab.dart';
import '../renderer/dynamic_tab_renderer.dart';

class DynamicTabScaffold extends StatelessWidget {
  final HubDynamicTab tab;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry padding;

  const DynamicTabScaffold({
    super.key,
    required this.tab,
    this.header,
    this.footer,
    this.padding = const EdgeInsets.symmetric(horizontal: 14),
  });

  @override
  Widget build(BuildContext context) {
    return DynamicTabRenderer(
      tab: tab,
      padding: padding,
      header: header,
      footer: footer,
      emptyState: DynamicTabEmptyState(
        title: tab.title.isNotEmpty ? tab.title : tab.label,
        message: 'This tab is ready. Add sections from AppsHub to show content.',
      ),
    );
  }
}
