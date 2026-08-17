import 'package:flutter/material.dart';

class ImageBlock extends StatelessWidget {
  final String url;
  final String fallbackAsset;
  final String caption;

  const ImageBlock({
    super.key,
    required this.url,
    required this.fallbackAsset,
    this.caption = '',
  });

  String _resolveUrl(String input) {
    final u = input.trim();

    if (u.isEmpty) return '';

    // already full URL
    if (u.startsWith('http')) return u;

    // FIX: convert relative path to full AppsHub URL
    return 'https://admin.appshub.digitxtramedia.com$u';
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveUrl(url);

    if (resolved.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              resolved,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Image.asset(
                  fallbackAsset,
                  width: double.infinity,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          if (caption.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
