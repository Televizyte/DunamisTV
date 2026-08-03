import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import '../../../app_config.dart';
import '../../../features/hub/state/hub_scope.dart';
import '../../../theme/theme_controller.dart';
import '../../../services/ads_service.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/ads/native_inline_ad_tile.dart';
import '../../widgets/dxm_top_bar.dart';
import '../../widgets/gradient_page_background.dart';

class QuizPlaceholderScreen extends StatefulWidget {
  final String quizKey;
  final Map<String, dynamic> extra;

  const QuizPlaceholderScreen({
    super.key,
    required this.quizKey,
    this.extra = const <String, dynamic>{},
  });

  @override
  State<QuizPlaceholderScreen> createState() => _QuizPlaceholderScreenState();
}

class _QuizPlaceholderScreenState extends State<QuizPlaceholderScreen> {
  _QuizData? _apiData;
  bool _loading = false;
  String _error = '';
  bool _isPlaying = false;
  bool _showResult = false;
  int _activeLevelIndex = 0;
  int _activeQuestionIndex = 0;
  final Map<String, String> _answers = <String, String>{};
  final _QuizSoundController _sound = _QuizSoundController();
  int _streak = 0;
  bool _runtimeMode = false;
  bool _answering = false;
  int _runtimePackId = 0;
  int _runtimeLevelId = 0;
  int _selectedPackLevelIndex = 0;
  String _selectedPackLevelTitle = 'Level 1';
  List<_QuizPackSummary> _categoryPacks = const <_QuizPackSummary>[];
  bool _packsLoading = false;
  final Map<int, _RuntimeProgressSnapshot> _levelProgressById =
      <int, _RuntimeProgressSnapshot>{};
  bool _progressLoading = false;
  bool _quizMusicEnabled = true;
  bool _quizEffectsEnabled = true;

  @override
  void initState() {
    super.initState();
    unawaited(_sound.init().then((_) async {
      await _sound.setMusicEnabled(_quizMusicEnabled);
      await _sound.setEffectsEnabled(_quizEffectsEnabled);
    }));
    unawaited(_loadQuiz());
  }

