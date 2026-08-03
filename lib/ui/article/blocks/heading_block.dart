import 'package:flutter/material.dart';

class HeadingBlock extends StatelessWidget {
  final String text;

  const HeadingBlock({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          height: 1.2,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
