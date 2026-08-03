import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/theme_controller.dart';

class ParagraphBlock extends StatelessWidget {
  final String text;
  final ValueChanged<String>? onMakeQuote;
  final ValueChanged<String>? onAddToNotes;
  final ValueChanged<String>? onOpenInBible;

  const ParagraphBlock({
    super.key,
    required this.text,
    this.onMakeQuote,
    this.onAddToNotes,
    this.onOpenInBible,
  });

  String _selectedOrWholeText(TextSelection selection) {
    final clean = text.trim();
    if (clean.isEmpty) return '';

    if (!selection.isValid || selection.isCollapsed) {
      return clean;
    }

    final start = selection.start < selection.end ? selection.start : selection.end;
    final end = selection.start < selection.end ? selection.end : selection.start;

    if (start < 0 || end > text.length || start >= end) {
      return clean;
    }

    final picked = text.substring(start, end).trim();
    return picked.isEmpty ? clean : picked;
  }

  String _detectBibleReference(String input) {
    final cleaned = input.replaceAll('\n', ' ');
    final regex = RegExp(
      r'\b(?:[1-3]\s*)?(?:Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|Samuel|Kings|Chronicles|Ezra|Nehemiah|Esther|Job|Psalms?|Proverbs|Ecclesiastes|Song of Solomon|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|Corinthians|Galatians|Ephesians|Philippians|Colossians|Thessalonians|Timothy|Titus|Philemon|Hebrews|James|Peter|Jude|Revelation)\s+\d+:\d+(?:-\d+)?\b',
      caseSensitive: false,
    );

    final match = regex.firstMatch(cleaned);
    if (match == null) return '';
    return (match.group(0) ?? '').trim();
  }

  Future<void> _copySelectedText(
    BuildContext context,
    TextSelection selection,
  ) async {
    final selectedText = _selectedOrWholeText(selection);
    if (selectedText.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: selectedText));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selected text copied')),
    );
  }

  void _openNoteEditor(BuildContext context, TextSelection selection) {
    final selectedText = _selectedOrWholeText(selection);
    if (selectedText.isEmpty) return;

    if (onAddToNotes != null) {
      onAddToNotes!(selectedText);
      return;
    }

    context.push(
      '/tools/notes/editor',
      extra: {
        'sourceType': 'article',
        'prefill': selectedText,
      },
    );
  }

  void _openQuoteCreator(BuildContext context, TextSelection selection) {
    final selectedText = _selectedOrWholeText(selection);
    if (selectedText.isEmpty) return;

    if (onMakeQuote != null) {
      onMakeQuote!(selectedText);
      return;
    }

    context.push(
      '/tools/quote',
      extra: {
        'prefill': selectedText,
      },
    );
  }

  void _openBibleReader(BuildContext context, TextSelection selection) {
    final selectedText = _selectedOrWholeText(selection);
    if (selectedText.isEmpty) return;

    final detectedReference = _detectBibleReference(selectedText);
    if (detectedReference.isEmpty) return;

    if (onOpenInBible != null) {
      onOpenInBible!(detectedReference);
      return;
    }

    context.push(
      '/tools/bible/reader',
      extra: {
        'ref': detectedReference,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final isLight = ThemeController.instance.isLightMode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SelectableText(
        text,
        style: TextStyle(
          color: isLight
              ? const Color(0xFF242938)
              : Colors.white.withOpacity(0.88),
          fontSize: 15,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
        contextMenuBuilder: (context, editableTextState) {
          final selection = editableTextState.textEditingValue.selection;
          final selectedText = _selectedOrWholeText(selection);
          final detectedReference = _detectBibleReference(selectedText);
          final defaultItems = editableTextState.contextMenuButtonItems;

          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: editableTextState.contextMenuAnchors,
            buttonItems: [
              ...defaultItems,
              ContextMenuButtonItem(
                label: 'Copy',
                onPressed: () {
                  ContextMenuController.removeAny();
                  _copySelectedText(context, selection);
                },
              ),
              ContextMenuButtonItem(
                label: 'Save to Note',
                onPressed: () {
                  ContextMenuController.removeAny();
                  _openNoteEditor(context, selection);
                },
              ),
              ContextMenuButtonItem(
                label: 'Make Quote',
                onPressed: () {
                  ContextMenuController.removeAny();
                  _openQuoteCreator(context, selection);
                },
              ),
              if (detectedReference.isNotEmpty)
                ContextMenuButtonItem(
                  label: 'Open in Bible',
                  onPressed: () {
                    ContextMenuController.removeAny();
                    _openBibleReader(context, selection);
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