  @override
  void dispose() {
    unawaited(_sound.dispose());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuizPlaceholderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quizKey != widget.quizKey ||
        oldWidget.extra.toString() != widget.extra.toString()) {
      _resetPlayState();
      unawaited(_loadQuiz());
    }
  }

  Future<void> _loadQuiz() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _packsLoading = _isBibleCategoryScreen && !_hasSelectedPack;
      _error = '';
      if (!_isBibleCategoryScreen || _hasSelectedPack) {
        _categoryPacks = const <_QuizPackSummary>[];
      }
      if (!_hasSelectedPack) {
        _levelProgressById.clear();
      }
      _progressLoading = _hasSelectedPack;
    });

    try {
      final data = await _QuizApiService.fetchQuiz(widget.quizKey);
      var resolvedData = data;
      var packs = const <_QuizPackSummary>[];

      if (_isBibleCategoryScreen && !_hasSelectedPack) {
        final rawPacks =
            await _QuizApiService.fetchCategoryPackSummaries(widget.quizKey);
        packs = _QuizPayloadResolver._filterPacksForCategory(
          widget.quizKey,
          rawPacks,
        );
      }

      var levelProgress = <int, _RuntimeProgressSnapshot>{};
      if (_hasSelectedPack) {
        resolvedData = await _QuizApiService.fetchPackDetail(
          packId: _selectedPackId,
          fallbackKey: widget.quizKey,
          fallback: data,
          extra: widget.extra,
        );
        levelProgress = await _QuizApiService.fetchLevelProgressForPack(
          packId: _selectedPackId,
          levels: resolvedData.levels,
        );
      }

      if (!mounted) return;
      setState(() {
        _apiData = resolvedData;
        _categoryPacks = packs;
        _levelProgressById
          ..clear()
          ..addAll(levelProgress);
        _loading = false;
        _packsLoading = false;
        _progressLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
        _packsLoading = false;
        _progressLoading = false;
      });
    }
  }

  bool get _isBibleQuizHome =>
      _QuizPayloadResolver._normalizeKey(widget.quizKey) == 'bible_quiz';

  bool get _isBibleCategoryScreen {
    final key = _QuizPayloadResolver._normalizeKey(widget.quizKey);
    return key == 'bible_general' ||
        key == 'bible_old_testament' ||
        key == 'bible_new_testament' ||
        key == 'bible_books' ||
        key == 'bible_characters' ||
        key == 'bible_memory';
  }

  int get _selectedPackId => _QuizApiService._firstPositiveInt([
        widget.extra['quiz_pack_id'],
        widget.extra['pack_id'],
        widget.extra['quizPackId'],
      ]);

  bool get _hasSelectedPack => _selectedPackId > 0;

  void _resetPlayState() {
    _isPlaying = false;
    _showResult = false;
    _activeLevelIndex = 0;
    _activeQuestionIndex = 0;
    _answers.clear();
    _streak = 0;
    _runtimeMode = false;
    _answering = false;
    _runtimePackId = 0;
    _runtimeLevelId = 0;
    _selectedPackLevelIndex = 0;
    _selectedPackLevelTitle = 'Level 1';
    unawaited(_sound.stopMusic());
  }

  bool _isLevelUnlocked(_QuizData data, int levelIndex) {
    if (levelIndex <= 0) return true;
    if (levelIndex >= data.levels.length) return false;

    for (var i = 0; i < levelIndex; i++) {
      final previousLevelId = data.levels[i].numericId;
      final progress = _levelProgressById[previousLevelId];
      if (progress?.isCompleted != true) return false;
    }
    return true;
  }

  Future<void> _startLevel(_QuizData data, int levelIndex,
      {bool restart = false}) async {
    if (levelIndex < 0 || levelIndex >= data.levels.length) return;
    if (!_isLevelUnlocked(data, levelIndex)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Complete Level $levelIndex first to unlock this level.'),
          ),
        );
      }
      return;
    }
    final selectedLevel = data.levels[levelIndex];
    setState(() {
      _activeLevelIndex = levelIndex;
      _selectedPackLevelIndex = levelIndex;
      _selectedPackLevelTitle = selectedLevel.title;
    });
    await _startQuiz(data, restart: restart);
  }

  void _enterRuntimeAttempt(
    _QuizData data,
    _RuntimeStartResult result,
    int packId,
    int levelId,
  ) {
    final runtimeData = data.applyRuntimeAttempt(result.payload);
    final hasQuestions = runtimeData.levels.isNotEmpty &&
        runtimeData.levels.first.questions.isNotEmpty;

    if (!hasQuestions) {
      final localHasQuestions = data.levels.isNotEmpty &&
          data.levels.any((level) => level.questions.isNotEmpty);
      setState(() {
        _apiData = data;
        _runtimeMode = false;
        _isPlaying = localHasQuestions;
        _showResult = false;
        _activeLevelIndex = _activeLevelIndex.clamp(0, data.levels.length - 1);
        _activeQuestionIndex = 0;
        _loading = false;
        _error = localHasQuestions
            ? ''
            : 'No quiz questions are available for this category yet.';
      });
      return;
    }

    setState(() {
      _apiData = runtimeData;
      _runtimeMode = true;
      _runtimePackId = packId;
      _runtimeLevelId = levelId;
      _isPlaying = true;
      _showResult = false;
      _activeLevelIndex = 0;
      _activeQuestionIndex = result.currentQuestionIndex
          .clamp(
            0,
            runtimeData.levels.isEmpty
                ? 0
                : runtimeData.levels.first.questions.length - 1,
          )
          .toInt();
      _answers
        ..clear()
        ..addAll(result.answeredLabelsByQuestionId);
      _streak = 0;
      _loading = false;
    });
  }

  Future<bool> _confirmResumeOrRestart(
    _QuizData data,
    _RuntimeStartResult result,
    int packId,
    int levelId,
  ) async {
    if (!result.isContinue || result.currentQuestionIndex <= 0) return true;
    if (!mounted) return false;

    setState(() => _loading = false);

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF10142A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume this quiz?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You stopped at Question ${result.currentQuestionIndex + 1}. Continue from there or restart this level from the beginning.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop('continue'),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                        'Continue from Question ${result.currentQuestionIndex + 1}'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop('restart'),
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Restart from Beginning'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop('cancel'),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return false;
    if (action == 'continue') {
      _enterRuntimeAttempt(data, result, packId, levelId);
      return false;
    }
    if (action == 'restart') {
      await _startQuiz(data, restart: true);
      return false;
    }
    return false;
  }

  Future<void> _startQuiz(_QuizData data, {bool restart = false}) async {
    if (!data.canStart || data.levels.isEmpty) return;

    await _sound.stage();
    unawaited(_sound.startMusic());

    final levelIndex = _activeLevelIndex.clamp(0, data.levels.length - 1);
    final level = data.levels[levelIndex];
    final packId = await _QuizApiService.resolveRuntimePackId(
      quizKey: widget.quizKey,
      extra: widget.extra,
      data: data,
    );
    final levelId = level.numericId;

    if (packId <= 0 || levelId <= 0) {
      setState(() {
        _resetPlayState();
        _isPlaying = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final result = await _QuizApiService.startRuntimeAttempt(
        quizPackId: packId,
        quizLevelId: levelId,
        restart: restart,
      );

      if (!mounted) return;

      final shouldEnter = restart
          ? true
          : await _confirmResumeOrRestart(data, result, packId, levelId);
      if (!mounted) return;
      if (shouldEnter) {
        _enterRuntimeAttempt(data, result, packId, levelId);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Runtime quiz start failed. Using local quiz mode. $error';
        _resetPlayState();
        _isPlaying = true;
      });
    }
  }

  Future<void> _chooseAnswer(_QuizQuestion question, String optionKey) async {
    if (_answering) return;

    if (!_runtimeMode || _runtimePackId <= 0 || _runtimeLevelId <= 0) {
      final isCorrect = question.correctOption == optionKey;
      if (isCorrect) {
        _streak++;
        _sound.correct(_streak);
      } else {
        _streak = 0;
        _sound.wrong();
      }
      setState(() {
        _answers[question.uid] = optionKey;
      });
      return;
    }

    setState(() => _answering = true);

    try {
      final answer = await _QuizApiService.answerRuntimeAttempt(
        quizPackId: _runtimePackId,
        quizLevelId: _runtimeLevelId,
        questionId: question.numericId,
        selectedLabel: optionKey,
        currentQuestionIndex: _activeQuestionIndex,
      );

      if (!mounted) return;

      if (answer.isCorrect) {
        _streak++;
        _sound.correct(_streak);
      } else {
        _streak = 0;
        _sound.wrong();
      }

      final updatedQuestion = question.copyWith(
        correctOption: answer.correctLabel,
        explanation: answer.explanation,
        answerNote: answer.answerNote,
        bibleReference: answer.bibleReference,
        bibleBook: answer.bibleBook,
        chapterStart: answer.chapterStart,
        verseStart: answer.verseStart,
        chapterEnd: answer.chapterEnd,
        verseEnd: answer.verseEnd,
      );

      setState(() {
        _apiData = (_apiData ??
                _QuizPayloadResolver.resolve(
                  quizKey: widget.quizKey,
                  extra: widget.extra,
                  hubRaw: const <String, dynamic>{},
                ))
            .replaceQuestion(updatedQuestion);
        _answers[question.uid] = optionKey;
        _answering = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _answering = false;
        _error = 'Could not submit answer yet. $error';
      });
    }
  }

  Future<void> _openQuizSettings() async {
    final colors = _QuizColors.fromLightMode(
      ThemeController.instance.isLightMode,
    );

    var sheetMusicEnabled = _quizMusicEnabled;
    var sheetEffectsEnabled = _quizEffectsEnabled;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.scaffold,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> updateMusic(bool value) async {
              setSheetState(() => sheetMusicEnabled = value);
              if (mounted) setState(() => _quizMusicEnabled = value);
              await _sound.setMusicEnabled(value);
              if (value && _isPlaying && !_showResult) {
                await _sound.startMusic();
              }
            }

            Future<void> updateEffects(bool value) async {
              setSheetState(() => sheetEffectsEnabled = value);
              if (mounted) setState(() => _quizEffectsEnabled = value);
              await _sound.setEffectsEnabled(value);
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.settings_rounded, color: colors.accent),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Quiz Settings',
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: Icon(Icons.close_rounded, color: colors.text),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _QuizSoundControlsCard(
                      colors: colors,
                      musicEnabled: sheetMusicEnabled,
                      effectsEnabled: sheetEffectsEnabled,
                      onMusicChanged: (value) => unawaited(updateMusic(value)),
                      onEffectsChanged: (value) =>
                          unawaited(updateEffects(value)),
                    ),
                    const SizedBox(height: 10),
                    _QuizAdPolicyNotice(colors: colors),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeRuntimeIfNeeded() async {
    if (!_runtimeMode || _runtimePackId <= 0 || _runtimeLevelId <= 0) return;
    try {
      await _QuizApiService.completeRuntimeAttempt(
        quizPackId: _runtimePackId,
        quizLevelId: _runtimeLevelId,
      );
      if (mounted) {
        setState(() {
          _levelProgressById[_runtimeLevelId] =
              _RuntimeProgressSnapshot.completed(_runtimeLevelId);
        });
      }
    } catch (_) {
      // Keep the local result screen usable even if completion sync fails.
    }
  }

  Future<void> _finishActiveLevel(_QuizData data) async {
    await _completeRuntimeIfNeeded();
    _sound.result(data.correctCount(_answers), data.totalQuestions);

    try {
      await AdsService.instance.trackAndMaybeShowInterstitial(
        context,
        tabKey: 'quiz',
        countAction: true,
      );
    } catch (_) {
      // Ads must never block quiz completion.
    }

    if (!mounted) return;
    setState(() {
      _showResult = true;
      _isPlaying = false;
    });
  }

  void _handleQuizBack() {
    if (_isPlaying || _showResult) {
      setState(_resetPlayState);
      return;
    }

    final normalized = _QuizPayloadResolver._normalizeKey(widget.quizKey);
    if (normalized.startsWith('bible_') && normalized != 'bible_quiz') {
      context.go('/quiz/bible_quiz');
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }

    context.go('/explore');
  }

  @override
  Widget build(BuildContext context) {
    final store = HubScope.maybeOf(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        ThemeController.instance,
        if (store != null) store,
      ]),
      builder: (context, _) {
        final fallbackData = _QuizPayloadResolver.resolve(
          quizKey: widget.quizKey,
          extra: widget.extra,
          hubRaw: store?.raw ?? const <String, dynamic>{},
        );

        final data = _apiData?.mergeMissing(fallbackData) ?? fallbackData;
        final colors = _QuizColors.fromLightMode(
          ThemeController.instance.isLightMode,
        );

        return Scaffold(
          backgroundColor: colors.scaffold,
          bottomNavigationBar: _QuizBottomBannerSlot(
            tabKey: data.adTabKey,
            colors: colors,
          ),
          body: Column(
            children: [
              DxmTopBar(
                title: data.title,
                showBack: true,
                showMenu: true,
                onBack: _handleQuizBack,
                onRefresh: () async {
                  await store?.refresh();
                  await _loadQuiz();
                },
                extraMenuItems: [
                  DxmTopBarMenuEntry(
                    icon: Icons.settings_rounded,
                    title: 'Quiz Settings',
                    subtitle: 'Music, sound effects, and quiz ad policy',
                    onTap: () => unawaited(_openQuizSettings()),
                  ),
                ],
              ),
              Expanded(
                child: GradientPageBackground(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await store?.refresh();
                      await _loadQuiz();
                    },
                    child: _buildBody(data, colors),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(_QuizData data, _QuizColors colors) {
    if (_showResult) {
      return _QuizResultView(
        data: data,
        answers: _answers,
        colors: colors,
        levelTitle: _selectedPackLevelTitle,
        levelNumber: _selectedPackLevelIndex + 1,
        onRestart: () {
          final restartIndex = _selectedPackLevelIndex;
          setState(_resetPlayState);
          unawaited(_loadQuiz().then((_) async {
            final packData = _apiData;
            if (packData != null && restartIndex < packData.levels.length) {
              await _startLevel(packData, restartIndex, restart: true);
            }
          }));
        },
        onBackToIntro: () {
          setState(_resetPlayState);
          unawaited(_loadQuiz());
        },
      );
    }

    if (_isPlaying && data.canStart) {
      return _QuizPlayView(
        data: data,
        colors: colors,
        activeLevelIndex: _activeLevelIndex,
        activeQuestionIndex: _activeQuestionIndex,
        answers: _answers,
        answering: _answering,
        onChoose: (question, optionKey) =>
            unawaited(_chooseAnswer(question, optionKey)),
        onNext: () {
          final currentLevel = data.levels[_activeLevelIndex];
          final hasNextQuestion =
              _activeQuestionIndex < currentLevel.questions.length - 1;

          if (hasNextQuestion) {
            setState(() => _activeQuestionIndex++);
            return;
          }

          unawaited(_finishActiveLevel(data));
        },
        onQuit: () {
          setState(_resetPlayState);
          unawaited(_loadQuiz());
        },
      );
    }

    final isPackPicker = _isBibleCategoryScreen && !_hasSelectedPack;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
      children: [
        if (_loading && !_packsLoading) _LoadingNotice(colors: colors),
        if (_error.trim().isNotEmpty) ...[
          _ErrorNotice(error: _error, colors: colors, onRetry: _loadQuiz),
          const SizedBox(height: 14),
        ],
        if (_isBibleQuizHome) ...[
          _BibleQuizCategoryPanel(
            colors: colors,
            onOpenCategory: (key) => context.go('/quiz/$key'),
          ),
          const SizedBox(height: 14),
          _QuizNativeAdSlot(tabKey: data.adTabKey, colors: colors),
        ] else if (isPackPicker) ...[
          _QuizPackPickerPanel(
            title: _QuizPayloadResolver._categoryTitle(widget.quizKey),
            subtitle: _QuizPayloadResolver._categorySubtitle(widget.quizKey),
            packs: _categoryPacks,
            loading: _packsLoading,
            colors: colors,
            showTestamentTabs:
                _QuizPayloadResolver._normalizeKey(widget.quizKey) ==
                        'bible_books' ||
                    _QuizPayloadResolver._normalizeKey(widget.quizKey) ==
                        'book_by_book',
            onOpenPack: (pack) {
              context.push(
                '/quiz/${widget.quizKey}',
                extra: pack.toRouteExtra(),
              );
            },
          ),
          const SizedBox(height: 14),
          _QuizNativeAdSlot(tabKey: data.adTabKey, colors: colors),
        ] else ...[
          _QuizHeroCard(
            data: data,
            colors: colors,
            onStart: data.canStart ? () => unawaited(_startQuiz(data)) : null,
          ),
          const SizedBox(height: 14),
          _QuizNativeAdSlot(tabKey: data.adTabKey, colors: colors),
          const SizedBox(height: 14),
          _QuizInfoGrid(data: data, colors: colors),
          const SizedBox(height: 14),
          if (data.canStart)
            _QuizLevelPreviewCard(
              data: data,
              colors: colors,
              progressByLevelId: _levelProgressById,
              progressLoading: _progressLoading,
              onStartLevel: (index) => unawaited(_startLevel(data, index)),
            )
          else
            _QuizReadinessCard(data: data, colors: colors),
        ],
      ],
    );
  }
}

class _QuizApiService {
  const _QuizApiService._();

  static Future<_QuizData> fetchQuiz(String quizKey) async {
    final normalized = _QuizPayloadResolver._normalizeKey(quizKey);

    if (!_isContainerQuizKey(normalized)) {
      final enginePack = await _fetchEnginePackByKey(normalized);
      if (enginePack != null) return enginePack;
    }

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quizzes/$normalized',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Quiz API ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid quiz response');

    final root = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    final data = _QuizPayloadResolver._asMap(root['data']) ?? root;

    final parsed = _QuizData.fromApi(data, fallbackKey: normalized);
    return hydrateMissingQuestions(parsed);
  }

  static bool _isContainerQuizKey(String key) {
    return const <String>{
      'bible_quiz',
      'bible_general',
      'bible_old_testament',
      'bible_new_testament',
      'bible_books',
      'book_by_book',
      'bible_characters',
      'bible_memory',
    }.contains(key);
  }

  static Future<_QuizData?> _fetchEnginePackByKey(String key) async {
    if (key.trim().isEmpty) return null;

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quiz/packs',
    ).replace(queryParameters: <String, String>{
      'slug': key,
      'per_page': '100',
    });

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final data = decoded['data'];
    if (data is! List) return null;

    final packs = data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item.cast<String, dynamic>()))
        .where((item) {
      final slug = _QuizPayloadResolver._normalizeKey(
        _QuizPayloadResolver._firstString(item, const ['slug', 'key']),
      );
      final status = _QuizPayloadResolver._firstString(
        item,
        const ['status', 'state'],
      ).toLowerCase();
      final enabled = _QuizPayloadResolver._firstBool(
        item,
        const ['is_enabled', 'enabled'],
        fallback: true,
      );
      return slug == key &&
          enabled &&
          (status.isEmpty || status == 'published');
    }).toList(growable: false);

    if (packs.isEmpty) return null;

    packs.sort((a, b) {
      final aq = _QuizQuestion._firstInt(
        a,
        const ['question_count', 'total_questions'],
      );
      final bq = _QuizQuestion._firstInt(
        b,
        const ['question_count', 'total_questions'],
      );
      if (aq != bq) return bq.compareTo(aq);

      final al = _QuizQuestion._firstInt(a, const ['level_count']);
      final bl = _QuizQuestion._firstInt(b, const ['level_count']);
      if (al != bl) return bl.compareTo(al);

      return _QuizQuestion._firstInt(a, const ['sort_order']).compareTo(
        _QuizQuestion._firstInt(b, const ['sort_order']),
      );
    });

    final selected = Map<String, dynamic>.from(packs.first);
    final packId = _QuizQuestion._firstInt(selected, const ['id', 'pack_id']);
    if (packId <= 0) return null;

    selected['quiz_pack_id'] = packId;
    selected['pack_id'] = packId;
    final fallback = _QuizData.fromApi(selected, fallbackKey: key);

    return fetchPackDetail(
      packId: packId,
      fallbackKey: key,
      fallback: fallback,
      extra: selected,
    );
  }

  static Future<_QuizData> hydrateMissingQuestions(_QuizData data) async {
    if (data.levels.isEmpty) return data;

    final hydrated = <_QuizLevel>[];
    for (final level in data.levels) {
      if (level.questions.isNotEmpty || level.numericId <= 0) {
        hydrated.add(level);
        continue;
      }

      try {
        final questions = await fetchLevelQuestions(level.numericId);
        hydrated.add(_QuizLevel(
          id: level.id,
          title: level.title,
          difficulty: level.difficulty,
          questions: questions,
          questionCount:
              questions.isNotEmpty ? questions.length : level.questionCount,
        ));
      } catch (_) {
        hydrated.add(level);
      }
    }

    final total = hydrated.fold<int>(
      0,
      (sum, level) => sum + level.questions.length,
    );

    return _QuizData(
      key: data.key,
      title: data.title,
      subtitle: data.subtitle,
      type: data.type,
      status: data.status,
      difficulty: data.difficulty,
      imageUrl: data.imageUrl,
      questionCount: total > 0 ? total : data.questionCount,
      levelCount: hydrated.length,
      leaderboardEnabled: data.leaderboardEnabled,
      levels: hydrated,
      runtimePackId: data.runtimePackId,
    );
  }

  static Future<List<_QuizQuestion>> fetchLevelQuestions(int levelId) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quiz/levels/$levelId/questions',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Quiz level questions API ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return const <_QuizQuestion>[];
    final root = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    final data = root['data'];
    final rawQuestions = data is List
        ? data
        : (_QuizPayloadResolver._asMap(data)?['questions'] ??
            _QuizPayloadResolver._asMap(data)?['items'] ??
            root['questions']);

    if (rawQuestions is! List) return const <_QuizQuestion>[];

    return rawQuestions
        .whereType<Map>()
        .map((item) => _QuizQuestion.fromApi(
              Map<String, dynamic>.from(item.cast<String, dynamic>()),
            ))
        .where((question) => question.options.isNotEmpty)
        .toList(growable: false);
  }

  static Future<int> resolveRuntimePackId({
    required String quizKey,
    required Map<String, dynamic> extra,
    required _QuizData data,
  }) async {
    final explicit = _firstPositiveInt([
      extra['quiz_pack_id'],
      extra['pack_id'],
      extra['quizPackId'],
      data.runtimePackId,
    ]);
    if (explicit > 0) return explicit;

    final key = _QuizPayloadResolver._normalizeKey(quizKey);
    var collection = '';
    var category = '';

    if (key == 'bible_books' || key == 'book_by_book') {
      collection = 'bible_quiz';
      category = 'book_by_book';
    } else if (key == 'sod_quiz' || key == 'sod') {
      collection = 'sod_quiz';
    } else if (key == 'article_quiz' || key == 'article') {
      collection = 'article_quiz';
    } else if (key == 'bible_quiz') {
      collection = 'bible_quiz';
      category = 'general';
    }

    if (collection.isEmpty) return 0;

    final packs = await fetchPacks(collection: collection, category: category);
    if (packs.isEmpty) return 0;

    packs.sort((a, b) {
      final aq = _QuizQuestion._firstInt(
          a, const ['question_count', 'total_questions']);
      final bq = _QuizQuestion._firstInt(
          b, const ['question_count', 'total_questions']);
      if (aq != bq) return bq.compareTo(aq);
      return _QuizQuestion._firstInt(a, const ['sort_order']).compareTo(
        _QuizQuestion._firstInt(b, const ['sort_order']),
      );
    });

    return _QuizQuestion._firstInt(packs.first, const ['id']);
  }

  static Future<List<Map<String, dynamic>>> fetchPacks({
    required String collection,
    String category = '',
  }) async {
    final query = <String, String>{'collection': collection};
    if (category.trim().isNotEmpty) query['category'] = category.trim();

    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quiz/packs',
    ).replace(queryParameters: query);

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Quiz packs API ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return const <Map<String, dynamic>>[];
    final data = decoded['data'];
    if (data is! List) return const <Map<String, dynamic>>[];

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<List<_QuizPackSummary>> fetchCategoryPackSummaries(
    String quizKey,
  ) async {
    final spec = _QuizPayloadResolver._categoryApiSpec(quizKey);
    if (spec.collection.isEmpty) return const <_QuizPackSummary>[];
    final raw = await fetchPacks(
      collection: spec.collection,
      category: spec.category,
    );
    return raw
        .map((item) =>
            _QuizPackSummary.fromApi(item, fallbackCategory: spec.category))
        .where((pack) => pack.id > 0 && pack.isPublished)
        .toList(growable: false);
  }

  static Future<_QuizData> fetchPackDetail({
    required int packId,
    required String fallbackKey,
    required _QuizData fallback,
    required Map<String, dynamic> extra,
  }) async {
    final levels = await fetchPackLevels(packId);
    final title = _QuizPayloadResolver._firstString(
      extra,
      const ['pack_title', 'title', 'name'],
    );
    final subtitle = _QuizPayloadResolver._firstString(
      extra,
      const ['pack_subtitle', 'subtitle', 'description'],
    );
    final type = _QuizPayloadResolver._firstString(
      extra,
      const ['pack_type', 'type'],
    );
    final questionCount = _firstPositiveInt([
      extra['question_count'],
      extra['total_questions'],
      levels.fold<int>(0, (sum, level) => sum + level.questionCount),
      fallback.questionCount,
    ]);

    final resolved = _QuizData(
      key: fallback.key,
      title: title.isNotEmpty ? title : fallback.title,
      subtitle: subtitle.isNotEmpty ? subtitle : fallback.subtitle,
      type: type.isNotEmpty ? type : fallback.type,
      status: 'published',
      difficulty: fallback.difficulty.isNotEmpty ? fallback.difficulty : 'easy',
      imageUrl: fallback.imageUrl,
      questionCount: questionCount,
      levelCount: levels.isNotEmpty ? levels.length : fallback.levelCount,
      leaderboardEnabled: fallback.leaderboardEnabled,
      levels: levels.isNotEmpty ? levels : fallback.levels,
      runtimePackId: packId,
    );

    return hydrateMissingQuestions(resolved);
  }

  static Future<List<_QuizLevel>> fetchPackLevels(int packId) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quiz/packs/$packId/levels',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Quiz pack levels API ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return const <_QuizLevel>[];
    final root = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    final data = root['data'];
    final rawLevels = data is List
        ? data
        : (_QuizPayloadResolver._asMap(data)?['levels'] ??
            _QuizPayloadResolver._asMap(root['data'])?['items']);
    if (rawLevels is! List) return const <_QuizLevel>[];

    return rawLevels
        .whereType<Map>()
        .map((item) => _QuizLevel.fromApi(
              Map<String, dynamic>.from(item.cast<String, dynamic>()),
              allowEmpty: true,
            ))
        .where((level) => level.numericId > 0)
        .toList(growable: false);
  }

  static Future<_RuntimeStartResult> startRuntimeAttempt({
    required int quizPackId,
    required int quizLevelId,
    bool restart = false,
  }) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quiz/attempt/start',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-APP-TOKEN': AppConfig.appToken,
          },
          body: jsonEncode({
            'quiz_pack_id': quizPackId,
            'quiz_level_id': quizLevelId,
            'restart': restart,
            'shuffle_questions': true,
            'shuffle_options': true,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Start attempt API ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid start response');
    final root = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    if (root['ok'] != true) throw Exception(root['error'] ?? 'Start failed');
    final data = Map<String, dynamic>.from(
      (_QuizPayloadResolver._asMap(root['data']) ?? const <String, dynamic>{}),
    );
    data['mode'] = _QuizPayloadResolver._firstString(root, const ['mode']);
    return _RuntimeStartResult.fromMap(data);
  }

  static Future<_RuntimeAnswerResult> answerRuntimeAttempt({
    required int quizPackId,
    required int quizLevelId,
    required int questionId,
    required String selectedLabel,
    required int currentQuestionIndex,
  }) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quiz/attempt/answer',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-APP-TOKEN': AppConfig.appToken,
          },
          body: jsonEncode({
            'quiz_pack_id': quizPackId,
            'quiz_level_id': quizLevelId,
            'question_id': questionId,
            'selected_label': selectedLabel,
            'current_question_index': currentQuestionIndex,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Answer attempt API ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw const FormatException('Invalid answer response');
    final root = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    if (root['ok'] != true) throw Exception(root['error'] ?? 'Answer failed');
    final data =
        _QuizPayloadResolver._asMap(root['data']) ?? const <String, dynamic>{};
    return _RuntimeAnswerResult.fromMap(data);
  }

  static Future<void> completeRuntimeAttempt({
    required int quizPackId,
    required int quizLevelId,
  }) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quiz/attempt/complete',
    );

    await http
        .post(
          url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-APP-TOKEN': AppConfig.appToken,
          },
          body: jsonEncode({
            'quiz_pack_id': quizPackId,
            'quiz_level_id': quizLevelId,
          }),
        )
        .timeout(const Duration(seconds: 20));
  }

  static Future<Map<int, _RuntimeProgressSnapshot>> fetchLevelProgressForPack({
    required int packId,
    required List<_QuizLevel> levels,
  }) async {
    final results = <int, _RuntimeProgressSnapshot>{};
    if (packId <= 0 || levels.isEmpty) return results;

    for (final level in levels) {
      final levelId = level.numericId;
      if (levelId <= 0) continue;
      try {
        final snapshot = await fetchRuntimeProgress(
          quizPackId: packId,
          quizLevelId: levelId,
        );
        results[levelId] = snapshot;
      } catch (_) {
        results[levelId] = _RuntimeProgressSnapshot.empty(levelId);
      }
    }

    return results;
  }

  static Future<_RuntimeProgressSnapshot> fetchRuntimeProgress({
    required int quizPackId,
    required int quizLevelId,
  }) async {
    final url = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/v1/apps/${AppConfig.appSlug}/quiz/progress/$quizPackId/$quizLevelId',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'X-APP-TOKEN': AppConfig.appToken,
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _RuntimeProgressSnapshot.empty(quizLevelId);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return _RuntimeProgressSnapshot.empty(quizLevelId);
    final root = Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    final data = _QuizPayloadResolver._asMap(root['data']) ?? root;
    final progress = _QuizPayloadResolver._asMap(data['progress']) ?? data;
    return _RuntimeProgressSnapshot.fromMap(progress,
        fallbackLevelId: quizLevelId);
  }

  static int _firstPositiveInt(List<dynamic> values) {
    for (final value in values) {
      if (value is int && value > 0) return value;
      if (value is num && value.toInt() > 0) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed != null && parsed > 0) return parsed;
    }
    return 0;
  }
}

