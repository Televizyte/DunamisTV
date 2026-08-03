class AppEnginePayloadStandard {
  const AppEnginePayloadStandard._();

  static const Map<String, List<String>> coreFields = {
    'identity': [
      'app_key',
      'app_slug',
      'app_type',
      'brand_key',
      'platform',
    ],
    'navigation': [
      'tabs',
      'tab_key',
      'tab_label',
      'tab_icon',
      'tab_order',
    ],
    'section': [
      'section_key',
      'title',
      'subtitle',
      'layout',
      'order',
      'settings',
    ],
    'item': [
      'id',
      'key',
      'title',
      'subtitle',
      'description',
      'image_url',
      'thumbnail_url',
      'badge',
      'type',
    ],
    'action': [
      'engine',
      'route',
      'url',
      'content_id',
      'bucket',
      'action',
      'cta',
      'cta_label',
    ],
    'media': [
      'video_url',
      'stream_url',
      'audio_url',
      'youtube_url',
      'hls_url',
      'duration',
      'playlist_id',
    ],
    'tool_bridge': [
      'text',
      'reference',
      'verse_text',
      'verse_reference',
      'quote_text',
      'note_text',
      'source_title',
      'source_type',
      'source_id',
    ],
    'commerce': [
      'product_id',
      'price',
      'currency',
      'cart_id',
      'checkout_url',
      'order_id',
    ],
  };

  static const Map<String, dynamic> exampleDailyScripturePayload = {
    'section_key': 'daily_scripture',
    'title': 'Daily Scripture',
    'layout': 'scripture',
    'engine': 'bible',
    'verse_text': 'The Lord is my shepherd; I shall not want.',
    'verse_reference': 'Psalm 23:1',
    'actions': [
      {
        'label': 'Open Bible',
        'engine': 'bible',
        'reference': 'Psalm 23:1',
      },
      {
        'label': 'Make Quote',
        'engine': 'quote_creator',
        'quote_text': 'The Lord is my shepherd; I shall not want.',
        'source_title': 'Psalm 23:1',
      },
      {
        'label': 'Add Note',
        'engine': 'notes',
        'note_text': 'Psalm 23:1 — The Lord is my shepherd; I shall not want.',
        'source_title': 'Daily Scripture',
      },
    ],
  };

  static const Map<String, dynamic> exampleStoreProductPayload = {
    'section_key': 'featured_products',
    'title': 'Featured Products',
    'layout': 'grid',
    'items': [
      {
        'id': 'prod_001',
        'title': 'Product Name',
        'subtitle': 'Short product description',
        'image_url': 'https://example.com/product.jpg',
        'engine': 'store',
        'route': '/tab/store',
        'product_id': 'prod_001',
        'price': 25.00,
        'currency': 'USD',
      },
    ],
  };

  static const Map<String, dynamic> exampleRadioPayload = {
    'section_key': 'live_radio',
    'title': 'Live Radio',
    'layout': 'hero',
    'engine': 'live_audio',
    'stream_url': 'https://example.com/radio-stream.mp3',
    'actions': [
      {
        'label': 'Listen Live',
        'engine': 'live_audio',
        'stream_url': 'https://example.com/radio-stream.mp3',
      },
    ],
  };

  static const Map<String, dynamic> exampleMediaPayload = {
    'section_key': 'media_library',
    'title': 'Media Library',
    'layout': 'vertical_list',
    'items': [
      {
        'id': 'media_001',
        'title': 'Teaching Title',
        'subtitle': 'Audio / Video message',
        'engine': 'media_player',
        'video_url': 'https://example.com/video.mp4',
        'audio_url': 'https://example.com/audio.mp3',
        'actions': [
          {
            'label': 'Take Note',
            'engine': 'notes',
            'source_id': 'media_001',
            'source_type': 'media',
          },
          {
            'label': 'Make Quote',
            'engine': 'quote_creator',
            'source_id': 'media_001',
            'source_type': 'media',
          },
        ],
      },
    ],
  };
}
