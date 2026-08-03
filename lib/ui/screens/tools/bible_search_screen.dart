import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/bible/models/bible_models.dart';
import '../../../features/bible/state/bible_store.dart';

class BibleSearchScreen extends StatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  State<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends State<BibleSearchScreen> {
  static const _topGradient = LinearGradient(
    colors: <Color>[
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final BibleStore _store = BibleStore();
  final TextEditingController _controller = TextEditingController();

  List<BibleSearchResult> _results = <BibleSearchResult>[];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map && extra['query'] != null) {
      _controller.text = extra['query'].toString();
    }

    await _store.init();
    await _runSearch();

    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _store.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _controller.text.trim();

    if (!mounted) return;
    setState(() {
      _searching = true;
    });

    final results = await _store.search(query);

    if (!mounted) return;

    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _openResult(BibleVerse verse) {
    context.push(
      '/tools/bible/reader',
      extra: <String, dynamic>{
        'book': verse.book,
        'chapter': verse.chapter,
        'verse': verse.verse,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _store.isLightTheme;

    return Scaffold(
      backgroundColor:
          isLight ? const Color(0xFFF7F1E6) : const Color(0xFF070B18),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(gradient: _topGradient),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Bible Search',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isLight ? 'Dark mode' : 'Light mode',
                  onPressed: () async {
                    await _store.toggleReaderTheme();
                    if (!mounted) return;
                    setState(() {});
                  },
                  icon: Icon(
                    isLight
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
      body: _store.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                            color: isLight
                                ? const Color(0xFF1E1B16)
                                : Colors.white,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _runSearch(),
                          decoration: InputDecoration(
                            hintText: 'Search by reference or keyword',
                            hintStyle: TextStyle(
                              color: isLight
                                  ? const Color(0xFF8A7C68)
                                  : Colors.white.withOpacity(0.45),
                            ),
                            filled: true,
                            fillColor: isLight
                                ? const Color(0xFFF2E8D8)
                                : const Color(0xFF151C3A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _runSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2C96),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Icon(Icons.search_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _searching
                      ? const Center(child: CircularProgressIndicator())
                      : _results.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _controller.text.trim().isEmpty
                                      ? 'Enter a reference or a word to search the Bible.'
                                      : 'No matching verses found.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isLight
                                        ? const Color(0xFF5F5648)
                                        : Colors.white.withOpacity(0.74),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 0, 14, 18),
                              itemCount: _results.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final result = _results[index];
                                return _SearchResultTile(
                                  isLight: isLight,
                                  result: result,
                                  onTap: () => _openResult(result.verse),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.isLight,
    required this.result,
    required this.onTap,
  });

  final bool isLight;
  final BibleSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isLight ? const Color(0xFFFFFBF4) : const Color(0xFF0E1430),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE6D8C3)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                result.verse.reference,
                style: TextStyle(
                  color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.verse.text,
                style: TextStyle(
                  color: isLight
                      ? const Color(0xFF4C453A)
                      : Colors.white.withOpacity(0.82),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
