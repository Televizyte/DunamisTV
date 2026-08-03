import '../../core/config/app_env.dart';
import '../../core/http/simple_http.dart';

class HubRepository {
  Future<Map<String, dynamic>> fetchHubConfig(String platformSlug) async {
    final url = AppEnv.hubConfigUrl(platformSlug);
    return SimpleHttp.getJson(url);
  }
}
