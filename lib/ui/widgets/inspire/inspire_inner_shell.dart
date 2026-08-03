import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InspireInnerShell extends StatelessWidget {
  final String title;
  final VoidCallback? onRefresh;
  final Widget child;

  const InspireInnerShell({
    super.key,
    required this.title,
    required this.child,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Column(
          children: [
            _TopRow(
              title: title,
              onBack: () => context.pop(),
              onRefresh: onRefresh,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onRefresh;

  const _TopRow({
    required this.title,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1228),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(Icons.arrow_back_rounded, color: Colors.white.withOpacity(0.9)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onRefresh,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1228),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(0.9)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
