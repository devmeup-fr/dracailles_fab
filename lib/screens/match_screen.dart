import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/models/match_type_model.dart';
import 'package:fab_dracailles/theme/colors.dart';
import 'package:fab_dracailles/widgets/banner_match_widget.dart';
import 'package:flutter/material.dart';

import '../models/game_player_model.dart';
import '../widgets/life_tracker_widget.dart';

class HistoryEntry {
  final int lifePoints;
  final GamePlayer player;

  HistoryEntry({
    required this.lifePoints,
    required this.player,
  });
}

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<LifeTrackerWidgetState> _player1Key = GlobalKey();
  final GlobalKey<LifeTrackerWidgetState> _player2Key = GlobalKey();

  late List<GamePlayer> _players;
  GamePlayer? _winner;
  late List<HistoryEntry> _history;

  late MatchType _matchType;
  final List<Color> _colorsToSelect = ThemeColors.colorsPlayerGame;

  void initGame() {
    _winner = null;
    GamePlayer firstPlayer = GamePlayer(
        index: 0,
        name: '',
        color: _colorsToSelect[0],
        life: _matchType.lifeGamePlayer);
    GamePlayer secondPlayer = GamePlayer(
        index: 1,
        name: '',
        color: _colorsToSelect[1],
        life: _matchType.lifeGamePlayer);
    _players = [
      firstPlayer,
      secondPlayer,
    ];
    _history = [
      HistoryEntry(lifePoints: _matchType.lifeGamePlayer, player: firstPlayer),
      HistoryEntry(lifePoints: _matchType.lifeGamePlayer, player: secondPlayer)
    ];
  }

  @override
  void initState() {
    super.initState();
    _matchType = MatchType.initMatch();
    initGame();
  }

  @override
  dispose() {
    super.dispose();
  }

  void addToHistory(GamePlayer player) {
    setState(() {
      _history = [
        ..._history,
        HistoryEntry(lifePoints: player.life, player: player)
      ];
    });
    _checkGameOver();
  }

  void _checkGameOver() {
    if (_players[0].life <= 0) {
      _winner = _players[1]; // Player 2 wins
      _showWinnerDialog();
    } else if (_players[1].life <= 0) {
      _winner = _players[0]; // Player 1 wins
      _showWinnerDialog();
    }
  }

  // Show winner dialog when game is over
  void _showWinnerDialog() {
    if (_winner == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('game.winner')),
        content:
            Text('$context.translate("game.congratulations") ${_winner!.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.translate('common.ok')),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    _players[0].life = _matchType.lifeGamePlayer;
    _players[1].life = _matchType.lifeGamePlayer;
    _winner = null;

    setState(() {
      _history = [
        HistoryEntry(
            lifePoints: _matchType.lifeGamePlayer, player: _players[0]),
        HistoryEntry(lifePoints: _matchType.lifeGamePlayer, player: _players[1])
      ];
    });
  }

  void _reversePlayers() {
    setState(() {
      _players = List.from(_players.reversed);
      _player1Key.currentState?.resetLife();
      _player2Key.currentState?.resetLife();
    });
  }

  void _setPlayers(List<GamePlayer> players) {
    setState(() {
      _players = players;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // Players and their life trackers
          Column(
            children: [
              LifeTrackerWidget(
                gamePlayer: _players[1],
                invertMode: true,
                onLifeChanged: (amount) {
                  addToHistory(_players[1]);
                },
              ),
              LifeTrackerWidget(
                gamePlayer: _players[0],
                onLifeChanged: (amount) {
                  addToHistory(_players[0]);
                },
              ),
            ],
          ),
          // Centered logo and action bar in a stacked layout
          BannerMatchWidget(
              reversePlayers: _reversePlayers,
              resetGame: _resetGame,
              players: _players,
              setPlayers: _setPlayers,
              history: _history,
              matchType: _matchType,
              setMatchType: (MatchType value) => setState(() {
                    _matchType = value;
                  }))
        ],
      ),
    );
  }
}
