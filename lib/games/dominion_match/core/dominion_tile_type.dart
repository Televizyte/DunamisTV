import 'package:flutter/material.dart';

enum DominionTileType {
  bible,
  cross,
  dove,
  fire,
  crown,
  heart,
  light,
  prayer,
  shield,
  rowBurst,
  columnBurst,
  faithBomb,
  scriptureGem,
  dominion,
}

extension DominionTileTypeX on DominionTileType {
  bool get isPower => switch (this) {
        DominionTileType.rowBurst ||
        DominionTileType.columnBurst ||
        DominionTileType.faithBomb ||
        DominionTileType.scriptureGem ||
        DominionTileType.dominion =>
          true,
        _ => false,
      };

  bool get isBase => !isPower;
}

class DominionTileSpec {
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final Color glowColor;
  final bool premium;

  const DominionTileSpec({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.glowColor,
    this.premium = false,
  });

  static DominionTileSpec fromType(DominionTileType type) {
    return switch (type) {
      DominionTileType.bible => const DominionTileSpec(
          label: 'Bible',
          shortLabel: 'WORD',
          icon: Icons.menu_book_rounded,
          startColor: Color(0xFF1E6CFF),
          endColor: Color(0xFF0B2B95),
          glowColor: Color(0xFF3C8CFF),
        ),
      DominionTileType.cross => const DominionTileSpec(
          label: 'Cross',
          shortLabel: 'CROSS',
          icon: Icons.church_rounded,
          startColor: Color(0xFFFFE9A6),
          endColor: Color(0xFFD99B24),
          glowColor: Color(0xFFFFD66B),
        ),
      DominionTileType.dove => const DominionTileSpec(
          label: 'Dove',
          shortLabel: 'PEACE',
          icon: Icons.flutter_dash_rounded,
          startColor: Color(0xFF78E2FF),
          endColor: Color(0xFF1782B9),
          glowColor: Color(0xFF78E2FF),
        ),
      DominionTileType.fire => const DominionTileSpec(
          label: 'Fire',
          shortLabel: 'FIRE',
          icon: Icons.local_fire_department_rounded,
          startColor: Color(0xFFFF7248),
          endColor: Color(0xFFC82437),
          glowColor: Color(0xFFFF7A3D),
        ),
      DominionTileType.crown => const DominionTileSpec(
          label: 'Crown',
          shortLabel: 'CROWN',
          icon: Icons.workspace_premium_rounded,
          startColor: Color(0xFFFFD95D),
          endColor: Color(0xFFB87906),
          glowColor: Color(0xFFFFD95D),
        ),
      DominionTileType.heart => const DominionTileSpec(
          label: 'Heart',
          shortLabel: 'LOVE',
          icon: Icons.favorite_rounded,
          startColor: Color(0xFFFF4DB8),
          endColor: Color(0xFFB70E7C),
          glowColor: Color(0xFFFF4DB8),
        ),
      DominionTileType.light => const DominionTileSpec(
          label: 'Light',
          shortLabel: 'LIGHT',
          icon: Icons.wb_sunny_rounded,
          startColor: Color(0xFFFFF8B8),
          endColor: Color(0xFFFFB13D),
          glowColor: Color(0xFFFFF3A7),
        ),
      DominionTileType.prayer => const DominionTileSpec(
          label: 'Prayer',
          shortLabel: 'PRAY',
          icon: Icons.volunteer_activism_rounded,
          startColor: Color(0xFFB2FFEA),
          endColor: Color(0xFF00A887),
          glowColor: Color(0xFF60FFD3),
        ),
      DominionTileType.shield => const DominionTileSpec(
          label: 'Shield',
          shortLabel: 'SHIELD',
          icon: Icons.shield_rounded,
          startColor: Color(0xFFB9C8FF),
          endColor: Color(0xFF4B5FA8),
          glowColor: Color(0xFFA7B8FF),
        ),
      DominionTileType.rowBurst => const DominionTileSpec(
          label: 'Row Burst',
          shortLabel: 'ROW',
          icon: Icons.horizontal_rule_rounded,
          startColor: Color(0xFF34F5C5),
          endColor: Color(0xFF007D7A),
          glowColor: Color(0xFF34F5C5),
          premium: true,
        ),
      DominionTileType.columnBurst => const DominionTileSpec(
          label: 'Column Burst',
          shortLabel: 'COL',
          icon: Icons.view_stream_rounded,
          startColor: Color(0xFFB47CFF),
          endColor: Color(0xFF4A1BA6),
          glowColor: Color(0xFFB47CFF),
          premium: true,
        ),
      DominionTileType.faithBomb => const DominionTileSpec(
          label: 'Faith Bomb',
          shortLabel: 'BOMB',
          icon: Icons.brightness_7_rounded,
          startColor: Color(0xFFFF8B5B),
          endColor: Color(0xFFD7195A),
          glowColor: Color(0xFFFF6E9D),
          premium: true,
        ),
      DominionTileType.scriptureGem => const DominionTileSpec(
          label: 'Scripture Gem',
          shortLabel: 'GEM',
          icon: Icons.diamond_rounded,
          startColor: Color(0xFF91F7FF),
          endColor: Color(0xFF1E53FF),
          glowColor: Color(0xFF91F7FF),
          premium: true,
        ),
      DominionTileType.dominion => const DominionTileSpec(
          label: 'Dominion Burst',
          shortLabel: 'DOM',
          icon: Icons.auto_awesome_rounded,
          startColor: Color(0xFFFFF3A7),
          endColor: Color(0xFF8D3DFF),
          glowColor: Color(0xFFFFF3A7),
          premium: true,
        ),
    };
  }

  static List<DominionTileType> get baseTypes => const [
        DominionTileType.bible,
        DominionTileType.cross,
        DominionTileType.dove,
        DominionTileType.fire,
        DominionTileType.crown,
        DominionTileType.heart,
        DominionTileType.light,
        DominionTileType.prayer,
        DominionTileType.shield,
      ];

  static List<DominionTileType> get beginnerTypes => const [
        DominionTileType.bible,
        DominionTileType.cross,
        DominionTileType.dove,
        DominionTileType.heart,
        DominionTileType.crown,
      ];

  static List<DominionTileType> get powerTypes => const [
        DominionTileType.rowBurst,
        DominionTileType.columnBurst,
        DominionTileType.faithBomb,
        DominionTileType.scriptureGem,
        DominionTileType.dominion,
      ];
}
