import 'package:flutter/material.dart';

class DividerBlock extends StatelessWidget {
  const DividerBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(
        height: 1,
        color: Colors.white.withOpacity(0.10),
      ),
    );
  }
}
