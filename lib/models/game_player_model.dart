import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:flutter/material.dart';

class GamePlayer {
  int index;
  int life;
  Color color;

  /// Hero picked to represent this player for the current match, if any.
  /// When set, its image (once dropped in assets/images/heros/) replaces
  /// the flat [color] as the player's background.
  FabHero? hero;

  GamePlayer({
    required this.index,
    this.life = 40,
    this.color = Colors.blueAccent,
    this.hero,
  });

  void resetLife() {
    life = 40;
  }

  void adjustLife(int amount) {
    life += amount;
  }
}
