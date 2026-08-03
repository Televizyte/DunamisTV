import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../features/quote_creator/state/quote_creator_scope.dart';
import '../../../features/quote_creator/state/quote_creator_store.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';
import 'quote_creator/quote_creator_payload.dart';
import 'quote_creator/quote_preview_card.dart';

class QuoteCreatorScreen extends StatelessWidget {
  const QuoteCreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return QuoteCreatorScope(
      store: QuoteCreatorStore(),
      child: const _QuoteCreatorView(),
    );
  }
}

class _QuoteCreatorView extends StatefulWidget {
  const _QuoteCreatorView();

  @override
  State<_QuoteCreatorView> createState() => _QuoteCreatorViewState();
}

class _QuoteCreatorViewState extends State<_QuoteCreatorView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _payloadApplied = false;
  bool _isPickingImage = false;

  String _incomingSourceType = '';
  String _incomingSourceId = '';
  String _incomingReference = '';
  String _incomingSourceLabel = '';
  bool _openedFromConnectedTool = false;

  @override
  void initState() {
    super.initState();
    AdsService.instance.preloadInterstitial(tabKey: 'explore:quote_creator');
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_payloadApplied) return;
    _payloadApplied = true;

    final store = QuoteCreatorScope.of(context);
    final extra = GoRouterState.of(context).extra;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyIncomingPayload(store, extra);
    });
  }

  void _applyIncomingPayload(QuoteCreatorStore store, Object? extra) {
    final result = applyQuoteCreatorIncomingPayload(
      store: store,
      extra: extra,
      quoteController: _quoteController,
      authorController: _authorController,
      resolveSourceLabel: _resolveSourceLabel,
    );

    if (result == null) return;

    _incomingSourceType = result.sourceType;
    _incomingSourceId = result.sourceId;
    _incomingReference = result.reference;
    _incomingSourceLabel = result.sourceLabel;
    _openedFromConnectedTool = result.openedFromConnectedTool;

    if (mounted) setState(() {});
  }

  String _resolveSourceLabel(String sourceType) {
    switch (sourceType.trim().toLowerCase()) {
      case 'bible':
        return 'Loaded from Bible';
      case 'article':
        return 'Loaded from Article';
      case 'note':
        return 'Loaded from Notes';
      case 'sod_quotes':
        return 'Loaded from SOD Quote';
      case 'daily-scripture':
        return 'Loaded from Daily Scripture';
      case 'daily-quote':
        return 'Loaded from Daily Quote';
      case 'quote':
        return 'Loaded from Quote';
      default:
        return '';
    }
  }

  void _resetEditor(QuoteCreatorStore store) {
    store.reset();
    _quoteController.clear();
    _authorController.clear();
    _incomingSourceType = '';
    _incomingSourceId = '';
    _incomingReference = '';
    _incomingSourceLabel = '';
    _openedFromConnectedTool = false;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromDevice(QuoteCreatorStore store) async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      final mimeType = _mimeTypeFromPath(file.path);
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

      store.setBackgroundImage(dataUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image inserted successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to insert image from device')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  String _mimeTypeFromPath(String path) {
    final value = path.toLowerCase();
    if (value.endsWith('.png')) return 'image/png';
    if (value.endsWith('.webp')) return 'image/webp';
    if (value.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _copyCurrentQuote(QuoteCreatorStore store) async {
    final quote = store.quote.trim();
    final author = store.author.trim();

    if (quote.isEmpty && author.isEmpty) return;

    final text = author.isEmpty ? quote : '$quote\n\n$author';
    await Clipboard.setData(ClipboardData(text: text.trim()));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied')),
    );
  }

  void _sendCurrentQuoteToNotes(QuoteCreatorStore store) {
    final quote = store.quote.trim();
    final author = store.author.trim();

    if (quote.isEmpty && author.isEmpty) return;

    final prefill = author.isEmpty ? quote : '$quote\n\n$author';

    context.push(
      '/tools/notes/editor',
      extra: {
        'title': author.isEmpty ? 'Quote Draft' : author,
        'prefill': prefill,
        'sourceType': 'quote',
        'sourceId': _incomingSourceId,
      },
    );
  }

  void _openBibleFromReference() {
    if (_incomingReference.trim().isEmpty) return;

    context.push(
      '/tools/bible/reader',
      extra: {
        'ref': _incomingReference.trim(),
      },
    );
  }

  PreferredSizeWidget _buildQuoteCreatorTopBar(
    BuildContext context,
    QuoteCreatorStore store,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(58),
      child: AnimatedBuilder(
        animation: ThemeController.instance,
        builder: (context, _) {
          final isLight = ThemeController.instance.isLightMode;

          return Container(
            decoration: const BoxDecoration(
              gradient: DxmTopBar.topGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Quote Creator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reset',
                      onPressed: () => _resetEditor(store),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: isLight
                          ? 'Switch to dark mode'
                          : 'Switch to light mode',
                      onPressed: () => ThemeController.instance.toggleTheme(),
                      icon: Icon(
                        isLight
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      tooltip: 'More',
                      onPressed: () => showDxmTopBarMenu(
                        context,
                        isLight: isLight,
                        onRefresh: () => _resetEditor(store),
                        extraItems: [
                          DxmTopBarMenuEntry(
                            icon: Icons.collections_bookmark_rounded,
                            title: 'My Designs',
                            subtitle: 'Open saved quote designs',
                            onTap: () {
                              context.push('/tools/quote/library');
                            },
                          ),
                        ],
                      ),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = QuoteCreatorScope.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([store, ThemeController.instance]),
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;

        return Scaffold(
          appBar: _buildQuoteCreatorTopBar(context, store),
          body: GradientPageBackground(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    children: [
                      QuotePreviewCard(
                        store: store,
                        isLight: isLight,
                      ),
                      const SizedBox(height: 14),
                      if (_openedFromConnectedTool)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ConnectedSourceCard(
                            isLight: isLight,
                            sourceLabel: _incomingSourceLabel,
                            reference: _incomingReference,
                            onCopyTap: () => _copyCurrentQuote(store),
                            onNotesTap: () => _sendCurrentQuoteToNotes(store),
                            onBibleTap: _incomingReference.trim().isEmpty
                                ? null
                                : _openBibleFromReference,
                          ),
                        ),
                      _EditorInputs(
                        store: store,
                        quoteController: _quoteController,
                        authorController: _authorController,
                        isLight: isLight,
                      ),
                      const SizedBox(height: 14),
                      _QuickInsertCard(
                        isLight: isLight,
                        incomingSourceLabel: _incomingSourceLabel,
                      ),
                      const SizedBox(height: 14),
                      _ControlsCard(
                        controller: _tabController,
                        store: store,
                        onPickImage: () => _pickImageFromDevice(store),
                        isPickingImage: _isPickingImage,
                        isLight: isLight,
                      ),
                      const SizedBox(height: 14),
                      _ActionButtons(
                        isLight: isLight,
                        onLibraryTap: () =>
                            context.push('/tools/quote/library'),
                        onNextTap: () {
                          context.push(
                            '/tools/quote/preview',
                            extra: store.toPayload(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SafeArea(
                  top: false,
                  child: BannerAdWidget(
                    tabKey: 'explore:quote_creator',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectedSourceCard extends StatelessWidget {
  final bool isLight;
  final String sourceLabel;
  final String reference;
  final VoidCallback onCopyTap;
  final VoidCallback onNotesTap;
  final VoidCallback? onBibleTap;

  const _ConnectedSourceCard({
    required this.isLight,
    required this.sourceLabel,
    required this.reference,
    required this.onCopyTap,
    required this.onNotesTap,
    required this.onBibleTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasReference = reference.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0A1027),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sourceLabel.isEmpty ? 'Connected Tools' : sourceLabel,
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF1E1B16)
                  : Colors.white.withOpacity(0.90),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasReference
                ? 'Reference detected: $reference'
                : 'Use the current quote across your connected tools.',
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF6B6256)
                  : Colors.white.withOpacity(0.62),
              fontSize: 11.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InsertActionChip(
                label: 'Copy',
                icon: Icons.copy_rounded,
                isLight: isLight,
                onTap: onCopyTap,
              ),
              _InsertActionChip(
                label: 'To Notes',
                icon: Icons.note_add_rounded,
                isLight: isLight,
                onTap: onNotesTap,
              ),
              if (hasReference && onBibleTap != null)
                _InsertActionChip(
                  label: 'Open Bible',
                  icon: Icons.menu_book_rounded,
                  isLight: isLight,
                  onTap: onBibleTap!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorInputs extends StatelessWidget {
  final QuoteCreatorStore store;
  final TextEditingController quoteController;
  final TextEditingController authorController;
  final bool isLight;

  const _EditorInputs({
    required this.store,
    required this.quoteController,
    required this.authorController,
    required this.isLight,
  });

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isLight ? const Color(0xFF8A7C68) : const Color(0xFF7E8098),
      ),
      filled: true,
      fillColor: isLight ? const Color(0xFFF2E8D8) : const Color(0xFF0E1430),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFFFF2C96), width: 1.2),
      ),
      contentPadding: const EdgeInsets.all(14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _quoteTokens(store.quote);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Main Quote Text',
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF1E1B16)
                  : Colors.white.withOpacity(0.86),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: quoteController,
            onChanged: store.setQuote,
            maxLines: 4,
            style: TextStyle(
              color: isLight ? const Color(0xFF1E1B16) : Colors.white,
              height: 1.35,
            ),
            decoration: _decoration('Type your main quote...'),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  isLight ? const Color(0xFFF7F1E6) : const Color(0xFF0A1027),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight
                    ? const Color(0xFFE6D8C3)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highlighted Words',
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF1E1B16)
                        : Colors.white.withOpacity(0.90),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap any word below to make part of the quote stand out.',
                  style: TextStyle(
                    color: isLight
                        ? const Color(0xFF6B6256)
                        : Colors.white.withOpacity(0.60),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                if (tokens.isEmpty)
                  Text(
                    'Type your main quote first to enable highlight styling.',
                    style: TextStyle(
                      color: isLight
                          ? const Color(0xFF6B6256)
                          : Colors.white.withOpacity(0.56),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tokens.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final token = tokens[index];
                        final selected = _isWordHighlighted(store, index);

                        return GestureDetector(
                          onTap: () => _toggleHighlight(store, index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? store.highlightColor.withOpacity(0.92)
                                  : (isLight
                                      ? const Color(0xFFF2E8D8)
                                      : const Color(0xFF151C3A)),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected
                                    ? Colors.white.withOpacity(0.92)
                                    : (isLight
                                        ? const Color(0xFFE0D0BC)
                                        : Colors.white.withOpacity(0.10)),
                                width: selected ? 1.4 : 1,
                              ),
                            ),
                            child: Text(
                              token.trim(),
                              style: TextStyle(
                                color:
                                    _isLight(store.highlightColor) && selected
                                        ? Colors.black
                                        : (isLight
                                            ? const Color(0xFF1E1B16)
                                            : Colors.white),
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (tokens.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: store.segments.isEmpty
                        ? null
                        : () => store.clearSegments(),
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Clear Highlights'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isLight ? const Color(0xFF6B6256) : Colors.white70,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Secondary Text / Author (optional)',
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF1E1B16)
                  : Colors.white.withOpacity(0.86),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: authorController,
            onChanged: store.setAuthor,
            maxLines: 2,
            style: TextStyle(
              color: isLight ? const Color(0xFF1E1B16) : Colors.white,
              height: 1.3,
            ),
            decoration: _decoration('Add supporting text or author...'),
          ),
        ],
      ),
    );
  }

  List<String> _quoteTokens(String value) {
    if (value.trim().isEmpty) return [];
    return RegExp(r'\S+\s*')
        .allMatches(value)
        .map((match) => match.group(0) ?? '')
        .where((token) => token.trim().isNotEmpty)
        .toList();
  }

  bool _isWordHighlighted(QuoteCreatorStore store, int index) {
    if (store.segments.isEmpty) return false;
    if (index < 0 || index >= store.segments.length) return false;
    return store.segments[index].isHighlight;
  }

  void _toggleHighlight(QuoteCreatorStore store, int index) {
    final tokens = _quoteTokens(store.quote);
    if (tokens.isEmpty || index >= tokens.length) return;

    if (store.segments.length != tokens.length) {
      store.applySegmentsFromText(store.quote);
    }

    store.toggleSegmentHighlight(index);
  }

  bool _isLight(Color color) {
    return color.computeLuminance() > 0.5;
  }
}

class _QuickInsertCard extends StatelessWidget {
  final bool isLight;
  final String incomingSourceLabel;

  const _QuickInsertCard({
    required this.isLight,
    required this.incomingSourceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_InsertItem>[
      if (incomingSourceLabel.trim().isNotEmpty)
        _InsertItem(
          label: incomingSourceLabel,
          icon: Icons.link_rounded,
          message: 'This quote was opened from a connected tool.',
        ),
      const _InsertItem(
        label: 'From Bible',
        icon: Icons.menu_book_rounded,
        message: 'Use Bible verse actions to send a verse here directly.',
      ),
      const _InsertItem(
        label: 'From Notes',
        icon: Icons.sticky_note_2_rounded,
        message: 'Use Note Editor → Make Quote to send note text here.',
      ),
      const _InsertItem(
        label: 'SOD Quote',
        icon: Icons.format_quote_outlined,
        message: 'SOD quote cards can send content here directly.',
      ),
      const _InsertItem(
        label: 'Articles',
        icon: Icons.article_rounded,
        message: 'Article Reader Tools can now send content here directly.',
      ),
      const _InsertItem(
        label: 'Daily Scripture',
        icon: Icons.auto_stories_rounded,
        message: 'Home Daily Scripture can open here with backend design.',
      ),
      const _InsertItem(
        label: 'Daily Quote',
        icon: Icons.format_quote_rounded,
        message: 'Home Daily Quote can open here with backend design.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0A1027),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connected Inputs',
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF1E1B16)
                  : Colors.white.withOpacity(0.88),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _InsertActionChip(
                  label: item.label,
                  icon: item.icon,
                  isLight: isLight,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(item.message)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InsertItem {
  final String label;
  final IconData icon;
  final String message;

  const _InsertItem({
    required this.label,
    required this.icon,
    required this.message,
  });
}

class _InsertActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLight;
  final VoidCallback onTap;

  const _InsertActionChip({
    required this.label,
    required this.icon,
    required this.isLight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(
        icon,
        size: 18,
        color: isLight ? const Color(0xFF1E1B16) : Colors.white,
      ),
      backgroundColor:
          isLight ? const Color(0xFFF2E8D8) : const Color(0xFF151C3A),
      side: BorderSide(
        color:
            isLight ? const Color(0xFFE0D0BC) : Colors.white.withOpacity(0.10),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      label: Text(
        label,
        style: TextStyle(
          color: isLight ? const Color(0xFF1E1B16) : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ControlsCard extends StatelessWidget {
  final TabController controller;
  final QuoteCreatorStore store;
  final VoidCallback onPickImage;
  final bool isPickingImage;
  final bool isLight;

  const _ControlsCard({
    required this.controller,
    required this.store,
    required this.onPickImage,
    required this.isPickingImage,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0A1027),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isLight
              ? const Color(0xFFE6D8C3)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          TabBar(
            controller: controller,
            isScrollable: true,
            labelColor: isLight ? const Color(0xFF1E1B16) : Colors.white,
            unselectedLabelColor: isLight
                ? const Color(0xFF6B6256)
                : Colors.white.withOpacity(0.58),
            indicatorColor: const Color(0xFFFF2C96),
            dividerColor: isLight
                ? const Color(0xFFE6D8C3)
                : Colors.white.withOpacity(0.06),
            tabs: const [
              Tab(text: 'Templates'),
              Tab(text: 'Text'),
              Tab(text: 'Colors'),
              Tab(text: 'Background'),
              Tab(text: 'Branding'),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: controller,
              children: [
                _TemplatesTab(store: store, isLight: isLight),
                _TextTab(store: store, isLight: isLight),
                _ColorsTab(store: store, isLight: isLight),
                _BackgroundTab(
                  store: store,
                  onPickImage: onPickImage,
                  isPickingImage: isPickingImage,
                  isLight: isLight,
                ),
                _BrandingTab(store: store, isLight: isLight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatesTab extends StatelessWidget {
  final QuoteCreatorStore store;
  final bool isLight;

  const _TemplatesTab({
    required this.store,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final templates = const [
      'Faith',
      'Wisdom',
      'Prayer',
      'Motivation',
      'Scripture',
      'Bold Pink',
      'Clean White',
      'Royal Blue',
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _TabSectionTitle(text: 'Templates', isLight: isLight),
        const SizedBox(height: 8),
        Text(
          'Start with a preset, then adjust colors, background, and text.',
          style: TextStyle(
            color: isLight
                ? const Color(0xFF6B6256)
                : Colors.white.withOpacity(0.60),
            fontSize: 11.8,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: templates.map((label) {
            return _TemplateChip(
              label: label,
              isLight: isLight,
              onTap: () => store.applyTemplate(label),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TextTab extends StatelessWidget {
  final QuoteCreatorStore store;
  final bool isLight;

  const _TextTab({
    required this.store,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _TabSectionTitle(text: 'Fonts', isLight: isLight),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: store.fontOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final font = store.fontOptions[index];
              final selected = store.fontFamily == font;
              return _SelectableChip(
                label: font,
                selected: selected,
                isLight: isLight,
                onTap: () => store.setFontFamily(font),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        _TabSectionTitle(text: 'Main Quote Font Size', isLight: isLight),
        Slider(
          value: store.fontSize.clamp(16.0, 56.0),
          min: 16,
          max: 56,
          divisions: 40,
          label: store.fontSize.clamp(16.0, 56.0).round().toString(),
          onChanged: store.setFontSize,
        ),
        const SizedBox(height: 10),
        _TabSectionTitle(
          text: 'Secondary Text / Author Size',
          isLight: isLight,
        ),
        Slider(
          value: store.authorFontSize.clamp(8.0, 32.0),
          min: 8,
          max: 32,
          divisions: 24,
          label: store.authorFontSize.clamp(8.0, 32.0).toStringAsFixed(1),
          onChanged: store.setAuthorFontSize,
        ),
        const SizedBox(height: 10),
        _TabSectionTitle(text: 'Highlighted Text Size', isLight: isLight),
        Slider(
          value: store.highlightFontScale.clamp(0.8, 1.8),
          min: 0.8,
          max: 1.8,
          divisions: 20,
          label:
              '${store.highlightFontScale.clamp(0.8, 1.8).toStringAsFixed(2)}x',
          onChanged: store.setHighlightFontScale,
        ),
        const SizedBox(height: 10),
        _TabSectionTitle(text: 'Text Scale', isLight: isLight),
        Slider(
          value: store.textScale.clamp(0.6, 2.4),
          min: 0.6,
          max: 2.4,
          divisions: 18,
          label: store.textScale.clamp(0.6, 2.4).toStringAsFixed(1),
          onChanged: store.setTextScale,
        ),
        const SizedBox(height: 10),
        _TabSectionTitle(text: 'Alignment & Position', isLight: isLight),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _IconChoiceButton(
              icon: Icons.format_align_left_rounded,
              selected: store.alignment == TextAlign.left,
              isLight: isLight,
              onTap: () => store.setAlignment(TextAlign.left),
            ),
            _IconChoiceButton(
              icon: Icons.format_align_center_rounded,
              selected: store.alignment == TextAlign.center,
              isLight: isLight,
              onTap: () => store.setAlignment(TextAlign.center),
            ),
            _IconChoiceButton(
              icon: Icons.format_align_right_rounded,
              selected: store.alignment == TextAlign.right,
              isLight: isLight,
              onTap: () => store.setAlignment(TextAlign.right),
            ),
            OutlinedButton.icon(
              onPressed: store.resetTextPosition,
              icon: const Icon(Icons.center_focus_strong_rounded, size: 18),
              label: const Text('Reset Position'),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isLight ? const Color(0xFF1E1B16) : Colors.white,
                side: BorderSide(
                  color: isLight
                      ? const Color(0xFFE0D0BC)
                      : Colors.white.withOpacity(0.20),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorsTab extends StatelessWidget {
  final QuoteCreatorStore store;
  final bool isLight;

  const _ColorsTab({
    required this.store,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _TabSectionTitle(text: 'Quote Text Color', isLight: isLight),
        const SizedBox(height: 10),
        _ColorScroller(
          colors: store.textColorOptions,
          selected: store.textColor,
          onTap: store.setTextColor,
        ),
        const SizedBox(height: 18),
        _TabSectionTitle(text: 'Highlight Text Color', isLight: isLight),
        const SizedBox(height: 10),
        _ColorScroller(
          colors: store.textColorOptions,
          selected: store.highlightColor,
          onTap: store.setHighlightColor,
        ),
        const SizedBox(height: 18),
        _TabSectionTitle(
          text: 'Secondary Text / Author Color',
          isLight: isLight,
        ),
        const SizedBox(height: 10),
        _ColorScroller(
          colors: store.textColorOptions,
          selected: store.authorColor,
          onTap: store.setAuthorColor,
        ),
      ],
    );
  }
}

class _ColorScroller extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onTap;

  const _ColorScroller({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final color = colors[index];
          return _ColorDot(
            color: color,
            selected: selected.value == color.value,
            onTap: () => onTap(color),
          );
        },
      ),
    );
  }
}

class _BackgroundTab extends StatelessWidget {
  final QuoteCreatorStore store;
  final VoidCallback onPickImage;
  final bool isPickingImage;
  final bool isLight;

  const _BackgroundTab({
    required this.store,
    required this.onPickImage,
    required this.isPickingImage,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _TabSectionTitle(text: 'Solid Background Colors', isLight: isLight),
        const SizedBox(height: 10),
        _ColorScroller(
          colors: store.backgroundColorOptions,
          selected: store.backgroundColor,
          onTap: store.setBackgroundColor,
        ),
        const SizedBox(height: 18),
        _TabSectionTitle(text: 'Gradient Backgrounds', isLight: isLight),
        const SizedBox(height: 10),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: store.gradientOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final gradient = store.gradientOptions[index];
              final selected =
                  _gradientEquals(store.backgroundGradient, gradient);

              return GestureDetector(
                onTap: () => store.setBackgroundGradient(gradient),
                child: Container(
                  width: 92,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF2C96)
                          : (isLight
                              ? const Color(0xFFE0D0BC)
                              : Colors.white.withOpacity(0.14)),
                      width: selected ? 2.4 : 1.0,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF2C96).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: selected
                      ? const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        _TabSectionTitle(text: 'Overlay Strength', isLight: isLight),
        Slider(
          value: store.overlayStrength.clamp(0.0, 0.85),
          min: 0,
          max: 0.85,
          divisions: 17,
          label: '${(store.overlayStrength.clamp(0.0, 0.85) * 100).round()}%',
          onChanged: store.setOverlayStrength,
        ),
        Text(
          'Use 0% for clean plain backgrounds. Increase for images when text needs contrast.',
          style: TextStyle(
            color: isLight
                ? const Color(0xFF6B6256)
                : Colors.white.withOpacity(0.58),
            fontSize: 11.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        _TabSectionTitle(text: 'Image Backgrounds', isLight: isLight),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: store.bundledBackgrounds.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final asset = store.bundledBackgrounds[index];
              final selected = store.backgroundImage == asset;

              return GestureDetector(
                onTap: () => store.setBackgroundImage(asset),
                child: Container(
                  width: 92,
                  height: 82,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFFF2C96)
                          : (isLight
                              ? const Color(0xFFE0D0BC)
                              : Colors.white.withOpacity(0.10)),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1B1B2A),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isPickingImage ? null : onPickImage,
                icon: isPickingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.photo_library_rounded),
                label: Text(
                  isPickingImage ? 'Opening...' : 'Insert image from device',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isLight ? const Color(0xFF1E1B16) : Colors.white,
                  side: BorderSide(
                    color: isLight
                        ? const Color(0xFFE0D0BC)
                        : Colors.white.withOpacity(0.25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  store.clearBackgroundImage();
                  store.setOverlayStrength(0);
                  store.backgroundGradient = null;
                  store.notifyListeners();
                },
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isLight ? const Color(0xFF6B6256) : Colors.white70,
                  side: BorderSide(
                    color: isLight
                        ? const Color(0xFFE0D0BC)
                        : Colors.white.withOpacity(0.18),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('Clear'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _gradientEquals(LinearGradient? a, LinearGradient b) {
    if (a == null) return false;
    if (a.colors.length != b.colors.length) return false;
    for (var i = 0; i < a.colors.length; i++) {
      if (a.colors[i].value != b.colors[i].value) return false;
    }
    return true;
  }
}

class _BrandingTab extends StatelessWidget {
  final QuoteCreatorStore store;
  final bool isLight;

  const _BrandingTab({
    required this.store,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SwitchListTile(
          value: store.showWatermark,
          onChanged: (_) => store.toggleWatermark(),
          activeColor: const Color(0xFFFF2C96),
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Show Dunamis TV watermark',
            style: TextStyle(
              color: isLight ? const Color(0xFF1E1B16) : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            'The watermark remains optional and the design position stays stable.',
            style: TextStyle(
              color: isLight
                  ? const Color(0xFF6B6256)
                  : Colors.white.withOpacity(0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onLibraryTap;
  final VoidCallback onNextTap;
  final bool isLight;

  const _ActionButtons({
    required this.onLibraryTap,
    required this.onNextTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onLibraryTap,
            icon: const Icon(Icons.collections_bookmark_rounded),
            label: const Text('My Designs'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isLight ? const Color(0xFF1E1B16) : Colors.white,
              side: BorderSide(
                color: isLight
                    ? const Color(0xFFE0D0BC)
                    : Colors.white.withOpacity(0.22),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onNextTap,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2C96),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabSectionTitle extends StatelessWidget {
  final String text;
  final bool isLight;

  const _TabSectionTitle({
    required this.text,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color:
            isLight ? const Color(0xFF1E1B16) : Colors.white.withOpacity(0.84),
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isLight;

  const _TemplateChip({
    required this.label,
    required this.onTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor:
          isLight ? const Color(0xFFF2E8D8) : const Color(0xFF151C3A),
      side: BorderSide(
        color:
            isLight ? const Color(0xFFE0D0BC) : Colors.white.withOpacity(0.10),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      label: Text(
        label,
        style: TextStyle(
          color: isLight ? const Color(0xFF1E1B16) : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isLight;

  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      backgroundColor: selected
          ? const Color(0xFFFF2C96)
          : (isLight ? const Color(0xFFF2E8D8) : const Color(0xFF151C3A)),
      side: BorderSide(
        color: selected
            ? const Color(0xFFFF2C96)
            : (isLight
                ? const Color(0xFFE0D0BC)
                : Colors.white.withOpacity(0.10)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      label: Text(
        label,
        style: TextStyle(
          color: selected
              ? Colors.white
              : (isLight ? const Color(0xFF1E1B16) : Colors.white),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _IconChoiceButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isLight;

  const _IconChoiceButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 52,
        height: 46,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF2C96)
              : (isLight ? const Color(0xFFF2E8D8) : const Color(0xFF151C3A)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF2C96)
                : (isLight
                    ? const Color(0xFFE0D0BC)
                    : Colors.white.withOpacity(0.10)),
          ),
        ),
        child: Icon(
          icon,
          color: selected
              ? Colors.white
              : (isLight ? const Color(0xFF1E1B16) : Colors.white),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final checkColor = _isLight(color) ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.white.withOpacity(0.14),
            width: selected ? 2.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.28),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                size: 18,
                color: checkColor,
              )
            : null,
      ),
    );
  }

  bool _isLight(Color color) {
    return color.computeLuminance() > 0.5;
  }
}
