import 'package:fab_dracailles/core/utils/localization_util.dart';
import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/match_service.dart';

class MatchListScreen extends StatelessWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.translate('match.entityName.1'))),
      body: FutureBuilder<List<Match>>(
        future: MatchService().getMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    "${context.translate("common.errors.title")} : ${snapshot.error}"));
          }
          final matches = snapshot.data ?? [];
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return ListTile(
                title: Text(
                    "${context.translate("match.title")} ${match.id} - ${match.type}"),
                subtitle:
                    Text("${context.translate("match.date")} : ${match.date}"),
                onTap: () {
                  Navigator.pushNamed(context, '/match/${match.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
