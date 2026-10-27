import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:fab_dracailles/core/utils/player_color_prefs.dart';
import 'package:fab_dracailles/models/match_type_model.dart';
import 'package:fab_dracailles/theme/colors.dart';
import 'package:fab_dracailles/widgets/banner_match_widget.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey<LifeTrackerWidgetState> _player1Key = GlobalKey();
  final GlobalKey<LifeTrackerWidgetState> _player2Key = GlobalKey();

  late List<GamePlayer> _players;
  GamePlayer? _winner;
  late List<HistoryEntry> _history;

  late MatchType _matchType;

  void initGame() {
    _winner = null;
    GamePlayer firstPlayer = GamePlayer(
        index: 0,
        color: ThemeColors.primary,
        life: _matchType.lifeGamePlayer);
    GamePlayer secondPlayer = GamePlayer(
        index: 1,
        color: ThemeColors.secondary,
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
    WidgetsBinding.instance.addObserver(this);
    _enableWakelockIfNeeded();
    _loadSavedAppearance();
  }

  /// Restores the color/hero/life players had last time, so they don't have
  /// to re-select them at the start of every game, and so Android killing
  /// the app in the background (not just a user force-close) doesn't look
  /// like life points silently resetting.
  Future<void> _loadSavedAppearance() async {
    final savedColors = await Future.wait(
      [getPlayerColor(0), getPlayerColor(1)],
    );
    final savedHeroes = await Future.wait(
      [getPlayerHero(0), getPlayerHero(1)],
    );
    final savedLife = await Future.wait(
      [getPlayerLife(0), getPlayerLife(1)],
    );
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _players.length; i++) {
        final color = savedColors[i];
        if (color != null) _players[i].color = color;
        final hero = savedHeroes[i];
        if (hero != null) _players[i].hero = hero;
        // A saved life (an ongoing match) wins; otherwise fall back to the
        // hero's own printed total (some heroes deviate from 40/20), then
        // to the format's default.
        _players[i].life = savedLife[i] ??
            _players[i].hero?.life ??
            _matchType.lifeGamePlayer;
        _history[i] =
            HistoryEntry(lifePoints: _players[i].life, player: _players[i]);
      }
      _syncMatchTypeToHeroes();
    });
    _persistAllLife();
  }

  Future<void> _persistLife(GamePlayer player) =>
      savePlayerLife(player.index, player.life);

  Future<void> _persistAllLife() => Future.wait(_players.map(_persistLife));

  /// Switches between Classic Constructed and Silver Age/Young based on
  /// whether either player currently has a Young hero, so a hero restored
  /// at startup gets the right format from the first frame (banner_match_
  /// widget.dart does the same thing when a hero is picked in-session) -
  /// the timer duration and the default life for a player without their
  /// own hero both depend on the format. No-ops if it's already right.
  void _syncMatchTypeToHeroes() {
    final wantsYoung =
        _players.any((p) => p.hero != null && fabHeroesYoung.contains(p.hero));
    final target =
        wantsYoung ? MatchTypeEnum.sage : MatchTypeEnum.classicConstructed;
    if (_matchType.type == target) return;
    _matchType = MatchType(
      type: target,
      durationGame: MatchType.getDurationByType(target),
      lifeGamePlayer: MatchType.getLifeGamePlayerByType(target),
    );
    for (final player in _players) {
      if (player.hero == null) player.life = _matchType.lifeGamePlayer;
    }
    for (var i = 0; i < _history.length; i++) {
      _history[i] =
          HistoryEntry(lifePoints: _players[i].life, player: _players[i]);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enableWakelockIfNeeded();
    } else {
      _disableWakelock();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableWakelock();
    super.dispose();
  }

  Future<void> _enableWakelockIfNeeded() async {
    if (_winner == null) await WakelockPlus.enable();
  }

  Future<void> _disableWakelock() async {
    await WakelockPlus.disable();
  }

  void addToHistory(GamePlayer player) {
    setState(() {
      _history = [
        ..._history,
        HistoryEntry(lifePoints: player.life, player: player)
      ];
    });
    _persistLife(player);
    _checkGameOver();
  }

  void _checkGameOver() {
    if (_players[0].life <= 0) {
      _winner = _players[1]; // Player 2 wins
      _disableWakelock();
    } else if (_players[1].life <= 0) {
      _winner = _players[0]; // Player 1 wins
      _disableWakelock();
    }
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
    _persistAllLife();
    _enableWakelockIfNeeded();
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
    _persistAllLife();
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
