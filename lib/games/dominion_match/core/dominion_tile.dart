import 'dominion_tile_type.dart';

class DominionTile {
  final String id;
  final DominionTileType type;
  final int row;
  final int col;
  final bool isMatched;
  final bool isNew;
  final bool locked;
  final int shieldStrength;

  const DominionTile({
    required this.id,
    required this.type,
    required this.row,
    required this.col,
    this.isMatched = false,
    this.isNew = false,
    this.locked = false,
    this.shieldStrength = 0,
  });

  bool get isPower => type.isPower;
  bool get isShielded => locked || shieldStrength > 0;

  DominionTile copyWith({
    String? id,
    DominionTileType? type,
    int? row,
    int? col,
    bool? isMatched,
    bool? isNew,
    bool? locked,
    int? shieldStrength,
  }) {
    return DominionTile(
      id: id ?? this.id,
      type: type ?? this.type,
      row: row ?? this.row,
      col: col ?? this.col,
      isMatched: isMatched ?? this.isMatched,
      isNew: isNew ?? this.isNew,
      locked: locked ?? this.locked,
      shieldStrength: shieldStrength ?? this.shieldStrength,
    );
  }
}

class DominionPoint {
  final int row;
  final int col;

  const DominionPoint(this.row, this.col);

  @override
  bool operator ==(Object other) {
    return other is DominionPoint && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}
