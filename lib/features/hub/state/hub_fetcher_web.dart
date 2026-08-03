import 'dart:html' as html;

Future<String> hubHttpGet(String url) async {
  final req = await html.HttpRequest.request(
    url,
    method: 'GET',
    requestHeaders: {'Accept': 'application/json'},
  );
  return req.responseText ?? '';
}
