import 'package:flutter/material.dart';

class BookReaderTools extends StatelessWidget {
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onNotes;
  final VoidCallback onQuote;
  final VoidCallback onSettings;
  final VoidCallback onListen;
  final bool isLight;

  const BookReaderTools({
    super.key,
    required this.onCopy,
    required this.onShare,
    required this.onNotes,
    required this.onQuote,
    required this.onSettings,
    required this.onListen,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _Tool(Icons.copy_rounded, 'Copy', onCopy),
      _Tool(Icons.share_rounded, 'Share', onShare),
      _Tool(Icons.note_add_rounded, 'Notes', onNotes),
      _Tool(Icons.format_quote_rounded, 'Quote', onQuote),
      _Tool(Icons.record_voice_over_rounded, 'Listen', onListen),
      _Tool(Icons.tune_rounded, 'Settings', onSettings),
    ];

    final chipBg =
        isLight ? const Color(0xFFFFFBF4) : Colors.white.withOpacity(0.07);
    final chipBorder =
        isLight ? const Color(0xFFE6D8C3) : Colors.white.withOpacity(0.10);
    final chipText = isLight ? const Color(0xFF1E1B16) : Colors.white;

    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return ActionChip(
            onPressed: item.onTap,
            avatar: Icon(item.icon, color: chipText, size: 18),
            backgroundColor: chipBg,
            side: BorderSide(color: chipBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            label: Text(
              item.label,
              style: TextStyle(
                color: chipText,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Tool(this.icon, this.label, this.onTap);
}
