import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the color/hero picked for each player slot (0/1) across
/// sessions, so players don't have to re-pick them at the start of every
/// game.
String _colorKeyForPlayer(int playerIndex) => 'player_color_$playerIndex';
String _heroKeyForPlayer(int playerIndex) => 'player_hero_$playerIndex';
String _lifeKeyForPlayer(int playerIndex) => 'player_life_$playerIndex';
String _historyKeyForPlayer(int playerIndex) => 'player_history_$playerIndex';

Future<void> savePlayerColor(int playerIndex, Color color) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_colorKeyForPlayer(playerIndex), color.toARGB32());
}

Future<Color?> getPlayerColor(int playerIndex) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getInt(_colorKeyForPlayer(playerIndex));
  return value == null ? null : Color(value);
}

Future<void> savePlayerHero(int playerIndex, FabHero? hero) async {
  final prefs = await SharedPreferences.getInstance();
  if (hero == null) {
    await prefs.remove(_heroKeyForPlayer(playerIndex));
  } else {
    await prefs.setString(_heroKeyForPlayer(playerIndex), hero.name);
  }
}

/// Looks the saved name back up in [fabHeroesAdult]/[fabHeroesYoung] - returns
/// null if nothing was saved, or if the hero was renamed/removed since.
Future<FabHero?> getPlayerHero(int playerIndex) async {
  final prefs = await SharedPreferences.getInstance();
  final name = prefs.getString(_heroKeyForPlayer(playerIndex));
  if (name == null) return null;
  for (final hero in [...fabHeroesAdult, ...fabHeroesYoung]) {
    if (hero.name == name) return hero;
  }
  return null;
}

/// Current life total, saved on every change so Android killing the app in
/// the background (not just the user force-closing it) doesn't silently
/// reset it back to the match's starting total on next launch.
Future<void> savePlayerLife(int playerIndex, int life) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_lifeKeyForPlayer(playerIndex), life);
}

Future<int?> getPlayerLife(int playerIndex) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_lifeKeyForPlayer(playerIndex));
}

/// The life-point history graph shown in the match's "Historique" dialog,
/// saved per player so it also survives Android killing the app in the
/// background instead of resetting to just the current total.
Future<void> savePlayerHistory(int playerIndex, List<int> lifePoints) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _historyKeyForPlayer(playerIndex),
    lifePoints.map((e) => e.toString()).toList(),
  );
}

Future<List<int>> getPlayerHistory(int playerIndex) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(_historyKeyForPlayer(playerIndex));
  if (saved == null) return [];
  return saved.map(int.parse).toList();
}

/// Whether the match screen's two player slots are currently swapped
/// (reversePlayers()) - saved so an app restart keeps the layout as the
/// player left it instead of always coming back to the original order.
const _playersReversedKey = 'players_reversed';

Future<void> savePlayersReversed(bool reversed) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_playersReversedKey, reversed);
}

Future<bool> getPlayersReversed() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_playersReversedKey) ?? false;
}
