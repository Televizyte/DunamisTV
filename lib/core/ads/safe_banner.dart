import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SafeBanner extends StatelessWidget {
  final Widget mobileBanner;

  const SafeBanner({super.key, required this.mobileBanner});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return mobileBanner;
  }
}
