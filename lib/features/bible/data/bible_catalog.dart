const String bibleIndexPath = 'assets/bible/index.json';

String getBookAssetPath(String file) {
  return 'assets/bible/books/$file';
}

String canonicalizeBibleBookName(String input) {
  final normalized = _normalizeBibleKey(input);

  const aliases = <String, String>{
    // Old Testament
    'genesis': 'Genesis',
    'gen': 'Genesis',

    'exodus': 'Exodus',
    'exo': 'Exodus',
    'exod': 'Exodus',
    'ex': 'Exodus',

    'leviticus': 'Leviticus',
    'lev': 'Leviticus',

    'numbers': 'Numbers',
    'num': 'Numbers',
    'nm': 'Numbers',

    'deuteronomy': 'Deuteronomy',
    'deut': 'Deuteronomy',
    'dt': 'Deuteronomy',

    'joshua': 'Joshua',
    'josh': 'Joshua',

    'judges': 'Judges',
    'judg': 'Judges',
    'jdg': 'Judges',
    'jg': 'Judges',

    'ruth': 'Ruth',
    'rth': 'Ruth',

    '1samuel': '1 Samuel',
    '1sam': '1 Samuel',
    '1sa': '1 Samuel',
    'i samuel': '1 Samuel',
    'i sam': '1 Samuel',
    'first samuel': '1 Samuel',

    '2samuel': '2 Samuel',
    '2sam': '2 Samuel',
    '2sa': '2 Samuel',
    'ii samuel': '2 Samuel',
    'ii sam': '2 Samuel',
    'second samuel': '2 Samuel',

    '1kings': '1 Kings',
    '1kgs': '1 Kings',
    '1ki': '1 Kings',
    'i kings': '1 Kings',
    'first kings': '1 Kings',

    '2kings': '2 Kings',
    '2kgs': '2 Kings',
    '2ki': '2 Kings',
    'ii kings': '2 Kings',
    'second kings': '2 Kings',

    '1chronicles': '1 Chronicles',
    '1chr': '1 Chronicles',
    '1ch': '1 Chronicles',
    'i chronicles': '1 Chronicles',
    'first chronicles': '1 Chronicles',

    '2chronicles': '2 Chronicles',
    '2chr': '2 Chronicles',
    '2ch': '2 Chronicles',
    'ii chronicles': '2 Chronicles',
    'second chronicles': '2 Chronicles',

    'ezra': 'Ezra',
    'ezr': 'Ezra',

    'nehemiah': 'Nehemiah',
    'neh': 'Nehemiah',

    'esther': 'Esther',
    'est': 'Esther',

    'job': 'Job',

    'psalms': 'Psalms',
    'psalm': 'Psalms',
    'ps': 'Psalms',
    'psa': 'Psalms',
    'pslm': 'Psalms',

    'proverbs': 'Proverbs',
    'prov': 'Proverbs',
    'prv': 'Proverbs',
    'pro': 'Proverbs',

    'ecclesiastes': 'Ecclesiastes',
    'eccl': 'Ecclesiastes',
    'ecc': 'Ecclesiastes',

    'songofsolomon': 'Song of Solomon',
    'song solomon': 'Song of Solomon',
    'song': 'Song of Solomon',
    'songofsongs': 'Song of Solomon',
    'songs': 'Song of Solomon',
    'sos': 'Song of Solomon',
    'canticles': 'Song of Solomon',

    'isaiah': 'Isaiah',
    'isa': 'Isaiah',

    'jeremiah': 'Jeremiah',
    'jer': 'Jeremiah',

    'lamentations': 'Lamentations',
    'lam': 'Lamentations',

    'ezekiel': 'Ezekiel',
    'ezek': 'Ezekiel',
    'eze': 'Ezekiel',

    'daniel': 'Daniel',
    'dan': 'Daniel',

    'hosea': 'Hosea',
    'hos': 'Hosea',

    'joel': 'Joel',
    'jl': 'Joel',

    'amos': 'Amos',
    'am': 'Amos',

    'obadiah': 'Obadiah',
    'obad': 'Obadiah',
    'ob': 'Obadiah',

    'jonah': 'Jonah',
    'jon': 'Jonah',

    'micah': 'Micah',
    'mic': 'Micah',

    'nahum': 'Nahum',
    'nah': 'Nahum',

    'habakkuk': 'Habakkuk',
    'hab': 'Habakkuk',

    'zephaniah': 'Zephaniah',
    'zeph': 'Zephaniah',
    'zep': 'Zephaniah',

    'haggai': 'Haggai',
    'hag': 'Haggai',

    'zechariah': 'Zechariah',
    'zech': 'Zechariah',
    'zec': 'Zechariah',

    'malachi': 'Malachi',
    'mal': 'Malachi',

    // New Testament
    'matthew': 'Matthew',
    'matt': 'Matthew',
    'mt': 'Matthew',

    'mark': 'Mark',
    'mrk': 'Mark',
    'mk': 'Mark',
    'mr': 'Mark',

    'luke': 'Luke',
    'luk': 'Luke',
    'lk': 'Luke',

    'john': 'John',
    'jn': 'John',
    'jhn': 'John',

    'acts': 'Acts',
    'act': 'Acts',

    'romans': 'Romans',
    'rom': 'Romans',
    'ro': 'Romans',

    '1corinthians': '1 Corinthians',
    '1cor': '1 Corinthians',
    '1co': '1 Corinthians',
    'i corinthians': '1 Corinthians',
    'i cor': '1 Corinthians',
    'first corinthians': '1 Corinthians',

    '2corinthians': '2 Corinthians',
    '2cor': '2 Corinthians',
    '2co': '2 Corinthians',
    'ii corinthians': '2 Corinthians',
    'ii cor': '2 Corinthians',
    'second corinthians': '2 Corinthians',

    'galatians': 'Galatians',
    'gal': 'Galatians',

    'ephesians': 'Ephesians',
    'eph': 'Ephesians',

    'philippians': 'Philippians',
    'phil': 'Philippians',
    'php': 'Philippians',
    'philip': 'Philippians',

    'colossians': 'Colossians',
    'col': 'Colossians',

    '1thessalonians': '1 Thessalonians',
    '1thess': '1 Thessalonians',
    '1thes': '1 Thessalonians',
    'i thessalonians': '1 Thessalonians',
    'i thess': '1 Thessalonians',
    'first thessalonians': '1 Thessalonians',

    '2thessalonians': '2 Thessalonians',
    '2thess': '2 Thessalonians',
    '2thes': '2 Thessalonians',
    'ii thessalonians': '2 Thessalonians',
    'ii thess': '2 Thessalonians',
    'second thessalonians': '2 Thessalonians',

    '1timothy': '1 Timothy',
    '1tim': '1 Timothy',
    '1ti': '1 Timothy',
    'i timothy': '1 Timothy',
    'i tim': '1 Timothy',
    'first timothy': '1 Timothy',

    '2timothy': '2 Timothy',
    '2tim': '2 Timothy',
    '2ti': '2 Timothy',
    'ii timothy': '2 Timothy',
    'ii tim': '2 Timothy',
    'second timothy': '2 Timothy',

    'titus': 'Titus',
    'tit': 'Titus',

    'philemon': 'Philemon',
    'phlm': 'Philemon',
    'phm': 'Philemon',

    'hebrews': 'Hebrews',
    'heb': 'Hebrews',

    'james': 'James',
    'jas': 'James',
    'jam': 'James',

    '1peter': '1 Peter',
    '1pet': '1 Peter',
    '1pe': '1 Peter',
    'i peter': '1 Peter',
    'i pet': '1 Peter',
    'first peter': '1 Peter',

    '2peter': '2 Peter',
    '2pet': '2 Peter',
    '2pe': '2 Peter',
    'ii peter': '2 Peter',
    'ii pet': '2 Peter',
    'second peter': '2 Peter',

    '1john': '1 John',
    '1jn': '1 John',
    '1jhn': '1 John',
    'i john': '1 John',
    'first john': '1 John',

    '2john': '2 John',
    '2jn': '2 John',
    '2jhn': '2 John',
    'ii john': '2 John',
    'second john': '2 John',

    '3john': '3 John',
    '3jn': '3 John',
    '3jhn': '3 John',
    'iii john': '3 John',
    'third john': '3 John',

    'jude': 'Jude',
    'jud': 'Jude',

    'revelation': 'Revelation',
    'rev': 'Revelation',
    're': 'Revelation',
    'the revelation': 'Revelation',
  };

  if (aliases.containsKey(normalized)) {
    return aliases[normalized]!;
  }

  return _toTitleCasePreservingLeadingNumber(input);
}

String _normalizeBibleKey(String input) {
  var value = input.trim().toLowerCase();

  value = value.replaceAll('.', '');
  value = value.replaceAll(':', ' ');
  value = value.replaceAll(RegExp(r'\s+'), ' ').trim();

  value = value
      .replaceAll(RegExp(r'^(first)\s+'), '1 ')
      .replaceAll(RegExp(r'^(second)\s+'), '2 ')
      .replaceAll(RegExp(r'^(third)\s+'), '3 ')
      .replaceAll(RegExp(r'^(1st)\s+'), '1 ')
      .replaceAll(RegExp(r'^(2nd)\s+'), '2 ')
      .replaceAll(RegExp(r'^(3rd)\s+'), '3 ');

  return value;
}

String _toTitleCasePreservingLeadingNumber(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  final words = trimmed
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .toList(growable: false);

  return words.map((word) {
    final lower = word.toLowerCase();
    if (RegExp(r'^\d+$').hasMatch(lower)) {
      return lower;
    }

    return lower[0].toUpperCase() + lower.substring(1);
  }).join(' ');
}
