import 'dart:convert';
import 'dart:io';

Future<String> hubHttpGet(String url) async {
  final uri = Uri.parse(url);
  final client = HttpClient();
  try {
    final req = await client.getUrl(uri);
    req.headers.set('Accept', 'application/json');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    return body;
  } finally {
    client.close(force: true);
  }
}
