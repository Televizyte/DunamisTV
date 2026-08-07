import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../models/dynamic_section.dart';
import '../navigation/dynamic_action_executor.dart';
import '../../../ui/shared/designers/dxm_design_parser.dart';
import '../../../ui/shared/designers/dxm_dynamic_quote_card.dart';
import '../../../ui/shared/designers/public_attribution_normalizer.dart';
import '../../../features/notes/models/note_model.dart';
import '../../../features/notes/state/notes_store.dart';

class DynamicHubCardRenderer extends StatelessWidget {
  final HubDynamicCard card;
  final double height;
  final int index;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const DynamicHubCardRenderer({
    super.key,
    required this.card,
    this.height = 160,
    this.index = 0,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (_isDesignedDailyCard(card)) {
      return Padding(
        padding: padding,
        child: _DesignedDailyCard(
          card: card,
          index: index,
          borderRadius: borderRadius,
          onOpen: onTap ?? () => _open(context),
        ),
      );
    }

    final safeTitle = card.title.trim();
    final safeSubtitle = card.subtitle.trim();
    final safeBadge =
        card.badge.trim().isNotEmpty ? card.badge.trim() : _badgeFromCard(card);
    final imageUrl = card.imageUrl.trim();

    return Padding(
      padding: padding,
      child: Opacity(
        opacity: card.enabled ? 1 : 0.58,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: card.enabled ? (onTap ?? () => _open(context)) : null,
            child: Ink(
              height: height,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    color: Colors.black.withOpacity(0.18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: borderRadius,
                    child: _DynamicCardImage(
                      imageUrl: imageUrl,
                      height: height,
                      index: index,
                    ),
                  ),
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.08),
                          Colors.black.withOpacity(0.20),
                          Colors.black.withOpacity(0.76),
                        ],
                        stops: const [0.0, 0.42, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -8,
                    bottom: -10,
                    child: Icon(
                      card.icon,
                      size: 92,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _DynamicCardBadge(text: safeBadge),
                            const Spacer(),
                            Icon(
                              card.icon,
                              color: Colors.white.withOpacity(0.92),
                              size: 23,
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (safeTitle.isNotEmpty)
                          Text(
                            safeTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        if (safeSubtitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            safeSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.88),
                              fontSize: 12.5,
                              height: 1.25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    await DynamicActionExecutor.execute(
      context,
      DynamicActionExecutor.fromCard(card),
    );
  }

  static String _badgeFromCard(HubDynamicCard card) {
    final value =
        '${card.title} ${card.type} ${card.route} ${card.url} ${card.engine}'
            .toLowerCase();

    if (value.contains('live')) return 'LIVE';
    if (value.contains('video')) return 'VIDEO';
    if (value.contains('short')) return 'SHORT';
    if (value.contains('article')) return 'READ';
    if (value.contains('quote')) return 'QUOTE';
    if (value.contains('scripture')) return 'WORD';
    if (value.contains('bible')) return 'BIBLE';
    if (value.contains('note')) return 'NOTE';
    if (value.contains('game')) return 'GAME';
    if (value.contains('web')) return 'WEB';

    return 'OPEN';
  }
}

class DynamicHubCompactCardRenderer extends StatelessWidget {
  final HubDynamicCard card;
  final int index;
  final VoidCallback? onTap;

  const DynamicHubCompactCardRenderer({
    super.key,
    required this.card,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (_isDesignedDailyCard(card)) {
      return _DesignedDailyCard(
        card: card,
        index: index,
        borderRadius: BorderRadius.circular(22),
        onOpen: onTap ?? () => _open(context),
      );
    }

    final safeTitle = card.title.trim();
    final safeSubtitle = card.subtitle.trim();

    return Opacity(
      opacity: card.enabled ? 1 : 0.58,
      child: Material(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: card.enabled ? (onTap ?? () => _open(context)) : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: _gradientFor(index),
                  ),
                  child: Icon(
                    card.icon,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (safeTitle.isNotEmpty)
                        Text(
                          safeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                      if (safeSubtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          safeSubtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.68),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withOpacity(0.62),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    await DynamicActionExecutor.execute(
      context,
      DynamicActionExecutor.fromCard(card),
    );
  }

  LinearGradient _gradientFor(int index) {
    const palettes = [
      [Color(0xFF1D5CFF), Color(0xFFE2388A)],
      [Color(0xFF5F3BFF), Color(0xFF35C6FF)],
      [Color(0xFF087E8B), Color(0xFFB9FBC0)],
      [Color(0xFF8E24AA), Color(0xFFFF4E8A)],
      [Color(0xFF2563EB), Color(0xFF9333EA)],
    ];

    final colors = palettes[index % palettes.length];

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}

class DynamicHubIconCardRenderer extends StatelessWidget {
  final HubDynamicCard card;
  final int index;
  final VoidCallback? onTap;

  const DynamicHubIconCardRenderer({
    super.key,
    required this.card,
    this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeTitle = card.title.trim();

    return Opacity(
      opacity: card.enabled ? 1 : 0.58,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: card.enabled ? (onTap ?? () => _open(context)) : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.055),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _gradientFor(index),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                        color: Colors.black.withOpacity(0.16),
                      ),
                    ],
                  ),
                  child: Icon(
                    card.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (safeTitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    safeTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      height: 1.12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    await DynamicActionExecutor.execute(
      context,
      DynamicActionExecutor.fromCard(card),
    );
  }

  LinearGradient _gradientFor(int index) {
    const palettes = [
      [Color(0xFF1D5CFF), Color(0xFFE2388A)],
      [Color(0xFF5F3BFF), Color(0xFF35C6FF)],
      [Color(0xFF087E8B), Color(0xFFB9FBC0)],
      [Color(0xFF8E24AA), Color(0xFFFF4E8A)],
      [Color(0xFF2563EB), Color(0xFF9333EA)],
    ];

    final colors = palettes[index % palettes.length];

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}

class _DesignedDailyCard extends StatelessWidget {
  final HubDynamicCard card;
  final int index;
  final BorderRadius borderRadius;
  final VoidCallback? onOpen;
  final GlobalKey _canvasKey = GlobalKey();

  _DesignedDailyCard({
    required this.card,
    required this.index,
    required this.borderRadius,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final design = _designFromCard(card);
    final content = _DailyContent.fromCard(card);

    return Opacity(
      opacity: card.enabled ? 1 : 0.58,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: card.enabled
              ? () => _showDesignedPreview(context, design, content)
              : null,
          child: DxmDynamicQuoteCard(
            mainText: content.mainText,
            supportText: content.supportText,
            referenceText: content.reference,
            design: design,
            showActionsBar: true,
            canvasKey: _canvasKey,
            borderRadius: borderRadius,
            actions: [
              Expanded(
                child: _DesignedDailyPillButton(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Quote',
                  onPressed: card.enabled ? onOpen : null,
                  accentColor: design.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DesignedDailyPillButton(
                  icon: Icons.note_add_rounded,
                  label: 'Add',
                  onPressed: card.enabled
                      ? () => _addDesignedQuoteToNotes(context, content)
                      : null,
                  accentColor: design.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DesignedDailyPillButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onPressed: card.enabled
                      ? () => _shareDesignedQuoteImage(context, content)
                      : null,
                  accentColor: design.accentColor,
                  primary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DxmDesignData _designFromCard(HubDynamicCard card) {
    final raw = _flattenCardRaw(card.raw);
    final backgroundImage = card.imageUrl.trim().isNotEmpty
        ? card.imageUrl.trim()
        : _stringValue(raw['thumbnail_url'] ?? raw['background_image_url']);

    return DxmDesignData.fromMap(
      raw,
      imageUrl: backgroundImage,
      fallbackMainFontSize: 24,
      fallbackSupportFontSize: 12,
    );
  }

  Future<void> _addDesignedQuoteToNotes(
    BuildContext context,
    _DailyContent content,
  ) async {
    final text = _plainQuoteText(content);
    if (text.trim().isEmpty) return;

    try {
      final store = NotesStore();
      await store.init();
      final note = NoteModel.empty(
        id: 'quote_${DateTime.now().millisecondsSinceEpoch}',
        sourceType: 'quote',
        sourceId: (card.raw['id'] ??
                card.raw['content_id'] ??
                card.raw['post_id'] ??
                card.key ??
                card.title)
            .toString(),
      ).copyWith(
        title: _shortNoteTitle(content.mainText),
        content: text,
        category: 'Quotes',
        tags: const ['quote'],
      );
      await store.saveNote(note);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote added to Notes')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add quote to Notes')),
      );
    }
  }

  Future<void> _shareDesignedQuoteImage(
    BuildContext context,
    _DailyContent content,
  ) async {
    try {
      final bytes = await _renderDesignedQuoteToPng();
      final fileName = 'quote_${DateTime.now().millisecondsSinceEpoch}.png';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        text: content.supportText.isNotEmpty ? content.supportText : 'Quote',
        subject: 'Quote',
      );
    } catch (_) {
      final fallback = _plainQuoteText(content);
      if (fallback.trim().isNotEmpty) {
        await Share.share(fallback, subject: 'Quote');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share quote')),
        );
      }
    }
  }

  Future<Uint8List> _renderDesignedQuoteToPng() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Quote canvas is not ready');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to render quote image');
    }

    return byteData.buffer.asUint8List();
  }

  String _plainQuoteText(_DailyContent content) {
    final parts = <String>[
      content.mainText.trim(),
      if (content.supportText.trim().isNotEmpty) content.supportText.trim(),
      if (content.reference.trim().isNotEmpty) content.reference.trim(),
    ];
    return parts.where((part) => part.isNotEmpty).join('\n');
  }

  String _shortNoteTitle(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return 'Quote';
    if (clean.length <= 54) return clean;
    return '${clean.substring(0, 54).trim()}...';
  }

  void _showDesignedPreview(
    BuildContext context,
    DxmDesignData design,
    _DailyContent content,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (context) {
        final previewCanvasKey = GlobalKey();
        final screen = MediaQuery.sizeOf(context);
        final availableWidth = screen.width - 32;
        final availableHeight = screen.height - 128;
        const actionHeight = 46.0;
        const actionGap = 10.0;

        var previewWidth = availableWidth;
        var previewHeight = previewWidth / design.aspectRatio;
        final maxPreviewHeight = availableHeight - actionHeight - actionGap;

        if (previewHeight > maxPreviewHeight) {
          previewHeight = maxPreviewHeight;
          previewWidth = previewHeight * design.aspectRatio;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: previewWidth,
                  height: previewHeight,
                  child: DxmDynamicQuoteCard(
                    mainText: content.mainText,
                    supportText: content.supportText,
                    referenceText: content.reference,
                    design: design,
                    showActionsBar: false,
                    canvasKey: previewCanvasKey,
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                const SizedBox(height: actionGap),
                SizedBox(
                  width: previewWidth,
                  height: actionHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => _saveDesignedPreviewImage(
                          context,
                          previewCanvasKey,
                          content,
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Save Image'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _shareDesignedPreviewImage(
                          context,
                          previewCanvasKey,
                          content,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveDesignedPreviewImage(
    BuildContext context,
    GlobalKey previewCanvasKey,
    _DailyContent content,
  ) async {
    await _shareDesignedPreviewImage(
      context,
      previewCanvasKey,
      content,
      subject: 'Save quote image',
      text:
          content.supportText.isNotEmpty ? content.supportText : 'Quote image',
      filePrefix: 'quote_save',
    );
  }

  Future<void> _shareDesignedPreviewImage(
    BuildContext context,
    GlobalKey previewCanvasKey,
    _DailyContent content, {
    String subject = 'Quote image',
    String text = 'Quote image',
    String filePrefix = 'quote',
  }) async {
    try {
      final bytes = await _renderPreviewQuoteToPng(previewCanvasKey);
      final fileName =
          '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.png';
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'image/png',
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        text: text,
        subject: subject,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare quote image')),
      );
    }
  }

  Future<Uint8List> _renderPreviewQuoteToPng(GlobalKey previewCanvasKey) async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = previewCanvasKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Quote preview canvas is not ready');
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Unable to render quote preview image');
    }

    return byteData.buffer.asUint8List();
  }
}

class _DesignedDailyActionBar extends StatelessWidget {
  final Color accentColor;
  final VoidCallback? onOpen;

  const _DesignedDailyActionBar({
    required this.accentColor,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1428).withOpacity(0.96),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DesignedDailyPillButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Quote',
              onPressed: onOpen,
              accentColor: accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DesignedDailyPillButton(
              icon: Icons.note_add_rounded,
              label: 'Add',
              onPressed: () {},
              accentColor: accentColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DesignedDailyPillButton(
              icon: Icons.share_rounded,
              label: 'Share',
              onPressed: () {},
              accentColor: accentColor,
              primary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignedDailyPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color accentColor;
  final bool primary;

  const _DesignedDailyPillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.accentColor,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? Colors.white : Colors.white.withOpacity(0.06);
    final fg = primary ? const Color(0xFF101528) : Colors.white;
    final border = primary ? Colors.white : accentColor.withOpacity(0.35);

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withOpacity(0.6),
        disabledForegroundColor: fg.withOpacity(0.55),
        side: BorderSide(color: border.withOpacity(0.8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _DesignedDailyBackground extends StatelessWidget {
  final _RenderStyle style;
  final String imageUrl;
  final int index;

  const _DesignedDailyBackground({
    required this.style,
    required this.imageUrl,
    required this.index,
  });

  bool get _hasRemoteImage {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    if (style.backgroundMode == 'image' && _hasRemoteImage) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradient(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Stack(
            children: [
              _gradient(),
              Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return _gradient();
  }

  Widget _gradient() {
    if (style.backgroundMode == 'solid') {
      return Container(color: style.bgColor);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            style.bgColor,
            style.bgColor2,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -42,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.accentColor.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: -34,
            bottom: -38,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesignedDailyTextBlock extends StatelessWidget {
  final _RenderStyle style;
  final _DailyContent content;

  const _DesignedDailyTextBlock({
    required this.style,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final mainText = content.mainText.trim();
    final supportText = content.supportText.trim();
    final refText = content.reference.trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: style.crossAxisAlignment,
      children: [
        if (content.isQuote && style.showQuoteMark)
          Text(
            '“',
            textAlign: style.textAlign,
            style: TextStyle(
              color: style.accentColor.withOpacity(0.95),
              fontSize: (style.titleSize * 1.7).clamp(28, 90),
              height: 0.8,
              fontFamily: style.fontFamily,
              fontWeight: style.fontWeight,
            ),
          ),
        if (mainText.isNotEmpty)
          Text(
            mainText,
            textAlign: style.textAlign,
            style: TextStyle(
              color: style.textColor,
              fontSize: style.titleSize,
              height: style.lineHeight,
              fontFamily: style.fontFamily,
              fontWeight: style.fontWeight,
              letterSpacing: style.fontFamily == 'Impact' ? 0.2 : null,
            ),
          ),
        if (supportText.isNotEmpty) ...[
          SizedBox(height: style.titleSize * 0.45),
          Text(
            supportText,
            textAlign: style.textAlign,
            style: TextStyle(
              color: style.textColor.withOpacity(0.86),
              fontSize: style.fontSize,
              height: style.lineHeight,
              fontFamily: style.fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (refText.isNotEmpty) ...[
          SizedBox(height: style.titleSize * 0.50),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: style.accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: style.accentColor.withOpacity(0.35),
              ),
            ),
            child: Text(
              refText,
              textAlign: style.textAlign,
              style: TextStyle(
                color: style.textColor.withOpacity(0.94),
                fontSize: (style.fontSize * 0.92).clamp(8, 18),
                height: 1.1,
                fontFamily: style.fontFamily,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DynamicCardImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final int index;

  const _DynamicCardImage({
    required this.imageUrl,
    required this.height,
    required this.index,
  });

  bool get _hasRemoteImage {
    final uri = Uri.tryParse(imageUrl.trim());
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl.trim(),
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _DynamicCardGradientPlaceholder(
            height: height,
            index: index,
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Stack(
            children: [
              _DynamicCardGradientPlaceholder(
                height: height,
                index: index,
              ),
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return _DynamicCardGradientPlaceholder(
      height: height,
      index: index,
    );
  }
}

class _DynamicCardGradientPlaceholder extends StatelessWidget {
  final double height;
  final int index;

  const _DynamicCardGradientPlaceholder({
    required this.height,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFF0B1F4D), Color(0xFF1D5CFF), Color(0xFFE2388A)],
      [Color(0xFF180B3A), Color(0xFF5F3BFF), Color(0xFF35C6FF)],
      [Color(0xFF081F2D), Color(0xFF087E8B), Color(0xFFB9FBC0)],
      [Color(0xFF2A0D30), Color(0xFF8E24AA), Color(0xFFFF4E8A)],
      [Color(0xFF111827), Color(0xFF2563EB), Color(0xFF9333EA)],
    ];

    final colors = palettes[index % palettes.length];

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -38,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -34,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicCardBadge extends StatelessWidget {
  final String text;

  const _DynamicCardBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final safeText = text.trim().isEmpty ? 'OPEN' : text.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        safeText.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Map<String, dynamic> _flattenCardRaw(Map<String, dynamic> source) {
  final output = <String, dynamic>{};

  void addMap(dynamic value) {
    if (value is! Map) return;
    for (final entry in value.entries) {
      output[entry.key.toString()] = entry.value;
    }
  }

  addMap(source);

  for (final key in const [
    'payload',
    'style',
    'render_style',
    'design',
    'quote_card',
    'meta',
    'meta_json',
    'cover',
    'media',
  ]) {
    final nested = source[key];
    addMap(nested);

    if (key == 'payload' && nested is Map) {
      for (final payloadKey in const [
        'meta',
        'style',
        'render_style',
        'design',
        'quote_card',
      ]) {
        addMap(nested[payloadKey]);
      }
    }

    if (key == 'quote_card' && nested is Map) {
      addMap(nested['colors']);
      addMap(nested['layout']);
      addMap(nested['typography']);
    }
  }

  final blocks = source['blocks'] ?? source['blocks_json'];
  if (blocks is List && blocks.isNotEmpty) {
    final first = blocks.first;
    addMap(first);
    if (first is Map) addMap(first['meta']);
  }

  return output;
}

class _DailyContent {
  final String kind;
  final String mainText;
  final String supportText;
  final String reference;

  const _DailyContent({
    required this.kind,
    required this.mainText,
    required this.supportText,
    required this.reference,
  });

  bool get isQuote => kind == 'daily_quote';

  factory _DailyContent.fromCard(HubDynamicCard card) {
    final raw = _flattenCardRaw(card.raw);
    final kind = _stringValue(raw['daily_kind'] ?? raw['home_kind']);

    if (kind == 'daily_scripture') {
      return _DailyContent(
        kind: kind,
        mainText: _stringValue(
          raw['scripture_text'] ??
              raw['verse'] ??
              raw['text'] ??
              raw['main_text'] ??
              card.title,
        ),
        supportText: _stringValue(
          raw['scripture_note'] ??
              raw['note'] ??
              raw['subtitle'] ??
              card.subtitle,
        ),
        reference: _publicAttributionFrom([
          raw['scripture_reference'],
          raw['reference'],
          raw['ref'],
        ]),
      );
    }

    final quote = _stringValue(
      raw['quote'] ??
          raw['quote_text'] ??
          raw['text'] ??
          raw['main_text'] ??
          raw['title'] ??
          card.title,
    );

    final source = _publicAttributionFrom([
      raw['quote_source'],
      raw['source'],
      raw['author_name'],
      raw['subtitle'],
      card.subtitle,
    ]);

    return _DailyContent(
      kind: kind == 'daily_quote' ? kind : 'daily_quote',
      mainText: quote,
      supportText: source,
      reference: '',
    );
  }
}

class _RenderStyle {
  final String standard;
  final String backgroundMode;
  final String cardFormat;
  final String? fontFamily;
  final String textScaleMode;
  final Color textColor;
  final Color bgColor;
  final Color bgColor2;
  final Color accentColor;
  final double fontSize;
  final double titleSize;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final Alignment alignment;
  final Alignment horizontalAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final int overlayStrength;
  final int contentWidth;
  final double cardPadding;
  final double lineHeight;
  final bool showQuoteMark;

  const _RenderStyle({
    required this.standard,
    required this.backgroundMode,
    required this.cardFormat,
    required this.fontFamily,
    required this.textScaleMode,
    required this.textColor,
    required this.bgColor,
    required this.bgColor2,
    required this.accentColor,
    required this.fontSize,
    required this.titleSize,
    required this.fontWeight,
    required this.textAlign,
    required this.alignment,
    required this.horizontalAlignment,
    required this.crossAxisAlignment,
    required this.overlayStrength,
    required this.contentWidth,
    required this.cardPadding,
    required this.lineHeight,
    required this.showQuoteMark,
  });

  double get aspectRatio {
    switch (cardFormat.trim().toLowerCase()) {
      case 'square':
        return 1;
      case 'story':
        return 9 / 16;
      case 'landscape':
      case 'wide':
        return 16 / 9;
      case 'cinematic':
        return 21 / 9;
      case 'classic':
        return 3 / 2;
      case 'portrait':
      default:
        return 4 / 5;
    }
  }

  factory _RenderStyle.fromCard(HubDynamicCard card) {
    final raw = card.raw;
    final payload = _mapValue(raw['payload']) ?? const <String, dynamic>{};
    final explicitStyle = _mapValue(raw['render_style']) ??
        _mapValue(raw['style']) ??
        _mapValue(raw['design']) ??
        _mapValue(payload['render_style']) ??
        _mapValue(payload['style']) ??
        _mapValue(payload['design']) ??
        const <String, dynamic>{};
    final style = <String, dynamic>{
      ...raw,
      ...payload,
      ...explicitStyle,
    };

    final textAlign = _parseTextAlign(_stringValue(style['text_align']));
    final verticalAlign = _stringValue(style['vertical_align']);
    final horizontalAlign = _stringValue(style['text_align']);

    return _RenderStyle(
      standard:
          _stringValue(style['standard'], fallback: 'dxm_render_style_v1'),
      backgroundMode: _stringValue(
          style['background_mode'] ??
              style['backgroundMode'] ??
              style['background_type'] ??
              style['backgroundType'] ??
              style['background'] ??
              style['bg_mode'],
          fallback: 'gradient'),
      cardFormat: _stringValue(
          style['card_format'] ??
              style['cardFormat'] ??
              style['card_ratio'] ??
              style['cardRatio'] ??
              style['aspect_ratio'] ??
              style['aspectRatio'] ??
              style['format_ratio'] ??
              style['format'] ??
              style['ratio'],
          fallback: 'portrait'),
      fontFamily: _fontFamily(_stringValue(style['font_family'])),
      textScaleMode: _stringValue(style['text_scale_mode'], fallback: 'auto'),
      textColor: _colorValue(
          style['text_color'] ??
              style['textColor'] ??
              style['main_text_color'] ??
              style['quote_text_color'] ??
              style['font_color'] ??
              style['color'],
          const Color(0xFFFFFFFF)),
      bgColor: _colorValue(
          style['bg_color'] ??
              style['bgColor'] ??
              style['background_color'] ??
              style['backgroundColor'] ??
              style['solid_color'] ??
              style['card_color'],
          const Color(0xFF160042)),
      bgColor2: _colorValue(
          style['bg_color_2'] ??
              style['bgColor2'] ??
              style['background_color_2'] ??
              style['backgroundColor2'] ??
              style['gradient_color_2'],
          const Color(0xFFE2388A)),
      accentColor: _colorValue(
          style['accent_color'] ??
              style['accentColor'] ??
              style['highlight_color'] ??
              style['highlightColor'] ??
              style['highlight_text_color'] ??
              style['brand_color'],
          const Color(0xFF38BDF8)),
      fontSize: _doubleValue(
        style['font_size'] ??
            style['fontSize'] ??
            style['support_font_size'] ??
            style['source_size'] ??
            style['source_font_size'] ??
            style['sourceFontSize'],
        fallback: 14,
        min: 8,
        max: 40,
      ),
      titleSize: _doubleValue(
        style['title_size'] ??
            style['titleSize'] ??
            style['main_font_size'] ??
            style['mainFontSize'] ??
            style['quote_size'] ??
            style['quote_font_size'] ??
            style['quoteFontSize'] ??
            style['text_size'] ??
            style['textSize'],
        fallback: 24,
        min: 10,
        max: 64,
      ),
      fontWeight: _fontWeight(_stringValue(style['font_weight'])),
      textAlign: textAlign,
      alignment: _parseAlignment(verticalAlign, horizontalAlign),
      horizontalAlignment: _parseHorizontalAlignment(horizontalAlign),
      crossAxisAlignment: _parseCrossAxisAlignment(horizontalAlign),
      overlayStrength: _intValue(
          style['overlay_strength'] ??
              style['overlayStrength'] ??
              style['overlay_opacity'],
          fallback: 58,
          min: 0,
          max: 100),
      contentWidth: _intValue(
          style['content_width'] ??
              style['contentWidth'] ??
              style['text_width'] ??
              style['textWidth'],
          fallback: 86,
          min: 45,
          max: 100),
      cardPadding: _doubleValue(
        style['card_padding'] ??
            style['card_padding_x'] ??
            style['padding_x'] ??
            style['padding'],
        fallback: 34,
        min: 12,
        max: 80,
      ),
      lineHeight: _doubleValue(
          style['line_height'] ??
              style['lineHeight'] ??
              style['text_line_height'],
          fallback: 1.35,
          min: 1,
          max: 2),
      showQuoteMark: _boolValue(
          style['show_quote_mark'] ??
              style['showQuoteMark'] ??
              style['quote_mark'],
          fallback: true),
    );
  }
}

bool _isDesignedDailyCard(HubDynamicCard card) {
  final raw = card.raw;
  final dailyKind = _stringValue(raw['daily_kind'] ?? raw['home_kind']);
  final style = _mapValue(raw['render_style']) ??
      _mapValue(raw['style']) ??
      _mapValue(raw['payload']);
  final payload = _mapValue(raw['payload']) ?? const <String, dynamic>{};
  final builder = _mapValue(raw['item_builder']) ??
      _mapValue(payload['item_builder']) ??
      const <String, dynamic>{};
  final type = _stringValue(raw['type']).toLowerCase();
  final layout = _stringValue(raw['layout']).toLowerCase();
  final kind = _stringValue(builder['kind']).toLowerCase();
  final designerType = _stringValue(payload['designer_type']).toLowerCase();

  if (dailyKind == 'daily_scripture' || dailyKind == 'daily_quote') {
    return true;
  }

  if (type.contains('quote') ||
      layout.contains('quote') ||
      kind.contains('quote') ||
      designerType == 'quote_card') {
    return true;
  }

  if (style != null &&
      _stringValue(style['standard']) == 'dxm_render_style_v1') {
    return true;
  }

  return false;
}

dynamic _payloadValue(Map<String, dynamic> raw, String key) {
  final payload = _mapValue(raw['payload']);
  if (payload == null) return null;
  return payload[key];
}

Map<String, dynamic>? _mapValue(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  return null;
}

String _stringValue(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is Map || value is Iterable) return fallback;
  final text = value.toString().trim();
  if (text.startsWith('{') || text.startsWith('(')) return fallback;
  return text.isEmpty ? fallback : text;
}

String _publicAttributionFrom(Iterable<Object?> values) {
  for (final value in values) {
    final normalized = PublicAttributionNormalizer.normalize(value);
    if (normalized != null) return normalized;
  }
  return '';
}

int _intValue(
  dynamic value, {
  required int fallback,
  required int min,
  required int max,
}) {
  final parsed = int.tryParse((value ?? '').toString().trim());
  if (parsed == null) return fallback;
  if (parsed < min) return min;
  if (parsed > max) return max;
  return parsed;
}

double _doubleValue(
  dynamic value, {
  required double fallback,
  required double min,
  required double max,
}) {
  final parsed = double.tryParse((value ?? '').toString().trim());
  if (parsed == null) return fallback;
  if (parsed < min) return min;
  if (parsed > max) return max;
  return parsed;
}

bool _boolValue(dynamic value, {required bool fallback}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final raw = value.toString().trim().toLowerCase();

  if (raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on') return true;
  if (raw == '0' || raw == 'false' || raw == 'no' || raw == 'off') return false;

  return fallback;
}

Color _colorValue(dynamic value, Color fallback) {
  final raw = (value ?? '').toString().trim();

  if (raw.isEmpty) return fallback;

  final clean = raw.replaceAll('#', '').replaceAll('0x', '');

  if (clean.length == 6) {
    final parsed = int.tryParse('FF$clean', radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  if (clean.length == 8) {
    final parsed = int.tryParse(clean, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }

  return fallback;
}

String? _fontFamily(String value) {
  switch (value.trim().toLowerCase()) {
    case 'serif':
      return 'serif';
    case 'georgia':
      return 'Georgia';
    case 'impact':
      return 'Impact';
    case 'mono':
    case 'monospace':
      return 'monospace';
    case 'system':
    default:
      return null;
  }
}

FontWeight _fontWeight(String value) {
  switch (value.trim()) {
    case '100':
      return FontWeight.w100;
    case '200':
      return FontWeight.w200;
    case '300':
      return FontWeight.w300;
    case '400':
      return FontWeight.w400;
    case '500':
      return FontWeight.w500;
    case '600':
      return FontWeight.w600;
    case '800':
      return FontWeight.w800;
    case '900':
      return FontWeight.w900;
    case '700':
    default:
      return FontWeight.w700;
  }
}

TextAlign _parseTextAlign(String value) {
  switch (value.trim().toLowerCase()) {
    case 'left':
    case 'start':
      return TextAlign.left;
    case 'right':
    case 'end':
      return TextAlign.right;
    case 'center':
    default:
      return TextAlign.center;
  }
}

Alignment _parseAlignment(String vertical, String horizontal) {
  final v = vertical.trim().toLowerCase();
  final h = horizontal.trim().toLowerCase();

  if (v == 'start' && (h == 'left' || h == 'start')) return Alignment.topLeft;
  if (v == 'start' && (h == 'right' || h == 'end')) return Alignment.topRight;
  if (v == 'start') return Alignment.topCenter;

  if (v == 'end' && (h == 'left' || h == 'start')) return Alignment.bottomLeft;
  if (v == 'end' && (h == 'right' || h == 'end')) return Alignment.bottomRight;
  if (v == 'end') return Alignment.bottomCenter;

  if (h == 'left' || h == 'start') return Alignment.centerLeft;
  if (h == 'right' || h == 'end') return Alignment.centerRight;

  return Alignment.center;
}

Alignment _parseHorizontalAlignment(String horizontal) {
  final h = horizontal.trim().toLowerCase();

  if (h == 'left' || h == 'start') return Alignment.centerLeft;
  if (h == 'right' || h == 'end') return Alignment.centerRight;

  return Alignment.center;
}

CrossAxisAlignment _parseCrossAxisAlignment(String horizontal) {
  final h = horizontal.trim().toLowerCase();

  if (h == 'left' || h == 'start') return CrossAxisAlignment.start;
  if (h == 'right' || h == 'end') return CrossAxisAlignment.end;

  return CrossAxisAlignment.center;
}
