import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/gradient_page_background.dart';

class DailyScriptureScreen extends StatelessWidget {
  const DailyScriptureScreen({super.key});

  static const _topGradient = LinearGradient(
    colors: [
      Color(0xFF1A1F5A),
      Color(0xFF5B1FA8),
      Color(0xFFB70E7C),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // v1 demo content (later will come from DXM FireDrive)
  static const String _ref = 'Jeremiah 29:11';
  static const String _verse =
      '“For I know the thoughts that I think toward you, saith the LORD…”';
  static const String _note =
      'Short note: God is personally involved with you today — this scripture is His reminder that you are not alone.';

  @override
  Widget build(BuildContext context) {
    final shareText = 'Today’s Scripture ($_ref)\n\n$_verse\n\n$_note';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Container(
          decoration: const BoxDecoration(gradient: _topGradient),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 6),
                const Text(
                  "Today's Scripture",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: GradientPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          children: [
            Text(
              "Today's Scripture",
              style: TextStyle(
                color: Colors.white.withOpacity(0.92),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'A verse of encouragement from the Bible.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Lilac card like your screenshot
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE9DCFF), // lilac
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                    color: Colors.black.withOpacity(0.25),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _verse,
                      style: const TextStyle(
                        color: Color(0xFF141225), // dark text
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _note,
                      style: const TextStyle(
                        color: Color(0xFF2B2540),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Actions row
                    Row(
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1A46FF),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                          ),
                          onPressed: () => context.push(
                            '/tools/bible',
                            extra: {
                              'ref': _ref,
                              'verse': _verse,
                              'note': _note,
                            },
                          ),
                          child: const Text(
                            'Read full Bible',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1A46FF),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                          ),
                          onPressed: () => context.push(
                            '/tools/quote',
                            extra: {
                              'prefill': shareText,
                              'source': 'daily-scripture',
                            },
                          ),
                          child: const Text(
                            'Open in Quote Creator',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Share',
                          onPressed: () => Share.share(shareText),
                          icon: const Icon(Icons.share_rounded,
                              color: Color(0xFF141225)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
