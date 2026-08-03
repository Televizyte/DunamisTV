import 'package:flutter/material.dart';

import 'web_screen_impl.dart'
    if (dart.library.html) 'web_screen_web.dart' as impl;

class WebScreen extends StatelessWidget {
  final String title;
  final String url;

  const WebScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return impl.WebScreenImpl(title: title, url: url);
  }
}
