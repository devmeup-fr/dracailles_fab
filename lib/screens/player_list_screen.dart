import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:flutter/material.dart';

import '../models/player_model.dart';
import '../services/player_service.dart';

class PlayerListScreen extends StatelessWidget {
  const PlayerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.translate('player.entityName.1'))),
      body: FutureBuilder<List<Player>>(
        future: PlayerService().getPlayers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    "${context.translate("common.errors.title")} : ${snapshot.error}"));
          }
          final players = snapshot.data ?? [];
          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return Card(
                child: ListTile(
                  title: Text(player.name),
                  subtitle: Text(
                      "${context.translate("player.ranking")} : ${player.ranking}"),
                  trailing: Text(
                      "${context.translate("player.winsLetter")} : ${player.wins} / ${context.translate("player.lossesLetter")} : ${player.losses}"),
                  onTap: () {
                    Navigator.pushNamed(context, '/player/${player.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
