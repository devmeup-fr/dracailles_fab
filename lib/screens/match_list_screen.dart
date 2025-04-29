import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:fab_dracailles/utils/animation.dart';
import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/match_service.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('match.entityName.1')),
      ),
      body: FutureBuilder<List<Match>>(
        future: MatchService().getMatches(),
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

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return Center(
              child: Text(
                context.translate("match.noData"),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];

              // Animation de la liste pour ajouter un effet de fade-in
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
                      "${context.translate("match.title")} ${match.id} - ${match.type}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    subtitle: Text(
                      "${context.translate("match.date")} : ${match.date}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    leading: const Icon(
                      Icons.sports_score, // Icône personnalisée pour les matchs
                      size: 30,
                      color: Colors.blue,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 20),
                    tileColor:
                        Colors.blue[50], // Dégradé de couleur d'arrière-plan
                    onTap: () {
                      Navigator.pushNamed(context, '/match/${match.id}');
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
