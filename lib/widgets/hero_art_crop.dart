import 'package:flutter/material.dart';

/// Crops a fixed fractional window out of an asset image and scales it to
/// fill its box, without ever touching the image file on disk.
///
/// The hero photos under `assets/images/hero_photos/` are full card scans
/// (title bar, art, rules text, stats), not isolated art. Plain
/// `BoxFit.cover` centers on the whole card, which cuts into the character
/// whenever the card's art box isn't vertically centered on the card - the
/// crop fractions below pick out just the art box instead. Tune them here
/// if a future card template shifts the art box.
class HeroArtCrop extends StatelessWidget {
  final String assetPath;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const HeroArtCrop({
    super.key,
    required this.assetPath,
    this.left = 0.05,
    this.top = 0.1253,
    this.right = 0.95,
    this.bottom = 0.6026,
  });

  @override
  Widget build(BuildContext context) {
    final cropWidth = right - left;
    final cropHeight = bottom - top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        final boxHeight = constraints.maxHeight;
        final fullWidth = boxWidth / cropWidth;
        final fullHeight = boxHeight / cropHeight;
        // Maps the crop window's position to the -1..1 alignment OverflowBox
        // expects, so the window lands exactly on the visible box.
        final alignX = 2 * left / (1 - cropWidth) - 1;
        final alignY = 2 * top / (1 - cropHeight) - 1;

        return ClipRect(
          child: OverflowBox(
            maxWidth: fullWidth,
            maxHeight: fullHeight,
            alignment: Alignment(alignX, alignY),
            child: Image.asset(
              assetPath,
              width: fullWidth,
              height: fullHeight,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
