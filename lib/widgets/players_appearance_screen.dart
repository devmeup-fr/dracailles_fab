import 'dart:math' as math;

import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:fab_dracailles/core/utils/player_color_prefs.dart';
import 'package:fab_dracailles/models/game_player_model.dart';
import 'package:fab_dracailles/models/match_type_model.dart';
import 'package:fab_dracailles/widgets/hero_color_picker_screen.dart';
import 'package:flutter/material.dart';

/// Shown via [showDialog]: just the two player bubbles, top = player 1,
/// bottom = player 2 (a flat color, or the hero thumbnail once one is
/// picked). No names, no labels — tapping a bubble pushes
/// [HeroColorPickerScreen] to change it, and there is nothing else here to
/// accidentally stack when going back and forth between players.
class PlayersAppearanceScreen extends StatefulWidget {
  final List<GamePlayer> players;
  final List<Color> colors;
  final MatchType matchType;
  final void Function(List<GamePlayer> players) setPlayers;
  // Switches the match between Classic Constructed and Silver Age/Young
  // based on both players' current heroes (not just whichever one was
  // just picked) - called after this player's hero/color is applied.
  final void Function() syncMatchType;
  // True when opened from the top player's (rotated) badge, so this dialog
  // and any screen it pushes render upside down and read right-side up for
  // them - same idea as LifeTrackerWidget's own invertMode.
  final bool inverted;

  const PlayersAppearanceScreen({
    super.key,
    required this.players,
    required this.colors,
    required this.matchType,
    required this.setPlayers,
    required this.syncMatchType,
    this.inverted = false,
  });

  @override
  State<PlayersAppearanceScreen> createState() =>
      _PlayersAppearanceScreenState();
}

class _PlayersAppearanceScreenState extends State<PlayersAppearanceScreen> {
  Future<void> _editPlayer(int playerIndex) async {
    final idx = widget.players.indexWhere((p) => p.index == playerIndex);
    if (idx == -1) return;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HeroColorPickerScreen(
        colors: widget.colors,
        inverted: widget.inverted,
        startOnHeroTab: widget.players[idx].hero != null,
        // A hero already picked wins; otherwise default to whichever the
        // match is already running as (so a SAGE match suggests Young
        // heroes instead of always defaulting to Adult).
        startOnYoung: widget.players[idx].hero != null
            ? fabHeroesYoung.contains(widget.players[idx].hero)
            : widget.matchType.type != MatchTypeEnum.classicConstructed,
        onColorSelected: (color) async {
          widget.players[idx].color = color;
          widget.players[idx].hero = null;
          widget.setPlayers(widget.players);
          widget.syncMatchType();
          await savePlayerColor(playerIndex, color);
          await savePlayerHero(playerIndex, null);
        },
        onHeroSelected: (hero, isYoung) async {
          widget.players[idx].hero = hero;
          widget.players[idx].life = hero.life;
          widget.setPlayers(widget.players);
          widget.syncMatchType();
          await savePlayerHero(playerIndex, hero);
        },
      ),
    ));
    if (!mounted) return;
    setState(() {}); // Refresh the bubble with whatever was just picked.
  }

  Widget _buildBubble(GamePlayer player) {
    return GestureDetector(
      onTap: () => _editPlayer(player.index),
      child: CircleAvatar(
        radius: 48,
        backgroundColor: player.color,
        backgroundImage:
            player.hero != null ? AssetImage(player.hero!.thumbnailPath) : null,
        onBackgroundImageError:
            player.hero != null ? (exception, stackTrace) {} : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: widget.inverted ? math.pi : 0,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Match screen shows players[1] at the top (inverted) and
            // players[0] at the bottom. The whole dialog gets rotated 180°
            // above when opened from the top badge, which would otherwise
            // flip this order too - so swap it here first, to cancel that
            // out and keep each bubble next to its actual player.
            children: widget.inverted
                ? [
                    _buildBubble(widget.players[0]),
                    const SizedBox(height: 28),
                    _buildBubble(widget.players[1]),
                  ]
                : [
                    _buildBubble(widget.players[1]),
                    const SizedBox(height: 28),
                    _buildBubble(widget.players[0]),
                  ],
          ),
        ),
      ),
    );
  }
}
