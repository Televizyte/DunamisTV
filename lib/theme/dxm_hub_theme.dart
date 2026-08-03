import 'package:flutter/material.dart';
import '../features/hub/domain/hub_models.dart';

class DxmHubTheme {
  static ThemeData build({HubConfig? hub}) {
    final primary = _parseHex(hub?.console.primaryColor ?? '#1e0042');
    final accent = _parseHex(hub?.console.accentColor ?? '#ff24a4');

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: const Color(0xFF0B0F1A),
      ),
      scaffoldBackgroundColor: const Color(0xFF050713),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: const Color(0xCC050713),
        selectedItemColor: accent,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: const Color(0xFF0B1020),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      extensions: <ThemeExtension<dynamic>>[
        HubBrand(primary: primary, accent: accent),
      ],
    );
  }

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    final v = int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return Color(v ?? 0xFF1E0042);
  }
}

class HubBrand extends ThemeExtension<HubBrand> {
  final Color primary;
  final Color accent;

  const HubBrand({required this.primary, required this.accent});

  @override
  HubBrand copyWith({Color? primary, Color? accent}) {
    return HubBrand(primary: primary ?? this.primary, accent: accent ?? this.accent);
  }

  @override
  HubBrand lerp(ThemeExtension<HubBrand>? other, double t) {
    if (other is! HubBrand) return this;
    return HubBrand(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
    );
  }
}
