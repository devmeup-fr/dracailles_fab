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
  // Tracks reversePlayers() state so it can be persisted/restored - without
  // this, an app restart always put the original order back, undoing a
  // reversal the player had made before.
  bool _playersReversed = false;

  void initGame() {
    _winner = null;
    GamePlayer firstPlayer = GamePlayer(
        index: 0, color: ThemeColors.primary, life: _matchType.lifeGamePlayer);
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
    final savedHistory = await Future.wait(
      [getPlayerHistory(0), getPlayerHistory(1)],
    );
    final reversed = await getPlayersReversed();
    if (!mounted) return;
    setState(() {
      // _players[i] is still in its freshly-created, un-reversed order here
      // (index i matches GamePlayer.index i) - restoring each slot's saved
      // data by that same i is what keeps it matched to the right player
      // even if the list gets reordered below.
      final newHistory = <HistoryEntry>[];
      for (var i = 0; i < _players.length; i++) {
        final color = savedColors[i];
        if (color != null) _players[i].color = color;
        final hero = savedHeroes[i];
        if (hero != null) _players[i].hero = hero;
        // A saved life (an ongoing match) wins; otherwise fall back to the
        // hero's own printed total (some heroes deviate from 40/20), then
        // to the format's default.
        _players[i].life =
            savedLife[i] ?? _players[i].hero?.life ?? _matchType.lifeGamePlayer;
        final points = savedHistory[i];
        if (points.isEmpty) {
          newHistory.add(
              HistoryEntry(lifePoints: _players[i].life, player: _players[i]));
        } else {
          newHistory.addAll(points
              .map((p) => HistoryEntry(lifePoints: p, player: _players[i])));
        }
      }
      _history = newHistory;
      _syncMatchTypeToHeroes();
      // Applied last, after each player's own data is in place, so this
      // only reorders the list (matching whichever layout was left before
      // closing the app) without touching which data belongs to whom.
      if (reversed) {
        _playersReversed = true;
        _players = List.from(_players.reversed);
      }
    });
    _persistAllLife();
    _persistHistory();
  }

  Future<void> _persistLife(GamePlayer player) =>
      savePlayerLife(player.index, player.life);

  Future<void> _persistAllLife() => Future.wait(_players.map(_persistLife));

  Future<void> _persistHistory() =>
      Future.wait(_players.map((player) => savePlayerHistory(
          player.index,
          _history
              .where((entry) => entry.player == player)
              .map((entry) => entry.lifePoints)
              .toList())));

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
    // Appended, not rebuilt by position - _history can now hold several
    // restored entries per player (not just one each), so overwriting
    // _history[i] by index would mix up whose entry is whose as soon as
    // one player has more points than the other.
    for (final player in _players) {
      if (player.hero == null) {
        player.life = _matchType.lifeGamePlayer;
        _history.add(HistoryEntry(lifePoints: player.life, player: player));
      }
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
    _persistHistory();
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
    _persistHistory();
    _enableWakelockIfNeeded();
  }

  void _reversePlayers() {
    setState(() {
      _players = List.from(_players.reversed);
      _playersReversed = !_playersReversed;
      _player1Key.currentState?.resetLife();
      _player2Key.currentState?.resetLife();
    });
    savePlayersReversed(_playersReversed);
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
