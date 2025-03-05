import 'dart:async';

import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/models/match_type_model.dart';
import 'package:fab_dracailles/theme/colors.dart';
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
  late List<HistoryEntry> _history;

  final int _dieSides = 6;
  int _rolledNumber = 1;
  bool _rolling = false;

  late MatchType _matchType;
  late int _timerDuration;
  late int _timeLeft;
  Timer? _timer;
  bool _timerStarted = false; // Track if the timer has started

  final List<Color> _colorsToSelect = ThemeColors.colorsPlayerGame;

  void initGame() {
    _timerDuration = _matchType.durationGame;
    _timeLeft = _matchType.durationGame;
    GamePlayer firstPlayer = GamePlayer(
        name: 'Joueur 1',
        color: _colorsToSelect[0],
        life: _matchType.lifeGamePlayer);
    GamePlayer secondPlayer = GamePlayer(
        name: 'Joueur 2',
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
    _timer?.cancel();
  }

  void _resetGame() {
    _players[0].life = _matchType.lifeGamePlayer;
    _players[1].life = _matchType.lifeGamePlayer;
    setState(() {
      _history = [
        HistoryEntry(
            lifePoints: _matchType.lifeGamePlayer, player: _players[0]),
        HistoryEntry(lifePoints: _matchType.lifeGamePlayer, player: _players[1])
      ];
      _timeLeft = _matchType.durationGame; // Reset the timer
      _timerDuration = _matchType.durationGame;
      _timerStarted = false; // Allow the timer to be started again
    });
    _timer?.cancel();
  }

  void _reversePlayers() {
    setState(() {
      _players = List.from(_players.reversed);
      _player1Key.currentState?.resetLife();
      _player2Key.currentState?.resetLife();
    });
  }

  Future<void> _rollDie() async {
    setState(() {
      _rolling = true;
    });

    for (int i = 0; i < 10; i++) {
      setState(() {
        _rolledNumber =
            (1 + (DateTime.now().millisecondsSinceEpoch % _dieSides));
      });
    }

    setState(() {
      _rolling = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('game.die.dieRoll',
            translationParams: {"sides": _dieSides.toString()})),
        content: Text(context.translate('game.die.dieRolled',
            translationParams: {"rolledNumber": _rolledNumber.toString()})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.translate('common.ok')),
          ),
        ],
      ),
    );
  }

  void changePlayersColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate("player.changeColorPlayers")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _players.asMap().entries.map((entry) {
            int index = entry.key;
            GamePlayer player = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      color: player.color,
                      alignment: Alignment.center,
                      child: Text(
                        player.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      selectPlayerColor(index);
                    },
                    child: Text(context.translate("player.changeColor")),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.translate("common.close")),
          ),
        ],
      ),
    );
  }

  void selectPlayerColor(int playerIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate("player.changeColorPlayerName",
            translationParams: {"name": _players[playerIndex].name})),
        content: Wrap(
          spacing: 10,
          children: _colorsToSelect.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _players[playerIndex].color = color;
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                changePlayersColor();
              },
              child: CircleAvatar(backgroundColor: color),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.translate('common.cancel')),
          ),
        ],
      ),
    );
  }

  void showHistory() {
    List<HistoryEntry> player0History =
        _history.where((entry) => entry.player == _players[0]).toList();
    List<HistoryEntry> player1History =
        _history.where((entry) => entry.player == _players[1]).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Entête avec les noms des joueurs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _players[0].name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _players[0].color,
                    ),
                  ),
                  Text(
                    _players[1].name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: _players[1].color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Utilisation de SingleChildScrollView pour le défilement
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Row(
                    children: [
                      // Historique du joueur 0
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: player0History.map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                entry.lifePoints.toString(),
                                style: TextStyle(
                                  fontSize:
                                      entry == player0History.last ? 24 : 16,
                                  color: _players[0].color,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Séparateur vertical
                      Container(
                        width: 1,
                        color: Colors.grey.shade400,
                      ),
                      // Historique du joueur 1
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: player1History.map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                entry.lifePoints.toString(),
                                style: TextStyle(
                                  fontSize:
                                      entry == player1History.last ? 24 : 16,
                                  color: _players[1].color,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton de fermeture
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                  backgroundColor: ThemeColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  context.translate('common.cancel'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.translate('game.settings'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.translate('game.matchType')),
                DropdownButton<MatchTypeEnum>(
                  value: _matchType.type,
                  dropdownColor: Colors.white,
                  focusColor: Colors.white,
                  items: MatchTypeEnum.values.map((matchType) {
                    return DropdownMenuItem(
                      value: matchType,
                      child: Text(matchType.name,
                          style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _matchType = MatchType(
                          type: value,
                          durationGame: MatchType.getDurationByType(value),
                          lifeGamePlayer:
                              MatchType.getLifeGamePlayerByType(value),
                        );
                        _resetGame(); // Reset du jeu si nécessaire
                      });
                    }
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.translate('common.cancel')),
          ),
        ],
      ),
    );
  }

  void startTimer() {
    _timeLeft = _timerDuration; // Reset timer to match duration
    setState(() {
      _timeLeft--; // Reset timer to match duration
      _timerStarted = true; // Disable logo click
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_timerStarted) return;

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer!.cancel(); // Stop timer when it reaches zero
        }
      });
    });
  }

  void toggleTimer() {
    setState(() {
      _timerStarted = !_timerStarted;
    });
  }

  void addToHistory(GamePlayer player) {
    setState(() {
      _history = [
        ..._history,
        HistoryEntry(lifePoints: player.life, player: player)
      ];
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
          Align(
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Action bar background (full width)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left-side buttons
                      Row(
                        children: [
                          IconButton(
                            onPressed: showSettings,
                            icon: const Icon(Icons.settings, size: 30),
                            tooltip: context.translate('game.settings'),
                          ),
                          IconButton(
                            onPressed: showHistory,
                            icon: const Icon(Icons.history, size: 30),
                            tooltip: context.translate("game.history"),
                          ),
                          IconButton(
                            onPressed: _rollDie,
                            icon: const Icon(Icons.casino, size: 30),
                            tooltip: context.translate("game.die.rollDie"),
                          ),
                        ],
                      ),

                      // Right-side buttons
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => changePlayersColor(),
                            icon: const Icon(Icons.color_lens, size: 30),
                            tooltip: context.translate("player.changeColorPlayers"),
                          ),
                          IconButton(
                            onPressed: _reversePlayers,
                            icon: const Icon(Icons.swap_horiz, size: 30),
                            tooltip: context.translate("game.swapPlayer"),
                          ),
                          IconButton(
                            onPressed: _resetGame,
                            icon: const Icon(Icons.refresh, size: 30),
                            tooltip: context.translate("game.resetGame"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Logo placed on top of the action bar
                Positioned(
                  top: -37, // Adjust to ensure overlap
                  child: GestureDetector(
                    onTap: _timerDuration == _timeLeft
                        ? startTimer
                        : toggleTimer, // Disable logo tap after start
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Image.asset(
                                'assets/images/logo_dracailles_min.png',
                                height: 100,
                              ),
                              if (!_timerStarted && _timerDuration != _timeLeft)
                                Center(
                                  child: Icon(
                                    Icons.pause_circle_filled,
                                    size: 100,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                            ],
                          ),
                          if (_timerDuration != _timeLeft)
                            Text(
                              '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
