import 'package:flutter/material.dart';

import '../navigation/dynamic_action_executor.dart';
import 'native_engine_test_payloads.dart';

class NativeEngineTestScreen extends StatelessWidget {
  const NativeEngineTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B17),
        foregroundColor: Colors.white,
        title: const Text('Native Engine Test'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: NativeEngineTestPayloads.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = NativeEngineTestPayloads.items[index];

          return Material(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                DynamicActionExecutor.executeMap(context, item);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1D5CFF),
                            Color(0xFFFF4DB8),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (item['title'] ?? '').toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (item['subtitle'] ?? '').toString(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
