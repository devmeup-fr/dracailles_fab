import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/utils/animation.dart';
import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../services/player_service.dart';

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('player.entityNamePlural')),
      ),
      body: FutureBuilder<List<Player>>(
        future: PlayerService().getPlayers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "${context.translate("common.errors.title")} : ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final players = snapshot.data ?? [];

          if (players.isEmpty) {
            return Center(
              child: Text(
                context.translate("player.noData"),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];

              // Animation fade-in pour chaque joueur
              return FadeTransition(
                opacity: getAnimation(context),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    subtitle: Text(
                      "${context.translate("player.ranking")} : ${player.ranking}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    leading: const Icon(
                      Icons.person, // Icône personnalisée pour chaque joueur
                      size: 30,
                      color: Colors.blue,
                    ),
                    trailing: Text(
                      "${context.translate("player.winsLetter")} : ${player.wins} / ${context.translate("player.lossesLetter")} : ${player.losses}",
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                    tileColor:
                        Colors.blue[50], // Dégradé de couleur d'arrière-plan
                    onTap: () {
                      Navigator.pushNamed(context, '/player/${player.id}');
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
