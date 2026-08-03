class SectionActionRegistry {
  const SectionActionRegistry._();

  static const Set<String> scriptureTypes = {
    'scripture',
    'daily_scripture',
    'scripture_card',
  };

  static const Set<String> quoteTypes = {
    'quote',
    'daily_quote',
    'quote_card',
  };

  static const Set<String> mediaTypes = {
    'video',
    'videos',
    'video_feed',
    'live',
    'stream',
    'youtube',
    'hls',
  };

  static String normalize(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_');
  }

  static bool isScripture(String value) {
    return scriptureTypes.contains(normalize(value));
  }

  static bool isQuote(String value) {
    return quoteTypes.contains(normalize(value));
  }

  static bool isMedia(String value) {
    return mediaTypes.contains(normalize(value));
  }
}
