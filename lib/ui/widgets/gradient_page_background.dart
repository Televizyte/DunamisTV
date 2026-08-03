import 'package:flutter/material.dart';
import '../../theme/theme_controller.dart';

class GradientPageBackground extends StatelessWidget {
  final Widget child;
  const GradientPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final isLight = ThemeController.instance.isLightMode;

        return Container(
          decoration: BoxDecoration(
            gradient: isLight
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF7F1E6),
                      Color(0xFFF3EBDD),
                      Color(0xFFEDE3D0),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF070A17),
                      Color(0xFF0B1020),
                      Color(0xFF140B2D),
                    ],
                  ),
          ),
          child: child,
        );
      },
    );
  }
}
