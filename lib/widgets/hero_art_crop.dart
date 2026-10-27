import 'package:flutter/material.dart';

/// Crops a fixed fractional window out of an asset image and shows it
/// cover-fit in its box, without ever touching the image file on disk.
///
/// The hero photos under `assets/images/hero_photos/` are full card scans,
/// not isolated art, and the set mixes two templates: bordered cards with
/// a title bar above the art and a rules-text box below it, and full-art
/// cards with no border where the art reaches the very top edge and only a
/// name plate sits at the bottom. Plain `BoxFit.cover` centers on the whole
/// card, cutting into the character's head either way. There's no single
/// crop that removes a top title bar AND never touches a full-art head, so
/// `top` defaults to 0 (never crops the top - at worst a bordered card's
/// title bar peeks in) and only the bottom text/name-plate area is cropped.
///
/// This needs the asset's real pixel size (not just the fractions) to crop
/// without distorting the art: the crop is extracted at native resolution
/// first, then cover-fit into the box as a second, separate, uniform scale.
class HeroArtCrop extends StatefulWidget {
  final String assetPath;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const HeroArtCrop({
    super.key,
    required this.assetPath,
    this.left = 0.05,
    this.top = 0.0,
    this.right = 0.95,
    this.bottom = 0.62,
  });

  @override
  State<HeroArtCrop> createState() => _HeroArtCropState();
}

class _HeroArtCropState extends State<HeroArtCrop> {
  static final Map<String, Size> _sizeCache = {};

  Size? _imageSize;
  ImageStreamListener? _listener;
  ImageStream? _stream;

  @override
  void initState() {
    super.initState();
    _resolveSize();
  }

  @override
  void didUpdateWidget(covariant HeroArtCrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _imageSize = null;
      _resolveSize();
    }
  }

  void _resolveSize() {
    final cached = _sizeCache[widget.assetPath];
    if (cached != null) {
      _imageSize = cached;
      return;
    }
    final stream = AssetImage(widget.assetPath).resolve(
      const ImageConfiguration(),
    );
    _listener = ImageStreamListener((info, _) {
      final size = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      _sizeCache[widget.assetPath] = size;
      _detachListener();
      if (mounted) setState(() => _imageSize = size);
    }, onError: (error, stackTrace) => _detachListener());
    _stream = stream..addListener(_listener!);
  }

  void _detachListener() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _listener = null;
    _stream = null;
  }

  @override
  void dispose() {
    _detachListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _imageSize;
    final fallback = Image.asset(
      widget.assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
    // Not resolved yet (first frame) or failed to load: fall back to a
    // plain cover image so something still shows instead of nothing.
    if (size == null) return fallback;

    final artWidth = (widget.right - widget.left) * size.width;
    final artHeight = (widget.bottom - widget.top) * size.height;
    if (artWidth <= 0 || artHeight <= 0) return fallback;

    // Maps the crop window's position within the full image to the -1..1
    // alignment OverflowBox expects, so the window lands exactly over it.
    final cropWidthFraction = widget.right - widget.left;
    final cropHeightFraction = widget.bottom - widget.top;
    final alignX = cropWidthFraction >= 1
        ? 0.0
        : 2 * widget.left / (1 - cropWidthFraction) - 1;
    final alignY = cropHeightFraction >= 1
        ? 0.0
        : 2 * widget.top / (1 - cropHeightFraction) - 1;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: artWidth,
          height: artHeight,
          child: OverflowBox(
            maxWidth: size.width,
            maxHeight: size.height,
            alignment: Alignment(alignX, alignY),
            // Rendered at the image's own native size, so this is a pure
            // crop (via OverflowBox clipping) with no stretching - any
            // scaling happens once, uniformly, in the FittedBox above.
            child: Image.asset(
              widget.assetPath,
              width: size.width,
              height: size.height,
              fit: BoxFit.fill,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
