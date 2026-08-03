import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../../../app_config.dart';
import '../../../features/hub/state/hub_scope.dart';
import '../../../services/auth_action_gate.dart';
import '../../../services/content_engagement_service.dart';
import '../../../services/ads_service.dart';
import '../../../theme/theme_controller.dart';
import '../../article/blocks/article_block_renderer.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleId;
  final Map<String, dynamic>? initialItem;
  final String? sourceHint;

  const ArticleDetailScreen({
    super.key,
    required this.articleId,
    this.initialItem,
    this.sourceHint,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey _commentsSectionKey = GlobalKey();
  final FlutterTts _tts = FlutterTts();

  bool _bootstrapped = false;
  bool _loadingComments = false;
  bool _postingComment = false;
  bool _togglingLike = false;
  bool _loadingArticle = false;
  bool _commentsExpanded = false;

  bool _liked = false;
  int _likesCount = 0;
  int _commentsCount = 0;

  List<Map<String, dynamic>> _comments = const [];

  String _selectedText = '';

  bool _ttsReady = false;
  bool _ttsSpeaking = false;
  bool _ttsPaused = false;
  String _ttsStatus = 'Ready';
  List<String> _ttsQueue = const <String>[];
  int _ttsQueueIndex = 0;
  double _readerFontScale = 1.0;
  double _speechRate = 0.48;
  double _speechPitch = 1.0;

  String? _sourceHint;
  Map<String, dynamic> _item = const {};

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate.clamp(0.25, 0.85));
      await _tts.setPitch(_speechPitch.clamp(0.75, 1.35));
      await _tts.awaitSpeakCompletion(false);

      _tts.setStartHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsReady = true;
          _ttsSpeaking = true;
          _ttsPaused = false;
          _ttsStatus = 'Reading aloud';
        });
      });

      _tts.setCompletionHandler(() {
        if (!mounted) return;
        if (_ttsQueueIndex + 1 < _ttsQueue.length) {
          _ttsQueueIndex += 1;
          _speakNextTtsChunk();
          return;
        }

        setState(() {
          _ttsSpeaking = false;
          _ttsPaused = false;
          _ttsStatus = 'Finished';
          _ttsQueue = const <String>[];
          _ttsQueueIndex = 0;
        });
      });

      _tts.setCancelHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsSpeaking = false;
          _ttsPaused = false;
          _ttsStatus = 'Stopped';
          _ttsQueue = const <String>[];
          _ttsQueueIndex = 0;
        });
      });

      _tts.setPauseHandler(() {
        if (!mounted) return;
        setState(() {
          _ttsSpeaking = false;
          _ttsPaused = true;
          _ttsStatus = 'Paused';
        });
      });

      if (!mounted) return;
      setState(() {
        _ttsReady = true;
        _ttsStatus = 'Ready';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ttsReady = false;
        _ttsStatus = 'Read aloud is not available on this device.';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_bootstrapped) return;
    _bootstrapped = true;

    final extra = GoRouterState.of(context).extra;
    _sourceHint = widget.sourceHint ??
        ((extra is Map) ? (extra['source'] as String?) : null);

    final store = HubScope.maybeOf(context);
    final Map<String, dynamic> hubMap = store?.raw ?? const <String, dynamic>{};
    final inspire = (hubMap['inspire'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    _item = _notificationInitialItem(widget.initialItem) ??
        _findItem(
          inspire,
          widget.articleId,
          _sourceHint,
        ) ??
        <String, dynamic>{
          'id': widget.articleId,
          'title': 'Loading article...',
          'subtitle': 'Opening the selected update.',
          'blocks': const <Map<String, dynamic>>[],
        };

    _syncEngagementStateFromItem(_item);

    _loadFullArticle();
    _loadComments();
  }

  @override
  void dispose() {
    _tts.stop();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadFullArticle() async {
    if (_loadingArticle) return;

    setState(() => _loadingArticle = true);

    try {
      final uri = Uri.parse(AppConfig.contentDetailUrl(widget.articleId));

      final res = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-APP-TOKEN': AppConfig.appToken,
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        return;
      }

      final decoded = jsonDecode(res.body);

      Map<String, dynamic>? incoming;
      if (decoded is Map<String, dynamic>) {
        incoming = decoded;
      } else if (decoded is Map) {
        incoming = decoded.cast<String, dynamic>();
      }

      if (incoming == null) return;

      final normalized = _normalizeContentDetailResponse(incoming);

      if (!mounted) return;
      setState(() {
        _item = {
          ..._item,
          ...normalized,
        };
        _syncEngagementStateFromItem(_item);
      });
    } catch (_) {
      // keep fallback snapshot if detail load fails
    } finally {
      if (mounted) {
        setState(() => _loadingArticle = false);
      }
    }
  }

  Map<String, dynamic> _normalizeContentDetailResponse(
    Map<String, dynamic> payload,
  ) {
    final data = <String, dynamic>{};

    if (payload['item'] is Map) {
      data.addAll((payload['item'] as Map).cast<String, dynamic>());
    } else if (payload['data'] is Map) {
      data.addAll((payload['data'] as Map).cast<String, dynamic>());
    } else {
      data.addAll(payload);
    }

    if (payload['likes_count'] != null && data['likes_count'] == null) {
      data['likes_count'] = payload['likes_count'];
    }

    if (payload['comments_count'] != null && data['comments_count'] == null) {
      data['comments_count'] = payload['comments_count'];
    }

    if (payload['liked'] != null && data['liked'] == null) {
      data['liked'] = payload['liked'];
    }

    if (payload['liked_by_me'] != null && data['liked_by_me'] == null) {
      data['liked_by_me'] = payload['liked_by_me'];
    }

    final nestedPayload = data['payload'];
    if (nestedPayload is Map) {
      final nested = nestedPayload.cast<String, dynamic>();

      if (data['blocks'] == null && nested['blocks'] != null) {
        data['blocks'] = nested['blocks'];
      }

      if (data['blocks_json'] == null && nested['blocks_json'] != null) {
        data['blocks_json'] = nested['blocks_json'];
      }

      if (data['body_html'] == null && nested['body_html'] != null) {
        data['body_html'] = nested['body_html'];
      }

      if (data['body'] == null && nested['body'] != null) {
        data['body'] = nested['body'];
      }

      if (data['content'] == null && nested['content'] != null) {
        data['content'] = nested['content'];
      }

      if (data['text'] == null && nested['text'] != null) {
        data['text'] = nested['text'];
      }

      if (data['bucket'] == null && nested['bucket'] != null) {
        data['bucket'] = nested['bucket'];
      }

      if (data['content_type'] == null && nested['content_type'] != null) {
        data['content_type'] = nested['content_type'];
      }

      if (data['published_at'] == null && nested['published_at'] != null) {
        data['published_at'] = nested['published_at'];
      }

      if (data['author_name'] == null && nested['author_name'] != null) {
        data['author_name'] = nested['author_name'];
      }
    }

    return data;
  }

  Map<String, dynamic>? _notificationInitialItem(Map<String, dynamic>? item) {
    if (item == null || item.isEmpty) return null;

    final data = item['data'];
    final map =
        data is Map ? data.cast<String, dynamic>() : <String, dynamic>{};
    final title = _firstNonEmpty([
      item['title'],
      map['title'],
      'Loading article...',
    ]);
    final body = _firstNonEmpty([
      item['body'],
      item['message'],
      map['body'],
      map['message'],
    ]);
    final imageUrl = _firstNonEmpty([
      item['image_url'],
      item['image'],
      map['image_url'],
      map['image'],
      map['cover_image_url'],
    ]);
    final bucket = _firstNonEmpty([
      map['notification_kind'],
      map['bucket'],
      map['content_type'],
      'article',
    ]);

    return <String, dynamic>{
      'id': widget.articleId,
      'title': title,
      'subtitle': body,
      'body': body,
      'bucket': bucket == 'article' ? 'articles' : bucket,
      'content_type': bucket == 'article' ? 'articles' : bucket,
      'image_url': imageUrl,
      'cover_image_url': imageUrl,
      'thumbnail_url': imageUrl,
      'featured_image': imageUrl,
      'payload': {
        'bucket': bucket == 'article' ? 'articles' : bucket,
        'content_type': bucket == 'article' ? 'articles' : bucket,
        'body': body,
        'image_url': imageUrl,
        'cover_image_url': imageUrl,
      },
      'blocks': const <Map<String, dynamic>>[],
    };
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  void _syncEngagementStateFromItem(Map<String, dynamic> item) {
    _liked = _boolValue(item, ['liked_by_me', 'liked']) ?? false;
    _likesCount = _intValue(item, ['likes_count', 'likesCount']) ?? 0;
    _commentsCount = _intValue(item, ['comments_count', 'commentsCount']) ?? 0;

    final payload = item['payload'];
    if (payload is Map) {
      final engagement = payload['engagement'];
      if (engagement is Map) {
        final casted = engagement.cast<String, dynamic>();
        _liked = _boolValue(casted, ['liked_by_me', 'liked']) ?? _liked;
        _likesCount =
            _intValue(casted, ['likes_count', 'likesCount']) ?? _likesCount;
        _commentsCount =
            _intValue(casted, ['comments_count', 'commentsCount']) ??
                _commentsCount;
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);

    try {
      final res = await ContentEngagementService.instance
          .fetchComments(widget.articleId);

      final rawItems = res['items'];
      final items = rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList(growable: false)
          : <Map<String, dynamic>>[];

      setState(() {
        _comments = items;
        _commentsCount = _intFromDynamic(res['comments_count']) ?? items.length;
        if (items.isNotEmpty) {
          _commentsExpanded = true;
        }
      });
    } catch (_) {
      // silent
    } finally {
      if (mounted) {
        setState(() => _loadingComments = false);
      }
    }
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty || _postingComment) return;

    setState(() => _postingComment = true);

    try {
      final res = await ContentEngagementService.instance.postComment(
        widget.articleId,
        body,
      );

      final item = res['item'];
      final commentsCount = _intFromDynamic(res['comments_count']);

      if (item is Map) {
        setState(() {
          _comments = [
            item.cast<String, dynamic>(),
            ..._comments,
          ];
          _commentsCount = commentsCount ?? _comments.length;
          _commentController.clear();
          _commentsExpanded = true;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added.')),
      );
    } on EngagementAuthRequiredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to comment.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _postingComment = false);
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    try {
      await ContentEngagementService.instance.deleteComment(
        widget.articleId,
        commentId,
      );

      setState(() {
        _comments = _comments
            .where((e) => _intFromDynamic(e['id']) != commentId)
            .toList(growable: false);
        _commentsCount = _comments.length;
        if (_comments.isEmpty) {
          _commentsExpanded = false;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted.')),
      );
    } on EngagementAuthRequiredException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _toggleLike() async {
    if (_togglingLike) return;

    final nextLike = !_liked;

    setState(() => _togglingLike = true);

    try {
      final res = await ContentEngagementService.instance.setLike(
        widget.articleId,
        like: nextLike,
      );

      setState(() {
        _liked = res['liked'] == true;
        _likesCount = _intFromDynamic(res['likes_count']) ?? _likesCount;
      });
    } on EngagementAuthRequiredException {
      if (!mounted) return;
      final allowed = await AuthActionGate.requireAuthentication(
        context,
        action: AuthRequiredAction.like,
      );
      if (allowed && mounted) {
        await _toggleLike();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Like update failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _togglingLike = false);
      }
    }
  }

  void _scrollToComments() {
    if (!_commentsExpanded) {
      setState(() => _commentsExpanded = true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _commentsSectionKey.currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.08,
      );
    });
  }

  String _articlePlainText({
    required String title,
    required String? subtitle,
    required List<Map<String, dynamic>> blocks,
  }) {
    final buffer = StringBuffer();

    void addLine(String value) {
      final clean = value.trim();
      if (clean.isEmpty) return;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(clean);
    }

    addLine(title);
    if ((subtitle ?? '').trim().isNotEmpty) {
      addLine(subtitle!.trim());
    }

    final flattenedBlocks = _flattenBlocksText(blocks);
    if (flattenedBlocks.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(flattenedBlocks.trim());
    } else {
      final fallback = _stringValue(_item, ['body', 'content', 'text']) ??
          _stringValueFromPayload(_item, ['body', 'content', 'text']) ??
          '';
      if (fallback.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(fallback.trim());
      } else {
        final html = (_item['body_html'] ?? '').toString().trim();
        final payloadHtml =
            (_asMap(_item['payload'])?['body_html'] ?? '').toString().trim();
        final stripped = _stripHtml(html.isNotEmpty ? html : payloadHtml);
        if (stripped.trim().isNotEmpty) {
          if (buffer.isNotEmpty) buffer.writeln();
          buffer.write(stripped.trim());
        }
      }
    }

    return buffer.toString().trim();
  }

  String _quotePrefillFromArticle({
    required String title,
    required String? subtitle,
    required List<Map<String, dynamic>> blocks,
  }) {
    final blockText = _flattenBlocksText(blocks).trim();
    if (blockText.isNotEmpty) {
      final firstParagraph =
          blockText.split(RegExp(r'\n{2,}')).map((e) => e.trim()).firstWhere(
                (e) => e.isNotEmpty,
                orElse: () => '',
              );
      if (firstParagraph.isNotEmpty) {
        return firstParagraph.length > 320
            ? '${firstParagraph.substring(0, 320).trim()}...'
            : firstParagraph;
      }
    }

    final subtitleValue = (subtitle ?? '').trim();
    if (subtitleValue.isNotEmpty) {
      return subtitleValue;
    }

    return title.trim();
  }

  Future<void> _speakArticleText(String text) async {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return;

    if (!_ttsReady) {
      await _initTts();
      if (!_ttsReady) return;
    }

    try {
      await _tts.stop();
      await _tts.setSpeechRate(_speechRate.clamp(0.25, 0.85));
      await _tts.setPitch(_speechPitch.clamp(0.75, 1.35));

      _ttsQueue = _splitTtsText(clean);
      _ttsQueueIndex = 0;

      if (_ttsQueue.isEmpty) return;
      await _speakNextTtsChunk();
    } catch (_) {
      if (!mounted) return;
      setState(() => _ttsStatus = 'Read aloud failed on this device.');
    }
  }

  Future<void> _speakNextTtsChunk() async {
    if (!_ttsReady || _ttsQueue.isEmpty) return;

    final chunk = _ttsQueue[_ttsQueueIndex].trim();
    if (chunk.isEmpty) return;

    await _tts.speak(chunk);
    if (!mounted) return;
    setState(() {
      _ttsSpeaking = true;
      _ttsPaused = false;
      _ttsStatus = _ttsQueue.length > 1
          ? 'Reading aloud ${_ttsQueueIndex + 1}/${_ttsQueue.length}'
          : 'Reading aloud';
    });
  }

  List<String> _splitTtsText(String text) {
    const maxChunk = 3200;
    final clean = text.trim();
    if (clean.length <= maxChunk) return <String>[clean];

    final chunks = <String>[];
    var remaining = clean;

    while (remaining.length > maxChunk) {
      var cut = remaining.lastIndexOf(RegExp(r'[.!?]\s'), maxChunk);
      if (cut < 900) {
        cut = remaining.lastIndexOf(' ', maxChunk);
      }
      if (cut < 900) cut = maxChunk;

      chunks.add(remaining.substring(0, cut).trim());
      remaining = remaining.substring(cut).trim();
    }

    if (remaining.isNotEmpty) chunks.add(remaining);
    return chunks.where((chunk) => chunk.trim().isNotEmpty).toList();
  }

  Future<void> _pauseReadAloud() async {
    if (!_ttsReady) return;
    try {
      await _tts.pause();
      if (!mounted) return;
      setState(() {
        _ttsSpeaking = false;
        _ttsPaused = true;
        _ttsStatus = 'Paused';
      });
    } catch (_) {
      await _stopReadAloud();
    }
  }

  Future<void> _stopReadAloud() async {
    if (!_ttsReady) return;
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _ttsSpeaking = false;
      _ttsPaused = false;
      _ttsStatus = 'Stopped';
      _ttsQueue = const <String>[];
      _ttsQueueIndex = 0;
    });
  }

  void _setReaderFontScale(double value) {
    setState(() {
      _readerFontScale = value.clamp(0.82, 1.42);
    });
  }

  Future<void> _setSpeechRate(double value) async {
    final next = value.clamp(0.25, 0.85);
    setState(() => _speechRate = next);
    if (_ttsReady) await _tts.setSpeechRate(next);
  }

  Future<void> _setSpeechPitch(double value) async {
    final next = value.clamp(0.75, 1.35);
    setState(() => _speechPitch = next);
    if (_ttsReady) await _tts.setPitch(next);
  }

  Future<void> _showReaderSettingsSheet({
    required _ArticleDetailColors colors,
    required String articleText,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void updateFontScale(double value) {
              _setReaderFontScale(value);
              setSheetState(() {});
            }

            Future<void> updateSpeechRate(double value) async {
              await _setSpeechRate(value);
              setSheetState(() {});
            }

            Future<void> updateSpeechPitch(double value) async {
              await _setSpeechPitch(value);
              setSheetState(() {});
            }

            Future<void> readText() async {
              await _speakArticleText(articleText);
              setSheetState(() {});
            }

            Future<void> pauseText() async {
              await _pauseReadAloud();
              setSheetState(() {});
            }

            Future<void> stopText() async {
              await _stopReadAloud();
              setSheetState(() {});
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: 12 + MediaQuery.of(sheetContext).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: colors.scaffold,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: Border.all(color: colors.panelBorder),
                    boxShadow: colors.panelShadow,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.panelSubtitle.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ReaderSettingsCard(
                          colors: colors,
                          fontScale: _readerFontScale,
                          speechRate: _speechRate,
                          speechPitch: _speechPitch,
                          ttsReady: _ttsReady,
                          ttsStatus: _ttsStatus,
                          isSpeaking: _ttsSpeaking,
                          isPaused: _ttsPaused,
                          onFontScaleChanged: updateFontScale,
                          onSpeechRateChanged: updateSpeechRate,
                          onSpeechPitchChanged: updateSpeechPitch,
                          onReadTap: readText,
                          onPauseTap: pauseText,
                          onStopTap: stopText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _copyArticleText(String text) async {
    if (text.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article text copied')),
    );
  }

  void _openInQuoteCreator({
    required String quoteText,
    required String author,
    required String sourceId,
    required String sourceType,
    String? reference,
  }) {
    if (quoteText.trim().isEmpty) return;

    context.push(
      '/tools/quote',
      extra: {
        'designData': {
          'quote': quoteText.trim(),
          'author': author.trim().isEmpty ? 'Dunamis TV' : author.trim(),
          'reference': (reference ?? '').trim(),
          'source_type': sourceType,
          'source_id': sourceId,
        },
      },
    );
  }

  void _openInNotes({
    required String title,
    required String text,
    required String sourceId,
    required String sourceType,
  }) {
    if (text.trim().isEmpty && title.trim().isEmpty) return;

    context.push(
      '/tools/notes/editor',
      extra: {
        'title': title.trim(),
        'prefill': text.trim(),
        'sourceType': sourceType,
        'sourceId': sourceId,
      },
    );
  }

  void _openInBible(String reference) {
    final clean = reference.trim();
    if (clean.isEmpty) return;

    context.push(
      '/tools/bible/reader',
      extra: {
        'ref': clean,
      },
    );
  }

  String _selectedOrArticleText(String fallbackText) {
    final selected = _selectedText.trim();
    if (selected.isNotEmpty) return selected;
    return fallbackText.trim();
  }

  Widget _buildSelectionWrappedContent({
    required List<Widget> children,
  }) {
    return SelectionArea(
      onSelectionChanged: (selectedContent) {
        final next = (selectedContent?.plainText ?? '').trim();
        if (next == _selectedText) return;

        setState(() {
          _selectedText = next;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);

    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;
        final colors = _ArticleDetailColors.fromBrightness(isLight);

        final title =
            _stringValue(_item, ['title', 'name', 'headline']) ?? 'Reading';

        final subtitle = _stringValue(_item, [
          'subtitle',
          'excerpt',
          'summary',
          'description',
        ]);

        final author = _stringValue(_item, [
              'author_name',
              'author',
              'publisher_name',
            ]) ??
            _stringValueFromPayload(_item, [
              'author_name',
              'author',
              'publisher_name',
            ]) ??
            'Dunamis';

        final publishedAtRaw = _stringValue(_item, [
              'published_at',
              'date',
              'publish_at',
              'created_at',
            ]) ??
            _stringValueFromPayload(_item, [
              'published_at',
              'date',
              'publish_at',
              'created_at',
            ]);

        final publishedAt = _formatPublishedDate(publishedAtRaw);

        final bucket = _stringValue(_item, [
              'bucket',
              'content_type',
            ]) ??
            _stringValueFromPayload(_item, [
              'bucket',
              'content_type',
            ]) ??
            _sourceHint ??
            'article';

        final imageUrl = _pickImage(_item);
        final blocks = _extractBlocks(_item);
        final bannerTabKey = _bannerTabKey(bucket);

        AdsService.instance.preloadInterstitial(tabKey: bannerTabKey);

        final articleText = _articlePlainText(
          title: title,
          subtitle: subtitle,
          blocks: blocks,
        );

        final quotePrefill = _quotePrefillFromArticle(
          title: title,
          subtitle: subtitle,
          blocks: blocks,
        );

        final detectedReference = _detectBibleReference(articleText);
        final canOpenBible = detectedReference.trim().isNotEmpty;
        final canUseTools =
            articleText.trim().isNotEmpty || title.trim().isNotEmpty;

        final contentWidgets = <Widget>[
          if (blocks.isEmpty) ..._renderLegacyBody(_item, colors),
          if (blocks.isNotEmpty)
            ...blocks.map(
              (block) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: ArticleBlockRenderer(
                  block: block,
                  fallbackAsset: _fallbackAssetForSource(_sourceHint),
                  onMakeQuote: (text) => _openInQuoteCreator(
                    quoteText: text,
                    author: author,
                    sourceId: widget.articleId,
                    sourceType: 'article.selection',
                    reference: _detectBibleReference(text),
                  ),
                  onAddToNotes: (text) => _openInNotes(
                    title: title,
                    text: text,
                    sourceId: widget.articleId,
                    sourceType: 'article.selection',
                  ),
                  onOpenInBible: _openInBible,
                ),
              ),
            ),
        ];

        return Scaffold(
          backgroundColor: colors.scaffold,
          bottomNavigationBar: SafeArea(
            top: false,
            child: BannerAdWidget(
              tabKey: bannerTabKey,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            ),
          ),
          body: Column(
            children: [
              DxmTopBar(
                title: title,
                showBack: true,
                showMenu: true,
                onRefresh: () => store?.refresh(),
                extraMenuItems: [
                  DxmTopBarMenuEntry(
                    icon: Icons.chrome_reader_mode_rounded,
                    title: 'Reader Mode',
                    subtitle: 'Text size, read aloud, speed and voice',
                    onTap: () => _showReaderSettingsSheet(
                      colors: colors,
                      articleText: articleText,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: GradientPageBackground(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await store?.refresh();
                      await _loadFullArticle();
                      await _loadComments();
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
                      children: [
                        if (_loadingArticle)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child:
                                  const LinearProgressIndicator(minHeight: 4),
                            ),
                          ),
                        _ArticleHeroCard(
                          imageUrl: imageUrl,
                          fallbackAsset: _fallbackAssetForSource(_sourceHint),
                          bucketLabel: _bucketLabel(bucket),
                          colors: colors,
                        ),
                        const SizedBox(height: 14),
                        _ArticleTitlePanel(
                          title: title,
                          subtitle: subtitle,
                          colors: colors,
                        ),
                        const SizedBox(height: 18),
                        MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(_readerFontScale),
                          ),
                          child: _buildSelectionWrappedContent(
                            children: contentWidgets,
                          ),
                        ),
                        if (_selectedText.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _SelectedTextToolsCard(
                            selectedText: _selectedText,
                            detectedReference:
                                _detectBibleReference(_selectedText),
                            colors: colors,
                            onCopyTap: () => _copyArticleText(_selectedText),
                            onNotesTap: () => _openInNotes(
                              title: title,
                              text: _selectedText,
                              sourceId: widget.articleId,
                              sourceType: 'article.selection',
                            ),
                            onQuoteTap: () => _openInQuoteCreator(
                              quoteText: _selectedText,
                              author: author,
                              sourceId: widget.articleId,
                              sourceType: 'article.selection',
                              reference: _detectBibleReference(_selectedText),
                            ),
                            onBibleTap: () => _openInBible(
                              _detectBibleReference(_selectedText),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _ArticleMetaCard(
                          author: author,
                          publishedAt: publishedAt,
                          bucketLabel: _bucketLabel(bucket),
                          colors: colors,
                        ),
                        const SizedBox(height: 16),
                        _ActionRow(
                          title: title,
                          shareText: _buildShareText(
                            title: title,
                            subtitle: subtitle,
                            author: author,
                            articleId: widget.articleId,
                          ),
                          liked: _liked,
                          likesCount: _likesCount,
                          commentsCount: _commentsCount,
                          onLikeTap: _toggleLike,
                          onCommentsTap: _scrollToComments,
                          onQuoteTap: null,
                          likeBusy: _togglingLike,
                          colors: colors,
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        _ReaderToolsCard(
                          canOpenBible: canOpenBible,
                          colors: colors,
                          detectedReference: detectedReference,
                          onCopyTap: canUseTools
                              ? () => _copyArticleText(articleText)
                              : null,
                          onBibleTap: canOpenBible
                              ? () => _openInBible(detectedReference)
                              : null,
                          onNotesTap: canUseTools
                              ? () => _openInNotes(
                                    title: title,
                                    text: _selectedOrArticleText(articleText),
                                    sourceId: widget.articleId,
                                    sourceType: 'article',
                                  )
                              : null,
                          onQuoteTap: canUseTools
                              ? () {
                                  final selected = _selectedText.trim();
                                  _openInQuoteCreator(
                                    quoteText: selected.isNotEmpty
                                        ? selected
                                        : quotePrefill,
                                    author: author,
                                    sourceId: widget.articleId,
                                    sourceType: selected.isNotEmpty
                                        ? 'article.selection'
                                        : 'article',
                                    reference: selected.isNotEmpty
                                        ? _detectBibleReference(selected)
                                        : detectedReference,
                                  );
                                }
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _SelectionHintCard(
                          colors: colors,
                          onCopyTap: canUseTools
                              ? () => _copyArticleText(articleText)
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _CommentsSectionHeader(
                          commentsCount: _commentsCount,
                          expanded: _commentsExpanded,
                          onToggle: () {
                            setState(
                                () => _commentsExpanded = !_commentsExpanded);
                          },
                          colors: colors,
                        ),
                        const SizedBox(height: 12),
                        if (_commentsExpanded)
                          KeyedSubtree(
                            key: _commentsSectionKey,
                            child: _CommentsCard(
                              loading: _loadingComments,
                              posting: _postingComment,
                              comments: _comments,
                              commentsCount: _commentsCount,
                              controller: _commentController,
                              onSubmit: _submitComment,
                              onDelete: _deleteComment,
                              colors: colors,
                            ),
                          )
                        else
                          KeyedSubtree(
                            key: _commentsSectionKey,
                            child: _CollapsedCommentsCard(
                              commentsCount: _commentsCount,
                              onOpen: () {
                                setState(() => _commentsExpanded = true);
                              },
                              colors: colors,
                            ),
                          ),
                        const SizedBox(height: 26),
                        _ArticleFooterCard(colors: colors),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Map<String, dynamic>? _findItem(
    Map<String, dynamic> inspire,
    String id,
    String? sourceHint,
  ) {
    final order = <String>[
      if (sourceHint != null) sourceHint,
      'articles',
      'inside_dunamis',
      'highlights',
      'wordification',
      'motivation',
      'sod',
      'sod_quotes',
    ].toSet().toList();

    for (final key in order) {
      final raw = inspire[key];
      if (raw is! List) continue;

      for (final it in raw) {
        if (it is! Map) continue;
        final m = it.cast<String, dynamic>();
        final itemId = (m['id'] ?? m['slug'] ?? '').toString();
        if (itemId == id) return m;
      }
    }

    return null;
  }

  static List<Map<String, dynamic>> _extractBlocks(Map<String, dynamic> item) {
    final rawBlocks = item['blocks_json'] ?? item['blocks'];

    if (rawBlocks is String && rawBlocks.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBlocks);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
        }
      } catch (_) {}
    }

    if (rawBlocks is List) {
      return rawBlocks
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }

    final payload = item['payload'];
    if (payload is Map) {
      final payloadMap = payload.cast<String, dynamic>();

      final payloadBlocks = payloadMap['blocks_json'] ?? payloadMap['blocks'];

      if (payloadBlocks is String && payloadBlocks.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(payloadBlocks);
          if (decoded is List) {
            return decoded
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList();
          }
        } catch (_) {}
      }

      if (payloadBlocks is List) {
        return payloadBlocks
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }

      final payloadBodyHtml = payloadMap['body_html'];
      if (payloadBodyHtml != null &&
          payloadBodyHtml.toString().trim().isNotEmpty) {
        return [
          {
            'type': 'html',
            'html': payloadBodyHtml.toString(),
          }
        ];
      }

      final payloadBody = _stringValue(payloadMap, ['body', 'content', 'text']);
      if ((payloadBody ?? '').trim().isNotEmpty) {
        return [
          {
            'type': 'paragraph',
            'text': payloadBody!,
          }
        ];
      }
    }

    final bodyHtml = item['body_html'];
    if (bodyHtml != null && bodyHtml.toString().trim().isNotEmpty) {
      return [
        {
          'type': 'html',
          'html': bodyHtml.toString(),
        }
      ];
    }

    final body = _stringValue(item, ['body', 'content', 'text']);
    if ((body ?? '').trim().isNotEmpty) {
      return [
        {
          'type': 'paragraph',
          'text': body!,
        }
      ];
    }

    return const [];
  }

  static List<Widget> _renderLegacyBody(
    Map<String, dynamic> item,
    _ArticleDetailColors colors,
  ) {
    String body = _stringValue(item, ['body', 'content', 'text']) ?? '';

    if (body.trim().isEmpty) {
      final payload = item['payload'];
      if (payload is Map) {
        final payloadMap = payload.cast<String, dynamic>();
        body = _stringValue(payloadMap, ['body', 'content', 'text']) ?? '';

        if (body.trim().isEmpty) {
          final payloadHtml = payloadMap['body_html'];
          if (payloadHtml != null && payloadHtml.toString().trim().isNotEmpty) {
            return [
              ArticleBlockRenderer(
                block: {
                  'type': 'html',
                  'html': payloadHtml.toString(),
                },
                fallbackAsset: _fallbackAssetForSource(
                  _stringValue(payloadMap, ['bucket', 'content_type']),
                ),
              ),
            ];
          }
        }
      }
    }

    if (body.trim().isEmpty) {
      return [
        Text(
          'Content body is not available yet.',
          style: TextStyle(
            color: colors.bodySecondary,
            fontSize: 14.5,
            height: 1.55,
            fontWeight: FontWeight.w600,
          ),
        ),
      ];
    }

    final paras = body
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return [
      for (final p in paras) ...[
        SelectableText(
          p,
          style: TextStyle(
            color: colors.bodyPrimary,
            fontSize: 15.2,
            height: 1.62,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
      ]
    ];
  }

  static String _flattenBlocksText(List<Map<String, dynamic>> blocks) {
    final buffer = StringBuffer();

    void addText(String value) {
      final clean = value.trim();
      if (clean.isEmpty) return;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(clean);
    }

    for (final block in blocks) {
      final type = (block['type'] ?? '').toString().trim().toLowerCase();

      if (type == 'bullet_list' || type == 'list') {
        final items = block['items'];
        if (items is List) {
          for (final item in items) {
            final text = item.toString().trim();
            if (text.isNotEmpty) {
              addText('• $text');
            }
          }
        }
        continue;
      }

      final directText = (block['text'] ?? '').toString().trim();
      if (directText.isNotEmpty) {
        addText(directText);
        continue;
      }

      final html = (block['html'] ?? block['body'] ?? '').toString().trim();
      if (html.isNotEmpty) {
        addText(_stripHtml(html));
      }
    }

    return buffer.toString().trim();
  }

  static String _stripHtml(String value) {
    return value
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  static String _detectBibleReference(String input) {
    final cleaned = input.replaceAll('\n', ' ');
    final regex = RegExp(
      r'\b(?:[1-3]\s*)?(?:Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|Samuel|Kings|Chronicles|Ezra|Nehemiah|Esther|Job|Psalms?|Proverbs|Ecclesiastes|Song of Solomon|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|Corinthians|Galatians|Ephesians|Philippians|Colossians|Thessalonians|Timothy|Titus|Philemon|Hebrews|James|Peter|Jude|Revelation)\s+\d+:\d+(?:-\d+)?\b',
      caseSensitive: false,
    );

    final match = regex.firstMatch(cleaned);
    if (match == null) return '';
    return (match.group(0) ?? '').trim();
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return null;
  }

  static String? _pickImage(Map<String, dynamic> item) {
    const directKeys = [
      'cover_image_url',
      'image_url',
      'cover_image',
      'cover_url',
      'banner_url',
      'featured_image',
      'thumbnail_url',
      'thumbnail',
      'image',
      'poster',
      'photo',
      'cover_asset_url',
    ];

    for (final key in directKeys) {
      final value = item[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }

    final payload = item['payload'];
    if (payload is Map) {
      final cover = payload['cover'];
      if (cover is Map) {
        for (final key in directKeys) {
          final value = cover[key];
          final s = value?.toString().trim() ?? '';
          if (s.isNotEmpty) return s;
        }
      }

      for (final key in directKeys) {
        final value = payload[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return s;
      }
    }

    return null;
  }

  static String _fallbackAssetForSource(String? source) {
    switch ((source ?? '').toLowerCase()) {
      case 'highlights':
        return 'assets/images/home_4.jpg';
      case 'wordification':
        return 'assets/images/home_5.jpg';
      case 'motivation':
        return 'assets/images/home_1.jpg';
      case 'sod':
      case 'sod_quotes':
        return 'assets/images/home_2.jpg';
      case 'inside_dunamis':
      case 'articles':
      default:
        return 'assets/images/home_3.jpg';
    }
  }

  static String _bannerTabKey(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'wordification':
        return 'inspire.wordification';
      case 'motivation':
        return 'inspire.motivation';
      case 'highlights':
      case 'highlight':
        return 'inspire.highlights';
      case 'sod':
        return 'inspire.sod.read';
      case 'sod_quotes':
        return 'inspire.sod.quotes';
      case 'inside_dunamis':
      case 'articles':
      default:
        return 'inspire.articles';
    }
  }

  static String? _stringValue(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      final s = value?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  static String? _stringValueFromPayload(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    final payload = item['payload'];
    if (payload is! Map) return null;
    return _stringValue(payload.cast<String, dynamic>(), keys);
  }

  static bool? _boolValue(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value is bool) return value;
      if (value is num) return value == 1;
      if (value is String) {
        final s = value.trim().toLowerCase();
        if (['1', 'true', 'yes', 'on'].contains(s)) return true;
        if (['0', 'false', 'no', 'off'].contains(s)) return false;
      }
    }
    return null;
  }

  static int? _intValue(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final parsed = _intFromDynamic(item[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static int? _intFromDynamic(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String _bucketLabel(String raw) {
    final key = raw.trim().toLowerCase();
    switch (key) {
      case 'inside_dunamis':
      case 'articles':
        return 'INSIDE DUNAMIS';
      case 'highlights':
      case 'highlight':
        return 'HIGHLIGHTS';
      case 'wordification':
        return 'WORDIFICATION';
      case 'motivation':
        return 'MOTIVATION';
      case 'sod':
      case 'sod_quotes':
        return 'SOD';
      default:
        return 'ARTICLE';
    }
  }

  static String _buildShareText({
    required String title,
    required String? subtitle,
    required String author,
    required String articleId,
  }) {
    final parts = <String>[
      title.trim(),
      if ((subtitle ?? '').trim().isNotEmpty) subtitle!.trim(),
      'By $author',
      'Read in Dunamis TV:',
      AppConfig.articleShareUrl(articleId),
    ];

    return parts.join('\n\n');
  }

  static String? _formatPublishedDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final parsed = DateTime.parse(raw).toLocal();

      const months = <String>[
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final month = months[parsed.month - 1];
      final day = parsed.day;
      final year = parsed.year;

      final hour24 = parsed.hour;
      final minute = parsed.minute.toString().padLeft(2, '0');
      final suffix = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);

      return '$month $day, $year • $hour12:$minute $suffix';
    } catch (_) {
      return raw;
    }
  }
}

class _ArticleHeroCard extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final String bucketLabel;
  final _ArticleDetailColors colors;

  const _ArticleHeroCard({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.bucketLabel,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 230,
        child: Stack(
          children: [
            Positioned.fill(
              child: _SmartImage(
                imageUrl: imageUrl,
                fallbackAsset: fallbackAsset,
                colors: colors,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.04),
                      Colors.black.withOpacity(0.18),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.heroBorder),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: _ArticlePill(text: bucketLabel, colors: colors),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleTitlePanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final _ArticleDetailColors colors;

  const _ArticleTitlePanel({
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final cleanSubtitle = (subtitle ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.trim().isEmpty ? 'Reading' : title.trim(),
            style: TextStyle(
              color: colors.panelTitle,
              fontSize: 22,
              height: 1.14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (cleanSubtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              cleanSubtitle,
              style: TextStyle(
                color: colors.panelSubtitle,
                fontSize: 13.4,
                height: 1.38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArticleMetaCard extends StatelessWidget {
  final String author;
  final String? publishedAt;
  final String bucketLabel;
  final _ArticleDetailColors colors;

  const _ArticleMetaCard({
    required this.author,
    required this.publishedAt,
    required this.bucketLabel,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleText = (publishedAt ?? '').trim().isNotEmpty
        ? 'Published • $publishedAt'
        : bucketLabel;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)],
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: colors.onAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author,
                  style: TextStyle(
                    color: colors.panelTitle,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: TextStyle(
                    color: colors.panelSubtitle,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final String shareText;
  final bool liked;
  final int likesCount;
  final int commentsCount;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentsTap;
  final VoidCallback? onQuoteTap;
  final bool likeBusy;
  final _ArticleDetailColors colors;

  const _ActionRow({
    required this.title,
    required this.shareText,
    required this.liked,
    required this.likesCount,
    required this.commentsCount,
    required this.onLikeTap,
    required this.onCommentsTap,
    required this.onQuoteTap,
    required this.likeBusy,
    required this.colors,
  });

  void _share(BuildContext context) {
    Share.share(shareText.trim().isNotEmpty ? shareText : title);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _MiniActionButton(
          icon: Icons.share_rounded,
          label: 'Share',
          onTap: () => _share(context),
          colors: colors,
        ),
        _MiniActionButton(
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          label: likeBusy ? 'Please wait...' : 'Like ($likesCount)',
          onTap: likeBusy ? () {} : onLikeTap,
          colors: colors,
          active: liked,
        ),
        _MiniActionButton(
          icon: Icons.mode_comment_outlined,
          label: 'Comments ($commentsCount)',
          onTap: onCommentsTap,
          colors: colors,
        ),
        if (onQuoteTap != null)
          _MiniActionButton(
            icon: Icons.format_quote_rounded,
            label: 'Open in Quote Creator',
            onTap: onQuoteTap!,
            colors: colors,
          ),
      ],
    );
  }
}

class _SelectedTextToolsCard extends StatelessWidget {
  final String selectedText;
  final String detectedReference;
  final VoidCallback onCopyTap;
  final VoidCallback onNotesTap;
  final VoidCallback onQuoteTap;
  final VoidCallback onBibleTap;
  final _ArticleDetailColors colors;

  const _SelectedTextToolsCard({
    required this.selectedText,
    required this.detectedReference,
    required this.onCopyTap,
    required this.onNotesTap,
    required this.onQuoteTap,
    required this.onBibleTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final hasBibleReference = detectedReference.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Text Tools',
            style: TextStyle(
              color: colors.panelTitle,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selectedText,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.panelSubtitle,
              fontSize: 12.8,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasBibleReference) ...[
            const SizedBox(height: 8),
            Text(
              'Scripture detected: $detectedReference',
              style: TextStyle(
                color: colors.panelTitle,
                fontSize: 12.3,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniActionButton(
                icon: Icons.format_quote_rounded,
                label: 'Make Quote',
                onTap: onQuoteTap,
                colors: colors,
              ),
              _MiniActionButton(
                icon: Icons.note_add_rounded,
                label: 'Add to Notes',
                onTap: onNotesTap,
                colors: colors,
              ),
              if (hasBibleReference)
                _MiniActionButton(
                  icon: Icons.menu_book_rounded,
                  label: 'Open Bible',
                  onTap: onBibleTap,
                  colors: colors,
                ),
              _MiniActionButton(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: onCopyTap,
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReaderSettingsCard extends StatelessWidget {
  final _ArticleDetailColors colors;
  final double fontScale;
  final double speechRate;
  final double speechPitch;
  final bool ttsReady;
  final bool isSpeaking;
  final bool isPaused;
  final String ttsStatus;
  final ValueChanged<double> onFontScaleChanged;
  final ValueChanged<double> onSpeechRateChanged;
  final ValueChanged<double> onSpeechPitchChanged;
  final VoidCallback onReadTap;
  final VoidCallback onPauseTap;
  final VoidCallback onStopTap;

  const _ReaderSettingsCard({
    required this.colors,
    required this.fontScale,
    required this.speechRate,
    required this.speechPitch,
    required this.ttsReady,
    required this.isSpeaking,
    required this.isPaused,
    required this.ttsStatus,
    required this.onFontScaleChanged,
    required this.onSpeechRateChanged,
    required this.onSpeechPitchChanged,
    required this.onReadTap,
    required this.onPauseTap,
    required this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chrome_reader_mode_rounded,
                  color: colors.panelTitle, size: 19),
              const SizedBox(width: 8),
              Text(
                'Reader Settings',
                style: TextStyle(
                  color: colors.panelTitle,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${(fontScale * 100).round()}%',
                style: TextStyle(
                  color: colors.panelSubtitle,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniActionButton(
                icon: Icons.text_decrease_rounded,
                label: 'A-',
                onTap: () => onFontScaleChanged(fontScale - 0.08),
                colors: colors,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Slider(
                  value: fontScale.clamp(0.82, 1.42),
                  min: 0.82,
                  max: 1.42,
                  divisions: 12,
                  onChanged: onFontScaleChanged,
                ),
              ),
              const SizedBox(width: 10),
              _MiniActionButton(
                icon: Icons.text_increase_rounded,
                label: 'A+',
                onTap: () => onFontScaleChanged(fontScale + 0.08),
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Read aloud: $ttsStatus',
            style: TextStyle(
              color: colors.panelSubtitle,
              fontSize: 12.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniActionButton(
                icon: Icons.volume_up_rounded,
                label: isSpeaking
                    ? 'Restart'
                    : (isPaused ? 'Resume' : 'Read Aloud'),
                onTap: ttsReady ? onReadTap : () {},
                colors: colors,
              ),
              _MiniActionButton(
                icon: Icons.pause_rounded,
                label: 'Pause',
                onTap: ttsReady ? onPauseTap : () {},
                colors: colors,
              ),
              _MiniActionButton(
                icon: Icons.stop_rounded,
                label: 'Stop',
                onTap: ttsReady ? onStopTap : () {},
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ReaderSliderRow(
            label: 'Speed',
            value: speechRate,
            min: 0.25,
            max: 0.85,
            divisions: 12,
            colors: colors,
            onChanged: onSpeechRateChanged,
          ),
          _ReaderSliderRow(
            label: 'Voice pitch',
            value: speechPitch,
            min: 0.75,
            max: 1.35,
            divisions: 12,
            colors: colors,
            onChanged: onSpeechPitchChanged,
          ),
        ],
      ),
    );
  }
}

class _ReaderSliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final _ArticleDetailColors colors;
  final ValueChanged<double> onChanged;

  const _ReaderSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              color: colors.panelSubtitle,
              fontSize: 12.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _ReaderToolsCard extends StatelessWidget {
  final VoidCallback? onQuoteTap;
  final VoidCallback? onNotesTap;
  final VoidCallback? onBibleTap;
  final VoidCallback? onCopyTap;
  final bool canOpenBible;
  final String detectedReference;
  final _ArticleDetailColors colors;

  const _ReaderToolsCard({
    required this.onQuoteTap,
    required this.onNotesTap,
    required this.onBibleTap,
    required this.onCopyTap,
    required this.canOpenBible,
    required this.detectedReference,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reader Tools',
            style: TextStyle(
              color: colors.panelTitle,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            canOpenBible
                ? 'Send this reading into your tools. Scripture detected: $detectedReference'
                : 'Send this reading into your tools for quotes, notes, and personal study.',
            style: TextStyle(
              color: colors.panelSubtitle,
              fontSize: 12.4,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniActionButton(
                icon: Icons.format_quote_rounded,
                label: 'Make Quote',
                onTap: onQuoteTap ?? () {},
                colors: colors,
              ),
              _MiniActionButton(
                icon: Icons.note_add_rounded,
                label: 'Add to Notes',
                onTap: onNotesTap ?? () {},
                colors: colors,
              ),
              if (canOpenBible)
                _MiniActionButton(
                  icon: Icons.menu_book_rounded,
                  label: 'Open in Bible',
                  onTap: onBibleTap ?? () {},
                  colors: colors,
                ),
              _MiniActionButton(
                icon: Icons.copy_rounded,
                label: 'Copy Text',
                onTap: onCopyTap ?? () {},
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionHintCard extends StatelessWidget {
  final _ArticleDetailColors colors;
  final VoidCallback? onCopyTap;

  const _SelectionHintCard({
    required this.colors,
    required this.onCopyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)],
              ),
            ),
            child: Icon(
              Icons.touch_app_rounded,
              color: colors.onAccent,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Highlight any article text with the normal system selection menu, then use the Reader Tools below for Quote and Add to Notes.',
              style: TextStyle(
                color: colors.panelSubtitle,
                fontSize: 12.8,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onCopyTap != null) ...[
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Copy article text',
              onPressed: onCopyTap,
              icon: Icon(
                Icons.copy_rounded,
                color: colors.panelTitle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _ArticleDetailColors colors;
  final bool active;

  const _MiniActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colors,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.buttonBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.buttonText, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors.buttonText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsSectionHeader extends StatelessWidget {
  final int commentsCount;
  final bool expanded;
  final VoidCallback onToggle;
  final _ArticleDetailColors colors;

  const _CommentsSectionHeader({
    required this.commentsCount,
    required this.expanded,
    required this.onToggle,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.panelBorder),
          boxShadow: colors.panelShadow,
        ),
        child: Row(
          children: [
            Icon(
              Icons.mode_comment_outlined,
              color: colors.panelTitle,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                commentsCount > 0
                    ? 'Discussion ($commentsCount)'
                    : 'Discussion',
                style: TextStyle(
                  color: colors.panelTitle,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: colors.panelSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

class _CollapsedCommentsCard extends StatelessWidget {
  final int commentsCount;
  final VoidCallback onOpen;
  final _ArticleDetailColors colors;

  const _CollapsedCommentsCard({
    required this.commentsCount,
    required this.onOpen,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final text = commentsCount > 0
        ? '$commentsCount comment${commentsCount == 1 ? '' : 's'} available. Tap to open the discussion.'
        : 'No comments yet. Tap here to open the discussion and be the first to comment.';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.panelBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.panelBorder),
          boxShadow: colors.panelShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5B1FA8), Color(0xFFB70E7C)],
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: colors.onAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: colors.panelSubtitle,
                  fontSize: 13.2,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsCard extends StatelessWidget {
  final bool loading;
  final bool posting;
  final List<Map<String, dynamic>> comments;
  final int commentsCount;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final ValueChanged<int> onDelete;
  final _ArticleDetailColors colors;

  const _CommentsCard({
    required this.loading,
    required this.posting,
    required this.comments,
    required this.commentsCount,
    required this.controller,
    required this.onSubmit,
    required this.onDelete,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments ($commentsCount)',
            style: TextStyle(
              color: colors.panelTitle,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: colors.inputBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.inputBorder),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  maxLines: 3,
                  style: TextStyle(color: colors.inputText),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(color: colors.inputHint),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: posting ? null : onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB70E7C),
                      foregroundColor: colors.onAccent,
                    ),
                    child: Text(posting ? 'Posting...' : 'Post Comment'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (comments.isEmpty)
            Text(
              'No comments yet. Be the first to comment.',
              style: TextStyle(
                color: colors.panelSubtitle,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...comments.map(
              (comment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CommentTile(
                  comment: comment,
                  onDelete: () {
                    final id = _intFromDynamic(comment['id']);
                    if (id != null) {
                      onDelete(id);
                    }
                  },
                  colors: colors,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static int? _intFromDynamic(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final VoidCallback onDelete;
  final _ArticleDetailColors colors;

  const _CommentTile({
    required this.comment,
    required this.onDelete,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final user = comment['user'];
    final name = (user is Map ? user['name'] : null)?.toString() ?? 'Unknown';
    final body = (comment['body'] ?? '').toString();
    final createdAt = (comment['created_at'] ?? '').toString();
    final canDelete = comment['can_delete'] == true;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.commentBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.commentBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: colors.panelTitle,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (canDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.panelSubtitle,
                    size: 18,
                  ),
                  tooltip: 'Delete',
                ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            body,
            style: TextStyle(
              color: colors.bodyPrimary,
              fontSize: 13.4,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (createdAt.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              createdAt,
              style: TextStyle(
                color: colors.metaMuted,
                fontSize: 11.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArticleFooterCard extends StatelessWidget {
  final _ArticleDetailColors colors;

  const _ArticleFooterCard({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.panelBorder),
        boxShadow: colors.panelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reader Ready',
            style: TextStyle(
              color: colors.panelTitle,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This article page is now arranged for better reading, smoother interaction, and cleaner discussion flow.',
            style: TextStyle(
              color: colors.panelSubtitle,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final _ArticleDetailColors colors;

  const _SmartImage({
    required this.imageUrl,
    required this.fallbackAsset,
    required this.colors,
  });

  bool get _hasRemoteImage => (imageUrl ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasRemoteImage) {
      return Image.network(
        imageUrl!.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            fallbackAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: colors.imageFallback,
            ),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: colors.imageLoading,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          );
        },
      );
    }

    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: colors.imageFallback,
      ),
    );
  }
}

class _ArticlePill extends StatelessWidget {
  final String text;
  final _ArticleDetailColors colors;

  const _ArticlePill({
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.pillBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colors.pillBorder,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onImagePrimary,
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ArticleDetailColors {
  final Color scaffold;
  final Color panelBg;
  final Color panelBorder;
  final List<BoxShadow>? panelShadow;
  final Color panelTitle;
  final Color panelSubtitle;
  final Color metaMuted;
  final Color bodyPrimary;
  final Color bodySecondary;
  final Color buttonBg;
  final Color buttonText;
  final Color inputBg;
  final Color inputBorder;
  final Color inputText;
  final Color inputHint;
  final Color commentBg;
  final Color commentBorder;
  final Color heroBorder;
  final List<Color> heroOverlay;
  final Color onImagePrimary;
  final Color onImageSecondary;
  final Color pillBg;
  final Color pillBorder;
  final Color imageLoading;
  final Color imageFallback;
  final Color onAccent;

  const _ArticleDetailColors({
    required this.scaffold,
    required this.panelBg,
    required this.panelBorder,
    required this.panelShadow,
    required this.panelTitle,
    required this.panelSubtitle,
    required this.metaMuted,
    required this.bodyPrimary,
    required this.bodySecondary,
    required this.buttonBg,
    required this.buttonText,
    required this.inputBg,
    required this.inputBorder,
    required this.inputText,
    required this.inputHint,
    required this.commentBg,
    required this.commentBorder,
    required this.heroBorder,
    required this.heroOverlay,
    required this.onImagePrimary,
    required this.onImageSecondary,
    required this.pillBg,
    required this.pillBorder,
    required this.imageLoading,
    required this.imageFallback,
    required this.onAccent,
  });

  factory _ArticleDetailColors.fromBrightness(bool isLight) {
    if (isLight) {
      return _ArticleDetailColors(
        scaffold: const Color(0xFFF6F7FB),
        panelBg: Colors.white.withOpacity(0.94),
        panelBorder: const Color(0xFFE6E8F0),
        panelShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        panelTitle: const Color(0xFF1E1B16),
        panelSubtitle: const Color(0xFF5E6472),
        metaMuted: const Color(0xFF7B8496),
        bodyPrimary: const Color(0xFF242938),
        bodySecondary: const Color(0xFF5E6472),
        buttonBg: Colors.white.withOpacity(0.96),
        buttonText: const Color(0xFF1E1B16),
        inputBg: const Color(0xFFF7F8FC),
        inputBorder: const Color(0xFFE1E6F0),
        inputText: const Color(0xFF1E1B16),
        inputHint: const Color(0xFF8A91A3),
        commentBg: const Color(0xFFF8F9FC),
        commentBorder: const Color(0xFFE5E9F2),
        heroBorder: Colors.white.withOpacity(0.10),
        heroOverlay: [
          Colors.black.withOpacity(0.10),
          Colors.black.withOpacity(0.22),
          Colors.black.withOpacity(0.70),
        ],
        onImagePrimary: Colors.white,
        onImageSecondary: Colors.white.withOpacity(0.90),
        pillBg: Colors.black.withOpacity(0.28),
        pillBorder: Colors.white.withOpacity(0.16),
        imageLoading: const Color(0xFFE9ECF5),
        imageFallback: const Color(0xFFD9DEEA),
        onAccent: Colors.white,
      );
    }

    return _ArticleDetailColors(
      scaffold: const Color(0xFF0B1020),
      panelBg: const Color(0xFF0D1228),
      panelBorder: Colors.white.withOpacity(0.08),
      panelShadow: null,
      panelTitle: Colors.white,
      panelSubtitle: Colors.white.withOpacity(0.72),
      metaMuted: Colors.white.withOpacity(0.46),
      bodyPrimary: Colors.white.withOpacity(0.88),
      bodySecondary: Colors.white.withOpacity(0.78),
      buttonBg: const Color(0xFF0D1228),
      buttonText: Colors.white,
      inputBg: Colors.white.withOpacity(0.03),
      inputBorder: Colors.white.withOpacity(0.08),
      inputText: Colors.white,
      inputHint: Colors.white.withOpacity(0.42),
      commentBg: Colors.white.withOpacity(0.03),
      commentBorder: Colors.white.withOpacity(0.06),
      heroBorder: Colors.white.withOpacity(0.08),
      heroOverlay: [
        Colors.black.withOpacity(0.12),
        Colors.black.withOpacity(0.28),
        Colors.black.withOpacity(0.88),
      ],
      onImagePrimary: Colors.white,
      onImageSecondary: Colors.white.withOpacity(0.88),
      pillBg: Colors.black.withOpacity(0.34),
      pillBorder: Colors.white.withOpacity(0.14),
      imageLoading: const Color(0xFF151528),
      imageFallback: const Color(0xFF1B1B2A),
      onAccent: Colors.white,
    );
  }
}