class _QuizPackSummary {
  final int id;
  final String title;
  final String subtitle;
  final String type;
  final String category;
  final String status;
  final int questionCount;
  final int levelCount;

  const _QuizPackSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.category,
    required this.status,
    required this.questionCount,
    required this.levelCount,
  });

  factory _QuizPackSummary.fromApi(
    Map<String, dynamic> map, {
    String fallbackCategory = '',
  }) {
    final rawTitle = _QuizPayloadResolver._firstString(
      map,
      const ['title', 'name', 'label'],
    );
    final title = rawTitle.isNotEmpty ? rawTitle : 'Quiz Pack';
    return _QuizPackSummary(
      id: _QuizQuestion._firstInt(map, const ['id', 'pack_id']),
      title: title,
      subtitle: _QuizPayloadResolver._firstString(
        map,
        const ['subtitle', 'description', 'summary'],
      ),
      type: _QuizPayloadResolver._firstString(
        map,
        const ['type', 'quiz_type', 'pack_type'],
      ),
      category:
          _QuizPayloadResolver._firstString(map, const ['category']).isNotEmpty
              ? _QuizPayloadResolver._firstString(map, const ['category'])
              : fallbackCategory,
      status:
          _QuizPayloadResolver._firstString(map, const ['status']).isNotEmpty
              ? _QuizPayloadResolver._firstString(map, const ['status'])
              : 'published',
      questionCount: _QuizQuestion._firstInt(
        map,
        const ['question_count', 'questions_count', 'total_questions'],
      ),
      levelCount: _QuizQuestion._firstInt(
        map,
        const ['level_count', 'levels_count'],
        fallback: 1,
      ),
    );
  }

  bool get isPublished => status.trim().toLowerCase() == 'published';
  bool get isPlayable => isPublished && levelCount > 0 && questionCount > 0;

  String get testament => _BibleBookTestament.fromTitle(title);

  String get displayTitle {
    final normalized = title.trim();
    if (normalized.toLowerCase().endsWith('quiz')) return normalized;
    return '$normalized Quiz';
  }

  Map<String, dynamic> toRouteExtra() => <String, dynamic>{
        'quiz_pack_id': id,
        'pack_id': id,
        'pack_title': displayTitle,
        'pack_subtitle': subtitle,
        'pack_type': type,
        'pack_category': category,
        'question_count': questionCount,
        'level_count': levelCount,
      };
}

class _QuizApiSpec {
  final String collection;
  final String category;

  const _QuizApiSpec(this.collection, this.category);
}

class _RuntimeProgressSnapshot {
  final int levelId;
  final String status;
  final int currentQuestionIndex;
  final int answeredCount;
  final int score;

  const _RuntimeProgressSnapshot({
    required this.levelId,
    required this.status,
    required this.currentQuestionIndex,
    required this.answeredCount,
    required this.score,
  });

  bool get hasProgress => currentQuestionIndex > 0 || answeredCount > 0;
  bool get isCompleted => status.trim().toLowerCase() == 'completed';

  factory _RuntimeProgressSnapshot.empty(int levelId) {
    return _RuntimeProgressSnapshot(
      levelId: levelId,
      status: 'not_started',
      currentQuestionIndex: 0,
      answeredCount: 0,
      score: 0,
    );
  }

  factory _RuntimeProgressSnapshot.completed(int levelId) {
    return _RuntimeProgressSnapshot(
      levelId: levelId,
      status: 'completed',
      currentQuestionIndex: 0,
      answeredCount: 0,
      score: 0,
    );
  }

  factory _RuntimeProgressSnapshot.fromMap(
    Map<String, dynamic> map, {
    required int fallbackLevelId,
  }) {
    final answered = map['answered_questions'];
    return _RuntimeProgressSnapshot(
      levelId: _QuizQuestion._firstInt(
        map,
        const ['quiz_level_id', 'level_id'],
        fallback: fallbackLevelId,
      ),
      status:
          _QuizPayloadResolver._firstString(map, const ['status']).isNotEmpty
              ? _QuizPayloadResolver._firstString(map, const ['status'])
              : 'not_started',
      currentQuestionIndex: _QuizQuestion._firstInt(
        map,
        const ['current_question_index'],
      ),
      answeredCount: answered is List
          ? answered.length
          : _QuizQuestion._firstInt(map, const ['answered_count']),
      score: _QuizQuestion._firstInt(map, const ['score']),
    );
  }
}

class _RuntimeStartResult {
  final Map<String, dynamic> payload;
  final String mode;
  final int currentQuestionIndex;
  final Map<String, String> answeredLabelsByQuestionId;

  const _RuntimeStartResult({
    required this.payload,
    required this.mode,
    required this.currentQuestionIndex,
    required this.answeredLabelsByQuestionId,
  });

  bool get isContinue => mode.trim().toLowerCase() == 'continue';

  factory _RuntimeStartResult.fromMap(Map<String, dynamic> map) {
    final progress = _QuizPayloadResolver._asMap(map['progress']) ??
        const <String, dynamic>{};
    final answered =
        progress['answered_questions'] ?? map['answered_questions'];
    final labels = <String, String>{};

    if (answered is List) {
      for (final item in answered.whereType<Map>()) {
        final itemMap = Map<String, dynamic>.from(item.cast<String, dynamic>());
        final questionId = _QuizPayloadResolver._firstString(
          itemMap,
          const ['question_id', 'id'],
        );
        final selected = _QuizPayloadResolver._firstString(
          itemMap,
          const ['selected_label', 'answer', 'selected'],
        ).toUpperCase();
        if (questionId.isNotEmpty && selected.isNotEmpty) {
          labels[questionId] = selected;
        }
      }
    }

    return _RuntimeStartResult(
      payload: map,
      mode: _QuizPayloadResolver._firstString(map, const ['mode']).isNotEmpty
          ? _QuizPayloadResolver._firstString(map, const ['mode'])
          : _QuizPayloadResolver._firstString(progress, const ['mode']),
      currentQuestionIndex: _QuizQuestion._firstInt(
        map,
        const ['current_question_index'],
        fallback:
            _QuizQuestion._firstInt(progress, const ['current_question_index']),
      ),
      answeredLabelsByQuestionId: labels,
    );
  }
}

class _RuntimeAnswerResult {
  final bool isCorrect;
  final String correctLabel;
  final String explanation;
  final String answerNote;
  final String bibleReference;
  final String bibleBook;
  final int chapterStart;
  final int verseStart;
  final int chapterEnd;
  final int verseEnd;

  const _RuntimeAnswerResult({
    required this.isCorrect,
    required this.correctLabel,
    required this.explanation,
    required this.answerNote,
    required this.bibleReference,
    required this.bibleBook,
    required this.chapterStart,
    required this.verseStart,
    required this.chapterEnd,
    required this.verseEnd,
  });

  factory _RuntimeAnswerResult.fromMap(Map<String, dynamic> map) {
    return _RuntimeAnswerResult(
      isCorrect: map['is_correct'] == true,
      correctLabel: _QuizPayloadResolver._firstString(
        map,
        const ['correct_label', 'correct_option'],
      ).toUpperCase(),
      explanation: _QuizPayloadResolver._firstString(
        map,
        const ['explanation', 'review_note'],
      ),
      answerNote: _QuizPayloadResolver._firstString(
        map,
        const ['answer_note', 'answerNote'],
      ),
      bibleReference: _QuizPayloadResolver._firstString(
        map,
        const ['bible_reference', 'reference'],
      ),
      bibleBook: _QuizPayloadResolver._firstString(
        map,
        const ['bible_book', 'book'],
      ),
      chapterStart:
          _QuizQuestion._firstInt(map, const ['chapter_start', 'chapter']),
      verseStart: _QuizQuestion._firstInt(map, const ['verse_start', 'verse']),
      chapterEnd: _QuizQuestion._firstInt(map, const ['chapter_end']),
      verseEnd: _QuizQuestion._firstInt(map, const ['verse_end']),
    );
  }
}

