import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScriptureBlock extends StatelessWidget {
  final String text;

  const ScriptureBlock({
    super.key,
    required this.text,
  });

  String _cleanText() {
    return text.trim();
  }

  void _openInBible(BuildContext context) {
    final value = _cleanText();
    if (value.isEmpty) return;

    // We pass raw scripture text — Bible module already knows how to resolve
    context.push(
      '/tools/bible',
      extra: {
        'query': value,
        'highlight': true,
      },
    );
  }

  void _openNoteEditor(BuildContext context) {
    final value = _cleanText();
    if (value.isEmpty) return;

    context.push(
      '/tools/notes/editor',
      extra: {
        'sourceType': 'scripture',
        'prefill': value,
      },
    );
  }

  void _openQuoteCreator(BuildContext context) {
    final value = _cleanText();
    if (value.isEmpty) return;

    context.push(
      '/tools/quote',
      extra: {
        'prefill': value,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = _cleanText();
    if (value.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _openInBible(context),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF0D1228),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Open in Bible',
                      onTap: () {
                        Navigator.pop(context);
                        _openInBible(context);
                      },
                    ),
                    _ActionItem(
                      icon: Icons.note_add_rounded,
                      label: 'Save to Notes',
                      onTap: () {
                        Navigator.pop(context);
                        _openNoteEditor(context);
                      },
                    ),
                    _ActionItem(
                      icon: Icons.format_quote_rounded,
                      label: 'Make Quote',
                      onTap: () {
                        Navigator.pop(context);
                        _openQuoteCreator(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)],
          ),
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.45,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
