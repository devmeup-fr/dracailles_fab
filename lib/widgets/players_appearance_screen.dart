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
  final void Function(List<GamePlayer> players) setPlayers;
  final void Function(MatchTypeEnum type) applyMatchType;

  const PlayersAppearanceScreen({
    super.key,
    required this.players,
    required this.colors,
    required this.setPlayers,
    required this.applyMatchType,
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
        startOnHeroTab: widget.players[idx].hero != null,
        startOnYoung: fabHeroesYoung.contains(widget.players[idx].hero),
        onColorSelected: (color) async {
          widget.players[idx].color = color;
          widget.players[idx].hero = null;
          widget.setPlayers(widget.players);
          await savePlayerColor(playerIndex, color);
          await savePlayerHero(playerIndex, null);
        },
        onHeroSelected: (hero, isYoung) async {
          widget.players[idx].hero = hero;
          widget.setPlayers(widget.players);
          // Resets both players to the format's default life, then this
          // player's life is overridden to the hero's own printed total
          // (some heroes deviate from the usual 40/20).
          widget.applyMatchType(
              isYoung ? MatchTypeEnum.sage : MatchTypeEnum.classicConstructed);
          widget.players[idx].life = hero.life;
          widget.setPlayers(widget.players);
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
        backgroundImage: player.hero != null
            ? AssetImage(player.hero!.thumbnailPath)
            : null,
        onBackgroundImageError:
            player.hero != null ? (exception, stackTrace) {} : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Match screen shows players[1] at the top (inverted) and
            // players[0] at the bottom, so the bubbles follow that order.
            _buildBubble(widget.players[1]),
            const SizedBox(height: 28),
            _buildBubble(widget.players[0]),
          ],
        ),
      ),
    );
  }
}
