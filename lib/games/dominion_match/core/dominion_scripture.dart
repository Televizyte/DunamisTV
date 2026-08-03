import 'dart:math';

import 'dominion_level.dart';

class DominionScripture {
  final String title;
  final String text;
  final String reference;
  final String tone;

  const DominionScripture({
    required this.title,
    required this.text,
    required this.reference,
    required this.tone,
  });

  String get displayText => '“$text” — $reference';
  String get notesTitle => 'Dominion Match Scripture — $reference';
  String get notesBody => '$text\n\n$reference\n\nSaved from Dominion Match.';
  String get quoteText => text;

  Map<String, dynamic> toBiblePayload({String source = 'dominion_match'}) {
    return <String, dynamic>{
      'source': source,
      'sourceType': source,
      'source_type': source,
      'sourceId': reference,
      'source_id': reference,
      'ref': reference,
      'reference': reference,
      'bible_reference': reference,
      'bibleReference': reference,
      'verseText': text,
      'verse_text': text,
      'bibleVerseText': text,
      'bible_verse_text': text,
      'scriptureText': text,
      'scripture_text': text,
      'text': text,
    };
  }

  Map<String, dynamic> toNotesPayload({String source = 'dominion_match'}) {
    return <String, dynamic>{
      'source': source,
      'sourceType': source,
      'source_type': source,
      'sourceId': reference,
      'source_id': reference,
      'title': notesTitle,
      'prefill': notesBody,
      'reference': reference,
      'ref': reference,
      'text': text,
      'quote': text,
      'author': reference,
      'note_title': notesTitle,
      'note_body': notesBody,
      'bible_reference': reference,
      'insertScripture': <String, dynamic>{
        'ref': reference,
        'reference': reference,
        'verse': text,
      },
    };
  }

  Map<String, dynamic> toQuotePayload({String source = 'dominion_match'}) {
    return <String, dynamic>{
      'source': source,
      'sourceType': source,
      'source_type': source,
      'sourceId': reference,
      'source_id': reference,
      'reference': reference,
      'ref': reference,
      'text': text,
      'quote': text,
      'quote_text': text,
      'main_quote': text,
      'author': reference,
      'bible_reference': reference,
      'designData': <String, dynamic>{
        'quote': text,
        'text': text,
        'quote_text': text,
        'author': reference,
        'source_type': source,
        'source_id': reference,
        'reference': reference,
      },
    };
  }

  Map<String, dynamic> toToolPayload({String source = 'dominion_match'}) {
    return <String, dynamic>{
      ...toNotesPayload(source: source),
      'verseText': text,
      'verse_text': text,
      'bibleVerseText': text,
      'bible_verse_text': text,
      'scriptureText': text,
      'scripture_text': text,
      'designData': <String, dynamic>{
        'quote': text,
        'text': text,
        'quote_text': text,
        'author': reference,
        'source_type': source,
        'source_id': reference,
        'reference': reference,
      },
    };
  }
}

enum DominionScriptureMoment {
  opening,
  victory,
  failure,
  lowTime,
  combo,
  power,
  unlock,
}

class DominionScriptureBank {
  DominionScriptureBank._();

  static final Random _random = Random();
  static final List<String> _recentReferences = <String>[];
  static int _counter = 0;
  static const int _recentLimit = 8;

  static DominionScripture opening(DominionLevel level) {
    return _pick(_pool(level, DominionScriptureMoment.opening), level.stage);
  }

  static DominionScripture victory(DominionLevel level) {
    return _pick(_pool(level, DominionScriptureMoment.victory), level.stage);
  }

  static DominionScripture failure(DominionLevel level) {
    return _pick(_pool(level, DominionScriptureMoment.failure), level.stage);
  }

  static DominionScripture lowTime(DominionLevel level) {
    return _pick(_pool(level, DominionScriptureMoment.lowTime), level.stage);
  }

  static DominionScripture combo(DominionLevel level) {
    return _pick(_pool(level, DominionScriptureMoment.combo), level.stage);
  }

  static DominionScripture power(DominionLevel level) {
    return _pick(_pool(level, DominionScriptureMoment.power), level.stage);
  }

  static DominionScripture unlock(DominionLevel level) {
    return _pick(_pool(level, DominionScriptureMoment.unlock), level.stage);
  }

  static DominionScripture _pick(List<DominionScripture> pool, int stage) {
    if (pool.isEmpty) return _generalEncouragement.first;
    _counter++;

    final available = pool
        .where((item) => !_recentReferences.contains(item.reference))
        .toList(growable: false);
    final source = available.isEmpty ? pool : available;
    final seed = DateTime.now().millisecondsSinceEpoch + stage + _counter;
    final index = (seed + _random.nextInt(100000)) % source.length;
    final picked = source[index];

    _recentReferences.add(picked.reference);
    if (_recentReferences.length > _recentLimit) {
      _recentReferences.removeAt(0);
    }

    return picked;
  }

