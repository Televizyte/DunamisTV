import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class QuoteBlock extends StatelessWidget {
  final String text;

  const QuoteBlock({
    super.key,
    required this.text,
  });

  String _cleanText() {
    return text.trim();
  }

  void _openNoteEditor(BuildContext context) {
    final value = _cleanText();
    if (value.isEmpty) return;

    context.push(
      '/tools/notes/editor',
      extra: {
        'sourceType': 'article',
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
      onTap: () => _openQuoteCreator(context),
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
                      icon: Icons.format_quote_rounded,
                      label: 'Open in Quote Creator',
                      onTap: () {
                        Navigator.pop(context);
                        _openQuoteCreator(context);
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
                      icon: Icons.copy_rounded,
                      label: 'Copy Quote',
                      onTap: () async {
                        Navigator.pop(context);
                        await Clipboard.setData(ClipboardData(text: value));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quote copied')),
                        );
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1228),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: Colors.white.withOpacity(0.70),
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
