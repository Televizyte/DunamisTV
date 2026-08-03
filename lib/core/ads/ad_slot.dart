import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AdSlot extends StatelessWidget {
  final double height;
  final String label;
  final EdgeInsets padding;

  const AdSlot({
    super.key,
    this.height = 72,
    this.label = 'Ad Slot',
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    // On Web: show a placeholder box (so UI layout stays consistent).
    if (kIsWeb) {
      return Padding(
        padding: padding,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    }

    // On Mobile: this is where the real Banner widget will render later
    // (we’ll wire it after we patch your ad manager).
    return const SizedBox.shrink();
  }
}