  static List<DominionScripture> _pool(
    DominionLevel level,
    DominionScriptureMoment moment,
  ) {
    final worldPool = _worldPool(level.worldType, moment);
    final sharedPool = _sharedPool(moment);
    return <DominionScripture>[...worldPool, ...sharedPool];
  }

  static List<DominionScripture> _worldPool(
    DominionWorldType world,
    DominionScriptureMoment moment,
  ) {
    switch (world) {
      case DominionWorldType.garden:
        return switch (moment) {
          DominionScriptureMoment.opening => const <DominionScripture>[
              DominionScripture(
                title: 'Start with courage',
                text:
                    'Be strong and of a good courage; be not afraid, neither be thou dismayed.',
                reference: 'Joshua 1:9',
                tone: 'encouragement',
              ),
              DominionScripture(
                title: 'Begin with light',
                text:
                    'The LORD is my light and my salvation; whom shall I fear?',
                reference: 'Psalms 27:1',
                tone: 'confidence',
              ),
              DominionScripture(
                title: 'Grace for the step',
                text:
                    'I can do all things through Christ which strengtheneth me.',
                reference: 'Philippians 4:13',
                tone: 'strength',
              ),
              DominionScripture(
                title: 'Peace for the mind',
                text:
                    'Thou wilt keep him in perfect peace, whose mind is stayed on thee.',
                reference: 'Isaiah 26:3',
                tone: 'peace',
              ),
            ],
          DominionScriptureMoment.victory => const <DominionScripture>[
              DominionScripture(
                title: 'Good beginning',
                text:
                    'The path of the just is as the shining light, that shineth more and more unto the perfect day.',
                reference: 'Proverbs 4:18',
                tone: 'growth',
              ),
              DominionScripture(
                title: 'Seed is growing',
                text:
                    'Being confident of this very thing, that he which hath begun a good work in you will perform it.',
                reference: 'Philippians 1:6',
                tone: 'growth',
              ),
            ],
          _ => const <DominionScripture>[],
        };
      case DominionWorldType.rescue:
        return switch (moment) {
          DominionScriptureMoment.opening => const <DominionScripture>[
              DominionScripture(
                title: 'Run with patience',
                text:
                    'Let us run with patience the race that is set before us.',
                reference: 'Hebrews 12:1',
                tone: 'focus',
              ),
              DominionScripture(
                title: 'Steady your heart',
                text:
                    'Commit thy works unto the LORD, and thy thoughts shall be established.',
                reference: 'Proverbs 16:3',
                tone: 'stability',
              ),
            ],
          DominionScriptureMoment.lowTime => const <DominionScripture>[
              DominionScripture(
                title: 'Help is close',
                text:
                    'God is our refuge and strength, a very present help in trouble.',
                reference: 'Psalms 46:1',
                tone: 'help',
              ),
              DominionScripture(
                title: 'Do not fear the pressure',
                text:
                    'Fear thou not; for I am with thee: be not dismayed; for I am thy God.',
                reference: 'Isaiah 41:10',
                tone: 'comfort',
              ),
            ],
          _ => const <DominionScripture>[],
        };
      case DominionWorldType.hazard:
        return switch (moment) {
          DominionScriptureMoment.opening => const <DominionScripture>[
              DominionScripture(
                title: 'Strength for battle',
                text:
                    'Through God we shall do valiantly: for he it is that shall tread down our enemies.',
                reference: 'Psalms 60:12',
                tone: 'dominion',
              ),
              DominionScripture(
                title: 'Stand through the storm',
                text:
                    'When thou passest through the waters, I will be with thee.',
                reference: 'Isaiah 43:2',
                tone: 'boldness',
              ),
            ],
          DominionScriptureMoment.power => const <DominionScripture>[
              DominionScripture(
                title: 'Power released',
                text:
                    'The people that do know their God shall be strong, and do exploits.',
                reference: 'Daniel 11:32',
                tone: 'power',
              ),
            ],
          _ => const <DominionScripture>[],
        };
      case DominionWorldType.stronghold:
        return switch (moment) {
          DominionScriptureMoment.opening => const <DominionScripture>[
              DominionScripture(
                title: 'Break through',
                text:
                    'For the weapons of our warfare are not carnal, but mighty through God to the pulling down of strong holds.',
                reference: '2 Corinthians 10:4',
                tone: 'warfare',
              ),
              DominionScripture(
                title: 'Stand strong',
                text: 'Having done all, to stand.',
                reference: 'Ephesians 6:13',
                tone: 'resilience',
              ),
            ],
          _ => const <DominionScripture>[],
        };
      case DominionWorldType.crown:
        return switch (moment) {
          DominionScriptureMoment.opening => const <DominionScripture>[
              DominionScripture(
                title: 'Royal trial',
                text:
                    'Blessed is the man that endureth temptation: for when he is tried, he shall receive the crown of life.',
                reference: 'James 1:12',
                tone: 'crown',
              ),
              DominionScripture(
                title: 'Press for the prize',
                text:
                    'I press toward the mark for the prize of the high calling of God in Christ Jesus.',
                reference: 'Philippians 3:14',
                tone: 'excellence',
              ),
            ],
          DominionScriptureMoment.victory => const <DominionScripture>[
              DominionScripture(
                title: 'Crown of reward',
                text:
                    'I have fought a good fight, I have finished my course, I have kept the faith.',
                reference: '2 Timothy 4:7',
                tone: 'reward',
              ),
            ],
          _ => const <DominionScripture>[],
        };
      case DominionWorldType.endless:
        return const <DominionScripture>[
          DominionScripture(
            title: 'Keep going',
            text: 'The joy of the LORD is your strength.',
            reference: 'Nehemiah 8:10',
            tone: 'strength',
          ),
          DominionScripture(
            title: 'Do not faint',
            text:
                'And let us not be weary in well doing: for in due season we shall reap, if we faint not.',
            reference: 'Galatians 6:9',
            tone: 'endurance',
          ),
        ];
    }
  }

