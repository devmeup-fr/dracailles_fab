import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/utils/animation.dart';
import 'package:flutter/material.dart';

import '../models/tournament_model.dart';
import '../services/tournament_service.dart';

class TournamentListScreen extends StatelessWidget {
  const TournamentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('tournament.entityName.1')),
      ),
      body: FutureBuilder<List<Tournament>>(
        future: TournamentService().getTournaments(),
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

          final tournaments = snapshot.data ?? [];

          if (tournaments.isEmpty) {
            return Center(
              child: Text(
                context.translate("tournament.noData"),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];

              // Animation fade-in pour chaque tournoi
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
                      tournament.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    subtitle: Text(
                      "${context.translate('tournament.date')} : ${tournament.date.toLocal()}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    leading: const Icon(
                      Icons.star, // Icône personnalisée pour chaque tournoi
                      size: 30,
                      color: Colors.orange,
                    ),
                    trailing: Text(
                      tournament.status,
                      style: TextStyle(color: Colors.green[700]),
                    ),
                    tileColor:
                        Colors.orange[50], // Dégradé de couleur d'arrière-plan
                    onTap: () {
                      Navigator.pushNamed(
                          context, '/tournament/${tournament.id}');
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