class _LoadingNotice extends StatelessWidget {
  final _QuizColors colors;

  const _LoadingNotice({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.3,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Loading quiz from AppsHub...',
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String error;
  final _QuizColors colors;
  final VoidCallback onRetry;

  const _ErrorNotice({
    required this.error,
    required this.colors,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.card,
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, color: colors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load the live quiz yet. Showing saved placeholder details. $error',
              style: TextStyle(
                color: colors.text,
                height: 1.4,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _BibleQuizCategoryPanel extends StatelessWidget {
  final _QuizColors colors;
  final void Function(String key) onOpenCategory;

  const _BibleQuizCategoryPanel({
    required this.colors,
    required this.onOpenCategory,
  });

  static const List<_BibleQuizCategory> _categories = [
    _BibleQuizCategory(
      key: 'bible_general',
      title: 'General Bible Knowledge',
      subtitle: 'Foundational Bible questions for everyone.',
      icon: Icons.auto_stories_rounded,
      gradient: [Color(0xFF101C54), Color(0xFF4C2EA8)],
    ),
    _BibleQuizCategory(
      key: 'bible_old_testament',
      title: 'Old Testament',
      subtitle: 'Creation, prophets, kings, psalms, and covenant stories.',
      icon: Icons.history_edu_rounded,
      gradient: [Color(0xFF14213D), Color(0xFF8A4F12)],
    ),
    _BibleQuizCategory(
      key: 'bible_new_testament',
      title: 'New Testament',
      subtitle: 'Gospels, Acts, epistles, and the life of Christ.',
      icon: Icons.church_rounded,
      gradient: [Color(0xFF0B3D4D), Color(0xFF0AA6C2)],
    ),
    _BibleQuizCategory(
      key: 'bible_books',
      title: 'Book by Book',
      subtitle: 'Genesis, Psalms, Matthew, John, Romans, and more.',
      icon: Icons.menu_book_rounded,
      gradient: [Color(0xFF25105C), Color(0xFFB70E7C)],
    ),
    _BibleQuizCategory(
      key: 'bible_characters',
      title: 'Bible Characters',
      subtitle: 'Abraham, Moses, David, Esther, Paul, Peter, and more.',
      icon: Icons.groups_rounded,
      gradient: [Color(0xFF2D1B69), Color(0xFF6D4CFF)],
    ),
    _BibleQuizCategory(
      key: 'bible_memory',
      title: 'Scripture Memory',
      subtitle: 'Recall references, verses, promises, and key truths.',
      icon: Icons.psychology_alt_rounded,
      gradient: [Color(0xFF5B1436), Color(0xFFFF2C96)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colors.card,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: colors.iconGradient),
                ),
                child: const Icon(Icons.quiz_rounded, color: Colors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Bible Quiz Category',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose a Bible study area. Each category opens its own quiz set.',
                      style: TextStyle(
                        color: colors.subText,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 640 ? 2 : 1;
              const spacing = 10.0;
              final width =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _categories
                    .map(
                      (item) => SizedBox(
                        width: width,
                        child: _BibleQuizCategoryCard(
                          item: item,
                          colors: colors,
                          onTap: () => onOpenCategory(item.key),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BibleQuizCategoryCard extends StatelessWidget {
  final _BibleQuizCategory item;
  final _QuizColors colors;
  final VoidCallback onTap;

  const _BibleQuizCategoryCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: item.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: item.gradient.last.withValues(alpha: 0.20),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(17),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.13)),
                ),
                child: Icon(item.icon, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 11.6,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BibleQuizCategory {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const _BibleQuizCategory({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}

class _QuizPackPickerPanel extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<_QuizPackSummary> packs;
  final bool loading;
  final _QuizColors colors;
  final void Function(_QuizPackSummary pack) onOpenPack;
  final bool showTestamentTabs;

  const _QuizPackPickerPanel({
    required this.title,
    required this.subtitle,
    required this.packs,
    required this.loading,
    required this.colors,
    required this.onOpenPack,
    this.showTestamentTabs = false,
  });

  @override
  State<_QuizPackPickerPanel> createState() => _QuizPackPickerPanelState();
}

class _QuizPackPickerPanelState extends State<_QuizPackPickerPanel> {
  String _activeTestament = 'old';

  List<_QuizPackSummary> get _visiblePacks {
    return widget.packs.where((pack) => pack.isPlayable).where((pack) {
      if (!widget.showTestamentTabs) return true;
      final testament = pack.testament;
      if (testament == 'unknown') return true;
      return testament == _activeTestament;
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final visiblePacks = _visiblePacks;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: colors.card,
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: LinearGradient(colors: colors.iconGradient),
                ),
                child:
                    const Icon(Icons.folder_copy_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: colors.subText,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.showTestamentTabs) ...[
            const SizedBox(height: 14),
            _TestamentTabs(
              active: _activeTestament,
              colors: colors,
              onChanged: (value) => setState(() => _activeTestament = value),
            ),
          ],
          const SizedBox(height: 16),
          if (widget.loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: colors.accent),
              ),
            )
          else if (visiblePacks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colors.scaffold.withValues(alpha: 0.28),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                widget.showTestamentTabs
                    ? 'No published ${_activeTestament == 'old' ? 'Old Testament' : 'New Testament'} book quiz is available yet. Once it is published in AppsHub, it will appear here automatically.'
                    : 'No published quiz pack is available in this category yet. Once it is created and published in AppsHub, it will appear here automatically.',
                style: TextStyle(
                  color: colors.subText,
                  height: 1.45,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ...visiblePacks.map(
              (pack) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuizPackTile(
                  pack: pack,
                  colors: colors,
                  onTap: () => widget.onOpenPack(pack),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TestamentTabs extends StatelessWidget {
  final String active;
  final _QuizColors colors;
  final ValueChanged<String> onChanged;

  const _TestamentTabs({
    required this.active,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.scaffold.withValues(alpha: 0.42),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _tab('old', 'Old Testament')),
          const SizedBox(width: 6),
          Expanded(child: _tab('new', 'New Testament')),
        ],
      ),
    );
  }

  Widget _tab(String value, String label) {
    final selected = active == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient:
              selected ? LinearGradient(colors: colors.iconGradient) : null,
          color: selected ? null : Colors.transparent,
          border: Border.all(
            color: selected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : colors.subText,
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _QuizPackTile extends StatelessWidget {
  final _QuizPackSummary pack;
  final _QuizColors colors;
  final VoidCallback onTap;

  const _QuizPackTile({
    required this.pack,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                colors.accent.withValues(alpha: 0.22),
                colors.card.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: colors.accent.withValues(alpha: 0.26)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(colors: colors.iconGradient),
                ),
                child: Center(
                  child: Text(
                    pack.title.trim().isEmpty
                        ? '?'
                        : pack.title.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pack.subtitle.trim().isNotEmpty
                          ? pack.subtitle.trim()
                          : '${pack.levelCount} level(s) • ${pack.questionCount} questions',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.subText,
                        height: 1.25,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        _Pill(
                            text: '${pack.levelCount} Levels', colors: colors),
                        _Pill(
                            text: '${pack.questionCount} Questions',
                            colors: colors),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: colors.text, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizHeroCard extends StatelessWidget {
  final _QuizData data;
  final _QuizColors colors;
  final VoidCallback? onStart;

  const _QuizHeroCard({
    required this.data,
    required this.colors,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.heroGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (data.imageUrl.trim().isNotEmpty)
            Positioned.fill(
              child: Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.heroOverlayTop,
                    colors.heroOverlayBottom,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(text: data.typeLabel, colors: colors),
                    _Pill(text: data.statusLabel, colors: colors),
                    _Pill(text: data.difficultyLabel, colors: colors),
                  ],
                ),
                const SizedBox(height: 34),
                Icon(Icons.quiz_rounded, color: colors.heroIcon, size: 46),
                const SizedBox(height: 12),
                Text(
                  data.title,
                  style: TextStyle(
                    color: colors.heroText,
                    fontSize: 29,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: colors.heroSubText,
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      data.canStart ? 'Start Quiz' : 'Questions Being Prepared',
                    ),
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

class _QuizPlayView extends StatefulWidget {
  final _QuizData data;
  final _QuizColors colors;
  final int activeLevelIndex;
  final int activeQuestionIndex;
  final Map<String, String> answers;
  final bool answering;
  final void Function(_QuizQuestion question, String optionKey) onChoose;
  final VoidCallback onNext;
  final VoidCallback onQuit;

  const _QuizPlayView({
    required this.data,
    required this.colors,
    required this.activeLevelIndex,
    required this.activeQuestionIndex,
    required this.answers,
    this.answering = false,
    required this.onChoose,
    required this.onNext,
    required this.onQuit,
  });

  @override
  State<_QuizPlayView> createState() => _QuizPlayViewState();
}

class _QuizPlayViewState extends State<_QuizPlayView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
      lowerBound: 0.92,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final colors = widget.colors;

    if (data.levels.isEmpty) {
      return const Center(
        child: Text(
          'No quiz levels are available yet.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      );
    }

    final safeLevelIndex =
        widget.activeLevelIndex.clamp(0, data.levels.length - 1);
    final level = data.levels[safeLevelIndex];
    if (level.questions.isEmpty) {
      return const Center(
        child: Text(
          'No quiz questions are available for this category yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      );
    }

    final safeQuestionIndex =
        widget.activeQuestionIndex.clamp(0, level.questions.length - 1);
    final question = level.questions[safeQuestionIndex];
    final selected = widget.answers[question.uid] ?? '';
    final answered = selected.isNotEmpty;
    final isCorrect = selected == question.correctOption;
    final isLastQuestion = safeQuestionIndex == level.questions.length - 1;
    final isLastLevel = widget.activeLevelIndex == data.levels.length - 1;
    final totalAnswered = widget.answers.length;
    final totalQuestions = data.totalQuestions;
    final xpEarned = data.correctCount(widget.answers) * 10;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: colors.heroGradient),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.16),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ScaleTransition(
                    scale: _pulseController,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        gradient: LinearGradient(colors: colors.iconGradient),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${level.title} · Question ${safeQuestionIndex + 1}/${level.questions.length}',
                      style: TextStyle(
                        color: colors.heroText,
                        fontSize: 18,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onQuit,
                    child: const Text('Quit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: data.progressValue(
                    widget.activeLevelIndex,
                    widget.activeQuestionIndex,
                  ),
                  minHeight: 10,
                  color: colors.accent,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniGameChip(
                    icon: Icons.bolt_rounded,
                    label: '$xpEarned XP',
                    colors: colors,
                  ),
                  const SizedBox(width: 8),
                  _MiniGameChip(
                    icon: Icons.check_circle_rounded,
                    label:
                        '${data.correctCount(widget.answers)}/$totalAnswered correct',
                    colors: colors,
                  ),
                  const Spacer(),
                  Text(
                    '$totalAnswered/$totalQuestions',
                    style: TextStyle(
                      color: colors.heroSubText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(question.uid),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: colors.card,
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Pill(text: '${question.points} XP', colors: colors),
                    _Pill(
                      text: answered
                          ? (isCorrect ? 'Correct' : 'Review')
                          : widget.answering
                              ? 'Saving...'
                              : 'Choose wisely',
                      colors: colors,
                    ),
                    _Pill(
                      text: 'No ads while answering',
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question.text,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 21,
                    height: 1.32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(height: 18),
                ...question.options.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AnswerOptionTile(
                      option: option,
                      selected: selected == option.key,
                      answered: answered,
                      correct: question.correctOption == option.key,
                      colors: colors,
                      onTap: answered || widget.answering
                          ? null
                          : () => widget.onChoose(question, option.key),
                    ),
                  ),
                ),
                if (answered) ...[
                  const SizedBox(height: 10),
                  _ExplanationCard(
                    question: question,
                    selected: selected,
                    colors: colors,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onNext,
                      icon: Icon(
                        isLastQuestion && isLastLevel
                            ? Icons.flag_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        isLastQuestion && isLastLevel
                            ? 'Finish Quiz'
                            : 'Next Question',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerOptionTile extends StatelessWidget {
  final _QuizOption option;
  final bool selected;
  final bool answered;
  final bool correct;
  final _QuizColors colors;
  final VoidCallback? onTap;

  const _AnswerOptionTile({
    required this.option,
    required this.selected,
    required this.answered,
    required this.correct,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = answered && correct
        ? colors.success
        : answered && selected && !correct
            ? colors.warning
            : selected
                ? colors.accent
                : colors.border;

    final icon = answered && correct
        ? Icons.check_circle_rounded
        : answered && selected && !correct
            ? Icons.cancel_rounded
            : selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      transform: Matrix4.identity()..scale(selected ? 1.015 : 1.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected || (answered && correct)
                ? LinearGradient(
                    colors: [
                      borderColor.withValues(alpha: 0.22),
                      colors.card.withValues(alpha: 0.88),
                    ],
                  )
                : null,
            color: selected || (answered && correct)
                ? null
                : colors.scaffold.withValues(alpha: 0.26),
            border: Border.all(color: borderColor, width: selected ? 1.8 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor.withValues(alpha: 0.17),
                  border:
                      Border.all(color: borderColor.withValues(alpha: 0.42)),
                ),
                child: Center(
                  child: Text(
                    option.key,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    color: colors.text,
                    height: 1.35,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: borderColor, size: 23),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final _QuizQuestion question;
  final String selected;
  final _QuizColors colors;

  const _ExplanationCard({
    required this.question,
    required this.selected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final correct = selected == question.correctOption;
    final explanation = question.explanation.trim().isEmpty
        ? 'The correct answer is option ${question.correctOption}.'
        : question.explanation.trim();

    final answerNote = question.answerNote.trim();
    final bibleReference = question.bibleReference.trim();
    final studyFocus = question.studyFocus.trim();
    final questionKind = question.questionKind.trim();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color:
            (correct ? colors.success : colors.warning).withValues(alpha: 0.10),
        border: Border.all(
          color: (correct ? colors.success : colors.warning)
              .withValues(alpha: 0.40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                correct ? Icons.celebration_rounded : Icons.lightbulb_rounded,
                color: correct ? colors.success : colors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  correct
                      ? 'Correct! $explanation'
                      : 'Good attempt. $explanation',
                  style: TextStyle(
                    color: colors.text,
                    height: 1.45,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (answerNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            _StudyInfoBox(
              icon: Icons.school_rounded,
              title: 'Answer Note',
              body: answerNote,
              colors: colors,
            ),
          ],
          if (bibleReference.isNotEmpty) ...[
            const SizedBox(height: 12),
            _BibleReferenceBox(
              reference: bibleReference,
              studyFocus: studyFocus,
              questionKind: questionKind,
              colors: colors,
              onOpen: () {
                final payload = question.toBiblePayload();
                final book = (payload['book'] ?? payload['bookName'] ?? '')
                    .toString()
                    .trim();
                final chapter = question.chapterStart > 0
                    ? question.chapterStart
                    : _QuizQuestion._firstInt(payload, const ['chapter']);
                final verse = question.verseStart > 0
                    ? question.verseStart
                    : _QuizQuestion._firstInt(payload, const ['verse']);
                final query = <String, String>{
                  if (book.isNotEmpty) 'book': book,
                  if (chapter > 0) 'chapter': chapter.toString(),
                  if (verse > 0) 'verse': verse.toString(),
                  if (verse > 0) 'highlight': verse.toString(),
                  if (verse > 0) 'focusVerse': verse.toString(),
                  if (verse > 0) 'scrollToVerse': verse.toString(),
                };
                final target = Uri(
                  path: '/tools/bible/reader',
                  queryParameters: query.isEmpty ? null : query,
                ).toString();
                context.push(target, extra: payload);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _StudyInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final _QuizColors colors;

  const _StudyInfoBox({
    required this.icon,
    required this.title,
    required this.body,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.scaffold.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.accent, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.subText,
                    fontSize: 12.5,
                    height: 1.42,
                    fontWeight: FontWeight.w700,
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

class _BibleReferenceBox extends StatelessWidget {
  final String reference;
  final String studyFocus;
  final String questionKind;
  final _QuizColors colors;
  final VoidCallback onOpen;

  const _BibleReferenceBox({
    required this.reference,
    required this.studyFocus,
    required this.questionKind,
    required this.colors,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final tags = <String>[
      if (studyFocus.trim().isNotEmpty) studyFocus.trim(),
      if (questionKind.trim().isNotEmpty) questionKind.trim(),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.accent.withValues(alpha: 0.18),
            colors.card.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: colors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bible Reference',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            reference,
            style: TextStyle(
              color: colors.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.scaffold.withValues(alpha: 0.36),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: colors.subText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open in Bible'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizResultView extends StatelessWidget {
  final _QuizData data;
  final Map<String, String> answers;
  final _QuizColors colors;
  final String levelTitle;
  final int levelNumber;
  final VoidCallback onRestart;
  final VoidCallback onBackToIntro;

  const _QuizResultView({
    required this.data,
    required this.answers,
    required this.colors,
    required this.levelTitle,
    required this.levelNumber,
    required this.onRestart,
    required this.onBackToIntro,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.totalQuestions;
    final correct = data.correctCount(answers);
    final wrong = (total - correct).clamp(0, total);
    final percent = total == 0 ? 0 : ((correct / total) * 100).round();
    final xp = correct * 10;
    final rank = percent >= 95
        ? 'Scripture Legend'
        : percent >= 85
            ? 'Bible Champion'
            : percent >= 70
                ? 'Covenant Victor'
                : percent >= 50
                    ? 'Faith Builder'
                    : 'Keep Training';
    final unlockedText = percent >= 50
        ? 'Next level unlocked after sync'
        : 'Replay this level to improve your score';

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: total == 0 ? 0 : correct / total),
          duration: const Duration(milliseconds: 950),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border:
                    Border.all(color: colors.accent.withValues(alpha: 0.35)),
                gradient: LinearGradient(colors: colors.heroGradient),
                boxShadow: [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.24),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniGameChip(
                        icon: Icons.emoji_events_rounded,
                        label: 'Level $levelNumber Complete',
                        colors: colors,
                      ),
                      _MiniGameChip(
                        icon: Icons.auto_awesome_rounded,
                        label: rank,
                        colors: colors,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Icon(
                    percent >= 50
                        ? Icons.workspace_premium_rounded
                        : Icons.psychology_alt_rounded,
                    color: colors.heroIcon,
                    size: 62,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    percent >= 50 ? 'Level Complete!' : 'Attempt Complete',
                    style: TextStyle(
                      color: colors.heroText,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data.title} • $levelTitle',
                    style: TextStyle(
                      color: colors.heroSubText,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correct of $total correct · $percent% accuracy',
                    style: TextStyle(
                      color: colors.heroSubText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 12,
                      color: percent >= 50 ? colors.success : colors.warning,
                      backgroundColor: colors.card,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _RewardBox(
                          icon: Icons.check_circle_rounded,
                          title: correct.toString(),
                          label: 'Correct',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RewardBox(
                          icon: Icons.cancel_rounded,
                          title: wrong.toString(),
                          label: 'Wrong',
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _RewardBox(
                          icon: Icons.bolt_rounded,
                          title: '+$xp XP',
                          label: 'XP Earned',
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RewardBox(
                          icon: Icons.workspace_premium_rounded,
                          title: rank,
                          label: 'Badge Rank',
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _QuizCertificatePreview(
          title: data.title,
          levelTitle: levelTitle,
          rank: rank,
          percent: percent,
          colors: colors,
        ),
        const SizedBox(height: 14),
        _QuizNativeAdSlot(
          tabKey: data.adTabKey,
          colors: colors,
          minHeight: 118,
        ),
        const SizedBox(height: 14),
        _LevelUnlockNotice(
          text: unlockedText,
          colors: colors,
          unlocked: percent >= 50,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onBackToIntro,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Back to Levels'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Replay Level'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuizCertificatePreview extends StatelessWidget {
  final String title;
  final String levelTitle;
  final String rank;
  final int percent;
  final _QuizColors colors;

  const _QuizCertificatePreview({
    required this.title,
    required this.levelTitle,
    required this.rank,
    required this.percent,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colors.card,
            colors.accent.withValues(alpha: 0.16),
          ],
        ),
        border: Border.all(color: colors.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech_rounded, color: colors.accent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Certificate path prepared',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Complete every level in $title to unlock a full book certificate. This level badge records $levelTitle, $percent% accuracy, and the rank: $rank.',
            style: TextStyle(
              color: colors.subText,
              fontSize: 12.5,
              height: 1.42,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelUnlockNotice extends StatelessWidget {
  final String text;
  final bool unlocked;
  final _QuizColors colors;

  const _LevelUnlockNotice({
    required this.text,
    required this.unlocked,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: (unlocked ? colors.success : colors.warning)
            .withValues(alpha: 0.12),
        border: Border.all(
          color: (unlocked ? colors.success : colors.warning)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.lock_open_rounded : Icons.replay_rounded,
            color: unlocked ? colors.success : colors.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGameChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final _QuizColors colors;

  const _MiniGameChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.heroIcon, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.heroText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String label;
  final _QuizColors colors;

  const _RewardBox({
    required this.icon,
    required this.title,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.heroIcon, size: 24),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.heroText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.heroSubText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _QuizInfoGrid extends StatelessWidget {
  final _QuizData data;
  final _QuizColors colors;

  const _QuizInfoGrid({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuizMetric(Icons.layers_rounded, 'Levels', data.levelCount.toString()),
      _QuizMetric(
          Icons.help_rounded, 'Questions', data.questionCount.toString()),
      const _QuizMetric(Icons.workspace_premium_rounded, 'Rewards', 'XP'),
      _QuizMetric(
        Icons.leaderboard_rounded,
        'Leaderboard',
        data.leaderboardEnabled ? 'Ready' : 'Later',
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.85,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: colors.card,
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(colors: colors.iconGradient),
                ),
                child: Icon(item.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.meta,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuizLevelPreviewCard extends StatelessWidget {
  final _QuizData data;
  final _QuizColors colors;
  final Map<int, _RuntimeProgressSnapshot> progressByLevelId;
  final bool progressLoading;
  final void Function(int index) onStartLevel;

  const _QuizLevelPreviewCard({
    required this.data,
    required this.colors,
    required this.progressByLevelId,
    required this.progressLoading,
    required this.onStartLevel,
  });

  bool _isUnlocked(int index) {
    if (index <= 0) return true;
    for (var i = 0; i < index; i++) {
      final previousLevelId = data.levels[i].numericId;
      if (progressByLevelId[previousLevelId]?.isCompleted != true) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Available Levels',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (progressLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...data.levels.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final level = entry.value;
              final count = level.questionCount > 0
                  ? level.questionCount
                  : level.questions.length;
              final progress = progressByLevelId[level.numericId];
              final completed = progress?.isCompleted == true;
              final hasProgress = progress?.hasProgress == true;
              final unlocked = _isUnlocked(index);
              final nextRequirement = index;
              final buttonLabel = completed
                  ? 'Replay'
                  : hasProgress
                      ? 'Continue'
                      : 'Start';
              final statusText = completed
                  ? 'Completed'
                  : unlocked
                      ? (hasProgress
                          ? 'Resume from Question ${(progress?.currentQuestionIndex ?? 0) + 1}'
                          : '$count questions')
                      : 'Complete Level $nextRequirement first';

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: unlocked ? 1 : 0.56,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    color: unlocked
                        ? colors.scaffold.withValues(alpha: 0.25)
                        : colors.scaffold.withValues(alpha: 0.12),
                    border: Border.all(
                      color: completed
                          ? colors.success.withValues(alpha: 0.45)
                          : colors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        completed
                            ? Icons.verified_rounded
                            : unlocked
                                ? Icons.layers_rounded
                                : Icons.lock_rounded,
                        color: completed
                            ? colors.success
                            : unlocked
                                ? colors.accent
                                : colors.meta,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level.title,
                              style: TextStyle(
                                color: colors.text,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: completed
                                    ? colors.success
                                    : unlocked
                                        ? colors.subText
                                        : colors.meta,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (unlocked)
                        FilledButton.icon(
                          onPressed: () => onStartLevel(index),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text(buttonLabel),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.lock_rounded, size: 17),
                          label: const Text('Locked'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuizBottomBannerSlot extends StatelessWidget {
  final String tabKey;
  final _QuizColors colors;

  const _QuizBottomBannerSlot({
    required this.tabKey,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTabKey = tabKey.trim().isNotEmpty ? tabKey.trim() : 'quiz';
    final allowed = _QuizAdsPolicy.isBannerAllowed(visibleTabKey);

    if (!allowed && !kIsWeb) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.scaffold.withOpacity(0.98),
          border: Border(
            top: BorderSide(color: colors.border.withOpacity(0.75)),
          ),
        ),
        child: allowed
            ? BannerAdWidget(
                tabKey: visibleTabKey,
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
              )
            : _QuizBottomAdPreviewPlaceholder(colors: colors),
      ),
    );
  }
}

class _QuizBottomAdPreviewPlaceholder extends StatelessWidget {
  final _QuizColors colors;

  const _QuizBottomAdPreviewPlaceholder({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.055),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: LinearGradient(colors: colors.iconGradient),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Quiz banner ad slot',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Backend-controlled adaptive banner area.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.66),
                          fontSize: 10.4,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withOpacity(0.10),
                  ),
                  child: const Text(
                    'Ad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizNativeAdSlot extends StatelessWidget {
  final String tabKey;
  final _QuizColors colors;
  final double minHeight;

  const _QuizNativeAdSlot({
    required this.tabKey,
    required this.colors,
    this.minHeight = 112,
  });

  @override
  Widget build(BuildContext context) {
    final visibleTabKey = tabKey.trim().isNotEmpty ? tabKey.trim() : 'quiz';
    final allowed = _QuizAdsPolicy.isNativeAllowed(visibleTabKey);

    if (!allowed && !kIsWeb) return const SizedBox.shrink();

    if (allowed) {
      return NativeInlineAdTile(
        tabKey: visibleTabKey,
        label: 'Sponsored',
        minHeight: minHeight,
      );
    }

    return _QuizAdPreviewPlaceholder(
      colors: colors,
      label: 'Native ad slot',
      message:
          'Enable native ads for the quiz tab in AppsHub to show sponsored cards in safe listing/result areas.',
      height: minHeight,
    );
  }
}

class _QuizAdPreviewPlaceholder extends StatelessWidget {
  final _QuizColors colors;
  final String label;
  final String message;
  final double height;

  const _QuizAdPreviewPlaceholder({
    required this.colors,
    required this.label,
    required this.message,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 7, 12, 9),
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.055),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: colors.iconGradient),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 11.2,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withOpacity(0.10),
            ),
            child: const Text(
              'Ad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizAdsPolicy {
  const _QuizAdsPolicy._();

  static bool isBannerAllowed(String tabKey) {
    try {
      return AdsService.instance.bannerAllowedForTab(tabKey);
    } catch (_) {
      return false;
    }
  }

  static bool isNativeAllowed(String tabKey) {
    try {
      return AdsService.instance.nativeAllowedForTab(tabKey);
    } catch (_) {
      return false;
    }
  }
}

class _QuizAdPolicyNotice extends StatelessWidget {
  final _QuizColors colors;

  const _QuizAdPolicyNotice({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_rounded, color: colors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ads are controlled from AppsHub. Banner, native, and interstitial placements use the existing app ad system and can be switched off from backend policy without changing this quiz screen.',
              style: TextStyle(
                color: colors.subText,
                fontSize: 12.3,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizSoundControlsCard extends StatelessWidget {
  final _QuizColors colors;
  final bool musicEnabled;
  final bool effectsEnabled;
  final ValueChanged<bool> onMusicChanged;
  final ValueChanged<bool> onEffectsChanged;

  const _QuizSoundControlsCard({
    required this.colors,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onMusicChanged,
    required this.onEffectsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volume_up_rounded, color: colors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quiz Sound',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Pill(text: 'Adventure audio', colors: colors),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dedicated quiz music and effects are ready for this engine. Final epic audio can be swapped later without changing the gameplay flow.',
            style: TextStyle(
              color: colors.subText,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: musicEnabled,
            onChanged: onMusicChanged,
            activeColor: colors.accent,
            title: Text(
              'Background music',
              style: TextStyle(color: colors.text, fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              'Epic adventure loop during active quiz play',
              style: TextStyle(color: colors.meta, fontWeight: FontWeight.w700),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: effectsEnabled,
            onChanged: onEffectsChanged,
            activeColor: colors.accent,
            title: Text(
              'Answer sound effects',
              style: TextStyle(color: colors.text, fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              'Correct, wrong, start, and level-complete sounds',
              style: TextStyle(color: colors.meta, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizReadinessCard extends StatelessWidget {
  final _QuizData data;
  final _QuizColors colors;

  const _QuizReadinessCard({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final message = data.canStart
        ? 'This quiz has questions and is ready to start.'
        : 'This quiz entry is connected to AppsHub, but questions are still being prepared or the quiz is not published yet.';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            data.canStart ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: data.canStart ? colors.success : colors.warning,
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.text,
                height: 1.45,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizRoadmapCard extends StatelessWidget {
  final _QuizColors colors;

  const _QuizRoadmapCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Questions come from AppsHub Quiz Center',
      'Score and XP are calculated locally for this version',
      'Banner ads stay outside active answering screens',
      'Works for SOD Quiz, Bible Quiz, Article Quiz, and future quizzes',
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: colors.card,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Engine Flow',
            style: TextStyle(
              color: colors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.bolt_rounded, color: colors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        color: colors.subText,
                        height: 1.35,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final _QuizColors colors;

  const _Pill({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: colors.pill,
        border: Border.all(color: colors.pillBorder),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: colors.pillText,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _QuizMetric {
  final IconData icon;
  final String label;
  final String value;

  const _QuizMetric(this.icon, this.label, this.value);
}

class _QuizData {
  final String key;
  final String title;
  final String subtitle;
  final String type;
  final String status;
  final String difficulty;
  final String imageUrl;
  final int questionCount;
  final int levelCount;
  final bool leaderboardEnabled;
  final List<_QuizLevel> levels;
  final int runtimePackId;

  const _QuizData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.difficulty,
    required this.imageUrl,
    required this.questionCount,
    required this.levelCount,
    required this.leaderboardEnabled,
    this.levels = const <_QuizLevel>[],
    this.runtimePackId = 0,
  });

  factory _QuizData.fromApi(Map<String, dynamic> map,
      {required String fallbackKey}) {
    final key = _QuizPayloadResolver._normalizeKey(
      _QuizPayloadResolver._firstString(
              map, const ['quiz_key', 'key', 'slug', 'id']).isNotEmpty
          ? _QuizPayloadResolver._firstString(
              map, const ['quiz_key', 'key', 'slug', 'id'])
          : fallbackKey,
    );

    final levels = _levelsFromApi(map);
    final flatQuestions =
        levels.fold<int>(0, (sum, level) => sum + level.questions.length);

    return _QuizData(
      key: key,
      title: _QuizPayloadResolver._firstString(
              map, const ['title', 'name', 'label']).isNotEmpty
          ? _QuizPayloadResolver._firstString(
              map, const ['title', 'name', 'label'])
          : _QuizPayloadResolver._titleFromKey(key),
      subtitle: _QuizPayloadResolver._firstString(
          map, const ['subtitle', 'description', 'summary']),
      type: _QuizPayloadResolver._firstString(
              map, const ['quiz_type', 'type', 'content_type']).isNotEmpty
          ? _QuizPayloadResolver._firstString(
              map, const ['quiz_type', 'type', 'content_type'])
          : _QuizPayloadResolver._typeFromKey(key),
      status: _QuizPayloadResolver._firstString(map, const ['status', 'state'])
              .isNotEmpty
          ? _QuizPayloadResolver._firstString(map, const ['status', 'state'])
          : 'draft',
      difficulty:
          _QuizPayloadResolver._firstString(map, const ['difficulty', 'level'])
                  .isNotEmpty
              ? _QuizPayloadResolver._firstString(
                  map, const ['difficulty', 'level'])
              : 'easy',
      imageUrl: _QuizPayloadResolver._firstString(map, const [
        'image_url',
        'image',
        'cover_image_url',
        'thumbnail_url',
        'poster_url',
      ]),
      questionCount: flatQuestions > 0
          ? flatQuestions
          : _QuizPayloadResolver._firstInt(map, const [
              'question_count',
              'questions_count',
              'total_questions',
            ]),
      levelCount: levels.isNotEmpty
          ? levels.length
          : _QuizPayloadResolver._firstInt(
              map, const ['level_count', 'levels_count'],
              fallback: 3),
      leaderboardEnabled: _QuizPayloadResolver._firstBool(
        map,
        const ['leaderboard_enabled', 'leaderboard'],
        fallback: true,
      ),
      levels: levels,
      runtimePackId: _QuizPayloadResolver._firstInt(
        map,
        const ['quiz_pack_id', 'pack_id', 'runtime_pack_id'],
      ),
    );
  }

  static List<_QuizLevel> _levelsFromApi(Map<String, dynamic> map) {
    final rawLevels = map['levels'];
    if (rawLevels is List) {
      return rawLevels
          .whereType<Map>()
          .map((item) => _QuizLevel.fromApi(
              Map<String, dynamic>.from(item.cast<String, dynamic>())))
          .where((level) =>
              level.questions.isNotEmpty ||
              level.numericId > 0 ||
              level.questionCount > 0)
          .toList(growable: false);
    }

    final rawQuestions = map['questions'];
    if (rawQuestions is List) {
      final grouped = <int, List<_QuizQuestion>>{};
      for (final item in rawQuestions.whereType<Map>()) {
        final question = _QuizQuestion.fromApi(
            Map<String, dynamic>.from(item.cast<String, dynamic>()));
        grouped
            .putIfAbsent(question.level, () => <_QuizQuestion>[])
            .add(question);
      }

      return grouped.entries
          .map((entry) => _QuizLevel(
                id: entry.key.toString(),
                title: 'Level ${entry.key}',
                difficulty: entry.key == 1
                    ? 'easy'
                    : entry.key == 2
                        ? 'medium'
                        : 'hard',
                questions: entry.value,
                questionCount: entry.value.length,
              ))
          .toList(growable: false);
    }

    return const <_QuizLevel>[];
  }

  _QuizData mergeMissing(_QuizData fallback) {
    return _QuizData(
      key: key.isNotEmpty ? key : fallback.key,
      title: title.isNotEmpty ? title : fallback.title,
      subtitle: subtitle.isNotEmpty ? subtitle : fallback.subtitle,
      type: type.isNotEmpty ? type : fallback.type,
      status: status.isNotEmpty ? status : fallback.status,
      difficulty: difficulty.isNotEmpty ? difficulty : fallback.difficulty,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : fallback.imageUrl,
      questionCount: questionCount > 0 ? questionCount : fallback.questionCount,
      levelCount: levelCount > 0 ? levelCount : fallback.levelCount,
      leaderboardEnabled: leaderboardEnabled,
      levels: levels.isNotEmpty ? levels : fallback.levels,
      runtimePackId: runtimePackId > 0 ? runtimePackId : fallback.runtimePackId,
    );
  }

  _QuizData applyRuntimeAttempt(Map<String, dynamic> attempt) {
    final pack = _QuizPayloadResolver._asMap(attempt['quiz_pack']) ??
        const <String, dynamic>{};
    final levelMap = _QuizPayloadResolver._asMap(attempt['level']) ??
        const <String, dynamic>{};
    final rawQuestions = attempt['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((item) => _QuizQuestion.fromApi(
                  Map<String, dynamic>.from(item.cast<String, dynamic>()),
                ))
            .where((question) => question.options.isNotEmpty)
            .toList(growable: false)
        : const <_QuizQuestion>[];

    final runtimeLevel = _QuizLevel(
      id: _QuizPayloadResolver._firstString(levelMap, const ['id']).isNotEmpty
          ? _QuizPayloadResolver._firstString(levelMap, const ['id'])
          : (levels.isNotEmpty ? levels.first.id : '1'),
      title: _QuizPayloadResolver._firstString(
              levelMap, const ['title', 'name', 'label']).isNotEmpty
          ? _QuizPayloadResolver._firstString(
              levelMap, const ['title', 'name', 'label'])
          : (levels.isNotEmpty ? levels.first.title : 'Level 1'),
      difficulty: _QuizPayloadResolver._firstString(
              levelMap, const ['difficulty']).isNotEmpty
          ? _QuizPayloadResolver._firstString(levelMap, const ['difficulty'])
          : difficulty,
      questions: questions,
      questionCount: questions.length,
    );

    return _QuizData(
      key: key,
      title: title,
      subtitle: subtitle,
      type: type,
      status: 'published',
      difficulty: difficulty,
      imageUrl: imageUrl,
      questionCount: questions.length,
      levelCount: 1,
      leaderboardEnabled: leaderboardEnabled,
      levels: [runtimeLevel],
      runtimePackId:
          _QuizQuestion._firstInt(pack, const ['id'], fallback: runtimePackId),
    );
  }

  _QuizData replaceQuestion(_QuizQuestion updatedQuestion) {
    return _QuizData(
      key: key,
      title: title,
      subtitle: subtitle,
      type: type,
      status: status,
      difficulty: difficulty,
      imageUrl: imageUrl,
      questionCount: questionCount,
      levelCount: levelCount,
      leaderboardEnabled: leaderboardEnabled,
      runtimePackId: runtimePackId,
      levels: levels
          .map((level) => level.replaceQuestion(updatedQuestion))
          .toList(growable: false),
    );
  }

  bool get canStart =>
      questionCount > 0 &&
      levels.isNotEmpty &&
      status.trim().toLowerCase() == 'published';

  int get totalQuestions =>
      levels.fold<int>(0, (sum, level) => sum + level.questions.length);

  int correctCount(Map<String, String> answers) {
    var total = 0;
    for (final level in levels) {
      for (final question in level.questions) {
        if ((answers[question.uid] ?? '') == question.correctOption) total++;
      }
    }
    return total;
  }

  double progressValue(int levelIndex, int questionIndex) {
    final total = totalQuestions;
    if (total <= 0) return 0;

    var completedBeforeLevel = 0;
    for (var i = 0; i < levelIndex; i++) {
      completedBeforeLevel += levels[i].questions.length;
    }

    return (completedBeforeLevel + questionIndex + 1) / total;
  }

  String get typeLabel => _humanize(type.isEmpty ? 'quiz' : type);
  String get statusLabel => _humanize(status.isEmpty ? 'draft' : status);
  String get difficultyLabel =>
      _humanize(difficulty.isEmpty ? 'easy' : difficulty);
  String get adTabKey => 'quiz.$key';

  static String _humanize(String value) {
    final words =
        value.replaceAll('_', ' ').replaceAll('-', ' ').trim().split(' ');
    return words
        .where((part) => part.trim().isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _QuizLevel {
  final String id;
  final String title;
  final String difficulty;
  final List<_QuizQuestion> questions;
  final int questionCount;

  const _QuizLevel({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.questions,
    this.questionCount = 0,
  });

  int get numericId => int.tryParse(id) ?? 0;

  _QuizLevel replaceQuestion(_QuizQuestion updatedQuestion) {
    return _QuizLevel(
      id: id,
      title: title,
      difficulty: difficulty,
      questionCount: questionCount,
      questions: questions
          .map((question) =>
              question.uid == updatedQuestion.uid ? updatedQuestion : question)
          .toList(growable: false),
    );
  }

  factory _QuizLevel.fromApi(Map<String, dynamic> map,
      {bool allowEmpty = false}) {
    final rawQuestions = map['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map>()
            .map((item) => _QuizQuestion.fromApi(
                Map<String, dynamic>.from(item.cast<String, dynamic>())))
            .where((question) => allowEmpty || question.options.isNotEmpty)
            .toList(growable: false)
        : const <_QuizQuestion>[];

    final title = _QuizPayloadResolver._firstString(
        map, const ['title', 'name', 'label']);
    final number = _QuizPayloadResolver._firstInt(
        map, const ['level_number', 'level', 'sort_order'],
        fallback: 1);
    final qCount = _QuizPayloadResolver._firstInt(
      map,
      const ['question_count', 'questions_count', 'total_questions'],
      fallback: questions.length,
    );

    return _QuizLevel(
      id: _QuizPayloadResolver._firstString(map, const ['id', 'key']).isNotEmpty
          ? _QuizPayloadResolver._firstString(map, const ['id', 'key'])
          : number.toString(),
      title: title.isNotEmpty ? title : 'Level $number',
      difficulty: _QuizPayloadResolver._firstString(map, const ['difficulty'])
              .isNotEmpty
          ? _QuizPayloadResolver._firstString(map, const ['difficulty'])
          : number == 1
              ? 'easy'
              : number == 2
                  ? 'medium'
                  : 'hard',
      questions: questions,
      questionCount: qCount,
    );
  }
}

class _QuizQuestion {
  final String uid;
  final String text;
  final List<_QuizOption> options;
  final String correctOption;
  final String explanation;
  final String answerNote;
  final String bibleReference;
  final String bibleBook;
  final int chapterStart;
  final int verseStart;
  final int chapterEnd;
  final int verseEnd;
  final String studyFocus;
  final String questionKind;
  final int level;
  final int points;

  const _QuizQuestion({
    required this.uid,
    required this.text,
    required this.options,
    required this.correctOption,
    required this.explanation,
    this.answerNote = '',
    this.bibleReference = '',
    this.bibleBook = '',
    this.chapterStart = 0,
    this.verseStart = 0,
    this.chapterEnd = 0,
    this.verseEnd = 0,
    this.studyFocus = '',
    this.questionKind = '',
    this.level = 1,
    required this.points,
  });

  int get numericId => int.tryParse(uid) ?? 0;

  _QuizQuestion copyWith({
    String? correctOption,
    String? explanation,
    String? answerNote,
    String? bibleReference,
    String? bibleBook,
    int? chapterStart,
    int? verseStart,
    int? chapterEnd,
    int? verseEnd,
  }) {
    return _QuizQuestion(
      uid: uid,
      text: text,
      options: options,
      correctOption: (correctOption == null || correctOption.trim().isEmpty)
          ? this.correctOption
          : correctOption.trim().toUpperCase(),
      explanation: explanation ?? this.explanation,
      answerNote: answerNote ?? this.answerNote,
      bibleReference: bibleReference ?? this.bibleReference,
      bibleBook: bibleBook ?? this.bibleBook,
      chapterStart: chapterStart ?? this.chapterStart,
      verseStart: verseStart ?? this.verseStart,
      chapterEnd: chapterEnd ?? this.chapterEnd,
      verseEnd: verseEnd ?? this.verseEnd,
      studyFocus: studyFocus,
      questionKind: questionKind,
      level: level,
      points: points,
    );
  }

  bool get hasBibleReference => bibleReference.trim().isNotEmpty;

  Map<String, dynamic> toBiblePayload() {
    final reference = bibleReference.trim();

    return <String, dynamic>{
      'source': 'quiz',
      'sourceType': 'quiz',
      'source_type': 'quiz',
      'sourceId': uid,
      'source_id': uid,
      'ref': reference,
      'reference': reference,
      'bible_reference': reference,
      'bibleReference': reference,
      'book': bibleBook.trim(),
      'bookName': bibleBook.trim(),
      'book_name': bibleBook.trim(),
      'chapter': chapterStart,
      'chapterNumber': chapterStart,
      'chapter_number': chapterStart,
      'verse': verseStart,
      'verseNumber': verseStart,
      'verse_number': verseStart,
      'verseStart': verseStart,
      'verse_start': verseStart,
      'selectedVerse': verseStart,
      'selected_verse': verseStart,
      'highlightVerse': verseStart,
      'highlight_verse': verseStart,
      'targetVerse': verseStart,
      'target_verse': verseStart,
      'initialVerse': verseStart,
      'initial_verse': verseStart,
      'scrollToVerse': verseStart,
      'scroll_to_verse': verseStart,
      'focusVerse': verseStart,
      'focus_verse': verseStart,
      'verseEnd': verseEnd,
      'verse_end': verseEnd,
      'chapterEnd': chapterEnd,
      'chapter_end': chapterEnd,
      'chapterStart': chapterStart,
      'chapter_start': chapterStart,
      'selectedReference': reference,
      'selected_reference': reference,
      'highlightReference': reference,
      'highlight_reference': reference,
      'scriptureText': answerNote.trim(),
      'scripture_text': answerNote.trim(),
      'text': answerNote.trim(),
      'note': explanation.trim(),
      'quiz_question': text.trim(),
    };
  }

  factory _QuizQuestion.fromApi(
    Map<String, dynamic> map, {
    String fallbackId = '',
    int fallbackLevel = 1,
    int fallbackPoints = 1,
  }) {
    final normalized = Map<String, dynamic>.from(map);
    if (fallbackId.trim().isNotEmpty &&
        (normalized['id'] == null ||
            normalized['id'].toString().trim().isEmpty)) {
      normalized['id'] = fallbackId;
    }
    if (normalized['points'] == null) {
      normalized['points'] = fallbackPoints;
    }
    if (normalized['level'] == null) {
      normalized['level'] = fallbackLevel;
    }
    return _QuizQuestion.fromMap(normalized);
  }

  factory _QuizQuestion.fromMap(Map<String, dynamic> map) {
    final id = _firstString(map, const ['id', 'uid', 'key', 'question_id']);
    final rawOptions = map['options'];
    final options = <_QuizOption>[];

    if (rawOptions is List) {
      for (var i = 0; i < rawOptions.length; i++) {
        final item = rawOptions[i];
        final fallbackKey = String.fromCharCode(65 + i);

        if (item is Map) {
          final itemMap =
              Map<String, dynamic>.from(item.cast<String, dynamic>());
          final key = _firstString(itemMap, const ['key', 'option', 'label'])
              .trim()
              .toUpperCase();
          final text =
              _firstString(itemMap, const ['text', 'value', 'answer', 'title']);
          if (text.trim().isNotEmpty) {
            options.add(_QuizOption(
              key: key.isEmpty ? fallbackKey : key,
              text: text,
            ));
          }
        } else {
          final text = item?.toString().trim() ?? '';
          if (text.isNotEmpty) {
            options.add(_QuizOption(key: fallbackKey, text: text));
          }
        }
      }
    }

    if (options.isEmpty) {
      for (final entry in const <String, List<String>>{
        'A': ['option_a', 'optionA', 'a'],
        'B': ['option_b', 'optionB', 'b'],
        'C': ['option_c', 'optionC', 'c'],
        'D': ['option_d', 'optionD', 'd'],
      }.entries) {
        final value = _firstString(map, entry.value);
        if (value.trim().isNotEmpty) {
          options.add(_QuizOption(key: entry.key, text: value));
        }
      }
    }

    var correct = _firstString(
      map,
      const [
        'correct_option',
        'correctOption',
        'correct',
        'answer',
        'correct_answer',
      ],
    ).trim().toUpperCase();

    if (correct.length > 1) {
      correct = correct.substring(0, 1);
    }

    final bibleBook = _firstString(
      map,
      const ['bible_book', 'bibleBook', 'book', 'book_name', 'bookName'],
    );

    final chapterStart = _firstInt(
      map,
      const ['chapter_start', 'chapterStart', 'chapter', 'chapter_number'],
    );

    final verseStart = _firstInt(
      map,
      const ['verse_start', 'verseStart', 'verse', 'verse_number'],
    );

    final chapterEnd = _firstInt(
      map,
      const ['chapter_end', 'chapterEnd'],
      fallback: chapterStart,
    );

    final verseEnd = _firstInt(
      map,
      const ['verse_end', 'verseEnd'],
      fallback: verseStart,
    );

    final suppliedReference = _firstString(
      map,
      const [
        'bible_reference',
        'bibleReference',
        'reference',
        'ref',
        'scripture_reference',
        'scriptureReference',
      ],
    );

    final generatedReference = _buildReference(
      book: bibleBook,
      chapterStart: chapterStart,
      verseStart: verseStart,
      chapterEnd: chapterEnd,
      verseEnd: verseEnd,
    );

    return _QuizQuestion(
      uid: id.isEmpty ? 'q_${DateTime.now().microsecondsSinceEpoch}' : id,
      text: _firstString(
        map,
        const ['question', 'question_text', 'questionText', 'title', 'text'],
      ),
      options: options,
      correctOption: correct.isEmpty ? 'A' : correct,
      explanation: _firstString(
        map,
        const ['explanation', 'description', 'review_note'],
      ),
      answerNote: _firstString(
        map,
        const ['answer_note', 'answerNote', 'note', 'answer_description'],
      ),
      bibleReference: suppliedReference.trim().isNotEmpty
          ? suppliedReference
          : generatedReference,
      bibleBook: bibleBook,
      chapterStart: chapterStart,
      verseStart: verseStart,
      chapterEnd: chapterEnd,
      verseEnd: verseEnd,
      studyFocus: _firstString(
        map,
        const ['study_focus', 'studyFocus', 'focus', 'topic'],
      ),
      questionKind: _firstString(
        map,
        const ['question_kind', 'questionKind', 'kind', 'style'],
      ),
      level: _firstInt(map, const ['level', 'level_number', 'levelNumber'],
          fallback: 1),
      points: _firstInt(map, const ['points', 'xp'], fallback: 1).clamp(1, 999),
    );
  }

  static String _buildReference({
    required String book,
    required int chapterStart,
    required int verseStart,
    required int chapterEnd,
    required int verseEnd,
  }) {
    final cleanBook = book.trim();
    if (cleanBook.isEmpty || chapterStart <= 0) return '';

    if (verseStart <= 0) return '$cleanBook $chapterStart';

    final sameEnd = chapterEnd <= 0 ||
        (chapterEnd == chapterStart &&
            (verseEnd <= 0 || verseEnd == verseStart));

    if (sameEnd) return '$cleanBook $chapterStart:$verseStart';

    if (chapterEnd == chapterStart && verseEnd > verseStart) {
      return '$cleanBook $chapterStart:$verseStart-$verseEnd';
    }

    if (chapterEnd > 0 && verseEnd > 0) {
      return '$cleanBook $chapterStart:$verseStart-$chapterEnd:$verseEnd';
    }

    return '$cleanBook $chapterStart:$verseStart';
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is Map || value is Iterable) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static int _firstInt(
    Map<String, dynamic> map,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString().trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }
}

class _QuizOption {
  final String key;
  final String text;

  const _QuizOption({required this.key, required this.text});

  factory _QuizOption.fromApi(Map<String, dynamic> map) {
    return _QuizOption(
      key: _QuizPayloadResolver._firstString(map, const ['key', 'id', 'label'])
          .toUpperCase(),
      text: _QuizPayloadResolver._firstString(
          map, const ['text', 'title', 'value', 'label']),
    );
  }
}

class _QuizPayloadResolver {
  const _QuizPayloadResolver._();

  static _QuizData resolve({
    required String quizKey,
    required Map<String, dynamic> extra,
    required Map<String, dynamic> hubRaw,
  }) {
    final normalizedKey = _normalizeKey(quizKey);
    final extraSource = _asMap(extra['quiz_source']) ??
        _asMap(extra['watch_source']) ??
        _asMap(_asMap(extra['content_intelligence'])?['quiz_source']);

    final action = _asMap(extra['action']);
    final actionSource = _asMap(action?['quiz_source']);
    final hubSource = _findQuizSource(hubRaw, normalizedKey);

    final merged = <String, dynamic>{
      ...?hubSource,
      ...?extraSource,
      ...?actionSource,
      ...extra,
    };

    final key = _firstString(merged, const ['quiz_key', 'key', 'slug', 'id']);
    final safeKey = _normalizeKey(key.isNotEmpty ? key : normalizedKey);
    final title = _firstString(merged, const ['title', 'name', 'label']);
    final subtitle =
        _firstString(merged, const ['subtitle', 'description', 'summary']);
    final type =
        _firstString(merged, const ['quiz_type', 'type', 'content_type']);
    final status = _firstString(merged, const ['status', 'state']);
    final difficulty = _firstString(merged, const ['difficulty', 'level']);
    final imageUrl = _firstString(merged, const [
      'image_url',
      'image',
      'cover_image_url',
      'thumbnail_url',
      'poster_url',
    ]);

    return _QuizData(
      key: safeKey,
      title: title.isNotEmpty ? title : _titleFromKey(safeKey),
      subtitle: subtitle.isNotEmpty
          ? subtitle
          : 'Quiz content is controlled from AppsHub Quiz Center.',
      type: type.isNotEmpty ? type : _typeFromKey(safeKey),
      status: status.isNotEmpty ? status : 'draft',
      difficulty: difficulty.isNotEmpty ? difficulty : 'easy',
      imageUrl: imageUrl,
      questionCount: _firstInt(merged, const [
        'question_count',
        'questions_count',
        'total_questions',
      ]),
      levelCount:
          _firstInt(merged, const ['level_count', 'levels_count'], fallback: 3),
      leaderboardEnabled: _firstBool(
        merged,
        const ['leaderboard_enabled', 'leaderboard'],
        fallback: true,
      ),
    );
  }

  static Map<String, dynamic>? _findQuizSource(
      Map<String, dynamic> raw, String quizKey) {
    Map<String, dynamic>? found;

    void scan(dynamic value) {
      if (found != null || value == null) return;
      if (value is List) {
        for (final item in value) {
          scan(item);
          if (found != null) return;
        }
        return;
      }
      if (value is! Map) return;

      final map = Map<String, dynamic>.from(value.cast<String, dynamic>());
      final source = _asMap(map['quiz_source']) ??
          _asMap(_asMap(map['content_intelligence'])?['quiz_source']) ??
          _asMap(_asMap(map['action'])?['quiz_source']);

      final candidateKey = _normalizeKey(_firstString(
          {...map, ...?source}, const ['quiz_key', 'key', 'slug']));
      if (candidateKey == quizKey) {
        found = {...map, ...?source};
        return;
      }

      for (final child in map.values) {
        scan(child);
        if (found != null) return;
      }
    }

    scan(raw);
    return found;
  }

  static String _normalizeKey(String value) =>
      value.trim().toLowerCase().replaceAll('-', '_');

  static List<_QuizPackSummary> _filterPacksForCategory(
    String quizKey,
    List<_QuizPackSummary> packs,
  ) {
    final key = _normalizeKey(quizKey);
    final playable = packs.where((pack) => pack.isPlayable).toList();

    bool hasAny(String source, List<String> terms) {
      final normalized = _normalizeKey(source);
      return terms.any((term) => normalized.contains(_normalizeKey(term)));
    }

    bool isBookPack(_QuizPackSummary pack) {
      return pack.testament == 'old' || pack.testament == 'new';
    }

    if (key == 'bible_books' || key == 'book_by_book') {
      return playable.where(isBookPack).toList();
    }

    if (key == 'bible_general') {
      return playable.where((pack) {
        final category = pack.category;
        final title = pack.title;
        return hasAny(category, const ['general']) ||
            hasAny(
                title, const ['general bible knowledge', 'general knowledge']);
      }).toList();
    }

    if (key == 'bible_characters') {
      return playable.where((pack) {
        final category = pack.category;
        final title = pack.title;
        return hasAny(category, const ['character', 'characters']) ||
            hasAny(title, const [
              'character',
              'characters',
              'abraham',
              'moses',
              'david',
              'solomon',
              'esther',
              'daniel',
              'paul',
              'peter',
            ]);
      }).toList();
    }

    if (key == 'bible_memory') {
      return playable.where((pack) {
        final category = pack.category;
        final title = pack.title;
        return hasAny(category, const ['memory', 'scripture_memory']) ||
            hasAny(title, const ['memory', 'scripture memory', 'memor']);
      }).toList();
    }

    if (key == 'bible_old_testament') {
      return playable.where((pack) => pack.testament == 'old').toList();
    }

    if (key == 'bible_new_testament') {
      return playable.where((pack) => pack.testament == 'new').toList();
    }

    return playable;
  }

  static _QuizApiSpec _categoryApiSpec(String quizKey) {
    final key = _normalizeKey(quizKey);
    if (key == 'bible_books' || key == 'book_by_book') {
      return const _QuizApiSpec('bible_quiz', 'book_by_book');
    }
    if (key == 'bible_general') {
      return const _QuizApiSpec('bible_quiz', 'general');
    }
    if (key == 'bible_old_testament') {
      return const _QuizApiSpec('bible_quiz', 'old_testament');
    }
    if (key == 'bible_new_testament') {
      return const _QuizApiSpec('bible_quiz', 'new_testament');
    }
    if (key == 'bible_characters') {
      return const _QuizApiSpec('bible_quiz', 'characters');
    }
    if (key == 'bible_memory') {
      return const _QuizApiSpec('bible_quiz', 'scripture_memory');
    }
    if (key == 'sod_quiz' || key == 'sod') {
      return const _QuizApiSpec('sod_quiz', '');
    }
    if (key == 'article_quiz' || key == 'article') {
      return const _QuizApiSpec('article_quiz', '');
    }
    return const _QuizApiSpec('', '');
  }

  static String _categoryTitle(String quizKey) {
    switch (_normalizeKey(quizKey)) {
      case 'bible_general':
        return 'General Bible Knowledge';
      case 'bible_old_testament':
        return 'Old Testament Quiz Packs';
      case 'bible_new_testament':
        return 'New Testament Quiz Packs';
      case 'bible_books':
      case 'book_by_book':
        return 'Choose Bible Book Quiz';
      case 'bible_characters':
        return 'Bible Character Quiz Packs';
      case 'bible_memory':
        return 'Scripture Memory Quiz Packs';
    }
    return _titleFromKey(_normalizeKey(quizKey));
  }

  static String _categorySubtitle(String quizKey) {
    switch (_normalizeKey(quizKey)) {
      case 'bible_books':
      case 'book_by_book':
        return 'Select the exact book you want to study and play. New books appear here when published from AppsHub.';
      case 'bible_general':
        return 'Select a general Bible knowledge quiz pack.';
      case 'bible_old_testament':
        return 'Select an Old Testament quiz group or pack.';
      case 'bible_new_testament':
        return 'Select a New Testament quiz group or pack.';
      case 'bible_characters':
        return 'Select a Bible character study quiz.';
      case 'bible_memory':
        return 'Select a scripture memory quiz pack.';
    }
    return 'Select a quiz pack to view available levels.';
  }

  static String _titleFromKey(String key) {
    if (key == 'sod_quiz') return 'SOD Quiz';
    if (key == 'bible_quiz') return 'Bible Quiz';
    final words = key
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty);
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static String _typeFromKey(String key) {
    if (key.contains('sod')) return 'sod';
    if (key.contains('bible')) return 'bible';
    if (key.contains('article')) return 'article';
    return 'general';
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map)
      return Map<String, dynamic>.from(value.cast<String, dynamic>());
    return null;
  }

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static int _firstInt(Map<String, dynamic> map, List<String> keys,
      {int fallback = 0}) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse((value ?? '').toString().trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static bool _firstBool(Map<String, dynamic> map, List<String> keys,
      {bool fallback = false}) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      final text = (value ?? '').toString().trim().toLowerCase();
      if (['1', 'true', 'yes', 'enabled', 'ready'].contains(text)) return true;
      if (['0', 'false', 'no', 'disabled'].contains(text)) return false;
    }
    return fallback;
  }
}

class _BibleBookTestament {
  static const Set<String> _old = {
    'genesis',
    'exodus',
    'leviticus',
    'numbers',
    'deuteronomy',
    'joshua',
    'judges',
    'ruth',
    '1 samuel',
    '2 samuel',
    '1 kings',
    '2 kings',
    '1 chronicles',
    '2 chronicles',
    'ezra',
    'nehemiah',
    'esther',
    'job',
    'psalms',
    'proverbs',
    'ecclesiastes',
    'song of solomon',
    'isaiah',
    'jeremiah',
    'lamentations',
    'ezekiel',
    'daniel',
    'hosea',
    'joel',
    'amos',
    'obadiah',
    'jonah',
    'micah',
    'nahum',
    'habakkuk',
    'zephaniah',
    'haggai',
    'zechariah',
    'malachi',
  };

  static const Set<String> _new = {
    'matthew',
    'mark',
    'luke',
    'john',
    'acts',
    'romans',
    '1 corinthians',
    '2 corinthians',
    'galatians',
    'ephesians',
    'philippians',
    'colossians',
    '1 thessalonians',
    '2 thessalonians',
    '1 timothy',
    '2 timothy',
    'titus',
    'philemon',
    'hebrews',
    'james',
    '1 peter',
    '2 peter',
    '1 john',
    '2 john',
    '3 john',
    'jude',
    'revelation',
  };

  static String fromTitle(String title) {
    var normalized = title
        .toLowerCase()
        .replaceAll('quiz', '')
        .replaceAll('book of', '')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    normalized = normalized
        .replaceFirst('first ', '1 ')
        .replaceFirst('second ', '2 ')
        .replaceFirst('third ', '3 ');

    if (_old.contains(normalized)) return 'old';
    if (_new.contains(normalized)) return 'new';
    return 'unknown';
  }
}

class _QuizColors {
  final Color scaffold;
  final Color card;
  final Color border;
  final Color text;
  final Color subText;
  final Color meta;
  final Color accent;
  final Color success;
  final Color warning;
  final Color heroText;
  final Color heroSubText;
  final Color heroIcon;
  final Color heroOverlayTop;
  final Color heroOverlayBottom;
  final Color pill;
  final Color pillBorder;
  final Color pillText;
  final List<Color> heroGradient;
  final List<Color> iconGradient;

  const _QuizColors({
    required this.scaffold,
    required this.card,
    required this.border,
    required this.text,
    required this.subText,
    required this.meta,
    required this.accent,
    required this.success,
    required this.warning,
    required this.heroText,
    required this.heroSubText,
    required this.heroIcon,
    required this.heroOverlayTop,
    required this.heroOverlayBottom,
    required this.pill,
    required this.pillBorder,
    required this.pillText,
    required this.heroGradient,
    required this.iconGradient,
  });

  factory _QuizColors.fromLightMode(bool isLight) {
    if (isLight) {
      return const _QuizColors(
        scaffold: Color(0xFFF6F7FB),
        card: Color(0xFFFFFFFF),
        border: Color(0xFFE2E8F0),
        text: Color(0xFF111827),
        subText: Color(0xFF475569),
        meta: Color(0xFF64748B),
        accent: Color(0xFF7C3AED),
        success: Color(0xFF059669),
        warning: Color(0xFFD97706),
        heroText: Colors.white,
        heroSubText: Color(0xFFE0F2FE),
        heroIcon: Colors.white,
        heroOverlayTop: Color(0xBB111827),
        heroOverlayBottom: Color(0xDD312E81),
        pill: Color(0x33FFFFFF),
        pillBorder: Color(0x55FFFFFF),
        pillText: Colors.white,
        heroGradient: [Color(0xFF3B0764), Color(0xFF0E7490)],
        iconGradient: [Color(0xFF7C3AED), Color(0xFF2563EB)],
      );
    }

    return const _QuizColors(
      scaffold: Color(0xFF070A18),
      card: Color(0xFF0D1228),
      border: Color(0xFF242A44),
      text: Color(0xFFF8FAFC),
      subText: Color(0xFFCBD5E1),
      meta: Color(0xFF94A3B8),
      accent: Color(0xFFA855F7),
      success: Color(0xFF22C55E),
      warning: Color(0xFFF59E0B),
      heroText: Colors.white,
      heroSubText: Color(0xFFDDE7FF),
      heroIcon: Colors.white,
      heroOverlayTop: Color(0x77000000),
      heroOverlayBottom: Color(0xE0060A18),
      pill: Color(0x28FFFFFF),
      pillBorder: Color(0x2FFFFFFF),
      pillText: Colors.white,
      heroGradient: [Color(0xFF321270), Color(0xFF073E6B)],
      iconGradient: [Color(0xFF7C3AED), Color(0xFF2563EB)],
    );
  }
}

class _QuizSoundController {
  AudioPlayer? _effectPlayer;
  AudioPlayer? _musicPlayer;
  bool _ready = false;
  bool _effectsEnabled = true;
  bool _musicEnabled = true;
  bool _musicPlaying = false;

  Future<void> init() async {
    try {
      _effectPlayer = AudioPlayer(playerId: 'quiz_effects');
      _musicPlayer = AudioPlayer(playerId: 'quiz_music');
      await _musicPlayer?.setReleaseMode(ReleaseMode.loop);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> setEffectsEnabled(bool enabled) async {
    _effectsEnabled = enabled;
    if (!enabled) {
      try {
        await _effectPlayer?.stop();
      } catch (_) {}
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    if (!enabled) {
      await stopMusic();
    }
  }

  Future<void> startMusic() async {
    if (!_ready || !_musicEnabled || _musicPlayer == null || _musicPlaying) {
      return;
    }
    try {
      await _musicPlayer!.play(
        AssetSource('audio/quiz_engine/quiz_adventure_loop.wav'),
        volume: 0.20,
      );
      _musicPlaying = true;
    } catch (_) {
      _musicPlaying = false;
    }
  }

  Future<void> stopMusic() async {
    try {
      await _musicPlayer?.stop();
    } catch (_) {
      // Ignore stop errors.
    }
    _musicPlaying = false;
  }

  Future<void> stage() async {
    await _play('audio/quiz_engine/quiz_start.wav', volume: 0.48);
    await HapticFeedback.selectionClick();
  }

  Future<void> correct(int streak) async {
    await _play(
      streak >= 3
          ? 'audio/quiz_engine/quiz_combo.wav'
          : 'audio/quiz_engine/quiz_correct.wav',
      volume: 0.55,
    );
    await HapticFeedback.mediumImpact();
  }

  Future<void> wrong() async {
    await _play('audio/quiz_engine/quiz_wrong.wav', volume: 0.42);
    await HapticFeedback.lightImpact();
  }

  Future<void> result(int correct, int total) async {
    await stopMusic();
    final passed = total > 0 && correct / total >= 0.5;
    await _play(
      passed
          ? 'audio/quiz_engine/quiz_level_complete.wav'
          : 'audio/quiz_engine/quiz_retry.wav',
      volume: 0.58,
    );
    await HapticFeedback.heavyImpact();
  }

  Future<void> _play(String asset, {double volume = 0.55}) async {
    if (!_ready || !_effectsEnabled || _effectPlayer == null) return;

    try {
      await _effectPlayer!.stop();
      await _effectPlayer!.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // Sound should never break the quiz experience.
    }
  }

  Future<void> dispose() async {
    try {
      await _effectPlayer?.dispose();
      await _musicPlayer?.dispose();
    } catch (_) {
      // Ignore dispose errors.
    }
  }
}
