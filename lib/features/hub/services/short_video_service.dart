import 'dart:convert';
import 'package:http/http.dart' as http;

class ShortVideoService {
  static const String baseUrl =
      'https://admin.appshub.digitxtramedia.com/api/v1';

  static const String appToken = 'YOUR_APP_TOKEN_HERE';

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'X-APP-TOKEN': appToken,
      };

  /// LIKE VIDEO
  static Future<void> likeVideo(String videoId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/short-videos/like'),
        headers: headers,
        body: jsonEncode({'video_id': videoId}),
      );
    } catch (_) {
      // silent fail (UI should not break)
    }
  }

  /// SAVE VIDEO
  static Future<void> saveVideo(String videoId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/short-videos/save'),
        headers: headers,
        body: jsonEncode({'video_id': videoId}),
      );
    } catch (_) {}
  }

  /// TRACK WATCH
  static Future<void> trackWatch(String videoId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/short-videos/watch'),
        headers: headers,
        body: jsonEncode({'video_id': videoId}),
      );
    } catch (_) {}
  }

  /// SHARE LINK (DYNAMIC)
  static String generateShareLink(String videoId) {
    return 'https://digitxtramedia.com/shorts/$videoId';
  }
}
