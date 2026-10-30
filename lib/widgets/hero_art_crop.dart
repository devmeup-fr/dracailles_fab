import 'package:flutter/material.dart';

/// Crops a fixed fractional window out of an asset image and shows it
/// cover-fit in its box, without ever touching the image file on disk.
///
/// The defaults suit full-art hero photos: the art bleeds to every edge
/// except a thin name plate at the very bottom, which consistently starts
/// around 85-88% of the image height across samples, so the default
/// `bottom` clears that with a small margin and trims as little of the art
/// as possible - cropping more than necessary here forces a tighter zoom
/// once it's cover-fit into the (usually wider) tile than is actually
/// needed. Bordered cards need an explicit override instead (see
/// life_tracker_widget.dart): title bar from 0 to ~12%, then art down to
/// ~62% before a rules text box, consistent across samples checked.
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
    this.left = 0.0,
    this.top = 0.0,
    this.right = 1.0,
    this.bottom = 0.86,
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
        // The tile's own aspect ratio rarely matches the extracted crop's,
        // so cover still has to cut some of it to fill the tile. Default
        // (center) alignment would cut that evenly off the top and bottom -
        // but the head is near the top of the art, not the middle, so
        // anchoring to the top instead pushes all of that extra cropping
        // onto the bottom, where it's safe.
        alignment: Alignment.topCenter,
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
