import 'dart:async';

import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/core/utils/player_color_prefs.dart';
import 'package:fab_dracailles/models/game_player_model.dart';
import 'package:fab_dracailles/models/match_type_model.dart';
import 'package:fab_dracailles/screens/match_screen.dart';
import 'package:fab_dracailles/theme/colors.dart';
import 'package:fab_dracailles/widgets/devmeup_widget.dart';
import 'package:fab_dracailles/widgets/radial_menu_widget.dart';
import 'package:flutter/material.dart';

class BannerMatchWidget extends StatefulWidget {
  final Function resetGame;
  final Function reversePlayers;
  final List<GamePlayer> players;
  final Function setPlayers;
  final List<HistoryEntry> history;
  final MatchType matchType;
  final Function setMatchType;

  const BannerMatchWidget(
      {super.key,
      required this.resetGame,
      required this.reversePlayers,
      required this.players,
      required this.setPlayers,
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
  bool _timerStarted = false;
  bool _timerPause = false;

  OverlayEntry? Entry;
  final GlobalKey _logoKey = GlobalKey();
  final LayerLink _logoLink = LayerLink();

  final List<Color> _colorsToSelect = ThemeColors.colorsPlayerGame;

  void initGame() {
    _timeLeft = widget.matchType.durationGame;
    _timerDuration = widget.matchType.durationGame;
    _timerStarted = false;
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

  String _playerLabel(BuildContext context, GamePlayer player) =>
      player.hero?.name ??
      "${context.translate('player.entityName')} ${player.index + 1}";

  void changePlayersColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate("player.changeColorPlayers")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              widget.players.reversed.toList().asMap().entries.map((entry) {
            GamePlayer player = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  if (player.hero != null)
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(player.hero!.thumbnailPath),
                      onBackgroundImageError: (exception, stackTrace) {},
                      backgroundColor: player.color,
                    )
                  else
                    CircleAvatar(radius: 20, backgroundColor: player.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_playerLabel(context, player)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      selectPlayerAppearance(player.index,
                          onApplied: changePlayersColor);
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

  /// Applies a match format: updates duration/life (via [MatchType]), resets
  /// both players' life to the new total, and restarts the timer state.
  void _applyMatchType(MatchTypeEnum value) {
    int duration = MatchType.getDurationByType(value);
    widget.setMatchType(MatchType(
      type: value,
      durationGame: duration,
      lifeGamePlayer: MatchType.getLifeGamePlayerByType(value),
    ));
    initGame();
    widget.resetGame();
    _timer?.cancel();
    setState(() {
      _timeLeft = duration;
      _timerDuration = duration;
      _timerStarted = false;
      _timerPause = false;
    });
  }

  /// Opens the color/hero picker for [playerIndex]. [onApplied] runs after
  /// a pick closes the picker - pass [changePlayersColor] to reopen that
  /// list (when entering from there), or leave it null when the caller
  /// (e.g. the Settings dialog) already rebuilds itself on its own, so we
  /// don't stack an extra, unrelated dialog on top of it.
  void selectPlayerAppearance(int playerIndex, {VoidCallback? onApplied}) {
    int indexOfPlayerByIndex(List<GamePlayer> players, int wantedIndex) =>
        players.indexWhere((p) => p.index == wantedIndex);

    int tab = 0; // 0 = couleur, 1 = héros
    bool showYoung = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          Widget colorGrid() => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _colorsToSelect.map((color) {
                  return GestureDetector(
                    onTap: () async {
                      List<GamePlayer> updatePlayers = widget.players;
                      final idx =
                          indexOfPlayerByIndex(updatePlayers, playerIndex);
                      if (idx != -1) {
                        updatePlayers[idx].color = color;
                        updatePlayers[idx].hero = null;
                      }
                      widget.setPlayers(updatePlayers);
                      await savePlayerColor(playerIndex, color);
                      await savePlayerHero(playerIndex, null);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      onApplied?.call();
                    },
                    child: CircleAvatar(radius: 28, backgroundColor: color),
                  );
                }).toList(),
              );

          Widget heroTile(FabHero hero) => GestureDetector(
                onTap: () async {
                  List<GamePlayer> updatePlayers = widget.players;
                  final idx =
                      indexOfPlayerByIndex(updatePlayers, playerIndex);
                  if (idx != -1) {
                    updatePlayers[idx].hero = hero;
                  }
                  widget.setPlayers(updatePlayers);
                  // Resets both players to the format's default life, then
                  // this player's life is overridden below to the hero's
                  // own printed total (some heroes deviate from 40/20).
                  _applyMatchType(showYoung
                      ? MatchTypeEnum.sage
                      : MatchTypeEnum.classicConstructed);
                  if (idx != -1) {
                    widget.players[idx].life = hero.life;
                    widget.setPlayers(widget.players);
                  }
                  await savePlayerHero(playerIndex, hero);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  onApplied?.call();
                },
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: AssetImage(hero.thumbnailPath),
                        onBackgroundImageError: (exception, stackTrace) {},
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hero.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );

          Widget heroPicker() {
            final heroes = showYoung ? fabHeroesYoung : fabHeroesAdult;
            final byClass = <FabHeroClass, List<FabHero>>{};
            for (final hero in heroes) {
              // Multi-class heroes show up under each of their classes.
              for (final heroClass in hero.heroClasses) {
                byClass.putIfAbsent(heroClass, () => []).add(hero);
              }
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ToggleButtons(
                  isSelected: [!showYoung, showYoung],
                  onPressed: (i) => setModalState(() => showYoung = i == 1),
                  borderRadius: BorderRadius.circular(8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(context.translate('player.heroAdult')),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(context.translate('player.heroYoung')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (byClass.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(context.translate('player.noHeroes'),
                        style: TextStyle(color: Colors.grey[600])),
                  )
                else
                  ...byClass.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: entry.value.map(heroTile).toList(),
                            ),
                          ],
                        ),
                      )),
              ],
            );
          }

          return AlertDialog(
            scrollable: true,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: Text(context.translate("player.changeColorPlayerName",
                translationParams: {
                  "name": _playerLabel(context, widget.players[playerIndex])
                })),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ToggleButtons(
                    isSelected: [tab == 0, tab == 1],
                    onPressed: (i) => setModalState(() => tab = i),
                    borderRadius: BorderRadius.circular(8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(context.translate('player.color')),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(context.translate('player.hero')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tab == 0) colorGrid() else heroPicker(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.translate('common.cancel')),
              ),
            ],
          );
        });
      },
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _playerLabel(context, widget.players[0]),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: widget.players[0].color,
                    ),
                  ),
                  Text(
                    _playerLabel(context, widget.players[1]),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: widget.players[1].color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
          return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const Divider(
                      height: 25,
                      color: ThemeColors.primary,
                    ),

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
                          _applyMatchType(value);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Joueur 1
                    Text(
                      "${context.translate('player.entityName')} 1",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerTile(widget.players[0], 0, setModalState),
                    const SizedBox(height: 16),
                    // Joueur 2
                    Text(
                      "${context.translate('player.entityName')} 2",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerTile(widget.players[1], 1, setModalState),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.translate('common.cancel')),
                        ),
                      ],
                    )
                  ]));
        });
      },
    );
  }

  Widget _buildPlayerTile(GamePlayer player, int index,
      void Function(void Function()) setModalState) {
    return GestureDetector(
      onTap: () => selectPlayerAppearance(index,
          onApplied: () => setModalState(() {})),
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
            Row(
              children: [
                if (player.hero != null)
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: player.color,
                    backgroundImage: AssetImage(player.hero!.thumbnailPath),
                    onBackgroundImageError: (exception, stackTrace) {},
                  )
                else
                  CircleAvatar(radius: 14, backgroundColor: player.color),
                const SizedBox(width: 10),
                Text(_playerLabel(context, player),
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Icon(Icons.edit, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void runTimer() {
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

  void startTimer() {
    _timeLeft = _timerDuration;
    setState(() {
      _timeLeft--;
      _timerStarted = true;
      _timerPause = false;
    });
    runTimer();
  }

  void toggleTimer() {
    setState(() {
      _timerPause = !_timerPause;
    });
    if (_timerPause) {
      _timer?.cancel();
    } else {
      runTimer();
    }
  }

  void _openRadialMenu() {
    if (Entry != null) return;
    final overlay = Overlay.of(context);

    // Position du logo pour centrer la roue
    final box = _logoKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final offset = box.localToGlobal(Offset.zero);
    final center = offset + Offset(size.width / 2, size.height / 2);

    Entry = OverlayEntry(
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets.bottom;
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeRadialMenu,
                  child: Container(color: Colors.black.withValues(alpha: 0.35)),
                ),
              ),
              Positioned.fill(
                child: RadialMenu(
                  center: center,
                  radius: 100,
                  items: [
                    RadialAction(
                      icon: Icons.settings,
                      tooltip: context.translate('game.matchType'),
                      onTap: () {
                        _closeRadialMenu();
                        showSettings();
                      },
                    ),
                    RadialAction(
                      icon: Icons.history,
                      tooltip: context.translate('game.history'),
                      onTap: () {
                        _closeRadialMenu();
                        showHistory();
                      },
                    ),
                    RadialAction(
                      icon: Icons.casino,
                      tooltip: context.translate('game.die.rollDie'),
                      onTap: () {
                        _closeRadialMenu();
                        _rollDie();
                      },
                    ),
                    RadialAction(
                      icon: Icons.color_lens,
                      tooltip: context.translate('player.changeColorPlayers'),
                      onTap: () {
                        _closeRadialMenu();
                        changePlayersColor();
                      },
                    ),
                    RadialAction(
                      icon: Icons.swap_horiz,
                      tooltip: context.translate('game.swapPlayer'),
                      onTap: () {
                        _closeRadialMenu();
                        widget.reversePlayers();
                      },
                    ),
                    RadialAction(
                      icon: Icons.refresh,
                      tooltip: context.translate('game.resetGame'),
                      onTap: () {
                        _closeRadialMenu();
                        widget.resetGame();
                        _timer?.cancel();
                        setState(() {
                          _timeLeft = widget.matchType.durationGame;
                          _timerDuration = widget.matchType.durationGame;
                          _timerStarted = false;
                          _timerPause = false;
                        });
                      },
                    ),
                    // Timer: start/pause selon l’état
                    RadialAction(
                      icon: !_timerPause && _timerStarted
                          ? Icons.pause
                          : Icons.play_arrow,
                      tooltip: !_timerPause
                          ? context.translate('game.timer.pause')
                          : context.translate('game.timer.start'),
                      onTap: () {
                        _closeRadialMenu();
                        if (_timerStarted) {
                          toggleTimer();
                        } else {
                          startTimer();
                        }
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 8.0 + insets,
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 600,
                      ),
                      child: const DevMeUpWidget(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(Entry!);
  }

  void _closeRadialMenu() {
    Entry?.remove();
    Entry = null;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isCompact = media.size.width < 360;
    final double circleDiameter = isCompact ? 140.0 : 160.0;
    final double timerFontSize = circleDiameter * 0.16;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: CompositedTransformTarget(
                link: _logoLink,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openRadialMenu,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        key: _logoKey,
                        width: circleDiameter,
                        height: circleDiameter,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Logo centré
                            Center(
                              child: Image.asset(
                                'assets/images/logo_dracailles_full.png',
                                height: circleDiameter * 0.9,
                                fit: BoxFit.contain,
                              ),
                            ),

                            // Compteur en overlay (bas du cercle)
                            // Overlay compteur / pause
                            if (_timerDuration != _timeLeft ||
                                (_timerPause && _timerStarted))
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Affiche le compteur si temps écoulé
                                          if (_timerDuration != _timeLeft)
                                            Text(
                                              '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontSize: timerFontSize,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                shadows: const [
                                                  Shadow(
                                                    blurRadius: 2,
                                                    color: Colors.black45,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Espace entre compteur et icône si les deux sont affichés
                                          if (_timerDuration != _timeLeft &&
                                              _timerPause &&
                                              _timerStarted)
                                            const SizedBox(width: 8),

                                          // Affiche l’icône pause si conditions remplies
                                          if (_timerPause && _timerStarted)
                                            const Icon(
                                              Icons.pause_circle_filled,
                                              color: Colors.white,
                                              size: 20,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 2,
                                                  color: Colors.black45,
                                                  offset: Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
