import 'dart:async';

import 'package:fab_dracailles/models/game_player_model.dart';
import 'package:fab_dracailles/widgets/hero_art_crop.dart';
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

  @override
  void initState() {
    super.initState();
  }

  void _adjustLife(int amount) {
    setState(() {
      if (widget.gamePlayer.life + amount >= -10) {
        widget.gamePlayer.adjustLife(amount);
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Transform(
        alignment: Alignment.center,
        transform: widget.invertMode
            ? Matrix4.rotationZ(3.14159) // 180° rotation
            : Matrix4.identity(),
        child: Container(
          // The player color is always the base paint: if a hero is picked
          // but its image file hasn't been dropped in assets/images/heros/
          // yet, the image silently fails to draw and the color shows
          // through instead of a broken-asset error.
          color: widget.gamePlayer.color,
          child: Stack(
            children: [
              if (widget.gamePlayer.hero != null)
                Positioned.fill(
                  // Bordered cards follow a consistent template: title bar
                  // from 0-~12%, art from there down to ~62% (then a rules
                  // text box), confirmed across several samples. Full-art
                  // photos have no title bar and keep art almost to the
                  // very bottom (HeroArtCrop's own defaults).
                  child: widget.gamePlayer.hero!.isFullArt
                      ? HeroArtCrop(
                          assetPath: widget.gamePlayer.hero!.photoPath)
                      : HeroArtCrop(
                          assetPath: widget.gamePlayer.hero!.photoPath,
                          left: 0.05,
                          top: 0.12,
                          right: 0.95,
                          bottom: 0.62,
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
                  alignment: Alignment(
                      _temporaryLifeChange < 0 ? -0.6 : 0.6, -0.5),
                  child: Text(
                    (_temporaryLifeChange > 0 ? "+" : "") +
                        _temporaryLifeChange.toString(),
                    style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // The numbers below are a fixed design reference, not
                  // actual pixel sizes - FittedBox scales the whole row
                  // uniformly to fill whatever space this tile has, so it
                  // grows on a tablet and shrinks on a small phone instead
                  // of overflowing or looking tiny.
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 40.0),
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              widget.gamePlayer.life.toString(),
                              style: const TextStyle(
                                fontSize: 150,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 40.0),
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
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
      ),
    );
  }
}