  static List<DominionScripture> _sharedPool(DominionScriptureMoment moment) {
    return switch (moment) {
      DominionScriptureMoment.victory => const <DominionScripture>[
          DominionScripture(
            title: 'Victory unlocked',
            text:
                'But thanks be to God, which giveth us the victory through our Lord Jesus Christ.',
            reference: '1 Corinthians 15:57',
            tone: 'victory',
          ),
          DominionScripture(
            title: 'More than conqueror',
            text:
                'In all these things we are more than conquerors through him that loved us.',
            reference: 'Romans 8:37',
            tone: 'dominion',
          ),
          DominionScripture(
            title: 'He causes triumph',
            text:
                'Now thanks be unto God, which always causeth us to triumph in Christ.',
            reference: '2 Corinthians 2:14',
            tone: 'triumph',
          ),
          DominionScripture(
            title: 'The work is rewarded',
            text: 'For ye shall have reward for your labour.',
            reference: '2 Chronicles 15:7',
            tone: 'reward',
          ),
        ],
      DominionScriptureMoment.failure => const <DominionScripture>[
          DominionScripture(
            title: 'Rise again',
            text: 'For a just man falleth seven times, and riseth up again.',
            reference: 'Proverbs 24:16',
            tone: 'continue',
          ),
          DominionScripture(
            title: 'Do not give up',
            text:
                'And let us not be weary in well doing: for in due season we shall reap, if we faint not.',
            reference: 'Galatians 6:9',
            tone: 'endurance',
          ),
          DominionScripture(
            title: 'Strength returns',
            text: 'They that wait upon the LORD shall renew their strength.',
            reference: 'Isaiah 40:31',
            tone: 'renewal',
          ),
          DominionScripture(
            title: 'Continue in prayer',
            text:
                'Rejoicing in hope; patient in tribulation; continuing instant in prayer.',
            reference: 'Romans 12:12',
            tone: 'resilience',
          ),
          DominionScripture(
            title: 'Try again with hope',
            text:
                'Weeping may endure for a night, but joy cometh in the morning.',
            reference: 'Psalms 30:5',
            tone: 'hope',
          ),
        ],
      DominionScriptureMoment.combo => const <DominionScripture>[
          DominionScripture(
            title: 'Keep pressing',
            text:
                'Be ye stedfast, unmoveable, always abounding in the work of the Lord.',
            reference: '1 Corinthians 15:58',
            tone: 'discipline',
          ),
          DominionScripture(
            title: 'Do it heartily',
            text:
                'And whatsoever ye do, do it heartily, as to the Lord, and not unto men.',
            reference: 'Colossians 3:23',
            tone: 'excellence',
          ),
        ],
      DominionScriptureMoment.unlock => const <DominionScripture>[
          DominionScripture(
            title: 'New level unlocked',
            text:
                'The LORD shall increase you more and more, you and your children.',
            reference: 'Psalms 115:14',
            tone: 'increase',
          ),
        ],
      _ => const <DominionScripture>[],
    };
  }

  static const List<DominionScripture> _generalEncouragement =
      <DominionScripture>[
    DominionScripture(
      title: 'Keep going',
      text: 'The joy of the LORD is your strength.',
      reference: 'Nehemiah 8:10',
      tone: 'strength',
    ),
  ];
}
