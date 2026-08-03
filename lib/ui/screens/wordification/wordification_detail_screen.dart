import 'package:flutter/material.dart';

class WordificationDetailScreen extends StatelessWidget {
  final String itemId;

  const WordificationDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text('Wordification'),
        backgroundColor: const Color(0xFF0B1020),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121A33),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: const Text(
            'Wordification Detail (Placeholder)\n\nThis screen will render:\n\n• Scripture reference\n• Scripture text\n• Explanation\n• Application\n\nPowered by FireDrive later.',
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.35),
          ),
        ),
      ),
    );
  }
}
