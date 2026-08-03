import 'package:flutter/material.dart';

class GradientPageBackground extends StatelessWidget {
  final Widget child;

  const GradientPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF070A16), // deep navy/black
            Color(0xFF0B1030), // navy
            Color(0xFF1A0F2E), // purple tint
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}
