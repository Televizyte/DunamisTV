import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/dominion_scripture.dart';

Future<void> showDominionScriptureDialog({
  required BuildContext context,
  required DominionScripture scripture,
  required bool victory,
  required VoidCallback onContinue,
  required VoidCallback onRetry,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Scripture encouragement',
    barrierColor: Colors.black.withOpacity(0.46),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
            child: Material(
              color: Colors.transparent,
              child: _ScriptureCard(
                scripture: scripture,
                victory: victory,
                onContinue: onContinue,
                onRetry: onRetry,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.08),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _ScriptureCard extends StatelessWidget {
  final DominionScripture scripture;
  final bool victory;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const _ScriptureCard({
    required this.scripture,
    required this.victory,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          colors: victory
              ? const [Color(0xFF0D3A60), Color(0xFF40228B), Color(0xFFC51D83)]
              : const [Color(0xFF171C33), Color(0xFF332465), Color(0xFF6C1F58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: (victory ? const Color(0xFFFF2EA6) : const Color(0xFF38D5FF))
                .withOpacity(0.28),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    victory
                        ? Icons.emoji_events_rounded
                        : Icons.volunteer_activism_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        victory ? 'Stage Completed' : 'Try Again With Courage',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      Text(
                        scripture.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '“${scripture.text}”',
              style: TextStyle(
                color: Colors.white.withOpacity(0.90),
                fontSize: 15,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              scripture.reference,
              style: const TextStyle(
                color: Color(0xFFFFD6F0),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (victory) {
                        onContinue();
                      } else {
                        onRetry();
                      }
                    },
                    icon: Icon(
                      victory
                          ? Icons.arrow_forward_rounded
                          : Icons.refresh_rounded,
                    ),
                    label: Text(victory ? 'Next Stage' : 'Retry Stage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2EA6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(
                      '/tools/bible/reader',
                      extra: scripture.toBiblePayload(),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Bible'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.26)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniAction(
                    icon: Icons.note_add_rounded,
                    label: 'Save to Notes',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(
                        '/tools/notes/editor',
                        extra: scripture.toNotesPayload(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniAction(
                    icon: Icons.format_quote_rounded,
                    label: 'Make Quote',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(
                        '/tools/quote',
                        extra: scripture.toQuotePayload(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
