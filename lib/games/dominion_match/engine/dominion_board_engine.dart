import 'dart:math';

import '../core/dominion_level.dart';
import '../core/dominion_tile.dart';
import '../core/dominion_tile_type.dart';

class DominionBoardEngine {
  static const rows = 8;
  static const cols = 8;

  final Random _random;

  DominionBoardEngine({Random? random}) : _random = random ?? Random();

  List<List<DominionTile>> generateBoard(DominionLevel level) {
    final grid = List.generate(
      rows,
      (row) => List.generate(
        cols,
        (col) => DominionTile(
          id: _id(row, col),
          type: DominionTileType.bible,
          row: row,
          col: col,
          isNew: true,
        ),
      ),
    );

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        var type = _randomType(level);
        var guard = 0;
        while (_createsInitialMatch(grid, row, col, type) && guard < 80) {
          type = _randomType(level);
          guard++;
        }
        grid[row][col] = grid[row][col].copyWith(type: type, isNew: true);
      }
    }

    return grid;
  }

  DominionTileType _randomType(DominionLevel level) {
    final roll = _random.nextDouble();
    if (roll < level.dominionChance) return DominionTileType.dominion;
    if (roll < level.dominionChance + level.powerTileChance) {
      return _randomPowerType(level);
    }

    final values = _baseTypesForLevel(level);
    return values[_random.nextInt(values.length)];
  }

  DominionTileType _randomPowerType(DominionLevel level) {
    final available = <DominionTileType>[
      DominionTileType.rowBurst,
      DominionTileType.columnBurst,
      if (level.stage >= 18) DominionTileType.faithBomb,
      if (level.stage >= 8) DominionTileType.scriptureGem,
      if (level.stage >= 30) DominionTileType.dominion,
    ];
    return available[_random.nextInt(available.length)];
  }

  List<DominionTileType> _baseTypesForLevel(DominionLevel level) {
    final base = level.stage <= 10
        ? DominionTileSpec.beginnerTypes
        : DominionTileSpec.baseTypes;
    final limit = level.tileVariety.clamp(4, base.length);
    return base.take(limit).toList(growable: false);
  }

  bool _createsInitialMatch(
    List<List<DominionTile>> grid,
    int row,
    int col,
    DominionTileType type,
  ) {
    if (type.isPower) return false;
    if (col >= 2 &&
        grid[row][col - 1].type == type &&
        grid[row][col - 2].type == type) {
      return true;
    }
    if (row >= 2 &&
        grid[row - 1][col].type == type &&
        grid[row - 2][col].type == type) {
      return true;
    }
    return false;
  }

  bool isAdjacent(DominionPoint a, DominionPoint b) {
    return (a.row - b.row).abs() + (a.col - b.col).abs() == 1;
  }

  List<List<DominionTile>> swapped(
    List<List<DominionTile>> board,
    DominionPoint a,
    DominionPoint b,
  ) {
    final grid = clone(board);
    final first = grid[a.row][a.col];
    final second = grid[b.row][b.col];
    grid[a.row][a.col] = second.copyWith(row: a.row, col: a.col);
    grid[b.row][b.col] = first.copyWith(row: b.row, col: b.col);
    return grid;
  }

  Set<DominionPoint> findMatches(List<List<DominionTile>> grid) {
    final points = <DominionPoint>{};

    for (var row = 0; row < rows; row++) {
      var start = 0;
      for (var col = 1; col <= cols; col++) {
        final isEnd =
            col == cols || grid[row][col].type != grid[row][start].type;
        if (isEnd) {
          final length = col - start;
          final type = grid[row][start].type;
          if (length >= 3 && type.isBase) {
            for (var x = start; x < col; x++) {
              points.add(DominionPoint(row, x));
            }
          }
          start = col;
        }
      }
    }

    for (var col = 0; col < cols; col++) {
      var start = 0;
      for (var row = 1; row <= rows; row++) {
        final isEnd =
            row == rows || grid[row][col].type != grid[start][col].type;
        if (isEnd) {
          final length = row - start;
          final type = grid[start][col].type;
          if (length >= 3 && type.isBase) {
            for (var y = start; y < row; y++) {
              points.add(DominionPoint(y, col));
            }
          }
          start = row;
        }
      }
    }

    return points;
  }

  Set<DominionPoint> powerBlast(DominionPoint center, DominionTileType type) {
    return switch (type) {
      DominionTileType.rowBurst => rowBlast(center.row),
      DominionTileType.columnBurst => columnBlast(center.col),
      DominionTileType.faithBomb => areaBlast(center, radius: 1),
      DominionTileType.scriptureGem => areaBlast(center, radius: 1),
      DominionTileType.dominion => areaBlast(center, radius: 2),
      _ => <DominionPoint>{center},
    };
  }

  Set<DominionPoint> rowBlast(int row) {
    return {for (var col = 0; col < cols; col++) DominionPoint(row, col)};
  }

  Set<DominionPoint> columnBlast(int col) {
    return {for (var row = 0; row < rows; row++) DominionPoint(row, col)};
  }

  Set<DominionPoint> areaBlast(DominionPoint center, {required int radius}) {
    final points = <DominionPoint>{};
    for (var row = center.row - radius; row <= center.row + radius; row++) {
      for (var col = center.col - radius; col <= center.col + radius; col++) {
        if (row >= 0 && row < rows && col >= 0 && col < cols) {
          points.add(DominionPoint(row, col));
        }
      }
    }
    return points;
  }

  List<List<DominionTile>> clearAndRefill(
    List<List<DominionTile>> board,
    Set<DominionPoint> matches,
    DominionLevel level,
  ) {
    final grid = clone(board);

    for (var col = 0; col < cols; col++) {
      final survivors = <DominionTile>[];
      for (var row = rows - 1; row >= 0; row--) {
        if (!matches.contains(DominionPoint(row, col))) {
          survivors.add(grid[row][col]);
        }
      }

      var writeRow = rows - 1;
      for (final tile in survivors) {
        grid[writeRow][col] =
            tile.copyWith(row: writeRow, col: col, isNew: false);
        writeRow--;
      }

      while (writeRow >= 0) {
        grid[writeRow][col] = DominionTile(
          id: _id(writeRow, col),
          type: _randomType(level),
          row: writeRow,
          col: col,
          isNew: true,
        );
        writeRow--;
      }
    }

    return grid;
  }

  List<List<DominionTile>> clone(List<List<DominionTile>> board) {
    return board
        .map(
          (row) => row.map((tile) => tile.copyWith()).toList(growable: false),
        )
        .toList(growable: false);
  }

  String _id(int row, int col) =>
      '${DateTime.now().microsecondsSinceEpoch}_${row}_${col}_${_random.nextInt(99999)}';
}
