import 'package:flutter/material.dart';

class ScripturePreviewSheet extends StatelessWidget {
  const ScripturePreviewSheet({
    super.key,
    required this.reference,
    this.verse = '',
    this.note = '',
  });

  final String reference;
  final String verse;
  final String note;

  Map<String, dynamic> _payload(String action) {
    return {
      'action': action,
      'reference': reference.trim(),
      'verse': verse.trim(),
      'note': note.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reference.trim().isEmpty ? 'Scripture' : reference.trim(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (verse.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                verse.trim(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note.trim(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.menu_book_rounded,
              label: 'Open in Bible',
              onTap: () => Navigator.pop(context, _payload('bible')),
            ),
            _ActionTile(
              icon: Icons.note_add_rounded,
              label: 'Add to Note',
              onTap: () => Navigator.pop(context, _payload('note')),
            ),
            _ActionTile(
              icon: Icons.format_quote_rounded,
              label: 'Make Quote',
              onTap: () => Navigator.pop(context, _payload('quote')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: const Icon(Icons.circle, color: Colors.transparent, size: 0),
      title: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
