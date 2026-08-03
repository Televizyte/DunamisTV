import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/dominion_tile.dart';
import '../../core/dominion_tile_type.dart';

class DominionTileWidget extends StatefulWidget {
  final DominionTile tile;
  final bool selected;
  final bool busy;
  final Color worldAccent;
  final VoidCallback onTap;

  const DominionTileWidget({
    super.key,
    required this.tile,
    required this.selected,
    required this.busy,
    required this.worldAccent,
    required this.onTap,
  });

  @override
  State<DominionTileWidget> createState() => _DominionTileWidgetState();
}

class _DominionTileWidgetState extends State<DominionTileWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double _safeOpacity(double value) => value.clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final spec = DominionTileSpec.fromType(widget.tile.type);
    final isPower = widget.tile.type.isPower;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseWave = math.sin(_pulseController.value * math.pi * 2);
        final normalizedPulse =
            ((pulseWave + 1) / 2).clamp(0.0, 1.0).toDouble();

        final selectedGlowOpacity = widget.selected
            ? _safeOpacity(0.38 + (normalizedPulse * 0.22))
            : 0.0;
        final powerGlowOpacity = isPower
            ? _safeOpacity(0.36 + (normalizedPulse * 0.24))
            : _safeOpacity(0.20 + (normalizedPulse * 0.08));
        final glassOpacity = _safeOpacity(isPower
            ? 0.22 + (normalizedPulse * 0.14)
            : 0.12 + (normalizedPulse * 0.06));
        final radialOpacity = _safeOpacity(widget.selected
            ? 0.32 + (normalizedPulse * 0.18)
            : isPower
                ? 0.20 + (normalizedPulse * 0.14)
                : 0.0);

        final scale = widget.selected
            ? 1.08 + (normalizedPulse * 0.025)
            : widget.tile.isNew
                ? 1.025
                : isPower
                    ? 1.0 + (normalizedPulse * 0.012)
                    : 1.0;

        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          scale: scale,
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 220),
            turns: widget.selected && isPower ? 0.015 : 0,
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: widget.busy ? null : widget.onTap,
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 190),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [spec.startColor, spec.endColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: widget.selected
                          ? Colors.white
                          : isPower
                              ? spec.glowColor.withOpacity(
                                  _safeOpacity(0.72 + (normalizedPulse * 0.18)))
                              : Colors.white.withOpacity(0.18),
                      width: widget.selected || isPower ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: spec.glowColor.withOpacity(
                          widget.selected
                              ? selectedGlowOpacity
                              : powerGlowOpacity,
                        ),
                        blurRadius: widget.selected || isPower
                            ? 18 + (normalizedPulse * 6)
                            : 9,
                        spreadRadius: isPower ? 1.2 : 0,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 6,
                        top: 5,
                        right: 6,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(glassOpacity),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutBack,
                          scale: widget.selected ? 1.08 : 1.0,
                          child: Icon(
                            spec.icon,
                            color: isPower
                                ? const Color(0xFF160B34)
                                : Colors.white,
                            size: isPower ? 24 : 20,
                          ),
                        ),
                      ),
                      if (isPower)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: Text(
                              spec.shortLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 6.4,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      if (isPower || widget.selected)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(radialOpacity),
                                    Colors.transparent,
                                  ],
                                  radius: 0.82,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (isPower)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: widget.worldAccent.withOpacity(
                                    _safeOpacity(0.10 + normalizedPulse * 0.18),
                                  ),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
