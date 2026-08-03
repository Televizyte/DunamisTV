import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/dominion_level.dart';
import '../../core/dominion_tile.dart';
import '../../engine/dominion_board_engine.dart';
import 'dominion_tile_widget.dart';

class DominionGameBoard extends StatelessWidget {
  final List<List<DominionTile>> board;
  final DominionPoint? selectedPoint;
  final bool busy;
  final DominionWorldTheme theme;
  final int shakeSeed;
  final int flashSeed;
  final bool lowTimePulse;
  final Future<void> Function(int row, int col) onTileTap;

  const DominionGameBoard({
    super.key,
    required this.board,
    required this.selectedPoint,
    required this.busy,
    required this.theme,
    required this.onTileTap,
    this.shakeSeed = 0,
    this.flashSeed = 0,
    this.lowTimePulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('board_motion_${shakeSeed}_$flashSeed'),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 430),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final shake = shakeSeed <= 0 ? 0.0 : math.sin(value * math.pi * 6) * 7;
        final flash = flashSeed <= 0 ? 0.0 : (1 - value).clamp(0.0, 1.0);
        final pulse =
            lowTimePulse ? (0.5 + (math.sin(value * math.pi * 2) * 0.5)) : 0.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: theme.boardColor.withOpacity(0.90),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Color.lerp(
                  theme.accentColor.withOpacity(0.30),
                  theme.warningColor.withOpacity(0.72),
                  lowTimePulse ? 0.55 : flash,
                )!,
                width: lowTimePulse ? 1.7 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    theme.accentColor.withOpacity(0.18),
                    theme.warningColor.withOpacity(0.32),
                    lowTimePulse ? pulse : flash,
                  )!,
                  blurRadius: lowTimePulse ? 42 : 36,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DominionBoardEngine.cols,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: DominionBoardEngine.rows * DominionBoardEngine.cols,
          itemBuilder: (context, index) {
            final row = index ~/ DominionBoardEngine.cols;
            final col = index % DominionBoardEngine.cols;
            final selected =
                selectedPoint?.row == row && selectedPoint?.col == col;
            return DominionTileWidget(
              key: ValueKey(board[row][col].id),
              tile: board[row][col],
              selected: selected,
              busy: busy,
              worldAccent: theme.accentColor,
              onTap: () => onTileTap(row, col),
            );
          },
        ),
      ),
    );
  }
}
