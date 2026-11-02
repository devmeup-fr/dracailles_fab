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

  const LifeTrackerWidget({
    super.key,
    required this.gamePlayer,
    this.invertMode = false,
    required this.onLifeChanged,
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

  Widget _buildHeroArt(FabHero hero) {
    // Bordered cards follow a consistent template: title bar from 0-~12%,
    // art from there down to ~62% (then a rules text box), confirmed across
    // several samples. Full-art photos have no title bar and keep art
    // almost to the very bottom (HeroArtCrop's own defaults). The frame
    // below is now sized close to the source photo's own aspect ratio, so
    // this crop barely has to zoom to cover it - unlike the old edge-to-edge
    // tile, which forced a much heavier (and blurrier) upscale.
    return hero.isFullArt
        ? HeroArtCrop(assetPath: hero.photoPath)
        : HeroArtCrop(
            assetPath: hero.photoPath,
            left: 0.05,
            top: 0.12,
            right: 0.95,
            bottom: 0.62,
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
          Center(
            child: LayoutBuilder(builder: (context, constraints) {
              // Flesh and Blood's own card ratio (63x88mm) - sizing the
              // frame to it is what lets the hero art inside sit close
              // to its native aspect instead of needing a heavy crop.
              const cardAspect = 63 / 88;
              var frameHeight = constraints.maxHeight * 0.6;
              var frameWidth = frameHeight * cardAspect;
              final maxFrameWidth = constraints.maxWidth * 0.66;
              if (frameWidth > maxFrameWidth) {
                frameWidth = maxFrameWidth;
                frameHeight = frameWidth / cardAspect;
              }
              final medallionSize = frameWidth * 0.62;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey(_pulseTick),
                    tween: Tween(begin: 1.35, end: 1.0),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                    builder: (context, glowStrength, child) => OrnateFrame(
                      width: frameWidth,
                      height: frameHeight,
                      accentColor: widget.gamePlayer.color,
                      glowStrength: glowStrength,
                      child: child!,
                    ),
                    child: _buildHeroArt(hero),
                  ),
                  // Overlaps the frame's bottom edge like a card's own
                  // power/life gem, instead of floating bare digits
                  // over the art.
                  Transform.translate(
                    offset: Offset(0, -medallionSize * 0.5),
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
                            color:
                                widget.gamePlayer.color.withValues(alpha: 0.6),
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
                            child: Text(
                              widget.gamePlayer.life.toString(),
                              style: fantasyDisplay(
                                fontSize: medallionSize * 0.52,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
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
              child: Text(
                widget.gamePlayer.life.toString(),
                style: fantasyDisplay(fontSize: 150, color: Colors.white),
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
            // Faint tap-zone hints, out at the edges rather than hugging
            // the medallion - the card and its life total stay the clear
            // focal point, these just confirm which side does what.
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 18.0),
                child: Text(
                  '-',
                  style: fantasyDisplay(
                    fontSize: 34,
                    color: FantasyPalette.parchmentDim.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 18.0),
                child: Text(
                  '+',
                  style: fantasyDisplay(
                    fontSize: 34,
                    color: FantasyPalette.parchmentDim.withValues(alpha: 0.5),
                  ),
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
