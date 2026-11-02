import 'package:fab_dracailles/theme/fantasy_theme.dart';
import 'package:flutter/material.dart';

/// Frames [child] like a physical card sitting on the table: a gold double
/// ring around a clipped window, with a soft glow in [accentColor] behind
/// it. Deliberately doesn't try to fill its parent edge to edge - leaving
/// the dark background visible around it is what makes it read as an
/// object placed on the table rather than wallpaper, and it also means the
/// art inside never needs to be blown up past its own resolution just to
/// cover a much bigger tile.
class OrnateFrame extends StatelessWidget {
  final double width;
  final double height;
  final Color accentColor;
  final Widget child;
  final double glowStrength;

  const OrnateFrame({
    super.key,
    required this.width,
    required this.height,
    required this.accentColor,
    required this.child,
    this.glowStrength = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    const outerRadius = 18.0;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(outerRadius),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.55 * glowStrength),
            blurRadius: 26 * glowStrength,
            spreadRadius: 1 * glowStrength,
          ),
        ],
      ),
      // Outer ring: a gradient instead of a flat gold gives the trim a
      // faint sheen instead of looking like a solid-color plastic band.
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerRadius),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FantasyPalette.gold,
              FantasyPalette.goldDim,
              FantasyPalette.gold,
            ],
          ),
        ),
        child: Padding(
          // Thin dark gap between the two rings - without it the inner
          // ring's own color just blends into the outer one.
          padding: const EdgeInsets.all(2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: FantasyPalette.obsidian,
              borderRadius: BorderRadius.circular(outerRadius - 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(outerRadius - 6),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
