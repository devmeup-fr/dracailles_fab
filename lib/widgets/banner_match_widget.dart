import 'dart:async';

import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/models/game_player_model.dart';
import 'package:fab_dracailles/models/match_type_model.dart';
import 'package:fab_dracailles/screens/match_screen.dart';
import 'package:fab_dracailles/theme/colors.dart';
import 'package:flutter/material.dart';

class BannerMatchWidget extends StatefulWidget {
  final Function resetGame;
  final Function reversePlayers;
  final List<GamePlayer> players;
  final List<HistoryEntry> history;
  final MatchType matchType;
  final Function setMatchType;

  const BannerMatchWidget(
      {super.key,
      required this.resetGame,
      required this.reversePlayers,
      required this.players,
      required this.history,
      required this.matchType,
      required this.setMatchType});

  @override
  State<BannerMatchWidget> createState() => _BannerMatchWidgetState();
}

class _BannerMatchWidgetState extends State<BannerMatchWidget> {
  int _dieSides = 6;
  Timer? _timer;
  late int _timerDuration;
  late int _timeLeft;
  bool _timerStarted = false; // Track if the timer has started

  final List<Color> _colorsToSelect = ThemeColors.colorsPlayerGame;

  void initGame() {
    _timeLeft = widget.matchType.durationGame; // Reset the timer
    _timerDuration = widget.matchType.durationGame;
    _timerStarted = false; // Allow the timer to be started again
  }

  @override
  void initState() {
    super.initState();
    initGame();
  }

  @override
  dispose() {
    super.dispose();
    _timer?.cancel();
  }

  Future<void> _rollDie() async {
    int? rolledNumber = _roll(_dieSides);
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.translate('game.die.dieRoll',
                    translationParams: {"sides": _dieSides.toString()})),
                const Icon(Icons.casino, color: ThemeColors.primary),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _dieSides,
                  dropdownColor: Colors.white,
                  focusColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: context.translate('game.die.dieType'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items: [2, 3, 4, 5, 6].map((sides) {
                    return DropdownMenuItem(
                      value: sides,
                      child: Text("d$sides"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _dieSides = value);
                      setModalState(() => rolledNumber = null);

                      Future.delayed(const Duration(milliseconds: 500), () {
                        setModalState(() {
                          rolledNumber = _roll(value);
                        });
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  context.translate('game.die.dieRolled'),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    "${rolledNumber ?? '-'}",
                    key: ValueKey(rolledNumber),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.replay),
                  label: Text(context.translate('game.die.rollAgain')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setModalState(() => rolledNumber = null);

                    Future.delayed(const Duration(milliseconds: 500), () {
                      setModalState(() {
                        rolledNumber = _roll(_dieSides);
                      });
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.translate('common.ok')),
              ),
            ],
          );
        });
      },
    );
  }

  int _roll(int sides) {
    return 1 + (DateTime.now().millisecondsSinceEpoch % sides);
  }

  void changePlayersColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate("player.changeColorPlayers")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.players.asMap().entries.map((entry) {
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
            translationParams: {"name": widget.players[playerIndex].name})),
        content: Wrap(
          spacing: 10,
          children: _colorsToSelect.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  widget.players[playerIndex].color = color;
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
    List<HistoryEntry> player0History = widget.history
        .where((entry) => entry.player == widget.players[0])
        .toList();
    List<HistoryEntry> player1History = widget.history
        .where((entry) => entry.player == widget.players[1])
        .toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                    widget.players[0].name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: widget.players[0].color,
                    ),
                  ),
                  Text(
                    widget.players[1].name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: widget.players[1].color,
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
                                  color: widget.players[0].color,
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
                                  color: widget.players[1].color,
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
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Row(
                    children: [
                      const Icon(Icons.settings, color: Colors.black54),
                      const SizedBox(width: 10),
                      Text(
                        context.translate('game.settings'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 25),

                  // Type de match
                  Text(
                    context.translate('game.matchType'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MatchTypeEnum>(
                    initialValue: widget.matchType.type,
                    dropdownColor: Colors.white,
                    focusColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: MatchTypeEnum.values.map((matchType) {
                      return DropdownMenuItem(
                        value: matchType,
                        child: Text(matchType.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        widget.setMatchType(MatchType(
                          type: value,
                          durationGame: MatchType.getDurationByType(value),
                          lifeGamePlayer:
                              MatchType.getLifeGamePlayerByType(value),
                        ));
                        widget.resetGame();
                        _timer?.cancel();
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Joueur 1
                  Text(
                    "${context.translate('player.entityName')} 1",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildPlayerTile(widget.players[0], 1, setModalState),
                  const SizedBox(height: 16),

                  // Joueur 2
                  Text(
                    "${context.translate('player.entityName')} 2",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildPlayerTile(widget.players[1], 2, setModalState),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.translate('common.cancel')),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildPlayerTile(GamePlayer player, int index,
      void Function(void Function()) setModalState) {
    return GestureDetector(
      onTap: () => _selectOrCreatePlayer(index, setModalState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              player.name.isEmpty
                  ? context.translate('player.create')
                  : player.name,
              style: TextStyle(
                fontSize: 16,
                color: player.name.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
            const Icon(Icons.edit, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _selectOrCreatePlayer(
      int playerNumber, void Function(void Function()) parentSetModalState) {
    String tempName = widget.players[playerNumber - 1].name;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(context.translate("player.selectPlayer")),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: tempName,
                  decoration: InputDecoration(
                    labelText: context.translate("player.name"),
                  ),
                  onChanged: (value) {
                    setModalState(() => tempName = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.translate('common.cancel')),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.players[playerNumber - 1].name = tempName;
                  });
                  parentSetModalState(
                      () {}); // Force rafraîchissement modale principale
                  Navigator.of(context).pop();
                },
                child: Text(context.translate("player.create")),
              ),
            ],
          );
        });
      },
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

  @override
  Widget build(BuildContext context) {
    return Align(
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
                      onPressed: () => widget.reversePlayers(),
                      icon: const Icon(Icons.swap_horiz, size: 30),
                      tooltip: context.translate("game.swapPlayer"),
                    ),
                    IconButton(
                      onPressed: () {
                        widget.resetGame();
                        _timer?.cancel();
                      },
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
                              color: Colors.white.withValues(alpha: 0.8),
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
    );
  }
}
