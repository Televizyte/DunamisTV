import 'app_template_blueprint.dart';

class AppTemplateRegistry {
  const AppTemplateRegistry._();

  static final Map<String, AppTemplateBlueprint> templates = {
    'tv': _tvTemplate,
    'store': _storeTemplate,
    'media': _mediaTemplate,
    'radio': _radioTemplate,
  };

  static AppTemplateBlueprint get(String key) {
    return templates[key] ?? _tvTemplate;
  }

  /// =========================
  /// 📺 TV TEMPLATE (Dunamis / Celebration TV)
  /// =========================
  static const AppTemplateBlueprint _tvTemplate = AppTemplateBlueprint(
    key: 'tv',
    name: 'TV App Template',
    description: 'For church, streaming, and video-based apps',
    sections: [
      {
        'section_key': 'hero',
        'title': 'Live Now',
        'type': 'video',
        'layout': 'hero',
      },
      {
        'section_key': 'daily_scripture',
        'title': 'Daily Scripture',
        'type': 'scripture',
        'layout': 'compact',
      },
      {
        'section_key': 'daily_quote',
        'title': 'Daily Quote',
        'type': 'quote',
        'layout': 'compact',
      },
      {
        'section_key': 'highlights',
        'title': 'Message Highlights',
        'type': 'video_feed',
        'layout': 'vertical_list',
      },
    ],
  );

  /// =========================
  /// 🛒 STORE TEMPLATE
  /// =========================
  static const AppTemplateBlueprint _storeTemplate = AppTemplateBlueprint(
    key: 'store',
    name: 'Store App Template',
    description: 'For ecommerce and marketplace apps',
    sections: [
      {
        'section_key': 'featured_products',
        'title': 'Featured Products',
        'type': 'product',
        'layout': 'grid',
      },
      {
        'section_key': 'categories',
        'title': 'Categories',
        'type': 'category',
        'layout': 'icon_grid',
      },
    ],
  );

  /// =========================
  /// 🎧 MEDIA TEMPLATE
  /// =========================
  static const AppTemplateBlueprint _mediaTemplate = AppTemplateBlueprint(
    key: 'media',
    name: 'Media Player Template',
    description: 'For audio/video content apps',
    sections: [
      {
        'section_key': 'media_library',
        'title': 'Media Library',
        'type': 'media',
        'layout': 'vertical_list',
      },
      {
        'section_key': 'shorts',
        'title': 'Short Videos',
        'type': 'short_video_feed',
        'layout': 'short_video_feed',
      },
    ],
  );

  /// =========================
  /// 📻 RADIO TEMPLATE
  /// =========================
  static const AppTemplateBlueprint _radioTemplate = AppTemplateBlueprint(
    key: 'radio',
    name: 'Radio App Template',
    description: 'For live audio and radio streaming apps',
    sections: [
      {
        'section_key': 'live_radio',
        'title': 'Live Radio',
        'type': 'live_audio',
        'layout': 'hero',
      },
      {
        'section_key': 'schedule',
        'title': 'Programs',
        'type': 'schedule',
        'layout': 'vertical_list',
      },
    ],
  );
}
