import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/core/utils/player_color_prefs.dart';
import 'package:fab_dracailles/models/game_player_model.dart';
import 'package:fab_dracailles/models/match_type_model.dart';
import 'package:fab_dracailles/screens/match_screen.dart';
import 'package:fab_dracailles/theme/colors.dart';
import 'package:fab_dracailles/widgets/devmeup_widget.dart';
import 'package:fab_dracailles/widgets/hero_color_picker_screen.dart';
import 'package:fab_dracailles/widgets/players_appearance_screen.dart';
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
  void didUpdateWidget(covariant BannerMatchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The match type can also change from outside (match_screen.dart
    // syncing it to a restored hero at startup, not through
    // _applyMatchType below) - react to that the same way: restart the
    // timer for the new format's duration.
    if (oldWidget.matchType.type != widget.matchType.type) {
      final duration = widget.matchType.durationGame;
      _timer?.cancel();
      setState(() {
        _timeLeft = duration;
        _timerDuration = duration;
        _timerStarted = false;
        _timerPause = false;
      });
    }
  }

  @override
  dispose() {
    super.dispose();
    _timer?.cancel();
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

  /// Like [_applyMatchType], but also carries heroes over to the new
  /// format - only used for an explicit pick from the settings dropdown,
  /// not [_syncMatchTypeToHeroes]'s own call (that one is already reacting
  /// to a hero pick, so converting heroes there would fight the choice the
  /// user just made).
  void _applyMatchTypeFromSettings(MatchTypeEnum value) {
    _applyMatchType(value);
    _convertHeroesForFormat(value);
  }

  /// Carries each player's hero over to its counterpart in the other age
  /// group when switching directly to Classic Constructed or Silver Age -
  /// e.g. picking SAGE shouldn't leave an Adult hero selected, and vice
  /// versa. Draft/Sealed are left alone, there's no clear convention there.
  /// Runs after _applyMatchType's resetGame() so this life/hero write is
  /// the one that sticks.
  void _convertHeroesForFormat(MatchTypeEnum value) {
    if (value != MatchTypeEnum.sage &&
        value != MatchTypeEnum.classicConstructed) {
      return;
    }
    final wantsYoung = value == MatchTypeEnum.sage;
    var changed = false;
    for (final player in widget.players) {
      final hero = player.hero;
      if (hero == null) continue;
      if (fabHeroesYoung.contains(hero) == wantsYoung) continue;
      final counterpart = findCrossFormatCounterpart(hero);
      if (counterpart == null) continue;
      player.hero = counterpart;
      player.life = counterpart.life;
      changed = true;
      // widget.setPlayers() below only persists life (see match_screen.dart's
      // _setPlayers) - without this, the OLD hero would still be the one
      // reloaded after an app restart, even though the life total shown
      // right now already matches the new one.
      savePlayerHero(player.index, counterpart);
    }
    if (changed) widget.setPlayers(widget.players);
  }

  /// Switches the match between Classic Constructed and Silver Age/Young
  /// based on whether EITHER player currently has a Young hero - not just
  /// whichever one was just picked, so picking an Adult hero for one
  /// player doesn't flip the format back while the other is still Young.
  /// No-ops if the format is already right, so it stays silent when the
  /// pick didn't need to change it.
  void _syncMatchTypeToHeroes() {
    final wantsYoung = widget.players
        .any((p) => p.hero != null && fabHeroesYoung.contains(p.hero));
    final target =
        wantsYoung ? MatchTypeEnum.sage : MatchTypeEnum.classicConstructed;
    if (widget.matchType.type == target) return;
    _applyMatchType(target);
    // _applyMatchType()'s resetGame() put both players back to the
    // format's default life - players with their own hero keep its
    // printed total instead (some heroes deviate from the usual 40/20).
    for (final player in widget.players) {
      if (player.hero != null) player.life = player.hero!.life;
    }
    widget.setPlayers(widget.players);
  }

  Future<void> _rollDie({required bool inverted}) async {
    // Waits for an explicit tap instead of rolling as soon as the dialog
    // opens. `rolling` is tracked separately from `rolledNumber` so the
    // brief gap while a reroll "spins" doesn't look like the die was reset
    // back to its never-been-rolled state (that button flashing back on
    // for half a second looked like a bug).
    int? rolledNumber;
    bool rolling = false;
    int rollTick = 0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          void startRoll() {
            setModalState(() {
              rolling = true;
              rollTick++;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              setModalState(() {
                rolledNumber = _roll(_dieSides);
                rolling = false;
              });
            });
          }

          return Transform.rotate(
            angle: inverted ? math.pi : 0,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.translate('game.die.dieRoll',
                      translationParams: {"sides": _dieSides.toString()})),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
                        // Back to the "Lancer le dé" button instead of
                        // auto-rolling the new die type.
                        setModalState(() => rolledNumber = null);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  if (rolling)
                    TweenAnimationBuilder<double>(
                      key: ValueKey(rollTick),
                      tween: Tween(begin: 0, end: 4 * math.pi),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, angle, child) => Transform.rotate(
                        angle: angle,
                        child: child,
                      ),
                      child: const Icon(
                        Icons.casino,
                        size: 48,
                        color: ThemeColors.primary,
                      ),
                    )
                  else if (rolledNumber == null)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.casino),
                      label: Text(context.translate('game.die.rollDie')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: startRoll,
                    )
                  else ...[
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
                        "$rolledNumber",
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
                      onPressed: startRoll,
                    ),
                  ],
                ],
              ),
            ),
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

  void showHistory({required bool inverted}) {
    List<HistoryEntry> player0History = widget.history
        .where((entry) => entry.player == widget.players[0])
        .toList();
    List<HistoryEntry> player1History = widget.history
        .where((entry) => entry.player == widget.players[1])
        .toList();

    showDialog(
      context: context,
      builder: (context) => Transform.rotate(
        angle: inverted ? math.pi : 0,
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              // Opaque - a translucent background let the match screen
              // (both players' hero art at once) bleed through underneath,
              // which doesn't line up with this dialog's own left/right
              // split and just looked like one hero spilling into the
              // other's column.
              color: Colors.white,
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
                    child: IntrinsicHeight(
                      // Row centers shorter children by default - with one
                      // history longer than the other, that pushed the
                      // shorter column's numbers down instead of lining up
                      // both at the top. Stretching both to the same
                      // (tallest) height keeps them top-aligned and gives
                      // both tinted backgrounds the same height too.
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Historique du joueur 0 - fond teinté de sa propre
                          // couleur, pour que son côté reste clairement le
                          // sien et ne se mélange pas avec l'autre colonne.
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: widget.players[0].color
                                    .withValues(alpha: 0.08),
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: player0History.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Text(
                                      entry.lifePoints.toString(),
                                      style: TextStyle(
                                        fontSize: entry == player0History.last
                                            ? 24
                                            : 16,
                                        color: widget.players[0].color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            color: Colors.grey.shade400,
                          ),
                          // Historique du joueur 1 - idem, teinté de sa
                          // propre couleur.
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              decoration: BoxDecoration(
                                color: widget.players[1].color
                                    .withValues(alpha: 0.08),
                                borderRadius: const BorderRadius.horizontal(
                                    right: Radius.circular(12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: player1History.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Text(
                                      entry.lifePoints.toString(),
                                      style: TextStyle(
                                        fontSize: entry == player1History.last
                                            ? 24
                                            : 16,
                                        color: widget.players[1].color,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton de fermeture
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 40),
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
      ),
    );
  }

  void showSettings({required bool inverted}) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Transform.rotate(
              angle: inverted ? math.pi : 0,
              child: AlertDialog(
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
                            _applyMatchTypeFromSettings(value);
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
                      _buildPlayerTile(widget.players[0], setModalState,
                          inverted: inverted),
                      const SizedBox(height: 16),
                      // Joueur 2
                      Text(
                        "${context.translate('player.entityName')} 2",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      _buildPlayerTile(widget.players[1], setModalState,
                          inverted: inverted),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(context.translate('common.cancel')),
                          ),
                        ],
                      )
                    ]),
              ));
        });
      },
    );
  }

  Widget _buildPlayerTile(
      GamePlayer player, void Function(void Function()) setModalState,
      {required bool inverted}) {
    return GestureDetector(
      onTap: () async {
        // player.index is a stable identity, not a screen position - it
        // survives reversePlayers() reordering widget.players, unlike a
        // plain 0/1 passed in from the call site would (that was a real
        // bug: color/hero/life got saved and restored under the wrong
        // player after a reversal).
        final idx = widget.players.indexWhere((p) => p.index == player.index);
        if (idx == -1) return;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HeroColorPickerScreen(
            colors: _colorsToSelect,
            inverted: inverted,
            startOnHeroTab: widget.players[idx].hero != null,
            // A hero already picked wins; otherwise default to whichever
            // the match is already running as (so a SAGE match suggests
            // Young heroes instead of always defaulting to Adult).
            startOnYoung: widget.players[idx].hero != null
                ? fabHeroesYoung.contains(widget.players[idx].hero)
                : widget.matchType.type != MatchTypeEnum.classicConstructed,
            onColorSelected: (color) async {
              widget.players[idx].color = color;
              widget.players[idx].hero = null;
              widget.setPlayers(widget.players);
              _syncMatchTypeToHeroes();
              await savePlayerColor(player.index, color);
              await savePlayerHero(player.index, null);
            },
            onHeroSelected: (hero, isYoung) async {
              widget.players[idx].hero = hero;
              widget.players[idx].life = hero.life;
              widget.setPlayers(widget.players);
              _syncMatchTypeToHeroes();
              await savePlayerHero(player.index, hero);
            },
          ),
        ));
        setModalState(() {});
      },
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

  void _openRadialMenu({required bool inverted}) {
    if (Entry != null) return;
    final overlay = Overlay.of(context);

    // Always fans out from the middle of the match area, regardless of
    // which edge badge was tapped - a badge pinned to an edge doesn't have
    // room around it for a centered wheel of icons.
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final size = box.size;
    final offset = box.localToGlobal(Offset.zero);
    // RadialMenu positions its items with Positioned inside a Stack that
    // lives in the Overlay - on the web build the Overlay itself sits
    // inside MaterialApp.builder's phone-width cap, so its own origin no
    // longer coincides with the window's. localToGlobal gives a
    // window-relative point; re-basing it onto the overlay's own box is
    // what Positioned actually needs.
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final center = overlayBox
        .globalToLocal(offset + Offset(size.width / 2, size.height / 2));

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
                  inverted: inverted,
                  items: [
                    RadialAction(
                      icon: Icons.settings,
                      tooltip: context.translate('game.matchType'),
                      onTap: () {
                        _closeRadialMenu();
                        showSettings(inverted: inverted);
                      },
                    ),
                    RadialAction(
                      icon: Icons.history,
                      tooltip: context.translate('game.history'),
                      onTap: () {
                        _closeRadialMenu();
                        showHistory(inverted: inverted);
                      },
                    ),
                    RadialAction(
                      icon: Icons.casino,
                      tooltip: context.translate('game.die.rollDie'),
                      onTap: () {
                        _closeRadialMenu();
                        _rollDie(inverted: inverted);
                      },
                    ),
                    RadialAction(
                      icon: Icons.color_lens,
                      tooltip: context.translate('player.changeColorPlayers'),
                      onTap: () {
                        _closeRadialMenu();
                        showDialog(
                          context: context,
                          builder: (_) => PlayersAppearanceScreen(
                            players: widget.players,
                            colors: _colorsToSelect,
                            matchType: widget.matchType,
                            setPlayers: (players) => widget.setPlayers(players),
                            syncMatchType: _syncMatchTypeToHeroes,
                            inverted: inverted,
                          ),
                        );
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

  Widget _buildLogoButton({
    required double diameter,
    required double timerFontSize,
    required bool inverted,
  }) {
    return Transform.rotate(
      angle: inverted ? math.pi : 0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openRadialMenu(inverted: inverted),
        child: Container(
          width: diameter,
          height: diameter,
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
                  height: diameter * 0.9,
                  fit: BoxFit.contain,
                ),
              ),

              // Compteur en overlay (bas du cercle) - l'état pause a sa
              // propre grande superposition au milieu de l'écran à la
              // place d'une petite icône ici.
              if (_timerDuration != _timeLeft)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        child: Text(
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
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isCompact = media.size.width < 360;
    // Back to roughly the original single-badge size, now that each one is
    // pinned to a screen edge instead of sitting over the hero art.
    final double circleDiameter = isCompact ? 100.0 : 120.0;
    final double timerFontSize = circleDiameter * 0.16;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pinned to the left/right edges instead of the horizontal center,
          // since hero art is usually centered on the card - this keeps
          // both badges clear of the face no matter the hero.
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _buildLogoButton(
                diameter: circleDiameter,
                timerFontSize: timerFontSize,
                inverted: true,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildLogoButton(
                diameter: circleDiameter,
                timerFontSize: timerFontSize,
                inverted: false,
              ),
            ),
          ),
          // Big, obvious paused state instead of the small icon that used
          // to sit next to the timer - tapping it resumes, same as the
          // timer action in the radial menu.
          if (_timerPause && _timerStarted)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: toggleTimer,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(
                        child: Icon(
                          Icons.pause_circle_filled,
                          color: Colors.white,
                          size: 110,
                        ),
                      ),
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
