import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/bible/models/bible_models.dart';
import '../../../features/bible/state/bible_store.dart';

class BibleChaptersScreen extends StatefulWidget {
  const BibleChaptersScreen({super.key});

  @override
  State<BibleChaptersScreen> createState() => _BibleChaptersScreenState();
}

class _BibleChaptersScreenState extends State<BibleChaptersScreen> {
  static const _topGradient = LinearGradient(
    colors: <Color>[
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  final BibleStore _store = BibleStore.instance;
  String _bookName = '';
  bool _routeExtraHandled = false;

  @override
  void initState() {
    super.initState();
    _bootStore();
  }

  Future<void> _bootStore() async {
    await _store.init();
    if (!mounted) return;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_routeExtraHandled) return;
    _routeExtraHandled = true;

    final extra = GoRouterState.of(context).extra;
    if (extra is Map && extra['book'] != null) {
      _bookName = extra['book'].toString();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openChapter(int chapter) {
    context.push(
      '/tools/bible/reader',
      extra: <String, dynamic>{
        'book': _bookName,
        'chapter': chapter,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _store.isLightTheme;
    final BibleBook? book = _store.findBook(_bookName);

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
                Expanded(
                  child: Text(
                    book?.name ?? 'Chapters',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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
                    isLight ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
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
          : book == null
              ? Center(
                  child: Text(
                    'Book not found',
                    style: TextStyle(
                      color:
                          isLight ? const Color(0xFF1E1B16) : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                  child: GridView.builder(
                    itemCount: book.chapterCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, index) {
                      final chapter = index + 1;
                      return _ChapterTile(
                        isLight: isLight,
                        chapter: chapter,
                        onTap: () => _openChapter(chapter),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.isLight,
    required this.chapter,
    required this.onTap,
  });

  final bool isLight;
  final int chapter;
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE6D8C3)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Center(
            child: Text(
              '$chapter',
              style: TextStyle(
                color: isLight ? const Color(0xFF1E1B16) : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
