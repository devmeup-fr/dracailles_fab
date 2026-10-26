import 'package:fab_dracailles/core/data/fab_heroes.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the color/hero picked for each player slot (0/1) across
/// sessions, so players don't have to re-pick them at the start of every
/// game.
String _colorKeyForPlayer(int playerIndex) => 'player_color_$playerIndex';
String _heroKeyForPlayer(int playerIndex) => 'player_hero_$playerIndex';

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
