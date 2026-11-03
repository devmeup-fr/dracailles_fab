import 'dart:async';

import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:fab_dracailles/models/game_player_model.dart';
import 'package:fab_dracailles/theme/fantasy_theme.dart';
import 'package:fab_dracailles/widgets/hero_art_crop.dart';
import 'package:fab_dracailles/widgets/ornate_frame.dart';
import 'package:flutter/material.dart';

class LifeTrackerWidget extends StatefulWidget {
  final GamePlayer gamePlayer;
  final bool invertMode;
  final void Function(int amount) onLifeChanged;
  // Shown as a small, faint readout near the seam - reading the opponent's
  // own big number means either deciphering it upside down or physically
  // turning the phone; this is always right-side up for whoever's tile
  // it's drawn in.
  final int opponentLife;

  const LifeTrackerWidget({
    super.key,
    required this.gamePlayer,
    this.invertMode = false,
    required this.onLifeChanged,
    required this.opponentLife,
  });

  @override
  LifeTrackerWidgetState createState() => LifeTrackerWidgetState();
}

class LifeTrackerWidgetState extends State<LifeTrackerWidget> {
  Timer? _longPressTimer;
  int _temporaryLifeChange = 0;
  Timer? _temporaryLifeTimer;
  // Bumped on every life change - keying the glow's TweenAnimationBuilder on
  // this retriggers its animation each time, giving the frame a brief pulse
  // instead of a static glow, without needing an AnimationController.
  int _pulseTick = 0;

  @override
  void initState() {
    super.initState();
  }

  void _adjustLife(int amount) {
    setState(() {
      if (widget.gamePlayer.life + amount >= -10) {
        widget.gamePlayer.adjustLife(amount);
        _pulseTick++;
      }
    });
  }

  void _lifeChangedHandle(int amount) {
    setState(() {
      widget.onLifeChanged(amount);
    });
  }

  void _showTemporaryLifeChange(int amount) {
    setState(() {
      _temporaryLifeChange += amount;
    });

    _temporaryLifeTimer?.cancel();
    _temporaryLifeTimer = Timer(const Duration(milliseconds: 800), () {
      _lifeChangedHandle(_temporaryLifeChange);
      setState(() {
        _temporaryLifeChange = 0;
      });
    });
  }

  void resetLife() {
    setState(() {
      widget.gamePlayer.resetLife();
    });
  }

