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
  /// How much of a bordered hero photo's top to crop away so the title
  /// bar's printed name doesn't show. Eyeballed against several bordered
  /// photos: the title ribbon (frame + text) consistently ends by ~10-13%
  /// of the image height, well above where a character's head starts, so
  /// 0.12 clears the name with a little margin to spare. Full-art photos
  /// keep the `HeroArtCrop` default of 0 instead (see its doc comment).
  static const double _borderedTopCrop = 0.12;

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
                  child: HeroArtCrop(
                    assetPath: widget.gamePlayer.hero!.photoPath,
                    top: widget.gamePlayer.hero!.isFullArt
                        ? 0.0
                        : _borderedTopCrop,
                  ),
                ),
              if (_temporaryLifeChange != 0)
                Positioned(
                  left: 300,
                  top: 100,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
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
                  ],
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