  void _startLongPressTimer(int amount) {
    _adjustLife(amount);
    _showTemporaryLifeChange(amount);
    _longPressTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _adjustLife(amount);
      _showTemporaryLifeChange(amount);
    });
  }

  void _stopLongPressTimer() {
    _longPressTimer?.cancel();
  }

  // Full-opacity gold plus a dark outline instead of a half-transparent
  // parchment tint - the dim version read fine against the dark table but
  // nearly disappeared against a bright flat player color, since it had
  // no contrast mechanism besides opacity.
  TextStyle get _tapHintStyle => fantasyDisplay(
        fontSize: 34,
        color: FantasyPalette.gold,
      ).copyWith(shadows: const [
        Shadow(color: Colors.black54, blurRadius: 6),
        Shadow(color: Colors.black54, blurRadius: 2),
      ]);

  /// A plain "6" and "9" can look like each other read upside down - by
  /// the opponent glancing across, or in [opponentLife]'s own faint
  /// readout below. Anchoring a dot to the same corner (lower-right)
  /// regardless of which digit it is means a genuinely-rotated one shows
  /// its dot in the wrong corner (upper-left) instead of quietly landing
  /// on top of where the other digit's own dot would be.
  Widget _buildLifeNumber(
    int life, {
    required double fontSize,
    Color color = FantasyPalette.parchment,
  }) {
    final style = fantasyDisplay(fontSize: fontSize, color: color);
    if (life != 6 && life != 9) {
      return Text(life.toString(), style: style);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(life.toString(), style: style),
        Positioned(
          right: -fontSize * 0.05,
          bottom: fontSize * 0.02,
          child: Container(
            width: fontSize * 0.12,
            height: fontSize * 0.12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroArt(FabHero hero) {
    // Bordered cards follow a consistent template: title plate (with a
    // flourish that dips further down than the plate's own flat body) down
    // to a gold-scrollwork rules-box border. Measured pixel-by-pixel across
    // several samples (Dorinthea, Dorinthea Ironsong, Levia, Levia
    // Shadowborn Abomination): the title flourish's lowest point lands
    // anywhere up to ~12.6% of the image height, and the rules-box border's
    // earliest start is ~59.4% - the previous 12%/62% window clipped
    // straight through both, which is what was showing as a thin gold edge
    // at the top and bottom of the framed card. These add a safety margin
    // on top of the measured range instead of sitting right at it.
    // Full-art photos have no title bar and keep art almost to the very
    // bottom (HeroArtCrop's own defaults).
    return hero.isFullArt
        ? HeroArtCrop(assetPath: hero.photoPath)
        : HeroArtCrop(
            assetPath: hero.photoPath,
            left: 0.05,
            top: 0.14,
            right: 0.95,
            bottom: 0.575,
          );
  }

  /// A hero card framed on the dark table - see [_buildFlatColorFill] for
  /// the no-hero alternative.
  Widget _buildHeroCard(FabHero hero) {
    return ColoredBox(
      // Dark table instead of a flat player-color fill - the player's
      // color now lives in the frame's glow and the ambient tint below,
      // so a framed card reads as an object placed on the table rather
      // than the background itself.
      color: FantasyPalette.obsidian,
      child: Stack(
        children: [
          // Faint radial wash of the player's own color, centered
          // behind the frame - just enough to tint the table without
          // competing with the gold trim or the art.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    widget.gamePlayer.color.withValues(alpha: 0.30),
                    FantasyPalette.obsidian.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          LayoutBuilder(builder: (context, constraints) {
            // Flesh and Blood's own card ratio (63x88mm) - sizing the
            // frame to it is what lets the hero art inside sit close
            // to its native aspect instead of needing a heavy crop.
            const cardAspect = 63 / 88;
            // A bit bigger than the original pass (0.6/0.66) - there was
            // too much bare table around the card - but not pushed so far
            // that a plain, evenly-centered margin stops clearing
            // BannerMatchWidget's dead-center timer pill: a biased
            // push-down was tried instead and just made the margins
            // uneven (cramped at the outer edge, loose at the seam) for
            // no real benefit over simply keeping the card a bit smaller.
            var frameHeight = constraints.maxHeight * 0.68;
            var frameWidth = frameHeight * cardAspect;
            final maxFrameWidth = constraints.maxWidth * 0.74;
            if (frameWidth > maxFrameWidth) {
              frameWidth = maxFrameWidth;
              frameHeight = frameWidth / cardAspect;
            }
            // Smaller than the frame itself (was 0.62) - frees up enough
            // room that the card can actually use desiredDownShift below
            // instead of the slack being eaten entirely by the medallion.
            var medallionSize = frameWidth * 0.5;
            // The medallion overlaps the frame's bottom edge by half its
            // own size, so that's its actual contribution to the card's
            // total visual footprint - NOT frameHeight + medallionSize.
            // This used to be built as a Column with the medallion
            // Transform.translate'd up into the overlap: that only moves
            // where the medallion PAINTS, not the space the Column
            // reserves for it during layout, so the Column always thought
            // it needed the full frameHeight + medallionSize (no overlap
            // credited) - a hard cap keyed off the correct, smaller height
            // below never actually got to fire before the real, bigger
            // Column had already overflowed. Building it as a Stack sized
            // to the true visual height instead makes the two agree.
            var cardHeight = frameHeight + medallionSize * 0.5;
            final cardWidth =
                frameWidth > medallionSize ? frameWidth : medallionSize;
            // Hard cap: whatever the size multipliers above are tuned to,
            // the card must still fit the tile it's drawn in - a tall
            // narrow tile (a small phone, a bumped text/UI scale, …) can
            // make even a "reasonable looking" ratio run a few pixels
            // taller than what's actually available, which is what was
            // showing up as a RenderFlex overflow at the tile's edge.
            // Scaling every dimension down by the same factor keeps the
            // card's own proportions (and the art's crop) unchanged.
            if (cardHeight > constraints.maxHeight) {
              final shrink = constraints.maxHeight / cardHeight;
              frameHeight *= shrink;
              frameWidth *= shrink;
              medallionSize *= shrink;
              cardHeight = constraints.maxHeight;
            }

            // A plain Center() put the card right in the middle, but it
            // reads better nudged down a bit, toward the timer pill at the
            // seam, than dead-center. Shifting the already-sized card via
            // alignment (rather than e.g. a fixed-size spacer added to its
            // layout) doesn't grow it, so it's capped at whatever slack
            // actually exists above and below it - worst case it just
            // ends up back at dead center instead of overflowing.
            const desiredDownShift = 24.0;
            final slack = (constraints.maxHeight - cardHeight)
                .clamp(0.0, double.infinity);
            final halfSlack = slack / 2;
            final alignY = halfSlack > 0
                ? (desiredDownShift / halfSlack).clamp(0.0, 1.0)
                : 0.0;

            return Align(
              alignment: Alignment(0, alignY),
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(_pulseTick),
                          tween: Tween(begin: 1.35, end: 1.0),
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                          builder: (context, glowStrength, child) =>
                              OrnateFrame(
                            width: frameWidth,
                            height: frameHeight,
                            accentColor: widget.gamePlayer.color,
                            glowStrength: glowStrength,
                            child: child!,
                          ),
                          child: _buildHeroArt(hero),
                        ),
                      ),
                    ),
                    // Overlaps the frame's bottom edge like a card's own
                    // power/life gem, instead of floating bare digits
                    // over the art.
                    Positioned(
                      top: frameHeight - medallionSize * 0.5,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: medallionSize,
                          height: medallionSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: FantasyPalette.obsidianLight,
                            border: Border.all(
                              color: FantasyPalette.gold,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gamePlayer.color
                                    .withValues(alpha: 0.6),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: _buildLifeNumber(
                                  widget.gamePlayer.life,
                                  fontSize: medallionSize * 0.52,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// No hero picked: fills the whole tile with the player's flat color
  /// (like before the card-table redesign) instead of shrinking it down
  /// into a framed card - there's no art to frame, so a small swatch on a
  /// dark backdrop just wasted most of the tile.
  Widget _buildFlatColorFill() {
    return ColoredBox(
      color: widget.gamePlayer.color,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FittedBox(
            fit: BoxFit.contain,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_pulseTick),
              tween: Tween(begin: 1.1, end: 1.0),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: _buildLifeNumber(
                widget.gamePlayer.life,
                fontSize: 150,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.gamePlayer.hero;
    return Expanded(
      child: Transform(
        alignment: Alignment.center,
        transform: widget.invertMode
            ? Matrix4.rotationZ(3.14159) // 180° rotation
            : Matrix4.identity(),
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  hero != null ? _buildHeroCard(hero) : _buildFlatColorFill(),
            ),
            // The opponent's own number sits in their tile, the one that's
            // rotated for them - reading it means either decoding it
            // upside down or physically turning the phone. This small,
            // faint copy lives in THIS tile instead, so it's already right
            // side up here. Anchored to local bottom-left: for the normal
            // (non-inverted) tile that's screen bottom-left as-is, and the
            // inverted tile's own 180° rotation carries that same local
            // corner to screen top-right - each player gets it at "their
            // own bottom-left" without needing separate per-tile logic.
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0, bottom: 10.0),
                child: Opacity(
                  opacity: 0.45,
                  child: _buildLifeNumber(
                    widget.opponentLife,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // Faint tap-zone hints, out at the edges rather than hugging
            // the medallion - the card and its life total stay the clear
            // focal point, these just confirm which side does what.
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 18.0),
                child: Text(
                  '-',
                  style: _tapHintStyle,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: Text(
                  '+',
                  style: _tapHintStyle,
                ),
              ),
            ),
            if (_temporaryLifeChange != 0)
              // Proportional, not a fixed pixel offset, so it lands in
              // the same relative spot regardless of screen size. Side
              // follows the running total's sign, not whichever button
              // was tapped last - e.g. -1, -1, +1 is still net negative
              // (-1) so it stays on the left until the total itself goes
              // positive.
              Align(
                alignment:
                    Alignment(_temporaryLifeChange < 0 ? -0.6 : 0.6, -0.7),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: FantasyPalette.obsidianLight.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: FantasyPalette.gold),
                  ),
                  child: Text(
                    (_temporaryLifeChange > 0 ? "+" : "") +
                        _temporaryLifeChange.toString(),
                    style: fantasyDisplay(fontSize: 24),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _adjustLife(-1);
                      _showTemporaryLifeChange(-1);
                    },
                    onLongPressStart: (_) => _startLongPressTimer(-5),
                    onLongPressEnd: (_) => _stopLongPressTimer(),
                    onLongPressCancel: () => _stopLongPressTimer(),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _adjustLife(1);
                      _showTemporaryLifeChange(1);
                    },
                    onLongPressStart: (_) => _startLongPressTimer(5),
                    onLongPressEnd: (_) => _stopLongPressTimer(),
                    onLongPressCancel: () => _stopLongPressTimer(),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
